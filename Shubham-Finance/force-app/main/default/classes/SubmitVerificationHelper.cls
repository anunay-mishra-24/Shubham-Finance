/**
* @File Name : SubmitVerificationHelper.cls
* @Description : Helper for Submit Modal
* @Author :
* @Last Modified By :
* @Last Modified On : July 27, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 27, 2025 |   | Initial Version
**/

public with sharing class SubmitVerificationHelper {

    @AuraEnabled(cacheable=true)
public static List<Map<String, String>> getStatusPicklistValues() {
    List<Map<String, String>> options = new List<Map<String, String>>();
    Schema.DescribeFieldResult fieldResult = Verification__c.Status__c.getDescribe();
    for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
        options.add(new Map<String, String>{
            'label' => entry.getLabel(),
            'value' => entry.getValue()
        });
    }
    return options;
}



    @AuraEnabled
    public static Id getApplicationId(Id verificationId) {
        Verification__c ver = [SELECT Application__c FROM Verification__c WHERE Id = :verificationId LIMIT 1];
        return ver.Application__c;
    }

    @AuraEnabled
    public static Id getBranchId(Id applicationId) {
        Application__c app = [SELECT Branch__c FROM Application__c WHERE Id = :applicationId LIMIT 1];
        return app.Branch__c;
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getInternalUsers(Id branchId) {
        List<User> users = new List<User>();
        for (Branch_Mapping__c bm : [
            SELECT Internal_User__r.Id, Internal_User__r.Name 
            FROM Branch_Mapping__c 
            WHERE Branch_Master__c = :branchId AND Internal_User__c != NULL
        ]) {
            users.add(bm.Internal_User__r);
        }
        return users;
    }

    @AuraEnabled
public static List<Account> getValidVendors(Id branchId) {
    Set<Id> vendorAccountIds = new Set<Id>();

    // Step 1: Get vendor accounts
    List<Branch_Mapping__c> mappings = [
        SELECT Vendor__c, Vendor__r.IsPartner 
        FROM Branch_Mapping__c 
        WHERE Branch_Master__c = :branchId AND Vendor__c != NULL
    ];

    for (Branch_Mapping__c bm : mappings) {
        if (bm.Vendor__r != null && bm.Vendor__r.IsPartner) {
            vendorAccountIds.add(bm.Vendor__c);
        }
    }

    // Step 2: Get Contacts related to vendor accounts
    Map<Id, List<Id>> vendorToContactMap = new Map<Id, List<Id>>();
    for (Contact con : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :vendorAccountIds]) {
        if (!vendorToContactMap.containsKey(con.AccountId)) {
            vendorToContactMap.put(con.AccountId, new List<Id>());
        }
        vendorToContactMap.get(con.AccountId).add(con.Id);
    }

    // Step 3: Flatten Contact IDs
    Set<Id> allContactIds = new Set<Id>();
    for (List<Id> contactList : vendorToContactMap.values()) {
        allContactIds.addAll(contactList);
    }

    // Step 4: Get Users created from those Contacts
    Set<Id> contactIdsWithUsers = new Set<Id>();
    for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :allContactIds]) {
        contactIdsWithUsers.add(u.ContactId);
    }

    // Step 5: Collect valid vendor accounts that have such users
    Set<Id> validVendorAccountIds = new Set<Id>();
    for (Id vendorAccId : vendorToContactMap.keySet()) {
        for (Id conId : vendorToContactMap.get(vendorAccId)) {
            if (contactIdsWithUsers.contains(conId)) {
                validVendorAccountIds.add(vendorAccId);
                break;
            }
        }
    }

    // Step 6: Return final vendor accounts
    List<Account> validVendors = [
        SELECT Id, Name FROM Account WHERE Id IN :validVendorAccountIds
    ];
    return validVendors;
}


    @AuraEnabled
    public static Id createVerificationActivity(Id verificationId, String vendorType, String triggerText, Id ownerId) {
        Verification_Activity__c va = new Verification_Activity__c();
        va.Verification__c = verificationId;
        va.Vendor_Status__c = 'Pending';
        va.Vendor_Type__c = vendorType;
        //va.Suspicious_Trigger__c = triggerText;
        va.OwnerId = ownerId;
        insert va;
        return va.Id;
    }
}