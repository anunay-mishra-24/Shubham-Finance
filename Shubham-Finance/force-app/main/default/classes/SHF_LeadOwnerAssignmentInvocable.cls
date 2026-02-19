/**
* @File Name          : SHF_LeadOwnerAssignmentInvocable.cls
* @Author             : Kunal Soni
* @Last Modified By   : Kunal Soni
* @Last Modified On   : 18-09-2025
* @Description        : Invocable class to run SHF_LeadOwnerAssignmentBatch from Flow/Process.
*/
public class SHF_LeadOwnerAssignmentInvocable {

    @InvocableMethod(
        label='Run Lead Owner Assignment Batch'
        description='Enqueues the Lead Owner Assignment batch job for round robin assignment'
    )
    public static void runBatch(List<Lead__c> leadList) {
        Database.executeBatch(new SHF_LeadOwnerAssignmentBatch(), 200);
    }
}