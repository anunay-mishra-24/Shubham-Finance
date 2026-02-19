/**
 * @Author      : Riteek Tiwari
 * @Date        : 2025-11-04
 * @Description : Selector class for Charge_Master__c records.
 */
public with sharing class SHF_ChargeMasterSelector extends fflib_SObjectSelector {

    // Return list of fields used commonly for querying Charge_Master__c
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Charge_Master__c.Id,
            Charge_Master__c.Name,
            Charge_Master__c.Amount_Based__c,
            Charge_Master__c.Lower_Range__c,
            Charge_Master__c.Upper_Range__c,
            Charge_Master__c.Login_Fee__c,
            Charge_Master__c.Fees_Name__c,
            Charge_Master__c.Product_Type__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return Charge_Master__c.sObjectType;
    }

    public List<Charge_Master__c> selectByLoanAmount(Decimal appliedLoanAmount, List<String> productTypes) {
        if (appliedLoanAmount == null) {
            System.debug('Applied loan amount is null. Returning empty list.');
            return new List<Charge_Master__c>();
        }

        if (productTypes == null || productTypes.isEmpty()) {
            productTypes = new List<String>{ 'Home Loan', 'Housing Loan' };
        }

        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Product_Type__c IN :productTypes ' +
                           'AND Lower_Range__c <= :appliedLoanAmount ' +
                           'AND Upper_Range__c >= :appliedLoanAmount ' +
                           'AND Fees_Name__c != NULL');
        query.setLimit(1);

        System.debug('Running SOQL: ' + query.toSOQL());
        return (List<Charge_Master__c>) Database.query(query.toSOQL());
    }
}