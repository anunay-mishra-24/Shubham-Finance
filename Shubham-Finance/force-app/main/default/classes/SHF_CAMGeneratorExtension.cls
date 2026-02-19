public with sharing class SHF_CAMGeneratorExtension {
    public String appId{get;set;}
    public User userDetails{get;set;}
    public Application__c application { get; set;}
    public List<Loan_Applicant__c> loanApplicantList { get; set; }
    public List<E_Verification__c> eVerificationList { get; set; }
    public Obligation__c obligation { get; set; }
    public Map<Id, Employment__c> employmentMap { get; set; }
    public List<Employment__c> employmentList { get; set; }
    public List<Deviation_and_Sanction_Condition__c> deviationList {get; set;}
    public List<Bank_Details__c> bankDetailsList {get; set;}
    public Bank_Details__c bankDetails {get; set;}
    public List<VAP__c> vapdetails {get; set;}
    public List<Personal_Discussion__c> pdList {get; set;}
    public List<Collateral_Application__c> collateralApplicationList {get; set;}
    public List<Collateral__c> collateralList {get; set;}
    public List<Activity_History__c> activityHistoryList {get; set;}
    public List<DecisionWrapper> decisionWrapperList {get; set;}
    public List<E_Verification__c> verificationDetailsList {get; set;}
    public List<EverificationWrapper> eVerificationWrappersList {get; set;}
    
    
    
    public SHF_CAMGeneratorExtension(ApexPages.StandardController std) {
        appId = ApexPages.currentPage().getParameters().get('id');
        if(appId == '' || appId == NULL){
            appId = 'a03C100000KbOUcIAN';
        }
        //Id appId = std.getId();
        userDetails = new User();
        userDetails = [SELECT Id, Name FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
        
        application = [SELECT ID,Name,Sub_Product__c,Product__r.Product_Type__c,Branch__r.Name,Application_Auto_Number__c,
					   CreatedDate
					   FROM Application__c 
                       WHERE Id=:appId];
        loanApplicantList = [SELECT Id, Name, Account_Name__c, RecordType_Name__c, Applicant_Type__c, Account__c, CKYC_Reference_ID__c,
                            Constitution__c, Relationship_with_Applicant__c, Registration_Type__c, Date_of_Birth__c, Date_Of_Incorporation1__c,
                            Pan_Number__c, Applicant_Age__c, IsFinancial_Applicant__c, Occupation__c, Total_Working_Experience__c, Industry__c,
                            Sub_Industry__c, Customer_Profile__c, Risk_Category__c, Final_Risk_Score__c, Commencement_Date__c, Registration_No__c,
                            Registration_Expiry_Date__c, Mobile_Number__c, Customer_Info_File_Number__c, Account__r.Name, Total_Income__c,
                            CIBIL_Verification__r.Main_applicant_s_credit_score__c, CRIF_Verification__r.Main_applicant_s_credit_score__c
                            /*Aadhaar_Face_Extraction_Verification__c, Account_Aggregator_CAM__c, Alternate_Mobile_Verification__c, 
                            AML_Verification__c, CIBIL_Verification__c, CRIF_Verification__c, Digilocker_Verification__c, DL_Verification__c,
                            Electricity_Verification__c, Email_Verification__c, Employment_Verification__c, GST_Verification__c, Hunter_Verification__c,
                            Insurance_Verification__c, Login_Fee_Verification__c, Mobile_Verification__c, PAN_Face_Extraction_Verification__c,
                            PAN_Verification__c, Passport_Verification__c, Penny_Drop_Verification__c, SMS_Consent__c, Udyam_Verification__c,
                            VoterId_Verification__c*/
                             FROM Loan_Applicant__c 
                             WHERE Application__c = :appId];

        verificationDetailsList = [SELECT Id, Name, Loan_Applicant__r.Account_Name__c, RecordType.Name, Status__c 
                        FROM E_Verification__c 
                        WHERE Loan_Applicant__r.Application__c =: appId];    

        eVerificationWrappersList = new List<EverificationWrapper>();
        for(E_Verification__c verific : verificationDetailsList){
            eVerificationWrappersList.add(new EverificationWrapper((String)verific.Loan_Applicant__r.Account_Name__c,
                                                            (String)verific.RecordType.Name,
                                                            (String)verific.Status__c));
        }
        
        Set<Id> loanApplicantIds = new Set<Id>();
        Set<Id> collateralIds = new Set<Id>();
        
        for (Loan_Applicant__c la : loanApplicantList) {
            loanApplicantIds.add(la.Id);
        }
        
        eVerificationList = [SELECT Id, Name, Type_Of_Insurance__c, Insured__c, Sum_Insured__c, Insurance_Provider__c,
                            Premium_Amount__c,Loss_Payee__c, Policy_Number__c,Start_Date__c, End_Date__c 
                             FROM E_Verification__c 
                             WHERE Loan_Application__c = :appId and RecordType.Name = 'Insurance'];
        
        deviationList = [SELECT Id, Name, Deviation_Description__c, Decision__c, Decision_By__c, Approving_Authority__c, Mitigants__r.Mitigant_Name__c, Approver_Comments__c
                            FROM Deviation_and_Sanction_Condition__c
                            WHERE Loan_Application__c =:appId];
        
        bankDetailsList =  [SELECT Id, Name, Interest_Rate_Type__c
                            FROM Bank_Details__c
                            WHERE Application__c = :appId];
        
        vapdetails =  [SELECT Id, Name, VAP_Product__c, VAP_Type__c, VAP_Category__c, VAP_Treatment__c, Applicant_Name__c, VAP_Policy_Amount__c,
                            VAP_Amount__c, Differential_Amount__c, Policy_Number__c, Disburse_To__c, Coverage_Amount__c, Premium_Amount__c
                            FROM VAP__c
                            WHERE Application__c = :appId];
        
        pdList =  [SELECT Id, Name, Loan_Applicant__r.Account_Name__c, Remarks__c, PD_Activity_Status__c
                            FROM Personal_Discussion__c
                            WHERE Loan_Applicant__c IN :loanApplicantIds];
        
        collateralApplicationList = [SELECT Id, Collateral__c
                            FROM Collateral_Application__c
                            WHERE Application__c = :appId];
        
        employmentList = [SELECT Id, Name, Loan_Applicant__c, Business_Employer_Name__c, Designation__c, Nature_of_Business__c, 
                            Total_Years_Of_Operation_Years__c, Industry_Classification__c, Employment_Type__c, Industry__c, Sub_Industry__c
                            FROM Employment__c
                            WHERE Loan_Applicant__c IN :loanApplicantIds];
        
        employmentMap = new Map<Id, Employment__c>();
        
        if(!employmentList.isEmpty()){
            for(Employment__c employment : employmentList) {
                employmentMap.put(employment.Loan_Applicant__c, employment);
            }
        }
        if(bankDetailsList.isEmpty()){
            bankDetails=null;
        }else {
            bankDetails = bankDetailsList[0];
        }
        
        List<Obligation__c> obligationList = [SELECT Id, Name, EMI__c
                                                FROM Obligation__c
                                                WHERE Application__c = :appId
                                                LIMIT 1
                                            ];
        
        if (!obligationList.isEmpty()) {
            obligation = obligationList[0];
        }
        
        if(employmentMap.isEmpty()){
            employmentMap=null;
        }
        
        collateralList = new List<Collateral__c>();
        System.debug('collateralApplicationList --> '+ collateralApplicationList);
        for (Collateral_Application__c colApp : collateralApplicationList) {
            System.debug('colApp --> '+ colApp.Collateral__c);
            collateralIds.add(colApp.Collateral__c);
            System.debug('collateralIds --> '+ collateralIds);
        }
        
        System.debug('collateralIds --> '+ collateralIds);
        
        if(!collateralIds.isEmpty()){
            System.debug('collateralIds --> '+ collateralIds);
            collateralList = [SELECT Id, Name, Full_Address__c, Nature_of_Property__c, Property_Type__c, Current_Usage__c, 
                              Property_cost_INR__c, Considered_Value__c, Built_Up_Area__c, Age_Of_Property_In_Years__c, Property_Classification__c,
                              Property_Ownership__c, Market_Value_INR__c,Type_Of_Purchase__c, Carpet_Area__c, Residual_Age_of_Property__c, 
                              Project_Name__c, Company_Name__r.Company_Name__c, Company_Name__r.Builder_Category__c, Project_Name__r.Name, 
                              Project_Name__r.Plan_Approved__c, Project_Name__r.Tentative_Date_Completion__c, Building_Name__r.Construction_Status__c
                              FROM Collateral__c
                              WHERE Id IN :collateralIds];
            System.debug('collateralList --> '+ collateralList);
        }
        
        activityHistoryList = [SELECT  Id, Name, Decision_Type__c, Description__c, From_User__r.Name, FROM_User__r.Role_Name__c,
                                 FROM_User__r.Username
                                FROM Activity_History__c
                                WHERE Application__c = :appId and Decision_Type__c != null];
        
        decisionWrapperList = new List<DecisionWrapper>();
        Pattern datePattern = Pattern.compile('(?i)(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\\s+[0-9]{1,2}\\s+[A-Za-z]+,\\s+[0-9]{4}\\sat\\s[0-9]{1,2}:[0-9]{2}\\s(?:am|pm)');
        
        for (Activity_History__c activity : activityHistoryList) {
            try {
                String description = activity.Description__c;
                String extractedDate = '';
                String extractedComment = '';
                
                if (description != null) {
                    description = description.trim();
                    
                    Matcher m = datePattern.matcher(description);
                    if (m != null && m.find()) {
                        extractedDate = m.group(0).trim();
                    }

                    Integer commentIndex = description.indexOf('Commnet:');
                    if (commentIndex >= 0) {
                        extractedComment = description.substring(commentIndex + 'Commnet:'.length()).trim();
                    } else {
                        extractedComment = '';
                    }
                }

                String fromUserName = '';
                String fromUserUsername = '';
                String fromUserRole = '';
                if (activity.From_User__r != null) {
                    if (activity.From_User__r.Name != null) fromUserName = activity.From_User__r.Name;
                    if (activity.From_User__r.Username != null) fromUserUsername = activity.From_User__r.Username;
                    if (activity.From_User__r.Role_Name__c != null) fromUserRole = activity.From_User__r.Role_Name__c;
                }

                decisionWrapperList.add(
                    new DecisionWrapper(
                    activity.Decision_Type__c,
                extractedComment,
                fromUserName,
                extractedDate,
                fromUserUsername,
                fromUserRole
                    )
                    );
                
            } catch (Exception e) {
                System.debug('Error parsing Activity_History record Id ' + activity.Id + ' : ' + e.getMessage());
            }
        }        
    }
    
    public Class EverificationWrapper{
        public String name{get; set;}
        public String verificationType{get; set;}
        public String verificationStatus{get; set;}
        
        public EverificationWrapper(String name, String verificationType, String verificationStatus){
            this.name = name;
            this.verificationType = verificationType;
            this.verificationStatus = String.isBlank(verificationStatus) ? verificationStatus : verificationStatus.toUpperCase();
        }
    }
    
    public Class DecisionWrapper{
        public String decision{get; set;}
        public String decisionComments{get; set;}
        public String decisionBy{get; set;}
        public String decisionDate{get; set;}
        public String userId{get; set;}
        public String level{get; set;}
        
        public DecisionWrapper(String decisionType, String comment, String fromUserName, String dateString, String userId, String roleName){
            this.decision = decisionType;
            this.decisionComments = comment;
            this.decisionBy = fromUserName;
            this.decisionDate = dateString;
            this.userId = userId;
            this.level = roleName;
        }
    }
    
}