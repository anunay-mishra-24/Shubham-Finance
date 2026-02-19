/**
 * @File Name          : SHF_TaskTATCalculator.cls
 * @Author             : Riteek Tiwari
 * @Last Modified By   : Riteek Tiwari
 * @Last Modified On   : 25-08-2025
 * @Description        : This class calculates actual Escalations for Task using Business Hours.
 * ================================================================================================
 * Update Ver         Date           Author         Modification
 * ================================================================================================
 * 1.0                25-08-2025     Riteek Tiwari  Initial Version
 */

public with sharing class SHF_TaskTATCalculator {

    @InvocableMethod(label='Calculate Task Escalations' description='Calculates L2, L3, L4 escalation dates for Tasks')
    public static void calculateEscalations(List<Task> tasks) {
        if (tasks == null || tasks.isEmpty()) return;

        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Task.SObjectType });

            Map<String, Id> bhMap = new Map<String, Id>();
            for (BusinessHours bh : [SELECT Id, Name FROM BusinessHours WHERE IsActive = true]) {
                bhMap.put(bh.Name.toLowerCase(), bh.Id);
            }

            Set<Id> leadIds = new Set<Id>();
            for (Task t : tasks) if (t.WhatId != null) leadIds.add(t.WhatId);
            Logger.info('Lead Ids: ' + leadIds);

            Map<Id, Lead__c> leadMap = new Map<Id, Lead__c>();
            if (!leadIds.isEmpty()) {
                List<Lead__c> leadList = new SHF_LeadSelector().selectByIdsWithBranchName(leadIds);
                leadMap = new Map<Id, Lead__c>(leadList);
            }
            Logger.info('Lead Map: ' + leadMap);

            // Process tasks
            for (Task t : tasks) {
                if (t.Status == SHF_ConstantsUtil.OPEN_STATUS && t.ActivityDate != null && leadMap.containsKey(t.WhatId)) {
                    Lead__c leadRec = leadMap.get(t.WhatId);
                    if (leadRec.Branch__c != null && leadRec.Branch__r != null) {
                        String bhName = 'SHDFC ' + leadRec.Branch__r.Name + ' Business Hours';
                        String bhKey = bhName.toLowerCase();

                        if (bhMap.containsKey(bhKey)) {
                            Id bhId = bhMap.get(bhKey);
                            DateTime startDate = t.ActivityDate.addDays(1);

                            t.L2_Escalation__c = BusinessHours.addGmt(
                                bhId, startDate, Integer.valueOf(Label.Task_L2_Escalation_Milliseconds)
                            );
                            t.L3_Escalation__c = BusinessHours.addGmt(
                                bhId, startDate, Integer.valueOf(Label.Task_L3_Escalation_Milliseconds)
                            );
                            t.L4_Escalation__c = BusinessHours.addGmt(
                                bhId, startDate, Integer.valueOf(Label.Task_L4_Escalation_Milliseconds)
                            );

                            Logger.info('Task Id:- ' + t.Id + ', escalations updated → L2: ' + t.L2_Escalation__c + ', L3: ' + t.L3_Escalation__c + ', L4: ' + t.L4_Escalation__c);

                            uow.registerDirty(t);
                        }
                    }
                }
            }
            uow.commitWork();

        } catch (Exception e) {
            Logger.error('Error in Task Escalation Calculation: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }
}