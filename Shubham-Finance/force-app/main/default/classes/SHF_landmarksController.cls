/**
* @File Name : SHF_landmarksController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 15, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 15, 2025 |   | Initial Version
**/

	public with sharing class SHF_landmarksController {
   @AuraEnabled
    public static List<Address__c> updateAddressLocation(Id recordId, Decimal latitude, Decimal longitude) {
        List<Address__c> addressRecord = [SELECT Id, Address_Location__Latitude__s, Address_Location__Longitude__s FROM Address__c WHERE Id = :recordId LIMIT 1];
        addressRecord[0].Address_Location__Latitude__s = latitude;
        addressRecord[0].Address_Location__Longitude__s = longitude;
        update addressRecord[0];
        return addressRecord;
    }
}