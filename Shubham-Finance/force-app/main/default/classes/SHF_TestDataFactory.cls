/**
 * @File Name          :  SHF_TestDataFactory.cls
 * @Author             :  Preeti
 * @Last Modified By   :  Kunal
 * @Last Modified On   :  18-08-2025
 * @Description        :  Utility class to create test data for Salesforce records.
 *                        Provides methods to create Case, Case_Categories_Matrix__c,
 *                        Application__c, Loan_Applicant__c, User, Branch_Master__c,
 *                        and Round_Robin__c records with default or provided values.
 *                        Supports optional insertion into the database.
 *================================================================================================
 * Update Ver   Date         Author        Modification
 *================================================================================================
 * 1.0          18-08-2025   Preeti        Initial Version
 * 1.1          19-08-2025   Kunal Soni    Initial Version
 */

public class SHF_TestDataFactory {
    
    /* ==========================================================================================
    CASE FACTORY METHODS
        ========================================================================================== */
        
    /**
     * Creates a Case record with default or provided values.
     */
    public static Case createCase(
        String subject,
    String status,
    String contactNo,
    String customerName,
    String suppliedEmail,
    String origin,
    String ticketType,
    String ticketSubType,
    Datetime actualTat,
    Datetime actualTatAfter1,
    Datetime actualTatAfter3,
    Datetime actualTatAfter4,
    Datetime actualTatBefore1,
    Datetime sendNotification4Hrs,
    Datetime escalationNotificationDate,
    Boolean doInsert
    ) {
        Datetime now = Datetime.now();
        
        Case cs = new Case(
            Subject                       = String.isBlank(subject) ? 'Test Case' : subject,
        Status                        = String.isBlank(status) ? SHF_ConstantsUtil.NEW_STATUS : status,
        Contact_No_1__c               = String.isBlank(contactNo) ? '9993495670' : contactNo,
        Customer_Name__c              = String.isBlank(customerName) ? 'Test Customer' : customerName,
        SuppliedEmail                 = String.isBlank(suppliedEmail) ? 'test@example.com' : suppliedEmail,
        Origin                        = String.isBlank(origin) ? 'Phone' : origin,
        Ticket_Type__c                = String.isBlank(ticketType) ? 'Enquiry' : ticketType,
        Ticket_Sub_Type__c            = String.isBlank(ticketSubType) ? 'Change in base rate' : ticketSubType,
        Actual_TAT__c                 = (actualTat == null) ? now.addDays(5) : actualTat,
        Actual_TAT_After_1__c         = (actualTatAfter1 == null) ? now.addMinutes(30) : actualTatAfter1,
        Actual_TAT_After_3__c         = (actualTatAfter3 == null) ? now.addMinutes(30) : actualTatAfter3,
        Actual_TAT_After_4__c         = (actualTatAfter4 == null) ? now.addMinutes(30) : actualTatAfter4,
        Actual_TAT_Before_1__c        = (actualTatBefore1 == null) ? now.addMinutes(30) : actualTatBefore1,
        Send_Notification_4_hours__c  = (sendNotification4Hrs == null) ? now.addMinutes(30) : sendNotification4Hrs,
        Escalation_Notification_Date__c = (escalationNotificationDate == null) ? now.addMinutes(30) : escalationNotificationDate
            );
        
        if (doInsert) insert cs;
        return cs;
    }
    
    /**
     * Creates a list of Case records with defaults or provided values.
     */
    public static List<Case> createCaseList(
        Integer count,
    String subject,
    String status,
    String contactNo,
    String customerName,
    String suppliedEmail,
    String origin,
    String ticketType,
    String ticketSubType,
    Datetime actualTat,
    Datetime actualTatAfter1,
    Datetime actualTatAfter3,
    Datetime actualTatAfter4,
    Datetime actualTatBefore1,
    Datetime sendNotification4Hrs,
    Datetime escalationNotificationDate,
    Boolean doInsert
    ) {
        List<Case> casesToInsert = new List<Case>();
        
        for (Integer i = 0; i < count; i++) {
            casesToInsert.add(createCase(
                subject, status, contactNo, customerName, suppliedEmail,
            origin, ticketType, ticketSubType, actualTat, actualTatAfter1,
            actualTatAfter3, actualTatAfter4, actualTatBefore1,
            sendNotification4Hrs, escalationNotificationDate, false
                ));
        }
        
        if (doInsert && !casesToInsert.isEmpty()) insert casesToInsert;
        return casesToInsert;
    }
    
