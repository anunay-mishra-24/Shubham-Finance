/**
* @File Name : SHF_RetriggerInvocable.cls
* @Description :
* @Author :
* @Last Modified By : Gaurav Kumar
* @Last Modified On : 12-09-2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 9, 2025 |   | Initial Version
**/

public class SHF_RetriggerInvocable {
    public class Request {
        //added by mansur alam
         @InvocableVariable
        public Document__c  oldDocRecord;
        @InvocableVariable
        public Document__c  newDocRecord;
         @InvocableVariable
        public Address__c oldAddRecord;
        @InvocableVariable
        public Address__c newAddRecord;
         @InvocableVariable
        public Collateral__c   oldCollRecord;
        @InvocableVariable
        public Collateral__c   newCollRecord;
        // Gaurav Kumar        
        @InvocableVariable
        public Application__c oldApplicationRecord;
        @InvocableVariable
        public Application__c newApplicationRecord;

        @InvocableVariable
        public Bank_Details__c oldBankDetailsRecord;
        @InvocableVariable
        public Bank_Details__c newBankDetailsRecord;

        @InvocableVariable
        public Deviation_and_Sanction_Condition__c oldDeviationRecord;
        @InvocableVariable
        public Deviation_and_Sanction_Condition__c newDeviationRecord;
        
        @InvocableVariable
        public E_Verification__c oldEVerificationRecord;
        @InvocableVariable
        public E_Verification__c newEVerificationRecord;

        @InvocableVariable
        public Employment__c oldEmploymentRecord;
        @InvocableVariable
        public Employment__c newEmploymentRecord;      
        
        @InvocableVariable
        public Loan_Applicant__c oldLoanApplicantRecord;
        @InvocableVariable
        public Loan_Applicant__c newLoanApplicantRecord;

        @InvocableVariable
        public Obligation__c oldObligationRecord;
        @InvocableVariable
        public Obligation__c newObligationRecord;

        @InvocableVariable
        public Personal_Discussion__c oldPersonalDiscussionRecord;
        @InvocableVariable
        public Personal_Discussion__c newPersonalDiscussionRecord;
        
        @InvocableVariable
        public VAP__c oldVapRecord;
        @InvocableVariable
        public VAP__c newVapRecord;
        
        // @InvocableVariable
        // public SObject oldRecord;
        // @InvocableVariable
        // public SObject newRecord;
        // Gaurav Kumar
        
        @InvocableVariable
        public Id applicationId;
        
        @InvocableVariable(required=true)
        public String objectName;
        
        @InvocableVariable(required=true)
        public String fieldToBeUpdated;
        
        @InvocableVariable(required=true)
        public String applicableFor;
        
        // Gaurav Kumar
        public Map<String, SObject> getOldMap() {
            Map<String, SObject> m = new Map<String, SObject>();
            m.put('VAP__c', oldVapRecord);
            m.put('Application__c', oldApplicationRecord);
            m.put('Loan_Applicant__c', oldLoanApplicantRecord);
            m.put('E_Verification__c', oldEVerificationRecord);
            m.put('Deviation_and_Sanction_Condition__c', oldDeviationRecord);
            m.put('Bank_Details__c', oldBankDetailsRecord);
            m.put('Personal_Discussion__c', oldPersonalDiscussionRecord);
            m.put('Employment__c', oldEmploymentRecord);
            m.put('Obligation__c', oldObligationRecord);
             m.put('Document__c', oldDocRecord);
            m.put('Collateral__c', oldCollRecord);
            m.put('Address__c', oldAddRecord);
            return m;
        }
        public Map<String, SObject> getNewMap() {
            Map<String, SObject> m = new Map<String, SObject>();
            m.put('VAP__c', newVapRecord);
            m.put('Application__c', newApplicationRecord);
            m.put('Loan_Applicant__c', newLoanApplicantRecord);
            m.put('E_Verification__c', newEVerificationRecord);
            m.put('Deviation_and_Sanction_Condition__c', newDeviationRecord);
            m.put('Bank_Details__c', newBankDetailsRecord);
            m.put('Personal_Discussion__c', newPersonalDiscussionRecord);
            m.put('Employment__c', newEmploymentRecord);
            m.put('Obligation__c', newObligationRecord);
            m.put('Document__c', newDocRecord);
            m.put('Collateral__c', newCollRecord);
            m.put('Address__c', newAddRecord);
            return m;
        }
        // Gaurav Kumar
    }
    
    @InvocableMethod(label='SHF_RetriggerInvocable')
    public static void compareValues(List<Request> requests) {
        List<SObject> appList = new List<SObject>();
        
        // Gaurav Kumar
        List<Re_Trigger_Field_Detail__mdt> metaList = new List<Re_Trigger_Field_Detail__mdt>();
        for (Re_Trigger_Field_Detail__mdt m : Re_Trigger_Field_Detail__mdt.getAll().values()) {
            if (m.Object_Name__c == requests[0].objectName && m.Applicable_For__c == requests[0].applicableFor) {
                metaList.add(m);
                break;
            }
        }

        if(metaList.isEmpty()) {
            return;
        }
        Set<Id> addedAppIds = new Set<Id>();
        Map<String, List<String>> metaMap = new Map<String, List<String>>();
        // metaMap.put(metaList[0].Object_Name__c,metaList[0].Field_API_Name__c.split(','));
        for(Re_Trigger_Field_Detail__mdt m : metaList){
            if (!metaMap.containsKey(m.Object_Name__c)) {
                metaMap.put(m.Object_Name__c, new List<String>());
            }
            for (String fieldName : m.Field_API_Name__c.split(',')) {
                metaMap.get(m.Object_Name__c).add(fieldName.trim());
            }
        }
        System.debug('metaMap'+metaMap);
        list<string> applicableforName = system.label.Eligibility_Flag.split(',');
        for (Request req : requests) {
            SObject oldRec = req.getOldMap().get(req.objectName);
            SObject newRec = req.getNewMap().get(req.objectName);
            
            for(String metadata : metaMap.get(req.objectName)){
                System.debug('metadata'+metadata);
                if(newRec.get(metadata) != oldRec.get(metadata)){
                    if (req.applicationId.getSObjectType() == Application__c.SObjectType) {                    
                        if (!addedAppIds.contains(req.applicationId)) {
                            Application__c app = new Application__c(Id = req.applicationId);
                            app.put(req.fieldToBeUpdated, null);
                            appList.add(app);
                            addedAppIds.add(req.applicationId);
                        }
                    }else if(req.applicationId.getSObjectType() == Loan_Applicant__c.SObjectType){
                        Loan_Applicant__c app = new Loan_Applicant__c(Id = req.applicationId);
                        if(applicableforName.size() > 0 && applicableforName.contains(req.applicableFor)){
                            app.put(req.fieldToBeUpdated, false);
                            appList.add(app);
                            addedAppIds.add(req.applicationId);
                        }
                    }
                    break;
                }
            }
            //Gaurav Kumar
        }
        if(appList != null && appList.size() > 0){             
            Database.SaveResult[] results = Database.update(appList, false); // Gaurav Kumar
        }
    }
}