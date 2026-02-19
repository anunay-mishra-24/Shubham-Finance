public without sharing class SHF_EmailVerificationController {
    
    public Id eVerificationId { get; set; }
    public Boolean isVerified { get; set; }
    public Boolean isExpired { get; set; }
    public String message { get; set; }

    public SHF_EmailVerificationController() {
        eVerificationId = ApexPages.currentPage().getParameters().get('id');
        isVerified = false;
        isExpired = false;
        message = '';

        checkInitialStatus();
    }

    private void checkInitialStatus() {
        try {
            if (String.isBlank(eVerificationId)) {
                message = 'Invalid verification link.';
                isExpired = true;
                return;
            }

            // Get Verification Record
            E_Verification__c eVer = [
                SELECT Id, Loan_Applicant__c, CreatedDate
                FROM E_Verification__c
                WHERE Id = :eVerificationId
                LIMIT 1
            ];

            // Check expiration
            if (Datetime.now() > eVer.CreatedDate.addHours(24)) {
                message = 'This verification link has expired. Please request a new verification email.';
                isExpired = true;
                return;
            }

            // Get applicant
            Loan_Applicant__c applicant = [
                SELECT Id, Is_Email_Address_Verified__c
                FROM Loan_Applicant__c
                WHERE Id = :eVer.Loan_Applicant__c
                LIMIT 1
            ];

            if (applicant.Is_Email_Address_Verified__c == TRUE) {
                message = 'Email is already verified.';
                isVerified = true;
            }

        } catch (Exception ex) {
            message = 'Verification record not found or invalid.';
            isExpired = true;
        }
    }

    public void verifyEmail() {
        try {

            E_Verification__c eVer = [
                SELECT Id, Loan_Applicant__c, Sent_To__c, CreatedDate
                FROM E_Verification__c
                WHERE Id = :eVerificationId
                LIMIT 1
            ];

            Loan_Applicant__c applicant = [
                SELECT Id, Email__c, Is_Email_Address_Verified__c,Email_Verification__c
                FROM Loan_Applicant__c
                WHERE Id = :eVer.Loan_Applicant__c
                LIMIT 1
            ];

            if (applicant.Is_Email_Address_Verified__c == TRUE) {
                message = 'Email is already verified.';
                isVerified = true;
                return;
            }
            
             if (eVer.Id != applicant.Email_Verification__c) {
                message = 'Link is expired.';
                isExpired = true;
                return;
            }

            applicant.Is_Email_Address_Verified__c = TRUE;
            update applicant;

            eVer.Status__c = 'Completed';
            eVer.Sent_To__c = applicant.Email__c;
            update eVer;

            message = 'Email Verified Successfully!';
            isVerified = true;

        } catch (Exception ex) {
            message = 'An error occurred: ' + ex.getMessage();
            isExpired = true;
        }
    }
}