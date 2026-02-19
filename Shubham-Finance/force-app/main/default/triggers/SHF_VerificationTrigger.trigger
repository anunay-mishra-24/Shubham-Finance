/**
* @File Name : SHF_VerificationTrigger.cls
* @Description :
* @Author : Anand
* @Last Modified By :
* @Last Modified On : December 30, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 30, 2025 |   | Initial Version
**/

trigger SHF_VerificationTrigger on Verification__c (after update) {
    
    if(Trigger.isAfter && Trigger.isUpdate){
        for(Verification__c ver : Trigger.new){
            Verification__c oldVer = Trigger.oldMap.get(ver.Id);
            
            if(ver.FCU_Manager_Decision__c != oldVer.FCU_Manager_Decision__c
            && ver.FCU_Manager_Decision__c != null){
                
                SHF_RCUBusinessRuleEngine.executeRCUBusinessRules(ver.Id);
            }
        }
    }
}