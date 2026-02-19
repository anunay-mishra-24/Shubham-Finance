/**
* @File Name : SHF_Approval_FuctionalityController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 29, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 29, 2025 |   | Initial Version
**/

public class SHF_Approval_FuctionalityController {
	@AuraEnabled
	public static String checkApprovalMatrix(String applicationId,String comment,String approver){
		Boolean isUserHasAuthority = false;
		try{
		if(applicationId != null){
			Application__c applicationDetail = new SHF_ApplicationSelector().selectApplicationForInsurance(applicationId);
			if(applicationDetail != null){
				if(applicationDetail.Final_Committee_Approval_Status__c == SHF_ConstantsUtil.APPROVED){
					Application__c  application = new Application__c ();
						application.id = applicationId;
						application.Application_Status__c  = SHF_ConstantsUtil.APPROVED;
						application.Approver_Comments__c  =comment;
						application.Credit_Sanction_Approved_By__c = approver != null ? approver : null;
						update application;
						return 'Success: Application Approved Succesfully';
				} 
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
						if(branchMaping.Internal_User__c == applicationDetail.OwnerId && applicationDetail.Applied_Loan_Amount__c <= branchMaping.Sanction_Limit__c ){
							isUserHasAuthority = true;
						}
					}
					if(isUserHasAuthority){
						Application__c  application = new Application__c ();
						application.id = applicationId;
						application.Application_Status__c  = SHF_ConstantsUtil.APPROVED;
						application.Approver_Comments__c  =comment;
						application.Credit_Sanction_Approved_By__c = approver != null ? approver : null;
                        application.Sanction_Date__c = Date.Today();
						update application;
						return 'Success: Application Approved Succesfully';
					}else{
						 Map<String, String> msg = SHF_CommonUtil.getMessageFromMetadata('Not_authorise_to_Approve_Loan_Amount');
							return 'Error: ' + msg.get('Message');
						}

				}else{

							System.debug('branchMappingDetail not found');
							return 'Error: branch mapping Detail not Found';
						}
				}else{
							System.debug('productBranchMappingDetail not found');
							return 'Error: Product branch mapping Detail not Found';
						}
			}else{
							System.debug('Application not found');
							return 'Error: Application not found';
						}
		}else{
							System.debug('Application not found');
							return 'Error: ApplicationId not found';
						}
	}catch(exception ex){
          system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
		  return 'error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber();
        }
		//return 'Error in Fetching mapping data';
	}
}