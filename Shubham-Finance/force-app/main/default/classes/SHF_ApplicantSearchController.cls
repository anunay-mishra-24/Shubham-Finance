/**
* @Author : Akshi Sharma
* @File Name : SHF_ApplicantSearchController.cls
* @Description : To handle Account & Loan Applicant search/creation
* @Last Modified By : Preeti
* @Last Modified On : 2025-10-09
**/
public with sharing class SHF_ApplicantSearchController {
    
    private SHF_AccountSelector accountSelector = new SHF_AccountSelector();
    private SHF_LoanApplicantsSelector applicantSelector = new SHF_LoanApplicantsSelector();
    
    /** Search Accounts by PAN / Phone / DOB **/
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String phone, String pan, Date dob, Id applicationId) {
        return new SHF_AccountSelector().selectByCriteria(phone, pan, dob, applicationId);
    }
    
    /** Return existing Account (first match) or create new Account using accInput **/
    @AuraEnabled
    public static Account getOrCreateAccount(String phone, String pan, Date dob, Account accInput, Id applicationId) {
        List<Account> existingAccounts = new SHF_AccountSelector().selectByCriteria(phone, pan, dob, applicationId);
        if (!existingAccounts.isEmpty()) {
            return existingAccounts[0];
        }
        return null;
    }
    
    /**
* @author : Preeti
* @Date : : 2025-10-09
* @description Checks if the maximum co-applicant limit has been reached for a given Application.
* @param applicationId Id - Salesforce Id of the Application__c record.
* @return Boolean - true if limit reached, false otherwise.
*/
    
    @AuraEnabled(cacheable=false)
    public static Boolean hasReachedCoApplicantLimit(Id applicationId) {
        final Integer CO_APPLICANT_LIMIT = 5;
        
        // Call the selector class method
        SHF_LoanApplicantsSelector loanApplicantselector = new SHF_LoanApplicantsSelector();
        Integer coApplicantCount = loanApplicantselector.countCoApplicantsByApplication(applicationId);
        
        return coApplicantCount >=  CO_APPLICANT_LIMIT;
    }
    
    
    
    /** Check if a Primary Applicant already exists **/
    @AuraEnabled(cacheable=false)
    public static Boolean hasPrimaryApplicant(Id applicationId) {
        Integer cnt = [
            SELECT COUNT()
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            AND Applicant_Type__c = 'Primary Applicant'
        ];
        return (cnt > 0);
    }
    
    // Helper to safely get String from Map
    private static String getString(Map<String, Object> data, String key) {
        return (data != null && data.containsKey(key) && data.get(key) != null) ? String.valueOf(data.get(key)) : null;
    }
    
    // Helper to parse Date safely
    private static Date parseDate(Map<String, Object> data, String key) {
        String dateStr = getString(data, key);
        if (dateStr != null) {
            try {
                return Date.valueOf(dateStr);
            } catch(Exception e) {
                System.debug('Invalid date format for ' + key + ': ' + dateStr);
            }
        }
        return null;
    }
    
    // Helper to parse Integer safely
    private static Integer parseInteger(Map<String, Object> data, String key) {
        String val = getString(data, key);
        return (val != null && val != '') ? Integer.valueOf(val) : null;
    }
    
    // Helper to parse Decimal safely
    private static Decimal parseDecimal(Map<String, Object> data, String key) {
        String val = getString(data, key);
        return (val != null && val != '') ? Decimal.valueOf(val) : null;
    }
    
    
    /**
* @author : Preeti
* @Date : : 2025-10-09
* @description Builds a Loan_Applicant__c record from input data and related Account/Application.
*              Determines record type (Individual or Non-Individual) and maps all fields safely.
* @param accountId Id - Salesforce Id of the related Account.
* @param applicationId Id - Salesforce Id of the related Application__c.
* @param applicantData Map<String,Object> - Map containing applicant data.
* @return Loan_Applicant__c - Constructed Loan Applicant record.
*/
    
    
    private static Loan_Applicant__c buildLoanApplicant(Id accountId, Id applicationId, Map<String, Object> applicantData) {
        String selectedRecordType = getString(applicantData, 'RecordType');
        Id loanApplicantRecordTypeId;
        String lastNameVal;
        String firstNameVal;
        String customerType;
        String fullName;
        String entityNameVal = getString(applicantData, 'Entity_Name__c');
        
        if (selectedRecordType == 'Individual') {
            firstNameVal = getString(applicantData, 'FirstName');
            lastNameVal = getString(applicantData, 'LastName');
            customerType = 'Individual';
            fullName = ((String.isNotBlank(firstNameVal) ? firstNameVal : '') +
               (String.isNotBlank(lastNameVal) ? ' ' + lastNameVal : '')).trim();
            loanApplicantRecordTypeId = SHF_CommonUtil.selectRecordTypeId('Loan_Applicant__c', 'Individual');
        } else if (selectedRecordType == 'Non_Individual') {
            firstNameVal = null;
            lastNameVal = null;
            fullName = entityNameVal;
            customerType = 'Non-Individual';
            loanApplicantRecordTypeId = SHF_CommonUtil.selectRecordTypeId('Loan_Applicant__c', 'Non_Individual');
        } else {
            throw new AuraHandledException('Invalid Record Type');
        }
        
        return new Loan_Applicant__c(
            Account__c = accountId,
            Application__c = applicationId,
            RecordTypeId = loanApplicantRecordTypeId,
            First_Name__c = firstNameVal,
            Middle_Name__c = getString(applicantData, 'MiddleName'),
            Last_Name__c = lastNameVal,
            Date_of_Birth__c = parseDate(applicantData, 'DOB'),
            PAN_Number__c = getString(applicantData, 'PAN_Number__c'),
            PF_Deducted__c = getString(applicantData, 'PF_Deducted__c'),
            UAN_Number__c = getString(applicantData, 'UAN_Number__c'),
            Mobile_Number__c = getString(applicantData, 'Primary_Mobile_Number__c'),
            Alternate_Mobile_Number__c = getString(applicantData, 'Alternate_Mobile__c'),
            Email__c = getString(applicantData, 'Email'),
            Applicant_Type__c = getString(applicantData, 'Type_of_Applicant__c'),
            Employment_Type__c = getString(applicantData, 'EmploymentType'),
            Name = fullName,
            Salutation__c = getString(applicantData, 'Salutation__c'),
            Fathers_Name__c = getString(applicantData, 'Father_Name__c'),
            Mothers_Name__c = getString(applicantData, 'Mother_Name__c'),
            Husbands_Name__c = getString(applicantData, 'Husband_Name__c'),
            Description__c = getString(applicantData, 'Description__c'),
            Caste_Category__c = getString(applicantData, 'Caste_Category__c'),
            Nationality__c = getString(applicantData, 'Nationality__c'),
            Gender__c = getString(applicantData, 'Gender__c'),
            Marital_Status__c = getString(applicantData, 'Marital_Status__c'),
            Person_with_Disabilities__c = getString(applicantData, 'Person_with_Disabilities__c'),
            Type_of_Impairment__c = getString(applicantData, 'Type_of_Impairment__c'),
            Qualification__c = (String) applicantData.get('Qualification__c'),
            Percentage_of_Impairment__c = parseDecimal(applicantData, 'Percentage_of_Impairment__c'),
            UDID_Number__c = getString(applicantData, 'UDID_Number__c'),
            Manual_Scavanger__c = getString(applicantData, 'Manual_Scavanger__c'),
            Preferred_Language__c = getString(applicantData, 'Preferred_Language__c'),
            No_of_dependents__c = parseInteger(applicantData, 'No_of_dependents__c'),
            Whatsapp_Number__c = getString(applicantData, 'Whatsapp_Number__c'),
            Whatsapp_Number_Same_As_Mobile_Number__c = (String) applicantData.get('Whatsapp_Number_Same_As_Mobile_Number__c'),
            Is_Customer_vernacular__c = getString(applicantData, 'Is_Customer_Vernacular__c'),
            Do_You_Want_To_Edit_The_Aadhar_Address__c = getString(applicantData, 'Do_You_Want_To_Edit_The_Aadhar_Address__c'),
            Total_Working_Experience__c = parseDecimal(applicantData, 'Total_Working_Experience__c'),
            Customer_Type__c = customerType,
            Entity_Name__c = entityNameVal,
            Date_Of_Incorporation1__c = parseDate(applicantData, 'Date_of_incorporation__c'),
            Company_Type__c = getString(applicantData, 'Company_Type__c'),
            Registration_Type__c = getString(applicantData, 'Registration_Type__c'),
            Commencement_Date__c = parseDate(applicantData, 'Commencement_Date__c'),
            No_of_Controlling_Person__c = parseInteger(applicantData, 'No_Of_Controlling_Person__c'),
            Registration_No__c = getString(applicantData, 'Registration_No__c'),
            Registration_Expiry_Date__c = parseDate(applicantData, 'Registration_Expiry_Date__c'),
            Group_Name__c = getString(applicantData, 'Group_Name__c'),
            Sub_Group_Name__c = getString(applicantData, 'Sub_Group_Name__c'),
            Constitution__c = getString(applicantData, 'Constitution__c'),
            IsFinancial_Applicant__c = getString(applicantData, 'IsFinancial_Applicant__c'),
            Occupation__c = getString(applicantData, 'Occupation__c'),
            Religion__c	= getString(applicantData, 'Religion__c'),
            Subcategory__c = getString(applicantData, 'Subcategory__c')
        );
    }
    
    /**
* @author : Preeti
* @Date : : 2025-10-09
* @description Creates a new Account (if needed) and a Loan Applicant record based on input data.
* @param applicantData Map<String,Object> - Map containing applicant data.
* @param applicationId Id - Salesforce Id of the related Application__c.
* @return Id - Id of the newly created Loan Applicant record.
*/    
    @AuraEnabled
