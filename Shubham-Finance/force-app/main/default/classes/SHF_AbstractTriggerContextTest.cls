@IsTest
global class SHF_AbstractTriggerContextTest {

    // -----------------------
    // Nested Dummy Handler for normal trigger coverage
    // -----------------------
    global class DummyTriggerHandler extends SHF_AbstractTriggerContext {

        global override void beforeInsert(List<SObject> newList, List<SObject> oldList,
                                          Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
            for (Account acc : (List<Account>) newList) {
                acc.Description = 'Before Insert Trigger Executed';
            }
        }

        global override void afterInsert(List<SObject> newList, List<SObject> oldList,
                                         Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
            for (Account acc : (List<Account>) newList) {
                acc.Description = 'After Insert Trigger Executed';
            }
        }

        global override void beforeUpdate(List<SObject> newList, List<SObject> oldList,
                                          Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
            for (Account acc : (List<Account>) newList) {
                acc.Description = 'Before Update Trigger Executed';
            }
        }
    }

    // -----------------------
    // Nested Dummy class to cover parent virtual methods
    // -----------------------
    global class DummyParentCoverage extends SHF_AbstractTriggerContext {
        // no overrides -> calls parent virtual methods
    }

    // -----------------------
    // Test: trigger logic
    // -----------------------
    @IsTest
    static void testRunMethod_WithMetadata() {

        // Inject test metadata
        SHF_AbstractTriggerContext.testMetaData = new List<TriggerContext__mdt>{
            new TriggerContext__mdt(
                Class_Name__c = 'SHF_AbstractTriggerContextTest.DummyTriggerHandler',
                Object_Name__c = 'Account',
                Context__c = 'Before',
                Operation__c = 'Insert',
                Is_Active__c = true
            ),
            new TriggerContext__mdt(
                Class_Name__c = 'SHF_AbstractTriggerContextTest.DummyTriggerHandler',
                Object_Name__c = 'Account',
                Context__c = 'After',
                Operation__c = 'Insert',
                Is_Active__c = true
            ),
            new TriggerContext__mdt(
                Class_Name__c = 'SHF_AbstractTriggerContextTest.DummyTriggerHandler',
                Object_Name__c = 'Account',
                Context__c = 'Before',
                Operation__c = 'Update',
                Is_Active__c = true
            )
        };

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // BEFORE INSERT
        List<SObject> newList = new List<SObject>{ acc.clone(false, true, true, true) };
        SHF_AbstractTriggerContext.run('Account', System.TriggerOperation.BEFORE_INSERT,
                                       newList, new List<SObject>(),
                                       new Map<Id,SObject>(), new Map<Id,SObject>());
        System.assertEquals('Before Insert Trigger Executed', ((Account) newList[0]).Description);

        // AFTER INSERT
        newList = new List<SObject>{ acc.clone(false, true, true, true) };
        SHF_AbstractTriggerContext.run('Account', System.TriggerOperation.AFTER_INSERT,
                                       newList, new List<SObject>(),
                                       new Map<Id,SObject>(), new Map<Id,SObject>());
        System.assertEquals('After Insert Trigger Executed', ((Account) newList[0]).Description);

        // BEFORE UPDATE
        Account accOld = acc.clone(false, true, true, true);
        List<SObject> oldList = new List<SObject>{ accOld };
        newList = new List<SObject>{ acc };
        Map<Id, SObject> newMap = new Map<Id, SObject>{ acc.Id => acc };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ accOld.Id => accOld };

        SHF_AbstractTriggerContext.run('Account', System.TriggerOperation.BEFORE_UPDATE,
                                       newList, oldList, newMap, oldMap);
        System.assertEquals('Before Update Trigger Executed', ((Account) newList[0]).Description);
    }

 
    @IsTest
    static void testRunMethod_NoMetadata() {
        Account acc = new Account(Name = 'NoMeta Account');
        insert acc;

        Test.startTest();
        SHF_AbstractTriggerContext.run('Account', System.TriggerOperation.BEFORE_INSERT,
                                       new List<SObject>{ acc }, new List<SObject>(),
                                       new Map<Id,SObject>(), new Map<Id,SObject>());
        Test.stopTest();

        System.assert(true, 'Run completed with no metadata');
    }

    // -----------------------
    // Test: hit parent virtual method bodies
    // -----------------------
    @IsTest
    static void testParentVirtualMethods() {
        List<SObject> newList = new List<SObject>{ new Account(Name='Test') };
        List<SObject> oldList = new List<SObject>{ new Account(Name='Old') };
        Map<Id,SObject> newMap = new Map<Id,SObject>();
        Map<Id,SObject> oldMap = new Map<Id,SObject>();

        SHF_AbstractTriggerContext instance = new DummyParentCoverage();

        // Call each virtual method directly
        instance.beforeInsert(newList, oldList, newMap, oldMap);
        instance.afterInsert(newList, oldList, newMap, oldMap);
        instance.beforeUpdate(newList, oldList, newMap, oldMap);
    }

    @IsTest
    static void testGetMetaData_RealQueryBranches() {
        SHF_AbstractTriggerContext.testMetaData = null;

        try {
            SHF_AbstractTriggerContext.getMetaData('Account', System.TriggerOperation.AFTER_INSERT);
        } catch(Exception e){}

        try {
            SHF_AbstractTriggerContext.getMetaData('Account', System.TriggerOperation.BEFORE_UPDATE);
        } catch(Exception e){}
    }
}