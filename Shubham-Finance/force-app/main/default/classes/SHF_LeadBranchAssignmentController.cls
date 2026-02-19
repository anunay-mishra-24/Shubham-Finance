/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_LeadBranchAssignmentController
 * Author          : <YourName>
 * Created Date    : Feb 9, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Feb 9, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Feb 9, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public without sharing class SHF_LeadBranchAssignmentController {

    @AuraEnabled(cacheable=true)
    public static User getNextBranchManager(Id leadId) {


        if (leadId == null) {
            throw new AuraHandledException('Lead Id is required');
        }

        // Fetch Lead Branch
        Lead__c ld = [SELECT Id, Branch__c FROM Lead__c WHERE Id = :leadId LIMIT 1];


        if (ld.Branch__c == null) {
            throw new AuraHandledException('Branch is not available on Lead');
        }

        // Fetch Branch Mapping with role Branch Manager users
        List<Branch_Mapping__c> mappings = [SELECT Id,Internal_User__c,Last_Assignment__c FROM Branch_Mapping__c WHERE Branch_Master__c = :ld.Branch__c AND Internal_User__r.UserRole.Name = 'Branch Manager' ORDER BY Last_Assignment__c ASC NULLS FIRST limit 1];


        if (mappings.isEmpty()) {
            throw new AuraHandledException('No Branch Manager found');
        }

        // Select first mapping (round robin)
        Branch_Mapping__c selectedMapping = mappings[0];

        // Fetch User from branch mapping
        User selectedUser = [SELECT Id, Name FROM User WHERE Id = :selectedMapping.Internal_User__c LIMIT 1];

        return selectedUser;
    }

    @AuraEnabled
    public static void assignLeadToUser(Id leadId, Id userId) {


        if (leadId == null || userId == null) {
            throw new AuraHandledException('Invalid input');
        }
        try {
        // Update Lead Owner
        Lead__c ld = new Lead__c(
			Id = leadId,
			Branch_Change_Flag__c = False,
            OwnerId = userId
        );

        update ld;

        // Update Last Assignment on Branch Mapping
        List<Branch_Mapping__c> mappings = [SELECT Id, Last_Assignment__c FROM Branch_Mapping__c WHERE Internal_User__c = :userId LIMIT 1];

        if (!mappings.isEmpty()) {
            mappings[0].Last_Assignment__c = System.now();
            update mappings;
            System.debug('Last assignment updated successfully');
        } else {
            System.debug('No mapping found to update Last Assignment');
        }
		}
		catch (Exception e) {

            System.debug('Unexpected Error: ' + e.getMessage());

            throw new AuraHandledException('Unexpected error occurred. Please try again.');
        }
    }
}