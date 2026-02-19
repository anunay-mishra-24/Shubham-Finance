public with sharing class SHF_ApplicationMoveToNextController {
    
    @AuraEnabled
    public static String moveToNextStage(Id recordId) {
        try {
            Application__c app = [
                SELECT Id, Application_Stage__c,Is_LAF_Generated__c,Is_LAF_Intimated__c, RecordType.DeveloperName,OwnerId,
                Product__c,Applied_Loan_Amount__c,Name,Branch__c,CBO_Approval_Status__c, Re_Sanction_Status__c, QDE_Last_Owner__c, Sendback_From__c,
                E_Sign_Executed__c, E_Sign_Success__c
                FROM Application__c 
                WHERE Id = :recordId 
                LIMIT 1
            ];
            // List<fees__c> feeList = [SELECT Id,application__c from Fees__c where application__c =:recordId AND Status__c = 'Collected'];
            List<Loan_Applicant__c> allApplicantList = new SHF_LoanApplicantsSelector().getApplicantsByApplication(recordId);//Added By Riteek
            system.debug('allApplicantList : '+allApplicantList);
            
            // if (app.RecordType.DeveloperName != 'QDE') {
            //     Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('INVALID_QDE_ACTION');
            //     return msg.get('MessageType') + ': ' + msg.get('Message');
            // }
            
            List<String> errorMessages = new List<String>();
            String nextStage;
            String resultMsg;
            // System.debug('feeList'+feeList);
            //     String Status = SHF_GetReciptStatus_Service.getReciptStatus(recordId);
            //     if(Status == 'X' || Status == 'x'){
            // 		List<fees__c> feeListNew = [SELECT Id,application__c,Status__c from Fees__c where application__c =:recordId AND Status__c = 'Pending'];
            //         feeListNew[0].Status__c = 'Cancelled';
            //         errorMessages.add(
            //             'Fee collection is marked as Cancelled in LMS. Please re-initiate the payment and complete fee collection before moving to the next stage. '
            //         );
            //         update feeListNew;
            // }else{
            //     if (feeList.isEmpty()) {
            //         errorMessages.add(
            //             'Login fee collection is mandatory before proceeding. ' +
            //             'Please complete the fee collection under the \'Fees and Charges\' tab to continue.'
            //         );
            //     }
            // }
            // system.debug('app.Application_Stage__c '+ app.Application_Stage__c);
            switch on app.Application_Stage__c {
                
                when 'Applicant Details' {
                    
                    if (app.Product__c == null) {
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('MISSING_PROGRAM_ERROR');
                        errorMessages.add(msg.get('Message'));
                    }   
                    
                    if (!hasRequiredApplicants(app.Id)) {
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('MISSING_APPLICANT_ERROR');
                        errorMessages.add(msg.get('Message'));
                    }
                    
                    if (!hasPrimaryApplicant(app.Id)) {
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('MISSING_PRIMARY_APPLICANT_ERROR');
                        errorMessages.add(msg.get('Message'));
                    }
                    
                    if (hasMissingReferenceMembers(app.Id)) {
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('Minimum_Reference_Limit');
                        errorMessages.add(msg.get('Message'));
                    }
                    
                    List<String> contactKeyErrors = validateContactPersonAndKeyEmployee(app.Id);
                    if (contactKeyErrors != null && !contactKeyErrors.isEmpty()) {
                        errorMessages.addAll(contactKeyErrors);
                    }
                    
                    List<String> partnerKeyErrors = validatePartnerAndDirector(app.Id);
                    if (partnerKeyErrors != null && !partnerKeyErrors.isEmpty()) {
                        errorMessages.addAll(partnerKeyErrors);
                    }

                    
                    
                    List<Loan_Applicant__c> applicants = [
                        SELECT Id, Name 
                        FROM Loan_Applicant__c 
                        WHERE Application__c = :app.Id 
                        AND IsDeleted__c = false
                    ];
                    
                    if (!applicants.isEmpty()) {
                        Map<Id, Personal_Discussion__c> pdMap = new Map<Id, Personal_Discussion__c>(
                            [SELECT Id, Loan_Applicant__c 
                             FROM Personal_Discussion__c 
                             WHERE Loan_Applicant__c IN :applicants]
                        );
                        
                        Map<Id, Personal_Discussion__c> pdByApplicantMap = new Map<Id, Personal_Discussion__c>();
                        for (Personal_Discussion__c pd : pdMap.values()) {
                            if (pd.Loan_Applicant__c != null) {
                                pdByApplicantMap.put(pd.Loan_Applicant__c, pd);
                            }
                        }
                        
                        for (Loan_Applicant__c applicant : applicants) {
                            if (!pdByApplicantMap.containsKey(applicant.Id)) {
                                errorMessages.add('Please complete the PD for ' + applicant.Name);
                            }
                        }
                    }
                    
                    List<Loan_Applicant__c> applicantsWithAddresses = [
                        SELECT Id,Name,
                        (SELECT Id, Name,Applicant_RecordType_Name__c, Mailing_Address__c,Communication_Address__c, Address_Type__c
                         FROM Addresses1__r)
                        FROM Loan_Applicant__c
                        WHERE Application__c = :app.Id
                        AND IsDeleted__c = false
                    ];
                    
                    Boolean hasMissingAddress = false;
                    for (Loan_Applicant__c applicant : applicantsWithAddresses) {
                        if (applicant.Addresses1__r == null || applicant.Addresses1__r.isEmpty()) {
                            hasMissingAddress = true;
                            break;
                        }
                        for (Address__c addr : applicant.Addresses1__r) {
                            if (addr.Applicant_RecordType_Name__c == 'Individual') {
                                if (String.isBlank(addr.Mailing_Address__c)) {
                                    hasMissingAddress = true;
                                    break;
                                }
                            } else if (addr.Applicant_RecordType_Name__c == 'Non-Individual') {
                                if (String.isBlank(addr.Address_Type__c)) {
                                    hasMissingAddress = true;
                                    break;
                                }
                            }
                        }
                        if (hasMissingAddress) break;
                    }
                    
                    if (hasMissingAddress) {
                        Map<String, String> msg = SHF_CommonUtil.getMessageFromMetadata('MISSING_ADDRESS_ERROR');
                        errorMessages.add(msg.get('Message'));
                    }
                    
                    if (allApplicantList != null && !allApplicantList.isEmpty()) {
                        List<String> applicantsForVerifiedPan = new List<String>();
                        List<String> applicantsForVerifiedAadhar = new List<String>();
                        List<String> applicantsForSmsConcent = new List<String>();
                        List<String> applicantsForBurear = new List<String>();
                        //  List<String> applicantsForUdyamRegistration = new List<String>();//added by Dimple 19-12-25
                        //  List<String> applicantsForUdyamAdvance = new List<String>();//added by Dimple 22-12-25
                        List<String> applicantsForMNRL = new List<String>();
                        List<String> applicantsForAlternateMNRL = new List<String>();
                        
                        // Map to store applicant Id → RecordType
                        Map<Id, String> appToRecordTypeMap = new Map<Id, String>();
                        for(Loan_Applicant__c la : allApplicantList) {
                            appToRecordTypeMap.put(la.Id, la.RecordType.DeveloperName);
                        }
                        for (Loan_Applicant__c la : allApplicantList) {
                            if (la.Is_PAN_Verified__c == false) {
                                applicantsForVerifiedPan.add(la.Name);
                            }
                            if (la.Is_Aadhar_Fetched__c == false  && (appToRecordTypeMap.get(la.Id) == 'Individual')) {
                                applicantsForVerifiedAadhar.add(la.Name);
                            }
                            if(la.Is_SMS_Consent_Given__c == false){
                                applicantsForSmsConcent.add(la.Name);
                            }
                            if(la.Mobile_Verification__c == null){
                                applicantsForMNRL.add(la.Name);
                            }
                            else if(la.Mobile_Verification__r.Mobile_IsFound__c){
                                applicantsForMNRL.add(la.Name);      
                            }
                            if(la.Alternate_Mobile_Number__c !=null && la.Alternate_Mobile_Verification__r.Mobile_IsFound__c){
                                applicantsForAlternateMNRL.add(la.Name);
                            }
                            if(appToRecordTypeMap.get(la.Id) == 'Individual'){
                                if(String.isBlank(la.CRIF_Verification__c) && String.isBlank(la.CIBIL_Verification__c)){
                                    applicantsForBurear.add(la.Name);
                                }
                                else if(String.isNotBlank(la.CRIF_Verification__c) && String.isNotBlank(la.CIBIL_Verification__c)){
                                    if(la.CRIF_Verification__r.Status__c != 'COMPLETED' || la.CIBIL_Verification__r.Status__c != 'COMPLETED' ){
                                        applicantsForBurear.add(la.Name);
                                    }

                                }
                                else if(String.isNotBlank(la.CRIF_Verification__c) && la.CRIF_Verification__r.Status__c != 'COMPLETED'){
                                    applicantsForBurear.add(la.Name);
                                }
                                else if(String.isNotBlank(la.CIBIL_Verification__c) && la.CIBIL_Verification__r.Status__c != 'COMPLETED'){
                                    applicantsForBurear.add(la.Name);
                                }

                                // {
                                //     if((String.isNotBlank(la.CRIF_Verification__c) && la.CRIF_Verification__r.Status__c != 'COMPLETED') || (String.isNotBlank(la.CIBIL_Verification__c) && la.CIBIL_Verification__r.Status__c != 'COMPLETED')){
                                //         applicantsForBurear.add(la.Name);
                                //     }
                                // }
                            }
                            /*added by Dimple 19-12-25
                            if(la.Udyam_Verification__r.Is_Udyam_Registration_Verified__c== false  && (appToRecordTypeMap.get(la.Id) == 'Non-Individual')){
                                applicantsForUdyamRegistration.add(la.Name);
                                System.debug('applicantsForUdyamRegistration' +applicantsForUdyamRegistration);
                            }
                             //added by Dimple 22-12-25
                            if(la.Udyam_Verification__r.Is_Udyam_Advance_Verified__c== false  && (appToRecordTypeMap.get(la.Id) == 'Non-Individual')){
                                applicantsForUdyamAdvance.add(la.Name);
                                System.debug('applicantsForUdyamAdvance' +applicantsForUdyamAdvance);
                            }*/
                        }
                        if(!applicantsForVerifiedPan.isEmpty() ){
                            errorMessages.add('PAN Verification is pending for '+String.join(applicantsForVerifiedPan, ' , '));
                        }
                        if(!applicantsForVerifiedAadhar.isEmpty() ){
                            errorMessages.add('Aadhar Verification is pending for '+String.join(applicantsForVerifiedAadhar, ' , '));
                        }
                        if(!applicantsForSmsConcent.isEmpty() ){
                            errorMessages.add('SMS Consent is pending for '+String.join(applicantsForSmsConcent, ' , '));
                        }
                        if(!applicantsForBurear.isEmpty()){
                            errorMessages.add('Bureau is pending for '+String.join(applicantsForBurear, ' , '));
                        }
                        if(!applicantsForMNRL.isEmpty()){
                            errorMessages.add('MNRL is pending for '+String.join(applicantsForMNRL, ' , '));
                        }
                        if(!applicantsForAlternateMNRL.isEmpty()){
                            errorMessages.add('Alternative Mobile MNRL is pending for '+String.join(applicantsForAlternateMNRL, ' , '));
                        }
                        /*added by Dimple 19-12-25
                        if(!applicantsForUdyamRegistration.isEmpty()){
                           errorMessages.add('The Udyam verification is pending for '+String.join(applicantsForUdyamRegistration, ' , '));
                            System.debug('errorMessagesforudyam' +errorMessages);
                        }
                         //added by Dimple 22-12-25
                        if(!applicantsForUdyamAdvance.isEmpty()){
                           errorMessages.add('The Udyam Advance Verification is pending for '+String.join(applicantsForUdyamAdvance, ' , '));
                            System.debug('errorMessagesforudyam' +errorMessages);
                        }*/
                    }
                    
                    //Employment Type
                    List<Loan_Applicant__c> empApplicants = [
                        SELECT Id, Name,
                        (SELECT Id FROM Employments__r)
                        FROM Loan_Applicant__c
                        WHERE Application__c = :app.Id
                        AND IsDeleted__c = false
                    ];
                    
                    List<String> applicantsMissingEmployment = new List<String>();
                    
                    for (Loan_Applicant__c la : empApplicants) {
                        if (la.Employments__r == null || la.Employments__r.isEmpty()) {
                            applicantsMissingEmployment.add(la.Name);
                        }
                    }
                    
                    if (!applicantsMissingEmployment.isEmpty()) {
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('Atleast_One_Employment_Required');
                        String finalMsg = msg.get('Message') + ' ' + String.join(applicantsMissingEmployment, ', ');
                        errorMessages.add(finalMsg);
                    }
                    //End
    // New validation: Check each applicant has one address marked Communication_Address__c = 'Yes'
    for (Loan_Applicant__c applicant : applicantsWithAddresses) {
        Boolean hasCommunicationAddr = false;
        if (applicant.Addresses1__r != null && !applicant.Addresses1__r.isEmpty()) {
            for (Address__c addr : applicant.Addresses1__r) {
                if (addr.Communication_Address__c == 'Yes') {
                    hasCommunicationAddr = true;
                    break;
                }
            }
        }
        if (!hasCommunicationAddr) {
            Map<String, String> commMsgMap = SHF_CommonUtil.getMessageFromMetadata('Communication_Address_Error');
            String commMsg = commMsgMap.get('Message');
            // Append applicant name in message
            errorMessages.add(commMsg + ' ' + applicant.Name);
        }
    }


                    
                    if (!errorMessages.isEmpty()) {
                        return 'ERROR: ' + String.join(errorMessages, '\n');
                    }
                   
                    nextStage = 'Collateral Details';
                }
                
                when 'Collateral Details' {
                    if (!hasCollateralApplication(app.Id)) {
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('MISSING_COLLATERAL_ERROR');
                        errorMessages.add(msg.get('Message'));
                    }

                    if (!errorMessages.isEmpty()) {
                        return 'ERROR: ' + String.join(errorMessages, '\n');
                    }
                    SHF_FeeCreationHandler.createFeeRecords(recordId, 'QDE');
                    nextStage = 'Document Checklist';

                    
                }
                
                when 'Document Checklist' {
                    List<Loan_Applicant__c> applicantsWithAddresses = [
                        SELECT Id,
                        (SELECT Id, Applicant_RecordType_Name__c, Mailing_Address__c, Address_Type__c
                         FROM Addresses1__r)
                        FROM Loan_Applicant__c
                        WHERE Application__c = :app.Id
                        AND IsDeleted__c = false
                    ];
                    
                    Boolean hasMissingAddress = false;
                    for (Loan_Applicant__c applicant : applicantsWithAddresses) {
                        if (applicant.Addresses1__r == null || applicant.Addresses1__r.isEmpty()) {
                            hasMissingAddress = true;
                            break;
                        }
                        for (Address__c addr : applicant.Addresses1__r) {
                            if (addr.Applicant_RecordType_Name__c == 'Individual') {
                                if (String.isBlank(addr.Mailing_Address__c)) {
                                    hasMissingAddress = true;
                                    break;
                                }
                            } else if (addr.Applicant_RecordType_Name__c == 'Non-Individual') {
                                if (String.isBlank(addr.Address_Type__c)) {
                                    hasMissingAddress = true;
                                    break;
                                }
                            }
                        }
                        if (hasMissingAddress) break;
                    }
                    
                    if (hasMissingAddress) {
                        Map<String, String> msg = SHF_CommonUtil.getMessageFromMetadata('MISSING_ADDRESS_ERROR');
                        errorMessages.add(msg.get('Message'));
                    }
                    
                    if (hasPendingMandatoryDocuments(app)) {
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('MANDATORY_DOCS_PENDING');
                        errorMessages.add(msg.get('Message'));
                    }
                    
                    if (!errorMessages.isEmpty()) {
                        return 'ERROR: ' + String.join(errorMessages, '\n');
                    }
                    
                    nextStage = 'Application Form Generation';
                }
                
                when 'Application Form Generation' {
                    if (hasOpenQueries(app.Id)) {
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('OPEN_QUERIES_ERROR');
                        errorMessages.add(msg.get('Message'));
                    }
                    
                    // --- Sales PD changes / Data_Changes_After_LAF_Generation__
                    
                    List<Loan_Applicant__c> applicantsWithPdChanges = [
                        SELECT Id, Name, Data_Changes_After_LAF_Generation__c
                        FROM Loan_Applicant__c
                        WHERE Application__c = :app.Id
                        AND Data_Changes_After_LAF_Generation__c != null
                    ];
                    
                    List<Loan_Applicant__c> applicantsToUpdate = new List<Loan_Applicant__c>();
                    
                    if (!applicantsWithPdChanges.isEmpty()) {
                        for (Loan_Applicant__c la : applicantsWithPdChanges) {
                            String changes = la.Data_Changes_After_LAF_Generation__c;
                            if (String.isNotBlank(changes)) {
                                // Multi-select picklist values are semicolon separated in API
                                List<String> values = new List<String>();
                                for (String v : changes.split(';')) {
                                    if (v != null) values.add(v.trim());
                                }
                                
                                // Check presence of specific value
                                Boolean hasCustomerProfileChanged = values.contains('Customer Profile Changed');
                                
                                if (hasCustomerProfileChanged) {
                                    if (app.Is_LAF_Generated__c == false) {
                                        // LAF not generated yet -> block moving forward for this applicant
                                        errorMessages.add('There are changes in the Sales PD for ' + la.Name + '. Please click on the ‘Generate LAF’ button before proceeding.');
                                    } else {
                                        // LAF already generated -> remove the "Customer Profile Changed" value from picklist
                                        List<String> newValues = new List<String>();
                                        for (String vv : values) {
                                            if (vv != 'Customer Profile Changed') {
                                                newValues.add(vv);
                                            }
                                        }
                                        String newValStr = (newValues.isEmpty()) ? null : String.join(newValues, ';');
                                        la.Data_Changes_After_LAF_Generation__c = newValStr;
                                        applicantsToUpdate.add(la);
                                    }
                                }
                            }
                        }
                    }
                    
                    if (!applicantsToUpdate.isEmpty()) {
                        try {
                            update applicantsToUpdate;
                        } catch (Exception e) {
                            // Swallow update exception but log; do not block stage change because update failure is non-critical
                            System.debug('Failed to clear Data_Changes_After_LAF_Generation__c values: ' + e.getMessage());
                        }
                    }
                    // ---------- END: Added logic for Sales PD changes 
                    
                    if(!errorMessages.isEmpty()){
                        return 'ERROR: ' + String.join(errorMessages, '\n');
                    }
                    
                    if (app.Is_LAF_Generated__c == false || app.Is_LAF_Intimated__c == false) {
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('LAF_Generation_and_Intimation_Error');
                        errorMessages.add(msg.get('Message'));
                    }
                    //Added By Riteek ****
                    // if (allApplicantList != null && !allApplicantList.isEmpty()) {
                    //     List<String> applicantsForVerifiedPan = new List<String>();
                    //     List<String> applicantsForVerifiedAadhar = new List<String>();
                    
                    //     for (Loan_Applicant__c la : allApplicantList) {
                    //         if (la.Is_PAN_Verified__c == false) {
                    //         applicantsForVerifiedPan.add(la.Name);
                    //         }
                    //         if (la.Is_Aadhar_Verified__c == false) {
                    //         applicantsForVerifiedAadhar.add(la.Name);
                    //         }
                    //     }
                    //      if(!applicantsForVerifiedPan.isEmpty() ){
                    //         errorMessages.add('PAN Verification is pending for '+String.join(applicantsForVerifiedPan, ' , '));
                    //     }
                    //     if(!applicantsForVerifiedAadhar.isEmpty() ){
                    //         errorMessages.add('Aadhar Verification is pending for '+String.join(applicantsForVerifiedAadhar, ' , '));
                    //     }
                    // }//*****
                    
                    if(!errorMessages.isEmpty()){
                        return 'ERROR: ' +String.join(errorMessages, '\n');
                    }
                    
                    RecordType rt = [
                        SELECT Id 
                        FROM RecordType 
                        WHERE DeveloperName = 'Credit_Evaluation' 
                        AND SObjectType = 'Application__c' 
                        LIMIT 1
                    ];
                    app.RecordTypeId = rt.Id;
                    nextStage = 'DDE';
                }
                
                //Gaurav Kumar 20-Jan-2026 SHF-1558
                when 'Negotiation' {
                    if(app.QDE_Last_Owner__c != null){
                        List<User> usrObj = [SELECT Id, Name, Profile.Name,isActive,Manager.Name,Manager.Branch_IDs__c FROM User WHERE Id = :app.QDE_Last_Owner__c LIMIT 1];
                        if(usrObj[0].isActive){
                            app.ownerId = app.QDE_Last_Owner__c;
                        }else if(usrObj[0].isActive == false && app.Branch__c == usrObj[0].Manager.Branch_IDs__c){
                            List<Branch_Mapping__c> rmUserList = [SELECT ID,Branch_Master__r.Name,Branch_Master__c,Internal_User__c,  Internal_User__r.Role_Name__c,Internal_User__r.IsActive  
                                                                  FROM Branch_Mapping__c WHERE Branch_Master__c =:app.Branch__c AND Internal_User__r.Role_Name__c='Feet_on_Street'];
                            if(rmUserList.size()>0){
                                if(rmUserList[0].Internal_User__r.IsActive){
                                    app.ownerId = rmUserList[0].Internal_User__c;
                                }
                            }
                        } else if(usrObj[0].isActive){
                            app.ownerId = app.QDE_Last_Owner__c;
                        }
                    }else{
                        errorMessages.add(System.Label.QDE_Last_Owner_Error);
                    }  
                    //---------Start SHF- 1476 Added by David ----------//                                     
                    List<Verification__c> verificationList = [Select Id, Name, RCU_Status__c,RCU_Decision__c,Type__c FROM Verification__c WHERE Type__c = 'RCU Comfort' AND Application__c =: app.Id];
                    if(verificationList.size()>0) {
                        if(verificationList[0].RCU_Status__c == 'Pending') {
                            Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('RCU_Comfort_Activity_Pending_Error');
                            errorMessages.add(msg.get('Message'));
                        }
                        else if(verificationList[0].RCU_Decision__c == 'Not Ok') {
                            Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('RCU_Decision_Error');
                            errorMessages.add(msg.get('Message'));
                        }
                    }
                    //---------End SHF- 1476 Added by David ----------//  
                    if(app.CBO_Approval_Status__c =='Pending' || app.Re_Sanction_Status__c =='Pending'){
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('CBO_And_ReSanction_Pending_Error');
                        errorMessages.add(msg.get('Message'));
                    }
                    // else if(app.CBO_Approval_Status__c =='Pending'){
                    //     Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('CBO_Pending_Error');
                    //     errorMessages.add(msg.get('Message'));
                    // }
                    // else if(app.Re_Sanction_Status__c =='Pending'){
                    //     Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('ReSanction_Pending_Error');
                    //     errorMessages.add(msg.get('Message'));
                    // }
                    else{
                        nextStage = 'Pre-Disbursement Document Collection';
                    }
                    if(!errorMessages.isEmpty()){
                        return 'ERROR: ' + String.join(errorMessages, '\n');
                    }
                    System.debug('nextStage'+nextStage);
                }
                //Gaurav Kumar End
                // Anunay Kumar SHF-1601 30-Jan-2026
                when 'Pre-Disbursement Document Collection' {
                    System.debug('hasspeciaConditionDocumentUploaded '+hasspeciaConditionDocumentUploaded(app));
                    //--------Ashutosh Dubey SHF-1596 19 Feb, 2026 starts ----------------------------//
                    if(!app.E_Sign_Executed__c){
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('E_Sign_Error');
                        errorMessages.add(msg.get('Message'));
                    }
                    //--------Ashutosh Dubey SHF-1596 19 Feb, 2026 ends ----------------------------//
                    if(hasspeciaConditionDocumentUploaded(app) == 'Pending'){
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('SPECIAL_CONDITION_DOCS_PENDING_UPLOAD');
                        errorMessages.add(msg.get('Message'));
                        //return 'ERROR: ' + String.join(errorMessages, '\n');
                    }
                    else if(hasspeciaConditionDocumentUploaded(app) == 'Not Uploaded'){
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('SPECIAL_CONDITION_DOCS_PENDING');
                        errorMessages.add(msg.get('Message'));
                        //return 'ERROR: ' + String.join(errorMessages, '\n');
                    }
                    if(hasOpenQueries(app.Id)){
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('SPECIAL_CONDITION_DOCS_QUERY_PENDING');
                        errorMessages.add(msg.get('Message'));
                        //return 'ERROR: ' + String.join(errorMessages, '\n');
                    }
                    if (hasPendingMandatoryDocuments(app)) {
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('MANDATORY_DOCS_PENDING');
                        errorMessages.add(msg.get('Message'));
                    }
                    //Gaurav kumar 09-Feb-2026
                    if (!hasTrancheRequestInitiation(app)) {
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('Tranche_Request_Initiation');
                        errorMessages.add(msg.get('Message'));
                    }
                    //end Gaurav
                    if (!errorMessages.isEmpty()) {
                        return 'ERROR: ' + String.join(errorMessages, '\n');
                    }
                    Group grup = [SELECT Id,Name FROM Group 
                                  WHERE Type = 'Queue' AND DeveloperName ='Pending_Applications_for_Cheque_Printing'];
                        nextStage = 'Cheque Printing';                    
                    app.Last_Pre_Dis_Doc_Collection_User__c = app.ownerId;
                    app.ownerId = grup.Id;
                }
                 when 'Cheque Printing' {
                    List<String> disbList = new List<String>();
                  List<Disbursement__c> disbursementList = [SELECT Id,Status__c FROM Disbursement__c  WHERE Application__c =:recordId];
                  if(disbursementList.size() == 0){
                    errorMessages.add('Atleast one tranche shall be created before moving forward.');
                  }
                    system.debug('disbursementList ' + disbursementList);
                 for(Query__c  query : [ SELECT Id,Query_Status__c,Disbursement__r.Name FROM Query__c   WHERE Disbursement__c IN :disbursementList AND Query_Status__c != 'Completed']){
                    disbList.add(query.Disbursement__r.Name);
                 }
                 system.debug('disbList '  +disbList);
                 if(!disbList.isEmpty()){
                     errorMessages.add('Kindly close all the queries of '+String.join(disbList, ',') +' before moving forward ');
                 }
                    if (!errorMessages.isEmpty()) {
                        return 'ERROR: ' + String.join(errorMessages, '\n');
                    }

                }
                when 'Disbursement Maker' {

                    String validationMessage = SHF_HunterValidatorOnStageMovement.validateApplicantsFinalDecision(app.Id);
                    errorMessages.add(validationMessage);
                    return 'ERROR: ' + String.join(errorMessages, '\n');

                }
                // End Anunay Kumar SHF-1601 30-Jan-2026
                when else {
                    Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('INVALID_QDE_Process');
                    return 'ERROR: ' + msg.get('Message');
                }
            }
            
            app.Application_Stage__c = nextStage;
            if(app.Sendback_From__c == nextStage){
                app.Sendback_From__c = '';
            }
            update app;
            createEVerificationRecords(app.Id);
            
            //---------Start SHF- 1224 Added by Ranjeet----------//
            // if(nextStage == 'DDE'){
            //     System.debug('AML nextStage===>'+nextStage);
            //     List<Loan_Applicant__c> amlApplicants = [ SELECT Id,AML_Verification__c, AML_Verification__r.AML_Request_Hash__c, Address__c, Address__r.Country__c, Address__r.State__c,
            //                                               Address__r.City__c, Address__r.Address_Line_1__c, Address__r.Pincode__r.Name, Name, Entity_Name__c, Pan_Number__c, GST_Number__c,
            //                                               Date_of_Birth__c, Date_Of_Incorporation1__c, Gender__c, Mobile_Number__c, Customer_Type__c FROM Loan_Applicant__c 
            //                                               WHERE Application__c = :app.Id AND IsDeleted__c = false];

            //     for(Loan_Applicant__c loanApplicant : amlApplicants){
            //         System.debug('amlApplicants==>'+amlApplicants);
            //         String newHash = SHF_AML_Service.buildAMLRequestHash(loanApplicant);
            //         System.debug('newHash==>'+newHash);
            //         Boolean triggerAML = false;
            //         if (loanApplicant.AML_Verification__c == null) {
            //             System.debug('elseIftriggerAML==>'+loanApplicant.AML_Verification__r.AML_Request_Hash__c);
            //             triggerAML = true;
            //         }
            //         else if (loanApplicant.AML_Verification__r.AML_Request_Hash__c != newHash){
            //             System.debug('elseIftriggerAML==>'+loanApplicant.AML_Verification__r.AML_Request_Hash__c);
            //             triggerAML = true;
            //         }
            //         if (triggerAML) {
            //             System.debug('triggerAML==>');
            //             if(String.isNotBlank(loanApplicant.Id)){
            //                System.enqueueJob( new SHF_AML_Queueable(loanApplicant.Id));
            //             }
            //         }
            //     }
            // }
            //---------End SHF- 1224 Added by Ranjeet----------//
            if (nextStage == 'DDE') {
                Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('MOVE_TO_DDE_SUCCESS');
                resultMsg = 'SUCCESS' + ': ' + msg.get('Message');
            } else {
                Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('NEXT_STAGE_SUCCESS');
                resultMsg = 'SUCCESS' + ': ' + msg.get('Message') + ' → ' + nextStage;
            }
            return resultMsg;
            
        } catch (Exception ex) {
            return 'ERROR: ' + ex.getMessage();
        }
    }
    
    private static Boolean hasOpenQueries(Id applicationId) {
        return [
            SELECT Id 
            FROM Query__c 
            WHERE Loan_Application_Number__c = :applicationId
            AND Query_Status__c != 'Completed'
            LIMIT 1
        ].size() > 0;
    }
    // added by Anunay SHF-1601 date : 30-01-2026
    private static String hasspeciaConditionDocumentUploaded(Application__c app) {
        System.debug('hasspeciaConditionDocumentUploaded app '+app);
        
        
        Set<String> statuses = new Set<String>{ 'Completed', 'Deferred', 'Waived Off' };
        // Fetch special condition documents

        List<Document__c> docs = [
            SELECT Id, Sanction_Condition_Status__c
            FROM Document__c
            WHERE Application__c = :app.Id
            AND Sanction_Condition_Status__c NOT IN :statuses AND Type__c = 'Special Condition' AND (Type_Of_Condition__c ='Sanction Condition' OR Type_Of_Condition__c ='Pre-Disbursement Document') order by Sanction_Condition_Status__c DESC
        ];
        List<Query__c > queryList = [SELECT Id FROM Query__c WHERE Loan_Application_Number__c = :app.Id AND Query_Status__c != 'Completed' LIMIT 1];
        String errorStatus = '';
        for (Document__c doc : docs) {
            
            if (doc.Sanction_Condition_Status__c =='Pending' ){
                errorStatus='Pending';
                break;  // pending special condition doc
            }
            else if(!statuses.contains(doc.Sanction_Condition_Status__c)){
                errorStatus='Not Uploaded';
                break;

            }
            
        }
        system.debug('hasspeciaConditionDocumentUploaded errorStatus '+errorStatus);
      
            return errorStatus;
        }
        // End added by Anunay SHF-1601 date : 30-01-2026
      
       
    
   
    private static Boolean hasPendingMandatoryDocuments(Application__c app) {
        if (app == null || app.Id == null) return false;
        List<Document__c> docs = new List<Document__c>();
        // Fetch mandatory documents
        if(app.Application_Stage__c != 'Pre-Disbursement Document Collection'){
        docs = [
            SELECT Id, Status__c, Mandatory_Document__c, Stage__c,Loan_Applicant__c
            FROM Document__c
            WHERE Application__c = :app.Id
            AND Mandatory_Document__c = true
            AND Stage__c = :app.RecordType.DeveloperName
            AND (
            Loan_Applicant__c = NULL
            OR Loan_Applicant__r.IsDeleted__c = false
            )
        ];
        }
        else{
            docs = [
            SELECT Id, Status__c, Mandatory_Document__c, Stage__c,Loan_Applicant__c
            FROM Document__c
            WHERE Application__c = :app.Id
            AND Mandatory_Document__c = true
            AND Stage__c = 'Pre-Disbursement Document Collection'	

        ];

        }
        
        // If there are no mandatory documents, it's not an error
        if (docs.isEmpty()) return false;
        
        // Check if any document is NOT uploaded
        for (Document__c d : docs) {
            if (d.Status__c != 'Uploaded') {
                return true;  // pending mandatory doc
            }
        }
        return false; // all uploaded
    }
    public static Boolean hasTrancheRequestInitiation(Application__c app) {

    if (app == null || app.Id == null) return false;

    Set<String> statuses = new Set<String>{
        'Tranche Approval',
        'Tranche Request Initiation'
    };

    Set<String> foundStatuses = new Set<String>();

    for (Disbursement__c d : [
        SELECT Status__c
        FROM Disbursement__c
        /*WHERE Application__c = :app.Id
        AND Status__c IN :statuses*/
    ]) {
        foundStatuses.add(d.Status__c);
    }

    if (foundStatuses.contains('Tranche Approval')) {
        return true;
    }

    // Otherwise require initiation
    return foundStatuses.contains('Tranche Request Initiation');
}

    
    private static Boolean hasMissingReferenceMembers(Id applicationId) {
        Integer referenceCount = [
            SELECT COUNT() 
            FROM Reference_Member__c 
            WHERE Application__c = :applicationId
            AND Type_of_Member__c = 'Reference'
            AND Type_of_Member__c != null
        ];
        return referenceCount < 2;
    }
    
    private static Boolean hasRequiredApplicants(Id applicationId) {
        final Integer CO_APPLICANT_LIMIT = 1;
        SHF_LoanApplicantsSelector loanApplicantselector = new SHF_LoanApplicantsSelector();
        Integer coApplicantCount = loanApplicantselector.countCoApplicantsByApplication(applicationId);
        return coApplicantCount >=  CO_APPLICANT_LIMIT;
    }
    
    private static List<String> validateContactPersonAndKeyEmployee(Id applicationId) {
        List<String> errorMessages = new List<String>();
        
        if (applicationId == null) return errorMessages;
        
        // Get all applicants for the application
        List<Loan_Applicant__c> applicants = [
            SELECT Id, Name, Account_Name__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            AND IsDeleted__c = false
        ];
        
        if (applicants.isEmpty()) return errorMessages;
        
        // Get all Reference Members for these applicants
        List<Reference_Member__c> refMembers = [
            SELECT Id, Loan_Applicant__c, Type_of_Member__c
            FROM Reference_Member__c
            WHERE Loan_Applicant__c IN :applicants
            AND Type_of_Member__c = 'Contact Person & Key Employee'
        ];
        
        // Map applicant Id -> Boolean indicating if they have this type
        Map<Id, Boolean> applicantHasContactKey = new Map<Id, Boolean>();
        for (Reference_Member__c rm : refMembers) {
            applicantHasContactKey.put(rm.Loan_Applicant__c, true);
        }
        
        // Validate each applicant
        for (Loan_Applicant__c app : applicants) {
            if (!applicantHasContactKey.containsKey(app.Id)) {
                errorMessages.add('Please add at least one Contact Person & Key Employee for ' + app.Account_Name__c);
            }
        }
        
        return errorMessages;
    }
    
    private static List<String> validatePartnerAndDirector(Id applicationId) {
        List<String> errorMessages = new List<String>();
        
        if (applicationId == null) return errorMessages;
        
        // Get only Non-Individual applicants with relevant constitution types
        List<Loan_Applicant__c> applicants = [
            SELECT Id, Name, Account_Name__c, Customer_Type__c, Constitution__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            AND IsDeleted__c = false
            AND Customer_Type__c = 'Non-Individual'
            AND (Constitution__c = 'Partnership' OR Constitution__c = 'Private Limited')
        ];
        
        if (applicants.isEmpty()) return errorMessages;
        
        // Get Reference Members of type 'Partner & Director' for these applicants
        List<Reference_Member__c> refMembers = [
            SELECT Id, Loan_Applicant__c, Type_of_Member__c
            FROM Reference_Member__c
            WHERE Loan_Applicant__c IN :applicants
            AND Type_of_Member__c = 'Partner & Director'
        ];
        
        // Map applicant Id -> count of Partner & Director
        Map<Id, Integer> applicantPartnerCount = new Map<Id, Integer>();
        for (Reference_Member__c rm : refMembers) {
            if (!applicantPartnerCount.containsKey(rm.Loan_Applicant__c)) {
                applicantPartnerCount.put(rm.Loan_Applicant__c, 0);
            }
            applicantPartnerCount.put(rm.Loan_Applicant__c, applicantPartnerCount.get(rm.Loan_Applicant__c) + 1);
        }
        
        // Validate each applicant
        for (Loan_Applicant__c app : applicants) {
            Integer count = applicantPartnerCount.containsKey(app.Id) ? applicantPartnerCount.get(app.Id) : 0;
            if (count < 2) {
                errorMessages.add('Please add at least two Partner & Director for ' + app.Account_Name__c);
            }
        }
        
        return errorMessages;
    }
    
    
    
    
    private static Boolean hasPrimaryApplicant(Id applicationId) {
        final Integer PRIMARY_APPLICANT_REQUIRED = 1;
        SHF_LoanApplicantsSelector loanApplicantSelector = new SHF_LoanApplicantsSelector();
        Integer primaryApplicantCount = loanApplicantSelector.countPrimaryApplicantsByApplication(applicationId);
        return primaryApplicantCount >= PRIMARY_APPLICANT_REQUIRED;
    }
    
    
    @AuraEnabled(cacheable=false)
    public static String validateBeforeStageChange(Id applicationId, String currentStage,String buttonLabel) {
        List<String> errorMessages = new List<String>();
        system.debug('applicationId ' + applicationId);
        system.debug('currentStage>>>  ' + currentStage);
        Boolean isMitigantsAdded = true;
        Boolean isDeviationPending = false;
        Boolean isRejected = false;
        
        if (currentStage == 'DDE' || currentStage == 'Credit Assessment') {
            List<Deviation_and_Sanction_Condition__c> deviationList = 
                new SHF_DeviationAndSanctionSelector().selestByApplicationId(new Set<Id>{applicationId});
            if(!deviationList.isEmpty()){
                for(Deviation_and_Sanction_Condition__c deviation : deviationList){
                    if(deviation.Decision__c != SHF_ConstantsUtil.APPROVED && deviation.Is_Delete__c == false ){
                        isDeviationPending = true;
                    }
                    if(deviation.Is_Delete__c == false && deviation.Mitigants__c == null){
                        isMitigantsAdded = false;
                        
                    }
                    if(deviation.Is_Delete__c == false &&  deviation.Decision__c == 'Rejected'){
                        isRejected = true;
                    }
                }
            }
            
            if(buttonLabel == SHF_ConstantsUtil.RECOMMEND){
                
                List<Loan_Applicant__c> applicants = [
                    SELECT Id, Name, Customer_Profile__c, PF_Deducted__c, Employment_Verification_Executed__c,Employment_Verification_Invalid__c
                    FROM Loan_Applicant__c
                    WHERE Application__c = :applicationId
                ];

                // Financial Calculator re-initiation validation after sendback
                List<Loan_Applicant__c> fcChangedApplicants = [
                    SELECT Id, Name
                    FROM Loan_Applicant__c
                    WHERE Application__c = :applicationId
                    AND Financial_Calculator_Changed_After_SB__c = true
                    AND IsFinancial_Applicant__c = 'Yes'
                ];
                if (!fcChangedApplicants.isEmpty()) {
                    List<String> fcNames = new List<String>();
                    for (Loan_Applicant__c la : fcChangedApplicants) {
                        fcNames.add(la.Name);
                    }
                    errorMessages.add(
                        'Financial Calculator parameters have been modified after sendback for: '
                        + String.join(fcNames, ', ')
                        + '. Please re-initiate the Financial Calculator process before proceeding.'
                    );
                }

                String pdCompletionMessage = validatePDCompletion(applicants); // Gaurav Kumar
                //errorMessages.add(pdCompletionMessage);
                // Collect invalid applicants
                List<String> invalidApplicantNames = new List<String>();
                List<String> uanChangedApplicantNames = new List<String>();

                for (Loan_Applicant__c app : applicants) {
                    if (app.Customer_Profile__c == 'Formal Salaried'
                        && app.PF_Deducted__c == 'Yes') {

                        if (app.Employment_Verification_Invalid__c == true) {
                            uanChangedApplicantNames.add(app.Name);

                        } else if (app.Employment_Verification_Executed__c == false) {
                            invalidApplicantNames.add(app.Name);
                        }
                    }
                }

                if (!invalidApplicantNames.isEmpty()) {
                    Map<String, String> msg =
                        SHF_CommonUtil.getMessageFromMetadata('Employment_Verification_Validation');

                    errorMessages.add(
                        msg.get('Message')
                        .replace('{Applicant Name}', String.join(invalidApplicantNames, ', '))
                    );
                }

                if (!uanChangedApplicantNames.isEmpty()) {
                    Map<String, String> msg =
                        SHF_CommonUtil.getMessageFromMetadata('Employment_Verification_UAN_Changed');

                    errorMessages.add(
                        msg.get('Message')
                        .replace('{Applicant Name}', String.join(uanChangedApplicantNames, ', '))
                    );
                }

                List<Loan_Applicant__c> insApplicants = [
                    SELECT Id, Name,
                        Insurance_Verification__c,
                        Insurance_Verification__r.Status__c
                    FROM Loan_Applicant__c
                    WHERE Application__c = :applicationId
                    AND Customer_Type__c = 'Individual'
                    AND IsDeleted__c = false
                ];

                List<String> insurancePendingApplicants = new List<String>();

                for (Loan_Applicant__c la : insApplicants) {
                    // Check if lookup is missing
                    if (la.Insurance_Verification__c == null) {
                        insurancePendingApplicants.add(la.Name);
                        continue;
                    }

                    // Check if status is not Completed
                    if (la.Insurance_Verification__r == null ||
                        la.Insurance_Verification__r.Status__c != 'COMPLETED') {
                        insurancePendingApplicants.add(la.Name);
                    }
                }

                if (!insurancePendingApplicants.isEmpty()) {
                    // errorMessages.add(
                    //     'Please complete Insurance Verification for: ' +
                    //     String.join(insurancePendingApplicants, ', ')
                    // );
                }

               
                if(!isMitigantsAdded){ //added by mansur on 17-11-2025
                    Map<String, String> msg = SHF_CommonUtil.getMessageFromMetadata('No_Mitigants_added');
                    errorMessages.add(msg.get('Message'));
                }
                if (hasOpenQueries(applicationId)) {
                    Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('OPEN_QUERIES_ERROR');
                    errorMessages.add(msg.get('Message'));
                }
                if(currentStage == 'DDE'){ //added by Anand on 02/12/2025
                    Application__c application = [SELECT Id, CAM_Generation_Date_Time__c, Application_Type__c
                                                  FROM Application__c 
                                                  WHERE Id =: applicationId
                                                  LIMIT 1];
                    if(application.CAM_Generation_Date_Time__c == null){
                        errorMessages.add('Please generate the CAM before moving to the next stage.');        // Commented For Demo, Once DMS Work We Need To Uncomment The Same
                    }
                    if(application.Application_Type__c == null){
                    errorMessages.add('Please enter all mandatory fields before moving to the next stage.');
                    }
                }
                if(currentStage == 'DDE'){
                 //Added by Dimple
                List<Loan_Applicant__c> udyamApplicants = [
                    SELECT Id, Name,
                        Udyam_Verification__c,
                        Udyam_Verification__r.Is_Udyam_Registration_Verified__c,
                        Udyam_Verification__r.Is_Udyam_Advance_Verified__c
                    FROM Loan_Applicant__c
                    WHERE Application__c = :applicationId
                    AND Customer_Type__c = 'Non-Individual'
                    AND IsDeleted__c = false
                ];
                 
                List<String> udyamVerification = new List<String>();

                for (Loan_Applicant__c la : udyamApplicants) {
                    if (la.Udyam_Verification__r.Is_Udyam_Registration_Verified__c == false) {
                        udyamVerification.add(la.Name);
                        System.debug('udyamVerification' +udyamVerification);
                    }
                    if(la.Udyam_Verification__r.Is_Udyam_Advance_Verified__c == false){
                                udyamVerification.add(la.Name);
                                System.debug('udyamVerification' +udyamVerification);
                    }
                }

                if (!udyamVerification.isEmpty()) {
                    errorMessages.add('The Udyam verification is pending for: ' + String.join(udyamVerification, ', '));
                        System.debug('errorMessagesforudyam' +errorMessages);
                }
                //For Hunter
                List<Loan_Applicant__c> hunterApplicants = [
                    SELECT Id, Name,
                        Hunter_Verification__c,
                        Hunter_Verification__r.Is_Hunter_Verified__c
                    FROM Loan_Applicant__c
                    WHERE Application__c = :applicationId
                    AND Customer_Type__c = 'Individual'
                    AND IsDeleted__c = false
                ];
                 
                List<String> hunterVerification = new List<String>();

                for (Loan_Applicant__c la : hunterApplicants) {
                    if (la.Hunter_Verification__r.Is_Hunter_Verified__c == FALSE) {
                        hunterVerification.add(la.Name);
                        System.debug('hunterVerification' +hunterVerification);
                        continue;
                    }
                }

                if (!hunterVerification.isEmpty()) {
                    errorMessages.add('The Hunter verification is pending for: ' + String.join(hunterVerification, ', '));
                        System.debug('errorMessagesforHunter' +errorMessages);
                }

                if (!hasRepaymentBankingDetail(applicationId)) {
                    errorMessages.add('Repayment details are pending.');
                }
            }
                
            } else if(buttonLabel == SHF_ConstantsUtil.APPROVE){ // validaitons on approve button
                if(!isMitigantsAdded){ //added by mansur on 17-11-2025
                    Map<String, String> msg = SHF_CommonUtil.getMessageFromMetadata('No_Mitigants_added');
                    errorMessages.add(msg.get('Message'));
                    
                }
                if(isRejected){ //added by mansur on 17-11-2025
                    Map<String, String> msg = SHF_CommonUtil.getMessageFromMetadata('Rejected_Deviation');
                    errorMessages.add(msg.get('Message'));
                    
                }
                if(isDeviationPending){ //added by mansur on 17-11-2025
                    Map<String, String> msg = SHF_CommonUtil.getMessageFromMetadata('Pending_Deviation');
                    errorMessages.add(msg.get('Message'));
                    
                }
                if (hasOpenQueries(applicationId)) {
                    Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('OPEN_QUERIES_ERROR');
                    errorMessages.add(msg.get('Message'));
                }
                 Application__c applicationDetail = new SHF_ApplicationSelector().selectApplicationForCIBIL(applicationId);
                 if(applicationDetail != null){
                    if(applicationDetail.Bre_Execution_Date__c == null){
                        Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('BRE_need_to_execute');
                         errorMessages.add(msg.get('Message'));
                    }
                 }
                 if(applicationDetail.Final_Committee_Approval_Status__c == SHF_ConstantsUtil.REJECTED){ // Added by mansur on 26-12-2025 (SHF-954)
                     Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('REJECTED_COMMITTEE_APPROVAL');
                         errorMessages.add(msg.get('Message'));
                 }
                   //validation msg for collateral SHF-304
                //  List<Collateral_Application__c > collAppList= new SHF_CollateralApplicationSelector().selectByAppIds(new set<Id>{applicationId});
                //     if(collAppList.isEmpty()){
                //         Map<String,String> msg = SHF_CommonUtil.getMessageFromMetadata('not_approved_collateral');
                //        //  errorMessages.add(msg.get('Message'));
                //     }

            }
        }
        // ================= START  SHF-1224 AML VALIDATION – Added by Ranjeet Pandit =================
        if (currentStage == 'DDE' && buttonLabel == SHF_ConstantsUtil.RECOMMEND) {

            List<Loan_Applicant__c> amlApplicants = [SELECT Id, Name, AML_Verification__c, AML_Verification__r.Status__c, AML_Verification__r.Sub_Status__c FROM Loan_Applicant__c
                                                    WHERE Application__c = :applicationId AND IsDeleted__c = false];

            for (Loan_Applicant__c applicant : amlApplicants) {
        
                // AML missing or not completed
                if (applicant.AML_Verification__c == null || applicant.AML_Verification__r.Status__c != SHF_ConstantsUtil.COMPLETEDSTATUS) {
                    Map<String, String> msgMap = SHF_CommonUtil.getMessageFromMetadata('AML_Verfication_Pending_Msg');
                    errorMessages.add(msgMap.get('Message')
                                     .replace('{Applicant Name}', applicant.Name)
                    );
                }
                // AML completed but status not Green
                else if (applicant.AML_Verification__r.Sub_Status__c != 'Green') {
        
                    Map<String, String> msgMap = SHF_CommonUtil.getMessageFromMetadata('AML_Status_Validation_Msg');
                    errorMessages.add(msgMap.get('Message')
                            .replace('{Status}', applicant.AML_Verification__r.Sub_Status__c)
                            .replace('{Applicant Name}', applicant.Name)
                    );
                }
            }
        }
        if(!errorMessages.isEmpty()){
            return String.join(errorMessages, '\n');
        }
        return null;
    }
    
    //Gaurav Kumar 28-Dec-2025
    public static String validatePDCompletion(List<Loan_Applicant__c> applicants) {
		Set<Id> applicantIds = new Set<Id>(); 
        if(applicants.size() > 0){
            for(Loan_Applicant__c loanApp : applicants){
                applicantIds.add(loanApp.Id);
            } 
        }
        
        // Applicants with Completed PD
        Set<Id> completedPD = new Set<Id>();
        for (AggregateResult ar : [SELECT Loan_Applicant__c laId FROM Personal_Discussion__c
                                    WHERE Loan_Applicant__c IN :applicantIds AND PD_Activity_Status__c = 'Completed' 
                                    AND Loan_Applicant__r.Customer_Profile__c != 'Formal Salaried' AND RecordType.Name='Credit PD'
                                    GROUP BY Loan_Applicant__c]) {
            completedPD.add((Id) ar.get('laId'));
        }

        // Find missing PD
        List<String> missingNames = new List<String>();
        for (Loan_Applicant__c la : applicants) {
            if (!completedPD.contains(la.Id) && la.Customer_Profile__c != 'Formal Salaried') {
                missingNames.add(la.Name);
            }
        }

        if (!missingNames.isEmpty()) {
            return 'Personal Discussion for '
                + String.join(missingNames, ', ')
                + ' must be completed before recommending the loan application.';
        }
        return null;
    }
    //
    @AuraEnabled(cacheable=true)
    public static List<Loan_Applicant__c> validateCreditPDReInitiation(Id recordId) {

        if (recordId == null) {
            return new List<Loan_Applicant__c>();
        }

        List<Loan_Applicant__c> applicants = [
            SELECT Id, Name, Credit_PD_Changed_After_Sendback__c
            FROM Loan_Applicant__c
            WHERE Application__c = :recordId
            AND Credit_PD_Changed_After_Sendback__c = true
        ];

        return applicants.size() > 0
            ? applicants
            : new List<Loan_Applicant__c>();
    }
    private static Boolean hasRepaymentBankingDetail(Id applicationId) {
        if (applicationId == null) return false;
            Application__c app = [
            SELECT Repayment_To_Re_Trigger__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        // If re-trigger flag is true then no repayment details exist
        if (app.Repayment_To_Re_Trigger__c) {
            return false;
        }

        return [
            SELECT COUNT()
            FROM Bank_Details__c
            WHERE Application__c = :applicationId
            AND RecordType.DeveloperName = 'Repayment'
        ] > 0;
    }

    
    @AuraEnabled
    public static void createEVerificationRecords(Id applicationId) {
        if (applicationId == null) return;
        
        RecordType insuranceRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Insurance' AND SObjectType = 'E_Verification__c' LIMIT 1];
        if (insuranceRT == null) return;
        
        List<Loan_Applicant__c> applicants = [
            SELECT Id, Insurance_Verification__c 
            FROM Loan_Applicant__c 
            WHERE Application__c = :applicationId AND Insurance_Verification__c = null
        ];
        if (applicants.isEmpty()) return;
        
        List<E_Verification__c> verifications = new List<E_Verification__c>();
        for (Loan_Applicant__c la : applicants) {
            verifications.add(new E_Verification__c(
                RecordTypeId       = insuranceRT.Id,
                Loan_Application__c = applicationId,
                Loan_Applicant__c   = la.Id
            ));
        }
        
        if (!verifications.isEmpty()) {
            insert verifications;
            
            List<Loan_Applicant__c> updateApplicants = new List<Loan_Applicant__c>();
            for (E_Verification__c ev : verifications) {
                updateApplicants.add(new Loan_Applicant__c(
                    Id = ev.Loan_Applicant__c,
                    Insurance_Verification__c = ev.Id
                ));
            }
            if (!updateApplicants.isEmpty()) {
                update updateApplicants;
            }
        }
    }
     @AuraEnabled
    public static Boolean hasCollateralApplication(Id applicationId) {
    if (applicationId == null) return false;

    Integer cnt = [
        SELECT COUNT()
        FROM Collateral_Application__c
        WHERE Application__c = :applicationId
    ];
    return cnt > 0;
}
    @AuraEnabled(cacheable=true)
    public static Boolean getFieldData(Id recordId) {
        
        if (recordId == null) {
            return false;
        }
        
        // Fields from Custom Label
        List<String> fieldList =
            System.Label.Negotiation_Submission_Pending.split(',');
        String soql =
            'SELECT ' + String.join(fieldList, ',') +
            ' FROM Application__c WHERE Id = :recordId';
        
        SObject rec = Database.query(soql);
        
        for (String fieldName : fieldList) {
            Object val = rec.get(fieldName);
            if (val != null && String.valueOf(val).trim() != '') {
                return true;
            }
            
        }
        
        return false;
    }
}