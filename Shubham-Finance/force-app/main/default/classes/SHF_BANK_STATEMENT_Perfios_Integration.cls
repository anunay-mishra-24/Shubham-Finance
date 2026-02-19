/**
* @File Name          : SHF_BANK_STATEMENT_Perfios_Integration
* @Description        : Class to Trigger Perfios APIs for retrieving TransactionId.
* @Author             : Karan Keswani
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/
public without sharing class SHF_BANK_STATEMENT_Perfios_Integration implements Database.AllowsCallouts {
    

    public Id customerId;
    private String password;
    private Date fromDate;
    private Date toDate;
    private HTTPCalloutService service;
    private HTTPCalloutService callbackService;

    private static final String PROCESS_TYPE = 'STATEMENT';
    private static final String LOAN_TYPE = 'Personal Loan';
    
//Constructor to initialize the variables
    public SHF_BANK_STATEMENT_Perfios_Integration(String customerId, String password, Date fromDate, Date toDate){
        this.customerId = customerId;
        this.password = password;
        this.fromDate = fromDate;
        this.toDate = toDate;
        this.service = new HTTPCalloutService('Perfios_Initiate_Transaction_API');
        this.callbackService = new HTTPCalloutService('Perfios_Transaction_Callback');
        // Debuggers
     System.debug('Working till here - 1');
    }
     
    
    public void main() {
        try {
            // Debuggers
     System.debug('Working till here - 2');
            createTransaction();
            // Debuggers
     System.debug('Working till here - 3');
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('In Line Number: ' + e.getLineNumber());
            Logger.error('Exception: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
        }
    }
    public void createTransaction() {
            
        HTTPResponse res = new HTTPResponse();
        
        // Debuggers
     	System.debug('Working till here - 4');
        
        E_Verification__c verify = null;
        List<E_Verification__c> createVerifyList = new List<E_Verification__c>();
        List<Loan_Applicant__c> applicants = new LoanApplicantsSelector().selectByIdWithParentRecords(new Set<Id>{customerId});
        
        // Debuggers
     System.debug('Working till here - 5');
        
        try {
            System.debug('fromDatefromDatefromDate '+fromDate);
             System.debug('toDatetoDatetoDate '+toDate);
            
            // Debuggers
     System.debug('Working till here - 6');
            
            String rangeFrom = DateTime.newInstance(fromDate.year(), fromDate.month(), fromDate.day()).format('yyyy-MM');  //system.now().addMonths(-6).format('yyyy-MM');
            System.debug('rangeFrom 00000000000  '+DateTime.newInstance(fromDate.year(), fromDate.month(), fromDate.day()));
            System.debug('rangeFrom   '+rangeFrom);
            String rangeTo =   DateTime.newInstance(toDate.year(), toDate.month(), toDate.day()).format('yyyy-MM');  //system.now().format('yyyy-MM');
            System.debug('rangeTo 0000000000000000  '+DateTime.newInstance(toDate.year(), toDate.month(), toDate.day()));
            System.debug('rangeTo   '+rangeTo);
            //for now hardcoding the loan type 
            String loanType = 'Home';
            //String loanType = applicants[0].Application__r.Product__c != SHF_ConstantsUtil.LOB_BL ? String.valueOf(applicants[0].Application__r.Product__c) : SHF_ConstantsUtil.SHF_PRODUCT_CATEGORY;
            
            // Debuggers
     System.debug('Working till here - 7');

            //debug
            Perfios_IntegrationUtil.payloadParent plDetails = new Perfios_IntegrationUtil.payloadParent(
                applicants[0].Id,
				String.valueOf(applicants[0].Application__r.Applied_Loan_Amount__c),
                String.valueOf(applicants[0].Application__r.Tenure__c),
                loanType,
                PROCESS_TYPE,
                rangeFrom,
                rangeTo,
                callbackService.getEndpointURL(),
                'atLeastOneTransactionPerMonthInRange',
                '20'//bankDetail.Institution_Id__c
            );
            
            // Debuggers
     System.debug('Working till here - 8');
            
            
            Perfios_IntegrationUtil.processPayload processPayload = new Perfios_IntegrationUtil.processPayload();
            processPayload.payload = plDetails;
            String payload = JSON.serialize(processPayload, true);
            
            System.debug('Request BODY  '+payload);
            
            res = Perfios_IntegrationUtil.initiateTransaction(payload);
            
            // Debuggers
     System.debug('Working till here - 9');
            
            System.debug(res);
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            // Debuggers
     System.debug('Working till here - 10');
            
            Savepoint sp;
            
            
            if (res.getStatusCode() == 200 && responseMap.containsKey('transaction')) {
                
                // Debuggers
     System.debug('Working till here - 11');
                
                 Map<String, Object> perfiosTransactionIdMap = (Map<String, Object>) responseMap.get('transaction');
                
                System.debug('perfios transaction id map ' + perfiosTransactionIdMap);
                
                // Debuggers
     			System.debug('Working till here - 12');
                
                 String perfiosTransactionId = (String) perfiosTransactionIdMap.get('perfiosTransactionId');
                
                System.debug('perfios transaction id  ' + perfiosTransactionId);
                
                // Debuggers
     			System.debug('Working till here - 13');
                
                /**
                fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new Schema.SObjectType[] {E_Verification__c.SObjectType});
                fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork( new List<SObjectType> {Loan_Applicant__c.SObjectType});
				**/
                
                
                E_Verification__c everficationObj = new E_Verification__c(id = customerId);
                everficationObj.Transaction_Id__c = perfiosTransactionId;
                
                
                
                 verify = createVerificationRecord(null);
                 verify.Perfios_Transaction_Id__c =perfiosTransactionId;//'RN3A1720448347043';
                 verify.Loan_Applicant__c = customerId;
                 verify.Password__c = password;
                 createVerifyList.add(verify);
            
 			     insert createVerifyList;
                
                 applicants[0].Perfios_Verification__c = createVerifyList[0].Id;
                 update applicants;
                
            
            	Document__c document = createDocumentRecord(applicants[0].Application__c, customerId, createVerifyList[0].Id);
                document.Document_Type__c = 'Banking Document';
                insert document;
                
                 List<ContentVersion> cvObjList = selectContentVersionsByLinkedEntityId(customerId);
                 System.debug('cvObjList  '+cvObjList);
                 SHF_DisplayDocumentsController.uploadDocument('', cvObjList[0].Title, String.valueOf(cvObjList[0].VersionData), document.Id, cvObjList[0].Id);
                
                 System.enqueueJob(new SHF_Perfios_Upload_Files_Integration(customerId,perfiosTransactionId, cvObjList,  createVerifyList[0].Id));
             } else {
                 verify = createVerificationRecord('Received status code ' + res.getStatusCode());
                 createVerifyList.add(verify);
             }
        

            // Storing log in nebula log
            if(res.getStatusCode() == 200 && String.isNotBlank(res.getBody())){
                
                Logger.info('Manual Fetch Response Body: ' + res.getBody());
				//Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (responseMap != null && responseMap.containsKey('statusMessage')) {
                    String statusMessage = (String) responseMap.get('statusMessage');
                    // everficationObj.Description__c = statusMessage;
                    Logger.info('Extracted statusMessage: ' + statusMessage); 
                } else {
                    Logger.error('statusMessage key NOT found in response.');
                }

            }else {
                Logger.error('Manual Fetch Failed. StatusCode: '+ res.getStatusCode() + ' Body: ' + res.getBody());
            }
            Logger.info('Manual Fetch Request Body: ' + service.getRequestBody());
            Logger.info('Manual Fetch Response Status Code: ' + res.getStatusCode());
            Logger.info('Manual Fetch Response Status: ' + res.getStatus());
            Logger.info('Manual Fetch Response Body: ' + res.getBody());
            
            }
            
          catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('In Line Number: ' + e.getLineNumber());
            Logger.error('Exception: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
            
            verify = createVerificationRecord(e.getMessage() + ' at line ' + e.getLineNumber());
            createVerifyList.add(verify);
        }finally {
            Logger.saveLog();
            System.debug('logger saved commented');
        }
        if (!createVerifyList.isEmpty() && createVerifyList[0].Id == null) {
            insert createVerifyList;
            applicants[0].Perfios_Verification__c = createVerifyList[0].Id;
            update applicants;
        }
    }
    
    private E_Verification__c createVerificationRecord(String failedReason) {
        E_Verification__c verify = SHF_CommonUtil.createVerfication(customerId, SHF_ConstantsUtil.PERFIOS_API_RECORD_TYPE, 'In Progress');
        verify.Failed_Reason__c = failedReason;
        verify.Loan_Applicant__c = customerId;
        return verify;
    }
    
    private Document__c createDocumentRecord(Id loanApplicationId, Id customerId, Id verificationId) {
        Document__c document = new Document__c();
        document.Application__c = loanApplicationId;
        document.Loan_Applicant__c = customerId;
        document.Verification__c = verificationId;
        document.Status__c = 'Uploaded';
        return document;
    }
    private List<ContentVersion> selectContentVersionsByLinkedEntityId(Id linkedEntityId) {
        List<String> contentDocumentIdList = new List<String>();
        for (ContentDocumentLink docLink : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :customerId]) {
            contentDocumentIdList.add(docLink.ContentDocumentId);
            System.debug('document id: ' + docLink.ContentDocumentId);
        }
        System.debug('contentDocumentIdList  '+contentDocumentIdList);
        // Fetch the content versions of the documents
        List<ContentVersion> cvObjList = [SELECT Title, Id, VersionData, FileType FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIdList ORDER BY CreatedDate DESC LIMIT 1];
        
        return cvObjList;
       
    }
}