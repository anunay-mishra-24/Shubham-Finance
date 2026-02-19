public with sharing class AddressValidationService {

    /**
     * @description Validates address rules based on Copy_Address_From__c, Residence, and Permanent flags.
     * @param addressRecord - The Address__c record to validate (unsaved or in-progress)
     * @throws AuraHandledException if validation fails
     */
    @AuraEnabled
    public static void validateAddress(Address__c addressRecord) {
        // Proceed only when address is copied from "Current Address"
        if (addressRecord.Copy_Address_From__c == 'Current Address') {

            //  Validate Residence Address
            if (addressRecord.Current_Address_same_as_Residence__c == 'Yes' 
                && addressRecord.Mailing_Address__c == 'Residential Address') {
                
                List<Address__c> existingAddresses = getAddressesByApplicant(addressRecord.Loan_Applicant__c);
                for (Address__c existing : existingAddresses) {
                    if (existing.Mailing_Address__c == 'Residential Address' && existing.Id != addressRecord.Id) {
                        throw new AuraHandledException('Residence address already exist.');
                    }
                }
                addressRecord.OVD__c = true;
            }

            // Validate Permanent Address
            if (addressRecord.Residence_same_as_Permanent_Address__c == true 
                && addressRecord.Mailing_Address__c == 'Permanent Address') {
                
                List<Address__c> existingAddresses = getAddressesByApplicant(addressRecord.Loan_Applicant__c);
                for (Address__c existing : existingAddresses) {
                    if (existing.Mailing_Address__c == 'Permanent Address' && existing.Id != addressRecord.Id) {
                        throw new AuraHandledException('Permanent address already exist.');
                    }
                }
                addressRecord.OVD__c = true;
            }
        }
    }

    /**
     * @description Fetch all Address__c records related to a Loan Applicant.
     */
    @AuraEnabled(cacheable=true)
    public static List<Address__c> getAddressesByApplicant(Id loanApplicantId) {
        if (loanApplicantId == null) return new List<Address__c>();
        return [
            SELECT Id, Mailing_Address__c, OVD__c
            FROM Address__c
            WHERE Loan_Applicant__c = :loanApplicantId
        ];
    }
}