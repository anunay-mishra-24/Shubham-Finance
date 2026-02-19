@RestResource(urlMapping='/AccountStatementAnalyzer/*')
global with sharing class SHF_AccountStatementAnalyzerService {

    @HttpPost
    global static void webhookListener() {
        
        Logger.info('Account Statement Analyzer Webhook Triggered');
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String requestBody = req.requestBody.toString();
            Logger.info('Webhook Raw Body: ' + requestBody);
            
            if (String.isBlank(requestBody)) {
                Logger.error('Empty webhook payload');
                return;
            }
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            system.debug('payload >> '+payload);
            
            String clientTxnId = (String) payload.get('clienttxnid');
            String txnId       = (String) payload.get('txnid');
            String fipId       = (String) payload.get('fipid');
            String fipname     = (String) payload.get('fipname');
            String pan         = (String) payload.get('pan');
            
            logger.info('clientTxnId >>> '+clientTxnId);
            if (String.isBlank(clientTxnId)) {
                Logger.error('clienttxnid missing in webhook');
            }
            
            List<E_Verification__c> evList = [SELECT Id, Name, Client_Txn_Id__c,Loan_Applicant__c FROM E_Verification__c WHERE Client_Txn_Id__c = :clientTxnId LIMIT 1];
            if (evList.isEmpty()) {
                Logger.error( 'No Account_Aggregator_CAM E_Verification found for clientTxnId: ' + clientTxnId );
                return;
            }
            E_Verification__c parentEV = evList[0];
            Logger.info('Matched E_Verification Id: ' + parentEV.Id);
            
            if (parentEV.Loan_Applicant__c == null) {
                Logger.error('Loan Applicant lookup is blank on E_Verification Id: ' + parentEV.Id);
            }
            
            Id applicantId = parentEV.Loan_Applicant__c;
            Logger.info('Matched Loan Applicant Id: ' + applicantId);
            String pdfBase64;
            Decimal currentBalance;
            Map<String,Decimal> averageMonthsTransaction = new Map<String,Decimal>();
            String transactionStartDate = '';
            String transactionEndDate = ''; 
            
            if (payload.containsKey('dataDetail')) {
                Map<String, Object> dataDetail =
                    (Map<String, Object>) payload.get('dataDetail');
                
                if (dataDetail != null) {
                    // PDF
                    if (dataDetail.containsKey('pdfbase64')) {
                        pdfBase64 = (String) dataDetail.get('pdfbase64');
                        if (pdfBase64 != null) {
                            pdfBase64 = pdfBase64.replace('"', '');
                        }
                    }
                    //currentBalance
                    if (dataDetail.containsKey('jsonData')) {
                        Map<String, Object> jsonData = (Map<String, Object>) dataDetail.get('jsonData');
                        if (jsonData != null && jsonData.containsKey('Account')) {
                            Map<String, Object> account =(Map<String, Object>) jsonData.get('Account');
                            if (account != null && account.containsKey('Summary')) {
                                Map<String, Object> summary =(Map<String, Object>) account.get('Summary');
                                if (summary != null && summary.containsKey('currentBalance')) {
                                    try {
                                        currentBalance = Decimal.valueOf( (String) summary.get('currentBalance') );
                                        Logger.info( 'Extracted currentBalance >>> ' + currentBalance );
                                    } catch (Exception ex) {  Logger.error( 'Error parsing currentBalance: ' + ex.getMessage() );
                                    }
                                }
                            }
                            // Trasaction work start here by Vikas
                            if(account != null && account.containsKey('Transactions')){
                                Map<String, Object> transactions = (Map<String, Object>) account.get('Transactions');
                                transactionStartDate = String.valueOf(transactions.get('startDate'));
                                transactionEndDate = String.valueOf(transactions.get('endDate'));
                                system.debug('Start date '+transactionStartDate);
                                system.debug('End date '+transactionEndDate);
                                if(transactions != null && transactions.containsKey('Transaction')){
                                    List<Object> transactionList = (List<Object>)transactions.get('Transaction');
                                    averageMonthsTransaction = getAvergeMonthsTransactions(transactionList);

                                    System.debug('averageMonthsTransaction -- '+averageMonthsTransaction);
                                    Logger.info('averageMonthsTransaction - '+averageMonthsTransaction);
                                }
                            }
                            // Trasaction work end here by Vikas
                        }
                    }
                }
            }
            
            Id lineItemRTId = Schema.SObjectType.E_Verification_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Account_Aggregator_Cam').getRecordTypeId();
            E_Verification_Line_Item__c lineItem = new E_Verification_Line_Item__c();
            lineItem.RecordTypeId = lineItemRTId;
            lineItem.E_Verification__c = parentEV.Id;
            lineItem.Pan__c = pan;
            lineItem.Transaction_Start_Date__c = Date.valueOf(transactionStartDate);
            lineItem.Transaction_End_Date__c = Date.valueOf(transactionEndDate);

            lineItem.Transaction_balance_Average__c = JSON.serialize(averageMonthsTransaction);
            
            insert lineItem;
            
            Logger.info('Line Item Created: ' + lineItem.Id);
            
            // Attach FULL RESPONSE (.txt) — ALWAYS
            ContentVersion responseTxt = new ContentVersion();
            responseTxt.Title = 'AA_Response_' + DateTime.now().getTime();
            responseTxt.PathOnClient = 'AA_Response.txt';
            responseTxt.VersionData = Blob.valueOf(requestBody);
            responseTxt.FirstPublishLocationId = lineItem.Id;
            insert responseTxt;
            Logger.info('Response TXT attached');
            
            // Attach PDF (IF PRESENT)
            if (String.isNotBlank(pdfBase64)) {
                
                Blob pdfBlob = EncodingUtil.base64Decode(pdfBase64);
                ContentVersion pdfCV = new ContentVersion();
                pdfCV.Title = 'Account_Statement_' + fipname;
                pdfCV.PathOnClient = 'AccountStatement.pdf';
                pdfCV.VersionData = pdfBlob;
                pdfCV.FirstPublishLocationId = lineItem.Id;
                insert pdfCV;
                
                Document__c doc;
                if (applicantId != null) {
                    doc = new Document__c();
                    doc.Loan_Applicant__c = applicantId;
                    doc.E_Verification_Line_Item__c = lineItem.Id;
                    doc.File_Name__c = 'Account Statement';
                    doc.Document_Source__c = 'API';
                    doc.Document_Category__c = 'Others';
                    doc.Status__c = 'Uploaded';
                    //doc.Stage__c = 'QDE';
                    doc.Document_Received_Date__c = System.today();
                    doc.CurrentBalance__c = string.valueof(currentBalance);
                    
                    insert doc;
                    Logger.info('Document record created: ' + doc.Id);
                }
                
                // 2. Attach Base64 TXT file
                ContentVersion base64TxtCV = new ContentVersion();
                base64TxtCV.Title = 'Account_Statement_' + pan;
                base64TxtCV.PathOnClient = 'Account_Statement_' + pan + '.txt';
                base64TxtCV.VersionData = Blob.valueOf(pdfBase64);
                base64TxtCV.FirstPublishLocationId = doc.Id;
                
                insert base64TxtCV;
                Logger.info('Base64 TXT attached');
                
            } else {
                Logger.info('No PDF found in this response');
            }
            
            // Success Response
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"status":"success","message":"Response processed"}');
            
        } catch (Exception e) {
            Logger.error('Webhook Error: ' + e.getMessage() + ' | Line: ' + e.getLineNumber());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"status":"error","message":"Internal error"}');
        } finally {
            Logger.saveLog();
        }
    }
    global static Map<String,Decimal> getAvergeMonthsTransactions(List<Object> transactionList){
        Map<String,Decimal> averageMonthsTransaction =  new Map<String,Decimal>();
        Map<String,Decimal> averageMonthsTransactionList = new Map<String,Decimal>();
        Map<String,Decimal> averageMonthTrasactionCount = new Map<String,Decimal>();
        Map<Integer,String> monthSeries = new Map<Integer,String>{
            1 => 'January',   
            2 => 'February',  
            3 => 'March',     
            4 => 'April',     
            5 => 'May',       
            6 => 'June',      
            7 => 'July',      
            8 => 'August',    
            9 => 'September', 
            10 => 'October',   
            11 => 'November',  
            12 => 'December'
        };
        if(transactionList != null){
            // Integer transactionYear = 0;
            for(Object transObj  : transactionList){
            Map<String, Object> transactionMap = (Map<String, Object>) transObj;
                if(transactionMap != null && String.isNotBlank(String.valueOf(transactionMap.get('transactionTimestamp'))) && String.isNotBlank(String.valueOf(transactionMap.get('currentBalance')))){
                    String iso = String.valueOf(transactionMap.get('transactionTimestamp'));
                    iso = iso.replace('T', ' ');
                    iso = iso.substring(0, 19);
                    Datetime dt = Datetime.valueOfGmt(iso);
                    // String transactionMonth =Date.newInstance(dt.year(), dt.month(), 1).format('MMMM');
                    String transactionMonth = monthSeries.get(dt.month());
                    String transactionYear = String.valueOf(dt.year());
                    String transactionMonthYear = transactionMonth + '_' + transactionYear;
                    Decimal currentBalance = Decimal.valueOf(String.valueOf(transactionMap.get('currentBalance')));

                    if(averageMonthsTransactionList.containsKey(transactionMonthYear)){
                        averageMonthsTransactionList.put(transactionMonthYear,(averageMonthsTransactionList.get(transactionMonthYear) + currentBalance));
                        averageMonthTrasactionCount.put(transactionMonthYear,averageMonthTrasactionCount.get(transactionMonthYear) + 1);
                    }
                    else{
                        averageMonthsTransactionList.put(transactionMonthYear ,currentBalance);
                        averageMonthTrasactionCount.put(transactionMonthYear,1);
                    } 
                }
            }
            for(String month : averageMonthsTransactionList.keySet()){
                String monthStr = month.split('_')[0];
                Decimal average = averageMonthsTransactionList.get(month)/averageMonthTrasactionCount.get(month);
                averageMonthsTransaction.put(month,average);
            }
        }
        return averageMonthsTransaction;
    }
}