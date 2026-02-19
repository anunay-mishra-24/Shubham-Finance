/**
* @File Name : SHF_RiskCalculation.cls
* @Description :
* @Author : Mansur
* @Last Modified By :
* @Last Modified On : October 23, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 23, 2025 |   | Initial Version
**/

public class SHF_RiskCalculation {
    Public static  Map<String,String> IndustryApplicantMap = new  Map<String,String>();
    @AuraEnabled
    public static String loadRiskData(Id applicationId) {
        List<Application__c>	applicationData = new list<Application__c>();
        Map<Id,Personal_Discussion__c> applicantwithCredtiPdMap = new Map<Id,Personal_Discussion__c>();
        Map<Id,Decimal> creditPdAndLoanAppMap = new Map<Id,Decimal>();
        List<String> applicantsForAge = new List<String>();
        List<String> applicantsForRelationship = new List<String>();
        List<String> applicantsForProfile = new List<String>();
        List<String> applicantsForIndustry = new List<String>();
        List<String> applicantsForCreditPd = new List<String>();
        List<String> errorMessages = new List<String>();
        Set<Id> applicantIdSet = new Set<Id>();
        Set<Id> applicantIdSetForEmployer = new Set<Id>();
        list<Loan_Applicant__c> applicantList = new List<Loan_Applicant__c>();
        Set<Id> crifVerificationId = new Set<Id>();
        
        try {
            // system.debug('applicationId>> ' + applicationId);
            if(applicationId != null){
                applicationData = new 	SHF_ApplicationSelector().getAllRelatedDataOfApplication(new Set<Id>{applicationId});
                
                
                if(!applicationData.isEmpty()){
                    if(!applicationData[0].Loan_Applicants__r.isEmpty()){
                        for(Loan_Applicant__c applicant : applicationData[0].Loan_Applicants__r){
                            if(applicant.IsDeleted__c == false){
                                 applicantIdSetForEmployer.add(applicant.Id);
                                if(applicant.Customer_Profile__c != SHF_ConstantsUtil.FORMAL_SALARIED && applicant.IsFinancial_Applicant__c == 'Yes'){
                                    applicantIdSet.add(applicant.Id);
                                    applicantList.add(applicant);
                                }
                                if(applicant.RecordType_Name__c == SHF_ConstantsUtil.INDIVIDUAL && applicant.CRIF_Verification__c != null){
                                    crifVerificationId.add(applicant.CRIF_Verification__c);
                                }
                                
                                if(applicant.Applicant_Age__c == null){
                                    applicantsForAge.add(applicant.Name);
                                }if(applicant.Relationship_with_Applicant__c == null){
                                    applicantsForRelationship.add(applicant.Name);
                                }if(applicant.Customer_Profile__c == null){
                                    applicantsForProfile.add(applicant.Name);
                                }
                            }
                        }
                        //getting employed details
                        system.debug('applicantIdSetForEmployer > ' + applicantIdSetForEmployer);
                        if(!applicantIdSetForEmployer.isEmpty()){
                           List<Employment__c> EmployerDetail  = new SHF_EmployerSelector().selectByApplicantsId(applicantIdSetForEmployer);
                           system.debug('EmployerDetail > ' + EmployerDetail);
                           if(!EmployerDetail.isEmpty()){
                                for(Employment__c emp : EmployerDetail){
                                    if(emp.Industry__c == null ){
                                        applicantsForIndustry.add(emp.Loan_Applicant__r.Name);
                                    }else{
                                        IndustryApplicantMap.put(emp.Loan_Applicant__c,emp.Industry__c);
                                    }
                                }
                           }
                        }
                        if(!applicantsForAge.isEmpty() ){
                            errorMessages.add('Age of '+String.join(applicantsForAge, ' , ') +' is Required');
                        }if(!applicantsForRelationship.isEmpty() ){
                            errorMessages.add('Relationship with Applicant of '+String.join(applicantsForRelationship, ' , ') +' is Required');
                        }
                        if(!applicantsForProfile.isEmpty() ){
                            errorMessages.add('Customer Profile of '+String.join(applicantsForProfile, ' , ') +' is Required');
                        }
                        if(!applicantsForIndustry.isEmpty() ){
                            errorMessages.add('Industry of '+String.join(applicantsForIndustry, ' , ') +' is Required');
                        }
                        
                        
                    }
                    if(applicationData[0].Branch__r == null){
                        errorMessages.add('Branch Name is Required for All Applicants');
                    }
                    if(applicationData[0].Product__r == null){
                        errorMessages.add('Product Name is Required for All Applicants');
                    }
                    if(applicationData[0].Lead__r.Lead_Sub_Source__c == null){
                        errorMessages.add('Lead Sub-Source is Required for All Applicants');
                    }
                    
                }
                
            }
            if(!applicantIdSet.isEmpty()){
                List<Personal_Discussion__c> pdRecords = new Shf_PD_Selector().selectPdByLoanApplicantId(applicantIdSet);
                if(!pdRecords.isEmpty()){
                    for(Personal_Discussion__c pd : pdRecords){
                        
                        if(pd.Credit_PD_Mode__c == SHF_ConstantsUtil.CREDIT_PD){
                            applicantwithCredtiPdMap.put(pd.Loan_Applicant__c,pd);
                        }
                    }
                }else{//need to uncomment this after PD development
                   // errorMessages.add('Create Credit PD for all Financial Applicants'); 
                    
                    
                }
                if(applicantwithCredtiPdMap != null && !applicantwithCredtiPdMap.isEmpty() &&  !applicantList.isEmpty()){
                    for(Loan_Applicant__c applicant : applicantList){
                        if(applicant.Customer_Profile__c != SHF_ConstantsUtil.FORMAL_SALARIED && applicant.IsFinancial_Applicant__c == 'Yes' ){
                            // system.debug('applicantwithCredtiPdMap.get(applicant.Id)> '+ applicantwithCredtiPdMap.get(applicant.Id));
                            if(applicantwithCredtiPdMap.get(applicant.Id) == null){
                                applicantsForCreditPd.add(applicant.First_Name__c +' '+ applicant.Last_Name__c);
                            }else{
                                creditPdAndLoanAppMap.put(applicant.Id,applicantwithCredtiPdMap.get(applicant.Id).Total_Expences__c);
                            }
                        }
                    }
                    if(!applicantsForCreditPd.isEmpty() ){ //need to uncomment this after PD development
                        errorMessages.add('Credit PD of '+String.join(applicantsForCreditPd, ' , ') +' is Required');
                    }
                }
            }
            
        }catch(exception ex){
            system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
            return 'ERROR :' + ex.getMessage()+' Line:- '+ ex.getlineNumber();
            
        }
        system.debug('errorMessages> ' + errorMessages);
        if(!errorMessages.isEmpty()){
            return 'ERROR: ' +String.join(errorMessages, '\n');
        }else{
            return SHF_RiskCalculation.calculateRisk(applicationId, applicationData, creditPdAndLoanAppMap, crifVerificationId);
        }
    }
    
