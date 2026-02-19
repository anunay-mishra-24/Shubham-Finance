/**
* @File Name          : SHF_AddressesSelector.cls
* @Description        : This class is used to fetch/query Address__c records based on conditions.
* @Author             : Riteek Tiwari
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         01-07-2025              Riteek Tiwari          
*/
public class AddressesSelector extends fflib_SObjectSelector {

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
            Address__c.Id,
            Address__c.Name,
            Address__c.Address_Type__c,
            Address__c.Address_Line_1__c,
            Address__c.Address_Line_2__c,
            Address__c.Address_Line_3__c,
            Address__c.Address_Location__c,
             Address__c.Address_Location__Latitude__s,
              Address__c.Address_Location__Longitude__s,
            Address__c.District__c,
            Address__c.Duration_at_Current_Address__c,
            Address__c.Duration_at_Current_City__c,
            Address__c.Flat_Plot_Number__c,
            Address__c.Full_Address__c,
            Address__c.Is_Address_Verified__c,
            Address__c.is_Deleted__c,
            Address__c.Is_Primary_Address__c,
            Address__c.Landmark__c,
            Address__c.Loan_Applicant__c,
            Address__c.Region__c,
            Address__c.Taluka__c,
            Address__c.Village__c,
             Address__c.Applicant_RecordType_Name__c,
              Address__c.Residence_same_as_Permanent_Address__c,
              Address__c.Mailing_Address__c,
               Address__c.Distance_From_Branch__c,
                Address__c.ODV__c,
                 Address__c.OGL__c,
            Address__c.Pincode__c
        }; 
    }

    public Schema.SObjectType getSObjectType() { 
        return Address__c.SObjectType; 
    }

    public List<Address__c> selectByIdsApplicantName(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Name');
         query.selectField('Loan_Applicant__r.Application__r.Branch__c'); // Add other fields you need
        query.setCondition('Id IN :recordIds AND is_Deleted__c = \'Active\'');
        return (List<Address__c>) Database.query(query.toSOQL());
    }

    public List<Address__c> selectCurrentAddressesByApplicantIds(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Loan_Applicant__c IN :recordIds AND Address_Type__c = \'Current Address\' AND is_Deleted__c = \'Active\'');
        //query.orderBy('CreatedDate'); // ascending order
        query.setLimit(1);
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    
    public List<Address__c>allAddressByApplicantIds(Set<Id> applicantId) {
        fflib_QueryFactory query = newQueryFactory();
         query.selectField('Address_Type__c');
          query.selectField('Mailing_Address__c');
          query.selectField('Pincode__r.Name');
        query.setCondition('Loan_Applicant__c IN :applicantId AND is_Deleted__c = \'Active\'');
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    
    
    /*
* @Author      : Preeti
* @Date        : 02/07/2025
* @description Fetches the list of Address__c records associated with the provided Loan Applicant Id.
* This method is used to retrieve the address details required for the CIBIL API request.
* It selects key address fields including Address Type, Address Lines, City, Pincode, and State.
* @param loanApplicantId - The Id of the Loan_Applicant__c record whose addresses need to be fetched.
* @return List of Address__c records linked to the provided Loan Applicant.
*/
    
    public List<Address__c> selectAddressesForCIBIL(Id loanApplicantId) {
        String query = newQueryFactory()
            .selectField('Id')
            .selectField('Address_Type__c')
            .selectField('Mailing_Address__c')
            .selectField('Address_Line_1__c')
            .selectField('Address_Line_2__c')
            .selectField('Address_Line_3__c')
            .selectField('City__c')
            .selectField('Pincode__c')
            .selectField('State__c')
            .setCondition('Loan_Applicant__c = :loanApplicantId AND is_Deleted__c = \'Active\'')
            .toSOQL();
        
        return Database.query(query);
    }
}