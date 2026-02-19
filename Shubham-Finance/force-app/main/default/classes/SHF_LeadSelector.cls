/**
* @File Name          : SHF_LeadSelector.cls
* @Author             : Kunal soni
* @Last Modified By   : kunal soni
* @Last Modified On   : 19-06-2025
* @Description        : this class is used for fatching the Lead records.
*================================================================================================
* Update Ver         Date                     Author                 Modification                    
*================================================================================================
* 1.0              19-06-2025              	Kunal soni             	Initial Version            
*/
public class SHF_LeadSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{ 
            Lead__c.Id, 
                Lead__c.Branch__c, 
                Lead__c.First_Name__c,
                Lead__c.Branch_Code__c,
                Lead__c.Name,
                Lead__c.Full_Name__C,
                Lead__c.Contact_No1__c,
                Lead__c.Rejected_By__c,
                Lead__c.Channel__c,
                Lead__c.Lead_Source__c,
                Lead__c.OwnerId,
                Lead__c.CreatedDate,
                Lead__c.IsImported__c,
                Lead__c.CRIF_Score__c,
                Lead__c.Entity_Name__c,
                Lead__c.Lead_Status__c
                }; 
                    }
        /**
    * @Description: Select required object. 
    * @Return: Schema.SObjectType.
    */
        public Schema.SObjectType getSObjectType() { 
            return Lead__c.SObjectType; 
        }
    
    	// leads with branch name
        public List<Lead__c> selectByIdsWithBranchName(Set<Id> leadIds){
            String query = newQueryFactory().selectFields(new List<String>{'Owner.Name','Branch__r.Name'}).setCondition('Id In : leadIds').
                toSOQL();
            return (List<Lead__c>) Database.query(query);
        }
    
      // Fetch Leads by Ids for CRIF_Score__c update
    public List<Lead__c> selectByIdsForCrifScore(Set<Id> leadIds){
        String query = newQueryFactory()
        .selectFields(new List<String>{ 'CRIF_Score__c' }).setCondition('Id IN :leadIds').toSOQL();
        return (List<Lead__c>) Database.query(query);
    }
    
}