/**
* @File Name          : SHF_DocumentsSelector.cls
* @Description        : This class is used to fetch/query Document__c records based on conditions.
* @Author             : Riteek Tiwari
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         07-07-2025              Riteek Tiwari          
*/
//Added by Ranjeet without sharing for Public Site Upload Documents
public without sharing class SHF_DocumentsSelector extends fflib_SObjectSelector {
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
            Document__c.Id,
                 Document__c.Document_Category__c,
                  Document__c.Status__c,
                   Document__c.Requested_Status__c,
                    Document__c.Activity_History__c,
                     Document__c.Sanction_Condition_Status__c,
                      Document__c.Type__c,
                       Document__c.Condition_Description__c,
                        Document__c.Comment__c,
                Document__c.Name
                }; 
                    }
    public Schema.SObjectType getSObjectType() { 
        return Document__c.SObjectType; 
    }
    
    public List<Document__c> selectByIdsApplicantName(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Name'); // Add other fields you need
        query.selectField('File_Name__c');
        query.setCondition('Id IN :recordIds');
        return (List<Document__c>) Database.query(query.toSOQL());
    }
    
    /**
* Method to select documents by document category
* @param docCategory - The document category to filter by
* @return List of Document__c records
*/
    public List<Document__c> selectByDocumentCategory(String docCategory) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Document_Category__c = :docCategory');
        return (List<Document__c>) Database.query(query.toSOQL());
    }
      public List<Document__c> selectByApplicationId(Set<Id> applicationId) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Name'); // Add other fields you need
        query.setCondition('Application__c  IN :applicationId');
        return (List<Document__c>) Database.query(query.toSOQL());
    }

    //Added by mansur for SHF-1562
     public List<Document__c> selectByApplicationIdAndActivityId(Set<Id> applicationId,Set<Id> activityHistoryId) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Name'); // Add other fields you need
        query.setCondition('Application__c  IN :applicationId AND Activity_History__c IN :  activityHistoryId');
        return (List<Document__c>) Database.query(query.toSOQL());
    }

    public List<Document__c> selectByDocIds(Set<Id> docIds) {
        fflib_QueryFactory query = newQueryFactory();
         query.selectField('Sanction_Condition_Master__r.Deviation_Level__c'); 
        query.setCondition('Id IN :docIds');
        return (List<Document__c>) Database.query(query.toSOQL());
    }

    public List<Document__c> selectByActivityHistoryIds(Set<Id> activityHostoryId) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Activity_History__c IN :activityHostoryId AND Sanction_Condition_Status__c =\'Approval Pending\'');
        return (List<Document__c>) Database.query(query.toSOQL());
    }
}