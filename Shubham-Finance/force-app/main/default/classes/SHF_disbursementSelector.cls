/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_disbursementSelector
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
	public class SHF_disbursementSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
            Disbursement__c.Id,
               Disbursement__c.Actual_Payment_Amount__c,
			   Disbursement__c.Adjustment_Amount__c,
			   //Disbursement__c.Application__c,
			   Disbursement__c.Bank_Account__c,
			  Disbursement__c.Cheque_Number__c,
			   Disbursement__c.Disbursal_Amount__c,
			  Disbursement__c.Disbursal_Date__c,
			   Disbursement__c.Disbursement_Bank__c,
			   Disbursement__c.Instrument_Number__c,
			   Disbursement__c.Payment_Mode__c,
			   Disbursement__c.PrincipalRecovery__c,
			   Disbursement__c.PrincipalRecoveryFrom__c,
			   Disbursement__c.PrincipalRecoveryOn__c,
			   Disbursement__c.Status__c
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return Disbursement__c.SObjectType; 
    }
    
   public List<Disbursement__c> selectByRecordId(Set<Id> disbId) {
    fflib_QueryFactory query = newQueryFactory();
    // query.selectField('Digilocker_Verification__r.Transaction_Id__c');
    query.setCondition('Id IN :disbId');
   // query.addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
    
    return (List<Disbursement__c>) Database.query(query.toSOQL());
}

}