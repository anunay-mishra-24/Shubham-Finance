public class SHF_ClearCAMDateInvocable {

    public class Request {
        @InvocableVariable(required=true)
        public String objectName;      // Example: "Document__c", "Loan_Applicant__c"

        @InvocableVariable(required=true)
        public Id applicationId;       // Id of Application__c record
    }

    @InvocableMethod
    public static void processCAMRetrigger(List<Request> requestList) {
        if(requestList == null || requestList.isEmpty()) return;

        Set<String> requestedObjectNames = new Set<String>();
        Set<Id> appIds = new Set<Id>();

        for(Request req : requestList) {
            requestedObjectNames.add(req.objectName);
            appIds.add(req.applicationId);
        }

        // Fetch metadata that contains matching object names
        List<Re_Trigger_Field_Detail__mdt> metaList = [
            SELECT Object_Name__c
            FROM Re_Trigger_Field_Detail__mdt
            WHERE Object_Name__c IN :requestedObjectNames
        ];

        if(metaList.isEmpty()) {
            // No metadata match → no update needed
            return;
        }

        // Metadata match found → clear CAM_Generation_Date_Time__c on Application
        List<Application__c> appsToUpdate = new List<Application__c>();

        for(Id appId : appIds) {
            Application__c app = new Application__c(
                Id = appId,
                CAM_Generation_Date_Time__c = null    // clearing field
            );
            appsToUpdate.add(app);
        }

        update appsToUpdate;
    }
}