/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : SHF_FeeCreationHandler
* Author          : <YourName>
* Created Date    : Feb 7, 2026
* Last Modified By: <YourName>
* Last Modified On: Feb 7, 2026
* Description     : This class implements for......
*  
* Change History  :
*  Date          │   Author     │   Change
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*  Feb 7, 2026  │ <YourName>   │ Initial version
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/

public without sharing class SHF_FeeCreationHandler {
    
    public class ChargeWrapper {
        @AuraEnabled public String typeOfCharge { get; set; }      // e.g., "CERSAI Charges"
        @AuraEnabled public Decimal gst { get; set; }              // e.g., 18
        @AuraEnabled public String chargeSubType { get; set; }     // e.g., "Collectible"
        @AuraEnabled public String relatedTo { get; set; }         // e.g., "Application" or Applicant name
        @AuraEnabled public Decimal amount { get; set; }           // e.g., 2500
        
        // Constructors must be inside the inner class
        public ChargeWrapper() {}
        
        public ChargeWrapper(String typeOfCharge, Decimal gst, String chargeSubType, String relatedTo, Decimal amount) {
            this.typeOfCharge  = typeOfCharge;
            this.gst           = gst;
            this.chargeSubType = chargeSubType;
            this.relatedTo     = relatedTo;
            this.amount        = amount;
        }
    }
    
    @AuraEnabled
    public static void createFeeRecords(String applicationId, String eventName) {
        Set<String> months = new Set<String>{'March','April','May','June'};
            String monthName = System.now().format('MMMM');
        monthName = months.contains(monthName) ? monthName : 'Other';
        System.debug('monthName = '+monthName);
        List<Application__c> application = [SELECT Id, Loan_Product__c, Applied_Loan_Amount__c FROM Application__c WHERE Id =: applicationId LIMIT 1];
        System.debug('application = '+application);
        Decimal requestedLoanAmount = application.get(0).Applied_Loan_Amount__c;
        String productName = application.get(0).Loan_Product__c;
        List<Fees__c> feeRecords = new List<Fees__c>();
        List<Charge_Master__c> chargeMaster = [SELECT
                                               Id, Amount_Based__c, Calculation_Type__c, Charge_Sub_Type__c,
                                               Fees_Name__c, GST_percentage__c, IsActive__c, Login_Fee__c,
                                               Lower_Range__c, Month__c, Percentage_Of__c, Product_Type__c,
                                               Stage__c, Type_Of_Charge__c, Upper_Range__c, Year__c
                                               FROM Charge_Master__c
                                               WHERE IsActive__c = true
                                               AND Product_Type__c =: productName
                                               AND Stage__c =: eventName];
                                               System.debug('chargeMaster = '+chargeMaster);
        Map<String, Map<String, List<Fees__c>>> oldFeeMap = new Map<String, Map<String, List<Fees__c>>>();
        for(Fees__c fee : [SELECT Id, Amount__c, Application__c, Charge_Master__c, Cancellation_Reason__c,
                           Fee_Type__c, Name, Status__c, Tax__c, Charge_Master__r.Charge_Sub_Type__c,
                           Charge_Master__r.Type_Of_Charge__c
                           FROM Fees__c
                           WHERE Application__c =: applicationId
                           AND Status__c != 'Cancelled']) 
        {
            System.debug('fee = '+fee);
            if(!oldFeeMap.containsKey(fee.Charge_Master__r.Charge_Sub_Type__c)){
                oldFeeMap.put(fee.Charge_Master__r.Charge_Sub_Type__c, new Map<String, List<Fees__c>>{fee.Fee_Type__c => new List<Fees__c>{fee}});
            } else {
                Map<String, List<Fees__c>> internalMap = oldFeeMap.get(fee.Charge_Master__r.Charge_Sub_Type__c);
                if(!internalMap.containsKey(fee.Fee_Type__c)){
                    internalMap.put(fee.Fee_Type__c, new List<Fees__c>());
                }
                internalMap.get(fee.Fee_Type__c).add(fee);
                oldFeeMap.put(fee.Charge_Master__r.Charge_Sub_Type__c, internalMap);
            }
        }
        for(Charge_Master__c charge : chargeMaster){
            System.debug('charge = '+charge);
            if(charge.Type_Of_Charge__c == 'Login Fees'){
                if(monthName == charge.Month__c && 
                   requestedLoanAmount >= charge.Lower_Range__c && requestedLoanAmount <= charge.Upper_Range__c) 
                {	
                    List<Fees__c> existingFees = oldFeeMap.containsKey(charge.Charge_Sub_Type__c) && oldFeeMap.get(charge.Charge_Sub_Type__c).containsKey(charge.Type_Of_Charge__c) ? 
                        oldFeeMap.get(charge.Charge_Sub_Type__c).get(charge.Type_Of_Charge__c) : null;
                    Fees__c fee = handleFeeRecordCreation(application.get(0), charge, existingFees);
                    if(fee != null){
                        feeRecords.add(fee);
                    }
                }
            }
        }
        
        if(!feeRecords.isEmpty()) {
            UPSERT feeRecords;
            System.debug(feeRecords);
        }
    }
    
    public static Fees__c handleFeeRecordCreation(Application__c application, Charge_Master__c charge, List<Fees__c> existingFee){
        System.debug('charge = '+charge);
        System.debug('existingFee = '+existingFee);
        if(charge.Charge_Sub_Type__c == 'Collectible') {
            if(existingFee != null && !existingFee.isEmpty()) {
                Decimal paidAmount = 0;  
                for(Fees__c fee : existingFee){
                    paidAmount += fee.Amount__c;
                }                
                if(charge.Login_Fee__c > paidAmount){
                    return createFee(application, charge, (charge.Login_Fee__c - paidAmount));
                }
                return null;
            } else {
                return createFee(application, charge, charge.Login_Fee__c);
            }
        } else {
            return null;
        }
    }
    
    public static Fees__c createFee(Application__c application, Charge_Master__c charge, Decimal feeAmount){
        return new Fees__c(
            Status__c = 'Pending',
            Related_To__c = 'Application',
            Application__c = application.Id,
            Charge_Master__c = charge.Id,
            Amount__c = feeAmount,
            Fee_Type__c = charge.Type_Of_Charge__c,
            Name = charge.Fees_Name__c
        );
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ChargeWrapper> getCharges(Id applicationId) {
        List<ChargeWrapper> rows = new List<ChargeWrapper>();
        if (applicationId == null) return rows;
        
        Application__c app = [
            SELECT Id, Product__c, Product__r.Product_Type__c, Sanction_Amount__c, Charges_Visible__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];
        if (app.Charges_Visible__c != true) {
            return rows;
        }
        
        Decimal sanctionAmt = (app.Sanction_Amount__c == null) ? 0 : app.Sanction_Amount__c;
        
        // ---------- (1) CERSAI Charge ----------
        List<Charge_Master__c> cersaiList = [
            SELECT Id, Amount_Based__c, Lower_Range__c, Upper_Range__c, GST_Percentage__c, Charge_Sub_Type__c, Product_Type__c
            FROM Charge_Master__c
            WHERE Type_of_Charge__c = 'Cersai'
            AND Product_Type__c   = :app.Product__r.Product_Type__c
            AND IsActive__c       = true
            AND Lower_Range__c    <= :sanctionAmt
            AND Upper_Range__c    >= :sanctionAmt
            LIMIT 1
        ];
        
        if (!cersaiList.isEmpty()) {
            Charge_Master__c cm = cersaiList[0];
            Decimal amt = parseDecimal(cm.Amount_Based__c);
            rows.add(new ChargeWrapper(
                'CERSAI Charges',
                cm.GST_Percentage__c,
                cm.Charge_Sub_Type__c,
                'Application',
                amt
            ));
        }
        
        // ---------- (2) Insurance Premiums ----------
        List<Loan_Applicant__c> applicants = [
            SELECT Id, Name, Insurance_Verification__r.Premium_Amount__c
            FROM Loan_Applicant__c
            WHERE Application__c = :app.Id AND IsDeleted__c = false
        ];
        
        for (Loan_Applicant__c la : applicants) {
            Decimal prem = (la.Insurance_Verification__r?.Premium_Amount__c == null) ? 0 : la.Insurance_Verification__r.Premium_Amount__c;
            String subType = 'Deductible';
            rows.add(new ChargeWrapper('Insurance Premium', null, subType, la.Name, prem));
        }
        
        // ---------- (3) Operational Costs ----------
        List<Charge_Master__c> opsList = [
            SELECT Id, Amount_Based__c, GST_Percentage__c, Charge_Sub_Type__c, Product_Type__c
            FROM Charge_Master__c
            WHERE Type_of_Charge__c = 'Charges'
            AND Product_Type__c   = :app.Product__r.Product_Type__c
            AND IsActive__c       = true
            LIMIT 1
        ];
        if (!opsList.isEmpty()) {
            Charge_Master__c cm = opsList[0];
            Decimal rate   = parseDecimal(cm.Amount_Based__c);
            Decimal base   = sanctionAmt * rate;
            Decimal gstPct = cm.GST_Percentage__c == null ? 0 : cm.GST_Percentage__c;
            Decimal gst    = base * (gstPct / 100);
            Decimal total  = base + gst;
            rows.add(new ChargeWrapper(
                'Administrative & Operational',
                gstPct,
                cm.Charge_Sub_Type__c,
                'Application',
                total.setScale(2)
            ));
        }
        
        return rows;
    }
    
    private static Decimal parseDecimal(String s) {
        try {
            if (String.isBlank(s)) return 0;
            return Decimal.valueOf(s.replace(',', '').trim());
        } catch (Exception e) {
            return 0;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<fees__c> getFees(String applicationId){
        List<fees__c> feelist = [select id,Tax__c,Amount__c,Fee_Type__c,Status__c from fees__c where Application__c =:applicationId];
        return feelist;
    }
    
    @AuraEnabled
    public static boolean checkIsBureauInitiatedOrNot(Id applicationId){
        boolean isbureauInitiated = true;
        List<Loan_Applicant__c> loanAppList = [SELECT Id,RecordType_Name__c,CRIF_Verification__c,CRIF_Verification__r.Status__c,CIBIL_Verification__r.Status__c
                                               from Loan_Applicant__c where application__c =:applicationId
                                              ];
        if(loanAppList.size()>0){
            if(loanAppList[0].RecordType_Name__c == 'Individual'){
                if(String.isBlank(loanAppList[0].CRIF_Verification__c) && String.isBlank(loanAppList[0].CIBIL_Verification__c)){
                    isbureauInitiated = false;
                }
                else if(String.isNotBlank(loanAppList[0].CRIF_Verification__c) && String.isNotBlank(loanAppList[0].CIBIL_Verification__c)){
                    if(loanAppList[0].CRIF_Verification__r.Status__c != 'COMPLETED' || loanAppList[0].CIBIL_Verification__r.Status__c != 'COMPLETED' ){
                        isbureauInitiated = false;
                    }
                }
                else if(String.isNotBlank(loanAppList[0].CRIF_Verification__c) && loanAppList[0].CRIF_Verification__r.Status__c != 'COMPLETED'){
                    isbureauInitiated = false;
                }
                else if(String.isNotBlank(loanAppList[0].CIBIL_Verification__c) && loanAppList[0].CIBIL_Verification__r.Status__c != 'COMPLETED'){
                    isbureauInitiated = false;
                }
            }
        }
        return isbureauInitiated;
    }
    
}