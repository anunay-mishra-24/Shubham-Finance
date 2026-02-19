@IsTest
public class EmailMessageTriggerTest {

    @IsTest
    static void testEmailReplyOnResolvedCaseCreatesNewCase() {

        // 1. Create Account
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        // 2. Create Case with Status = New (as per validation rule)
        Case caseNew = new Case(
            AccountId = acc.Id,
            Status = 'New',
            Origin = 'Email',
            Subject = 'Initial Case'
        );
        insert caseNew;

        // 3. Update Case to Resolved
        caseNew.Status = 'Resolved';
        update caseNew;

        // 4. Create EmailMessage on resolved Case
        EmailMessage email = new EmailMessage(
            ParentId = caseNew.Id,
            Subject = 'Customer Reply',
            TextBody = 'Customer replied after case was resolved',
            FromAddress = 'customer@test.com',
            ToAddress = 'support@test.com',
            Incoming = true,
            Status = '0'
        );

        Test.startTest();
        insert email;   // 🔥 Trigger executes here
        Test.stopTest();
    }

    @IsTest
    static void testEmailOnOpenCase_NoNewCaseCreated() {

        Account acc = new Account(Name = 'Test Account 2');
        insert acc;

        // Case remains New
        Case openCase = new Case(
            AccountId = acc.Id,
            Status = 'New',
            Origin = 'Email',
            Subject = 'Open Case'
        );
        insert openCase;

        EmailMessage email = new EmailMessage(
            ParentId = openCase.Id,
            Subject = 'Reply on open case',
            TextBody = 'Still working on this',
            FromAddress = 'customer@test.com',
            ToAddress = 'support@test.com',
            Incoming = true,
            Status = '0'
        );

        Test.startTest();
        insert email;
        Test.stopTest();
    }

    @IsTest
    static void testBulkEmailMessages() {

        Account acc = new Account(Name = 'Bulk Account');
        insert acc;

        // Create Case as New
        Case bulkCase = new Case(
            AccountId = acc.Id,
            Status = 'New',
            Origin = 'Email',
            Subject = 'Bulk Case'
        );
        insert bulkCase;

        // Update to Resolved
        bulkCase.Status = 'Resolved';
        update bulkCase;

        List<EmailMessage> emails = new List<EmailMessage>();

        for (Integer i = 0; i < 5; i++) {
            emails.add(new EmailMessage(
                ParentId = bulkCase.Id,
                Subject = 'Bulk Reply ' + i,
                TextBody = 'Bulk email body ' + i,
                FromAddress = 'customer@test.com',
                ToAddress = 'support@test.com',
                Incoming = true,
                Status = '0'
            ));
        }

        Test.startTest();
        insert emails;
        Test.stopTest();
    }
}