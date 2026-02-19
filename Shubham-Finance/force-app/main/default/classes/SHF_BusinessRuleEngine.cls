/**
* @File Name          : SHF_BusinessRuleEngine.cls
* @Description        : Check the condition for auto deviations.
* @Author             : Mansur 
* @Test CLass         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         20-09-2025               Mansur                 Initial Version
*/
public  class SHF_BusinessRuleEngine {
    public  Map<String,Deviation_Master__c> deviationMasterMap = new Map<String,Deviation_Master__c>();
    public List<Deviation_and_Sanction_Condition__c> deviationList = new List<Deviation_and_Sanction_Condition__c >();
    public Map<String,Map<String,String>> mdtMap = new Map<String,Map<String,String>>();
    // Constructor to initialize maps
    public SHF_BusinessRuleEngine() {
        initializeMaps();
    }
    
    private void initializeMaps() {
        Map<String,Business_Rule_Engine__mdt> breMetaData = new Map<String,Business_Rule_Engine__mdt>();
        
        // Get all records of the custom metadata type
        breMetaData = Business_Rule_Engine__mdt.getAll();
        for(Business_Rule_Engine__mdt mdtName : breMetaData.Values()){
            if(mdtName.Deviation_Name__c != null && mdtName.Extra_Parameters__c != null){
                Map<String, String> extraParamsMap = new Map<String, String>();
                // Split by new line to get individual key-value pairs
                List<String> keyValuePairs = mdtName.Extra_Parameters__c.split('\n');
                for (String pair : keyValuePairs) {
                    // Split each pair by colon to separate key and value
                    List<String> keyValue = pair.split(':');
                    if (keyValue.size() == 2) {
                        String key = keyValue[0].trim();
                        String value = keyValue[1].trim();
                        extraParamsMap.put(keyValue[0].trim(), keyValue[1].trim());
                        keyValue.clear();
                    }
                }
                mdtMap.put(mdtName.Deviation_Name__c,extraParamsMap) ;
            }
        }
        
        // Fetching all deviation master record
        SHF_DeviationMasterSelector deviationMaster = new SHF_DeviationMasterSelector();
        for(Deviation_Master__c deviation : deviationMaster.getAllDeviations()){
            deviationMasterMap.put(deviation.Deviation__c,deviation);
        }
    }
    //main method 
    public String createDeviationAndSanctionCondition(String applicationId){
        List<Loan_Applicant__c> applicantList = new List<Loan_Applicant__c>();
         Set<Id> applicantsIdForIdCard = new Set<Id>();
         Set<Id> financialApplicantIdSet = new Set<Id>();
         List<Loan_Applicant__c> applicantsForIdCard = new List<Loan_Applicant__c>();
        List<Loan_Applicant__c> financialApplicantList = new List<Loan_Applicant__c>();
        List<Loan_Applicant__c> nonFinancialapplicantList = new List<Loan_Applicant__c>();
        List<Branch_Master__c > branchList = new List<Branch_Master__c >();
        List<Branch_Master__c> branchMaster = new List<Branch_Master__c>();
        List<Address__c > addressList = new List<Address__c>();
        Loan_Applicant__c primaryApplicant = new Loan_Applicant__c();
        List<Collateral__c> collateralList = new List<Collateral__c>();
        Set<Id> collateralIdSet = new Set<Id>();
        List<Collateral_Application__c> collateralApplicationList = new List<Collateral_Application__c>();
        String msg ='';
        Decimal higherIncome = 0.00;
        Product_Master__c   childMasterRecord = new Product_Master__c();
        Loan_Applicant__c higherIncomeContributor = new Loan_Applicant__c();
        List<E_Verification__c> cibilCrifVerificationList = new List<E_Verification__c>();
        Set<Id> crifCibilIdSet = new Set<Id>();
        Map<String,E_Verification__c> applicantCrifMap = new Map<String,E_Verification__c>();
        Map<String,E_Verification__c> applicantCibilMap = new Map<String,E_Verification__c>();
        Map<String,Deviation_and_Sanction_Condition__c> existingMap   = new Map<String,Deviation_and_Sanction_Condition__c>();
        List<Deviation_and_Sanction_Condition__c> upsertDeviationList = new  List<Deviation_and_Sanction_Condition__c>();
                List<Deviation_and_Sanction_Condition__c> insertDeviationList = new  List<Deviation_and_Sanction_Condition__c>();

        Set<String> incominDeviationgKeys = new Set<String>();
        try{
            if(applicationId != null){
                //fetching Applicatin detail
                Application__c applicationDetail = new SHF_ApplicationSelector().selectApplicationForCIBIL(applicationId) ;
                //fetching all existing deviation records
                List<Deviation_and_Sanction_Condition__c> existingDeviaationList = new SHF_DeviationAndSanctionSelector().selectByApplicationId(new set<Id>{applicationId});
                //fetching Loan Applicants detail
                applicantList = new SHF_LoanApplicantsSelector().selectByIdWithLoanApplication(new Set<Id>{applicationId});
                if(!applicantList.isEmpty()){
                    for(Loan_Applicant__c applicant : applicantList){
                        if(applicant.CRIF_Verification__c != null && applicant.RecordType_Name__c == SHF_ConstantsUtil.INDIVIDUAL){
                            crifCibilIdSet.add(applicant.CRIF_Verification__c);
                        }
                        if(applicant.CIBIL_Verification__c != null && applicant.RecordType_Name__c == SHF_ConstantsUtil.INDIVIDUAL){
                            crifCibilIdSet.add(applicant.CIBIL_Verification__c);
                        }
                        if(applicant.Applicant_Type__c == SHF_ConstantsUtil.PRIMARY_APPLICANT){
                            primaryApplicant = applicant;
                        }
                        if(applicant.Customer_Profile__c == SHF_ConstantsUtil.INFORMAL_SALRIED_BANK_CREDIT || applicant.Customer_Profile__c == SHF_ConstantsUtil.INFORMAL_CASH_SALRIED ){
                            applicantsForIdCard.add(applicant);
                            applicantsIdForIdCard.add(applicant.Id);
                        }
                        if(applicant.IsFinancial_Applicant__c == 'Yes'){
                            //fetching Higher income contributor
                            if(higherIncome < applicant.Appraised_Income__c){ 
                                higherIncome = applicant.Appraised_Income__c;
                                higherIncomeContributor = applicant;
                                cibilCrifVerificationList = applicant.E_Verifications__r;
                            }
                            financialApplicantList.add(applicant);
                            financialApplicantIdSet.add(applicant.Id);
                        }else{
                            nonFinancialapplicantList.add(applicant);
                        }
                    }
                }
                if(applicationDetail != null){
                    system.debug('higherIncomeContributor.Customer_Profile__c ' + higherIncomeContributor.Customer_Profile__c);
                    // fetching child product record with same customer profile as higherIncome contributor
                    childMasterRecord = getChildProductRecord(applicationDetail.Product__c,higherIncomeContributor.Customer_Profile__c);
                    //fetching Branch master detail
                    branchMaster  =new  SHF_BranchSelector().getBranchById(new set<Id>{applicationDetail.Branch__c});
                }
                if(childMasterRecord != null){
                    
                    if(!crifCibilIdSet.isEmpty()){
                        List<E_Verification__c> crifCibilVerificationList =  new SHF_E_VerificationSelector().selectByrecordId(crifCibilIdSet);
                        if(!crifCibilVerificationList.isEmpty()){
                            for(E_Verification__c ver : crifCibilVerificationList){
                                if(ver.RecordTypeId == SHF_ConstantsUtil.CRIF_RECORDTYPE_ID){
                                    applicantCrifMap.put(ver.Loan_Applicant__c, ver);
                                }
                                if(ver.RecordTypeId == SHF_ConstantsUtil.CIBIL_RECORDTYPE_ID){
                                    applicantCibilMap.put(ver.Loan_Applicant__c, ver);
                                }
                            }
                        }
                    }
                    //retrigger deviation logic
                    if(!existingDeviaationList.isEmpty()){
                        for (Deviation_and_Sanction_Condition__c dev : existingDeviaationList) {
                            String key = (dev.Loan_Applicant__c != null)
                                ? dev.Deviation_Name__c + '|' + dev.Loan_Applicant__c
                                : dev.Deviation_Name__c + '|NO_APPLICANT';
                            existingMap.put(key, dev);
                        }
                        system.debug('existingMap.size> ' + existingMap.size());
                        system.debug('existingMap> ' + existingMap);
                    }
                    
                     collateralApplicationList = new SHF_CollateralApplicationSelector().selectByApplicationIds(new Set<Id>{applicationId});
                     system.debug('collateralApplicationList > ' + collateralApplicationList);
                     if(!collateralApplicationList.isEmpty()){
                        
                        for(Collateral_Application__c collApplication : collateralApplicationList){
                            collateralIdSet.add(collApplication.Collateral__c);
                        }
                     } 
                      system.debug('collateralIdSet > ' + collateralIdSet   );
                      //fetching Branch master detail
                      if(!collateralIdSet.isEmpty()){
                        //fetching collateral detail
                    collateralList = new SHF_CollateralSelector().selectByIds(collateralIdSet);

                      }
                    //dpd deviation------------------done--
                    dpdDeviationAndException(applicationId,applicantList,mdtMap,applicantCrifMap);
                    //LTV Deviations Up To 10%-----------------done
                    ltvDeviation(applicationDetail,mdtMap,childMasterRecord,collateralList);
                    //borrower location deviation outside geo limit----------------done
                    borrowerDeviation(applicationId,financialApplicantList,mdtMap,branchMaster);
                    //Deviation for Non-Service Location---------------done
                    nonServiceDeviation(applicationId,branchMaster,financialApplicantList);
                    //Negative Profile deviations---------------done
                    negativeProfileDeviation(applicationId,applicantList);
                    //Foir deviations----------------done
                    foirDeviation(applicationDetail,mdtMap,childMasterRecord);
                    //Minimum Age Deviation Primary Applicant--------------done
                    minimumAgeDeviation(applicationDetail,primaryApplicant,mdtMap,childMasterRecord);
                    //Cash Rentals/Multiple Tenanted Property deviation
                     rentalDeviation(applicationId,financialApplicantIdSet);
                    //Borrower Classified As Investors deviation---------------------done
                    borrowerAsInvestorDeviation(applicantList);
                    //Loan Amount Is More Than Maximum Branch Limit
                    amountMoreThanBranchLimitDeviation(applicationDetail,higherIncomeContributor,primaryApplicant);
                    //Company ID Card not available
                    idCardDeviation(applicationId,applicantsForIdCard,applicantsIdForIdCard);//All informal salaried cash, informal salaried bank credit-> credit pd recordtype 
                    //Average Bank Balance Exception
                    averageBankBalanceException(applicationId);
                    //Minimum Loan Amount Deviation ---------------------done
                    minimumLoanAMountDeviation(applicationDetail,childMasterRecord);
                    //Banking Requirement Exception
                    bankingRequirementException(applicationId);
                    //Maximum Age Deviations-// Maximum Age-for Income contributor and non financial(At Maturity)----------------done
                    maxAgeLimitDeviation(applicationDetail,applicantList,childMasterRecord);
                    //Deviation On Work Experience------------------done
                    workExperienceDeviation(applicationDetail,applicantList,childMasterRecord);
                    //Income Documents Not Available ----------------done
                    incomeDocsDeviation(applicationDetail,primaryApplicant);
                    //Minimum Tenure validation------------------done
                    minimumTenureDeviation(applicationDetail,childMasterRecord);
                    //Minimum CRIF/CIBIL Score(Financial Higher Income Applicant)--------------need rectification 
                    minimumCibilCrifDeviation(applicationDetail,higherIncomeContributor,childMasterRecord,applicantCibilMap,applicantCrifMap);
                    //IIR--------------done
                    deviationForIIR(applicationDetail,childMasterRecord);
                    //LVR/LCER--------------done
                    deviationForLvrAndLcer(applicationDetail,childMasterRecord);
                    //IAR--------------done
                    deviationForIAR(applicationDetail,childMasterRecord);
                    //Minimum Age-Co-Applicant-----------------done
                    minimumAgeCoApplicantDeviation(applicationDetail,applicantList,mdtMap,childMasterRecord);
                    //Maximum Age Property Owner(At Maturity)-------------------done
                    propertyOwnerMaxAgeDeviation(applicationDetail,collateralList,childMasterRecord);
                    //OGL-Property Address------------------done
                    oglPropertyAddDeviation(applicationDetail,collateralList);
                    //Rental Income
                    //  rentalIncomeDeviation(applicationId);
                }
            }
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType> {Deviation_and_Sanction_Condition__c.SObjectType});
            system.debug('deviationList > ' + deviationList);
             system.debug('deviationList.size > ' + deviationList.size());
            if(deviationList != null){
                if(existingMap != null && existingMap.size() > 0){
                    for (Deviation_and_Sanction_Condition__c incomingDeviation : deviationList) {
                        String key = (incomingDeviation.Loan_Applicant__c != null)
                            ? incomingDeviation.External_Key__c + '|' + incomingDeviation.Loan_Applicant__c
                            : incomingDeviation.External_Key__c + '|NO_APPLICANT';
                        incominDeviationgKeys.add(key);
                        if (existingMap.containsKey(key)) {
                            // Update existing
                            incomingDeviation.Id = existingMap.get(key).Id;
                            upsertDeviationList.add(incomingDeviation);
                        } else {
                            // Insert new
                            upsertDeviationList.add(incomingDeviation);
                        }
                    }
                   
                    //deactive the existing deviation
                    for (String key : existingMap.keySet()) {
                        if (!incominDeviationgKeys.contains(key)) {
                            Deviation_and_Sanction_Condition__c toBeInactiveDeviation = existingMap.get(key);
                            toBeInactiveDeviation.Is_Delete__c = true;
                            upsertDeviationList.add(toBeInactiveDeviation);
                        }
                    }
                    if(!upsertDeviationList.isEmpty()){
                        upsert upsertDeviationList;
                    }
                    
                }else{
                    uow.registerNew(deviationList);                        
                    uow.commitWork(); //inserted the list of deviation records
                }               
                //update bre trigger field on Application
                Application__c app  = new Application__c();
                app.id = applicationId;
                app.Bre_Execution_Date__c = System.today();
                update app;
            }
            msg = 'Success';
            Logger.info('BRE executed for these deviations ' + deviationList);
        }catch(Exception ex){
           msg =  ex.getMessage()+' Line:- '+ ex.getlineNumber();
            system.debug('error>>> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
            Logger.error('Auto BRE execution error : ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
        }finally{
            Logger.saveLog();
        }
        return msg;
    }
    
    //dpd deviation and exception
    public void dpdDeviationAndException(String applicationId,List<Loan_Applicant__c> applicantList,Map<String,Map<String,String>> metadataMap,Map<String,E_Verification__c> applicantCrifMap){        
        
        
        if(!applicantList.isEmpty()){
            for(Loan_Applicant__c applicant : applicantList){
                if(applicantCrifMap.containsKey(applicant.Id)){
                    if(applicantCrifMap.get(applicant.Id).Credit_Bureau_Exception__c){
                        createDeviationRecord(applicationId,SHF_ConstantsUtil.CREDIT_BUREAU_EXCEPTION,applicant.Id);
                    }
                    if(applicantCrifMap.get(applicant.Id).Credit_Bureau_Deviations__c){
                        createDeviationRecord(applicationId,SHF_ConstantsUtil.CREDIT_BUREAU_DEVIATION,applicant.Id);
                    }
                }
            }
        }        
    }
    
    //LTV Deviations Up To 10%
    public void ltvDeviation( Application__c applicationDetail, Map<String,Map<String,String>> mdtMap,Product_Master__c childMasterRecord,List<Collateral__c> collateralList){
        if(applicationDetail  != null && childMasterRecord != null){
            decimal ltvDiff = 0.00;
            boolean isPlot  =  false;
            //first we haveto check validation limit,1. 90% ltv, for loan upto 30 Lacs 2. 80% ltv, for loan amount amount  30 Lacs and above
            if((applicationDetail.Applied_Loan_Amount__c <= Integer.valueOf(mdtMap.get(SHF_ConstantsUtil.LTV_DEVIATION).get('applied_loanAmount')) && applicationDetail.LTV__c <= Decimal.valueOf(mdtMap.get(SHF_ConstantsUtil.LTV_DEVIATION).get('aggregatLtv2'))) || (applicationDetail.Applied_Loan_Amount__c > Integer.valueOf(mdtMap.get(SHF_ConstantsUtil.LTV_DEVIATION).get('applied_loanAmount')) && applicationDetail.LTV__c <= Decimal.valueOf(mdtMap.get(SHF_ConstantsUtil.LTV_DEVIATION).get('aggregatLtv1'))) ){
                if(!collateralList.isEmpty()){
                    for(Collateral__c coll : collateralList ){
                        if(coll.Collateral_Sub_Type_Property_Details__c == SHF_ConstantsUtil.PURCHASE_A_PLOT || coll.Collateral_Sub_Type_Property_Details__c == SHF_ConstantsUtil.PLOT_SELF_CONSTRUCTION){
                            isPlot = true;
                        }
                    }
                }
                if(isPlot){
                    ltvDiff =  applicationDetail.LTV__c - childMasterRecord.Plot_LTV__c;
                }else{
                    ltvDiff =  applicationDetail.LTV__c - childMasterRecord.LTV__c;
                }
                
            }
            //checking for deviation if diffrenece between caluclate ltv and configured ltv in product is less than 10%
            if(ltvDiff <= Decimal.valueOf(mdtMap.get(SHF_ConstantsUtil.LTV_DEVIATION).get('ltv_difference')) && ltvDiff > 0){
                createDeviationRecord( applicationDetail.Id,SHF_ConstantsUtil.LTV_DEVIATION,null);
            }
        }
    }
    
    //borrower location deviation outside geo limit
    public void borrowerDeviation(String applicationId,List<Loan_Applicant__c> applicantList,Map<String,Map<String,String>> mdtMap, List<Branch_Master__c> branchMaster){
        if(!applicantList.isEmpty()){
            for(Loan_Applicant__c applicant :applicantList ){
                if(!applicant.Addresses1__r.isEmpty() && applicant.IsFinancial_Applicant__c == 'Yes' ){
                    for(Address__c address : applicant.Addresses1__r){
                        if(address.Mailing_Address__c == SHF_ConstantsUtil.OFFICE_ADDRESS || address.Mailing_Address__c == SHF_ConstantsUtil.RESIDENCE_ADDRESS || address.Address_Type__c == SHF_ConstantsUtil.OFFICE_ADDRESS_Business ){
                            if(!branchMaster.isEmpty()){
                                //distance calculation by using SOQL query
                                List<Branch_Master__c > branches = [SELECT Id, DISTANCE(branch_Location__c, :address.Address_Location__c, 'km') distance 
                                                                    FROM Branch_Master__c WHERE Id =:branchMaster[0].Id LIMIT 1];
                                if (!branches.isEmpty()) {
                                    if( (Double)branches[0].get('distance') >  (Double)Integer.valueOf(mdtMap.get(SHF_ConstantsUtil.BORROWER_GEOLOCATION).get(SHF_ConstantsUtil.DISTANCE_LIMIT))){
                                        createDeviationRecord(applicationId,SHF_ConstantsUtil.BORROWER_GEOLOCATION,applicant.Id);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //Deviation for Non-Service Location
    public void nonServiceDeviation(String applicationId,  List<Branch_Master__c> branchMaster, List<Loan_Applicant__c> applicantList){
        Map<String,String> applicantOfficeCityMap = new Map<String,String>();
        //get branch city
        Set<String> branchCitySet = new Set<String>();
        for(Branch_Master__c branch :  [SELECT Id,Name from Branch_Master__c ]){
            branchCitySet.add(branch.Name);
        }
        
        if(!applicantList.isEmpty()){
            for(Loan_Applicant__c applicant : applicantList){
                if(applicant.IsFinancial_Applicant__c == 'Yes'){
                    if(!applicant.Addresses1__r.isEmpty()){
                        for(Address__c address : applicant.Addresses1__r){
                            if(address.Mailing_Address__c == SHF_ConstantsUtil.OFFICE_ADDRESS || address.Address_Type__c == SHF_ConstantsUtil.OFFICE_ADDRESS_Business){
                              if(!branchCitySet.isEmpty()){
                                    if(!branchCitySet.contains(address.City__c)){
                                         createDeviationRecord(applicationId,SHF_ConstantsUtil.DEVIATION_FOR_NON_SERVICE_LOCATION, applicant.Id );
                                    }
                                  }
                            }
                        }
                    }
                }
            }
        }     
    }
    
    //Negative Profile
    public void negativeProfileDeviation(String applicationId, List<Loan_Applicant__c> applicantList){
        if(applicationId != null && !applicantList.isEmpty()){
            for(Loan_Applicant__c applicant : applicantList){
                if(applicant.Profession_Category__c == SHF_ConstantsUtil.NEGATIVE){
                    createDeviationRecord(applicationId,SHF_ConstantsUtil.NEGATIVE_PROFILE, applicant.Id );
                }
            }
        }
    }
    
    //Foir Deviations
    public void foirDeviation(Application__c applicationDetail,Map<String,Map<String,String>> mdtMap,Product_Master__c childMasterRecord){
        if(applicationDetail != null && childMasterRecord != null){
            if(applicationDetail.FOIR_DBR__c != null && childMasterRecord.Policy_FOIR__c != null){
                Decimal foirDifference =  applicationDetail.FOIR_DBR__c - childMasterRecord.Policy_FOIR__c;
                if(foirDifference <= Decimal.valueOf(mdtMap.get(SHF_ConstantsUtil.FOIR_DEVIATION).get('foir_difference'))){
                    createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.FOIR_DEVIATION, null );
                }
            }
        }
    }
    
    //Minimum Age Deviation Primary Applicant
    public void minimumAgeDeviation(Application__c applicationDetail,Loan_Applicant__c primaryApplicant,Map<String,Map<String,String>> mdtMap,Product_Master__c childMasterRecord){
        if(primaryApplicant != null && applicationDetail !=  null && childMasterRecord != null){
            //age calculation
            Date dob = primaryApplicant.Date_of_Birth__c != null ? primaryApplicant.Date_of_Birth__c : primaryApplicant.Date_Of_Incorporation1__c;
            Decimal calculateDOB =  calculateExactAge(dob);
            if(calculateDOB <= Decimal.valueOf(childMasterRecord.Minimum_Applicant_Age__c !=null ? childMasterRecord.Minimum_Applicant_Age__c : '0') && primaryApplicant.Applicant_Age__c >= Integer.valueOf(mdtMap.get(SHF_ConstantsUtil.MINIMUM_AGE_DEVIATION).get(SHF_ConstantsUtil.MINIMUM_APP_AGE)) ){
                createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.MINIMUM_AGE_DEVIATION, primaryApplicant.Id );
            }
        }
    }
    
      //Cash Rentals/Multiple Tenanted Property deviation-
public void rentalDeviation(String applicationId,Set<Id> financialApplicantIdSet){
    Map<String,decimal> appIncomeData  = new  Map<String,decimal>();
    Map<String,decimal> appOtherIncomeData  = new  Map<String,decimal>();
    if(applicationId != null && !financialApplicantIdSet.isEmpty()){
        for( Income_Details__c income : new Shf_IncomeProgramSelector().selectIncomeByLoanApplicantId(financialApplicantIdSet)){
            if(income.RecordType.Name ==SHF_ConstantsUtil.INCOME_DETAILS ){
                appIncomeData.put(income.Loan_Applicant__c+'-'+'Income',income.Total_Income_Monthly__c);
            }else if(income.RecordType.Name ==SHF_ConstantsUtil.OTHERINCOME_DETAILS && income.Income_Head__c == SHF_ConstantsUtil.RENTAL_INCOME){
                 appOtherIncomeData.put(income.Loan_Applicant__c+'-'+'OtherIncome',income.Total_Income_Monthly__c);
            }
        }
        system.debug('appIncomeData > ' + appIncomeData);
         system.debug('appOtherIncomeData > ' + appOtherIncomeData);
        for(String applicantId : financialApplicantIdSet ){
            if(appIncomeData.containsKey(applicantId+'-'+'Income') && appOtherIncomeData.containsKey(applicantId+'-'+'OtherIncome')){
                if(appOtherIncomeData.get(applicantId+'-'+'OtherIncome') > appIncomeData.get(applicantId+'-'+'Income')){
                     createDeviationRecord(applicationId,SHF_ConstantsUtil.CASH_RENTAL_DEVIATION, applicantId );
                }

            }
        }
    }
}
    
    //Borrower Classified As Investors deviation
    public void borrowerAsInvestorDeviation( List<Loan_Applicant__c> applicantList){
        if(applicantList != null && !applicantList.isEmpty()){
            for(Loan_Applicant__c applicant : applicantList){
                if(applicant.Borrower_is_an_Investor__c == true && applicant.IsFinancial_Applicant__c == 'Yes'){
                    createDeviationRecord(applicant.Application__c,SHF_ConstantsUtil.CLASSIFIED_INVESTOR, applicant.Id );
                }
            }
        }       
    }
    
    //Loan Amount Is More Than Maximum Branch Limit
    public void amountMoreThanBranchLimitDeviation(Application__c applicationDetail,Loan_Applicant__c higherIncomeContributor,Loan_Applicant__c primaryApplicant){
        boolean isAmountMoreThanBranchLimit = false;
        if(applicationDetail != null){
            system.debug('Joint Exposure >> ' +applicationDetail.Joint_Exposure__c );
            List<Product_Branch_Mapping__c> productBranchMappList = new SHF_Product_Branch_Mapping_Selector().getProductBranchMappingById(new Set<Id>{applicationDetail.Branch__c},new Set<Id>{applicationDetail.Product__c});
            if(SHF_ConstantsUtil.INFORMAL_CASH_SALRIED == higherIncomeContributor.Customer_Profile__c && (Integer.valueOf(applicationDetail.Joint_Exposure__c) + Integer.valueOf(applicationDetail.Applied_Loan_Amount__c)) > integer.valueOf(mdtMap.get(SHF_ConstantsUtil.AMOUNT_MORE_THAN_BRANCH_LIMIT).get('amountLimit'))){
                isAmountMoreThanBranchLimit = true;
            }
            if(!productBranchMappList.isEmpty()){
                if(SHF_ConstantsUtil.INFORMAL_CASH_SALRIED != higherIncomeContributor.Customer_Profile__c && (Integer.valueOf(applicationDetail.Joint_Exposure__c) + Integer.valueOf(applicationDetail.Applied_Loan_Amount__c)) > integer.valueOf(productBranchMappList[0].Loan_Amount_Limit__c)){
                    isAmountMoreThanBranchLimit = true;
                }
            }
            if(isAmountMoreThanBranchLimit){
                createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.AMOUNT_MORE_THAN_BRANCH_LIMIT, higherIncomeContributor.Id );
                
            }
        }
     
    }
    
    //Company ID Card not available
    public void idCardDeviation(String applicationId,List<Loan_Applicant__c> applicantsForIdCard, Set<Id> applicantsIdForIdCard){
        if(applicationId != null && !applicantsForIdCard.isEmpty()  && !applicantsIdForIdCard.isEmpty()){
           List<Personal_Discussion__c> creditPdList = new Shf_PD_Selector().selectCreditPdByLoanApplicantId(applicantsIdForIdCard);
           system.debug('creditPdList '+ creditPdList);
           if(!creditPdList.isEmpty()){
            for(Personal_Discussion__c pd :creditPdList ){
                if(pd.employer_issued_id_card__c == SHF_ConstantsUtil.NO){
                     createDeviationRecord(applicationId,SHF_ConstantsUtil.COMPANY_ID_CARD_NOT_AVAILABLE, pd.Loan_Applicant__c);
                }
            }
           }
        }
    }

    //Average Bank Balance Exception
    public void averageBankBalanceException(String applicationId){
        
    }
    //Banking Requirement Exception
    public void bankingRequirementException(String applicationId){
        
    }
    //Minimum Loan Amount Deviation 
    public void minimumLoanAMountDeviation( Application__c applicationDetail,Product_Master__c childMasterRecord){
        if(applicationDetail != null && childMasterRecord != null){
            if(applicationDetail.Applied_Loan_Amount__c != null && childMasterRecord.Minimum_Loan_Amount__c != null ){
                if( applicationDetail.Applied_Loan_Amount__c < childMasterRecord.Minimum_Loan_Amount__c){
                    createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.MINIMUM_LOAN_AMOUNT_DEVIATION, null );
                }
            }
        }
    }
    
    //Maximum Age Deviations-// Maximum Age-for Income contributor and non financial(At Maturity)
    public void maxAgeLimitDeviation(Application__c applicationDetail, List<Loan_Applicant__c> applicantList,Product_Master__c childMasterRecord){
        if(applicationDetail != null && !applicantList.isEmpty() && childMasterRecord != null){
            for(Loan_Applicant__c applicant :applicantList ){

                //age calculation
            Date dob = applicant.Date_of_Birth__c != null ? applicant.Date_of_Birth__c : applicant.Date_Of_Incorporation1__c;
            Decimal calculateDOB =  calculateExactAge(dob);
                Decimal ageAtMaturity = 0.00;
                //calculate age at maturity
                ageAtMaturity = (applicationDetail.Tenure__c/12) + calculateDOB;
                if(applicant.IsFinancial_Applicant__c == 'Yes'){
                    if(ageAtMaturity > (childMasterRecord.Max_Income_contributor_Age_At_Maturity__c != null ? childMasterRecord.Max_Income_contributor_Age_At_Maturity__c : 0 )){
                        createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.MAXIMUM_AGE_INCOME_CONTRIBUTOR, applicant.Id );
                    }
                }else{
                    if(ageAtMaturity > (childMasterRecord.Maximum_Age_Non_Finacial_Borrowers_At_Ma__c != null ? childMasterRecord.Maximum_Age_Non_Finacial_Borrowers_At_Ma__c : 0 )){
                        createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.MAXIMUM_AGE_NON_FINAC, applicant.Id );
                    }
                }
                
            }
            
        }
    }
    
    //Income Documents Not Available 
    public void incomeDocsDeviation(Application__c applicationDetail, Loan_applicant__c primaryApplicant){
        if(applicationDetail != null && primaryApplicant != null){
           boolean isIncomeDocAvailable = false;
            List<Document__c> documentList = new  SHF_DocumentsSelector().selectByApplicationId(new set<Id>{applicationDetail.Id});
            system.debug('documentList> ' + documentList);
            if(!documentList.isEmpty()){
                for(Document__c doc : documentList){
                    if(doc.Document_Category__c  == SHF_ConstantsUtil.DOCUMENT_CATEGORY && doc.Status__c == SHF_ConstantsUtil.UPLOADED ){
                        isIncomeDocAvailable = true;
                        break;
                    }
                }
                if( !isIncomeDocAvailable && applicationDetail.Applied_Loan_Amount__c > = Decimal.valueOf(mdtMap.get(SHF_ConstantsUtil.INCOME_DOCUMENT_DEVIATION).get('loan_amount')) && primaryApplicant.Customer_Profile__c == SHF_ConstantsUtil.SELF_EMP_INFORMAL){
                        createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.INCOME_DOCUMENT_DEVIATION, primaryApplicant.Id );
                    }
            }
        }

    }
    
    //Deviation On Work Experience
    public void workExperienceDeviation(Application__c applicationDetail,  List<Loan_Applicant__c> applicantList,Product_Master__c childMasterRecord){
        if(applicationDetail != null && !applicantList.isEmpty() && childMasterRecord != null){
            for(Loan_Applicant__c applicant : applicantList){
                if(applicant.IsFinancial_Applicant__c == 'Yes'){
                    if(applicant.Total_Working_Experience__c < childMasterRecord.Minimum_Work_Experience__c){
                        createDeviationRecord(applicant.Application__c,SHF_ConstantsUtil.WORK_EXPERIENCE_DEVIATION, applicant.Id );
                    }
                }
            }
            
        }
    }
    
    //Minimum Tenure validation
    public void minimumTenureDeviation(Application__c applicationDetail,Product_Master__c childMasterRecord){
        if(applicationDetail != null && childMasterRecord != null){
            if(applicationDetail.Tenure__c != null && childMasterRecord.Minimum_Tenure_in_months__c !=null){
                if(applicationDetail.Tenure__c < childMasterRecord.Minimum_Tenure_in_months__c){
                    createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.MINIMUM_TENURE, null );
                }
            }
        }
    }
    
    //Minimum CRIF/CIBIL Score(Financial Higher Income Applicant)------need add income and crif_score field on product master then uncomment the code
    public void minimumCibilCrifDeviation(Application__c applicationDetail,Loan_Applicant__c higherIncomeContributor,Product_Master__c childMasterRecord, Map<String,E_Verification__c> applicantCrifMap, Map<String,E_Verification__c> applicantCibilMap){
        boolean isCibilCrif = false;
        if(applicationDetail != null && higherIncomeContributor != null &&   childMasterRecord != null){
            
            if(applicantCrifMap.containsKey(higherIncomeContributor.Id) && isNumber(childMasterRecord.Crif_Score__c) && applicantCrifMap.get(higherIncomeContributor.Id).score__c != null){
                if(decimal.valueOf(applicantCrifMap.get(higherIncomeContributor.Id).score__c) < Decimal.valueOf(childMasterRecord.Crif_Score__c)){
                    isCibilCrif = true;
                }
                
            } if(applicantCibilMap.containsKey(higherIncomeContributor.Id) && isNumber(childMasterRecord.Crif_Cibil_Score__c) && applicantCibilMap.get(higherIncomeContributor.Id).score__c != null){
                if(decimal.valueOf(applicantCibilMap.get(higherIncomeContributor.Id).score__c) < Decimal.valueOf(childMasterRecord.Crif_Cibil_Score__c)){
                    isCibilCrif = true;
                }
            }
            if(isCibilCrif){
                createDeviationRecord(applicationDetail.id,SHF_ConstantsUtil.MINIMUM_CRIF_CIBIL_SCORE, higherIncomeContributor.Id );
            }
        }
    }
    
    //IIR
    public void deviationForIIR(Application__c applicationDetail,Product_Master__c childMasterRecord){
        if(applicationDetail != null && childMasterRecord != null){
            if(childMasterRecord.IIR__c != null && applicationDetail.IIR__c != null){
                if(childMasterRecord.IIR__c < applicationDetail.IIR__c){
                    createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.IIR, null );
                }
            }
        }
    }
    
    //LVR/LCER
    public void deviationForLvrAndLcer(Application__c applicationDetail,Product_Master__c childMasterRecord){
        if(applicationDetail != null && childMasterRecord != null){
            if(childMasterRecord.LVR_LCER__c != null &&  applicationDetail.LVR__c != null){
                if(childMasterRecord.LVR_LCER__c < applicationDetail.LVR__c){
                    createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.LVR_LCER, null );
                }
            }
        }
    }
    
