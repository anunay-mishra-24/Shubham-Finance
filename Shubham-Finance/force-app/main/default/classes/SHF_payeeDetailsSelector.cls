/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_payeeDetailsSelector
 * Author          : <YourName>
 * Created Date    : Feb 8, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Feb 8, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Feb 8, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
	public class SHF_payeeDetailsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
            Payee_Details__c.Id,
               Payee_Details__c.Account_Number__c,
			   Payee_Details__c.AdjustmentAmount__c,
			   Payee_Details__c.BankValidationStatus__c,
			   Payee_Details__c.BeneficiaryAccountNumber__c,
			  Payee_Details__c.BeneficiaryAccountType__c,
			   Payee_Details__c.BeneficiaryName__c,
			  Payee_Details__c.BusinessPartnerNameApplicantName__c,
			   Payee_Details__c.BusinessPartnerTypeApplicantType__c,
			   Payee_Details__c.Customer_Bank__c,
			   Payee_Details__c.DisbursalAmount__c,
			   Payee_Details__c.Disbursement__c,
			   Payee_Details__c.EffectivePaymentDate__c,
			   Payee_Details__c.IFSC_Code__c,
			   Payee_Details__c.InFavourOf__c,
			   Payee_Details__c.InstrumentDate__c,
			   Payee_Details__c.Instrument_Number__c,
			   Payee_Details__c.Name,
			   Payee_Details__c.Payee_Name__c,
			   Payee_Details__c.Payment_Amount__c,
			   Payee_Details__c.Printing_Branch__c,
			   Payee_Details__c.SubPaymentMode__c,
			   Payee_Details__c.TypeOfPaymentMode__c
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return Payee_Details__c.SObjectType; 
    }
    
   public List<Payee_Details__c> selectByIdsDisbId(Set<Id> disbId) {
    fflib_QueryFactory query = newQueryFactory();
    
    query.setCondition('Disbursement__c IN :disbId');
	  query.setCondition('Is_Deleted__c = false');
    query.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
    
    return (List<Payee_Details__c>) Database.query(query.toSOQL());
}

}