    public static String calculateRisk(String applicationId, List<Application__c>	applicationData, Map<Id,Decimal> creditPdAndLoanAppMap, Set<Id> crifVerificationId ){
        Map<String,List<Risk_Score_Details__c>> keyAndRiskDetailMap = new Map<String,List<Risk_Score_Details__c>>();
        String total_Expences = '';
        Map<String,Decimal> thikWeightMasterMap = new  Map<String,Decimal>();
        Map<String,Decimal> thinWeightMasterMap = new  Map<String,Decimal>();
        Map<String,E_Verification__c> applicantCrifVerificationMap = new Map<String,E_Verification__c>();
        Decimal totalThinValue = 0.00;
        Decimal totalThikValue = 0.00;
        Decimal finalValue = 0.00;
        Decimal avrThik = 0.00;
        Decimal avrThin = 0.00;
        Integer totalValidApplicant = 0;
        List <Risk_Score_Master__c> riskMasterDataList =new SHF_riskScoreMasterSelector().getAllRelatedDataOfChild();
        
        try{
            if(!riskMasterDataList.isEmpty() && riskMasterDataList.size() > 0 ){
                for(Risk_Score_Master__c riskMaster : riskMasterDataList){
                    
                    if(riskMaster.Thik_Weight__c != null){ //check thik weight of master is not null
                        thikWeightMasterMap.put(riskMaster.Name,riskMaster.Thik_Weight__c) ;
                        if(riskMaster.Risks_Score_Details__r.size() > 0){
                            for(Risk_Score_Details__c riskDetail : riskMaster.Risks_Score_Details__r){
                                // system.debug('riskDetail.Effective_Date__c '+ riskDetail.Effective_Date__c);
                                //system.debug('today '+ System.Today());
                                 
                                
                                if(riskDetail.Weight_Type__c == SHF_ConstantsUtil.THIK && riskDetail.Effective_Date__c <= System.Today() && riskDetail.IsActive__c == true){
                                    if (!keyAndRiskDetailMap.containsKey(riskMaster.Name)) {
                                        keyAndRiskDetailMap.put(riskMaster.Name, new List<SObject>());
                                    }
                                    keyAndRiskDetailMap.get(riskMaster.Name).add(riskDetail);
                                }
                            }
                        }
                        
                    }if(riskMaster.Thin_Weight__c != null){//check thin weight of master is not null
                        thinWeightMasterMap.put(riskMaster.Name,riskMaster.Thin_Weight__c) ;
                        if(riskMaster.Risks_Score_Details__r.size() > 0){
                            for(Risk_Score_Details__c riskDetail : riskMaster.Risks_Score_Details__r){
                                if(riskDetail.Weight_Type__c == SHF_ConstantsUtil.THIN && riskDetail.Effective_Date__c <= System.Today() && riskDetail.IsActive__c == true){
                                    if (!keyAndRiskDetailMap.containsKey(riskMaster.Name)) {
                                        keyAndRiskDetailMap.put(riskMaster.Name, new List<SObject>());
                                    }
                                    keyAndRiskDetailMap.get(riskMaster.Name).add(riskDetail);
                                     
                                }
                            }
                        }
                    }
                    
                }
                System.debug('Size of mppp >> ' +  keyAndRiskDetailMap.get('Relationship with Applicant').size());
            }
            
            if(!crifVerificationId.isEmpty() && crifVerificationId.size() > 0){
                List<E_Verification__c> crifVerificationRecord =   new SHF_E_VerificationSelector().selectByrecordId(crifVerificationId);
                if(!crifVerificationRecord.isEmpty() && crifVerificationRecord.size() > 0){
                    for(E_Verification__c verification : crifVerificationRecord){
                        applicantCrifVerificationMap.put(verification.Loan_Applicant__c,verification);
                    }
                }
                
            }
            if(!applicationData.isEmpty()){
                if(!applicationData[0].Loan_Applicants__r.isEmpty()){
                    system.debug('applicant size> ' + applicationData[0].Loan_Applicants__r.size());
                    
                    for(Loan_Applicant__c applicant : applicationData[0].Loan_Applicants__r){
                        if(applicant.IsDeleted__c == false){
                            totalThinValue = 0.00;
                            totalThikValue = 0.00;
                            if(!keyAndRiskDetailMap.isEmpty()){
                                if(!creditPdAndLoanAppMap.isEmpty()){
                                    total_Expences = String.valueOf(creditPdAndLoanAppMap.get(applicant.Id));
                                }
                                //total expences 
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('Total Annual Expenses')) {
                                    if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                        //(' input ' + String.valueOf(total_Expences) +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        system.debug('total_Expences> ' + total_Expences );
                                        Boolean operator = evaluateOperator((total_Expences != '' && total_Expences != null) ? String.valueOf(total_Expences) : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ String.valueOf(total_Expences) + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('total exp  thin 1 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            system.debug('total exp thin 2 '+ totalThinValue);
                                        }
                                    }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                        // System.debug(' input ' + String.valueOf(total_Expences) +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator((total_Expences != '' && total_Expences != null) ? String.valueOf(total_Expences) : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);                                if(operator){
                                            totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ String.valueOf(total_Expences) + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('total exp thick 1 '+ totalThikValue);
                                            system.debug('total exp thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            
                                            
                                        }
                                    }
                                }                                
                                // Branch
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('Branch')) {
                                    if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                        
                                        // System.debug(' input ' + applicationData[0].Branch__r.Name +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator(applicationData[0].Branch__r.Name,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            
                                            totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ applicationData[0].Branch__r.Name + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Branch thin 1 '+ totalThinValue);
                                            system.debug('Branch thick 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                        // System.debug(' input ' + applicationData[0].Branch__r.Name +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator(applicationData[0].Branch__r.Name,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ applicationData[0].Branch__r.Name + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Branch thick 1 '+ totalThikValue);
                                            system.debug('Branch thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }
                                } 
                                // Product
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('Product')) {
                                    // system.debug('product detil >> ' + riskDetailReocrd);
                                    String subProduct_Program = applicationData[0].Product__r.Sub_Product__c+'-'+applicationData[0].Product__r.Name;
                                    if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                        // System.debug(' input ' + applicationData[0].Product__r.Name +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator(subProduct_Program,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ subProduct_Program + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Product thin 1 '+ totalThinValue);
                                            system.debug('Product thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                        // System.debug(' input ' + applicationData[0].Product__r.Name +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator(subProduct_Program,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ subProduct_Program + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Product thick 1 '+ totalThikValue);
                                            system.debug('Product thick 2 '+  thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }
                                }
                                // Analytical Channel
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('Analytical Channel')) {
                                    if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                        // System.debug(' input ' + applicationData[0].Lead__r.Lead_Sub_Source__c +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator(applicationData[0].Lead__r.Lead_Sub_Source__c,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        
                                        if(operator){
                                            totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ applicationData[0].Lead__r.Lead_Sub_Source__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Analytical Channel thin 1 '+ totalThinValue);
                                            system.debug('Analytical Channel thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                        // System.debug(' input ' + applicationData[0].Lead__r.Lead_Sub_Source__c +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator(applicationData[0].Lead__r.Lead_Sub_Source__c,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ applicationData[0].Lead__r.Lead_Sub_Source__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Analytical Channel thick 1 '+ totalThikValue);
                                            system.debug('Analytical Channel thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }
                                }
                                // Age
                                // system.debug('keyAndRiskDetailMapAge > ' +keyAndRiskDetailMap.get('Age').size());
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('Age')) {
                                    if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                        Boolean operator = evaluateOperator(String.valueOf(applicant.Applicant_Age__c),  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ applicant.Applicant_Age__c +'applicant name> '+ applicant.Name + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Age thin 1 '+ totalThinValue);
                                            system.debug('Age thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            
                                        }
                                    }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                        // System.debug(' input ' + String.valueOf(applicant.Applicant_Age__c) +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator(String.valueOf(applicant.Applicant_Age__c),  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ applicant.Applicant_Age__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Age thick 1 '+ totalThikValue);
                                            system.debug('Age thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }
                                }
                                // Customer profile
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('Employment_and_document_type')) {
                                    if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                        //   System.debug(' input ' + applicant.Customer_Profile__c +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator(applicant.Customer_Profile__c,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ applicant.Customer_Profile__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('ustomer profile thin 1 '+ totalThinValue);
                                            system.debug('ustomer profile thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                        //  System.debug(' input ' + applicant.Customer_Profile__c +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator(applicant.Customer_Profile__c,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ applicant.Customer_Profile__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('ustomer profile thick 1 '+ totalThikValue);
                                            system.debug('ustomer profile thick 2 '+  thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }
                                }
                                // Final_Industry
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('Final_Industry')) {
                                    if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN && IndustryApplicantMap.containsKey(applicant.Id)){
                                        //  System.debug(' input ' + IndustryApplicantMap.get(applicant.Id) +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator(IndustryApplicantMap.get(applicant.Id),  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ IndustryApplicantMap.get(applicant.Id) + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Final_Industry thin 1 '+ totalThinValue);
                                            system.debug('Final_Industry thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK && IndustryApplicantMap.containsKey(applicant.Id)){
                                        //  System.debug(' input ' + IndustryApplicantMap.get(applicant.Id)+' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator(IndustryApplicantMap.get(applicant.Id),  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ IndustryApplicantMap.get(applicant.Id) + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Final_Industry thick 1 '+ totalThikValue);
                                            system.debug('Final_Industry thick2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }
                                }
                                // Relationship with Applicant
                                 System.debug('Size of mppp >> ' +  keyAndRiskDetailMap.get('Relationship with Applicant').size());
                                system.debug('relation shipp ? ' +  keyAndRiskDetailMap.get('Relationship with Applicant'));
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('Relationship with Applicant')) {
                                    if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                        // System.debug(' input ' + applicant.Relationship_with_Applicant__c +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator((applicant.Relationship_with_Applicant__c != null && applicant.Relationship_with_Applicant__c != '') ? applicant.Relationship_with_Applicant__c :  SHF_ConstantsUtil.MISSING ,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                        if(operator){
                                            totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                           
                                            system.debug('value-> '+ applicant.Relationship_with_Applicant__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Relationship with Applicant thin 1 '+ totalThinValue);
                                            system.debug('Relationship with Applicant thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                        //System.debug(' input ' + applicant.Relationship_with_Applicant__c +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                        Boolean operator = evaluateOperator((applicant.Relationship_with_Applicant__c != null && applicant.Relationship_with_Applicant__c != '') ? applicant.Relationship_with_Applicant__c :  SHF_ConstantsUtil.MISSING ,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);                                if(operator){
                                            totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                            system.debug('value-> '+ applicant.Relationship_with_Applicant__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Relationship with Applicant thick 1 '+ totalThikValue);
                                            system.debug('Relationship with Applicant thick2 '+  thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                        }
                                    }
                                }
                                /******************************CRIF PART Start******************************************/
                                
                                // Maximum DPD in CRIF for last 15 months
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('CRF_DPD_L15M_max_max_ma')) {
                                    if(!applicantCrifVerificationMap.isEmpty() && applicantCrifVerificationMap.containsKey(applicant.Id)){
                                        
                                        if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Maximum_DPD_in_CRIF_for_last_15_months__c != null && applicantCrifVerificationMap.get(applicant.Id).Maximum_DPD_in_CRIF_for_last_15_months__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Maximum_DPD_in_CRIF_for_last_15_months__c :  SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                            if(operator){
                                                totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Maximum_DPD_in_CRIF_for_last_15_months__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Maximum DPD thin 1 '+ totalThinValue);
                                            system.debug('Maximum DPD thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                            System.debug(' input ' + applicantCrifVerificationMap.get(applicant.Id).Maximum_DPD_in_CRIF_for_last_15_months__c +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Maximum_DPD_in_CRIF_for_last_15_months__c != null && applicantCrifVerificationMap.get(applicant.Id).Maximum_DPD_in_CRIF_for_last_15_months__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Maximum_DPD_in_CRIF_for_last_15_months__c :  SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);                                if(operator){
                                                totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Maximum_DPD_in_CRIF_for_last_15_months__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Maximum DPD thick 1 '+ totalThikValue);
                                            system.debug('Maximum DPD thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }
                                    }
                                }
                                
                                // Number_of_enquires by Main applicant
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('Number_of_enquiries_ma')) {
                                    if(!applicantCrifVerificationMap.isEmpty() && applicantCrifVerificationMap.containsKey(applicant.Id)){
                                        
                                        if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Number_of_enquires_by_Main_applicant__c != null && applicantCrifVerificationMap.get(applicant.Id).Number_of_enquires_by_Main_applicant__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Number_of_enquires_by_Main_applicant__c :  SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                            if(operator){
                                                totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Number_of_enquires_by_Main_applicant__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Number_of_enquires thin 1 '+ totalThinValue);
                                            system.debug('Number_of_enquires thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Number_of_enquires_by_Main_applicant__c != null && applicantCrifVerificationMap.get(applicant.Id).Number_of_enquires_by_Main_applicant__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Number_of_enquires_by_Main_applicant__c :  SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);                                if(operator){
                                                totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                             system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Number_of_enquires_by_Main_applicant__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Number_of_enquires thick 1 '+ totalThikValue);
                                            system.debug('Number_of_enquires thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }
                                    }
                                }
                                // Total CRD Tradelines in Last 12 Months
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('CRF_NumTrd_ALL_CRD_L12M_sum_ma')) {
                                    if(!applicantCrifVerificationMap.isEmpty() && applicantCrifVerificationMap.containsKey(applicant.Id)){
                                        
                                        if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Total_CRD_Tradelines_in_Last_12_Months__c != null && applicantCrifVerificationMap.get(applicant.Id).Total_CRD_Tradelines_in_Last_12_Months__c !='') ? applicantCrifVerificationMap.get(applicant.Id).Total_CRD_Tradelines_in_Last_12_Months__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                            if(operator){
                                                totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Total_CRD_Tradelines_in_Last_12_Months__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Total CRD  thin 1 '+ totalThinValue);
                                            system.debug('Total CRD  thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Total_CRD_Tradelines_in_Last_12_Months__c != null && applicantCrifVerificationMap.get(applicant.Id).Total_CRD_Tradelines_in_Last_12_Months__c !='') ? applicantCrifVerificationMap.get(applicant.Id).Total_CRD_Tradelines_in_Last_12_Months__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);                                if(operator){
                                                totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Total_CRD_Tradelines_in_Last_12_Months__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Total CRD  thick 1 '+ totalThikValue);
                                            system.debug('Total CRD  thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }
                                    }
                                }
                                // Average Current balance in last 18 months
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('CRF_TotalCurBal_ALL_L18M_mean_ma')) {
                                    if(!applicantCrifVerificationMap.isEmpty() && applicantCrifVerificationMap.containsKey(applicant.Id)){
                                        
                                        if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Average_Current_balance_in_last_18_month__c != null && applicantCrifVerificationMap.get(applicant.Id).Average_Current_balance_in_last_18_month__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Average_Current_balance_in_last_18_month__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                            if(operator){
                                                totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Average_Current_balance_in_last_18_month__c+ ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Current balance thin 1 '+ totalThinValue);
                                            system.debug('Current balance thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Average_Current_balance_in_last_18_month__c != null && applicantCrifVerificationMap.get(applicant.Id).Average_Current_balance_in_last_18_month__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Average_Current_balance_in_last_18_month__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);                                if(operator){
                                                totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Average_Current_balance_in_last_18_month__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Current balance thick 1 '+ totalThikValue);
                                            system.debug('Current balance thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }
                                    }
                                }
                                // Average utilization for NBF in last 24 months
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('CRF_Utilization_NBF_L24M_mean_ma')) {
                                    if(!applicantCrifVerificationMap.isEmpty() && applicantCrifVerificationMap.containsKey(applicant.Id)){
                                        
                                        if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Average_utilization_for_NBF_in_last_24_m__c != null && applicantCrifVerificationMap.get(applicant.Id).Average_utilization_for_NBF_in_last_24_m__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Average_utilization_for_NBF_in_last_24_m__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                            if(operator){
                                                totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Average_utilization_for_NBF_in_last_24_m__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('utilization for NBF thin 1 '+ totalThinValue);
                                            system.debug('utilization for NBF thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Average_utilization_for_NBF_in_last_24_m__c != null && applicantCrifVerificationMap.get(applicant.Id).Average_utilization_for_NBF_in_last_24_m__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Average_utilization_for_NBF_in_last_24_m__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);                                if(operator){
                                                totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Average_utilization_for_NBF_in_last_24_m__c+ ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('utilization for NBF thick 1 '+ totalThikValue);
                                            system.debug('utilization for NBF thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }
                                    }
                                }
                                // Total PLN Tradelines in last 6 months
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('CRF_NumTrd_ALL_PLN_L6M_sum_ma')) {
                                    if(!applicantCrifVerificationMap.isEmpty() && applicantCrifVerificationMap.containsKey(applicant.Id)){
                                        
                                        if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Total_PLN_Tradelines_in_last_6_months__c != null && applicantCrifVerificationMap.get(applicant.Id).Total_PLN_Tradelines_in_last_6_months__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Total_PLN_Tradelines_in_last_6_months__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                            if(operator){
                                                totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Total_PLN_Tradelines_in_last_6_months__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('PLN Tradelines thin 1 '+ totalThinValue);
                                            system.debug('PLN Tradelines thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Total_PLN_Tradelines_in_last_6_months__c != null && applicantCrifVerificationMap.get(applicant.Id).Total_PLN_Tradelines_in_last_6_months__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Total_PLN_Tradelines_in_last_6_months__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);                                if(operator){
                                                totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Total_PLN_Tradelines_in_last_6_months__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('PLN Tradelines thick 1 '+ totalThikValue);
                                            system.debug('PLN Tradelines thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }
                                    }
                                }
                                // Main applicant's credit score
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('Main_applicant_s_credit_score')) {
                                    if(!applicantCrifVerificationMap.isEmpty() && applicantCrifVerificationMap.containsKey(applicant.Id)){
                                        
                                        if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Main_applicant_s_credit_score__c != null && applicantCrifVerificationMap.get(applicant.Id).Main_applicant_s_credit_score__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Main_applicant_s_credit_score__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                            if(operator){
                                                totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Main_applicant_s_credit_score__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Main applicant thin 1 '+ totalThinValue);
                                            system.debug('Main applicant thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Main_applicant_s_credit_score__c != null && applicantCrifVerificationMap.get(applicant.Id).Main_applicant_s_credit_score__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Main_applicant_s_credit_score__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);                                if(operator){
                                                totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Main_applicant_s_credit_score__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('Main applicant thick 1 '+ totalThikValue);
                                            system.debug('Main applicant thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }
                                    }
                                }
                                // Primary number of Accounts
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('Primary number of Accounts')) {
                                    if(!applicantCrifVerificationMap.isEmpty() && applicantCrifVerificationMap.containsKey(applicant.Id)){
                                        
                                        if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Primary_number_of_Accounts__c != null && applicantCrifVerificationMap.get(applicant.Id).Primary_number_of_Accounts__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Primary_number_of_Accounts__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                            if(operator){
                                                totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Primary_number_of_Accounts__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('number of Accounts thin 1 '+ totalThinValue);
                                            system.debug('number of Accounts thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                                                                        System.debug(' input ' + applicantCrifVerificationMap.get(applicant.Id).Primary_number_of_Accounts__c +' Operator__c '+riskDetailReocrd.Operator__c + ' bin1 ' + riskDetailReocrd.Bin__c + ' bin2 '+  riskDetailReocrd.Bin2__c);

                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).Primary_number_of_Accounts__c != null && applicantCrifVerificationMap.get(applicant.Id).Primary_number_of_Accounts__c != '') ? applicantCrifVerificationMap.get(applicant.Id).Primary_number_of_Accounts__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);  
                                            if(operator){
                                                totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).Primary_number_of_Accounts__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('number of Accounts thick 1 '+ totalThikValue);
                                            system.debug('number of Accounts thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }
                                    }
                                }
                                // New Accounts in last six months
                                for (Risk_Score_Details__c riskDetailReocrd : keyAndRiskDetailMap.get('New Accounts in last six months')) {
                                    if(!applicantCrifVerificationMap.isEmpty() && applicantCrifVerificationMap.containsKey(applicant.Id)){
                                        
                                        if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIN){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).New_Accounts_in_last_six_months__c != null && applicantCrifVerificationMap.get(applicant.Id).New_Accounts_in_last_six_months__c != '') ? applicantCrifVerificationMap.get(applicant.Id).New_Accounts_in_last_six_months__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);
                                            if(operator){
                                                totalThinValue +=   thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).New_Accounts_in_last_six_months__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('New Accounts thin 1 '+ totalThinValue);
                                            system.debug('New Accounts thin 2 '+ thinWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }else if(riskDetailReocrd.Weight_Type__c == SHF_ConstantsUtil.THIK){
                                            Boolean operator = evaluateOperator((applicantCrifVerificationMap.get(applicant.Id).New_Accounts_in_last_six_months__c != null && applicantCrifVerificationMap.get(applicant.Id).New_Accounts_in_last_six_months__c != '') ? applicantCrifVerificationMap.get(applicant.Id).New_Accounts_in_last_six_months__c : SHF_ConstantsUtil.MISSING,  riskDetailReocrd.Operator__c, riskDetailReocrd.Bin__c, riskDetailReocrd.Bin2__c);                                if(operator){
                                                totalThikValue +=   thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100);
                                                 system.debug('value-> '+ applicantCrifVerificationMap.get(applicant.Id).New_Accounts_in_last_six_months__c + ' master weight ' +riskDetailReocrd.Risk_Score_Master_Name__c+ ' woe ' + riskDetailReocrd.Scaled_WOE__c);
                                            system.debug('New Accounts thick 1 '+ totalThikValue);
                                            system.debug('New Accounts thick 2 '+ thikWeightMasterMap.get(riskDetailReocrd.Risk_Score_Master_Name__c) * (riskDetailReocrd.Scaled_WOE__c/100));
                                            }
                                        }
                                    }
                                }
                                
                                
                                
                                //update loan applicant with calculated value
                                system.debug('totalThikValue > ' + totalThikValue);
                                system.debug('totalThinValue > ' + totalThinValue);
                                applicant.Risk_Score_Thin_Weight__c =   totalThinValue;
                                applicant.Risk_Score_Thik_Weight__c =   totalThikValue;
                                update applicant;
                            }
                        }
                    }
                    for(Loan_Applicant__c app : applicationData[0].Loan_Applicants__r){
                        if(app.IsDeleted__c == false){
                            totalValidApplicant = totalValidApplicant + 1;
                            avrThin += app.Risk_Score_Thin_Weight__c;
                            avrThik += app.Risk_Score_Thik_Weight__c;
                        }
                    }
                   // applicationData[0].Risk_Score_Thin_Weight__c =avrThin / totalValidApplicant  ;
                   // applicationData[0].Risk_Score_Thik_Weight__c =avrThik / totalValidApplicant ;
                   // update applicationData[0];
                }
            }
            
        }catch(exception ex){
            system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
            return 'ERROR : ' + ex.getMessage()+' Line:- '+ ex.getlineNumber();
        }
        return 'Success';
    }
    
    public static Boolean evaluateOperator( String inputValue, String operator, String binValue1, String binValue2) {
        Boolean result = false;
        
        if (operator == null) {
            System.debug(' Operator is null');
            return false;
        }
        if(inputValue == SHF_ConstantsUtil.MISSING && binValue1 == SHF_ConstantsUtil.MISSING) {
            return true;
        }else if(inputValue == SHF_ConstantsUtil.MISSING ){
            return false;
        }
        else{
            switch on operator.toLowerCase() {
                when '<'  { result = Decimal.valueOf(inputValue) < Decimal.valueOf(binValue1) ; }
                when '<=' { result = Decimal.valueOf(inputValue) <= Decimal.valueOf(binValue1); }
                when '>'  { result = Decimal.valueOf(inputValue) > Decimal.valueOf(binValue1); }
                when '>=' { result = Decimal.valueOf(inputValue) >= Decimal.valueOf(binValue1); }
                when '='  { result = inputValue.toLowerCase()  == binValue1.toLowerCase(); }
                when '!=' { result = Decimal.valueOf(inputValue) != Decimal.valueOf(binValue1); }
                
                //  Handle BETWEEN logic
                when 'between' {
                    if (binValue2 == null) {
                        System.debug(' Missing Bin2 value for BETWEEN operator');
                        result = false;
                    } else {
                        result = Decimal.valueOf(inputValue) >= Decimal.valueOf(binValue1) && Decimal.valueOf(inputValue) <= Decimal.valueOf(binValue2);
                    }
                }
                
                when else {
                    System.debug(' Unknown operator: ' + operator);
                }
            }
        }
        return result;
    }
    
}