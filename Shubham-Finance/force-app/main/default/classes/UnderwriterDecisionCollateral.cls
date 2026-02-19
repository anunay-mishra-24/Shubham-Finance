/**
 * @File Name          : UnderwriterDecisionCollateral.cls
 * @Description        : Show the required fields into Data table for Under Writer decision Screen.
 * @Author             :Anunay Kumar
 *
 *==============================================================================
 * Ver         Date                     Author                 Modification
 *==============================================================================
 * 1.0         2025-01-05           Anunay Kumar         Initial Version
 */

public with sharing class UnderwriterDecisionCollateral {
    @AuraEnabled(cacheable=true)
    public static List<Collateral_Application__c> getCollaterals(Id applicationId) {
        try {
            if (applicationId == null) return new List<Collateral_Application__c>();

            return [
                SELECT Id, Name,
                       Collateral_Address__c,
                       LTV__c,
                       Cost_of_property__c,
                       Market_Value__c
                FROM Collateral_Application__c
                WHERE Application__c = :applicationId
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
           
            throw new AuraHandledException('Failed to load collateral details: ' + e.getMessage());
        }
    }
}