    /* ==========================================================================================
    CASE CATEGORY MATRIX FACTORY METHODS
        ========================================================================================== */
        
    public static Case_Categories_Matrix__c createCaseCategoryMatrix(
        String ticketType,
    String requestType,
    String ticketSubType,
    Integer turnaroundTime,
    Integer sendNotificationInDays,
    Boolean doInsert
    ) {
        Case_Categories_Matrix__c matrix = new Case_Categories_Matrix__c(
            Ticket_Type__c          = String.isBlank(ticketType) ? 'Enquiry' : ticketType,
        Request_Type__c         = String.isBlank(requestType) ? 'Increase/Decrease in base rate' : requestType,
        Ticket_Sub_Type__c      = String.isBlank(ticketSubType) ? 'Change in base rate' : ticketSubType,
        Turnaround_Time__c      = (turnaroundTime == null) ? 2 : turnaroundTime,
        Send_Notification_InDays__c = (sendNotificationInDays == null) ? 1 : sendNotificationInDays
            );
        
        if (doInsert) insert matrix;
        return matrix;
    }
    
    public static List<Case_Categories_Matrix__c> createCaseCategoryMatrixList(
        Integer count,
    String ticketType,
    String requestType,
    String ticketSubType,
    Integer turnaroundTime,
    Integer sendNotificationInDays,
    Boolean doInsert
    ) {
        List<Case_Categories_Matrix__c> matrixList = new List<Case_Categories_Matrix__c>();
        
        for (Integer i = 0; i < count; i++) {
            matrixList.add(createCaseCategoryMatrix(ticketType, requestType, ticketSubType, turnaroundTime, sendNotificationInDays, false));
        }
        
        if (doInsert && !matrixList.isEmpty()) insert matrixList;
        return matrixList;
    }
    public static Notification_Template__mdt createTemplate(String devName, String bellText, String emailText) {
        Notification_Template__mdt t = new Notification_Template__mdt(
            DeveloperName = devName,
        Bell_Notification__c = bellText,
        Email_Template__c = emailText
            );
        //insert t;
        return t;
    }
    // METADATA
    public static Notification_Template__mdt mockNotificationTemplate(String devName) {
        Notification_Template__mdt nt = new Notification_Template__mdt(
            DeveloperName = devName,
        MasterLabel = devName,
        Bell_Notification__c = 'Mock Bell Template for ' + devName,
        Email_Template__c = 'Mock Email Template for ' + devName
            );
        return nt;
    }
    
    /* ==========================================================================================
    USER FACTORY METHODS
        ========================================================================================== */
        
    public static User createUser(
        String firstName,
    String lastName,
    String email,
    String username,
    Id profileId,
    Boolean isActive,
    String phone,
    String mobilePhone,
    Boolean doInsert
    ) {
        User u = new User(
            FirstName         = String.isBlank(firstName) ? 'Test' : firstName,
        LastName          = String.isBlank(lastName) ? 'User' : lastName,
        Email             = String.isBlank(email) ? 'testuser@test.com' : email,
        Username          = String.isBlank(username) ? 'testuser12' + System.currentTimeMillis() + '@test.com' : username,
        Alias             = 'tuser',
        ProfileId         = profileId,
        TimeZoneSidKey    = 'Asia/Kolkata',
        LocaleSidKey      = 'en_US',
        EmailEncodingKey  = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        IsActive          = (isActive == null) ? true : isActive,
        Phone             = phone,
        MobilePhone       = mobilePhone
            );
        
        if (doInsert) insert u;
        return u;
    }
    
