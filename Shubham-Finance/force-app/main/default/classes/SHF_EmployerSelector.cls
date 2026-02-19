public class SHF_EmployerSelector extends fflib_SObjectSelector  {
	 public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
            Employment__c.Id,
                Employment__c.Name,
				Employment__c.Business_Category__c,
				Employment__c.Business_Employer_Contact_No__c,
				Employment__c.Business_Employer_Email_ID__c,
				Employment__c.Business_Employer_Name__c,
				Employment__c.Industry__c ,
				Employment__c.Loan_Applicant__c  ,
                Employment__c.ApplicantRecordType__c,
                Employment__c.uans__c,
                Employment__c.entityId__c
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return Employment__c.SObjectType; 
    }

	 public List<Employment__c> selectByIds(Set<Id> recordIds) {    
        fflib_QueryFactory query = new fflib_QueryFactory(Employment__c.sObjectType);
        //query.selectField('City_Master__r.Name'); 
        query.setCondition('Id IN : recordIds');
        return (List<Employment__c>) Database.query(query.toSOQL());
    }
	 public List<Employment__c> selectByApplicantsId(Set<Id> applicantIds) {    
        fflib_QueryFactory query = new fflib_QueryFactory(Employment__c.sObjectType);
        query.selectField('Industry__c'); 
		query.selectField('Loan_Applicant__r.Name'); 
		query.selectField('Loan_Applicant__c'); 
        query.setCondition('Loan_Applicant__c  IN : applicantIds');
        return (List<Employment__c>) Database.query(query.toSOQL());
    }
    /**
     * @Author      : Vikas Soni
     * @Date        : 2026-01-12
     * @Description : Fetches minimal employee details .
     */
    public List<Employment__c> selectCreateCustomerLMSApplicant(Id loanApplicantId) {
        if (loanApplicantId == null) return new List<Employment__c>();
        
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Id');
        query.selectField('Name');
        query.selectField('Occupation__c');
        query.selectField('Employment_Status__c');
        query.selectField('Employment_Type__c');
        query.selectField('Employed_From__c');
        query.selectField('Employed_Till__c');
        query.selectField('Department__c');
        query.selectField('Designation__c');
        query.selectField('Employee_Number__c');
        query.selectField('Total_Years_Of_Operation_Years__c');
        query.selectField('Total_Years_Of_Operation_Months__c');
        query.selectField('Industry__c');
        query.selectField('Sub_Industry__c');
        query.selectField('Business_Employer_Name__c');
        query.selectField('Website__c');
        query.selectField('Gross_Annual_Income_Yearly__c');
        query.selectField('Gross_Income_Monthly__c');
        query.selectField('Staff_Loan__c');
        query.selectField('uans__c');
        query.selectField('Loan_Applicant__c');
        query.setCondition('Loan_Applicant__c = :loanApplicantId');
        
        List<Employment__c> employment = (List<Employment__c>) Database.query(query.toSOQL());
        return employment;
    }
}