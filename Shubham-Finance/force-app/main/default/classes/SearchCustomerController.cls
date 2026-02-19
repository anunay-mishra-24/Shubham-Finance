/**
* @File Name : SearchCustomerController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 15, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 15, 2025 |   | Initial Version
**/
public with sharing class SearchCustomerController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> searchCustomer(String loanAppName, String mobileNumber) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        
        // Search Applications by Name
        if (String.isNotBlank(loanAppName)) {
            for (Application__c app : [
                SELECT Id, Name 
                FROM Application__c 
                WHERE Name LIKE :('%' + loanAppName + '%') 
                LIMIT 200
            ]) {
                results.add(new Map<String, Object>{
                    'Id' => app.Id,
                    'Name' => app.Name,
                    'Phone' => null,
                    'AccountName' => null,
                    'RecordType' => 'Application'
                });
            }
        }

        // Search Accounts by Phone
        if (String.isNotBlank(mobileNumber)) {
            for (Account acc : [
                SELECT Id, Name, Phone 
                FROM Account 
                WHERE Phone LIKE :('%' + mobileNumber + '%') 
                LIMIT 200
            ]) {
                results.add(new Map<String, Object>{
                    'Id' => acc.Id,
                    'Name' => null,
                    'Phone' => acc.Phone,
                    'AccountName' => acc.Name,
                    'RecordType' => 'Account'
                });
            }
        }

        return results;
    }
}