/**
* @File Name : MarkQueriesAndTasksAsCanceled.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 1, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 1, 2025 |   | Initial Version
**/

public without sharing class MarkQueriesAndTasksAsCanceled {
    
    @InvocableMethod
    public static void updateRecords(List<FlowInput> requests) {

        try {
            List<Id> appIds = new List<Id>();
            for (FlowInput req : requests) {
                if (req.applicationId != null) {
                    appIds.add(req.applicationId);
                }
            }

            if (appIds.isEmpty()) return;

            /* --------------------------
               1. Update Query__c records
            -------------------------- */
            List<Query__c> queries = [
                SELECT Id, Query_Status__c
                FROM Query__c
                WHERE Loan_Application_Number__c IN :appIds
            ];

            for (Query__c q : queries) {
                q.Query_Status__c = 'Cancel'; 
            }

            /* --------------------------
               2. Update Task records
            -------------------------- */
            List<Task> tasks = [
                SELECT Id, Status
                FROM Task
                WHERE WhatId IN :appIds
            ];

            for (Task t : tasks) {
                t.Status = 'Completed';
            }

            // Perform updates
            if (!queries.isEmpty()) {
                update queries;
            }
            if (!tasks.isEmpty()) {
                update tasks;
            }
        }
        catch (Exception ex) {
                throw new AuraHandledException('Error in MarkQueriesAndTasksAsCanceled: ' + ex.getMessage());
        }
    }

    public class FlowInput {
        @InvocableVariable(required=true)
        public Id applicationId;
    }
}