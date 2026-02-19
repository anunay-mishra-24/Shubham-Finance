/**
* @File Name          : SHF_BranchSelector.cls
* @Author             : Kunal soni
* @Last Modified By   : kunal soni
* @Last Modified On   : 19-06-2025
* @Description        : this class is used for fatching the Branch records.
*================================================================================================
* Update Ver         Date                     Author                 Modification                    
*================================================================================================
* 1.0              19-06-2025              	Kunal soni             	Initial Version            
*/
public class SHF_BranchSelector extends fflib_SObjectSelector{
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            Branch_Master__c.Id,
                Branch_Master__c.Name,
                Branch_Master__c.Branch_Location__c ,
                Branch_Master__c.Branch_Location__Longitude__s,
                Branch_Master__c.Branch_Location__Latitude__s,
                //Branch_Master__c.City__r.Name,
                Branch_Master__c.Branch_Code__c                
                };
                    }
    
    /**
* @Description: Select required object. 
* @Return: Schema.SObjectType.
*/
    public Schema.SObjectType getSObjectType() { 
        return Branch_Master__c.SObjectType; 
    }
    
    // fetch  the branch master on the basisof record Id..added by mansur alam
    public List<Branch_Master__c> getBranchById(set<Id> branchId) {
        fflib_QueryFactory query = newQueryFactory();
         query.selectField('City__r.Name');
        query.setCondition('Id IN :branchId');
        return (List<Branch_Master__c>) Database.query(query.toSOQL());
    }
    
    public List<Branch_Master__c> selectRoundRobinRecords(set<Id> ids){
        String query = String.format(
            'select {0} from {1} ' +
            'where Id IN : ids ',
            new List<String> {
                getFieldListString(),
                    getSObjectName()
                    }
        );
        return (List<Branch_Master__c>) Database.query(query);
    }
}