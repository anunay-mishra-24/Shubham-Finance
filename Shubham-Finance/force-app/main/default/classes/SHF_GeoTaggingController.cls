/**
* @File Name : SHF_GeoTaggingController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 19, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 19, 2025 |   | Initial Version
**/

public class SHF_GeoTaggingController {
	@AuraEnabled
public static void saveLocation(Id recordId, String latitude,String longitude) {
    try {
        Logger.info('recordId=' + recordId +'latitude=' + latitude +'longitude=' + longitude);

        Verification_Activity__c act = new Verification_Activity__c(
            Id = recordId,
            Latitude__c = latitude,
            Longitude__c = longitude,
            Geo_Location_Tagged_On__c = System.now(),
            Geo_Location_Tagged_By__c = UserInfo.getUserId()
        );

        update act;

        Logger.info('saveLocation completed successfully recordId=' + recordId);

    } catch (Exception e) {
        Logger.error('saveLocation failed | recordId=' + recordId +' errorMessage=' + e.getMessage() + ' stackTrace=' + e.getStackTraceString());

        throw new AuraHandledException('Unable to save location. Please try again.');
    }
}


}