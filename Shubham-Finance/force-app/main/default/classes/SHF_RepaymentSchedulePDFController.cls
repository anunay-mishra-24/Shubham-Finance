/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_RepaymentSchedulePDFController
 * Author          : Preeti
 * Created Date    : Jan 29, 2026
 * Last Modified By: Preeti
 * Last Modified On: Jan 29, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jan 29, 2026  │ Preeti  │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public with sharing class SHF_RepaymentSchedulePDFController {

    public List<SHF_Application_RepaymentSchedule.RepaymentScheduleWrapper>
        scheduleList { get; set; }

    public Decimal loanAmount { get; set; }
    public Decimal roi { get; set; }
    public Integer tenure { get; set; }

    public SHF_RepaymentSchedulePDFController() {

        Id applicationId = ApexPages.currentPage().getParameters().get('id');

        if (applicationId == null) {
            return;
        }

        Application__c app = [SELECT Sanction_Amount__c, Revised_Rate__c, Rate_of_Interest__c, Tenure__c FROM Application__c WHERE Id = :applicationId LIMIT 1];

        loanAmount = app.Sanction_Amount__c;
        roi = app.Revised_Rate__c != null ? app.Revised_Rate__c : app.Rate_of_Interest__c; tenure = Integer.valueOf(app.Tenure__c);

        scheduleList = SHF_Application_RepaymentSchedule.getRepaymentScheduleForPDF(tenure, roi, loanAmount,applicationId);
    }
}