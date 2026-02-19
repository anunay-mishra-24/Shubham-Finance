/**
* @File Name          : SHF_CollateralSelector.cls
* @Description        : This class is used to fetch/query Address__c records based on conditions.
* @Author             : Mansur
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         25-09-2025             Mansur  
*/
public class SHF_CollateralSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
            Collateral__c.Id,
                Collateral__c.Name,
                Collateral__c.Application__c,
                Collateral__c.Property_Type__c,
                 Collateral__c.Property_Address__c,
                 Collateral__c.Property_Owner__c,
              Collateral__c.Primary_Collateral__c,
              Collateral__c.Collateral_Sub_Type_Property_Details__c,
              Collateral__c.Property_Address__longitude__s,
              Collateral__c.Property_Address__latitude__s,
                Collateral__c.LTV__c
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return Collateral__c.SObjectType; 
    }
    
    public List<Collateral__c> selectByIds(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Name'); // Add other fields you need
         query.selectField('Property_Owner__r.Applicant_Age__c'); 
        query.setCondition('Id IN :recordIds');
        return (List<Collateral__c>) Database.query(query.toSOQL());
    }
    
    public List<Collateral__c> selectByApplicationId(Set<Id> applicationId) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Name'); // Add other fields you need
         query.selectField('Property_Owner__r.Applicant_Age__c'); 
        query.setCondition('Application__c IN :applicationId');
        return (List<Collateral__c>) Database.query(query.toSOQL());
    }

    public Collateral__c selectByCollateralId(Id collateralId) {
        fflib_QueryFactory query = newQueryFactory();

        query.selectField('Id');
        query.selectField('Application__c');
        query.selectField('Collateral_Sub_Type_Property_Details__c');
        query.selectField('Property_Type__c');
        query.selectField('Property_Description__c');
        query.selectField('Nature_of_Property__c');
        query.selectField('Type_Of_Purchase__c');
        query.selectField('Property_Classification__c');
        query.selectField('Built_Up_Area__c');
        query.selectField('Carpet_Area__c');
        query.selectField('Type_of_property__c');
        query.selectField('Residual_Age_of_Property__c');
        query.selectField('Property_cost_INR__c');
        query.selectField('Address_Type__c');
        query.selectField('Address_Line_2__c');
        query.selectField('Pincode__c');
        query.selectField('State__c');
        query.selectField('City__c');
        query.selectField('Company_Name__c');
        query.selectField('Company_Name__r.Builder_Code__c');
        query.selectField('Project_Name__c');
        query.selectField('Project_Name__r.Project_Code__c');
        query.selectField('Property_Ownership__c');

        query.setCondition('Id = :collateralId');

        List<Collateral__c> results =
            (List<Collateral__c>) Database.query(query.toSOQL());

        return results.isEmpty() ? null : results[0];
    }

}