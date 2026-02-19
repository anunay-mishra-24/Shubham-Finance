/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : Shf_IncomeProgramSelector
 * Author          : <YourName>
 * Created Date    : Feb 12, 2026
 * Last Modified By: Mansur
 * Last Modified On: Feb 12, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Feb 12, 2026  │ <Mansur>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class Shf_IncomeProgramSelector extends fflib_SObjectSelector {
	 public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Income_Details__c.Id,
                Income_Details__c.Name,
				Income_Details__c.Total_Income_Monthly__c,
				Income_Details__c.Loan_Applicant__c,
				Income_Details__c.RecordType.Name,
                Income_Details__c.Income_Head__c,
			    Income_Details__c.Total_Income_Annual__c,
                Income_Details__c.Application__c,
				Income_Details__c.Income_source__c
                };
                    }
    
    public Schema.SObjectType getSObjectType(){
        return Income_Details__c.sObjectType;
    }
     
    public List<Income_Details__c> selectIncomeByLoanApplicantId(Set<Id> applicantId){
        fflib_QueryFactory query = newQueryFactory();
		query.selectField('RecordType.Name');
        query.setCondition('Loan_Applicant__c IN : applicantId'); 
        return (List<Income_Details__c>) Database.query( query.toSOQL() );
    }

}