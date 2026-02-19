@isTest
public class SHF_GetPartnerUserOwnerTest {

    // ----------------------------------------
    // POSITIVE SCENARIO
    // ----------------------------------------
    @isTest
    static void testGetOwnerUser_success() {

        Account acc = new Account(Name = 'Test Partner Account');
        insert acc;

        Contact con = new Contact(LastName = 'Test Contact',AccountId = acc.Id,Email = 'contact@test.com');
        insert con;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            FirstName = 'Partner',
            LastName = 'User',
            Alias = 'puser',
            Email = 'partneruser@test.com',
            Username = 'partneruser' + System.currentTimeMillis() + '@test.com',
            ProfileId = p.Id,
            //ContactId = con.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        SHF_GetPartnerUserOwner.Input input = new SHF_GetPartnerUserOwner.Input();
        input.accountId = acc.Id;

        List<SHF_GetPartnerUserOwner.Input> inputs = new List<SHF_GetPartnerUserOwner.Input>{ input };

        Test.startTest();
        List<SHF_GetPartnerUserOwner.Output> outputs = SHF_GetPartnerUserOwner.getOwnerUser(inputs);
        Test.stopTest();
    }

    // ----------------------------------------
    // NEGATIVE: No Contact
    // ----------------------------------------
    @isTest
    static void testGetOwnerUser_noContact() {

        Account acc = new Account(Name = 'Account Without Contact');
        insert acc;

        SHF_GetPartnerUserOwner.Input input = new SHF_GetPartnerUserOwner.Input();
        input.accountId = acc.Id;

        List<SHF_GetPartnerUserOwner.Output> outputs = SHF_GetPartnerUserOwner.getOwnerUser(new List<SHF_GetPartnerUserOwner.Input>{ input });

        System.assertEquals(0, outputs.size(), 'No user should be returned when no contact exists');
    }

    // ----------------------------------------
    // NEGATIVE: Empty Input
    // ----------------------------------------
    @isTest
    static void testGetOwnerUser_emptyInput() {

        List<SHF_GetPartnerUserOwner.Output> outputs = SHF_GetPartnerUserOwner.getOwnerUser(new List<SHF_GetPartnerUserOwner.Input>());

        System.assertEquals(0, outputs.size(),'No output expected for empty input');
    }
    
}