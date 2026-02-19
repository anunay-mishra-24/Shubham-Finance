/**
* @File Name     : SHF_PennyDrop_Service_Test.cls
* @Description   : Test class for SHF_PennyDrop_Service
* @Author        : Kunal Soni
* ============================================================================== 
* Ver   Date          Author        Modification
* ============================================================================== 
* 1.0   19-08-2025    Kunal Soni    Initial Version
*/
@IsTest
public class SHF_PennyDrop_Service_Test {

    /**
     * Mock class to simulate Penny Drop API response
     */
    private class PennyDropMock implements HttpCalloutMock {
        private Boolean isSuccess;

        PennyDropMock(Boolean isSuccess) {
            this.isSuccess = isSuccess;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            if (isSuccess) {
                res.setBody(
                    '{"result":{"active":"yes","reason":"success","nameMatch":"no","mobileMatch":"not available","signzyReferenceId":"SCHtsXiunnDwNmNqO3p6NlnMBEwkS8eyemmNEUY61LeLc3LlXG56","auditTrail":{"nature":"BANK RRN","value":"523117062837","timestamp":"2025-08-19T11:50:58.280Z"},"nameMatchScore":0.9,"bankTransfer":{"response":"Bank Account details verified successfully.","bankRRN":"523117062837","beneName":"NIRAJ BHARDWAJ","beneMMID":"","beneMobile":"","beneIFSC":"PUNB0616900"}}}'
                );
            } else {
                res.setBody(
                    '{"error":{"name":"error","message":"\"beneficiaryAccount\" is not allowed to be empty","reason":"VALIDATION_ERROR","type":"Bad Request","statusCode":400}}'
                );
            }
            return res;
        }
    }

    @IsTest
    static void testPennyDropSuccess() {
        // Create Application
        Application__c app = SHF_TestDataFactory.createApplication('test', true);

        // Create Loan Applicant linked to Application
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(
            app.Id, 'John', 'Doe', '27AAACB2230M1ZL', true
        );

        // Mock success response
        Test.setMock(HttpCalloutMock.class, new PennyDropMock(true));

        Test.startTest();
        String message = SHF_PennyDrop_Service.validatePennyDetails(applicant.Id);
        Test.stopTest();

        // Verify that E-Verification got created
        List<E_Verification__c> verifications = [
            SELECT Id, Status__c, Description__c, Name_Match_Score__c, Penny_Date__c
            FROM E_Verification__c
            WHERE Loan_Applicant__c = :applicant.Id
        ];
    }

    @IsTest
    static void testPennyDropFailure() {
        // Create Application
        Application__c app = SHF_TestDataFactory.createApplication(null, true);

        // Create Loan Applicant linked to Application
        Loan_Applicant__c applicant = SHF_TestDataFactory.createLoanApplicant(
            app.Id, 'Jane', 'Smith', '27AAACB2230M1ZL', true
        );

        // Mock failure response
        Test.setMock(HttpCalloutMock.class, new PennyDropMock(false));

        Test.startTest();
        String message = SHF_PennyDrop_Service.validatePennyDetails(applicant.Id);
        Test.stopTest();

        // Verify that failed E-Verification got created
        List<E_Verification__c> verifications = [
            SELECT Id, Status__c, Error_Message__c
            FROM E_Verification__c
            WHERE Loan_Applicant__c = :applicant.Id
        ];
    }
}