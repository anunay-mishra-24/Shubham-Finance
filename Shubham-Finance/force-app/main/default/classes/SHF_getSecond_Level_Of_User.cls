/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : SHF_getSecond_Level_Of_User
* Author          : mansur
* Created Date    : Feb 4, 2026
* Last Modified By: <YourName>
* Last Modified On: Feb 4, 2026
* Description     : This class implements for......
*  
* Change History  :
*  Date          │   mansur     │   Change
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*  Feb 4, 2026  │ mansur  │ Initial version
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/

public class SHF_getSecond_Level_Of_User {
    
    public class FlowRequest {  
        @InvocableVariable(required=true)
        public String documentRecordIds;
        @InvocableVariable(required=true)
        public String applicationId;
    }
    
    @InvocableMethod(label='Get Second Level Of User' description='Processes input string and returns result')
    public static void getUserId(List<FlowRequest> requests) {
        System.debug('Total records from flow: '+requests.size());
        list<Activity_History__c> actList = new list<Activity_History__c>();
         list<Document__c> documentList = new list<Document__c>();
         list<Document__c> docListToUpdate = new list<Document__c>();
                    Set<Id> docIds = new Set<Id>();
        map<String,list<Document__c>> departmentWithDocsMap = new Map<String,list<Document__c>>();
         map<String,String> departmentWithInsertedActivityId = new  map<String,String>();
        system.debug('requests > ' + requests);
        try{
        if(!requests.isEmpty()){
            system.debug('requests1 > ' + requests);
            String applicationId =requests[0].applicationId;
            system.debug('applicationId > ' + applicationId);
            if(applicationId != null){
                Application__c appData = new SHF_ApplicationSelector().selectApplicationForCIBIL(applicationId);
                system.debug('appData > ' + appData);
                
                // Collect ids if needed
                for(FlowRequest req : requests){
                    if(req.documentRecordIds != null){
                        docIds.add(req.documentRecordIds);
                    }
                }
                if(!docIds.isEmpty()){
                   documentList = new SHF_DocumentsSelector().selectByDocIds(docIds);
                   system.debug('doclist size ' + documentList.size());
                   if(!documentList.isEmpty()){
                    for(Document__c docs :documentList ){
                        if(docs.Sanction_Condition_Master__r == null) continue;
                        String dept = docs.Sanction_Condition_Master__r.Deviation_Level__c;
                        if(String.isBlank(dept)) continue;
                        if(
                            dept == SHF_ConstantsUtil.L_CREDIT ||
                            dept == SHF_ConstantsUtil.L_SALES ||
                            dept == SHF_ConstantsUtil.L_OPERATIONS ||
                            dept == SHF_ConstantsUtil.L_LEGAL ||
                            dept == SHF_ConstantsUtil.L_TECHNICAL ||
                            dept == SHF_ConstantsUtil.L_FCU
                        ){
                            if(!departmentWithDocsMap.containsKey(dept)){
                                departmentWithDocsMap.put(dept, new List<Document__c>());
                            }
                            departmentWithDocsMap.get(dept).add(docs);
                        }
                    }
                }
                 system.debug('departmentWithDocsMap ' + departmentWithDocsMap);
                }
                // to get  owner id
                   List<User>  user = [SELECT Id,ManagerId,Manager.IsActive FROM User WHERE IsActive = true ];

                    if(departmentWithDocsMap.containsKey(SHF_ConstantsUtil.L_CREDIT)){
                       actList.add(createApprovalTaskInstance(appData,SHF_ConstantsUtil.L_CREDIT,user));
                    }
                     if(departmentWithDocsMap.containsKey(SHF_ConstantsUtil.L_SALES)){
                       actList.add(createApprovalTaskInstance(appData,SHF_ConstantsUtil.L_SALES,user));
                    }
                     if(departmentWithDocsMap.containsKey(SHF_ConstantsUtil.L_OPERATIONS)){
                       actList.add(createApprovalTaskInstance(appData,SHF_ConstantsUtil.L_OPERATIONS,user));
                    }
                     if(departmentWithDocsMap.containsKey(SHF_ConstantsUtil.L_FCU)){
                       actList.add(createApprovalTaskInstance(appData,SHF_ConstantsUtil.L_FCU,user));
                    }
                     if(departmentWithDocsMap.containsKey(SHF_ConstantsUtil.L_TECHNICAL)){
                       actList.add(createApprovalTaskInstance(appData,SHF_ConstantsUtil.L_TECHNICAL,user));
                    }
                    if(departmentWithDocsMap.containsKey(SHF_ConstantsUtil.L_LEGAL)){
                       actList.add(createApprovalTaskInstance(appData,SHF_ConstantsUtil.L_LEGAL,user));
                    }
                     system.debug('actList '+ actList);
                    if(!actList.isEmpty()){
                       
                        insert actList;
                        // After insert, Ids are available
                     for(Activity_History__c act : actList){
                         System.debug('Inserted Record Id: ' + act.Id);
                         departmentWithInsertedActivityId.put(act.Department__c,act.Id);
                      }
                    }
                    //add document as child to activity history records;
                    if(!documentList.isEmpty()){
                        for(Document__c  d: documentList){
                            if(departmentWithInsertedActivityId.containsKey(d.Sanction_Condition_Master__r.Deviation_Level__c)){
                                Document__c docInstance = new Document__c();
                                docInstance.Id = d.Id;
                                docInstance.Activity_History__c  = departmentWithInsertedActivityId.get(d.Sanction_Condition_Master__r.Deviation_Level__c);
                                docListToUpdate.add(docInstance);
                            }
                    }
                    }
                    if(!docListToUpdate.isEmpty()){
                         system.debug('docListToUpdate ' + docListToUpdate);
                        update docListToUpdate;
                    }
                    
            }
        }
        }catch (Exception e) {
    System.debug('Error Message: ' + e.getMessage());
    System.debug('Line Number: ' + e.getLineNumber());
}
    }

