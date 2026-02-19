public class ObligationProcessor {
    
    public static void execute() {
        // Dummy JSON
        String responseBody = '{ "STATUS": "COMPLETED", "ACKNOWLEDGEMENT-ID":410293527, "HEADER": { "CUST-ID": "111111", "APPLICATION-ID": "189040217268", "RESPONSE-TYPE": "RESPONSE", "REQUEST-RECEIVED-TIME": "04072025 09:35:21" }, "FINISHED": [ { "TRACKING-ID": 8777833, "BUREAU-STRING": "{ \\"controlData\\": { \\"success\\": true }, \\"consumerCreditData\\": [ { \\"tuefHeader\\": { \\"headerType\\": \\"TUEF\\", \\"version\\": \\"12\\", \\"memberRefNo\\": \\"TESTING TUEF IN JSON\\", \\"enquiryMemberUserId\\": \\"MG5348XXXX\\", \\"subjectReturnCode\\": 1, \\"enquiryControlNumber\\": \\"0021562XXXXX\\", \\"dateProcessed\\": \\"05052020\\", \\"timeProcessed\\": \\"101041\\" }, \\"accounts\\": [ { \\"index\\": \\"T001\\", \\"memberShortName\\": \\"NOT DISCLOSED\\", \\"accountNumber\\": \\"XXXX4321\\", \\"accountType\\": \\"05\\", \\"ownershipIndicator\\": 1, \\"dateOpened\\": \\"31122018\\", \\"lastPaymentDate\\": \\"04032019\\", \\"dateClosed\\": \\"01011900\\", \\"dateReported\\": \\"31032019\\", \\"highCreditAmount\\": 34000, \\"currentBalance\\": 33372, \\"amountOverdue\\": 0, \\"paymentHistory\\": \\"000XXX000000\\", \\"paymentStartDate\\": \\"01032019\\", \\"paymentEndDate\\": \\"01122022\\", \\"suitFiled\\": \\"00\\", \\"creditFacilityStatus\\": \\"00\\", \\"collateralValue\\": \\"000123456\\", \\"collateralType\\": \\"01\\", \\"creditLimit\\": \\"000023434\\", \\"cashLimit\\": \\"000000200\\", \\"interestRate\\": 24.13, \\"paymentTenure\\": 48, \\"emiAmount\\": 1392, \\"woAmountTotal\\": 2343, \\"woAmountPrincipal\\": 78787, \\"settlementAmount\\": 67676, \\"paymentFrequency\\": \\"03\\", \\"actualPaymentAmount\\": 1392, \\"errorDate\\": \\"12122022\\", \\"errorCode\\": \\"009\\", \\"cibilRemarksDate\\": \\"12122022\\", \\"cibilRemarksCode\\": \\"TL1008\\", \\"errorRemardsDate\\": \\"12122022\\", \\"errorRemarksCode1\\": \\"000001\\" },{ \\"index\\": \\"T001\\", \\"memberShortName\\": \\"NOT DISCLOSED\\", \\"accountNumber\\": \\"XXXX4321\\", \\"accountType\\": \\"61\\", \\"ownershipIndicator\\": 1, \\"dateOpened\\": \\"31122018\\", \\"lastPaymentDate\\": \\"04032019\\", \\"dateClosed\\": \\"01011900\\", \\"dateReported\\": \\"31032019\\", \\"highCreditAmount\\": 34000, \\"currentBalance\\": 33372, \\"amountOverdue\\": 0, \\"paymentHistory\\": \\"000XXX000000\\", \\"paymentStartDate\\": \\"01032019\\", \\"paymentEndDate\\": \\"01122022\\", \\"suitFiled\\": \\"00\\", \\"creditFacilityStatus\\": \\"00\\", \\"collateralValue\\": \\"000123456\\", \\"collateralType\\": \\"01\\", \\"creditLimit\\": \\"000023434\\", \\"cashLimit\\": \\"000000200\\", \\"interestRate\\": 24.13, \\"paymentTenure\\": 48, \\"emiAmount\\": 1392, \\"woAmountTotal\\": 2343, \\"woAmountPrincipal\\": 78787, \\"settlementAmount\\": 67676, \\"paymentFrequency\\": \\"03\\", \\"actualPaymentAmount\\": 1392, \\"errorDate\\": \\"12122022\\", \\"errorCode\\": \\"009\\", \\"cibilRemarksDate\\": \\"12122022\\", \\"cibilRemarksCode\\": \\"TL1008\\", \\"errorRemardsDate\\": \\"12122022\\", \\"errorRemarksCode1\\": \\"000001\\" } ] } ] }", "STATUS": "SUCCESS", "PRODUCT": "INDV", "BUREAU": "CIBIL", "ENCODED STRING": "" } ] }';
        
        Id applicationId = 'a03C100000HI4bLIAT';
        String bureau = 'CIBIL';
        
        processObligations(responseBody, applicationId, bureau);
    }
    
    public static void processObligations(String bureauResponseJson, Id applicationId, String bureau) {
        System.debug('### Starting processObligations');
        System.debug('### Application Id: ' + applicationId);
        System.debug('### Bureau: ' + bureau);
        
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Obligation__c.SObjectType});
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(bureauResponseJson);
            List<Object> finishedList = (List<Object>) responseMap.get('FINISHED');
            
            if (finishedList == null || finishedList.isEmpty()) {
                System.debug('### No FINISHED block found');
                return;
            }
            
            Map<String, Object> finishedMap = (Map<String, Object>) finishedList[0];
            String bureauStringJson = (String) finishedMap.get('BUREAU-STRING');
            System.debug('### Extracted BUREAU-STRING: ' + bureauStringJson);
            
            Map<String, Object> bureauMap = (Map<String, Object>) JSON.deserializeUntyped(bureauStringJson);
            List<Object> consumerCreditDataList = (List<Object>) bureauMap.get('consumerCreditData');
            
            if (consumerCreditDataList == null || consumerCreditDataList.isEmpty()) {
                System.debug('### No consumerCreditData found');
                return;
            }
            
            Map<String, Object> consumerCreditData = (Map<String, Object>) consumerCreditDataList[0];
            List<Object> accountsList = (List<Object>) consumerCreditData.get('accounts');
            
            if (accountsList == null || accountsList.isEmpty()) {
                System.debug('### No accounts found in consumerCreditData');
                return;
            }
            
            System.debug('### Total accounts found: ' + accountsList.size());
            
            // Deduplicate accounts based on unique key
            Set<String> uniqueKeys = new Set<String>();
            List<Map<String, Object>> uniqueAccounts = new List<Map<String, Object>>();
            
            for (Object accObj : accountsList) {
                Map<String, Object> accountMap = (Map<String, Object>) accObj;
                String uniqueKey = accountMap.get('accountType') + '_' + String.valueOf(accountMap.get('highCreditAmount')) + '_' + accountMap.get('dateOpened');
                
                if (uniqueKeys.add(uniqueKey)) {
                    uniqueAccounts.add(accountMap);
                }
            }
            
            System.debug('### Unique accounts to process: ' + uniqueAccounts.size());
            
            // Prepare Custom Setting map
               Map<String, SObject> productTypeMapRaw = SHF_CommonUtil.getCustomSettingMap('CIBIL_CRIF_Bureau_Product_Type__c');

            String source = (bureau == 'HIGHMARK') ? 'CRIF' : 'CIBIL';
            List<Obligation__c> obligationsToInsert = new List<Obligation__c>();
            
            for (Map<String, Object> accountMap : uniqueAccounts) {
                String accountType = (String) accountMap.get('accountType');
                Decimal highCreditAmount = (Decimal) accountMap.get('highCreditAmount');
                Decimal emiAmount = (Decimal) accountMap.get('emiAmount');
                String accountNumber = (String) accountMap.get('accountNumber');
                String suitFiled = (String) accountMap.get('suitFiled');
                Integer paymentTenure = (Integer) accountMap.get('paymentTenure');
                Decimal currentBalance = (Decimal) accountMap.get('currentBalance');
                
                Obligation__c obligation = new Obligation__c();
                obligation.Application__c = applicationId;
                obligation.Sanctioned_Amount__c = highCreditAmount;
                obligation.Source__c = source;
                obligation.EMI__c = emiAmount;
                obligation.Loan_Id__c = accountNumber;
                obligation.Loan_Status__c = suitFiled;
                obligation.Tenor__c = String.valueOf(paymentTenure);
                obligation.Outstanding_Amount__c = currentBalance;
               if (productTypeMapRaw.containsKey(accountType)) {
                // Cast to the correct type
                CIBIL_CRIF_Bureau_Product_Type__c setting = 
                    (CIBIL_CRIF_Bureau_Product_Type__c) productTypeMapRaw.get(accountType);
                obligation.Product__c = setting.Value__c;
            }
                
                obligationsToInsert.add(obligation);
            }
            
            if (!obligationsToInsert.isEmpty()) {
                uow.registerNew(obligationsToInsert);
                uow.commitWork();
                System.debug('### Obligations inserted: ' + obligationsToInsert.size());
            } else {
                System.debug('### No obligations to insert');
            }
            
        } catch (Exception ex) {
            Logger.error('Error in processCIBILResponse: ' + ex.getMessage());        }
    }
    
    
    
}