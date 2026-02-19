public without sharing class SHF_FeedbackFormController {
    public String parentId { get; set; }
    public String rating { get; set; }
    public String remark { get; set; }

    public Boolean showForm { get; set; }
    public Boolean showThanks { get; set; }
    public Boolean alreadySubmitted { get; set; }
    public Boolean invalidLink { get; set; }

    private Survey__c surveyRec;

    public SHF_FeedbackFormController() {
        // Get ID from URL
        parentId = ApexPages.currentPage().getParameters().get('id');
        rating   = ApexPages.currentPage().getParameters().get('rating');
        remark   = ApexPages.currentPage().getParameters().get('remark');
        
        // Initialize flags
        showForm = false; 
        showThanks = false; 
        alreadySubmitted = false; 
        invalidLink = false;

        // Validate parentId
        if (String.isBlank(parentId)) {
            invalidLink = true;
            return;
        }

        // Fetch survey
        List<Survey__c> surveyList = [
            SELECT Id 
            FROM Survey__c 
            WHERE Name = 'Case Feedback' 
            LIMIT 1
        ];
        if (surveyList.isEmpty()) {
            invalidLink = true;
            return;
        }
        surveyRec = surveyList[0];

        // Check for existing submission
        Integer existingCount = [
            SELECT COUNT()
            FROM SurveyTaker__c
            WHERE Case__c = :parentId
            AND Survey__c = :surveyRec.Id
        ];

        if (existingCount > 0) {
            alreadySubmitted = true;
        } else {
            showForm = true;
        }
    }
	
    public void submitFeedback() {
        System.debug('>>> submitFeedback method ENTERED');
        try {
            System.debug('>>>Rating'+rating);
            System.debug('--- START submitFeedback ---');
            // Explicitly pull rating & remark from the request parameters
            if (String.isBlank(rating)) {
                rating = ApexPages.currentPage().getParameters().get('rating');
            }
            if (String.isBlank(remark)) {
                remark = ApexPages.currentPage().getParameters().get('remark');
            }
            
            System.debug('>>> Rating after param pull: ' + rating);
            System.debug('>>> Remark after param pull: ' + remark);

            if (String.isBlank(rating)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a star rating.'));
                return;
            }
            
            // Defensive check
            if (surveyRec == null) {
                System.debug('*** surveyRec is NULL ***');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Survey record not found or inaccessible.'));
                return;
            }
            if (surveyRec.Id == null) {
                System.debug('*** surveyRec.Id is NULL ***');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Survey Id not accessible.'));
                return;
            }
            
            System.debug('--- surveyRec.Id accessible: ' + surveyRec.Id);
            
            // Hide form and clear error flags
            showForm = false;
            alreadySubmitted = false;
            invalidLink = false;
            
            System.debug('--- Creation SurveyTaker Begin ---');
            // Create SurveyTaker
            SurveyTaker__c taker = new SurveyTaker__c();
            System.debug('--- Assign Values in taker ---');
            taker.Survey__c = surveyRec.Id;
            taker.Completed__c = true;
            System.debug('--- User allocation ---');
            //taker.User__c = System.UserInfo.getUserId(); // Guest will have Site Guest User Id
            System.debug('--- User allocated ---');

            if (parentId.startsWith('500')) {
                taker.Case__c = parentId;
                System.debug('--- Case Linked to Taker ---');
            }

            System.debug('>>> Inserting SurveyTaker: ' + taker);
            insert taker;
            System.debug('>>> Inserted SurveyTaker ID: ' + taker.Id);

            // Create Question Responses
            List<Survey_Question__c> questions = [
                SELECT Id, Question__c
                FROM Survey_Question__c
                WHERE Survey__c = :surveyRec.Id
            ];

            List<SurveyQuestionResponse__c> responses = new List<SurveyQuestionResponse__c>();
            for (Survey_Question__c q : questions) {
                SurveyQuestionResponse__c resp = new SurveyQuestionResponse__c();
                resp.Survey_Question__c = q.Id;
                resp.SurveyTaker__c = taker.Id;

                if (q.Question__c == 'Please rate your experience (1 to 5 stars)') {
                    resp.Response__c = rating;
                } else if (q.Question__c == 'Remarks (if any)') {
                    resp.Response__c = remark;
                }
                responses.add(resp);
            }

            if (!responses.isEmpty()) {
                System.debug('>>> Inserting ' + responses.size() + ' SurveyQuestionResponse records');
                insert responses;
            }

            // Mark case as feedback filled (for duplicate prevention)
            if (parentId.startsWith('500')) {
                Case c = new Case(Id = parentId);
                c.Feedback_Filled__c = true;
                c.Feedback_Rating__c = Decimal.valueOf(rating);
                update c;
            }

            // Show Thank You (set here immediately)
            showThanks = true;
            showForm = false;

        } catch (Exception e) {
            System.debug('***** FEEDBACK DML ERROR: ' + e.getMessage() + ' | ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while saving feedback: ' + e.getMessage()));
            showForm = true;
        }
    }
}