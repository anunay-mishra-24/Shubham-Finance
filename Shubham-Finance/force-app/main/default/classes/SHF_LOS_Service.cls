public class SHF_LOS_Service {
    
     @future(callout=true)
    public static void processMobileVerificationFuture(Id applicantId, String mobile) {
        try {
            List<Loan_Applicant__c> loanAppList = new LoanApplicantsSelector().selectById(new Set<Id>{applicantId});
            if (!loanAppList.isEmpty()) {
               // SHF_Mobile_MNRL_Service.processMobileVerification(mobile, loanAppList[0]);
            } else {
                Logger.error('No Loan Applicant found for Id: ' + applicantId);
            }
        } catch (Exception ex) {
            Logger.error('Future Mobile Verification Error: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }
    }

}