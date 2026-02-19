/**
* @File Name : SHF_recomendedFuctionalityController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 29, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 29, 2025 |   | Initial Version
**/

public class SHF_recomendedFuctionalityController {
	// @AuraEnabled(cacheable=true)
    // public static List<User> getUsersByRole(String roleName) {
    //     if (String.isBlank(roleName)) return new List<User>();

    //     return [
    //         SELECT Id, Name 
    //         FROM User 
    //         WHERE UserRole.Name = :roleName 
    //         ORDER BY Name
    //     ];
    // }

    @AuraEnabled(cacheable=true)
    public static List<User> getUsersByRole(String roleName , String applicationId) {
        Boolean isUserHasAuthority = false;
         List<User>  u = new List<User>();
         List<Id> userList = new List<Id>();
        Application__c applicationDetail = new SHF_ApplicationSelector().selectApplicationForInsurance(applicationId);
			if(applicationDetail != null){
       
        if (String.isBlank(roleName) || applicationId == null) return new List<User>();
        List<Product_Branch_Mapping__c> productBranchMappingDetail = new SHF_Product_Branch_Mapping_Selector().getProductBranchMappingById(new set<Id> {applicationDetail.Branch__c},new set<Id> {applicationDetail.Product__c});
        if(!productBranchMappingDetail.isEmpty()){
            system.debug('productBranchMappingDetail '  + productBranchMappingDetail);
				system.debug('productBranchMappingDetail id '  + productBranchMappingDetail[0].Id);
				List<Branch_Mapping__c> branchMappinDetail = new SHF_Branch_Mapping_Selector().getBranchMappingByUserAndBranch(new set<Id> {productBranchMappingDetail[0].Id},SHF_ConstantsUtil.SANCTION_APPROVAL );
				system.debug('branchMappinDetail '  + branchMappinDetail);
                if(! branchMappinDetail.isEmpty()){
                    for(Branch_Mapping__c branchMaping : branchMappinDetail){
						system.debug('branchMaping.Internal_User__c '  + branchMaping.Internal_User__c + ' applicationDetail.OwnerId ' +applicationDetail.OwnerId);
						system.debug('applicationDetail.Applied_Loan_Amount__c '  + applicationDetail.Applied_Loan_Amount__c + ' branchMaping.Sanction_Limit__c ' + branchMaping.Sanction_Limit__c);
						if(branchMaping.Internal_User__r.UserRole.Name == roleName && applicationDetail.Applied_Loan_Amount__c <= branchMaping.Sanction_Limit__c ){
							userList.add(branchMaping.Internal_User__c);
						}
					}
                    if(!userList.isEmpty()){
                         u = [ SELECT Id, Name  FROM User WHERE Id IN:userList  ORDER BY Name ];
                    }
                }
        }
            }
            system.debug('u >' + u);
            return u;
    }

     @AuraEnabled(cacheable=true)
    public static Id getQueueIdByName(String queueName) {
        if (String.isBlank(queueName)) return null;
        Group g = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue'
            AND Name = :queueName
            LIMIT 1
        ];

        return g.Id;
    }

    @AuraEnabled
    public static String updateDeviation(String applicationId) {
        List<Deviation_and_Sanction_Condition__c> updatedDeviationList = new List<Deviation_and_Sanction_Condition__c>();
        try{
                        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Deviation_and_Sanction_Condition__c.SObjectType});
        if (String.isNotBlank(applicationId)){
           List<Deviation_and_Sanction_Condition__c> deviationList = new SHF_DeviationAndSanctionSelector().selestByApplicationId(new set<Id>{applicationId});
           
           if(!deviationList.isEmpty()){
            for(Deviation_and_Sanction_Condition__c deviation : deviationList){
                 system.debug('deviation>> ' + deviation);
                if(deviation.Decision__c == SHF_ConstantsUtil.PENDING){
                    Deviation_and_Sanction_Condition__c updatedDeviationDecision = new Deviation_and_Sanction_Condition__c();
                    updatedDeviationDecision.Decision__c = SHF_ConstantsUtil.SENT_FOR_REVIEW;
                    updatedDeviationDecision.id = deviation.Id;
                    updatedDeviationList.add(updatedDeviationDecision);
                }
            }
            system.debug('updatedDeviationList>> ' + updatedDeviationList);
            if(!updatedDeviationList.isEmpty()){
                 system.debug('updatedDeviationList>> ' + updatedDeviationList);
                 update updatedDeviationList;
            // uow.registerDirty(updatedDeviationList);
            }
           
           }
        }
        }catch(exception ex){
           system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
            return 'ERROR :' + ex.getMessage()+' Line:- '+ ex.getlineNumber();
        }
      return 'Success';
    }

    @AuraEnabled
    public static string createActivityHistoryRecord(String applicationId, String recomendationComment){
        String msg = ''; 
        try{

            List<Activity_History__c> existingActHistoryList = new List<Activity_History__c>();
            List<Activity_History__c> actHistoryList = new List<Activity_History__c>();
        if(applicationId == null) return 'Application Id null';
         Application__c application = new SHF_ApplicationSelector().selectApplicationForCIBIL(applicationId);
        // update all existing approvl record so that they will not consider for current approval process
        for(Activity_History__c actRecord : [SELECT id,Activity_For_Committee__c FROM Activity_History__c WHERE Activity_For_Committee__c = true AND Application__c =:applicationId AND RecordTypeId =:SHF_ConstantsUtil.ACTIVITY_HISTORY_FOR_COMMITTEE_RECORDTYPEID]){
            actRecord.Activity_For_Committee__c = false;
            existingActHistoryList.add(actRecord);
        }
        if(!existingActHistoryList.isEmpty()){
            update existingActHistoryList;
        }


        String committeeQueue = System.Label.Committee_Queue;
         system.debug('committeeQueue ' + committeeQueue);

        List<User> usersInQueue = [
    SELECT Id, Name, Email
    FROM User
    WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName =:committeeQueue  AND Group.Type = 'Queue')];
    system.debug('usersInQueue ' + usersInQueue);
    if(!usersInQueue.isEmpty()){
        for(User user : usersInQueue){
            Activity_History__c actHistory = new Activity_History__c ();
            actHistory.OwnerId  = user.Id;
             actHistory.RecordTypeId = SHF_ConstantsUtil.ACTIVITY_HISTORY_FOR_COMMITTEE_RECORDTYPEID;
            actHistory.Committee_Approval_Status__c = 'Pending';
            actHistory.Application__c = applicationId;
            actHistory.Recommended_Loan_Amount__c = String.valueOf(application.Recommended_Loan_Amount__c);
            actHistory.Comments__c = '';
            actHistory.Activity_For_Committee__c = true;
            actHistory.Recommendation_by_the_credit_user__c =recomendationComment !=null ? recomendationComment : application.Recomendation_comment__c;
            system.debug('actHistory>> ' +actHistory);
            actHistoryList.add(actHistory);

        }
        if(actHistoryList != null){
            insert actHistoryList;
            msg = 'SUCCESS';
        }
    }
    return '';
    }catch(exception ex){
            system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
            msg = 'ERROR :' + ex.getMessage()+' Line:- '+ ex.getlineNumber();
    }
    return msg;

    }
}