/**
* @File Name : SHF_CommitteeApprovalController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 26, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 26, 2025 |   | Initial Version
**/

public without sharing class SHF_CommitteeApprovalController {
    @AuraEnabled
    public static String updateCommitteeApprovalTask(String action, String actHistoryId, String comment){
        String msg = '';
        try{
            if(action != null && actHistoryId != null){
                Activity_History__c act = new Activity_History__c();
                act.id = actHistoryId;
                act.Comments__c  = comment;
                act.Committee_Approval_Status__c = action == 'Approve' ? SHF_ConstantsUtil.APPROVED :SHF_ConstantsUtil.REJECTED;
                update act;
                msg = 'Success';
            }
        }catch(exception ex){
            system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
            msg = 'error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber();
        }
        return msg;
    }
    
    @AuraEnabled
    public static String committeeApprovalCheck(String applicationId,String recordId){
        String msg = '';
        try{
            if(applicationId != null){
                Application__c applicationDetail = new SHF_ApplicationSelector().selectApplicationForCIBIL(applicationId);
                if(applicationDetail != null && applicationDetail.Final_Committee_Approval_Status__c == SHF_ConstantsUtil.PENDING ){
                    String committeeStatus = checkApprovalOrRejection(applicationId);
                    system.debug('committeeStatus > ' +committeeStatus);
                    if(committeeStatus != SHF_ConstantsUtil.PENDING ){
                        Application__c app = new Application__c();
                        app.id = applicationId;
                        app.Final_Committee_Approval_Status__c  = committeeStatus;
                        app.CAM_Generation_Date_Time__c = null;
                        if(applicationDetail.Previous_Credit_User__c != null){
                            app.OwnerId  = applicationDetail.Previous_Credit_User__c;
                        }
                        // if(committeeStatus == SHF_ConstantsUtil.REJECTED){
                        //     app.Application_Status__c = committeeStatus;
                        //     app.Application_Rejected_By__c = applicationDetail.Previous_Credit_User__c != null ? applicationDetail.Previous_Credit_User__c : null;
                        // }
                        update app;
                    }
                }
                 msg = 'Success';
            }
        }catch(exception ex){
            system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
            msg = 'error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber();
        }
        return msg;
    }
    
    public static String checkApprovalOrRejection(String applicationId){
        Integer approvalCount = 0;
        Integer rejectionCount = 0;
        Boolean mandatoryApproved = false;
        
        // Get active committee configuration
        Map<String, Committee_Member_Config__mdt> configMap = Committee_Member_Config__mdt.getAll();
        // Get decisions
        for(Activity_History__c act : [SELECT id,Owner.UserRole.Name,Comments__c,Committee_Approval_Status__c FROM Activity_History__c WHERE Activity_For_Committee__c = true AND Application__c =:applicationId AND RecordTypeId =:SHF_ConstantsUtil.ACTIVITY_HISTORY_FOR_COMMITTEE_RECORDTYPEID]){
            system.debug('act > ' + act);
            system.debug('configMap> ' +configMap);
            system.debug('UserRole > ' + act.Owner.UserRole.Name);
            String committeUserRole = act.Owner.UserRole.Name;
            system.debug('committeUserRole > ' + committeUserRole);
            if (String.isBlank(committeUserRole)) return '';
            String result = committeUserRole;
            // Replace hyphen with space to preserve word boundary
            result = result.replace('-', ' ');
            // Remove ampersand
            result = result.replace('&', '');
            // Replace multiple spaces with single underscore
            result = result.replaceAll('\\s+', '_');
            String role = result;
            system.debug('role> ' +role);
            Committee_Member_Config__mdt cfg = configMap.get(role);
            system.debug('cfg>> ' + cfg);
            if (cfg == null || !cfg.Active__c) continue;
            
            if (cfg.Is_Mandatory__c && act.Committee_Approval_Status__c == SHF_ConstantsUtil.REJECTED) {
                return SHF_ConstantsUtil.REJECTED; // Immediate rejection
            }
            else if (cfg.Is_Mandatory__c && act.Committee_Approval_Status__c == SHF_ConstantsUtil.APPROVED) {
                mandatoryApproved = true;
            }
            if (act.Committee_Approval_Status__c ==  SHF_ConstantsUtil.APPROVED) {
                approvalCount++;
            }
            system.debug('act.Committee_Approval_Status__c> ' + act.Committee_Approval_Status__c + ' rejectionCount> ' +rejectionCount);
            if (act.Committee_Approval_Status__c ==  SHF_ConstantsUtil.REJECTED) {
                rejectionCount++;
            }
            system.debug('act.Committee_Approval_Status__c> ' + act.Committee_Approval_Status__c + ' rejectionCount> ' +rejectionCount);
        }
        Integer minApprovals = Integer.valueOf(System.Label.Min_Committee_Approvals);
        Integer minRejection = Integer.valueOf(System.Label.Min_Committee_Rejection);
        if(rejectionCount >= minRejection){
            return  SHF_ConstantsUtil.REJECTED;
        }
        return (approvalCount >= minApprovals && mandatoryApproved) ? SHF_ConstantsUtil.APPROVED :  SHF_ConstantsUtil.PENDING;
    }

//For Negotiation approval task update
      @AuraEnabled
    public static String updateApplicationForNegotionTask(String action, String actHistoryId, String comment, String applicationId){
        String msg = '';
        String STATUS = 'Pending';
        List<Fees__c> updateFeeList = new List<Fees__c>();
        list<E_Verification__c> updateInsuranceList = new List<E_Verification__c>();
        Set<Id> insuranceIds = new Set<Id>();
        try{
            if(action != null && actHistoryId != null && (applicationId != null || applicationId != 'undefined')){
                Activity_History__c activity = [SELECT Id,Approval_for__c FROM Activity_History__c WHERE Id = :actHistoryId ];
                Activity_History__c act = new Activity_History__c();
                act.id = actHistoryId;
                act.Comments__c  = comment;
                STATUS = action == 'Approve' ? SHF_ConstantsUtil.APPROVED :SHF_ConstantsUtil.REJECTED;
                act.Committee_Approval_Status__c = STATUS;
                update act; //update activity history
                 Application__c applicationDetail = new SHF_ApplicationSelector().selectApplicationForCIBIL(applicationId);
                  List<Loan_Applicant__c> applicantList =new  SHF_LoanApplicantsSelector().selectByIdWithLoanApplication(new Set<Id> {applicationId});
                  if(!applicantList.isEmpty()){
                    for(Loan_Applicant__c applicantDetail :applicantList){
                        insuranceIds.add(applicantDetail.Insurance_Verification__c) ;
                    }
                  }
                 List<E_Verification__c> insuraceSetailList = new SHF_E_VerificationSelector().selectByrecordId(insuranceIds);
                 if(!insuraceSetailList.isEmpty()){
                    for(E_Verification__c veryfy : insuraceSetailList){
                        if(STATUS == SHF_ConstantsUtil.APPROVED){

                            system.debug('veryfy.Negotiation_Insured_Amount__c ' + veryfy.Negotiation_Insured_Amount__c);
                             system.debug('veryfy.Negotiation_Insurance_Tenure__c; ' + veryfy.Negotiation_Insurance_Tenure__c);
                              system.debug('veryfy.Negotiation_Insurance_Premium__c ' + veryfy.Negotiation_Insurance_Premium__c);

                            Decimal  amount,tenure,premium,originalAmount,originalTenure,originalPremium = null;
                            amount= veryfy.Negotiation_Insured_Amount__c;
                            tenure =veryfy.Negotiation_Insurance_Tenure__c;
                            premium = veryfy.Negotiation_Insurance_Premium__c;

                            system.debug('processFee11 ' + amount);
                             system.debug('processFeePerc111 ' + tenure);
                              system.debug('roi111 ' + premium);

                             //update actual value on insurance verification
                             if (veryfy.Insurance_Provider__c.containsIgnoreCase('Kotak')) {
                                    originalTenure =veryfy.Negotiation_Insurance_Tenure__c != null ? veryfy.Loan_Tenure_In_Years__c : null;
                                     veryfy.Loan_Tenure_In_Years__c = tenure != null ? tenure : veryfy.Loan_Tenure_In_Years__c;
                                     system.debug('originalTenure 11 ' + originalTenure);
                                } else if (veryfy.Insurance_Provider__c.containsIgnoreCase('ICICI')) {
                                     originalTenure =veryfy.Negotiation_Insurance_Tenure__c != null ? veryfy.Outstanding_Loan_Tenure__c : null;
                                    veryfy.Outstanding_Loan_Tenure__c = tenure != null ? tenure : veryfy.Outstanding_Loan_Tenure__c;
                                    system.debug('originalTenure 22 ' + originalTenure);
                                }
                                
                            originalAmount= veryfy.Negotiation_Insured_Amount__c !=null? veryfy.Insured_Amount__c : null;
                            originalPremium = veryfy.Negotiation_Insurance_Premium__c != null ? veryfy.Premium_Amount__c : null; 
                             
                             veryfy.Insured_Amount__c =  amount != null ? amount : veryfy.Insured_Amount__c;
                             veryfy.Premium_Amount__c = premium != null ? premium :veryfy.Premium_Amount__c ;

                              veryfy.Original_Insured_Amount__c =  originalAmount;
                            veryfy.Original_Insurance_Tenure__c = originalTenure;
                             veryfy.Original_Insurance_Premium__c = originalPremium;
                        }
                        veryfy.Negotiation_Insurance_Premium__c = null;
                         veryfy.Negotiation_Insured_Amount__c = null;
                          veryfy.Negotiation_Insurance_Tenure__c = null;
                          updateInsuranceList.add(veryfy);
                    }
                 }

                Application__c application = new Application__c();
                application.id = applicationId;
                if(activity.Approval_for__c == 'CBO'){
                     application.CBO_Approval_Status__c = STATUS;
                }else if(activity.Approval_for__c == 'Underwriter'){
                     application.Re_Sanction_Status__c = STATUS;
                }
               
                if(STATUS == SHF_ConstantsUtil.APPROVED){
                     
                     Decimal  processFee ,processFeePerc ,roi, originalProceddFee, originalProcessFeePerc,originalRoi = null;
                            processFee=  applicationDetail.Negotiation_Processing_Fee__c;
                            processFeePerc =applicationDetail.Negotiation_Processing_Fee_Percent__c;
                            roi = applicationDetail.Negotiation_Rate_of_Interest_ROI__c;

                            originalProceddFee=  applicationDetail.Negotiation_Processing_Fee__c != null ?  applicationDetail.Processing_Fee__c : null;
                            originalProcessFeePerc =applicationDetail.Negotiation_Processing_Fee_Percent__c != null ? applicationDetail.Processing_Fee_percent__c : null ;
                            originalRoi = applicationDetail.Negotiation_Rate_of_Interest_ROI__c != null ? applicationDetail.Original_ROI__c : null;
                            
                            application.Original_Processing_Fee__c = originalProceddFee;
                            application.Original_Processing_Fee_Percent__c =originalProcessFeePerc ;
                            application.Original_ROI__c = originalRoi ;
                     
                     application.Processing_Fee__c=processFee != null ? processFee : applicationDetail.Processing_Fee__c;
                       application.Processing_Fee_percent__c=processFeePerc != null ? processFeePerc : applicationDetail.Processing_Fee_percent__c;
                         application.Revised_Rate__c=roi !=null ? roi :  applicationDetail.Revised_Rate__c;

                         //logic to update Amount and gst/tax on fee record
                          List<Fees__c> feeList = new SHF_FeeSelector().selectByapplicationRecodID(applicationId);
                          if(!feeList.isEmpty()){
                            for(Fees__c fee : feeList){
                                if(fee.Fee_Type__c == SHF_ConstantsUtil.BALANCR_PROCESSING_FEE){
                                    Fees__c feeData = new Fees__c();
                                    feeData.Id = fee.Id;
                                    feeData.Amount__c = processFee != null ? processFee : applicationDetail.Processing_Fee__c;
                                    feeData.Tax__c = processFeePerc != null ? processFeePerc : applicationDetail.Processing_Fee_percent__c;
                                    updateFeeList.add(feeData);
                                }
                            }
                          }

               
                }
                system.debug('updateFeeList '+ updateFeeList);
                if(!updateFeeList.isEmpty()){

                    update updateFeeList;
                }
                application.Negotiation_Processing_Fee__c = null;
                application.Negotiation_Processing_Fee_Percent__c = null;
                application.Negotiation_Rate_of_Interest_ROI__c = null;

                 system.debug('application ' + application);
                update application; //update application record
                if(!updateInsuranceList.isEmpty()){
                     system.debug('updateInsuranceList ' + updateInsuranceList);
                    update updateInsuranceList;
                }
                msg = 'Success';
            }
        }catch(exception ex){
            system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
            msg = 'error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber();
        }
        return msg;
    }

    //For Special Condition approval task update
      @AuraEnabled
    public static String updateForSpecialConditionApprovalTask( String actHistoryId){
        String msg = '';
         String STATUS = 'Pending';
          try{
            if( actHistoryId != null ){
                List<Document__c> docList =	new SHF_DocumentsSelector().selectByActivityHistoryIds(new Set<Id>{actHistoryId});
                if(!docList.isEmpty()){
                    return 'Pending Task';
                }
                 List<Document__c> updateDocList = new List<Document__c>();
                Activity_History__c act = new Activity_History__c();
                act.id = actHistoryId;
               // act.Comments__c  = comment;
                act.Committee_Approval_Status__c = SHF_ConstantsUtil.COMPLETEDSTATUS;
                update act; //update activity history
                  msg = 'Success';
            }
          }catch(Exception ex){
                 system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
            msg = 'error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber();  
          }
          return msg;
        }
}