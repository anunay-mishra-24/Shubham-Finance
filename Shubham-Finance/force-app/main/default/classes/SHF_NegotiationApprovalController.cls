/**
* @File Name          : SHF_NegotiationApprovalController.cls
* @Description        :  Apex Controller for handling negotiation approval submissions.
* @Author             : Anunay Kumar
* @Created Date        : 2026-01-08
* @Last Modified Date  : 2026-01-08
*
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         2026-01-08           Anunay Kumar         Initial Version
* 1.1         2026-01-08           Author Name         Change details
*/

public without sharing class SHF_NegotiationApprovalController {
    
    @AuraEnabled
    public static String callNegotiationApproval(String applicationId) {
        if(applicationId == null) return 'error';
        //JSON creator
        JSONGenerator gen = JSON.createGenerator(true);
        List<Application__c> appList = new list<Application__c>();
        Application__c appInstance = new Application__c();
        appInstance.Id = applicationId;
        Boolean isApprovalForCBO = false;
        String msg = '';
        List<Activity_History__c > actHistoryList = new list<Activity_History__c>();
        try{
            Application__c applicationDetail = new SHF_ApplicationSelector().selectApplicationForCIBIL(applicationId);
            List<Loan_Applicant__c> applicantList =new  SHF_LoanApplicantsSelector().selectByIdWithLoanApplication(new Set<Id> {applicationId});
            System.debug('applicantList > ' + applicantList);
            if(!applicantList.isEmpty()){
                
                gen.writeStartObject();
                
                // Application
                gen.writeFieldName('applicationDetail');
                gen.writeStartObject();
                gen.writeStringField('Id', applicationDetail.Id);
                gen.writeStringField('Negotiation Sanctioned Loan Amount', applicationDetail.Negotiate_Sanctioned_Loan_Amount__c != null ? String.valueOf(applicationDetail.Negotiate_Sanctioned_Loan_Amount__c) : '');
                gen.writeStringField('Negotiation Tenure', applicationDetail.Negotiate_Tenure__c != null ? String.valueOf(applicationDetail.Negotiate_Tenure__c) : '');
                gen.writeStringField('Negotiation Processing Fee', applicationDetail.Negotiation_Processing_Fee__c != null ? String.valueOf(applicationDetail.Negotiation_Processing_Fee__c) : '');
                gen.writeStringField('Negotiation Processing Fee Percent',applicationDetail.Negotiation_Processing_Fee_Percent__c != null ? String.valueOf(applicationDetail.Negotiation_Processing_Fee_Percent__c) : '');
                gen.writeStringField('Negotiation Rate of Interest ROI',applicationDetail.Negotiation_Rate_of_Interest_ROI__c != null ? String.valueOf(applicationDetail.Negotiation_Rate_of_Interest_ROI__c) : '');
                gen.writeStringField('Original Processing Fee', applicationDetail.Processing_Fee__c != null ? String.valueOf(applicationDetail.Processing_Fee__c) : '');
                gen.writeStringField('Original Processing Fee Percent', applicationDetail.Processing_Fee_percent__c != null ? String.valueOf(applicationDetail.Processing_Fee_percent__c) : '');
                gen.writeStringField('Original ROI', applicationDetail.Revised_Rate__c != null ? String.valueOf(applicationDetail.Revised_Rate__c) : '');
                gen.writeStringField('Original Sanctioned Loan Amount',applicationDetail.Sanction_Amount__c != null ? String.valueOf(applicationDetail.Sanction_Amount__c) : '');
                gen.writeStringField('Original Tenure', applicationDetail.Tenure__c != null ? String.valueOf(applicationDetail.Tenure__c) : '');
                gen.writeStringField('RFC Processing Fee Percent ', applicationDetail.Processing_Fee_Percent_Reason_For_Change__c != null ? applicationDetail.Processing_Fee_Percent_Reason_For_Change__c : '');
                gen.writeStringField('RFC Processing Fee ', applicationDetail.Processing_Fee_Reason_For_Change__c != null ? applicationDetail.Processing_Fee_Reason_For_Change__c : '');
                gen.writeStringField('RFC ROI',applicationDetail.ROI_Reason_for_Change__c != null ? applicationDetail.ROI_Reason_for_Change__c : '');
                gen.writeStringField('RFC Sanctioned Loan Amount',applicationDetail.Sanction_Loan_Amount_Reason_for_Change__c != null ? applicationDetail.Sanction_Loan_Amount_Reason_for_Change__c : '');
                gen.writeStringField('RFC Tenure', applicationDetail.Tenure_Reason_for_Change__c != null ? applicationDetail.Tenure_Reason_for_Change__c : '');
                gen.writeEndObject();
                // Application JSON end
               
                // JSON FOR APpllicant
                gen.writeFieldName('applicantsInsurance');
                gen.writeStartArray();
                for(Loan_Applicant__c applicantDetail :applicantList){
                    System.debug('applicapplicantDetail.Insurance_Verification__cantList > ' + applicantDetail.Insurance_Verification__c);
                    if(applicantDetail.Insurance_Verification__c != null && applicantDetail.RecordType_Name__c == SHF_ConstantsUtil.INDIVIDUAL ){
                        system.debug('llllllll ' + applicantDetail.Insurance_Verification__r);
                        gen.writeStartObject();
                        gen.writeStringField('applicationId', applicantDetail.Id);
                        gen.writeStringField('Name', applicantDetail.Name != null ? applicantDetail.Name : '');
                        gen.writeStringField('Negotiation Insured Amount', applicantDetail.Insurance_Verification__r.Negotiation_Insured_Amount__c != null ? String.valueOf(applicantDetail.Insurance_Verification__r.Negotiation_Insured_Amount__c) : '');
                        gen.writeStringField('Negotiation Insurance Premium',applicantDetail.Insurance_Verification__r.Negotiation_Insurance_Premium__c != null ? String.valueOf(applicantDetail.Insurance_Verification__r.Negotiation_Insurance_Premium__c) : '');
                        gen.writeStringField('Negotiation Insurance Tenure', applicantDetail.Insurance_Verification__r.Negotiation_Insurance_Tenure__c != null ? String.valueOf(applicantDetail.Insurance_Verification__r.Negotiation_Insurance_Tenure__c) : '');
                        gen.writeStringField('Original Insurance Premium', applicantDetail.Insurance_Verification__r.Premium_Amount__c != null ? String.valueOf(applicantDetail.Insurance_Verification__r.Premium_Amount__c) : '');

                        if (applicantDetail.Insurance_Verification__r.Insurance_Provider__c.containsIgnoreCase('Kotak')) {
                             gen.writeStringField('Original Insurance Tenure', String.valueOf(applicantDetail.Insurance_Verification__r.Loan_Tenure_In_Years__c));
                        } else if (applicantDetail.Insurance_Verification__r.Insurance_Provider__c.containsIgnoreCase('ICICI')) {
                             gen.writeStringField('Original Insurance Tenure', String.valueOf(applicantDetail.Insurance_Verification__r.Outstanding_Loan_Tenure__c));
                        } else {
                             gen.writeStringField('Original Insurance Tenure', '');
                        }
                       // gen.writeStringField('Original Insurance Tenure', applicantDetail.Insurance_Verification__r.Outstanding_Loan_Tenure__c != null ? String.valueOf(applicantDetail.Insurance_Verification__r.Outstanding_Loan_Tenure__c) : (applicantDetail.Insurance_Verification__r.Loan_Tenure_In_Years__c != null ? String.valueOf(applicantDetail.Insurance_Verification__r.Loan_Tenure_In_Years__c) : ''));
                        gen.writeStringField('Original Insured Amount',applicantDetail.Insurance_Verification__r.Insured_Amount__c != null ? String.valueOf(applicantDetail.Insurance_Verification__r.Insured_Amount__c) : '');
                        gen.writeStringField('RFC Insured Amount',applicantDetail.Insurance_Verification__r.Insurance_Amount_Reason_for_Change__c != null ? applicantDetail.Insurance_Verification__r.Insurance_Amount_Reason_for_Change__c : '');
                        gen.writeStringField('RFC Insurance Premium', applicantDetail.Insurance_Verification__r.Insurance_Premium_Reason_for_Change__c != null ? String.valueOf(applicantDetail.Insurance_Verification__r.Insurance_Premium_Reason_for_Change__c) : '');
                        gen.writeStringField('RFC Insurance Tenure', applicantDetail.Insurance_Verification__r.Insurance_Tenure_Reason_for_Change__c != null ? applicantDetail.Insurance_Verification__r.Insurance_Tenure_Reason_for_Change__c : '');
                        gen.writeEndObject();
                        
                        System.debug('1  > ' + applicantDetail.Insurance_Verification__r.Negotiation_Insurance_Premium__c);
                        System.debug('2  > ' + applicantDetail.Insurance_Verification__r.Negotiation_Insured_Amount__c);
                        System.debug('3  > ' + applicantDetail.Insurance_Verification__r.Negotiation_Insurance_Tenure__c);
                        if(applicantDetail.Insurance_Verification__r.Negotiation_Insurance_Premium__c != null || applicantDetail.Insurance_Verification__r.Negotiation_Insured_Amount__c != null  || applicantDetail.Insurance_Verification__r.Negotiation_Insurance_Tenure__c != null || applicationDetail.Negotiation_Processing_Fee__c != null || applicationDetail.Negotiation_Processing_Fee_Percent__c != null || applicationDetail.Negotiation_Rate_of_Interest_ROI__c != null){
                            System.debug('isApprovalForCBO  > ' + isApprovalForCBO);
                            isApprovalForCBO = true;
                        }
                    }
                }
                gen.writeEndArray(); //end Applicant JSON
                gen.writeEndObject();
                
            }
            String jsonData = gen.getAsString();
            if(applicationDetail.Negotiate_Tenure__c != null || applicationDetail.Negotiate_Sanctioned_Loan_Amount__c != null){
                
                //Availability check for last sanctioned user
                if(applicationDetail.Credit_Sanction_Approved_By__c == null) return 'unavailableCreditSanctionUser';
                User user = [SELECT IsActive,ManagerId FROM User WHERE Id = :applicationDetail.Credit_Sanction_Approved_By__c];
                String lastSanctionUserManagerId = user != null ? (user.ManagerId != null ? user.ManagerId : null) : null;
                String  lastSanctionUserId  = user.IsActive == true ? user.Id : lastSanctionUserManagerId;
                //UPDATE Application details
                appInstance.Re_Sanction_Status__c = SHF_ConstantsUtil.PENDING;
                appInstance.Negotiation_Last_BM_Owner__c = UserInfo.getUserId(); // current loggedin User Id
                appInstance.IsSendBackFromPreDisbursement__c = true;
                appInstance.RecordTypeId = SHF_ConstantsUtil.APPLICATION_CREDIT_EVALUATION_RECORD_TYPE;
                appInstance.Application_Stage__c =SHF_ConstantsUtil.DDE;
                appInstance.CAM_Generation_Date_Time__c =null;
                appInstance.Application_Status__c = SHF_ConstantsUtil.ACTIVE_STATUS;
                appInstance.OwnerId = lastSanctionUserId ; 
                
                //Activity Hostory creation
                Activity_History__c actInstance = new Activity_History__c ();
                actInstance.Application__c  = applicationDetail.Id;
                actInstance.Committee_Approval_Status__c   = SHF_ConstantsUtil.PENDING;
                actInstance.RecordTypeId    =SHF_ConstantsUtil.ACTIVITY_HISTORY_FOR_Negotiation_RECORDTYPEID ;
                actInstance.OwnerId    = lastSanctionUserId;
                 actInstance.Approval_for__c    = 'Underwriter';
                actInstance.NegotiationApprovalJson__c    = jsonData;
                actHistoryList.add(actInstance);
            }
            system.debug('isApprovalForCBO > '+ isApprovalForCBO);
            if(isApprovalForCBO){
                // LOGIC FOR CBO
                //UPDATE UPLICATION DETAILs
                appInstance.CBO_Approval_Status__c = SHF_ConstantsUtil.PENDING;
                
                //CREATE ACTIVITY HISTORY RECORD 
                Activity_History__c actInstance1 = new Activity_History__c ();
                actInstance1.Application__c  = applicationDetail.Id;
                actInstance1.Committee_Approval_Status__c   = SHF_ConstantsUtil.PENDING;
                actInstance1.RecordTypeId    =SHF_ConstantsUtil.ACTIVITY_HISTORY_FOR_Negotiation_RECORDTYPEID ;
                String cboUserID = getCBOUser(applicationDetail.OwnerId);
                IF(cboUserID == NULL || cboUserID == '')
                    return 'unavailableCBO';
                system.debug('cboUserID > ' + cboUserID);
                actInstance1.OwnerId    = cboUserID;
                 actInstance1.Approval_for__c    = 'CBO';
                actInstance1.NegotiationApprovalJson__c    = jsonData;
                actHistoryList.add(actInstance1);
                
            }
            appList.add(appInstance);
            system.debug('actHistoryList > ' + actHistoryList);
            system.debug('appList > ' + appList);
            if(!actHistoryList.isEmpty())
                insert actHistoryList;
            if(!appList.isEmpty())
                update appList;
            msg = 'success';
        }catch(exception ex){
            system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
            msg = 'error > ' + ex.getMessage()+' Line:- '+ ex.getlineNumber();
        }
        return msg;
    }
    
    public static String getCBOUser(String rmUserId){
        if (rmUserId == null) return '';
        system.debug('rmUserId> ' + rmUserId);
        Map<Id, User> users = new Map<Id, User>([ SELECT Id, Name, ManagerId, UserRole.Name FROM User WHERE Profile.Name = :SHF_ConstantsUtil.SALES_PROFILE]);
        Set<Id> visited = new Set<Id>();
        Id currentId = rmUserId;
        while (currentId != null && !visited.contains(currentId)) {
            visited.add(currentId);
            
            User u = users.get(currentId);
            if (u == null) break;
            
            if (u.UserRole != null &&  u.UserRole.Name != null && u.UserRole.Name.containsIgnoreCase(SHF_ConstantsUtil.CBO)) {
                system.debug('rmUserId22> ' + u);
                return u.Id;
            }
            
            currentId = u.ManagerId;
        }
        
        return null;
    }  
     @AuraEnabled(cacheable=true)
    public static Activity_History__c getActivity(Id recordId) {
        if(recordId == null ) return null;
        return [
            SELECT
                NegotiationApprovalJson__c,
                Owner.Profile.Name
            FROM Activity_History__c
            WHERE Id = :recordId];
    }
        
}