/**
* @File Name          : SHF_BranchSelector.cls
* @Author             : Mansur
* @Last Modified By   : Mansur
* @Last Modified On   : 29-11-2025
* @Description        : this class is used for fatching the Branch records.
*================================================================================================
* Update Ver         Date                     Author                 Modification                    
*================================================================================================
* 1.0              19-06-2025              	Mansur             	Initial Version            
*/
public class SHF_Product_Branch_Mapping_Selector extends fflib_SObjectSelector{
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            Product_Branch_Mapping__c.Id,
                Product_Branch_Mapping__c.Name,
                Product_Branch_Mapping__c.Branch_Master__c ,
				Product_Branch_Mapping__c.Product_Master__c,
                Product_Branch_Mapping__c.Loan_Amount_Limit__c
                };
                    }
    
    /**
* @Description: Select required object. 
* @Return: Schema.SObjectType.
*/
    public Schema.SObjectType getSObjectType() { 
        return Product_Branch_Mapping__c.SObjectType; 
    }
    
    // fetch  the branch master on the basisof record Id..added by mansur alam
    public List<Product_Branch_Mapping__c> getProductBranchMappingById(set<Id> branchId,set<Id> procductId) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Branch_Master__c IN :branchId AND Product_Master__c IN : procductId');
        return (List<Product_Branch_Mapping__c>) Database.query(query.toSOQL());
    }
    
}