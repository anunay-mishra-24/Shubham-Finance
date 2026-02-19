/**
* @File Name : ShfCreditPdMainComponentCtrl.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 24, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 24, 2025 |   | Initial Version
**/

public class ShfCreditPdMainComponentCtrl {
	@AuraEnabled(Cacheable=true)
	public static List<ResponseWrapper> getLoanApplicantRecords(String applicationId){
		List<ResponseWrapper> responseList = new List<ResponseWrapper>();
		try{
			List<Loan_Applicant__c> loanApplicantList = [SELECT Id, Name, Applicant_Type__c, Account_Name__c, Application__r.Application_Stage__c,
														Application__c, Entity_Name__c, Customer_Type__c
														FROM Loan_Applicant__c 
														WHERE Application__c = :applicationId AND IsDeleted__c = FALSE
														ORDER BY Applicant_Type__c];
			if(loanApplicantList != null && !loanApplicantList.isEmpty()){
				for(Loan_Applicant__c record : loanApplicantList){
					ResponseWrapper response = new ResponseWrapper();
					String key = record.Account_Name__c + '-' + record.Application__c;
					String baseName;

					// If Non-Individual, use Entity_Name, otherwise use Account_Name
					if(record.Customer_Type__c == 'Non-Individual' && record.Entity_Name__c != null) {
						baseName = record.Entity_Name__c;
					} else {
						baseName = record.Account_Name__c;
					}
					// Append Applicant Type
					String name = baseName + '(' + record.Applicant_Type__c + ')';

					response.applicantName = name;
					response.id = record.Id;
					responseList.add(response);
				}
			}
		} catch(Exception ex) {
			//response.isSuccess = false;
			//response.responseBody = ex.getMessage();
			//return response;
		}

		//System.debug('ResponseWrapper-> ' + response);
		return responseList;
	}

	public class ResponseWrapper{
		@AuraEnabled public String applicantName;
		@AuraEnabled public String id;
	}
}