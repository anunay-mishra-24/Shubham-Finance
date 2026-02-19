/*
* @File Name : Application_RepaymentSchedule.cls
* @Author :  Preeti
* @Created Date : June 25, 2025
* @Description :  This apex class is used to generate EMI repayment table on the basis of Loan Amount, ROI, Tenure on application object.
* @Last Modified By :  Preeti
* @Last Modified On : June 25, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 25, 2025 |   | Initial Version
*/

public class SHF_Application_RepaymentSchedule {
    
    public List<RepaymentScheduleWrapper> repaymentScheduleList { get; set; }
    
    
    /*
Fetches Product_Master__c records related to the provided Application ID.
@param loanApplicationId The ID of the Application.
@return List of Product_Master__c records.
*/
    @AuraEnabled
    public static List<Product_Master__c> getProductDetails(String loanApplicationId) {
        Logger.info('--- getProductDetails: ' + loanApplicationId + ' ---');
        try{
            Logger.info('Start getProductDetails for Loan Application Id: ' + loanApplicationId);
            return new SHF_ProductMasterSelector().selectByLoanApplicationId(loanApplicationId);
        }catch (Exception e) {
            Logger.error('Error in getProductDetails: ' + e.getMessage());
            return new List<Product_Master__c>();
        } finally {
            Logger.saveLog();
        }
    }
    
    
    
    
    /*
This method generates the EMI repayment schedule based on the loan amount, interest rate, and tenure.
It creates a list of EMI details like EMI amount, interest, principal, and due dates.
@param tenure The total number of months for loan repayment.
@param roi The annual rate of interest (ROI).
@param appliedLoanAmount The loan amount (principal).
@return JSON string of the EMI repayment schedule.
*/
    
