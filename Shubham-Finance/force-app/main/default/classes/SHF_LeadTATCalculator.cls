/**
* @File Name          : SHF_LeadTATCalculator.cls
* @Author             : Riteek Tiwari
* @Last Modified By   : Riteek Tiwari
* @Last Modified On   : 26-08-2025
* @Description        : This class calculates actual Escalations for Lead__c using Business Hours.
* ================================================================================================
* Update Ver         Date           Author         Modification
* ================================================================================================
* 1.0                26-08-2025     Riteek Tiwari  
*/

public with sharing class SHF_LeadTATCalculator {
    
    @InvocableMethod(label='Calculate Lead Escalations' description='Calculates L2, L3, L4 escalation dates for Lead__c')
    public static void calculateEscalations(List<Lead__c> leads) {
        if (leads == null || leads.isEmpty()) return;
        
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ Lead__c.SObjectType });
            
            // Active Business Hours Map
            Map<String, Id> bhMap = new Map<String, Id>();
            for (BusinessHours bh : [SELECT Id, Name FROM BusinessHours WHERE IsActive = true]) {
                bhMap.put(bh.Name.toLowerCase(), bh.Id);
            }
            
            // Query fresh Leads with Branch relationship (to avoid null references)
            Set<Id> leadIds = new Set<Id>();
            for (Lead__c l : leads) if (l.Id != null) leadIds.add(l.Id);
            
            Map<Id, Lead__c> leadMap = new Map<Id, Lead__c>();
            if (!leadIds.isEmpty()) {
                List<Lead__c> leadList = new SHF_LeadSelector().selectByIdsWithBranchName(leadIds);
                leadMap = new Map<Id, Lead__c>(leadList);
            }
            
            // Process Leads
            for (Lead__c l : leads) {
                if (l.Lead_Status__c == SHF_ConstantsUtil.ACTIVE_STATUS && l.LastModifiedDate != null && leadMap.containsKey(l.Id)) {
                    Lead__c leadRec = leadMap.get(l.Id);
                    
                    if (leadRec.Branch__c != null && leadRec.Branch__r != null) {
                        String bhName = 'SHDFC ' + leadRec.Branch__r.Name + ' Business Hours';
                        String bhKey = bhName.toLowerCase();
                        
                        if (bhMap.containsKey(bhKey)) {
                            Id bhId = bhMap.get(bhKey);
                            DateTime startDate = l.LastModifiedDate;
                            System.debug('startDate@ : '+ startDate);
                            System.debug('bhName@ : '+ bhName);
                            System.debug('bhId@ : '+ bhId);
                            
                            l.L2_Escalation__c = BusinessHours.addGmt(
                                bhId, startDate, Integer.valueOf(Label.Task_L2_Escalation_Milliseconds)
                            );
                            l.L3_Escalation__c = BusinessHours.addGmt(
                                bhId, startDate, Integer.valueOf(Label.Task_L3_Escalation_Milliseconds)
                            );
                            l.L4_Escalation__c = BusinessHours.addGmt(
                                bhId, startDate, Integer.valueOf(Label.Task_L4_Escalation_Milliseconds)
                            );
                            
                            Logger.info('Lead Id:- ' + l.Id + ', escalations updated → L2: ' + l.L2_Escalation__c + ', L3: ' + l.L3_Escalation__c + ', L4: ' + l.L4_Escalation__c);
                            
                            uow.registerDirty(l);
                        }
                    }
                }
            }
            uow.commitWork();
            
        } catch (Exception e) {
            Logger.error('Error in Lead Escalation Calculation: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }
}