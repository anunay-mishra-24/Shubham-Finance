@IsTest
private class SHF_EmailServices_Test {

    private static Lead__c newLead(Decimal loan, Decimal scoreOpt) {

        Lead__c l = new Lead__c(
            Requested_Loan_Amount__c = loan,
            Contact_No1__c = '9999999999',
            Loan_Product__c = 'Home Loan',      
            Sub_Product__c = 'Home Loan Project'              
        );

        if (scoreOpt != null)
            l.CRIF_Score__c = scoreOpt;

        return l;
    }

    @IsTest
    static void testInboundEmail_UpdatesCrifScore_FromCsv() {

        Lead__c lead1 = newLead(100000, null);
        Lead__c lead2 = newLead(200000, 750);
        insert new List<Lead__c>{ lead1, lead2 };

        String csvData =
            'LeadId,CRIF_Score__c\n' +
            lead1.Id + ',680\n' +
            lead2.Id + ',720\n';

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        Messaging.InboundEmail.BinaryAttachment att = new Messaging.InboundEmail.BinaryAttachment();
        att.fileName = 'scores.csv';
        att.body = Blob.valueOf(csvData);

        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[] { att };

        Test.startTest();
        new SHF_EmailServices().handleInboundEmail(email, env);
        Test.stopTest();

        Map<Id, Lead__c> leadMap = new Map<Id, Lead__c>(
            [SELECT Id, CRIF_Score__c FROM Lead__c WHERE Id IN :new List<Id>{ lead1.Id, lead2.Id }]
        );

        System.assertEquals(680, leadMap.get(lead1.Id).CRIF_Score__c);
        System.assertEquals(750, leadMap.get(lead2.Id).CRIF_Score__c);
    }


    @IsTest
    static void testInboundEmail_NoValidCsv_NoErrors() {

        Lead__c lead1 = newLead(120000, null);
        insert lead1;

        String csvData =
            'AAA,BBB\n' +
            'foo,bar\n';

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        Messaging.InboundEmail.BinaryAttachment att =
            new Messaging.InboundEmail.BinaryAttachment();
        att.fileName = 'bad.csv';
        att.body = Blob.valueOf(csvData);

        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[] { att };

        Test.startTest();
        new SHF_EmailServices().handleInboundEmail(email, env);
        Test.stopTest();

        Lead__c db = [SELECT CRIF_Score__c FROM Lead__c WHERE Id = :lead1.Id];
        System.assertEquals(null, db.CRIF_Score__c);
    }


    @IsTest
    static void testInboundEmail_TextAttachment_Processed() {

        Lead__c lead1 = newLead(150000, null);
        insert lead1;

        String csvData =
            'LeadId,CRIF_Score__c\n' +
            lead1.Id + ',710\n';

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        Messaging.InboundEmail.TextAttachment txt =
            new Messaging.InboundEmail.TextAttachment();
        txt.fileName = 'scores.txt';
        txt.body = csvData;

        email.textAttachments = new Messaging.InboundEmail.TextAttachment[] { txt };

        Test.startTest();
        new SHF_EmailServices().handleInboundEmail(email, env);
        Test.stopTest();

        Lead__c db = [SELECT CRIF_Score__c FROM Lead__c WHERE Id = :lead1.Id];
        System.assertEquals(710, db.CRIF_Score__c);
    }
}