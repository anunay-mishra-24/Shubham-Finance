public with sharing class SHF_SharingRecords {
   
//use this method to share the record with user or group of users--added by mansur on 12-09-2005
public class FlowInputs{
        @InvocableVariable
        public String recordId;
        @InvocableVariable
        public String userOrGroupId;
        @InvocableVariable
        public String recordAccessLevel;        

    }
    
    @InvocableMethod(Label='Apex Record Sharing')
    public static void shareRecord(List<FlowInputs> request){
        if(request.size() > 0){
            system.debug('request'+request[0].recordId);
            system.debug('request'+request[0].userOrGroupId); 
            system.debug('request'+request[0].recordAccessLevel);
            if(String.isNotBlank(request[0].recordId) && String.isNotBlank(request[0].userOrGroupId) && String.isNotBlank(request[0].recordAccessLevel)){
                createCustomObjectShare(request[0].recordId, request[0].userOrGroupId, request[0].recordAccessLevel, true);
            }
        }
    }

 public static sObject createCustomObjectShare(Id recordId, Id userOrGroupId, String recordAccessLevel, Boolean isShareRecord){
        String sObjLabel = recordId.getSObjectType().getDescribe().getName();
        system.debug('sObjLabel-> ' + sObjLabel);
        // Create new sharing object for the custom object Job.
        sObjLabel = sObjLabel.contains('__c') ? sObjLabel.remove('__c') : sObjLabel;
        system.debug('sObjLabel-> ' + sObjLabel);
        sObject sObj = Schema.getGlobalDescribe().get(sObjLabel + '__Share').newSObject();
        system.debug('sObj-> ' + sObj);
        // Set the ID of record being shared.
        sObj.put('ParentId',recordId);
        // Set the ID of user or group being granted access.
        sObj.put('UserOrGroupId',userOrGroupId);
        // Set the access level.
        sObj.put('AccessLevel',recordAccessLevel);
        // Set rowCause to 'manual' for manual sharing.
        // This line can be omitted as 'manual' is the default value for sharing objects.
        //sObj.put('RowCause',Schema.Loan_Application__Share.RowCause.Manual);
        
        if(isShareRecord){
            // Insert the sharing record and capture the save result. 
            Database.SaveResult sr = Database.insert(sObj,false);
        }
        return sObj;
    }
}