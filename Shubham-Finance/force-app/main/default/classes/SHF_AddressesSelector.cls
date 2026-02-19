/**
* @File Name          : SHF_AddressesSelector.cls
* @Description        : This class is used to fetch/query Address__c records based on conditions.
* @Author             : Riteek Tiwari
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         03-07-2025              Riteek Tiwari          
*/
public class SHF_AddressesSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
            Address__c.Id,
                Address__c.Name,
                Address__c.Address_Type__c,
                Address__c.Address_Line_1__c,
                Address__c.Address_Line_2__c,
                Address__c.Address_Line_3__c,
               Address__c.Pincode__c,
                Address__c.City__c,
                Address__c.District__c,
                 Address__c.Address_Location__c,
                Address__c.State__c,
                Address__c.Mailing_Address__c,
                Address__c.Country__c,
                Address__c.Pincode__r.Name
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return Address__c.SObjectType; 
    }
    
    public List<Address__c> selectByIdsApplicantName(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('City__c');// Add other fields you need
        query.selectField('State__c');
        query.setCondition('Loan_Applicant__c IN :recordIds');
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    
    /** @Author      : Riteek
      * @Date        : 02/07/2025*/    
    public List<Address__c> selectCurrentAddressesByApplicantIds(Set<Id> recordIds) {    
        fflib_QueryFactory query = new fflib_QueryFactory(Address__c.sObjectType);
        query.selectField('Address_Type__c'); 
        query.setCondition('Loan_Applicant__c IN :recordIds AND Mailing_Address__c IN (\'Current Address\')');
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    public List<Address__c> selectPermanentAddressesByApplicantIds(Set<Id> recordIds) {    
        fflib_QueryFactory query = new fflib_QueryFactory(Address__c.sObjectType);
        query.setCondition('Loan_Applicant__c IN :recordIds AND Mailing_Address__c IN (\'Permanent Address\')');
        return (List<Address__c>) Database.query(query.toSOQL());
    }
    
     public List<Address__c> selectAddressByApplicantIds(Set<Id> recordIds) {    
        fflib_QueryFactory query = new fflib_QueryFactory(Address__c.sObjectType);
        query.selectField('State__c'); 
        query.selectField('District__c'); 
        query.setCondition('Loan_Applicant__c IN :recordIds');
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
    System.debug('Step 1: selectAddressesForCIBIL called with loanApplicantId: ' + loanApplicantId);
    Logger.info('Step 1: selectAddressesForCIBIL called with loanApplicantId: ' + loanApplicantId);
    
    // Check if Id is valid
    if (loanApplicantId == null) {
        System.debug('ERROR: Invalid loanApplicantId passed. Returning empty list.');
        Logger.error('Invalid loanApplicantId passed. Returning empty list.');
        return new List<Address__c>();
    }
    
    try {
        String query = newQueryFactory()
            .selectField('Id')
            .selectField('Address_Type__c')
            .selectField('Address_Line_1__c')
            .selectField('Address_Line_2__c')
            .selectField('Address_Line_3__c')
            .selectField('City__c')
            .selectField('Pincode__r.Name')
            .selectField('State__c')
            .setCondition('Loan_Applicant__c = :loanApplicantId AND is_Deleted__c = \'Active\'' )
            .toSOQL();
        
        System.debug('Step 2: Executing query: ' + query);
        Logger.info('Executing query: ' + query);
        
        List<Address__c> result = Database.query(query);
        
        System.debug('Step 3: Number of addresses fetched: ' + (result != null ? result.size() : 0));
        Logger.info('Number of addresses fetched: ' + (result != null ? result.size() : 0));
        
        return result;
        
    } catch (Exception e) {
        System.debug('ERROR: Exception in selectAddressesForCIBIL: ' + e.getMessage());
        System.debug('Stack Trace: ' + e.getStackTraceString());
        Logger.error('Exception in selectAddressesForCIBIL: ' + e.getMessage());
        Logger.error('Stack Trace: ' + e.getStackTraceString());
        return new List<Address__c>();
    }
}

    /** @Author      : Dimple
      * @Date        : 28/12/2025*/    
 public List<Address__c> selectAddressesForHunter(Id loanApplicantId) {
    
    // Check if Id is valid
    if (loanApplicantId == null) {
        System.debug('ERROR: Invalid loanApplicantId passed. Returning empty list.');
        Logger.error('Invalid loanApplicantId passed. Returning empty list.');
        return new List<Address__c>();
    }
    
    try {
        String query = newQueryFactory()
           .selectField('Id')
           .selectField('Address_Type__c') 
            .selectField('Address_Line_1__c')
            .selectField('Address_Line_2__c')
            .selectField('Address_Line_3__c')
            .selectField('City__c')
            .selectField('Pincode__r.Name')
            .selectField('State__c')
            .selectField('Country__c')
            .setCondition('Loan_Applicant__c = :loanApplicantId '+'AND (Mailing_Address__c = \'Permanent Address\' ' +
                         'OR Mailing_Address__c = \'Residential Address\')')
            .toSOQL();
        
        Logger.info('Executing query: ' + query);
        
        List<Address__c> result = Database.query(query);
        
        Logger.info('Number of addresses fetched: ' + (result != null ? result.size() : 0));
        
        return result;
        
    } catch (Exception e) {
        System.debug('ERROR: Exception in selectAddressesForHunter: ' + e.getMessage());
        System.debug('Stack Trace: ' + e.getStackTraceString());
        Logger.error('Exception in selectAddressesForHunter: ' + e.getMessage());
        Logger.error('Stack Trace: ' + e.getStackTraceString());
        return new List<Address__c>();
    }
}

/*
* @Author      : Vikas 
* @Date        : 15/01/2026
* @description Fetches the list of Address__c records associated with the provided Loan Applicant Id.
* This method is used to retrieve the address details required for the Lms API request.
* It selects key address fields including Address Type, Address Lines, City, Pincode, and State.
* @param loanApplicantId - The Id of the Loan_Applicant__c record whose addresses need to be fetched.
* @return List of Address__c records linked to the provided Loan Applicant.
*/
    
    public List<Address__c> selectAddressesForLMS(Id loanApplicantId) {
    System.debug('Step 1: selectAddressesForLMS called with loanApplicantId: ' + loanApplicantId);
    Logger.info('Step 1: selectAddressesForLMS called with loanApplicantId: ' + loanApplicantId);
    
    // Check if Id is valid
    if (loanApplicantId == null) {
        System.debug('ERROR: Invalid loanApplicantId passed. Returning empty list.');
        Logger.error('Invalid loanApplicantId passed. Returning empty list.');
        return new List<Address__c>();
    }
    
    try {
        String query = newQueryFactory()
            .selectField('Id')
            .selectField('Is_Primary_Address__c')
            .selectField('Address_Type__c')
            .selectField('Address_Line_1__c')
            .selectField('Address_Line_2__c')
            .selectField('Address_Line_3__c')
            .selectField('Village__c')
            .selectField('District__c')
            .selectField('Pincode__r.Name')
            .selectField('Pincode__r.City_Master__r.Name')
            .selectField('Landmark__c')
            .selectField('Region__c')
            .selectField('Taluka__c')
            .selectField('Mailing_Address__c')
            .selectField('State__c')
            .selectField('Duration_at_current_address_In_Months__c')
            .selectField('Duration_at_current_city_In_Months__c')
            .selectField('Is_Address_Verified__c')
            .setCondition('Loan_Applicant__c = :loanApplicantId ' )
            .toSOQL();
        
        System.debug('Step 2: Executing query: ' + query);
        Logger.info('Executing query: ' + query);
        
        List<Address__c> result = Database.query(query);
        
        System.debug('Step 3: Number of addresses fetched: ' + (result != null ? result.size() : 0));
        Logger.info('Number of addresses fetched: ' + (result != null ? result.size() : 0));
        
        return result;
        
    } catch (Exception e) {
        System.debug('ERROR: Exception in selectAddressesForLMS: ' + e.getMessage());
        System.debug('Stack Trace: ' + e.getStackTraceString());
        Logger.error('Exception in selectAddressesForLMS: ' + e.getMessage());
        Logger.error('Stack Trace: ' + e.getStackTraceString());
        return new List<Address__c>();
    }
}


public List<Address__c> selectAddressesForLitigation(Id loanApplicantId) {
    System.debug('Step 1: selectAddressesForLitigation called with loanApplicantId: ' + loanApplicantId);
    Logger.info('Step 1: selectAddressesForLitigation called with loanApplicantId: ' + loanApplicantId);
    
    // Check if Id is valid
    if (loanApplicantId == null) {
        System.debug('ERROR: Invalid loanApplicantId passed. Returning empty list.');
        Logger.error('Invalid loanApplicantId passed. Returning empty list.');
        return new List<Address__c>();
    }
    
    try {
        String query = newQueryFactory()
            .selectField('Id')
            .selectField('Loan_Applicant__c')
            .selectField('Full_Address__c')
            .selectField('Mailing_Address__c')
            .setCondition('Loan_Applicant__c = :loanApplicantId ' )
            .toSOQL();
        
        List<Address__c> result = Database.query(query);
        
        System.debug('Step 3: Number of addresses fetched: ' + (result != null ? result.size() : 0));
        Logger.info('Number of addresses fetched: ' + (result != null ? result.size() : 0));
        
        return result;
        
    } catch (Exception e) {
        System.debug('ERROR: Exception in selectAddressesForLitigation: ' + e.getMessage());
        System.debug('Stack Trace: ' + e.getStackTraceString());
        Logger.error('Exception in selectAddressesForLitigation: ' + e.getMessage());
        Logger.error('Stack Trace: ' + e.getStackTraceString());
        return new List<Address__c>();
    }
}

//Added By Riteek
    public List<Address__c> fetchAddressesForAPI(Id loanApplicantId) {
        if (loanApplicantId == null) {
            System.debug('Invalid loanApplicantId passed. Returning empty list.');
            return new List<Address__c>();
        }
        
        try {
            fflib_QueryFactory query = newQueryFactory();
            query.selectField('Id');
            query.selectField('Address_Type__c');
            query.selectField('Address_Line_1__c');
            query.selectField('Address_Line_2__c');
            query.selectField('Address_Line_3__c');
            query.selectField('City__c');
            query.selectField('State__c');
            query.selectField('District__c');
            query.selectField('Country__c');
            query.selectField('Mailing_Address__c');
            query.selectField('Is_Primary_Address__c');
            query.selectField('Pincode__c');           
            query.selectField('Pincode__r.Name');      
            //query.selectField('Pincode__r.City_Master__r.Name'); 
            query.setCondition('Loan_Applicant__c = :loanApplicantId AND is_Deleted__c = \'Active\'');
            
            List<Address__c> addresses = (List<Address__c>) Database.query(query.toSOQL());
            return addresses;
        } catch (Exception ex) {
            System.debug('Exception in fetchAddressesForAPI: ' + ex.getMessage()+' LineNumber > '+ex.getLineNumber());
            Logger.error('Stack Trace: ' + ex.getStackTraceString());
            return new List<Address__c>();
        }
    }
    
    //--------Ashutosh Dubey SHF-1596 19 Feb, 2026 starts ----------------------------//
    public List<Address__c> fetchAddressesForLeegality(Set<Id> loanApplicantIds) {
        if (loanApplicantIds == null) {
            System.debug('Invalid loanApplicantId passed. Returning empty list.');
            return new List<Address__c>();
        }
        
        try {
            fflib_QueryFactory query = newQueryFactory();
            query.selectField('Id');
            query.selectField('Address_Type__c');
            query.selectField('Address_Line_1__c');
            query.selectField('Address_Line_2__c');
            query.selectField('Address_Line_3__c');
            query.selectField('City__c');
            query.selectField('State__c');
            query.selectField('District__c');
            query.selectField('Country__c');
            query.selectField('Mailing_Address__c');
            query.selectField('Is_Primary_Address__c');
            query.selectField('Pincode__c');           
            query.selectField('Pincode__r.Name'); 
            query.selectField('Loan_Applicant__c');
            //query.selectField('Pincode__r.City_Master__r.Name'); 
            query.setCondition('Loan_Applicant__c IN :loanApplicantIds AND is_Deleted__c = \'Active\'');
            
            List<Address__c> addresses = (List<Address__c>) Database.query(query.toSOQL());
            return addresses;
        } catch (Exception ex) {
            System.debug('Exception in fetchAddressesForAPI: ' + ex.getMessage()+' LineNumber > '+ex.getLineNumber());
            Logger.error('Stack Trace: ' + ex.getStackTraceString());
            return new List<Address__c>();
        }
    }
	//--------Ashutosh Dubey SHF-1596 19 Feb, 2026 ends ----------------------------//
}