    @AuraEnabled
    public static String repaymentScheduleData(Integer tenure, Decimal roi, Decimal appliedLoanAmount,Id aplicationId) {
        Logger.info('--- repaymentScheduleData: ' + aplicationId + ' ---');
        //Gaurav Kumar 21-Dec-2025
        Date first_Installment_Date = System.today();
        String labelValue = System.Label.First_Installment_Date_Dynamic;
        List<Bank_Details__c> bnkDetals = [SELECT Id,First_Installment_Date__c FROM Bank_Details__c WHERE Application__c =:aplicationId and First_Installment_Date__c != null LIMIT 1];
        if(bnkDetals.isEmpty() || bnkDetals[0].First_Installment_Date__c == null){
            throw newMessageException('Please complete the repayment data entry before generating the repayment schedule.');
        }
        if(!bnkDetals.isEmpty() && bnkDetals[0].First_Installment_Date__c != null && labelValue == 'Yes'){
            first_Installment_Date = bnkDetals[0].First_Installment_Date__c;
        }
        //Gaurav Kumar
        System.debug('Starting Repayment Schedule Calculation');
        System.debug('Input Parameters - Tenure: ' + tenure + ', ROI: ' + roi + ', Vehicle Cost: ' + appliedLoanAmount);
        
        List<RepaymentScheduleWrapper> wrapperList = new List<RepaymentScheduleWrapper>();
        
        try {
            Decimal emi = SHF_Application_RepaymentSchedule.getPMT(roi, tenure, appliedLoanAmount);
            System.debug('Calculated EMI: ' + emi);
            //Gaurav Kumar 12-Feb-2026
            Application__c app = new Application__c();
            app.Id = aplicationId;
            app.EMI__c = emi;
            update app;
            //
            
            Date emiDate;
            Decimal openingBalance = 0;
            Integer actualDays = 0;
            Decimal totalInterest = 0;
            
            Date firstEmiDate = SHF_Application_RepaymentSchedule.getFirstEmiDate(first_Installment_Date);
            System.debug('First EMI Date: ' + firstEmiDate);
            
            Date lastLoanDate = firstEmiDate.addMonths(tenure);
            Integer totalLoanDays = firstEmiDate.daysBetween(lastLoanDate);
            Decimal avgOpeningBalance = 0;
            
            for (Integer i = 1; i <= tenure; i++) {
                if (i == 1) {
                    emiDate = firstEmiDate;
                    openingBalance = appliedLoanAmount;
                    actualDays = System.today().daysBetween(firstEmiDate);
                }
                
                RepaymentScheduleWrapper wrapperRecord = new RepaymentScheduleWrapper();
                wrapperRecord.emiNo = i;
                wrapperRecord.emiDate = emiDate;
                wrapperRecord.openingBalance = openingBalance;
                avgOpeningBalance += openingBalance;
                wrapperRecord.emi = Math.round(emi);
                
                // Year calculation 
                //wrapperRecord.daysInYear = Integer.valueOf(System.Label.Days_In_Year);
                wrapperRecord.daysInYear = ((Math.mod(System.today().year(), 4) == 0 && Math.mod(System.today().year(), 100) != 0) || Math.mod(System.today().year(), 400) == 0) ? 366 : 365;
                
                wrapperRecord.actualDays = actualDays;
                wrapperRecord.roi = roi / 100;
                
                wrapperRecord.interest = Math.ceil((openingBalance * wrapperRecord.actualDays * wrapperRecord.roi) / wrapperRecord.daysInYear);
                totalInterest += wrapperRecord.interest;
                
                wrapperRecord.principle = wrapperRecord.emi - wrapperRecord.interest;
                wrapperRecord.closingBalance = (i == tenure) ? 0 : wrapperRecord.openingBalance - wrapperRecord.principle;
                
                emiDate = wrapperRecord.emiDate.addMonths(1);
                openingBalance = wrapperRecord.closingBalance;
                actualDays = wrapperRecord.emiDate.daysBetween(emiDate);
                
                wrapperList.add(wrapperRecord);
                System.debug('Repayment Schedule Record: ' + wrapperRecord);
            }
            
            System.debug('Total Interest: ' + totalInterest);
            System.debug('Final Repayment Schedule List: ' + wrapperList);
            
        } catch (Exception e) {
            Logger.error('Error in repaymentScheduleData: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
        
        return JSON.serialize(wrapperList);
    }
    
    
    /*
This method calculates the EMI (monthly payment) using the PMT formula.
It helps to find the fixed EMI amount for the given loan amount, interest rate, and tenure.
@param rate The annual interest rate.
@param nper The total number of months for repayment.
@param pv The loan amount (principal).
@return The calculated EMI amount.
*/
    
    @AuraEnabled
    public static Decimal getPMT(Decimal rate, Decimal nper, Decimal pv) {
        Logger.info('--- getPMT: ' + rate + ' ---');
        try{
            System.debug('Calculating PMT - Rate: ' + rate + ', Nper: ' + nper + ', PV: ' + pv);
            rate = (rate / 100) / 12;
            Double doubleValue = 1 + rate;
            Double exponent = nper;
            
            Decimal pvif = Math.pow(doubleValue, exponent);
            Decimal pmt = ((pv * rate) * pvif) / (pvif - 1);
            
            System.debug('Calculated PMT (EMI): ' + pmt);
            return Math.ceil(pmt);
        }
        catch (Exception e) {
            Logger.error('Error in getPMT: ' + e.getMessage());
            return 0;
        } finally {
            Logger.saveLog();
        }
    }
    
    
    
    /*
This method calculates the first EMI date based on the loan disbursement date.
It helps to decide when the borrower should start paying EMIs.
@param disbursementDate The date on which the loan was given.
@return The calculated first EMI date.
*/
    
    public static Date getFirstEmiDate(Date disbursementDate) {
        System.debug('Calculating First EMI Date for Disbursement Date in the method: ');
        Logger.info('--- getFirstEmiDate: ' + disbursementDate + ' ---');
        try{
            System.debug('Calculating First EMI Date for Disbursement Date: ' + disbursementDate);
            
            Date firstDayOfNextMonth = System.today().toStartOfMonth().addMonths(1);
            Date firstEmiDate;
            String labelValue = System.Label.First_Installment_Date_Dynamic;
            if(labelValue == 'Yes'){
                if (System.today().day() > disbursementDate.day()) {
                    Date nextMonth = disbursementDate.addMonths(1);
                    firstEmiDate = Date.newInstance(nextMonth.year(), nextMonth.month(), disbursementDate.day() );
                }else if(System.today().day() <= disbursementDate.day()){
                    firstEmiDate = disbursementDate;
                }
            }else{
                if (disbursementDate.day() >= 1 && disbursementDate.day() <= 10) {
                    firstEmiDate = firstDayOfNextMonth.addDays(6);
                    } else if (disbursementDate.day() >= 11 && disbursementDate.day() <= 22) {
                        firstEmiDate = firstDayOfNextMonth.addDays(14);
                    } else if ((disbursementDate.day() >= 1 && disbursementDate.day() <= 5) || (disbursementDate.day() >= 16 && disbursementDate.day() <= 31)) {
                        firstDayOfNextMonth = firstDayOfNextMonth.addMonths(1);
                        firstEmiDate = firstDayOfNextMonth.addDays(4);
                    } else {
                        firstDayOfNextMonth = firstDayOfNextMonth.addMonths(1);
                        firstEmiDate = firstDayOfNextMonth.addDays(6);
                }
            }            
            
            System.debug('First EMI Date Calculated: ' + firstEmiDate);
            logger.info('First EMI Date Calculated: ' + firstEmiDate);
            return firstEmiDate;
        }catch (Exception e) {
            Logger.error('Error in getFirstEmiDate: ' + e.getMessage());
            return System.today();
        } finally {
            Logger.saveLog();
        }
    }

    private static AuraHandledException newMessageException(String msg){
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }
    
    public class RepaymentScheduleWrapper {
        public Integer emiNo { get; set; }
        public Date emiDate { get; set; }
        public Decimal openingBalance { get; set; }
        public Decimal emi { get; set; }
        public Decimal interest { get; set; }
        public Decimal principle { get; set; }
        public Decimal closingBalance { get; set; }
        public Decimal roi { get; set; }
        public Integer daysInYear { get; set; }
        public Integer actualDays { get; set; }
    }


    public static List<RepaymentScheduleWrapper> getRepaymentScheduleForPDF(Integer tenure,Decimal roi,Decimal appliedLoanAmount,Id applicationId) {
        String jsonData = repaymentScheduleData(tenure, roi, appliedLoanAmount, applicationId);
        
        return (List<RepaymentScheduleWrapper>) JSON.deserialize(jsonData, List<RepaymentScheduleWrapper>.class);
    }

}