    public static Activity_History__c createApprovalTaskInstance(Application__c appData,String deviationLevel, List<User> userList){
            Activity_History__c appH = new Activity_History__c();
            appH.Application__c = appData.Id;
            appH.Committee_Approval_Status__c = SHF_ConstantsUtil.PENDING;
            appH.Department__c = deviationLevel;
             system.debug('userList ' + userList);
             system.debug('deviationLevel ' + deviationLevel);
             system.debug('appData ' + appData);
             system.debug('ownerIfe ' + fetchOwnerForTask( appData, deviationLevel,userList));
            appH.OwnerId = fetchOwnerForTask( appData, deviationLevel,userList);
            appH.RecordTypeId =  Schema.SObjectType.Activity_History__c.getRecordTypeInfosByName().get('Activity History for Special Condition').getRecordTypeId();
           // appH.Requested_Status__c = requestedStatus;
            return appH;
    }
   public static Id fetchOwnerForTask(Application__c appData,String deviationLevel, List<User> userList){
    Id ownerId =null;
    system.debug('userList ' + userList);
    system.debug('deviationLevel ' + deviationLevel);
    system.debug('appData ' + appData);
     if(!userList.isEmpty()){
     for(User user : userList){
         if(deviationLevel == SHF_ConstantsUtil.L_CREDIT && appData.Credit_Sanction_Approved_By__c == user.Id){
                ownerId = (user.ManagerId != null  && user.Manager.IsActive == true) ? user.ManagerId : user.Id;
         }
          if(deviationLevel == SHF_ConstantsUtil.L_SALES && appData.OwnerId == user.Id){
                ownerId = (user.ManagerId != null  && user.Manager.IsActive == true) ? user.ManagerId : user.Id;
         }
         if(deviationLevel == SHF_ConstantsUtil.L_FCU && appData.OwnerId == user.Id){
                ownerId = user.Id;
         }
          if(deviationLevel == SHF_ConstantsUtil.L_OPERATIONS && appData.OwnerId == user.Id){
                ownerId = user.Id;
         }
          if((deviationLevel == SHF_ConstantsUtil.L_TECHNICAL || deviationLevel == SHF_ConstantsUtil.L_LEGAL) && appData.OwnerId == user.Id){
                ownerId = user.Id;
         }
      }
     }
    return ownerId;
   }
}