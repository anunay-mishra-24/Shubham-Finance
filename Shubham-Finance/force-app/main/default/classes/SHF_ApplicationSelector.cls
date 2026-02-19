/*
* @File Name : ApplicationSelector.cls
* @Description : Selector class to fetch Application records with required fields.
* @Author      : Preeti
* @Date        : 02/07/2025
* @Last Modified By : Preeti
* @Last Modified On : July 2, 2025
* @Modification Log :
*============================================================================== 
* Ver | Date | Author | Modification
*============================================================================== 
* 1.0 | July 2, 2025 | Preeti | Initial Version
*/

public class SHF_ApplicationSelector extends fflib_SObjectSelector {
    
    
    /*
* @Author      : Preeti
* @Date        : 02/07/2025
* @description Returns the SObject type for this selector.
* @return Schema.SObjectType for Application__c.
*/
    public Schema.SObjectType getSObjectType() {
        return Application__c.SObjectType;
    }
    
    
    /*
* @Author      : Preeti
* @Date        : 02/07/2025
* @description Returns the list of fields required for Application__c queries.
* @return List of Schema.SObjectField to be queried.
*/
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Application__c.Id,
                Application__c.Name,
                Application__c.Applied_Loan_Amount__c,
                Application__c.Product__c,
                Application__c.Branch__c,
                Application__c.Product__r.Name,
                Application__c.Branch__r.Name,
                Application__c.OwnerId,
                Application__c.Tenure__c,
                Application__c.Applied_Loan_Amount__c ,
                Application__c.Login_Fee_Verification__c,
                Application__c.LVR__c,
                Application__c.LTV__c,
                Application__c.IIR__c,
                Application__c.IAR__c,
                Application__c.FOIR_DBR__c,
               Application__c.Bre_Execution_Date__c,
                Application__c.Is_Current_User__c,
                Application__c.Risk_Category__c,
                //Application__c.Risk_Score_Thin_Weight__c,
               // Application__c.Risk_Score_Thik_Weight__c,
                Application__c.Application_Stage__c,
                Application__c.Loan_Agreement_No__c,
                 Application__c.Recomendation_comment__c,
                  Application__c.Recommended_Loan_Amount__c,
                  Application__c.Previous_Credit_User__c ,
                  Application__c.CAM_Generation_Date_Time__c  ,
                  Application__c.Final_Committee_Approval_Status__c  ,
                Application__c.Account__r.Name,
                Application__c.Application_Rejected_By__c,
                 Application__c.Negotiate_Tenure__c,
                  Application__c.Negotiate_Sanctioned_Loan_Amount__c,
                   Application__c.Negotiation_Approval_Status__c,
                   Application__c.Negotiation_Last_BM_Owner__c,
                  Application__c.Negotiation_Rate_of_Interest_ROI__c,
                   Application__c.Re_Sanction_Status__c,
                    Application__c.IsSendBackFromPreDisbursement__c,
                   Application__c.CBO_Approval_Status__c,
                   Application__c.Original_Processing_Fee__c,
                   Application__c.Processing_Fee_percent__c,
                   Application__c.Revised_Rate__c,
                   Application__c.Sanction_Amount__c,
                   Application__c.Tenure__c,
                    Application__c.Processing_Fee__c,
                   Application__c.Original_Processing_Fee_Percent__c,
                   Application__c.Original_ROI__c,
                   Application__c.Original_Sanction_Loan_Amount__c,
                   Application__c.Original_Tenure__c,
                   Application__c.Negotiate_Sanctioned_Loan_Amount__c,
                   Application__c.Negotiate_Tenure__c,
                   Application__c.Negotiation_Processing_Fee__c,
                    Application__c.Negotiation_Processing_Fee_Percent__c,
                   Application__c.Negotiation_Rate_of_Interest_ROI__c,
                    Application__c.Joint_Exposure__c,
                   Application__c.Processing_Fee_Percent_Reason_For_Change__c,
                   Application__c.Processing_Fee_Reason_For_Change__c,
                   Application__c.ROI_Reason_for_Change__c,
                    Application__c.Sanction_Loan_Amount_Reason_for_Change__c,
                   Application__c.Tenure_Reason_for_Change__c,

