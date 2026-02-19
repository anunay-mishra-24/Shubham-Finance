public with sharing class SHF_LoanApplicantsSelector extends fflib_SObjectSelector {
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Loan_Applicant__c.Id,
            Loan_Applicant__c.Account_Name__c,
            Loan_Applicant__c.Pan_Number__c,
            Loan_Applicant__c.Date_of_Birth__c,
            Loan_Applicant__c.First_Name__c,
            Loan_Applicant__c.Middle_Name__c,
            Loan_Applicant__c.Last_Name__c,
            Loan_Applicant__c.Date_of_Birth__c,
            Loan_Applicant__c.Gender__c,
            Loan_Applicant__c.CreatedDate,
            Loan_Applicant__c.Applicant_Type__c,
            Loan_Applicant__c.Name,
            Loan_Applicant__c.Application__c,
            Loan_Applicant__c.Total_Working_Experience__c,
            Loan_Applicant__c.Email__c,
            Loan_Applicant__c.Entity_Name__c, // add by vikas soni on 18-11-2025 for parul
            Loan_Applicant__c.Hunter_Verification__c, // dimple
            Loan_Applicant__c.CKYC_Reference_ID__c,
            Loan_Applicant__c.Mobile_Number__c,
            Loan_Applicant__c.Passport_File_Number__c,
            Loan_Applicant__c.Driving_License_Number__c,
            Loan_Applicant__c.GST_Number__c,
            Loan_Applicant__c.PAN_Verification__c,
            Loan_Applicant__c.GST_Verification__c,
            Loan_Applicant__c.Penny_Drop_Verification__c,
            Loan_Applicant__c.Electricity_Verification__c,
            Loan_Applicant__c.Digilocker_Verification__c,
            Loan_Applicant__c.Mobile_Verification__c,
            Loan_Applicant__c.Udyam_Registration_Number__c,
            Loan_Applicant__c.Udyam_Verification__c,
            Loan_Applicant__c.AML_Verification__c,
            Loan_Applicant__c.Address__c,
            Loan_Applicant__c.Date_Of_Incorporation__c,
            Loan_Applicant__c.Constitution__c,
            Loan_Applicant__c.Applicant_Age__c,
            Loan_Applicant__c.Borrower_is_an_Investor__c,
            Loan_Applicant__c.Customer_Info_File_Number__c,
            Loan_Applicant__c.Fathers_Name__c,
            Loan_Applicant__c.Marital_Status__c,
            Loan_Applicant__c.Customer_Category__c,
            Loan_Applicant__c.Total_Income__c,
            Loan_Applicant__c.Appraised_Income__c,
            //Loan_Applicant__c.Bank_Details__c,
            Loan_Applicant__c.Industry__c,
            Loan_Applicant__c.Mobile_Verification__c,
            Loan_Applicant__c.Alternate_Mobile_Verification__c,
            Loan_Applicant__c.Alternate_Mobile_Number__c,
            Loan_Applicant__c.Customer_Type__c,
            Loan_Applicant__c.VoterId_Verification__c,
            Loan_Applicant__c.IsFinancial_Applicant__c,
            Loan_Applicant__c.Voter_Id_Number__c,
            Loan_Applicant__c.Passport_Verification__c,
            Loan_Applicant__c.Customer_Profile__c,
            Loan_Applicant__c.DL_Verification__c,
            Loan_Applicant__c.Relationship_with_Applicant__c ,
            Loan_Applicant__c.IsDeleted__c  ,
            Loan_Applicant__c.SMS_Consent__c,
            Loan_Applicant__c.Is_Pan_Verified__c,
            Loan_Applicant__c.Is_SMS_Consent_Given__c,
            Loan_Applicant__c.Risk_Score_Thik_Weight__c,
            Loan_Applicant__c.Risk_Score_Thin_Weight__c,
            Loan_Applicant__c.Final_Risk_Score__c ,
            Loan_Applicant__c.CRIF_Verification__c ,
            Loan_Applicant__c.CIBIL_Verification__c ,
            Loan_Applicant__c.RecordType_Name__c ,
            Loan_Applicant__c.Email_Verification__c,
            Loan_Applicant__c.Is_Aadhar_Fetched__c,
            Loan_Applicant__c.Joint_Exposure__c,
            Loan_Applicant__c.Aadhar_Number__c,
            Loan_Applicant__c.Profession_Category__c,
            Loan_Applicant__c.Insurance_Verification__c,
            Loan_Applicant__c.Date_Of_Incorporation1__c,
            //Loan_Applicant__c.CAM_s_Account_Verification__c,
            Loan_Applicant__c.Account_Aggregator_CAM__c,
            Loan_Applicant__c.Aadhaar_Verification_Count__c,
            Loan_Applicant__c.Employment_Type__c
        };
    }
    
    public Schema.SObjectType getSObjectType(){
        return Loan_Applicant__c.sObjectType;
    }
    
    
    public List<Loan_Applicant__c> selectByIdWithLoanApplication(Set<Id> loanApplicationId){
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Insurance_Verification__r.Negotiation_Insured_Amount__c');
        query.selectField('Insurance_Verification__r.Negotiation_Insurance_Premium__c');
        query.selectField('Insurance_Verification__r.Negotiation_Insurance_Tenure__c');
        query.selectField('Insurance_Verification__r.Original_Insurance_Premium__c');
        query.selectField('Insurance_Verification__r.Original_Insurance_Tenure__c');
        query.selectField('Insurance_Verification__r.Original_Insured_Amount__c');
        
        query.selectField('Insurance_Verification__r.Premium_Amount__c');
        query.selectField('Insurance_Verification__r.Loan_Tenure_In_Years__c'); //incase of KOtak, depend on loan_Provider__c
        query.selectField('Insurance_Verification__r.Outstanding_Loan_Tenure__c'); //incase of icici,  depend on loan_Provider__c
        query.selectField('Insurance_Verification__r.Insured_Amount__c');
        
        query.selectField('Insurance_Verification__r.Insurance_Amount_Reason_for_Change__c');
        query.selectField('Insurance_Verification__r.Insurance_Premium_Reason_for_Change__c');
        query.selectField('Insurance_Verification__r.Insurance_Tenure_Reason_for_Change__c');
        query.selectField('Insurance_Verification__r.Insurance_Provider__c');
        query.setCondition('Application__c  IN : loanApplicationId AND IsDeleted__c = false');
        new SHF_AddressesSelector().addQueryFactorySubselect(query,'Addresses1__r');
        new SHF_E_VerificationSelector().addQueryFactorySubselect(query,'E_Verifications__r');
        new SHF_DocumentSelector().addQueryFactorySubselect(query, 'Documents__r');
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL());
    }
    //Added by mansur alam
    //we can get all the adrress related to the applicant
    public List<Loan_Applicant__c> selectByApplicantId(Set<Id> applicantId){
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id  IN : applicantId');
        new SHF_AddressesSelector().addQueryFactorySubselect(query,'Addresses1__r');
        new SHF_E_VerificationSelector().addQueryFactorySubselect(query,'E_Verifications__r');
        new SHF_DocumentSelector().addQueryFactorySubselect(query, 'Documents__r');
        ////we can get parent records of  applicant
        // new UB_VerificationsSelector().configureQueryFactoryFields(query,'Cibil_Verification__r');
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL());
    }
    
    //Added by riteek
    public List<Loan_Applicant__c> selectById(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        String deletedApplicant = 'No';
        query.selectField('Pan_Number__c');
        query.selectField('UAN_Number__c');
        query.selectField('Date_Of_Incorporation1__c');
        query.selectField('Litigation_Instant_Verification__c');
        query.selectField('Litigation_Advance_Verification__c');
        query.selectField('Digilocker_Verification__r.Transaction_Id__c');
        query.selectField('Digilocker_Verification__r.Masked_Aadhar_No__c');
        query.selectField('Digilocker_Verification__r.Request_Id__c');
        query.selectField('Digilocker_Verification__r.PAN_Full_Name__c');
        query.selectField('PAN_Verification__r.PAN_Full_Name__c');
        query.selectField('Digilocker_Verification__r.Aadhaar_Full_Name__c');
        query.selectField('Application__r.Branch__r.Branch_Code__c');
        /* query.selectField('Address__r.City__c');
        query.selectField('Address__r.Country__c');
        query.selectField('Address__r.Address_Line_1__c');
        query.selectField('Address__r.Address_Line_2__c');
        query.selectField('Address__r.Address_Line_3__c');
        query.selectField('Address__r.Address_Type__c');
        query.selectField('Address__r.District__c');
        query.selectField('Address__r.Pincode__c');
        query.selectField('Address__r.Pincode__r.Name');
        query.selectField('Address__r.State__c');
        query.selectField('Bank_Details__r.IFSC_Code__c');
        query.selectField('Bank_Details__r.Branch_Name__c');
        query.selectField('Bank_Details__r.Name');*/
            query.selectField('Mobile_Verification__r.Status__c');
        query.selectField('Discover_Verification__c');
        query.selectField('Alternate_Mobile_Verification__r.Status__c');
        query.selectField('Email_Verification__r.Status__c');
        query.selectField('Email_Verification__r.Sent_To__c');
        query.selectField('SMS_Consent__r.Status__c');
        query.selectField('SMS_Consent__r.OTP_Sent_to_Customer__c');
        query.selectField('Employment_Verification__c');
        query.selectField('Account_Aggregator_CAM__r.client_txn_id__c');
        query.selectField('Account_Aggregator_CAM__r.Consent_Handle_Periodic__c');
        query.selectField('Udyam_Verification__r.Is_Udyam_Registration_Verified__c');//Added by Dimple 22-12-25
        query.selectField('Udyam_Verification__r.Is_Udyam_Advance_Verified__c');
        query.selectField('Hunter_Verification__r.Is_Hunter_Verified__c'); //Added by Dimple
        query.selectField('Application__r.Product__r.Sub_Product_Code__c');
        query.setCondition('Id IN : recordIds AND IsDeleted__c = false');
        System.debug('query   '+query);
        SYstem.debug('Database.query( query.toSOQL() )  '+Database.query( query.toSOQL() ));
        return (List<Loan_Applicant__c>) Database.query( query.toSOQL() );
    }
    
    
    /*
     * @Author      : Preeti
     * @Date        : 02/07/2025
     * @description Fetches the Loan Applicant record for a given Loan applicant Id.
     * The method selects key personal and identification fields necessary for the API request.
     * @param applicationId - The Id of the Loan_Applicant__c record for which the Loan Applicant needs to be fetched.
     * @return Loan_Applicant__c record if found, otherwise null.
     */
    /*  public Loan_Applicant__c selectLoanApplicantForCIBIL(Id applicationId) {
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
    }*/
    
    
    public Loan_Applicant__c selectLoanApplicantForCIBIL(Id loanApplicantId) {
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
            .selectField('Application__c') // parent Id
            .selectField('Application__r.Name')
            .selectField('Application__r.Applied_Loan_Amount__c')
            .selectField('Application__r.Product__r.Product_Type__c')
            .setCondition('Id = :loanApplicantId AND IsDeleted__c = false')
            .toSOQL();
        
        List<Loan_Applicant__c> loanApplicantList = Database.query(query);
        return loanApplicantList.isEmpty() ? null : loanApplicantList[0];
    }
    
    
    
    /*
     * @Author      : Preeti
     * @Date        : 02/07/2025
     * @description Fetches an Loan_Applicant__c record by Id with required fields for Insurance API processing.
     * @param applicationId - The Id of the Loan_Applicant__c record to fetch.
     * @return Loan_Applicant__c record or null if not found.
     */
    
    public Loan_Applicant__c selectInsuranceApplicant(Id applicantId) {
        String query = newQueryFactory()
            .selectField('Id')
            .selectField('First_Name__c')
            .selectField('Last_Name__c')
            .selectField('Application__c')
            .selectField('Insurance_Verification__c')
            .selectField('Gender__c')
            .selectField('Date_of_Birth__c')
            .setCondition('Id = :applicantId AND IsDeleted__c = false')
            .toSOQL();
        
        List<Loan_Applicant__c> applicants = Database.query(query);
        return applicants.isEmpty() ? null : applicants[0];
    }
    
    /**
     * @author : Preeti
     * @Date : 2025-10-09
     * @description Counts the number of co-applicants (non-primary applicants)
     *              for a given Application__c record.
     * @param applicationId Id - record Id of the Application__c record.
     * @return Integer - Number of co-applicants associated with the application.
     */
    
    
    public Integer countCoApplicantsByApplication(Id applicationId) {
        if (applicationId == null) return 0;
        
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Application__c = :applicationId ' +
            'AND Applicant_Type__c != \'Primary Applicant\' ' +
            'AND Applicant_Type__c != null ' +
            'AND IsDeleted__c = false');
        
        List<Loan_Applicant__c> coApplicants = (List<Loan_Applicant__c>) Database.query(query.toSOQL());
        
        return coApplicants.size();
    }
    
    
    public Integer countPrimaryApplicantsByApplication(Id applicationId) {
        if (applicationId == null) return 0;
        
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Application__c = :applicationId ' +
            'AND Applicant_Type__c = \'Primary Applicant\' ' +
            'AND IsDeleted__c = false');
        
        List<Loan_Applicant__c> primaryApplicants =
            (List<Loan_Applicant__c>) Database.query(query.toSOQL());
        
        return primaryApplicants.size();
    }
    
    
    
    // NEWLY ADDED METHOD — for Address validation use case
    // Fetches all Loan_Applicant__c records for a given Application used to verify if Address is filled
    public List<Loan_Applicant__c> getApplicantsByApplication(Id applicationId) {
        if (applicationId == null) return new List<Loan_Applicant__c>();
        
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Application__c = :applicationId AND IsDeleted__c = false');
        query.selectField('Id');
        query.selectField('Name');
        query.selectField('Applicant_Type__c');
        query.selectField('Address__c');
        query.selectField('Application__c');
        query.selectField('CIBIL_Verification__r.Status__c');
        query.selectField('CRIF_Verification__r.Status__c');
        //Added by Dimple
        query.selectField('RecordTypeId');
        query.selectField('Mobile_Verification__r.Mobile_IsFound__c');
        query.selectField('Alternate_Mobile_Verification__r.Mobile_IsFound__c');
        
        query.selectField('RecordType.DeveloperName');
        
        System.debug('Fetching applicants for applicationId: ' + applicationId);
        List<Loan_Applicant__c> applicants = (List<Loan_Applicant__c>) Database.query(query.toSOQL());
        System.debug('Applicants fetched: ' + applicants);
        
        return applicants;
    }
    //  check if any applicant is missing address
    /**
     * @description Checks if any applicant for the given Application__c record
     *              has a missing Address__c.
     * @param applicationId Id - the Application__c record Id
     * @return Boolean - true if at least one applicant has missing address, false otherwise
     */
    public Boolean hasMissingApplicantAddress(Id applicationId) {
        List<Loan_Applicant__c> applicants = getApplicantsByApplication(applicationId);
        
        for (Loan_Applicant__c applicant : applicants) {
            if (String.isBlank(applicant.Address__c)) {
                System.debug('Missing Address for applicant Id: ' + applicant.Id);
                return true;
            }
        }
        
        return false;
    }
    
    //added by mansur --getting primary applicant only
    public Loan_Applicant__c getPrimaryApplicantByApplication(Id applicationId) {
        if (applicationId == null) return null;
        
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Application__r.Loan_Agreement_No__c');
        query.setCondition('Application__c = :applicationId ' +
            'AND Applicant_Type__c = \'Primary Applicant\' ' +
            'AND Applicant_Type__c != null ' +
            'AND IsDeleted__c = false');
        
        return (Loan_Applicant__c) Database.query(query.toSOQL());
    }
    
    /**
     * @Author      : Preeti
     * @Date        : 2025-11-13
     * @Description : Fetches minimal applicant details for Insurance API modal display.
     * @param applicantId Id - Loan Applicant record Id.
     * @return Loan_Applicant__c record with key fields.
     */
    public Loan_Applicant__c selectApplicantForInsuranceModal(Id applicantId) {
        if (applicantId == null) return null;
        
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Id');
        query.selectField('Name');
        query.selectField('Gender__c');
        query.selectField('Date_of_Birth__c');
        query.selectField('Applicant_Age__c');
        query.selectField('Application__r.Tenure__c');
        query.selectField('Application__r.Sanction_Amount__c');
        query.selectField('Application__r.Loan_Product__c');
        query.setCondition('Id = :applicantId AND IsDeleted__c = false');
        
        List<Loan_Applicant__c> applicants = (List<Loan_Applicant__c>) Database.query(query.toSOQL());
        return applicants.isEmpty() ? null : applicants[0];
    }
    
    /**
     * @Author      : Vikas Soni
     * @Date        : 2026-01-12
     * @Description : Fetches minimal applicant details for Insurance API modal display.
     */
    public Loan_Applicant__c selectCreateCustomerLMSApplicant(Id applicantId) {
        if (applicantId == null) return null;
        
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Id');
        query.selectField('Name');
        query.selectField('Gender__c');
        query.selectField('Mobile_Number__c');
        query.selectField('Mobile_Verification__r.Status__c');
        query.selectField('Pan_Number__c');
        query.selectField('Date_of_Birth__c');
        query.selectField('First_Name__c');
        query.selectField('Middle_Name__c');
        query.selectField('Gender__c');
        query.selectField('Email__c');
        query.selectField('Fathers_Name__c');
        query.selectField('Marital_Status__c');
        query.selectField('Constitution__c');
        query.selectField('Caste_Category__c');
        query.selectField('Registration_Type__c');
        query.selectField('Registration_No__c');
        query.selectField('Registration_Expiry_Date__c');
        query.selectField('No_Of_Controlling_Person__c');
        query.selectField('Commencement_Date__c');
        query.selectField('Date_Of_Incorporation1__c');
        query.selectField('Industry__c');
        query.selectField('Description__c');
        query.selectField('Total_Years_Of_Operation__c');
        query.selectField('Person_With_Disabilities__c');
        query.selectField('Religion__c');
        query.selectField('GST_Number__c');
        query.selectField('Voter_Id_Number__c');
        query.selectField('Aadhar_Number__c');
        query.selectField('Driving_License_Number__c');
        query.selectField('Passport_File_Number__c');
        query.selectField('Is_Customer_Updated_LMS__c');
        query.selectField('Contact_Number_2__c');
        query.selectField('Applicant_Age__c');
        query.selectField('Salutation__c');
        query.selectField('Customer_Info_File_Number__c');
        query.selectField('Application__r.Tenure__c');
        query.selectField('Application__r.Name');
        query.selectField('Mothers_Name__c');
        query.selectField('Application__r.Sanction_Amount__c');
        query.selectField('Application__r.Loan_Product__c');
        query.setCondition('Id = :applicantId AND IsDeleted__c = false');
        
        List<Loan_Applicant__c> applicants = (List<Loan_Applicant__c>) Database.query(query.toSOQL());
        return applicants.isEmpty() ? null : applicants[0];
    }
    
    /**
     * @Author      : Vikas Soni
     * @Date        : 2026-01-12
     * @Description : Fetches minimal applicant details for Litigation.
     */
    public Loan_Applicant__c selectLitigationApplicant(Id applicantId) {
        System.debug('applicantId - '+applicantId);
        if (applicantId == null) return null;
        
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Id');
        query.selectField('Name');
        query.selectField('Mobile_Number__c');
        query.selectField('Fathers_Name__c');
        query.selectField('Date_of_Birth__c');
        query.selectField('Customer_Type__c');
        query.selectField('Litigation_Instant_Verification__c');
        query.selectField('Litigation_Instant_Verification__r.Litigation_Verify_Id__c');
        query.selectField('Litigation_Instant_Verification__r.Status__c');
        query.selectField('Litigation_Advance_Verification__c');
        query.selectField('Litigation_Advance_Verification__r.Litigation_Verify_Id__c');
        query.selectField('Litigation_Advance_Verification__r.Status__c');
        query.setCondition('Id = :applicantId AND IsDeleted__c = false');
        
        system.debug('querrrry - '+query);
        List<Loan_Applicant__c> applicants = (List<Loan_Applicant__c>) Database.query(query.toSOQL());
        return applicants.isEmpty() ? null : applicants[0];
    }
    
}