    public static List<User> createUserList(
        Integer count,
    String firstName,
    String lastName,
    String email,
    String username,
    Id profileId,
    Boolean isActive,
    String phone,
    String mobilePhone,
    Boolean doInsert
    ) {
        List<User> users = new List<User>();
        for (Integer i = 0; i < count; i++) {
            users.add(createUser(firstName, lastName, email, username, profileId, isActive, phone, mobilePhone, false));
        }
        if (doInsert && !users.isEmpty()) insert users;
        return users;
    }
    
    /* ==========================================================================================
    APPLICATION & LOAN APPLICANT FACTORY METHODS
        ========================================================================================== */
        
    public static Application__c createApplication(String name, Boolean doInsert) {
        Application__c app = new Application__c(
            Name = String.isBlank(name) ? 'Test Application ' + System.currentTimeMillis() : name
            );
        if (doInsert) insert app;
        return app;
    }
    
    public static List<Application__c> createApplicationList(Integer count, String name, Boolean doInsert) {
        List<Application__c> apps = new List<Application__c>();
        for (Integer i = 0; i < count; i++) {
            apps.add(createApplication(name, false));
        }
        if (doInsert && !apps.isEmpty()) insert apps;
        return apps;
    }
    
    public static Loan_Applicant__c createLoanApplicant(Id applicationId, String firstName, String lastName, String gstNumber, Boolean doInsert) {
        Loan_Applicant__c applicant = new Loan_Applicant__c(
            Application__c = applicationId,
        First_Name__c  = String.isBlank(firstName) ? 'Test' : firstName,
        Last_Name__c   = String.isBlank(lastName) ? 'Applicant' : lastName,
        GST_Number__c  = String.isBlank(gstNumber) ? '27AAACB2230M1ZL' : gstNumber
            );
        if (doInsert) insert applicant;
        return applicant;
    }

    public static Loan_Applicant__c createLoanApplicantwithType(
    Id applicationId,
    String firstName,
    String lastName,
    String gstNumber,
    String applicantType,
    String isFinancialApplicant,
    Boolean doInsert
) {
    Loan_Applicant__c applicant = new Loan_Applicant__c(
        Application__c     = applicationId,
        First_Name__c      = String.isBlank(firstName) ? 'Test' : firstName,
        Last_Name__c       = String.isBlank(lastName) ? 'Applicant' : lastName,
        GST_Number__c      = String.isBlank(gstNumber) ? '27AAACB2230M1ZL' : gstNumber,
        Applicant_Type__c  = String.isBlank(applicantType) ? 'Primary Applicant' : applicantType,
        IsFinancial_Applicant__c = String.isBlank(isFinancialApplicant) ? 'Yes' : isFinancialApplicant
    );

    if (doInsert) {
        insert applicant;
    }
    return applicant;
}

    
    public static List<Loan_Applicant__c> createLoanApplicantList(Integer count, Id applicationId, String firstName, String lastName, String gstNumber, Boolean doInsert) {
        List<Loan_Applicant__c> applicants = new List<Loan_Applicant__c>();
        for (Integer i = 0; i < count; i++) {
            applicants.add(createLoanApplicant(applicationId, firstName, lastName, gstNumber, false));
        }
        if (doInsert && !applicants.isEmpty()) insert applicants;
        return applicants;
    }
    
    /* ==========================================================================================
    BRANCH MASTER & ROUND ROBIN FACTORY METHODS
        ========================================================================================== */
        
    public static Branch_Master__c createBranchMaster(String name, String branchCode, Boolean doInsert) {
        Branch_Master__c branch = new Branch_Master__c(
            Name          = String.isBlank(name) ? 'Delhi' : name,
        Branch_Code__c = String.isBlank(branchCode) ? '5186554' : branchCode
            );
        if (doInsert) insert branch;
        return branch;
    }
    
