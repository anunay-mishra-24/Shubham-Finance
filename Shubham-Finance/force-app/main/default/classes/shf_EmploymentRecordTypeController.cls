/**
* @File Name : shf_EmploymentRecordTypeController.cls
* @Description :
* @Author : kunal soni
* @Last Modified By :
* @Last Modified On : November 27, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 27, 2025 |   | Initial Version
**/

public with sharing class shf_EmploymentRecordTypeController {
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getEmploymentRecordTypes() {
        Map<String, String> rtMap = new Map<String, String>();
        for (RecordType rt : [
            SELECT Id, Name FROM RecordType 
            WHERE SObjectType = 'Employment__c'
        ]) {
            rtMap.put(rt.Name, rt.Id);
        }
        system.debug('rtMap--> '+rtMap);
        return rtMap;
    }
}