/**
* @File Name          : SHF_ManagersController.apxc
* @Description        : This class is responsible for controlling operation related manager_Ids__c field.
* @Author             : Kunal Soni
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         28-08-2025              Kunal Soni              Initial Version
**/
public class SHF_ManagersController {
    
    /**
        * @description: This method responsible for updating manager Id. 
        * @return: Void.
        */    
    @InvocableMethod(Label='Update User ManagerIds')
    public static void updateManager(List<Lead__c> leadList) {
        // Unit of Work
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType> { Lead__c.SObjectType }
        );
        // Create map user Id with ManagerId
        Map<Id, Id> mapUserIdWithManagerId = new Map<Id, Id>();
        // Create map user Id with list of direct and indirect manager ids
        Map<Id, List<Id>> mapUserIdWithAllManagerId = new Map<Id, List<Id>>();
        // Create set of profile Id
        Set<Id> setOfProfileId = new Set<Id>();
        // Create set of manager Id
        Set<Id> managerIdsSet = new Set<Id>();
        // Create set of owner Id
        Set<Id> ownerIdSet = new Set<Id>();
        // Create set of Branch Manager User Roles
        Set<Id> branchManagerIdSet = new Set<Id>();
        // Boolean variable handle user hierarchy
        boolean terminateLoop;
        // String variable used for holding indirect manager Id
        String newManagerId;
        
        List<sObject> sObjectList = new List<sObject>();
        
        try{
            if(!leadList.isEmpty() && leadList.size() > 0){
                // Populate ownerIdSet
                for(Lead__c input : leadList){
                    ownerIdSet.add(input.OwnerId);
                }
                // Get list of user those are created
           /*     List<User> userList = new SHF_UsersSelector().selectByIdsUserName(ownerIdSet);
                system.debug('userList--> '+userList);
                
                // Populate created user profile Id into setOfProfileId
                if(!userList.isEmpty()){
                    for(User usr : userList){
                        setOfProfileId.add(usr.ProfileId);
                        system.debug('profile--> '+usr.ProfileId);
                    }
                } */
                
                // Get list of created user direct and indirect managers. 
                List<User> listOfManagers = new SHF_UsersSelector().selectActiveSalesUsers(SHF_ConstantsUtil.SALES_PROFILE);
                // Popupulate mapUserIdWithManagerId
                if(!listOfManagers.isEmpty()) {
                    for(User usr : listOfManagers){
                        mapUserIdWithManagerId.put(usr.Id, usr.ManagerId);
                        if(usr.UserRole.Name == SHF_ConstantsUtil.BRANCH_MANAGER_ROLE){
                            branchManagerIdSet.add(usr.Id);
                        }
                    }
                }
                // Get direct and indirect manager Id list for respective users.
                for(String usrId : ownerIdSet) {
                    managerIdsSet.add(usrId);
                    if(mapUserIdWithManagerId.get(usrId) != null){
                        managerIdsSet.add(mapUserIdWithManagerId.get(usrId));
                        newManagerId = mapUserIdWithManagerId.get(usrId);   
                    }
                    do{
                        terminateLoop = false;
                        if(!String.isBlank(newManagerId)) {
                            if(!managerIdsSet.contains(mapUserIdWithManagerId.get(newManagerId)) && mapUserIdWithManagerId.get(newManagerId) != null) {
                                managerIdsSet.add(mapUserIdWithManagerId.get(newManagerId));
                                newManagerId = mapUserIdWithManagerId.get(newManagerId);
                                terminateLoop = true;
                            }
                        }
                    }while(terminateLoop);
                    mapUserIdWithAllManagerId.put(usrId, new List<Id>(managerIdsSet));
                    logger.info('mapUserIdWithAllManagerId'+ mapUserIdWithAllManagerId);
                    managerIdsSet.clear();
                }
                
                // Update newly created user's Manager_Ids__c
                for(Lead__c lead : leadList) {
                    uow.registerDirty(new Lead__c(
                        Id = lead.Id,
                        Manager_Ids__c = String.valueOf(mapUserIdWithAllManagerId.get(lead.OwnerId))
                    ));
                    logger.info('mapUserIdWithAllManagerId values '+ mapUserIdWithAllManagerId.get(lead.OwnerId));
                    for(String managerId : String.valueOf(mapUserIdWithAllManagerId.get(lead.OwnerId)).remove('(').remove(')').split(',')){
                        logger.info('Apex Sharing Users '+ managerId.trim());
                        Lead__Share ldShare = new Lead__Share();
                        ldShare.ParentId = lead.Id;
                        ldShare.UserOrGroupId = managerId.trim();
                        ldShare.AccessLevel = SHF_ConstantsUtil.EDIT_APEX_SHARING;
                       // ldShare.AccessLevel = branchManagerIdSet.contains(managerId.trim()) ? SHF_ConstantsUtil.EDIT_APEX_SHARING : SHF_ConstantsUtil.READ_APEX_SHARING;
                        sObjectList.add(ldShare);
                    }
                }
                Database.SaveResult[] sObjList = Database.insert(sObjectList, false);
                logger.info('Result sObjList '+ sObjList);
                // Commit Unit of Work
                uow.commitWork();
            }
        }catch (Exception e) {
            // Log the exception for visibility
            Logger.error('Error in Lead Manager Controller: ' + e.getMessage());
        }finally{
            Logger.saveLog();
        }
    }
}