    public static List<Round_Robin__c> createRoundRobinList(Integer count, String lob, Boolean isActive, List<User> users, Branch_Master__c branch) {
        if (branch == null) branch = createBranchMaster('Delhi', '0001', true);
        
        List<Round_Robin__c> rrList = new List<Round_Robin__c>();
        
        for (Integer i = 0; i < count; i++) {
            User u = (users != null && !users.isEmpty()) ? users[Math.mod(i, users.size())] : null;
            rrList.add(new Round_Robin__c(
                Branch_Name__c   = branch.Id,
            Is_Active__c     = isActive,
            User__c          = (u != null ? u.Id : null),
            Last_Assigned__c = System.now().addDays(-i),
            LOB__c           = lob
                ));
        }
        
        insert rrList;
        return rrList;
    }
    
    public static List<Round_Robin__c> createRoundRobinUsers(Integer count, String lob) {
        List<User> users = new List<User>();
        for (Integer i = 0; i < count; i++) {
            users.add(new User(
                Alias             = 'usr' + i,
            Email             = 'user' + i + '@test.com',
            EmailEncodingKey  = 'UTF-8',
            LastName          = 'TestUser' + i,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey      = 'en_US',
            TimeZoneSidKey    = 'Asia/Kolkata',
            UserName          = 'user' + i + DateTime.now().getTime() + '@test.com',
            ProfileId         = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            EmployeeNumber    = '1234'    
                ));
        }
        insert users;
        
        List<Round_Robin__c> roundRobins = new List<Round_Robin__c>();
        for (User u : users) {
            roundRobins.add(new Round_Robin__c(
                User__c          = u.Id,
            Last_Assigned__c = null,
            Is_Active__c     = true,
            LOB__c           = lob
                ));
        }
        insert roundRobins;
        
        return roundRobins;
    }
    
    /* ==========================================================================================
    DOCUMENT & ROUND ROBIN FACTORY METHODS
        ========================================================================================== */
        
    // public static Document__c createDocument(String name, Boolean doInsert) {
        //     Document__c doc = new Document__c(
        //         Name = String.isBlank(name) ? 'Test Document ' + System.currentTimeMillis() : name
        //     );
        //     if (doInsert) {
            //         insert doc;
        //     }
        //     return doc;
    // }
    
    /* ==========================================================================================
    DOCUMENT CHECKLIST & DOCUMENT FACTORY METHODS
        ========================================================================================== */
        
    public static Document_Checklist__c createDocumentChecklist(
        String category,
    String type,
    String applicableFor,
    String mandatoryOptional,
    String stage,
    String customerProfile,
    Boolean doInsert
    ) {
        Document_Checklist__c checklist = new Document_Checklist__c(
            Document_Category__c  = String.isBlank(category) ? 'Income Proof' : category,
        Document_Type__c      = String.isBlank(type) ? 'Income Proof' : type,
        Applicable_For__c     = String.isBlank(applicableFor) ? 'Loan' : applicableFor,
        Mandatory_Optional__c = String.isBlank(mandatoryOptional) ? 'Non Mandatory' : mandatoryOptional,
        Document_Stage__c     = String.isBlank(stage) ? 'QDE' : stage,
        Customer_Profile_FinnOne__c   = String.isBlank(customerProfile) ? 'Cash Salaried' : customerProfile
            );
        if (doInsert) insert checklist;
        return checklist;
    }
    
    public static Document__c createDocument(
        Id applicationId,
    Id applicantId,
    String category,
    String type,
    String stage,
    String status,
    Boolean doInsert
    ) {
        Document__c doc = new Document__c(
            // Name               = 'Test Document ' + System.currentTimeMillis(),
        Application__c     = applicationId,
        Loan_Applicant__c  = applicantId,
        Document_Category__c = String.isBlank(category) ? 'Income Proof' : category,
        Document_Type__c     = String.isBlank(type) ? 'Income Proof' : type,
        Stage__c             = String.isBlank(stage) ? 'QDE' : stage,
        Status__c            = String.isBlank(status) ? 'Not Uploaded' : status
            );
        if (doInsert) insert doc;
        return doc;
    }
    /* ==========================================================================================
    VERIFICATION & VERIFICATION ACTIVITY FACTORY METHODS
        ========================================================================================== */
        
