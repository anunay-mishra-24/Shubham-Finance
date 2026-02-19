public class SHF_KfsController {
    
    public KfsWrapper kfs {get; set;}
    
    public SHF_KfsController(){
        kfs = new KfsWrapper();
        Id applicationId = ApexPages.currentPage().getParameters().get('id');
        //applicationId = 'a03C100000Jx3QhIAJ';
        if(applicationId != null){
            Application__c application = [SELECT Id, Name, Sanction_Amount__c, Loan_Product__c, Tenure__c, Rate_of_Interest__c, EMI__c, Sub_Product__c, Negotiation_Rate_of_Interest_ROI__c, Negotiate_Sanctioned_Loan_Amount__c, Negotiate_Tenure__c, Product__r.Product_Type__c, Recommended_Loan_Amount__c, Revised_Rate__c, APR__c FROM Application__c WHERE Id =: applicationId];
            kfs.application = application;
            kfs.roi = application.Revised_Rate__c;
            kfs.sanctionAmount = application.Sanction_Amount__c;
            kfs.tenure = application.Tenure__c;
            kfs.apr = application.APR__c;
            Decimal emi = SHF_Application_RepaymentSchedule.getPMT(application.Revised_Rate__c, application.Tenure__c, application.Sanction_Amount__c);
            
            String repaymentSchedules = SHF_Application_RepaymentSchedule.repaymentScheduleData(Integer.valueOf(application.Tenure__c), application.Rate_of_Interest__c, application.Sanction_Amount__c, applicationId);
            List<SHF_Application_RepaymentSchedule.RepaymentScheduleWrapper> schedules = (List<SHF_Application_RepaymentSchedule.RepaymentScheduleWrapper>) JSON.deserialize(repaymentSchedules, List<SHF_Application_RepaymentSchedule.RepaymentScheduleWrapper>.class);
            
            List<SheduleWrapper> scheduleList = new List<SheduleWrapper>();
            List<RepaymentScheduleWrapper> repaymentScheduleList = new List<RepaymentScheduleWrapper>();
            kfs.totalInterest = 0;
            if (schedules != null && !schedules.isEmpty()) {
                Integer totalEmis = schedules.size();
                
                for (SHF_Application_RepaymentSchedule.RepaymentScheduleWrapper schedule : schedules) {
                    RepaymentScheduleWrapper repaySch = new RepaymentScheduleWrapper();
                    repaySch.emiNo          = schedule.emiNo;
                    repaySch.emi            = schedule.emi;
                    repaySch.interest       = schedule.interest;
                    repaySch.principle      = schedule.principle;
                    repaySch.closingBalance = schedule.closingBalance;
                    kfs.totalInterest += repaySch.emi;
                    
                    if (schedule.emiDate != null) {
                        repaySch.emiDate = Datetime.newInstance(schedule.emiDate, Time.newInstance(0,0,0,0)).format('dd-MM-yyyy');
                    }
                    repaymentScheduleList.add(repaySch);
                }
                
                SHF_Application_RepaymentSchedule.RepaymentScheduleWrapper first = schedules[0];
                SHF_Application_RepaymentSchedule.RepaymentScheduleWrapper last  = schedules[totalEmis - 1];
                
                if (first.emi == last.emi) {
                    scheduleList.add(new SheduleWrapper(first.emiNo, last.emiNo, first.emi));
                } else {
                    scheduleList.add(new SheduleWrapper(first.emiNo, last.emiNo - 1, first.emi));
                    scheduleList.add(new SheduleWrapper(last.emiNo, last.emiNo, last.emi));
                }
            }
            
            kfs.scheduleList = scheduleList;
            kfs.repaymentScheduleList = repaymentScheduleList;
            
            List<Bank_Details__c> bankDetails = [SELECT Id, Name, Due_Day__c, Interest_Rate_Type__c, Installment_Type__c, Repayment_Frequency__c, First_Installment_Date__c, Disbursal_Type__c FROM Bank_Details__c WHERE Application__c = :applicationId AND RecordType.DeveloperName = 'Repayment' LIMIT 1];
            if(!bankDetails.isEmpty()){
                kfs.bankDetail = bankDetails[0];
                kfs.firstInstallmentDate = bankDetails[0].First_Installment_Date__c != null ? String.valueOf(bankDetails[0].First_Installment_Date__c.day()).leftPad(2, '0') + '/' + String.valueOf(bankDetails[0].First_Installment_Date__c.month()).leftPad(2, '0') + '/' + String.valueOf(bankDetails[0].First_Installment_Date__c.year()) : '';
                Date lastEmiDate = kfs.firstInstallmentDate != '' ? bankDetails[0].First_Installment_Date__c.addMonths(Integer.valueOf(application.Tenure__c)) : null;
                kfs.lastInstallmentDate = lastEmiDate != null ? String.valueOf(lastEmiDate.day()).leftPad(2, '0') + '/' + String.valueOf(lastEmiDate.month()).leftPad(2, '0') + '/' + String.valueOf(lastEmiDate.year()) : '';
            }
            
            List<Anchor_Master__c> masters = [SELECT Id, Anchor_Type__c, Anchor_Rate__c FROM Anchor_Master__c WHERE Is_Active__c = true LIMIT 1];
            if(!masters.isEmpty()){
                kfs.master = masters[0];
                Decimal plrPercent = (masters[0].Anchor_Type__c == 'PLR' &&  masters[0].Anchor_Rate__c != null) ? masters[0].Anchor_Rate__c : 0;
                kfs.spread = application.Rate_of_Interest__c != null ? plrPercent - application.Rate_of_Interest__c : 0;
            }   
            
            List<Charge_Master__c> chargeList = [SELECT Id, Amount_Based__c, Lower_Range__c, Upper_Range__c, GST_Percentage__c, Charge_Sub_Type__c, Product_Type__c, Type_Of_Charge__c, Login_Fee__c FROM Charge_Master__c WHERE Product_Type__c =: application.Product__r.Product_Type__c AND Lower_Range__c <= :application.Sanction_Amount__c AND Upper_Range__c>= :application.Sanction_Amount__c];
            kfs.loginCharges = 0;
            kfs.totalCharges = 0;
            if(!chargeList.isEmpty()){
                List<Charge_Master__c> otherCharges = new List<Charge_Master__c>();
                for(Charge_Master__c charge : chargeList){
                    if(charge.Type_of_Charge__c == 'Login Fees'){
                       // kfs.loginCharge = charge;
                        kfs.loginCharges = charge.Login_Fee__c != null ? kfs.loginCharges + charge.Login_Fee__c : kfs.loginCharges;
                    }else {
                       // otherCharges.add(charge);
                       kfs.totalCharges = charge.Login_Fee__c != null ? kfs.totalCharges + charge.Login_Fee__c : kfs.totalCharges;
                    }
                }
               // kfs.otherCharges = otherCharges; 
            }
        }
        
        System.debug('kfs --> '+ JSON.serializePretty(kfs.scheduleList));
        
        //createDocumentRecord('Signed Loan Documents','','a03C100000H8AZvIAN');
    }
    
    public class KfsWrapper {
        public Application__c application {get; set;}
        public Bank_Details__c bankDetail {get; set;}
        public Anchor_master__c master {get; set;}
        public Decimal sanctionAmount {get; set;}
        public Decimal tenure {get; set;}
        public Decimal roi {get; set;}
        public Decimal spread {get; set;}
        public String firstInstallmentDate {get; set;}
        public String lastInstallmentDate {get; set;}
        public String emi {get; set;}
        public String loanDocumentCharges {get; set;}
        public String currencyCode {get; set;}
       // public Charge_Master__c loginCharge {get; set;}
       // public List<Charge_Master__c> otherCharges {get; set;}
        public List<SheduleWrapper> scheduleList {get; set;}
        public List<RepaymentScheduleWrapper> repaymentScheduleList {get; set;}
        public Decimal loginCharges {get; set;}
        public Decimal totalCharges {get; set;}
        public Decimal apr {get; set;}
        public Decimal totalInterest {get; set;}
        public KfsWrapper(){
            currencyCode = UserInfo.getDefaultCurrency();
        }
    }
    
    public class SheduleWrapper {
        public Decimal firstEmi {get; set;}
        public Decimal lastEmi {get; set;}
        public Decimal emiAmount {get; set;}
        
        public SheduleWrapper(Decimal first, Decimal last, Decimal amount) {
            this.firstEmi = first;
            this.lastEmi = last;
            this.emiAmount = amount;
        }
    }
    
    public class RepaymentScheduleWrapper {
        public Integer emiNo {get; set;}
        public String emiDate {get; set;}
        public Decimal emi {get; set;}
        public Decimal interest {get; set;}
        public Decimal principle {get; set;}
        public Decimal closingBalance {get; set;}
    }
    
    public static void createDocumentRecord(String docName,String applicantId,String applicationId){
        Document__c doc = new Document__c();
        doc.Document_Category__c = 'Others';
        doc.Document_Type__c = 'Other';
        doc.File_Name__c = docName;
        doc.Mandatory_Document__c = false;
        doc.Status__c = 'Not Uploaded';
        doc.Type__c = 'Special Condition';
        doc.Stage__c = 'DDE';
        // doc.Loan_Applicant__c = applicantId;
        doc.Application__c = applicationId;
        doc.Applicable_For__c = 'Loan Applicants';        
        insert doc;
    }
}