                   Application__c.Credit_Sanction_Approved_By__c,
                Application__c.CreatedDate
                };
                    }
    
    /*
* @Author      : Preeti
* @Date        : 02/07/2025
* @description Fetches a single Application__c record by Id with required fields for CIBIL API processing.
* @param applicationId - The Id of the Application__c record to fetch.
* @return Single Application__c record or null if not found.
*/
    public Application__c selectApplicationForCIBIL(Id applicationId) {
        String query = newQueryFactory()
            .selectField('Product__r.Name')
            .selectField('Branch__r.Name')
            .selectField('Branch__r.Branch_Code__c')
            .selectField('Product__r.Product_Type__c')
            .selectField('Product__r.Minimum_Co_Applicant_Age__c')
            .selectField('Product__r.Minimum_Applicant_Age__c')
            .selectField('Product__r.Minimum_Work_Experience__c')
            .selectField('Product__r.Minimum_Tenure_in_months__c')
            .selectField('Product__r.IAR__c')
            .selectField('Product__r.IIR__c')
            .selectField('Product__r.LVR_LCER__c')
            .selectField('Product__r.Max_Income_contributor_Age_At_Maturity__c')
            .selectField('Product__r.Maximum_Age_Property_Owner_At_Maturity__c')
            .selectField('Product__r.Maximum_Age_Non_Finacial_Borrowers_At_Ma__c')
            .selectField('Product__r.Crif_Cibil_Score__c')
            .selectField('Product__r.LTV__c')
            .selectField('Product__r.Plot_LTV__c')
            .selectField('Product__r.Policy_FOIR__c')
            .selectField('Product__r.Minimum_Loan_Amount__c')
            .selectField('Product__r.OGL_Property_Address__c')
            .setCondition('Id = :applicationId')
            .selectField('Branch__r.branch_Location__c')
            .selectField('Login_Fee_Verification__c')
            .selectField('Login_Fee_Verification__r.Receipt_Number__c')
            .toSOQL();
        
        List<Application__c> appList = Database.query(query);
        return appList.isEmpty() ? null : appList[0];
    }
    
    /*
* @Author      : Preeti
* @Date        : 02/07/2025
* @description Fetches a list of Application__c records by Id. 
* Although typically it will return one record (due to unique Id), this method returns a list to support bulk-safe patterns.
* @param applicationId - The Id of the Application__c record to fetch.
* @return List of Application__c records.
*/
    public List<Application__c> listOfselectApplicationForCIBIL(Id applicationId) {
        String query = newQueryFactory()
        .selectField('Branch__r.branch_Location__c')
            .setCondition('Id = :applicationId')
            .toSOQL();
        
        // List<Application__c> appList = Database.query(query);
        return (List<Application__c>) Database.query(query);
    }
    
    // Added by Riteek - Fetch Branch_Code__c for a given Application Id
    public List<Application__c> selectBranchCodeByApplicationId(Set<Id> recordIds){
        fflib_QueryFactory query = newQueryFactory();
        fflib_SObjectSelector applicantSelector = new SHF_LoanApplicantsSelector();
        applicantSelector.addQueryFactorySubselect(query, 'Loan_Applicants__r');
        query.selectField('Branch__r.Name');
        query.selectField('Branch__r.Branch_Code__c');
        query.selectField('Product__r.Name');
        query.selectField('Product__r.Product_Type__c');
        query.selectField('Product__r.Sub_Product__c');
        query.setCondition('Id IN : recordIds');
        System.debug('query   '+query);
        SYstem.debug('Database.query( query.toSOQL() )  '+Database.query( query.toSOQL() ));
        return (List<Application__c>) Database.query( query.toSOQL() );
    }
    
    /*
* @Author      : Preeti
* @Date        : 02/07/2025
* @description Fetches an Application__c record by Id with required fields for Insurance API processing.
* @param applicationId - The Id of the Application__c record to fetch.
* @return Application__c record or null if not found.
*/
    public Application__c selectApplicationForInsurance(Id applicationId) {
        String query = newQueryFactory()
            .selectField('Id')
            .selectField('Loan_Disbursement_Date__c')
            .selectField('Applied_Loan_Amount__c')
            .selectField('Tenure__c')
            .selectField('Product__r.Product_Type__c')
            .selectField('Branch__r.City__r.State_Master__r.State_Code__c')
            .selectField('Branch__r.City__r.State_Master__r.Region__c')
            .selectField('Branch__r.City__r.State_Master__r.Zone__c')
            .setCondition('Id = :applicationId')
            .toSOQL();
        
        List<Application__c> applications = Database.query(query);
        return applications.isEmpty() ? null : applications[0];
    }
    
    // Added by mansur - Fetch all related data of application
    public List<Application__c> getAllRelatedDataOfApplication(Set<Id> applicationId){
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Lead__r.Lead_Sub_Source__c');
        query.selectField('Branch__r.Name');
        query.selectField('Product__r.Name');
        query.selectField('Product__r.Sub_Product__c');
        //getting all applicant related to application
        fflib_SObjectSelector applicantSelector = new SHF_LoanApplicantsSelector();
        applicantSelector.addQueryFactorySubselect(query, 'Loan_Applicants__r');
        
        //getting Branch data related to application
        fflib_SObjectSelector branchSelector = new SHF_BranchSelector();
        branchSelector.configureQueryFactoryFields(query, 'Branch__r');
        
        
        //getting all Product related to application
        fflib_SObjectSelector productSelector = new SHF_ProductMasterSelector();
        productSelector.configureQueryFactoryFields(query, 'Product__r');
        query.setCondition('Id IN : applicationId');
        return (List<Application__c>) Database.query( query.toSOQL() );
    }
    
    /**
* Find Application by multiple conditions (Name, loanAggrement)
*/
    public List<Application__c> selectByCriteria(String name, String loanAggrement, String phone) {
        fflib_QueryFactory query = newQueryFactory()
            .selectField('Id')
            .selectField('Loan_Agreement_No__c')
            .selectField('Contact_No1__c')
            .selectField('Name')
            .selectField('Account__c')
            .selectField('Account__r.Phone')
            .selectField('Account__r.Email_id__c')
            .selectField('Account__r.Name')
            .selectField('Branch__c.Name')
            .selectField('Branch__c');
        
        List<String> conditions = new List<String>();
        
        if (!String.isBlank(name)) {
            conditions.add('Name = \'' + String.escapeSingleQuotes(name.trim()) + '\'');
        }
        if (!String.isBlank(loanAggrement)) {
            conditions.add('Loan_Agreement_No__c = \'' + String.escapeSingleQuotes(loanAggrement.trim()) + '\'');
        }
        if (!String.isBlank(phone)) {
            conditions.add('Account__r.Phone = \'' + String.escapeSingleQuotes(phone.trim()) + '\'');
        }
        
        if (!conditions.isEmpty()) {
            String finalCondition = String.join(conditions, ' OR ');
            query.setCondition(finalCondition);
        }
        
       system.debug('Application----- '+query);
        return (List<Application__c>) Database.query(query.toSOQL());
    }
    
    
    /**
    * @Author      :  Akshi Sharma
    * @Date        : 2025-12-09
    * @Description : Fetches minimal application details for Insurance API modal display.
    * @param application Id - Application record Id.
    * @return Application__c record with key fields.
    */
    public Application__c selectApplicationForInsuranceModal(Id applicationId) {
        if (applicationId == null) return null;

        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Id');
        query.selectField('Tenure__c');
        query.selectField('Sanction_Amount__c');
        query.setCondition('Id = :applicationId');

        List<Application__c> application = (List<Application__c>) Database.query(query.toSOQL());
        return application.isEmpty() ? null : application[0];
    }

        /*
* @Author      : Vikas Soni
* @Date        : 08/01/2026
* @description Fetches an Application__c record by Id with required fields for Loan Cancellation API processing.
* @param applicationId - The Id of the Application__c record to fetch.
* @return Application__c record or null if not found.
*/
    public Application__c selectApplicationForLoanCancellationLMS(Id applicationId) {
        if (applicationId == null) return null;

        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Id');
        query.selectField('Cancel_Remarks__c');
        query.selectField('Cancel_Reason__c');
        query.selectField('Application_Status__c');
        query.selectField('Login_Fee_Verification__c');
        query.selectField('Login_Fee_Verification__r.Receipt_Number__c');
        query.selectField('Cancel_Reason__c');
        query.setCondition('Id = :applicationId');

        List<Application__c> application = (List<Application__c>) Database.query(query.toSOQL());
        return application.isEmpty() ? null : application[0];
    }
    
    
}