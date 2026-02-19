/**
* @File Name : SHF_riskScoreDetailSelector.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 23, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 23, 2025 |   | Initial Version
**/

public class SHF_riskScoreDetailSelector extends fflib_SObjectSelector {
	 public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Risk_Score_Details__c.Id,
                Risk_Score_Details__c.Name,
				Risk_Score_Details__c.Bin__c,
				Risk_Score_Details__c.Bin2__c,
				Risk_Score_Details__c.Effective_Date__c,
				Risk_Score_Details__c.IsActive__c,
				Risk_Score_Details__c.Key__c,
				Risk_Score_Details__c.Operator__c,
				Risk_Score_Details__c.Risk_Score_Master__c,
				Risk_Score_Details__c.Risk_Score_Master_Name__c,
				Risk_Score_Details__c.Scaled_WOE__c,
				Risk_Score_Details__c.Weight_Type__c

                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return Risk_Score_Details__c.sObjectType;
    }
}