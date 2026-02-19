/**
* @File Name          : LoanApplicantsSelector.cls
* @Description        : This class used to fetch/query Loan Applications based on conditions.
* @Author             : Riteek Tiwari
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         18-06-2025              Riteek Tiwari            Initial Version
*/
public with sharing class LoanApplicantsSelector extends fflib_SObjectSelector {
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Loan_Applicant__c.Id,
                Loan_Applicant__c.Pan_Number__c,
                Loan_Applicant__c.Mobile_Number__c,
                Loan_Applicant__c.First_Name__c,
                Loan_Applicant__c.Last_Name__c,
                Loan_Applicant__c.Email__c,
                Loan_Applicant__c.PAN_Verification__c,
                Loan_Applicant__c.Mobile_Verification__c,
                Loan_Applicant__c.Digilocker_Verification__c,
                Loan_Applicant__c.Alternate_Mobile_Number__c,
                Loan_Applicant__c.Aadhaar_Face_Extraction_Verification__c,
                Loan_Applicant__c.PAN_Face_Extraction_Verification__c,
                Loan_Applicant__c.Insurance_Verification__c,
                Loan_Applicant__c.Udyam_Verification__c
                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return Loan_Applicant__c.sObjectType;
    }
    
    public List<Loan_Applicant__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        String deletedApplicant = 'No';
        query.selectField('Pan_Number__c');
        query.selectField('Mobile_Number__c');
        query.selectField('First_Name__c');
        query.selectField('Last_Name__c');
        query.selectField('Email__c');
        query.selectField('Digilocker_Verification__r.Transaction_Id__c');
        query.selectField('Mobile_Verification__r.Status__c');
        query.selectField('Alternate_Mobile_Verification__r.Status__c');
        query.selectField('Udyam_Verification__r.Is_Udyam_Registration_Verified__c');
        query.setCondition('Id IN : recordIds');
        System.debug('query   '+query);
        SYstem.debug('Database.query( query.toSOQL() )  '+Database.query( query.toSOQL() ));
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL() );
    }
    
    public List<Loan_Applicant__c> getMobileApplicant(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        String deletedApplicant = 'No';
        query.selectField('Pan_Number__c');
        query.selectField('Mobile_Number__c');
        //query.setCondition('Id IN : recordIds AND Mobile_Number__c =: mobileNumber');
        System.debug('query Mobile  '+query);
        System.debug('Database.query( query.toSOQL() )  '+Database.query( query.toSOQL() ));
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL() );
    }
    
    
    public List<Loan_Applicant__c> selectByIdWithParentRecords(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        // fflib_SObjectSelector accountsSelector = new UB_AccountsSelector();
        // accountsSelector.configureQueryFactoryFields(query, 'Account__r');
        //fflib_SObjectSelector verificationSelector = new UB_VerificationsSelector();
        //  verificationSelector.configureQueryFactoryFields(query, 'Aadhar_Verification__r');
        // fflib_SObjectSelector loanApplicationSelector = new UB_LoanApplicationsSelector();
        // loanApplicationSelector.configureQueryFactoryFields(query, 'Loan_Application__r');
        //  loanApplicationSelector.configureQueryFactoryFields(query, 'Loan_Application__r.Branch__r');
        //Added isDeleted Check for the soft delete functionality by lakshya Verma on 16-07-2024
        Boolean deletedApplicant = false;
        query.setCondition('Id IN : recordIds AND IsDeleted__c =: deletedApplicant');
        query.selectField('Application__r');
        query.selectField('Application__r.Product__c');
        //query.selectField('Application__r.isReadOnly__c');
        query.selectField('Application__r.Applied_Loan_Amount__c');
        query.selectField('Application__r.Tenure__c');
        system.debug('query==>'+query.toSOQL());
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL() );
    }
    
    public List<Loan_Applicant__c> selectByIdWithLoanApplication(Set<Id> loanApplicationId){
        fflib_QueryFactory query = newQueryFactory();
        // fflib_SObjectSelector loanApplicationSelector = new UB_LoanApplicationsSelector();
        // fflib_SObjectSelector verificationSelector = new UB_VerificationsSelector();
        // new UB_VerificationsSelector().configureQueryFactoryFields(query,'Cibil_Verification__r');
        // new UB_VerificationsSelector().configureQueryFactoryFields(query,'Aadhaar_Verification__r');
        // new UB_VerificationsSelector().configureQueryFactoryFields(query,'Perfios_Verification__r');
        // new UB_AddressesSelector().addQueryFactorySubselect(query,'Addresses__r');
        //Added isDeleted Check for the soft delete functionality by lakshya Verma on 16-07-2024
        String deletedApplicant = 'No';
        query.setCondition('Loan_Application__c IN : loanApplicationId AND IsDeleted__c =: deletedApplicant ');
        query.selectField('Loan_Application__r.LOB__c');
        query.selectField('BL_RBI_Willful_Defaulter_Check__c');
        query.selectField('BL_Personal_Discussion_Waived__c');
        query.selectField('BL_Office_FI_Waived__c');
        query.selectField('BL_Residence_FI_Waived__c');
        query.selectField('BL_Permanent_Address_FI_Waived__c');
        query.selectField('Perfios_ITR_Analysis_Verification__c');
        query.selectField('Perfios_GST_Analysis_Verification__c');
        query.selectField('Perfios_ITR_Analysis_Verification__c.Status__c');
        query.selectField('Perfios_GST_Analysis_Verification__r.Status__c');
        query.selectField('Cibil_Verification__r.Status__c');
        query.selectField('BL_Income_Considered__c');
        query.selectField('BL_GST_Applicable__c');
        query.selectField('Constitution__c');
        query.selectField('IsDeleted__c');
        query.selectField('BL_CIBIL_Score__c');
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL() );
    }
    
    
    
  
    
    
    /*
* @Author      : Preeti
* @Date        : 02/07/2025
* @description Fetches the primary Loan Applicant record for a given Loan Application Id.
* Specifically retrieves the applicant where Applicant_Type__c = 'Primary Applicant', which is required for CIBIL API processing.
* The method selects key personal and identification fields necessary for the API request.
* @param applicationId - The Id of the Application__c record for which the Loan Applicant needs to be fetched.
* @return Loan_Applicant__c record if found, otherwise null.
*/
    public Loan_Applicant__c selectLoanApplicantForCIBIL(Id applicationId) {
        String query = newQueryFactory()
            .selectField('Id')
            .selectField('First_Name__c')
            .selectField('Middle_Name__c')
            .selectField('Last_Name__c')
            .selectField('Gender__c')
            .selectField('Date_of_Birth__c')
            .selectField('Mobile_Number__c')
            .selectField('Pan_Number__c')
            .selectField('Applicant_Type__c')
            .setCondition('Application__c = :applicationId AND Applicant_Type__c = \'Primary Applicant\'')
            .toSOQL();
        
        List<Loan_Applicant__c> loanApplicantList = Database.query(query);
        return loanApplicantList.isEmpty() ? null : loanApplicantList[0];
    }
    

    
}