public static Id createAccountAndApplicant(Map<String, Object> applicantData, Id applicationId) {
    System.debug('Entered createAccountAndApplicant method');
    System.debug('applicantData: ' + applicantData);
    System.debug('applicationId: ' + applicationId);

    Id accountRecordTypeId = SHF_CommonUtil.selectRecordTypeId('Account', 'Customer');
    System.debug('accountRecordTypeId: ' + accountRecordTypeId);

    String firstNameVal = getString(applicantData, 'FirstName');
    String lastNameVal = getString(applicantData, 'LastName');
    String entityNameVal = getString(applicantData, 'Entity_Name__c');
    String selectedRecordType = getString(applicantData, 'RecordType');
    String customerType;
    if (selectedRecordType == 'Individual') {
        customerType = 'Individual';
    } else if (selectedRecordType == 'Non_Individual') {
        customerType = 'Non-Individual';
    } else {
        customerType = null; // fallback if record type not selected
    }

    System.debug('FirstName: ' + firstNameVal);
    System.debug('LastName: ' + lastNameVal);
    System.debug('Entity_Name__c: ' + entityNameVal);

    String finalLastName = String.isNotBlank(lastNameVal) ? lastNameVal : entityNameVal;
    System.debug('finalLastName: ' + finalLastName);

    Account acc = new Account(
        RecordTypeId = accountRecordTypeId,
        FirstName = firstNameVal,
        MiddleName = getString(applicantData, 'MiddleName'),
        LastName = finalLastName,
        PAN_Number__c = getString(applicantData, 'PAN_Number__c'),
        Phone = getString(applicantData, 'Primary_Mobile_Number__c'),
        Alternate_Mobile_Number__c = getString(applicantData, 'Alternate_Mobile__c'),
        Date_of_Birth__c = parseDate(applicantData, 'DOB'),
        Date_of_incorporation__c = parseDate(applicantData, 'Date_of_incorporation__c'),
        Email_id__c = getString(applicantData, 'Email'),
        Employment_Type__c = getString(applicantData, 'EmploymentType'),
        Entity_Name__c = entityNameVal,
        Customer_Type__c = customerType 
    );

    System.debug('Account before insert: ' + acc);

    try {
        insert acc;
        System.debug('Account inserted. Id: ' + acc.Id);
    } catch (Exception e) {
        System.debug('Account insert failed: ' + e.getMessage());
        throw e;
    }

    try {
        Loan_Applicant__c applicant = buildLoanApplicant(acc.Id, applicationId, applicantData);
        System.debug('Loan Applicant before insert: ' + applicant);
        insert applicant;
        System.debug('Loan Applicant inserted. Id: ' + applicant.Id);
        return applicant.Id;
    } catch (Exception ex) {
        System.debug('Loan Applicant insert failed: ' + ex.getMessage());
        throw ex;
    }
}

    
    
    /**
* @author : Preeti
* @Date : : 2025-10-09
* @description Creates a Loan Applicant record for an existing Account and Application.
* @param accountId Id - Salesforce Id of the existing Account.
* @param applicationId Id - Salesforce Id of the related Application__c.
* @param applicantData Map<String,Object> - Map containing applicant data.
* @return Id - Id of the newly created Loan Applicant record.
*/  
    @AuraEnabled
    public static Id createLoanApplicant(Id accountId, Id applicationId, Map<String, Object> applicantData) {
        if(accountId == null) throw new AuraHandledException('Account Id is required.');
        Loan_Applicant__c applicant = buildLoanApplicant(accountId, applicationId, applicantData);
        insert applicant;
        return applicant.Id;
    }


    @AuraEnabled(cacheable=true)
public static Integer getFinancialCoApplicantCount(Id applicationId) {
    return [
        SELECT COUNT() 
        FROM Loan_Applicant__c
        WHERE Application__c = :applicationId
        AND IsFinancial_Applicant__c = 'Yes'
        AND Applicant_Type__c != 'Primary Applicant'
        AND IsDeleted = false
    ];
}

    
    
}