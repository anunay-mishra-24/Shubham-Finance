/**
* @File Name : SHF_RCUBusinessRuleEngine.cls
* @Description :  this class is used for maintaining status of Sampled Documents.
* @Author :  Kuldeep Sahu
* @Last Modified On : Dec 29, 2025
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | Dec 29, 2025 | Kuldeep Sahu  | Initial Version
**/

public with sharing class SHF_RCUBusinessRuleEngine {
    public static Map<String, String> roleMap = new Map<String, String>{
        'HFCU' => 'Head-Fraud Control & Investigations',
            'HCS' => 'Head -Credit and Service',
            'ACM' => 'Area Credit Manager',
            'RCURM' => 'RCU Regional Manager',
            'RCUZM' => 'RCU Zonal Manager',
            'RCUSH' => 'RCU State Head'
            };
                
                // method to execute BRE for RCU
                public static void executeRCUBusinessRules(String recordId){
                    List<Verification__c> verificationRecord = [SELECT 
                                                                Id, Application__c, FCU_Manager_Decision__c, Type__c,
                                                                Application__r.Branch__c
                                                                FROM Verification__c
                                                                WHERE Id =: recordId
                                                                LIMIT 1];
                    if(!verificationRecord.isEmpty()) {                                                                                
                        String type = verificationRecord.get(0).Type__c == 'Seller' ? 'Seller RCU' : 'Borrower RCU';
                        List<Deviation_Master__c> deviationMaster = [SELECT
                                                                     Id, Deviation__c, Approving_Authority__c, Department__c,
                                                                     Deviation_Description__c, Mitigant_Code__c, Mitigant_Name__c,
                                                                     Product__c, Source__c, Type_Of_Deviation__c
                                                                     FROM Deviation_Master__c
                                                                     WHERE RecordType.Name = 'Deviation'
                                                                     AND Type_Of_Deviation__c = 'Application'
                                                                     AND Department__c =: type
                                                                     AND Source__c = 'System'
                                                                     AND Active__c = true];
                        Map<String, Deviation_Master__c> deviationMap = new Map<String, Deviation_Master__c>();                                                        
                        for(Deviation_Master__c devMaster : deviationMaster){
                            deviationMap.put(devMaster.Deviation__c, devMaster);
                        }                                                        
                        
                        List<Deviation_and_Sanction_Condition__c> existingDeviations = [SELECT Id
                                                                                        FROM Deviation_and_Sanction_Condition__c
                                                                                        WHERE Decision__c = 'Sent For Review'
                                                                                        AND Deviations__c IN : deviationMaster];
                        if(!existingDeviations.isEmpty()) {
                            DELETE existingDeviations;
                        }
                        Map<String, Set<String>> roleUserMap = findApprovalAuthority(verificationRecord.get(0).Application__r.Branch__c);
                        if(verificationRecord.get(0).Type__c == 'Seller') {
                            if(verificationRecord.get(0).FCU_Manager_Decision__c == 'RCU Not Recommended' || verificationRecord.get(0).FCU_Manager_Decision__c == 'Negative') {
                                createDeviationRecord(verificationRecord.get(0).Application__c, verificationRecord.get(0).Id, deviationMap.get('Not Recommended / Negative'), roleUserMap);
                            } else if(verificationRecord.get(0).FCU_Manager_Decision__c == 'RCU Refer to Credit' || verificationRecord.get(0).FCU_Manager_Decision__c == 'RCU Failed') {
                                createDeviationRecord(verificationRecord.get(0).Application__c, verificationRecord.get(0).Id, deviationMap.get('Refer to Credit / Failed'), roleUserMap);
                            }
                        } else if(verificationRecord.get(0).Type__c == 'Borrower') {
                            if(verificationRecord.get(0).FCU_Manager_Decision__c == 'RCU Not Recommended') {
                                createDeviationRecord(verificationRecord.get(0).Application__c, verificationRecord.get(0).Id, deviationMap.get('Not Recommended'), roleUserMap);
                            } else if(verificationRecord.get(0).FCU_Manager_Decision__c == 'Negative') {
                                createDeviationRecord(verificationRecord.get(0).Application__c, verificationRecord.get(0).Id, deviationMap.get('Negative'), roleUserMap);
                            } else if(verificationRecord.get(0).FCU_Manager_Decision__c == 'RCU Refer to Credit' || verificationRecord.get(0).FCU_Manager_Decision__c == 'RCU Failed'){
                                createDeviationRecord(verificationRecord.get(0).Application__c, verificationRecord.get(0).Id, deviationMap.get('Refer to Credit / Failed'), roleUserMap);
                            }
                        }
                    }
                }
    
    // method to create Deviation and Activity History records
    public static void createDeviationRecord(String applicationId, String verificationId, Deviation_Master__c dvRecord, Map<String, Set<String>> roleUserMap){        
        if(dvRecord != null){
            SHF_BusinessRuleEngine obj = new SHF_BusinessRuleEngine();
            Deviation_and_Sanction_Condition__c createdDeviaiton = new Deviation_and_Sanction_Condition__c();
            createdDeviaiton.Decision__c = SHF_ConstantsUtil.PENDING;
            createdDeviaiton.Deviation_Description__c = dvRecord.Deviation_Description__c;
            createdDeviaiton.Deviations__c = dvRecord.Id;
            createdDeviaiton.External_Key__c = dvRecord.Deviation__c;
            createdDeviaiton.Is_Delete__c = false;
            createdDeviaiton.Mitigants__c = null;
            createdDeviaiton.Loan_Application__c = applicationId;
            createdDeviaiton.Type__c = SHF_ConstantsUtil.DEVIATION;
            createdDeviaiton.Verification__c = verificationId;
            createdDeviaiton.Approving_Authority__c = dvRecord.Approving_Authority__c;
            INSERT createdDeviaiton;
            List<Activity_History__c> actHistoryList = new List<Activity_History__c>();
            Set<String> allApproverIds = new Set<String>();
            for(String roleName : dvRecord.Approving_Authority__c.split(';')) {
                String roleNameFull = roleMap.get(roleName);
                if(roleUserMap.containsKey(roleName)){
                    Set<String> userIds = roleUserMap.get(roleName);
                    allApproverIds.addAll(userIds);
                    for(String userId : userIds) {
                        Activity_History__c actHistory = new Activity_History__c ();
                        actHistory.OwnerId  = userId;
                        actHistory.RecordTypeId = SHF_ConstantsUtil.ACTIVITY_HISTORY_FOR_COMMITTEE_RECORDTYPEID;
                        actHistory.Committee_Approval_Status__c = 'Pending';
                        actHistory.Application__c = applicationId;
                        actHistory.Comments__c = '';
                        actHistory.Deviation__c = createdDeviaiton.Id;
                        actHistoryList.add(actHistory);
                    }
                    createdDeviaiton.Approvers__c = userIds.toString();
                }        
            }           
            UPDATE createdDeviaiton;
            if(!actHistoryList.isEmpty()) {
                INSERT actHistoryList;
            }
            // ================= Bell Notification =================
            if(!allApproverIds.isEmpty()){
                String bellTitle = System.Label.Deviation_Approval_Assignment_Title;
                String bellBody = System.Label.Deviation_Approval_Assignment_Body.replace('{Application ID}', applicationId);
                
                SHF_CommonUtil.notifyUsersByNotification(
                    allApproverIds,
                    createdDeviaiton.Id,
                    bellTitle,
                    bellBody,
                    'Send_Notification_To_User'
                );
            }
            
            // ================= Email Notification =================
            if(!allApproverIds.isEmpty()){
                // Bulk fetch emails for all approvers
                List<User> approvers = [SELECT Id, Email FROM User WHERE Id IN :allApproverIds AND Email != null];
                List<String> recipientEmails = new List<String>();
                for(User u : approvers) {
                    recipientEmails.add(u.Email);
                }
                
                if(!recipientEmails.isEmpty()){
                    // Build Email Body
                    String emailBody = 'A New Deviation record has been assigned to you\n\n' +
                        'Application Number : ' + applicationId + '\n' +
                        'Deviation ID : ' + createdDeviaiton.Id + '\n' +
                        'Current Stage : ' + createdDeviaiton.Loan_Application__r.Application_Stage__c + '\n' +
                        'Current Sub-stage : ' + createdDeviaiton.Loan_Application__r.Application_Status__c + '\n\n' +
                        'Thank you,\nShubham Housing Finance Development';
                    
                    String emailSubject = System.Label.Deviation_Assignment_Email_Subject;
                    
                    List<Messaging.SingleEmailMessage> emailsToSend = SHF_CommonUtil.notifyUsersByEmail(
                        recipientEmails,
                        emailBody,
                        emailSubject
                    );
                    
                    if(!emailsToSend.isEmpty()){
                        Messaging.sendEmail(emailsToSend);
                    }
                }
            }
            
        }
    }
    
    // Method to find Approval Authority
    public static Map<String, Set<String>> findApprovalAuthority(String branchId){
        Set<String> userIds = new Set<String>();
        List<Branch_Mapping__c> userBranchMapping = [SELECT 
                                                     Internal_User__c
                                                     FROM Branch_Mapping__c
                                                     WHERE Branch_Master__c =: branchId];
        for(Branch_Mapping__c branchMapping : userBranchMapping) {
            userIds.add(branchMapping.Internal_User__c);
        }
        List<User> users = [SELECT
                            Id, Name, UserRole.Name
                            FROM User
                            WHERE Id IN : userIds];
        Map<String, Set<String>> roleUserIdMap = new Map<String, Set<String>>();
        for(User userRec : users) {
            if(!roleUserIdMap.containsKey(userRec.UserRole.Name)) {
                roleUserIdMap.put(userRec.UserRole.Name, new Set<String>());            
            }
            roleUserIdMap.get(userRec.UserRole.Name).add(userRec.Id);
        }
        return roleUserIdMap;
    }
}