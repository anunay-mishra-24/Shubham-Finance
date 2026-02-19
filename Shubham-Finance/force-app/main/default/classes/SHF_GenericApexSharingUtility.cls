/*
* @File Name          : SHF_GenericApexSharingUtility.cls
* @Author             : Preeti
* @Created Date       : August 04, 2025
* @Description        : Utility class to create sharing records for both standard and custom objects.
*                       Prevents duplicate sharing for same User/Group and Record.
*                       Supports Flow invocation and is bulkified.
*/

public class SHF_GenericApexSharingUtility {

    // =========================
    // Flow Input Wrapper
    // =========================
    public class SharingInput {
        @InvocableVariable(required=true)
        public Id recordId;

        @InvocableVariable(required=true)
        public String objectApiName;

        @InvocableVariable(required=true)
        public Id userOrGroupId;

        @InvocableVariable(required=true)
        public String accessLevel;
    }

    // =========================
    // Standard Object Field Mapping
    // =========================
    private static final Map<String, Map<String, String>> STANDARD_OBJECT_MAPPING =
        new Map<String, Map<String, String>>{
            'Account'     => new Map<String, String>{
                'IdField' => 'AccountId',
                'AccessLevelField' => 'AccountAccessLevel'
            },
            'Opportunity' => new Map<String, String>{
                'IdField' => 'OpportunityId',
                'AccessLevelField' => 'OpportunityAccessLevel'
            },
            'Case'        => new Map<String, String>{
                'IdField' => 'CaseId',
                'AccessLevelField' => 'CaseAccessLevel'
            },
            'Contact'     => new Map<String, String>{
                'IdField' => 'ContactId',
                'AccessLevelField' => 'ContactAccessLevel'
            }
        };

    // =========================
    // Invocable Method
    // =========================
    @InvocableMethod(
        label='Create Generic Share'
        description='Creates share record only if not already shared with the user or group'
    )
    public static void createShare(List<SharingInput> inputs) {

        if (inputs == null || inputs.isEmpty()) return;

        // ----------------------------------------------------
        // Step 1: Prepare data for bulk SOQL
        // ----------------------------------------------------
        Map<String, Set<Id>> recordIdsByShareObj = new Map<String, Set<Id>>();
        Map<String, Set<Id>> userIdsByShareObj   = new Map<String, Set<Id>>();

        for (SharingInput input : inputs) {

            String shareObjName = getShareObjectName(input.objectApiName);

            if (!recordIdsByShareObj.containsKey(shareObjName)) {
                recordIdsByShareObj.put(shareObjName, new Set<Id>());
            }
            if (!userIdsByShareObj.containsKey(shareObjName)) {
                userIdsByShareObj.put(shareObjName, new Set<Id>());
            }

            recordIdsByShareObj.get(shareObjName).add(input.recordId);
            userIdsByShareObj.get(shareObjName).add(input.userOrGroupId);
        }

        // ----------------------------------------------------
        // Step 2: Query existing share records
        // ----------------------------------------------------
        Map<String, Set<String>> existingSharesMap = new Map<String, Set<String>>();

        for (String shareObj : recordIdsByShareObj.keySet()) {

            String parentField = getParentIdField(shareObj);

            Set<Id> recordIds = recordIdsByShareObj.get(shareObj);
            Set<Id> userIds   = userIdsByShareObj.get(shareObj);

            if (recordIds == null || recordIds.isEmpty() ||
                userIds == null || userIds.isEmpty()) {
                continue;
            }

            String soql =
                'SELECT ' + parentField + ', UserOrGroupId ' +
                'FROM ' + shareObj +
                ' WHERE ' + parentField + ' IN :recordIds' +
                ' AND UserOrGroupId IN :userIds';

            for (SObject sObj : Database.query(soql)) {

                String key = sObj.get(parentField) + '-' + sObj.get('UserOrGroupId');

                if (!existingSharesMap.containsKey(shareObj)) {
                    existingSharesMap.put(shareObj, new Set<String>());
                }
                existingSharesMap.get(shareObj).add(key);
            }
        }

        // ----------------------------------------------------
        // Step 3: Create share records if not already shared
        // ----------------------------------------------------
        List<SObject> sharesToInsert = new List<SObject>();

        for (SharingInput input : inputs) {

            String shareObjName = getShareObjectName(input.objectApiName);
            String parentField  = getParentIdField(shareObjName);
            String accessField  = getAccessLevelField(input.objectApiName);

            String key = input.recordId + '-' + input.userOrGroupId;

            // Skip if already shared
            if (existingSharesMap.containsKey(shareObjName) &&
                existingSharesMap.get(shareObjName).contains(key)) {
                continue;
            }

            SObject shareRecord =
                (SObject) Type.forName('Schema.' + shareObjName).newInstance();

            shareRecord.put(parentField, input.recordId);
            shareRecord.put('UserOrGroupId', input.userOrGroupId);
            shareRecord.put(accessField, input.accessLevel);

            // Set RowCause if supported
            Map<String, Schema.SObjectField> fields =
                Schema.getGlobalDescribe()
                    .get(shareObjName)
                    .getDescribe()
                    .fields.getMap();

            if (fields.containsKey('RowCause')) {
                shareRecord.put('RowCause', 'Manual');
            }

            sharesToInsert.add(shareRecord);
        }

        // ----------------------------------------------------
        // Step 4: Insert share records
        // ----------------------------------------------------
        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
        }
    }

    // =========================
    // Helper Methods
    // =========================
    private static String getShareObjectName(String objectApiName) {
        return objectApiName.endsWith('__c')
            ? objectApiName.replace('__c', '__Share')
            : objectApiName + 'Share';
    }

    private static String getParentIdField(String shareObjectName) {
        String baseObject = shareObjectName.replace('Share', '');

        if (STANDARD_OBJECT_MAPPING.containsKey(baseObject)) {
            return STANDARD_OBJECT_MAPPING.get(baseObject).get('IdField');
        }
        return 'ParentId';
    }

    private static String getAccessLevelField(String objectApiName) {
        if (STANDARD_OBJECT_MAPPING.containsKey(objectApiName)) {
            return STANDARD_OBJECT_MAPPING.get(objectApiName).get('AccessLevelField');
        }
        return 'AccessLevel';
    }
}