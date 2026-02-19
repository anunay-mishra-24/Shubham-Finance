@IsTest
    private class SHF_Udyam_Registration_Service_Test {
    
        private class ServiceMock implements HttpCalloutMock {
    
            private Boolean isSuccess;
    
            ServiceMock(Boolean isSuccess) {
                this.isSuccess = isSuccess;
            }
    
            public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');
    
                if (isSuccess) {
                    res.setBody(
                        '{"result":{' +
                        '"udyamRegistrationNo":"UDYAM-TEST-123",' +
                        '"dateOfRegistration":"2023-01-01",' +
                        '"profile":{' +
                            '"name":"Test Enterprise",' +
                            '"majorActivity":"Manufacturing",' +
                            '"organizationType":"Private",' +
                            '"ownerName":"Test Owner",' +
                            '"dateOfIncorporation":"2020-01-01",' +
                            '"dateOfCommencement":"2020-02-01"' +
                        '}' +
                    '}}'
                    );
                } else {
                    res.setBody(
                        '{"result":{}}'
                    );
                }
                return res;
            }
        }
    
        @IsTest
        static void testService_Success() {
    
            Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
    
            Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id,'Test','Applicant',null,true);
    
            Test.setMock(HttpCalloutMock.class, new ServiceMock(true));
    
            Test.startTest();
            String response = SHF_Udyam_Registrartion_Service.initiateUdyamRegistration(la.Id,'UDYAM-TEST-123');
            Test.stopTest();
    
            System.assertNotEquals(null,response);
    
            E_Verification__c ev =
               [SELECT Id,
                  Status__c,
                  Is_Udyam_Registration_Verified__c,
                  Loan_Applicant__c
                FROM E_Verification__c
                WHERE Loan_Applicant__c = :la.Id
                LIMIT 1];
    
            System.assertEquals(la.Id,ev.Loan_Applicant__c);
        }
    
        @IsTest
        static void testService_Failure() {
    
            Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
    
            Loan_Applicant__c la = SHF_TestDataFactory.createLoanApplicant(app.Id,'Test','Applicant',null,true);
    
            Test.setMock(HttpCalloutMock.class, new ServiceMock(false));
    
            Test.startTest();
            String response = SHF_Udyam_Registrartion_Service.initiateUdyamRegistration(la.Id,'123');
            Test.stopTest();
    
            System.assertNotEquals(null,response);
    
            E_Verification__c ev =
                [SELECT Id,
                        Status__c,
                        Error_Message__c
                 FROM E_Verification__c
                 WHERE Loan_Applicant__c = :la.Id
                 LIMIT 1];
    
            System.assertNotEquals(null,ev.Error_Message__c);
        }
    
        @IsTest
        static void testService_NoApplicant() {
    
            Test.startTest();
            String result = SHF_Udyam_Registrartion_Service.initiateUdyamRegistration(UserInfo.getUserId(),'UDYAM-TEST-123');
            Test.stopTest();
    
            System.assertEquals(
                null,
                result,
                'Result should be null for invalid applicant'
            );
        }
    }