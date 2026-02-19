/**
* @File Name          : SHF_DocumentCheckListSelector.cls
* @Description        : Fetch Document Checklist records with context-aware filtering.
* @Author             : Akshi Sharma
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         25-06-2025              Akshi Sharma            Initial Version
* 2.0         22-09-2025              Akshi Sharma            Added All Profiles + Optimized context filtering
*/
public class SHF_DocumentCheckListSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Document_Checklist__c.Id,
            Document_CheckList__c.Name,
            Document_Checklist__c.Document_Stage__c,
            Document_Checklist__c.Applicable_For__c,
            Document_Checklist__c.Customer_Profile_FinnOne__c,
            Document_Checklist__c.Document_Category__c,
            Document_Checklist__c.Document_Source__c,
            Document_Checklist__c.Document_Type__c,
            Document_Checklist__c.Is_Active__c,
            Document_Checklist__c.Mandatory_Optional__c          
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Document_Checklist__c.sObjectType;
    }
   
    public List<Document_Checklist__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN :recordIds');
        return (List<Document_Checklist__c>) Database.query(query.toSOQL());
    }

    /**
     * Main reusable selector method.
     * Handles Loan vs Applicant contexts, and supports All Profiles.
     *
     * @param stages          - stages to filter by (cumulative)
     * @param applicableFor   - 'Loan' or 'All Applicants'
     * @param customerProfileId - profile for applicant (null when context is Loan)
     */
    public List<Document_Checklist__c> selectForContext(
        List<String> stages,
        String applicableFor,
        String customerProfileId
    ){
        fflib_QueryFactory query = newQueryFactory();
        query.selectFields(getSObjectFieldList());
        
        List<String> conditions = new List<String>{
            'Is_Active__c = true',
            'Mandatory_Optional__c = \'Mandatory\'',
            'Applicable_For__c = :applicableFor'
            //'Document_Stage__c IN :stages'
        };
        
        if (applicableFor == 'All Applicants') {
            if (String.isNotBlank(customerProfileId)) {
                // Include both "All Profiles" and the specific applicant profile
                conditions.add('(Customer_Profile_FinnOne__c = \'All Profile\' OR Customer_Profile_FinnOne__c = :customerProfileId)');
            } else {
                // No applicant profile available → only "All Profile"
                conditions.add('Customer_Profile_FinnOne__c = \'All Profile\'');
            }
        }
        
        query.setCondition(String.join(conditions, ' AND '));
        return (List<Document_Checklist__c>) Database.query(query.toSOQL());
    }
    
    /*public List<Document_Checklist__c> selectByStagesAndContext(List<String> stages, String applicableFor, String customerProfileId){
        fflib_QueryFactory query = newQueryFactory();
        query.selectFields(getSObjectFieldList());
        
        List<String> conditions = new List<String>();
        
        conditions.add('Is_Active__c = true');
        conditions.add('Mandatory_Optional__c = \'Mandatory\'');
        conditions.add('Applicable_For__c = :applicableFor');
        conditions.add('Document_Stage__c IN :stages');
        
        if (applicableFor == 'All Applicants' && customerProfileId != null) {
            conditions.add('Customer_Profile_FinnOne__c = :customerProfileId');
        }
        
        query.setCondition(String.join(conditions, ' AND '));
        return (List<Document_Checklist__c>) Database.query(query.toSOQL());
    }*/


    public List<Document_Checklist__c> selectByCondition(String condition){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition(condition);
        return (List<Document_Checklist__c>) Database.query(query.toSOQL());
    }
}