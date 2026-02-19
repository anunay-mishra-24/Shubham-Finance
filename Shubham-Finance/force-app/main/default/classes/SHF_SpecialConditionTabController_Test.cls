/**
* @File Name : SHF_SpecialConditionTabController_Test.cls
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
private class SHF_SpecialConditionTabController_Test {
    
    @testSetup
    static void setupData() {

        Application__c app = SHF_TestDataFactory.createApplication('Test Application', true);
        
        SHF_TestDataFactory.createVerification(app.Id, UserInfo.getUserId(), 'Sampled', 'Document', null, true);
        
        insert new Sanction_Condition_Master__c(
            Type__c = 'Sanction Condition',
        Query_Sub_Cat__c = 'Bank Statement'
            );

        insert new Sanction_Condition_Master__c(
            Type__c = 'Sanction Condition',
        Query_Sub_Cat__c = 'ITR Documents'
            );
    }
    
    @isTest
    static void testCreateSpecialCondition() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Verification__c v = [SELECT Id FROM Verification__c LIMIT 1];
        
        Test.startTest();
        Id newDocId = SHF_SpecialConditionTabController.createSpecialCondition(
            app.Id,
        'Sanction Condition',
        'Condition Description',
        'Test Comment',
        v.Id
            );
        Test.stopTest();
        
        System.assertNotEquals(null, newDocId, 'Document Id should be returned');
        
        Document__c createdDoc = [
            SELECT Id, Type__c, Sanction_Condition_Status__c 
            FROM Document__c WHERE Id = :newDocId
        ];
        
        System.assertEquals('Special Condition', createdDoc.Type__c);
        System.assertEquals('Pending', createdDoc.Sanction_Condition_Status__c);
    }
    
    @isTest
    static void testCreateSpecialCondition_MissingAppId() {
        Boolean exceptionThrown = false;
        try {
            SHF_SpecialConditionTabController.createSpecialCondition(
                null, 'Sanction Condition', 'Desc', 'Comment', null
                );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'AuraHandledException should be thrown for missing Application Id');
    }

    @isTest
    static void testCreateSpecialCondition_Exception() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Boolean exceptionThrown = false;
        try {
            SHF_SpecialConditionTabController.createSpecialCondition(
                app.Id, 'abc', 'Desc', 'Comment', null
                );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'AuraHandledException should be thrown for missing Application Id');
    }
    
    @isTest
    static void testGetSpecialConditions() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Verification__c v = [SELECT Id FROM Verification__c LIMIT 1];
        
        SHF_SpecialConditionTabController.createSpecialCondition(
            app.Id, 'Sanction Condition', 'Fetch Test', 'Fetch Comment', v.Id
            );
        
        Test.startTest();
        List<Document__c> result = SHF_SpecialConditionTabController.getSpecialConditions(app.Id);
        Test.stopTest();
        
        System.assert(!result.isEmpty(), 'At least one document should be returned');
        System.assertEquals('Fetch Comment', result[0].Comment__c);
    }

    @isTest
    static void testGetSpecialConditions_MissingAppId() {
        Boolean exceptionThrown = false;
        try {
            SHF_SpecialConditionTabController.getSpecialConditions(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'AuraHandledException should be thrown for missing Application Id');
    }
    
    @isTest
    static void testUpdateSpecialCondition() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Verification__c v = [SELECT Id FROM Verification__c LIMIT 1];
        
        Id docId = SHF_SpecialConditionTabController.createSpecialCondition(
            app.Id, 'Sanction Condition', 'Old Desc', 'Old Comment', v.Id
            );
        
        Test.startTest();
        SHF_SpecialConditionTabController.updateSpecialCondition(
            docId, 'Sanction Condition', 'New Desc', 'New Comment'
            );
        Test.stopTest();
        
        Document__c updatedDoc = [
            SELECT Type_Of_Condition__c, Condition_Description__c, Comment__c 
            FROM Document__c WHERE Id = :docId
        ];
        
        System.assertEquals('Sanction Condition', updatedDoc.Type_Of_Condition__c);
        System.assertEquals('New Desc', updatedDoc.Condition_Description__c);
        System.assertEquals('New Comment', updatedDoc.Comment__c);
    }

    @isTest
    static void testUpdateSpecialCondition_MissingId() {
        Boolean exceptionThrown = false;
        try {
            SHF_SpecialConditionTabController.updateSpecialCondition(
                null, 'X', 'Y', 'Z'
                );
            System.assert(false, 'Exception expected for missing document Id');
        } catch (AuraHandledException e) {
            exceptionThrown = true;        
        }
        System.assert(exceptionThrown, 'AuraHandledException should be thrown for missing Application Id');
    }

    @isTest
    static void testGetConditionDescriptions() {
        Test.startTest();
        List<String> values = SHF_SpecialConditionTabController.getConditionDescriptions('Sanction Condition');
        Test.stopTest();
        
        System.assertEquals(2, values.size(), 'Should return 2 master entries');
        System.assert(values.contains('Bank Statement'));
        System.assert(values.contains('ITR Documents'));
    }
}