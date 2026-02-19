public with sharing class SHF_PersonalDiscussionController {
    
    //  Loan Applicant fetch
    @AuraEnabled(cacheable=true)
    public static List<Loan_Applicant__c> getLoanApplicants(Id applicationId) {
        return [
            SELECT Id, Name,Account_Name__c, Employment_Type__c, Customer_Profile__c, Subcategory__c, RecordType_Name__c
            FROM Loan_Applicant__c 
            WHERE Application__c = :applicationId
              AND IsDeleted__c = false
        ];
    }
    
  
    @AuraEnabled
    public static Id savePDRecord(Personal_Discussion__c pdRec) {

        System.debug('>>> Incoming PD Id: ' + pdRec.Id);
        System.debug('>>> Incoming Application__c: ' + pdRec.Application__c);
        System.debug('>>> Incoming Loan_Applicant__c: ' + pdRec.Loan_Applicant__c);

        // If editing an existing PD & Loan_Applicant__c is not passed then fetch it
        if (pdRec.Loan_Applicant__c == null && pdRec.Id != null) {
            Personal_Discussion__c existingPd = [
                SELECT Loan_Applicant__c
                FROM Personal_Discussion__c
                WHERE Id = :pdRec.Id
                LIMIT 1
            ];
            pdRec.Loan_Applicant__c = existingPd.Loan_Applicant__c;
        }

        //  Validate & load Loan Applicant 
        Loan_Applicant__c loanAppObj = [
            SELECT Id,
                   Application__r.OwnerId,
                   Employment_Type__c,
                   Application__r.Application_Stage__c,
                   Customer_Profile__c,
                   Data_Changes_After_LAF_Generation__c
            FROM Loan_Applicant__c
            WHERE Id = :pdRec.Loan_Applicant__c
            LIMIT 1
        ];
        
        Id appOwnerId = loanAppObj.Application__r.OwnerId;
        if (UserInfo.getUserId() != appOwnerId) {
            String errMsg;
            try {
                errMsg = [
                    SELECT Message__c
                    FROM Messages_Config__mdt
                    WHERE DeveloperName = 'Only_Application_Owner_Can_Modify_Error'
                    LIMIT 1
                ].Message__c;
            } catch (Exception e) {
                errMsg = 'You are not authorized to update this record.';
            }
            throw new AuraHandledException(errMsg);
        }

        // stop Sales PD creation in invalid stage 
        if (pdRec.Id == null) {
            try {
                String appStage = loanAppObj.Application__r.Application_Stage__c;
                if (appStage == null ||
                    !(appStage == 'Applicant Details' || appStage == 'Collateral Details')) {

                    String stageErr;
                    try {
                        stageErr = [
                            SELECT Message__c
                            FROM Messages_Config__mdt
                            WHERE DeveloperName = 'Error_Sales_PD_record_creation'
                            LIMIT 1
                        ].Message__c;
                    } catch (Exception e) {
                        stageErr = 'Sales PD cannot be created in the current application stage.';
                    }
                    throw new AuraHandledException(stageErr);
                }
            } catch (AuraHandledException ahe) {
                throw ahe;
            } catch (Exception ex) {
                throw new AuraHandledException(
                    'Unable to validate application stage for Sales PD creation.'
                );
            }
        }

        // Check existing Personal Discussion 
        if (pdRec.Id == null) {
            try {
                List<Personal_Discussion__c> existingPD = [
                    SELECT Id
                    FROM Personal_Discussion__c
                    WHERE Loan_Applicant__c = :pdRec.Loan_Applicant__c
                      AND RecordType.Name = 'Sales PD'
                    LIMIT 1
                ];
                if (!existingPD.isEmpty()) {
                    String dupErr;
                    try {
                        dupErr = [
                            SELECT Message__c
                            FROM Messages_Config__mdt
                            WHERE DeveloperName = 'Only_1_Sales_PD_Record'
                            LIMIT 1
                        ].Message__c;
                    } catch (Exception e) {
                        dupErr = 'Only one Sales PD record is allowed per loan applicant.';
                    }
                    throw new AuraHandledException(dupErr);
                }
            } catch (AuraHandledException ahe) {
                throw ahe;
            } catch (Exception ex) {
                throw new AuraHandledException(
                    'Unable to validate existing Sales PD records for the selected loan applicant.'
                );
            }
        }

        // Set Record Type for new Sales PD only
        if (pdRec.Id == null) {
            pdRec.RecordTypeId = Schema.SObjectType.Personal_Discussion__c
                .getRecordTypeInfosByName()
                .get('Sales PD')    // Record Type Name (label)
                .getRecordTypeId();
        }
        
       
        upsert pdRec;   

        Loan_Applicant__c loanAppUpdate = new Loan_Applicant__c(Id = pdRec.Loan_Applicant__c);

        String oldCustomerProfile = loanAppObj.Customer_Profile__c;
        String newCustomerProfile;

        // Sync Employment Type from PD question
        if (pdRec.Are_you_salaried_or_self_employed__c == 'Self-Employed') {
            loanAppUpdate.Employment_Type__c = 'Self-Employed';
        } else if (pdRec.Are_you_salaried_or_self_employed__c == 'Salaried') {
            loanAppUpdate.Employment_Type__c = 'Salaried';
        }

        //  Customer Profile Logic 
        if (pdRec.Are_you_salaried_or_self_employed__c == 'Self-Employed') {
            if (pdRec.Is_the_GST_Report_available__c == 'Yes') {
                loanAppUpdate.Customer_Profile__c = 'Self Employed- GST/ITR';
            } else if (pdRec.Is_BankStatement_avail_for_BankSurrogate__c == 'Yes') {
                loanAppUpdate.Customer_Profile__c = 'Self Employed- Banking Surrogate';
            } else if (pdRec.Can_Customer_Income_be_assessed__c == 'Yes') {
                loanAppUpdate.Customer_Profile__c = 'Self Employed- Informal';
            } else {
                loanAppUpdate.Customer_Profile__c = 'Non Financial'; 
 loanAppUpdate.IsFinancial_Applicant__c= 'No'; 
            }
        } else if (pdRec.Are_you_salaried_or_self_employed__c == 'Salaried') {
            if (pdRec.Is_the_last_2_month_salary_slip_availabl__c == 'Yes' || 
                pdRec.Is_Form_16_available__c == 'Yes') {
                loanAppUpdate.Customer_Profile__c = 'Formal Salaried';
            } else if (pdRec.Is_salary_credited_in_Bank_Account__c == 'Yes') {
                
                loanAppUpdate.Customer_Profile__c = 'Informal Salaried- Bank Credit'; 
            } else {
             
                loanAppUpdate.Customer_Profile__c = 'Informal Salaried- Cash'; 
            }
        }

        newCustomerProfile = loanAppUpdate.Customer_Profile__c;

        if (oldCustomerProfile != newCustomerProfile) {
            loanAppUpdate.Data_Changes_After_LAF_Generation__c = 'Customer Profile Changed';
            System.debug('>>> Customer Profile changed. Updating Data_Changes_After_LAF_Generation__c');
        }

        update loanAppUpdate;
        System.debug('>>> Loan Applicant updated successfully');

        return pdRec.Id;
    }
    @AuraEnabled(cacheable=true)
public static List<Loan_Applicant__c> getLoanApplicantsWithoutSalesPD(Id applicationId) {
    // check all loan applicants on application
    List<Loan_Applicant__c> applicants = [
        SELECT Id, Name, Account_Name__c, Employment_Type__c
        FROM Loan_Applicant__c
        WHERE Application__c = :applicationId
          AND IsDeleted__c = false
    ];

    if (applicants.isEmpty()) {
        return new List<Loan_Applicant__c>();
    }

 
    Set<Id> applicantIds = new Set<Id>();
    for (Loan_Applicant__c la : applicants) {
        applicantIds.add(la.Id);
    }

    // check loan applicants already have a Sales PD record
    Set<Id> applicantsWithSalesPD = new Set<Id>();
    for (Personal_Discussion__c pd : [
        SELECT Id, Loan_Applicant__c
        FROM Personal_Discussion__c
        WHERE Loan_Applicant__c IN :applicantIds
          AND RecordType.Name = 'Sales PD'
    ]) {
        applicantsWithSalesPD.add(pd.Loan_Applicant__c);
    }

    // Return only applicants without a Sales PD
    List<Loan_Applicant__c> result = new List<Loan_Applicant__c>();
    for (Loan_Applicant__c la : applicants) {
        if (!applicantsWithSalesPD.contains(la.Id)) {
            result.add(la);
        }
    }
    return result;
}

      
    //  Fetch Personal Discussion details Read Only
    @AuraEnabled(cacheable=true)
    public static Personal_Discussion__c getPDRecordDetails(Id pdId) {
        return [
            SELECT Id,
                   Name,
                   Application__r.Name,
                   Are_you_salaried_or_self_employed__c,
                   Is_the_GST_Report_available__c,
                   Is_BankStatement_avail_for_BankSurrogate__c,
                   Can_Customer_Income_be_assessed__c,
                   Is_the_last_2_month_salary_slip_availabl__c,
                   Is_Form_16_available__c,
                   Is_salary_credited_in_Bank_Account__c,
                   Loan_Applicant__r.Name,
                   Owner.Name,
                   CreatedBy.Name,
                   CreatedDate,
                   LastModifiedBy.Name,
                   LastModifiedDate,
                   Loan_Applicant__r.Employment_Type__c
            FROM Personal_Discussion__c
            WHERE Id = :pdId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Personal_Discussion__c getPDFields(Id recordId) {
        return [
            SELECT Name,
                   Owner.Name,
                   Credit_PD_Mode__c,
                   Industry__c,
                   PD_Activity_Status__c,
                   Application__r.Name,
                   Loan_Applicant__r.Name,
                   Are_you_salaried_or_self_employed__c,
                   Is_the_GST_Report_available__c,
                   Is_BankStatement_avail_for_BankSurrogate__c,
                   Can_Customer_Income_be_assessed__c,
                   Is_the_last_2_month_salary_slip_availabl__c,
                   Is_Form_16_available__c,
                   Is_salary_credited_in_Bank_Account__c,
                   Remarks__c,
                   CreatedBy.Name,
                   LastModifiedBy.Name,
                   Loan_Applicant__r.Employment_Type__c
            FROM Personal_Discussion__c
            WHERE Id = :recordId
        ];
    }

    // Gaurav Kumar 26-Dec-2025
    
    @AuraEnabled(cacheable=true)
    public static List<Loan_Applicant__c> getLoanApplicantCreditPd(Id applicationId) {
        return [
            SELECT Id, Name,Account_Name__c, Employment_Type__c, Customer_Profile__c, Subcategory__c, RecordType_Name__c
            FROM Loan_Applicant__c 
            WHERE Application__c = :applicationId AND Customer_Profile__c IN ('Formal Salaried','Informal Salaried- Bank Credit','Informal Salaried- Cash','Self Employed- GST/ITR','Self Employed- Banking Surrogate','Self Employed- Informal')
              AND IsDeleted__c = false 
        ];
    }
    @AuraEnabled
    public static Id savePDRecords(Personal_Discussion__c pdRec) {
        System.debug('>>> Incoming Application__c: ' + pdRec.Application__c);
        System.debug('>>> Incoming Loan_Applicant__c: ' + pdRec.Loan_Applicant__c);
        
        pdRec.RecordTypeId = Schema.SObjectType.Personal_Discussion__c
            .getRecordTypeInfosByName()
            .get('Credit PD')
            .getRecordTypeId();
        pdRec.PD_Activity_Status__c = 'Completed';
        if (pdRec.Id != null) {
            update pdRec;
        } else {
            if(pdRec.office_outside_photo__c == 'Yes'){
                createDocumentRecord('office outside photo',pdRec.Loan_Applicant__c,pdRec.Application__c);
            }
            if(pdRec.office_inside_photo__c == 'Yes'){
                createDocumentRecord('office inside photo',pdRec.Loan_Applicant__c,pdRec.Application__c);
            }
            if(pdRec.SelfieCapturedWithReportingMa__c == 'Yes'){
                createDocumentRecord('Selfie Captured With RM',pdRec.Loan_Applicant__c,pdRec.Application__c);
            }
            insert pdRec;
        }
        Loan_Applicant__c lonApp = new Loan_Applicant__c();
        lonApp.Id = pdRec.Loan_Applicant__c;
        lonApp.Credit_PD_Changed_After_Sendback__c = false;
        update lonApp;
        
        return pdRec.Id;
    }
    public static void createDocumentRecord(String docName,String applicantId,String applicationId){
        Document__c doc = new Document__c();
        doc.Document_Category__c = 'Others';
        doc.Document_Type__c = 'Other';
        doc.File_Name__c = docName;
        doc.Mandatory_Document__c = false;
        doc.Status__c = 'Not Uploaded';
        doc.Stage__c = 'DDE';
        doc.Loan_Applicant__c = applicantId;
        doc.Application__c = applicationId;
        doc.Applicable_For__c = 'Loan Applicants';        
        insert doc;
    }

    @AuraEnabled
    public static String savePDRefrenceRecords(String pdRefJSON,String recordId) {        
        List<PDRefrenceWrapper> warperData;
        try {
            warperData = (List<PDRefrenceWrapper>) JSON.deserialize(pdRefJSON, List<PDRefrenceWrapper>.class);
        } catch (Exception ex) {
            throw new AuraHandledException('Invalid JSON payload: ' + ex.getMessage());
        }
        
        List<PD_Reference__c> toInsert = new List<PD_Reference__c>();
        List<PD_Reference__c> toUpdate = new List<PD_Reference__c>();
        
        for (PDRefrenceWrapper r : warperData) {
            if(r.sfId != null){
                PD_Reference__c pd = new PD_Reference__c();
                pd.Id = r.sfId;
                pd.Personal_Discussion__c = recordId;
                pd.contact_address_details__c = r.contact;
                pd.Customer_Type__c = r.type;
                pd.nature_of_transaction__c = r.nature;
                pd.value_of_transaction__c = r.value;
                pd.frequency_of_transaction__c = r.frequency;
                pd.doing_business_since_when__c = r.doingSince;
                pd.credit_period__c = r.creditPeriod;
                
                toUpdate.add(pd);
            }else{
                PD_Reference__c pd = new PD_Reference__c();
                pd.Personal_Discussion__c = recordId;
                pd.contact_address_details__c = r.contact;
                pd.Customer_Type__c = r.type;
                pd.nature_of_transaction__c = r.nature;
                pd.value_of_transaction__c = r.value;
                pd.frequency_of_transaction__c = r.frequency;
                pd.doing_business_since_when__c = r.doingSince;
                pd.credit_period__c = r.creditPeriod;
                
                toInsert.add(pd);
            }
            
        }
        
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
            
        }
        
        return 'Succes';
        
    }
    @AuraEnabled 
    public static String saveRetailsProfileRelRecords(String pdRefJSON,String profileName,String recordId) {
        System.debug('pdRefJSON : '+pdRefJSON);
        String profileRecordTypId = Schema.getGlobalDescribe().get('Personal_Discussion_Details__c').getDescribe().getRecordTypeInfosByName().get('Profile').getRecordTypeId(); 
        List<PDRetailWrapper> warperData; Map<String, String> profileMap = new Map<String, String>{ 'retails' => 'Retail / Job Work', 'serviceProvider' => 'Service Provider', 'Contractor' => 'Contractor', 'OthersProfile' => 'Others-5' }; 
            try {
                warperData = (List<PDRetailWrapper>) JSON.deserialize(pdRefJSON, List<PDRetailWrapper>.class); 
                System.debug('PDRetailWrapper : '+warperData);
            } catch (Exception ex) {
                throw new AuraHandledException('Invalid JSON payload: ' + ex.getMessage());
            } 
        List<Personal_Discussion_Details__c> toInsert = new List<Personal_Discussion_Details__c>(); 
        List<Personal_Discussion_Details__c> toUpdate = new List<Personal_Discussion_Details__c>(); 
        for (PDRetailWrapper r : warperData) { 
            if(r.sfId != null){ 
                if(profileMap.get(r.type) == profileName){
                    Personal_Discussion_Details__c pd = new Personal_Discussion_Details__c();
                    pd.Id = r.sfId;
                    pd.Personal_Discussion__c = recordId;
                    pd.Profile__c = profileName;
                    pd.Item__c = r.item; 
                    pd.Daily_Volume__c = Decimal.valueOf(r.dailyVolume); 
                    pd.Cost__c = Decimal.valueOf(r.cost); 
                    pd.Total_Cost_Unit__c = Decimal.valueOf(r.totalCost); 
                    pd.Sale_Value_Unit__c = Decimal.valueOf(r.saleUnit); 
                    pd.Saving_Unit__c = Decimal.valueOf(r.savingUnit); 
                    pd.RecordTypeId = profileRecordTypId; toUpdate.add(pd);
                }
            }
            else{ 
                if(profileMap.get(r.type) == profileName){ 
                    Personal_Discussion_Details__c pd = new Personal_Discussion_Details__c(); 
                    pd.Personal_Discussion__c = recordId; 
                    pd.Item__c = r.item; 
                    pd.Profile__c = profileName; 
                    pd.Daily_Volume__c = Decimal.valueOf(r.dailyVolume); 
                    pd.Cost__c = Decimal.valueOf(r.cost); 
                    pd.Total_Cost_Unit__c = Decimal.valueOf(r.totalCost); 
                    pd.Sale_Value_Unit__c =Decimal.valueOf(r.saleUnit); 
                    pd.Saving_Unit__c = Decimal.valueOf(r.savingUnit); 
                    pd.RecordTypeId = profileRecordTypId; toInsert.add(pd); 
                } 
            } 
        } if (!toInsert.isEmpty()) {
            insert toInsert; 
        } if (!toUpdate.isEmpty()) {
            update toUpdate; 
        } 
        return 'Succes';
    }
    @AuraEnabled(cacheable=true)
    public static String getBranchCode(String applicationId) {
        if (String.isBlank(applicationId)) {
            return '';
        }
        Application__c appObj = [SELECT Branch__r.Branch_Code__c  FROM Application__c WHERE Id = :applicationId LIMIT 1];
        
        return appObj.Branch__r.Branch_Code__c != null ? appObj.Branch__r.Branch_Code__c : '';
    }

    @AuraEnabled(cacheable=true)
    public static Personal_Discussion__c getPdDynamic(Id loanApplicantId) {
        if(loanApplicantId == null) return null;
        return [ SELECT Name, RecordTypeId, Credit_PD_Mode__c, Application__c, Nature_of_Business__c, Industry__c, 
                Remarks__c, PD_Activity_Status__c, Total_Expences__c, Loan_Applicant__c, Are_you_salaried_or_self_employed__c, 
                Is_the_GST_Report_available__c, Is_BankStatement_avail_for_BankSurrogate__c, Can_Customer_Income_be_assessed__c, 
                Is_the_last_2_month_salary_slip_availabl__c, Is_Form_16_available__c, Is_salary_credited_in_Bank_Account__c, 
                Residence_Status__c, Distance_from_Branch__c, Resi_Stability__c, Critical_Medical_History_Details__c, 
                Involved_In_Speculative_Activities__c, Name_of_Successor_Alternate_Handler__c, application_no__c, other__c, 
                rent__c, transport__c, telephone__c, total__c, entertainment__c, chits_pigmy__c, loan_amount_applied_in_rs_lacs__c, 
                education__c, medical_expenditure__c, branch_name__c, name_of_applicant__c, sourcing_channel__c, clothing_expense__c,
                food_expense__c, insurance__c, cibil_crif_score__c, water_electricity__c, Name_of_the_Business__c, Person_Met__c, 
                Relationship__c, KYC_Validated_At_Business_Place__c, Documents_Verified__c, Business_board_seen__c, 
                Constitution_of_Business__c, Current_Office_Business_Address__c, Enter_Landmark_details__c, Business_Ownership_proof_if_available__c, 
                Locality_of_Business_Premises_Shop__c, asset_created_last_48_months__c, date_of_purchase__c, type_of_asset_declared__c,
                asset_owner__c, description_of_assets__c, investment_value__c, estimate_value__c, property_owner_name__c, 
                proof_of_document__c, property_address__c, end_use_of_loan__c, pd_snaps_video__c, Year_in_business__c, 
                Prior_Occupaton_if_different_From_Curren__c, Business_Premises__c, Occupied_Since_When__c, Size_of_the_Premises__c, 
                Type_of_Business_premises__c, Stock_Value_observed_during_PD_visit__c, No_of_family_members_in_the_family_with__c, 
                Are_there_any_critical_medical_history_o__c, Any_Alternate_Successor_of_Family_Who_C__c, Whether_the_applicant_is_involved_in_onl__c, 
                PD_Visit_Remarks_Recommendation_Note__c, office_timing__c, salary_date__c, SelfieCapturedWithReportingMa__c, 
                employer_industry__c, SelectConditionOfEmployerSPremises__c, job_profile_of_borrower__c, week_off_day__c, 
                nature_of_employers_business__c, incentive_received_monthly__c, office_outside_photo__c, type_of_employer_premises__c, 
                previous_employer_name__c, employer_issued_id_card__c, no_of_coworkers_in_office__c, employer_name__c, 
                is_company_operating_in_shifts__c, total_experience__c, office_inside_photo__c, salary_payment_mode__c, 
                current_fixed_salary__c, employer_representative_met__c, date_of_joining_current_employer__c, office_name_board_photo__c, 
                previous_employment_brief__c, salary_deducted_for_leaves__c, notes_from_credit_manager__c, employer_classification__c,
                DoesApplicantTakeAdvance__c, IsAnyAttendanceRecordMaintained__c, StartingSalaryOfBorrowerWithC__c, house_keeping_expense__c,
                cost__c, gross_daily_income__c, site_details__c, item__c, margin_per_unit__c, commission_paid_external_parties__c, 
                status__c, water_tea_expense__c, work_details__c, gross_monthly_income__c, sale_value_per_unit__c, other_fixed_expenses__c, 
                total_cost_per_unit__c, saving_per_unit__c, period_of_service__c, fixed_salary_all_employees__c, daily_volume__c, 
                contract_value__c, shop_rent_business_premises__c, stationery_expense__c, Avg_amount_of_Electricity_bill_of_last_3__c, 
                PD_Type_Selection__c 
                FROM Personal_Discussion__c 
                WHERE Loan_Applicant__c = :loanApplicantId AND RecordType.Name='Credit PD' LIMIT 1 ]; 
    }

    @AuraEnabled()
    public static List<Branch_Mapping__c> getBranchMapping(Id applicationId) {
        if(applicationId == null) return null;
        
        Application__c appObj = [SELECT Id, Branch__c FROM Application__c WHERE Id=:applicationId LIMIT 1];
        return [SELECT Id,Name,Vendor__c,Vendor__r.Name FROM Branch_Mapping__c
                WHERE Branch_Master__c =:appObj.Branch__c AND Vendor__c!= null];
    }
    @AuraEnabled()
    public static AttachmentWrapper getAttachmentRecord(Id applicantId) {
        if(applicantId == null) return null;
        
        Attachment att = [SELECT Id, Name, Body, ContentType FROM Attachment WHERE ParentId = :applicantId ORDER BY CreatedDate DESC LIMIT 1 ];
        AttachmentWrapper atWrap = new AttachmentWrapper();
        atWrap.base64Data = EncodingUtil.base64Encode(att.Body);
        atWrap.fileName = att.Name;
        return atWrap;
    }
    @AuraEnabled
    public static Decimal getBranchAddress(Id applicationId,String latitude,String longitude) {
        if (applicationId == null) return null;
        List<Application__c> appObjList = [SELECT Id, Branch__r.Branch_Location__Latitude__s, Branch__r.Branch_Location__Longitude__s
                                           FROM Application__c
                                           WHERE Id = :applicationId LIMIT 1 ];
        Decimal distane = calculateDistance(latitude,longitude,appObjList[0].Branch__r.Branch_Location__Latitude__s,appObjList[0].Branch__r.Branch_Location__Longitude__s);
        return distane!= null ? distane :null;
    }
    private static Double calculateDistance(String latitude1, String longtitude1, Decimal latitude2, Decimal longtitude2)
    {
        System.debug('latitude1 :'+latitude1);
        System.debug('longtitude1 :'+longtitude1);
        Location l1 = Location.newInstance(Decimal.valueOf(latitude1), Decimal.valueOf(longtitude1));
        Location l2 = Location.newInstance(latitude2, longtitude2);
        Double distance = Location.getDistance(l1,l2,'km');
        //Decimal distanceInMeters = distance * 1000;
        //return distanceInMeters;
        return distance;
    }
    @AuraEnabled(cacheable=true)
    public static List<Credit_Pd_Template_Configuration__mdt> getAllTemplates() {
        // Use MasterLabel for the label on custom metadata types
        return [
            SELECT Id, MasterLabel, Profile__c, PD_Template__c
            FROM Credit_Pd_Template_Configuration__mdt
            ORDER BY MasterLabel
        ];
    }

    @AuraEnabled
    public static PDProfileResponse fetchProfileWiseData(Id recordId) {

    PDProfileResponse response = new PDProfileResponse();

    for (Personal_Discussion_Details__c pd : [SELECT Id, Profile__c, Item__c,Daily_Volume__c, Cost__c, Total_Cost_Unit__c,
                                              Sale_Value_Unit__c, Saving_Unit__c
                                              FROM Personal_Discussion_Details__c
                                              WHERE Personal_Discussion__c = :recordId ]) {

        PDRetailWrapper w = new PDRetailWrapper();
        w.sfId = pd.Id;
        w.item = pd.Item__c;
        w.dailyVolume = String.valueOf(pd.Daily_Volume__c);
        w.cost = String.valueOf(pd.Cost__c);
        w.totalCost = String.valueOf(pd.Total_Cost_Unit__c);
        w.saleUnit = String.valueOf(pd.Sale_Value_Unit__c);
        w.savingUnit = String.valueOf(pd.Saving_Unit__c);

        if (pd.Profile__c == 'Retail / Job Work') {
            w.type = 'retails';
            w.uid = 'retails-' + pd.Id;
            response.retails.add(w);

        } else if (pd.Profile__c == 'Service Provider') {
            w.type = 'serviceProvider';
            w.uid = 'serviceProvider-' + pd.Id;
            response.serviceProviders.add(w);

        } else if (pd.Profile__c == 'Contractor') {
            w.type = 'Contractor';
            w.uid = 'Contractor-' + pd.Id;
            response.contractors.add(w);

        } else if (pd.Profile__c == 'Others') {
            w.type = 'OthersProfile';
            w.uid = 'OthersProfile-' + pd.Id;
            response.othersProfiles.add(w);
        }
    }

    return response;
}


    public class PDRefrenceWrapper {
        @AuraEnabled public String uid;
        @AuraEnabled public String type;
        @AuraEnabled public String contact;
        @AuraEnabled public String nature;
        @AuraEnabled public String value;
        @AuraEnabled public String frequency;
        @AuraEnabled public String doingSince;
        @AuraEnabled public String creditPeriod;
        @AuraEnabled public Id sfId; 
    }
    public class PDRetailWrapper {
        @AuraEnabled public String uid;
        @AuraEnabled public String type;
        @AuraEnabled public String item;
        @AuraEnabled public String dailyVolume;
        @AuraEnabled public String cost;
        @AuraEnabled public String totalCost;
        @AuraEnabled public String saleUnit;
        @AuraEnabled public String savingUnit;
        @AuraEnabled public Id sfId; 
    }
    public class PDProfileResponse {
        @AuraEnabled public List<PDRetailWrapper> retails ;
        @AuraEnabled public List<PDRetailWrapper> serviceProviders ;
        @AuraEnabled public List<PDRetailWrapper> contractors ;
        @AuraEnabled public List<PDRetailWrapper> othersProfiles ;
        public PDProfileResponse() {
        retails = new List<PDRetailWrapper>();
        serviceProviders = new List<PDRetailWrapper>();
        contractors = new List<PDRetailWrapper>();
        othersProfiles = new List<PDRetailWrapper>();
    }
    }
    public class AttachmentWrapper{
        @AuraEnabled public String base64Data;  
        @AuraEnabled public String fileName;     
        @AuraEnabled public String contentType;
    }
    // Gaurav Kumar 26-Dec-2025
}