    //IAR
    public void deviationForIAR(Application__c applicationDetail,Product_Master__c childMasterRecord){
        if(applicationDetail != null && childMasterRecord != null){
            if(childMasterRecord.IAR__c != null && applicationDetail.IAR__c != null){
                if(childMasterRecord.IAR__c < applicationDetail.IAR__c){
                    createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.IAR, null );
                }
            }
        }
    }
    
    //Minimum Age-Co-Applicant
    public void minimumAgeCoApplicantDeviation(Application__c applicationDetail,List<Loan_Applicant__c> applicantList,Map<String,Map<String,String>> mdtMap,Product_Master__c childMasterRecord){
        if(applicationDetail != null && !applicantList.isEmpty() && childMasterRecord != null){
            for(Loan_Applicant__c applicant : applicantList){
                if(applicant.Applicant_Type__c == SHF_ConstantsUtil.CO_APPLICANT && childMasterRecord.Minimum_Co_Applicant_Age__c != null){
                    if(applicant.IsFinancial_Applicant__c == 'Yes'){
                        //age calculation
                        Date dob = applicant.Date_of_Birth__c != null ? applicant.Date_of_Birth__c : applicant.Date_Of_Incorporation1__c;
                        Decimal calculateDOB =  calculateExactAge(dob);
                        if(Decimal.valueOf(childMasterRecord.Minimum_Co_Applicant_Age__c) >= calculateDOB && calculateDOB >= Integer.valueOf(mdtMap.get(SHF_ConstantsUtil.MINIMUM_AGE_DEVIATION).get(SHF_ConstantsUtil.MINIMUM_APP_AGE))){
                            createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.MINIMUM_AGE_CO_APP, applicant.Id );
                        }
                    }
                    else {
                         if(applicant.Applicant_Age__c == Integer.valueOf(mdtMap.get(SHF_ConstantsUtil.MINIMUM_AGE_DEVIATION).get(SHF_ConstantsUtil.MINIMUM_APP_AGE))){
                            createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.MINIMUM_AGE_CO_APP, applicant.Id );
                        }
                     }

               
                }
            }
        }
    }
    
    //Maximum Age Property Owner(At Maturity)
    public void propertyOwnerMaxAgeDeviation(Application__c applicationDetail,List<Collateral__c> collateralList,Product_Master__c childMasterRecord){
        if(!collateralList.isEmpty() && !collateralList.isEmpty() && childMasterRecord != null){
           
            for(Collateral__c coll : collateralList){
                     //age calculation
                     system.debug('coll.Property_Owner__r>> ' + coll.Property_Owner__r);
                     if(coll.Property_Owner__r != null){
                        Date dob = coll.Property_Owner__r.Date_of_Birth__c != null ? coll.Property_Owner__r.Date_of_Birth__c : coll.Property_Owner__r.Date_Of_Incorporation1__c;
                    Decimal calculateDOB =  calculateExactAge(dob);
                    Decimal ageAtMaturity =(applicationDetail.Tenure__c/12) + calculateDOB ;
                    if(childMasterRecord.Maximum_Age_Property_Owner_At_Maturity__c != null){
                        if(childMasterRecord.Maximum_Age_Property_Owner_At_Maturity__c < ageAtMaturity){
                            createDeviationRecord(applicationDetail.Id,SHF_ConstantsUtil.MAXIMUM_AGE_PROPERTY_OWNER, coll.Property_Owner__c );
                            break; 
                        }
                    }
                     }                
            }
            
        }
    }
    
    
    //OGL-Property Address
    public void oglPropertyAddDeviation(Application__c applicationDetail ,List<Collateral__c> collateralList){
        system.debug('collateralList<  ' + collateralList);
        if(applicationDetail != null && !collateralList.isEmpty()){
            Branch_Master__c branch = [
                SELECT Id, branch_Location__latitude__s, branch_Location__longitude__s
                FROM Branch_Master__c
                WHERE Id = :applicationDetail.Branch__c
                LIMIT 1
            ];
            
            if (branch.branch_Location__latitude__s == null || branch.branch_Location__longitude__s == null) {
                System.debug('Branch location missing, cannot calculate distance');
                return;
            }
            // Step 2: Get distance threshold (from metadata)
            Double maxDistance = Double.valueOf(String.valueOf(
                mdtMap.get(SHF_ConstantsUtil.OGL_PROPERTY_ADDRESS).get('distance')
            ));
            // Step 3: Check all collaterals in Apex (no SOQL in loop)
            Boolean deviationNeeded = false;
            Double branchLat = branch.branch_Location__latitude__s;
            Double branchLon = branch.branch_Location__longitude__s;
            
            for (Collateral__c coll : collateralList) {
                if (coll.Property_Address__latitude__s == null || coll.Property_Address__longitude__s == null) {
                    continue; // skip if no geolocation
                }
                Double distance = calculateDistance(
                    branchLat, branchLon,
                    coll.Property_Address__latitude__s, coll.Property_Address__longitude__s
                );
                system.debug('distance > ' + distance);
                if (distance > maxDistance) {
                    deviationNeeded = true;
                    break;
                }
            }
            
            // Step 4: Create deviation only if needed
            if (deviationNeeded) {
                createDeviationRecord(applicationDetail.Id, SHF_ConstantsUtil.OGL_PROPERTY_ADDRESS, null);
            }
        }
    }
    
    /* //Rental Income
public Deviation_and_Sanction_Condition__c rentalIncomeDeviation(String applicationId){
Deviation_and_Sanction_Condition__c rentalIncomeDeviations = new Deviation_and_Sanction_Condition__c();
return rentalIncomeDeviations;
}*/
    
    /**
* Helper method to calculate distance in kilometers between two geo points
* using the Haversine formula
*/
    public static Double calculateDistance(Double lat1, Double lon1, Decimal lat2, Decimal lon2) {
        Double R = 6371.0; // Earth radius in km
        
        // Apex doesn't have Math.toRadians(), so convert manually:
        Double dLat = (lat2 - lat1) * Math.PI / 180;
        Double dLon = (lon2 - lon1) * Math.PI / 180;
        
        lat1 = lat1 * Math.PI / 180;
        lat2 = lat2 * Math.PI / 180;
        
        Double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1) * Math.cos(lat2) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        
        Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c; // distance in kilometers
    }
    
    public Void createDeviationRecord(String applicationId,String deviationName,String applicantId ){
        Deviation_Master__c dvRecord =  deviationMasterMap.get(deviationName);
        if(dvRecord != null){
        Deviation_and_Sanction_Condition__c createdDeviaiton = new Deviation_and_Sanction_Condition__c();
        createdDeviaiton.Decision__c = SHF_ConstantsUtil.PENDING;
        createdDeviaiton.Deviation_Description__c = dvRecord.Deviation_Description__c;
        createdDeviaiton.Deviations__c = dvRecord.Id;
         createdDeviaiton.External_Key__c = dvRecord.Deviation__c;
        createdDeviaiton.Is_Delete__c = false;
         createdDeviaiton.Mitigants__c = null;
        createdDeviaiton.Loan_Application__c = applicationId;
        createdDeviaiton.Type__c = SHF_ConstantsUtil.DEVIATION;
        createdDeviaiton.Loan_Applicant__c = applicantId;
        createdDeviaiton.Approving_Authority__c = configureApprovingAuth(dvRecord.Approving_Authority__c);
        deviationList.add(createdDeviaiton);
    }
    }
    public String configureApprovingAuth(String authName){
        if(String.isNotBlank(authName)){
            if(authName =='ACM' ){
                return SHF_ConstantsUtil.ACM;
            }else if(authName =='ZCM'){
                return SHF_ConstantsUtil.ZCM;
            }else if(authName =='RCM'){
                return SHF_ConstantsUtil.RCM;
            }else if(authName =='BCM'){
                return SHF_ConstantsUtil.BCM;
            }else if(authName =='HCS'){
                return SHF_ConstantsUtil.HCS;
            }else if(authName =='SH'){
                return SHF_ConstantsUtil.SH;
            }else if(authName =='RTM'){
                return SHF_ConstantsUtil.RTM;
            }else if(authName =='CM'){
                return SHF_ConstantsUtil.CM;
            }
        }
        return '';
    }
    public Product_Master__c getChildProductRecord(String productId, String customerProfile){
        if(productId != null && customerProfile != null){
            List<Product_Master__c> productList = new SHF_ProductMasterSelector().selectParentId(productId);
            if(!productList.isEmpty()){
                for(Product_Master__c product : productList){
                    if(product.Customer_Profile__c.contains(customerProfile)){
                        return product;
                    }
                }
            }
        }
        return null;
    } 
    
    @AuraEnabled
    public static String executeBRE(Id applicationId) {
        String msg = '';
        try {
            SHF_BusinessRuleEngine bre = new SHF_BusinessRuleEngine();
            msg = bre.createDeviationAndSanctionCondition(applicationId);
        } catch(Exception ex){
            system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
            msg = 'error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber();
        }
        return msg;
    }
    public static Boolean isNumber(String value) {
        if (String.isBlank(value)) return false;
        try {
            Decimal.valueOf(value.trim());
            return true;
        } catch (Exception e) {
            return false;
        }
    }
    

    public static Decimal calculateExactAge(Date dob) {
        if (dob == null) {
            return null;
        }

        Date today = Date.today();

        Integer years = today.year() - dob.year();
        Integer months = today.month() - dob.month();
        Integer days = today.day() - dob.day();

        /* Adjust days */
        if (days < 0) {
            months--;
            Date prevMonth = today.addMonths(-1);
            days += Date.daysInMonth(prevMonth.year(), prevMonth.month());
        }

        /* Adjust months */
        if (months < 0) {
            years--;
            months += 12;
        }

        /* Final age calculation */
        Decimal age =
            years
            + (Decimal.valueOf(months) / 12)
            + (Decimal.valueOf(days) / 365);

        return age.setScale(6); // precision as needed
    }


    
}