/**
* @File Name          : SHF_FeedbackFormControllerTest.cls
* @Description        : test class to cover SHF_FeedbackFormController.
* @Author             : Kunal Soni
* 
* ==============================================================================
* Ver         Date         Author       Modification
* ==============================================================================
* 1.0         21-08-2025   Kunal Soni   Initial Version
*/
@IsTest
public class SHF_FeedbackFormControllerTest {

    // Utility method to create base data
    private static Id setupSurveyData() {
        Survey__c survey = new Survey__c(Name = 'Case Feedback');
        insert survey;

        Survey_Question__c q1 = new Survey_Question__c(
            Name = 'Q1',
            Survey__c = survey.Id,
            Question__c = 'Please rate your experience (1 to 5 stars)',
            OrderNumber__c = 1
        );
        Survey_Question__c q2 = new Survey_Question__c(
            Name = 'Q2',
            Survey__c = survey.Id,
            Question__c = 'Remarks (if any)',
            OrderNumber__c = 2
        );
        insert new List<Survey_Question__c>{q1, q2};

        return survey.Id;
    }

    @IsTest
    static void testInvalidLink_NoId() {
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/DummyPage'); 
        Test.setCurrentPage(pageRef);

        SHF_FeedbackFormController ctrl = new SHF_FeedbackFormController();
        System.assertEquals(true, ctrl.invalidLink, 'Should mark invalidLink if no id param');
        Test.stopTest();
    }

    @IsTest
    static void testAlreadySubmitted() {
        Id surveyId = setupSurveyData();
        Case c = new Case(Subject = 'Test Case');
        insert c;

        insert new SurveyTaker__c(
            Survey__c = surveyId,
            Case__c = c.Id,
            Completed__c = true
        );

        PageReference pageRef = new PageReference('/apex/DummyPage');
        pageRef.getParameters().put('id', c.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        SHF_FeedbackFormController ctrl = new SHF_FeedbackFormController();
        Test.stopTest();

        System.assertEquals(true, ctrl.alreadySubmitted, 'Should detect already submitted');
    }

    @IsTest
    static void testShowForm_NewFeedback() {
        Id surveyId = setupSurveyData();
        Case c = new Case(Subject = 'Fresh Case');
        insert c;

        PageReference pageRef = new PageReference('/apex/DummyPage');
        pageRef.getParameters().put('id', c.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        SHF_FeedbackFormController ctrl = new SHF_FeedbackFormController();
        Test.stopTest();

        System.assertEquals(true, ctrl.showForm, 'Form should be shown for new feedback');
    }

    @IsTest
    static void testSubmitFeedback_Success() {
        Id surveyId = setupSurveyData();
        Case c = new Case(Subject = 'Feedback Case');
        insert c;

        PageReference pageRef = new PageReference('/apex/DummyPage');
        pageRef.getParameters().put('id', c.Id);
        pageRef.getParameters().put('rating', '5');
        pageRef.getParameters().put('remark', 'Great support!');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        SHF_FeedbackFormController ctrl = new SHF_FeedbackFormController();
        ctrl.rating = '5';
        ctrl.remark = 'Great support!';
        ctrl.submitFeedback();
        Test.stopTest();

        System.assertEquals(true, ctrl.showThanks, 'Should show thanks after submission');

        // Verify SurveyTaker created
        SurveyTaker__c taker = [SELECT Id, Case__c FROM SurveyTaker__c LIMIT 1];
        System.assertEquals(c.Id, taker.Case__c);

        // Verify Case updated
        Case updatedCase = [SELECT Feedback_Filled__c, Feedback_Rating__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(true, updatedCase.Feedback_Filled__c);
        System.assertEquals(5, Integer.valueOf(updatedCase.Feedback_Rating__c));
    }

    @IsTest
    static void testSubmitFeedback_NoRating() {
        Id surveyId = setupSurveyData();
        Case c = new Case(Subject = 'Case Without Rating');
        insert c;

        PageReference pageRef = new PageReference('/apex/DummyPage');
        pageRef.getParameters().put('id', c.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        SHF_FeedbackFormController ctrl = new SHF_FeedbackFormController();
        ctrl.rating = null;
        ctrl.remark = 'Missing rating test';
        ctrl.submitFeedback();
        Test.stopTest();

        System.assertEquals(true, ctrl.showForm, 'Form should remain if rating missing');
    }
}