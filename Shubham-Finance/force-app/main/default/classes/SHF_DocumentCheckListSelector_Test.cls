@IsTest
private class SHF_DocumentCheckListSelector_Test {

    private static String getValidDocumentType() {
        Schema.DescribeFieldResult dfr =
            Document_Checklist__c.Document_Type__c.getDescribe();

        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe.isActive()) {
                return pe.getValue();
            }
        }
        System.assert(false, 'No active picklist value found for Document_Type__c');
        return null;
    }

    @TestSetup
    static void setupData() {

        String validDocType = getValidDocumentType();

        List<Document_Checklist__c> records = new List<Document_Checklist__c>();

        records.add(
            SHF_TestDataFactory.createDocumentChecklist(
                'KYC Documents',
                validDocType,
                'Loan',
                'Mandatory',
                'QDE',
                'Informal Salaried- Cash',
                true
            )
        );

        records.add(
            SHF_TestDataFactory.createDocumentChecklist(
                'Income_Proof__c',
                validDocType,
                'Loan',
                'Mandatory',
                'DDE',
                'Informal Salaried- Cash',
                true
            )
        );

        records.add(
            SHF_TestDataFactory.createDocumentChecklist(
                'Property Documents',
                validDocType,
                'All Applicants',
                'Mandatory',
                'DDE',
                'All Profile',
                true
            )
        );

        records.add(
            SHF_TestDataFactory.createDocumentChecklist(
                'Property Documents',
                validDocType,
                'All Applicants',
                'Mandatory',
                'DDE',
                'Formal Salaried',
                true
            )
        );

        records.add(
            SHF_TestDataFactory.createDocumentChecklist(
                'Loan Specific Documents',
                validDocType,
                'All Applicants',
                'Mandatory',
                'DDE',
                'All Profile',
                false
            )
        );

        records.add(
            SHF_TestDataFactory.createDocumentChecklist(
                'Loan Specific Documents',
                validDocType,
                'All Applicants',
                'Optional',
                'DDE',
                'All Profile',
                true
            )
        );

        insert records;
    }

    @IsTest
    static void test_selectById() {

        Set<Id> ids = new Set<Id>();
        for (Document_Checklist__c d :
            [SELECT Id FROM Document_Checklist__c WHERE Name IN ('KYC Documents','Income Proof')]
        ) {
            ids.add(d.Id);
        }

        SHF_DocumentCheckListSelector selector = new SHF_DocumentCheckListSelector();
        List<Document_Checklist__c> result = selector.selectById(ids);

        System.assertEquals(2, result.size(), 'Both Loan records must be returned');
    }

    @IsTest
    static void test_selectForContext_Loan() {

        SHF_DocumentCheckListSelector selector = new SHF_DocumentCheckListSelector();

        List<Document_Checklist__c> result =
            selector.selectForContext(
                new List<String>{'QDE','DDE'},
                'Loan',
                null
            );

        Set<String> names = new Set<String>();
        for (Document_Checklist__c d : result) names.add(d.Name);

        System.assert(names.contains('KYC Documents'));
        System.assert(names.contains('Income Proof'));
        System.assertEquals(2, result.size(), 'Only Loan documents expected');
    }

    @IsTest
    static void test_selectForContext_AllApplicants_WithProfile() {

        SHF_DocumentCheckListSelector selector = new SHF_DocumentCheckListSelector();

        List<Document_Checklist__c> result =
            selector.selectForContext(
                new List<String>{'DDE'},
                'All Applicants',
                'Formal Salaried'
            );

        Set<String> names = new Set<String>();
        for (Document_Checklist__c d : result) names.add(d.Name);

        System.assert(names.contains('Doc AllProfile'));
        System.assert(names.contains('Doc SpecificProfile'));
        System.assert(!names.contains('Doc Inactive'));
        System.assert(!names.contains('Doc Optional'));
    }

    @IsTest
    static void test_selectForContext_AllApplicants_NoProfile() {

        SHF_DocumentCheckListSelector selector = new SHF_DocumentCheckListSelector();

        List<Document_Checklist__c> result =
            selector.selectForContext(
                new List<String>{'DDE'},
                'All Applicants',
                null
            );

        System.assertEquals(1, result.size(), 'Only All Profile should be returned');
        System.assertEquals('Doc AllProfile', result[0].Name);
    }

    @IsTest
    static void test_selectByCondition() {

        SHF_DocumentCheckListSelector selector = new SHF_DocumentCheckListSelector();

        List<Document_Checklist__c> result =
            selector.selectByCondition('Name = \'KYC Documents\'');

        System.assertEquals(1, result.size());
        System.assertEquals('KYC Documents', result[0].Name);
    }
}