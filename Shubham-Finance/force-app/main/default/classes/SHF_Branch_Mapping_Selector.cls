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
public class SHF_Branch_Mapping_Selector extends fflib_SObjectSelector{
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            Branch_Mapping__c.Id,
                Branch_Mapping__c.Name,
                Branch_Mapping__c.Branch_Master__c ,
				Branch_Mapping__c.Internal_User__c,
				Branch_Mapping__c.Sanction_Limit__c,
                Branch_Mapping__c.Product_Branch_Mapping__c
                };
                    }
    
    /**
* @Description: Select required object. 
* @Return: Schema.SObjectType.
*/
    public Schema.SObjectType getSObjectType() { 
        return Branch_Mapping__c.SObjectType; 
    }
    
    // fetch  the branch master on the basisof record Id..added by mansur alam
    public List<Branch_Mapping__c > getBranchMappingByUserAndBranch(set<Id> procductBranchId,String recordTypeName) {
        fflib_QueryFactory query = newQueryFactory();
         query.selectField('Internal_User__r.UserRole.Name'); 
        query.setCondition('Product_Branch_Mapping__c IN : procductBranchId AND RecordType.Name =:recordTypeName');
        return (List<Branch_Mapping__c >) Database.query(query.toSOQL());
    }
    
}