/**
* @File Name : ProductSelector.cls
* @Description :  this class is used for fetching the Product__c records.
* @Author :  Preeti
* @Last Modified By :  June 26, 2025
* @Last Modified On : June 26, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 26, 2025 |   | Initial Version
**/


public class SHF_ProductMasterSelector extends fflib_SObjectSelector {
    
    
    
    /**
* @Description: Provides the fields to be queried by default.
* @Return: List of Schema.SObjectField.
*/
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
           // Product_Master__c.Loan_Tenure_in_months__c,
                Product_Master__c.Application__c,
                Product_Master__c.Product_Type__c,
                Product_Master__c.Scheme_Name__c,
                Product_Master__c.Fresh_Onboarding__c,
                Product_Master__c.Customer_Profile__c,
                Product_Master__c.Minimum_Tenure_in_months__c,
                Product_Master__c.LTV__c,
                Product_Master__c.Plot_LTV__c,
                Product_Master__c.Policy_FOIR__c,
                Product_Master__c.Minimum_Applicant_Age__c,
                Product_Master__c.Minimum_Co_Applicant_Age__c,
                Product_Master__c.Minimum_Work_Experience__c,
                Product_Master__c.Maximum_Tenure_in_months__c,
                Product_Master__c.Minimum_Loan_Amount__c,
                Product_Master__c.LVR_LCER__c,
                Product_Master__c.IIR__c,
                Product_Master__c.IAR__c,
                Product_Master__c.Max_Income_contributor_Age_At_Maturity__c,
                Product_Master__c.Maximum_Age_Non_Finacial_Borrowers_At_Ma__c,
                Product_Master__c.Maximum_Age_Property_Owner_At_Maturity__c,
                Product_Master__c.OGL_Property_Address__c,
                Product_Master__c.Crif_Cibil_Score__c,
                Product_Master__c.Programme__c,
                Product_Master__c.Status__c,
                Product_Master__c.Product_Code__c,
                Product_Master__c.Sub_Product_Code__c,
                 Product_Master__c.Program_Code__c,
                Product_Master__c.Applicable_Branch__c,
                Product_Master__c.Sub_Product__c,
                Product_Master__c.Crif_Score__c,
                Product_Master__c.Product_Name__c,
                Product_Master__c.Product_Master__c,
                Product_Master__c.Minimum_Work_Experience__c
                };
                    }
    /**
* @Description: Return the SObject type.
* @Return: Schema.SObjectType.
*/
    
    public Schema.SObjectType getSObjectType() { 
        return Product_Master__c.SObjectType; 
    }
    
    
    /**
* @Description: Fetch Product__c records by Loan Application Id.
* @Param: loanApplicationId - Id of Loan Application.
* @Return: List of Product__c records.
*/
    public List<Product_Master__c> selectByLoanApplicationId(Id loanApplicationId) {
        String query = newQueryFactory()
            .setCondition('Application__c = :loanApplicationId')
            .toSOQL();
        
        return (List<Product_Master__c>) Database.query(query);
    }
    
    public List<Product_Master__c> selectByPath(String path) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Digilocker_Verification__r.Transaction_Id__c');
        query.selectField('Digilocker_Verification__r.Transaction_Id__c');
        query.setCondition('Path__c = :path');
        return (List<Product_Master__c>) Database.query(query.toSOQL());
    }

    //Fetch child product  master record 
     public List<Product_Master__c> selectParentId(String parentId) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Product_Master__c = :parentId');
        return (List<Product_Master__c>) Database.query(query.toSOQL());
    }
   
}