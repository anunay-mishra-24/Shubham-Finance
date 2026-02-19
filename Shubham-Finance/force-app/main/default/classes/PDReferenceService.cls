/**
* @File Name : PDReferenceService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 11, 2025 |   | Initial Version
**/

public class PDReferenceService {
    // Wrapper class matching the user's provided class
    public class PDRefrenceWrapper {
        @AuraEnabled public String uid;
        @AuraEnabled public String type;
        @AuraEnabled public String contact;
        @AuraEnabled public String nature;
        @AuraEnabled public String value;
        @AuraEnabled public String frequency;
        @AuraEnabled public String doingSince;
        @AuraEnabled public String creditPeriod;
        @AuraEnabled public Id sfId;
    }

    // --- FETCH ---
    @AuraEnabled
    public static List<PDRefrenceWrapper> getSuplierReferences(String parentRecordId) {
        List<PDRefrenceWrapper> results = new List<PDRefrenceWrapper>();
        if (parentRecordId == null) return results;

		List<PD_Reference__c> pdList = [SELECT Id, Personal_Discussion__c, contact_address_details__c, Customer_Type__c, 
										nature_of_transaction__c, value_of_transaction__c, frequency_of_transaction__c, 
										doing_business_since_when__c, credit_period__c 
										FROM PD_Reference__c 
										WHERE Personal_Discussion__c = :parentRecordId AND Customer_Type__c='Supplier'];

        for (PD_Reference__c r : pdList) {
            PDRefrenceWrapper w = new PDRefrenceWrapper();
            w.sfId = r.Id;
            w.type = r.Customer_Type__c;
            w.contact = r.contact_address_details__c;
            w.nature = r.nature_of_transaction__c;
            w.value = r.value_of_transaction__c == null ? null : String.valueOf(r.value_of_transaction__c);
            w.frequency = r.frequency_of_transaction__c;
            w.doingSince = r.doing_business_since_when__c;
            w.creditPeriod = r.credit_period__c;
            results.add(w);
        }
        return results;
    }
	@AuraEnabled
    public static List<PDRefrenceWrapper> getCustomerReferences(String parentRecordId) {
        List<PDRefrenceWrapper> results = new List<PDRefrenceWrapper>();
        if (parentRecordId == null) return results;

		List<PD_Reference__c> pdList = [SELECT Id, Personal_Discussion__c, contact_address_details__c, Customer_Type__c, 
										nature_of_transaction__c, value_of_transaction__c, frequency_of_transaction__c, 
										doing_business_since_when__c, credit_period__c 
										FROM PD_Reference__c 
										WHERE Personal_Discussion__c = :parentRecordId AND Customer_Type__c='Customer'];

        for (PD_Reference__c r : pdList) {
            PDRefrenceWrapper w = new PDRefrenceWrapper();
            w.sfId = r.Id;
            w.type = r.Customer_Type__c;
            w.contact = r.contact_address_details__c;
            w.nature = r.nature_of_transaction__c;
            w.value = r.value_of_transaction__c == null ? null : String.valueOf(r.value_of_transaction__c);
            w.frequency = r.frequency_of_transaction__c;
            w.doingSince = r.doing_business_since_when__c;
            w.creditPeriod = r.credit_period__c;
            results.add(w);
        }
        return results;
    }

    // --- DELETE ---
    @AuraEnabled
    public static void deleteReference(Id sfId) {
        if (sfId == null) {
            throw new AuraHandledException('Missing id to delete');
        }
        try {
        SObjectType sObjType = sfId.getSObjectType();
        SObject recordToDelete = sObjType.newSObject(sfId);

        delete recordToDelete;

    } catch (Exception e) {
        throw new AuraHandledException(
            'Failed to delete record: ' + e.getMessage()
        );
    }
    }

 @AuraEnabled
public static Boolean checkDMSRequiredDoc(String pdRecordId) {
    Boolean isRequired = true;

    // Fetch PD record safely
    Personal_Discussion__c pdRec = [SELECT Id, Loan_Applicant__c FROM Personal_Discussion__c
                                    WHERE Id = :pdRecordId AND Loan_Applicant__c != null LIMIT 1 ];

    List<Document__c> docRecList = [SELECT Id FROM Document__c WHERE Loan_Applicant__c = :pdRec.Loan_Applicant__c
                                    AND Document_Category__c = 'Others' ];

    if (docRecList.size() >= 1) {
        isRequired = false;
    }

    return isRequired;
}

}