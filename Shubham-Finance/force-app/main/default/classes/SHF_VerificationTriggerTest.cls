/**
* @File Name : SHF_VerificationTriggerTest.cls
* @Description :
* @Author : Anand
* @Last Modified By :
* @Last Modified On : December 30, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 30, 2025 |   | Initial Version
**/

@isTest
private class SHF_VerificationTriggerTest {

    @isTest
    static void testVerificationTrigger() {

        Application__c application = SHF_TestDataFactory.createApplication('Test Application', true);
        
        Verification__c verificationObj = SHF_TestDataFactory.createVerification(application.Id, null, 'Sampled', 'Document', null, false);
        verificationObj.FCU_Manager_Decision__c = 'Negative';
        insert verificationObj;

        Test.startTest();

        verificationObj.FCU_Manager_Decision__c = 'RCU Failed';
        update verificationObj;

        Test.stopTest();

        Verification__c updatedVerification = [SELECT Id, FCU_Manager_Decision__c FROM Verification__c WHERE Id = :verificationObj.Id LIMIT 1];
        System.assertEquals(verificationObj.FCU_Manager_Decision__c, updatedVerification.FCU_Manager_Decision__c, 'FCU Manager Decision should be updated to RCU Failed');
    }
}