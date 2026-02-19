/*
* @File Name : SHF_ObligationSelector.cls
* @Description : Selector class to fetch Obligation__c records with required fields.
* @Author      : Preeti
* @Date        : 14/07/2025
* @Last Modified By : Preeti
* @Last Modified On : July 14, 2025
* @Modification Log :
*============================================================================== 
* Ver | Date | Author | Modification
*============================================================================== 
* 1.0 | July 14, 2025 | Preeti | Initial Version
*/

public class SHF_ObligationSelector extends fflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType() {
        return Obligation__c.SObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Obligation__c.Id,
                Obligation__c.Name,
                Obligation__c.Application__c,
                Obligation__c.Considered_for_FOIR__c,
                Obligation__c.EMI__c,
                Obligation__c.Institution__c,
                Obligation__c.Loan_Id__c,
                Obligation__c.Loan_Status__c,
                Obligation__c.Outstanding_Amount__c,
                Obligation__c.Product__c,
                Obligation__c.Remarks__c,
                Obligation__c.Sanctioned_Amount__c,
                Obligation__c.Source__c,
                Obligation__c.Tenor__c,
                Obligation__c.Tenor_Outstanding__c,
                Obligation__c.CreatedDate,
                Obligation__c.Cibil_Data_Deleted_On__c,
                Obligation__c.Consider_To_be_Deleted__c,
                Obligation__c.Loan_Applicant__c
                };
                    }
    
    public List<Obligation__c> selectActiveObligationsByApplication(Id applicationId, Id loanApplicantId) {
        String query = newQueryFactory()
            .selectFields(getSObjectFieldList())
            .setCondition('Application__c = :applicationId AND Loan_Applicant__c = :loanApplicantId AND Consider_To_be_Deleted__c = false')
            //.setCondition('Application__c = :applicationId AND Consider_To_be_Deleted__c = false')
            .addOrdering(Obligation__c.CreatedDate, fflib_QueryFactory.SortOrder.ASCENDING)
            .toSOQL();
        
        System.debug('****** '+ query + ' ' + applicationId +' '+ loanApplicantId);
        return (List<Obligation__c>) Database.query(query);
    }
    
    public Obligation__c selectById(Id obligationId) {
        String query = newQueryFactory()
            .selectFields(new List<SObjectField> { Obligation__c.Id })
            .setCondition('Id = :obligationId')
            .toSOQL();
        
        List<Obligation__c> result = (List<Obligation__c>) Database.query(query);
        return result.isEmpty() ? null : result[0];
    }
    
    
    public List<Obligation__c> selectDeletedObligationsByApplication(Id applicationId, Id loanApplicantId) {
        String query = newQueryFactory()
            .selectFields(getSObjectFieldList())
            .setCondition('Application__c = :applicationId AND Loan_Applicant__c = :loanApplicantId AND Consider_To_be_Deleted__c = true')
            .addOrdering(Obligation__c.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING)
            .toSOQL();
        
        return (List<Obligation__c>) Database.query(query);
    }
}