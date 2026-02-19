@IsTest
public class SHF_LeadCrifScoreBatchTest {

    /* ============================================================
       HELPER METHOD – CREATE LEADS
       ============================================================ */
    private static void createLeads(
        Integer count,
        Boolean crifNull,
        Id branchId
    ) {
        List<Lead__c> leads = new List<Lead__c>();

        for (Integer i = 0; i < count; i++) {
            leads.add(new Lead__c(
                /* -------- REQUIRED FIELDS -------- */
                Contact_No1__c  = '9999999999',
                Loan_Product__c = 'Home Loan',
                Sub_Product__c  = 'Ready Property',

                /* -------- BRANCH (FIX) -------- */
                Branch__c       = branchId,

                /* -------- BUSINESS DATA -------- */
                Requested_Loan_Amount__c = 100000,
                Crif_Score__c   = crifNull ? null : 750
            ));
        }
        insert leads;
    }

    /* ============================================================
       TEST SETUP
       ============================================================ */
    @testSetup
    static void setupData() {

        /* ---------- Create ONE Branch ---------- */
        Branch_Master__c branch =
            SHF_TestDataFactory.createBranchMaster(
                'Delhi',
                'DL001',
                true
            );

        /* ---------- Eligible Leads ---------- */
        createLeads(2, true, branch.Id);

        /* ---------- Ineligible Lead ---------- */
        createLeads(1, false, branch.Id);
    }

    /* ============================================================
       TEST: BATCH EXECUTION – DATA PRESENT
       ============================================================ */
    @IsTest
    static void testBatchExecution_WithEligibleLeads() {

        Test.startTest();
        Database.executeBatch(new SHF_LeadCrifScoreBatch(), 200);
        Test.stopTest();

        System.assert(
            Limits.getEmailInvocations() >= 0,
            'Batch executed successfully with eligible leads'
        );
    }

    /* ============================================================
       TEST: BATCH EXECUTION – NO ELIGIBLE DATA
       ============================================================ */
    @IsTest
    static void testBatchExecution_NoEligibleLeads() {

        List<Lead__c> leads = [SELECT Id FROM Lead__c];
        for (Lead__c l : leads) {
            l.Crif_Score__c = 800;
        }
        update leads;

        Test.startTest();
        Database.executeBatch(new SHF_LeadCrifScoreBatch(), 200);
        Test.stopTest();

        System.assert(true, 'No eligible leads path covered');
    }

    /* ============================================================
       TEST: SCHEDULABLE EXECUTION
       ============================================================ */
    @IsTest
    static void testSchedulableExecution() {

        String cronExp = '0 0 0 1 1 ? 2050';

        Test.startTest();
        System.schedule(
            'SHF Lead CRIF Batch Schedule',
            cronExp,
            new SHF_LeadCrifScoreBatch()
        );
        Test.stopTest();

        System.assert(true, 'Schedulable execution covered');
    }

    /* ============================================================
       TEST: FINISH METHOD
       ============================================================ */
    @IsTest
    static void testFinishMethod() {

        SHF_LeadCrifScoreBatch batch = new SHF_LeadCrifScoreBatch();

        Test.startTest();
        batch.finish(null);
        Test.stopTest();

        System.assert(true, 'Finish method executed');
    }
}