/**
* @File Name          : SHF_ApplicationManagersController.apxc
* @Description        : This class is responsible for controlling operation related manager_Ids__c field.
* @Author             : Kunal Soni
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.1         23-10-2025              Kunal Soni             Duplicate-safe & Id validation
*/

public class SHF_ApplicationManagersController {
    
    public class ManagerInputWrapper {
        @InvocableVariable(required=true)
        public Application__c appRecord;

        @InvocableVariable(required=false)
        public List<String> priorOwnerList; // List of Old Owners from Flow
    }

    @InvocableMethod(Label='Update User ManagerIds')
    public static void updateManager(List<ManagerInputWrapper> requestList) {

        ManagerInputWrapper request = requestList[0];
        Application__c appRec = request.appRecord;
        List<String> priorOwnerList = request.priorOwnerList;

        System.debug('requestList --> ' + requestList);
        System.debug('priorOwnerList --> ' + priorOwnerList);

        List<Application__c> appList = new List<Application__c>{ appRec };

        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType> { Application__c.SObjectType }
        );

        Map<Id, Id> mapUserIdWithManagerId = new Map<Id, Id>();
        Map<Id, Set<Id>> mapUserIdWithAllManagerId = new Map<Id, Set<Id>>(); // Use Set to prevent duplicates
        Set<Id> ownerIdSet = new Set<Id>();
        Set<Id> managerIdsSet = new Set<Id>();
        boolean terminateLoop;
        String newManagerId;
        List<SObject> sObjectList = new List<SObject>();

        try {
            if(!appList.isEmpty()) {
                
                // Collect Owner(s)
                for(Application__c input : appList){
                    ownerIdSet.add(input.OwnerId);
                }
                
                // Fetch all active sales users (for hierarchy)
                List<User> listOfManagers = new SHF_UsersSelector().selectActiveSalesUsers(SHF_ConstantsUtil.SALES_PROFILE);
                
                if(!listOfManagers.isEmpty()) {
                    for(User usr : listOfManagers){
                        mapUserIdWithManagerId.put(usr.Id, usr.ManagerId);
                    }
                }
                
                // Build Manager Hierarchy
                for(String usrId : ownerIdSet) {
                    managerIdsSet.add(usrId);
                    newManagerId = mapUserIdWithManagerId.get(usrId);
                    
                    if(newManagerId != null){
                        managerIdsSet.add(newManagerId);
                    }
                    
                    do {
                        terminateLoop = false;
                        if(!String.isBlank(newManagerId)) {
                            Id nextManager = mapUserIdWithManagerId.get(newManagerId);
                            if(nextManager != null && !managerIdsSet.contains(nextManager)) {
                                managerIdsSet.add(nextManager);
                                newManagerId = nextManager;
                                terminateLoop = true;
                            }
                        }
                    } while(terminateLoop);

                    // Insert current Hierarchy into Set to prevent duplicates
                    mapUserIdWithAllManagerId.put(usrId, new Set<Id>(managerIdsSet));
                    System.debug('Hierarchy Before Adding Prior Owners --> ' + mapUserIdWithAllManagerId);

                    // Add Prior Owner Users (NULL SAFE)
                    if(priorOwnerList != null && !priorOwnerList.isEmpty()) {
                        Set<Id> mgrSet = mapUserIdWithAllManagerId.get(usrId);
                        if(mgrSet == null) {
                            mgrSet = new Set<Id>();
                        }

                        for(String oldOwner : priorOwnerList) {
                            if(oldOwner != null && oldOwner.startsWith('005')) {
                                System.debug('Adding Old Owner --> ' + oldOwner);
                                mgrSet.add((Id)oldOwner);
                            }
                        }
                        mapUserIdWithAllManagerId.put(usrId, mgrSet);

                        System.debug('Hierarchy After Adding Prior Owners --> ' + mapUserIdWithAllManagerId);
                    }

                    managerIdsSet.clear();
                }
                
                // Update Field + Create Sharing
                for(Application__c app : appList) {
                    Set<Id> uniqueManagerIds = mapUserIdWithAllManagerId.get(app.OwnerId);
                    if(uniqueManagerIds == null) uniqueManagerIds = new Set<Id>();

                    // Update Manager_Ids__c field
                    uow.registerDirty(new Application__c(
                        Id = app.Id,
                        Manager_Ids__c = String.valueOf(uniqueManagerIds)
                    ));

                    // Create Apex Sharing Records
                    for(Id mgrId : uniqueManagerIds) {
                        if(mgrId != null && String.valueOf(mgrId).startsWith('005')) {
                            Application__Share shareRec = new Application__Share();
                            shareRec.ParentId = app.Id;
                            shareRec.UserOrGroupId = mgrId;
                            shareRec.RowCause = Schema.Application__Share.RowCause.Manual;
                            shareRec.AccessLevel = SHF_ConstantsUtil.READ_APEX_SHARING;
                            sObjectList.add(shareRec);
                        }
                    }
                }

                Database.SaveResult[] shareResults = Database.insert(sObjectList, false);
                uow.commitWork();
            }
        } catch (Exception e) {
            Logger.error('Error in Application Manager Controller: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }
}