/**
* @File Name          : SHF_RoundRobinSelector.cls
* @Author             : Kunal soni
* @Last Modified By   : kunal soni
* @Last Modified On   : 19-06-2025
* @Description        : this class is used for fatching the Round Robin records.
*================================================================================================
* Update Ver         Date                     Author                 Modification                    
*================================================================================================
* 1.0              19-06-2025              	Kunal soni             	Initial Version            
*/
public class SHF_RoundRobinSelector extends fflib_SObjectSelector {
    
     	/**
        * @Description: Select necessary fields. 
        * @Return: List<Schema.SObjectField>.
        */
    
    public List<Schema.SObjectField> getSObjectFieldList() { 
        return new List<Schema.SObjectField>{ 
            Round_Robin__c.Id, 
                Round_Robin__c.Branch_Name__c, 
                Round_Robin__c.Is_Active__c,
                Round_Robin__c.User__c,
                Round_Robin__c.Last_Assigned__c,
                Round_Robin__c.User_Email__c,
                Round_Robin__c.LOB__c,
                Round_Robin__c.User_Name__c
               
                }; 
                    }
        /**
    * @Description: Select required object. 
    * @Return: Schema.SObjectType.
    */
    public Schema.SObjectType getSObjectType() { 
        return Round_Robin__c.SObjectType; 
    }
    
    public override String getOrderBy() {
        return 'Last_Assigned__c';
    }
     
/* @Description: Round Robin records with Round_Robin_Name__c and User information
     */
    public List<Round_Robin__c> selectRoundRobinByName(String lob) {
        String query = newQueryFactory()
            .selectField('Branch_Name__r.Name')
            .selectFields(new List<String>{'User__r.Name', 'User__r.Phone'})
            .setCondition('Is_Active__c = true AND LOB__c =: lob')
            .toSOQL();
        return (List<Round_Robin__c>) Database.query(query);
    }

}