    public static Verification__c createVerification(
        Id applicationId,
    Id ownerId,
    String status,
    String type,
    String recordTypeName,
    Boolean doInsert
    ) {
        // Ensure we always have an Owner
        if (ownerId == null) {
            ownerId = UserInfo.getUserId();
        }
        
        Id recordTypeId;
        if (!String.isBlank(recordTypeName)) {
            try {
                recordTypeId = [SELECT Id FROM RecordType 
                                WHERE SObjectType = 'Verification__c' 
                                AND DeveloperName = :recordTypeName 
                                LIMIT 1].Id;
            } catch (Exception e) {
                // Fallback: no record type found
                recordTypeId = null;
            }
        }
        
        Verification__c v = new Verification__c(
            Application__c = applicationId,
        OwnerId       = ownerId,
        Status__c     = 'Sampled',
        Type__c       = 'Document'
            );
        
        if (recordTypeId != null) {
            v.RecordTypeId = recordTypeId;
        }
        if (doInsert) insert v;
        return v;
    }
    
    public static Verification_Activity__c createVerificationActivity(
        Id verificationId,
    Id ownerId,
    Boolean doInsert
    ) {
        if (ownerId == null) {
            ownerId = UserInfo.getUserId();
        }
        
        Verification_Activity__c va = new Verification_Activity__c(
            Verification__c = verificationId,
        OwnerId         = ownerId
            );
        
        if (doInsert) insert va;
        return va;
    }
    
    public static List<Verification_Activity__c> createVerificationActivities(
        Id verificationId,
    Integer count,
    Id ownerId,
    Boolean doInsert
    ) {
        List<Verification_Activity__c> activities = new List<Verification_Activity__c>();
        for (Integer i = 0; i < count; i++) {
            activities.add(createVerificationActivity(verificationId, ownerId, false));
        }
        if (doInsert && !activities.isEmpty()) insert activities;
        return activities;
    }
    
    /* ==========================================================================================
    ADDRESS FACTORY METHODS
        ========================================================================================== */
        
    /**
     * Creates an Address__c record with default or provided values.
     */
    public static Address__c createAddress(
        Id loanApplicantId,
    String addressLine1,
    String landmark,
    String District,
    String FlatPlotNumber,
    Boolean doInsert
    ) {
        Address__c addr = new Address__c(
            Loan_Applicant__c  = loanApplicantId,
        Address_Line_1__c  = String.isBlank(addressLine1) ? 'Test Address Line 1' : addressLine1,
        Landmark__c               = String.isBlank(landmark) ? 'Test Address' : landmark,
        District__c            = String.isBlank(District) ? 'Delhi' : District,
        Flat_Plot_Number__c           = String.isBlank(FlatPlotNumber) ? 'Delhi' : FlatPlotNumber
            );
        if (doInsert) insert addr;
        return addr;
    }
    
    /**
     * Creates a list of Address__c records with defaults or provided values.
     */
    public static List<Address__c> createAddressList(
        Integer count,
    Id loanApplicantId,
    String addressLine1,
    String landmark,
    String District,
    String FlatPlotNumber,
    Boolean doInsert
    ) {
        List<Address__c> addresses = new List<Address__c>();
        for (Integer i = 0; i < count; i++) {
            addresses.add(createAddress(loanApplicantId, addressLine1, landmark, District, FlatPlotNumber, false));
        }
        if (doInsert && !addresses.isEmpty()) insert addresses;
        return addresses;
    }
    
     /* ==========================================================================================
    PRODUCT MASTER FACTORY METHODS
        ========================================================================================== */
        
    public static Product_Master__c createProduct(Id applicationId, Boolean doInsert) {
    Product_Master__c prod = new Product_Master__c(
        Application__c = applicationId,
        Name = 'Test Product'
    );

    if (doInsert) insert prod;
    return prod;
    }

     /* ==========================================================================================
    COLLATERAL FACTORY METHODS
        ========================================================================================== */
        
    public static Collateral__c createCollateral(Id applicationId, Boolean doInsert) {
    Collateral__c col = new Collateral__c(Application__c = applicationId);

    if (doInsert) insert col;
    return col;
  }

}