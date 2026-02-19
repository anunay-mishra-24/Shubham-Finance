/**
* @File Name : SHF_SpecialConditionTabController.cls
* @Description : Handles creation, update and retrieval of Special Conditions linked to an Application.This controller is used by the Special Condition LWC tab.
* @Author : Preeti
* @Last Modified By :
* @Last Modified On : December 16, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 16, 2025 | Preeti   | Initial Version
**/

public without sharing class SHF_SpecialConditionTabController {
    private static final logger logger = new logger(SHF_SpecialConditionTabController.class);
    
    @AuraEnabled
    public static void requestStatusChange(List<Id> conditionIds, String requestedStatus) {
        if (conditionIds == null || conditionIds.isEmpty()) {
            logger.error('Missing condition Ids');
            throw new AuraHandledException('Condition Ids are required');
        }
        if (String.isBlank(requestedStatus)) {
            logger.error('Missing requested status');
            throw new AuraHandledException('Requested status is required');
        }
        
        logger.info('Requesting status change for ' + conditionIds.size() + ' conditions to ' + requestedStatus);
        
        List<Document__c> conditionsToUpdate = new List<Document__c>();
        for (Id conditionId : conditionIds) {
            Document__c doc = new Document__c(Id = conditionId);
            doc.Sanction_Condition_Status__c = 'Approval Pending';
            // Assuming Requested_Status__c is a field on the Document__c object
            // If this field does not exist, this line will cause a runtime error.
            doc.Requested_Status__c = requestedStatus;
            conditionsToUpdate.add(doc);
        }
        
        try {
            update conditionsToUpdate;
            logger.info('Successfully requested status change for ' + conditionsToUpdate.size() + ' conditions');
        } catch (DmlException e) {
            logger.error('Failed to request status change: ' + e.getMessage());
            throw new AuraHandledException('Failed to request status change: ' + e.getMessage());
        }
    }
    
    /*
* Creates a new Special Condition document for the given Application.
*
* @param applicationId        Id of the Application record
* @param typeOfCondition      Selected type of condition
* @param conditionDescription Description entered by the user
* @param comment              Additional comments (optional)
* @return Id                  Newly created Document record Id
*/
    
    @AuraEnabled
    public static Id createSpecialCondition(Id applicationId, String typeOfCondition, String conditionDescription, String comment, String verificationId) {
        if (applicationId == null) {
            logger.error('Missing Application Id');
            throw new AuraHandledException('Application Id is required');
        }
        
        logger.info('Creating Special Condition for Application Id: ' + applicationId);
        Document__c doc = new Document__c();
        
        // Attach Application
        doc.Application__c = applicationId;
        // Attach Verification
        doc.Verification__c = verificationId;
        
        // User input
        doc.Type_Of_Condition__c = typeOfCondition;
        doc.Condition_Description__c = conditionDescription;
        doc.Comment__c = comment;
        
        // Backend
        doc.Type__c = 'Special Condition';
        Sanction_Condition_Master__c scm;
        doc.Document_Category__c = 'Loan Specific Documents';

        List<Sanction_Condition_Master__c> scmList = [
            SELECT Id, Condition_Category__c
            FROM Sanction_Condition_Master__c
            WHERE Type__c = :typeOfCondition
            AND Query_Sub_Cat__c = :conditionDescription
            LIMIT 1
        ];

        if (!scmList.isEmpty()) {
            scm = scmList[0];

            String formattedCategory = scm.Condition_Category__c;
            if (formattedCategory != null) {
                formattedCategory = formattedCategory
                    .replaceAll('\\s*/\\s*', '_')
                    .replaceAll('\\s*-\\s*', '_')
                    .trim();
            }

            doc.File_Name__c = formattedCategory;
            doc.Sanction_Condition_Master__c = scm.Id;
        } else {
            // Fallback (important to avoid null File Name)
            doc.File_Name__c = typeOfCondition;
        }
        // doc.Sanction_Condition_Status__c = 'Pending';
        
        try {
            insert doc;
            logger.info('Special Condition created successfully. Document Id: ' + doc.Id);
            return doc.Id;
        } catch (DmlException e) {
            logger.error('Failed to create Special Condition: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
    
    
    /*
* Fetches all Special Conditions for the given Application.
*
* @param applicationId Id of the Application record
* @return List<Document__c> List of Special Condition documents
*/
    
    @AuraEnabled(cacheable=true)
    public static List<Document__c> getSpecialConditions(Id applicationId) {
        if (applicationId == null) {
            logger.error('Fetch Special Conditions failed: Application Id is missing');
            throw new AuraHandledException('Application Id is required');
        }
        logger.info('Fetching Special Conditions for Application Id: ' + applicationId);
        return [SELECT Id, Name, Type_Of_Condition__c,Document_Category__c,File_Name__c, Condition_Description__c, Comment__c, Status__c, Sanction_Condition_Status__c, CreatedById FROM Document__c WHERE Application__c = :applicationId AND Type__c = 'Special Condition' ORDER BY CreatedDate DESC];
    }
    
    
    
    /*
* Updates an existing Special Condition document.
* Only provided fields are updated.
*
* @param recordId             Id of the Document record
* @param typeOfCondition      Updated type of condition
* @param conditionDescription Updated description
* @param comment              Updated comments
*/
    
    @AuraEnabled
    public static void updateSpecialCondition( Id recordId, String typeOfCondition, String conditionDescription, String comment) {
        if (recordId == null) {
            logger.error('updateSpecialCondition | Missing Document Id');
            throw new AuraHandledException('Missing Document Id');
        }
        logger.info('Updating Special Condition. Document Id: ' + recordId);
        
        try {
            Document__c doc = [SELECT Id, Type_Of_Condition__c, Condition_Description__c, Comment__c FROM Document__c WHERE Id = :recordId LIMIT 1
                              ];
            
            // ---------- Update fields ----------
            if (String.isNotBlank(typeOfCondition)) {
                doc.Type_Of_Condition__c = typeOfCondition;
            }
            
            if (String.isNotBlank(conditionDescription)) {
                doc.Condition_Description__c = conditionDescription;
            }
            
            doc.Comment__c = comment; 
            
            update doc;
            
            logger.info('Special Condition updated successfully. Document Id: ' + recordId);
            
        } catch (Exception e) {
            logger.error( 'updateSpecialCondition | Failed to update Document | recordId=' + recordId + ' | ' + e.getMessage() );
            throw new AuraHandledException('Unable to update record.');
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getConditionDescriptions(String typeOfCondition) {
        
        List<String> conditionDescriptions = new List<String>();
        if (String.isBlank(typeOfCondition)) {
            return conditionDescriptions;
        }
        
        List<Sanction_Condition_Master__c> masters = [SELECT Query_Sub_Cat__c FROM Sanction_Condition_Master__c WHERE Type__c = :typeOfCondition AND Query_Sub_Cat__c != null ORDER BY Query_Sub_Cat__c];
        
        
        for (Sanction_Condition_Master__c scm : masters) {
            conditionDescriptions.add(scm.Query_Sub_Cat__c);
        }
        
        return conditionDescriptions;
    }
    
    
    
    public class UserAccessWrapper {
        @AuraEnabled public Boolean canChangeStatus;
    }

    @AuraEnabled(cacheable=true)
    public static UserAccessWrapper getUserAccessInfo(Id applicationId) {
        UserAccessWrapper access = new UserAccessWrapper();
        access.canChangeStatus = false; 

        
        List<PermissionSetAssignment> psa = [
            SELECT PermissionSet.Name 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :UserInfo.getUserId() 
            AND PermissionSet.Name = 'Admin_Permission_Set'
            LIMIT 1
        ];

        if (!psa.isEmpty()) {
            access.canChangeStatus = true;
            return access; 
        }

        
        String userRoleId = UserInfo.getUserRoleId();
        if (userRoleId != null) {
            UserRole userRole = [SELECT Name FROM UserRole WHERE Id = :userRoleId];
            if (userRole.Name == 'Regional Marketing') {
                access.canChangeStatus = true;
                return access; 
            }
        }

        
        if(applicationId != null) {
            try {
                List<Application__c> apps = [SELECT OwnerId FROM Application__c WHERE Id = :applicationId];
                if (!apps.isEmpty() && apps[0].OwnerId == UserInfo.getUserId()) {
                    access.canChangeStatus = true;
                    return access;
                }
            } catch (QueryException e) {
                System.debug('Could not query Application__c: ' + e.getMessage());
            }
        }

        return access;
    }

    public class logger {
        private String className;
        public logger(Type t) {
            this.className = t.getName();
        }
        public void error(String msg) {
            System.debug(System.LoggingLevel.ERROR, className + ': ' + msg);
        }
        public void info(String msg) {
            System.debug(System.LoggingLevel.INFO, className + ': ' + msg);
        }
    }


    @AuraEnabled(cacheable=true)
public static Document__c getDocumentByFileName(
    Id applicationId,
    String fileName
) {
    return [
        SELECT Id, Name, File_Name__c
        FROM Document__c
        WHERE Application__c = :applicationId
        AND File_Name__c = :fileName
        LIMIT 1
    ];
}




}