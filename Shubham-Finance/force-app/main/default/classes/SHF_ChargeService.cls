/**
* @File Name          : SHF_ChargeService.cls
* @Description        : This class is used to Calculate Charge & display in LWC
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         07-09-2025              Akshi Sharma
*/
public with sharing class SHF_ChargeService {

    public class ChargeWrapper {
        public String typeOfCharge;
        public Decimal gst;
        public String chargeSubType;
        public String relatedTo;
        public Decimal amount;

        public ChargeWrapper(String typeOfCharge, Decimal gst,
                             String chargeSubType, String relatedTo,
                             Decimal amount) {
            this.typeOfCharge = typeOfCharge;
            this.gst = gst;
            this.chargeSubType = chargeSubType;
            this.relatedTo = relatedTo;
            this.amount = amount;
        }
    }

    public class Input {
        @InvocableVariable(required=true)
        public Id applicationId;

        @InvocableVariable(required=true)
        public String stageName;
    }

    @InvocableMethod(label='Create / Update Fee Records')
    public static void createOrUpdateFees(List<Input> inputs) {
        for (Input i : inputs) {
            upsertFees(i.applicationId, i.stageName);
        }
    }

    private static void upsertFees(Id applicationId, String stageName) {

        if (applicationId == null) return;

        List<ChargeWrapper> calculatedCharges =
            calculateCharges(applicationId, stageName);

        if (calculatedCharges.isEmpty()) return;

        Map<String, Fees__c> existingFeeMap = new Map<String, Fees__c>();

        for (Fees__c f : [
            SELECT Id, Application__c, Fee_Type__c,
                   Related_To__c, Amount__c, Tax__c, Charge_Sub_Type__c
            FROM Fees__c
            WHERE Application__c = :applicationId
        ]) {
            existingFeeMap.put(buildKey(f.Fee_Type__c, f.Related_To__c), f);
        }

        List<Fees__c> toInsert = new List<Fees__c>();
        List<Fees__c> toUpdate = new List<Fees__c>();

        for (ChargeWrapper row : calculatedCharges) {

            String key = buildKey(row.typeOfCharge, row.relatedTo);

            if (existingFeeMap.containsKey(key)) {
                Fees__c existing = existingFeeMap.get(key);

                existing.Amount__c = row.amount;
                existing.Tax__c = row.gst;
                existing.Charge_Sub_Type__c = row.chargeSubType;

                toUpdate.add(existing);
            } else {
                toInsert.add(new Fees__c(
                    Application__c = applicationId,
                    Fee_Type__c = row.typeOfCharge,
                    Tax__c = row.gst,
                    Charge_Sub_Type__c = row.chargeSubType,
                    Related_To__c = row.relatedTo,
                    Amount__c = row.amount
                ));
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }

    private static String buildKey(String type, String relatedTo) {
        return (type + '|' + relatedTo).toLowerCase();
    }

    /*
     * LWC CALL
     */
    @AuraEnabled(cacheable=true)
       public static List<Fees__c> getFees(Id applicationId) {
       Id appId;
Boolean isFromDisbursement = false;

// Check if record is Disbursement
if(applicationId.getSObjectType() == Disbursement__c.sObjectType){
    isFromDisbursement = true;
    
    appId = [
        SELECT Application__c 
        FROM Disbursement__c 
        WHERE Id = :applicationId
        LIMIT 1
    ].Application__c;
}else{
    appId = applicationId;
}

// If application not found
if(appId == null){
    return new List<Fees__c>();
}

// Query fees
if(isFromDisbursement){
    // From Disbursement return all fees
    return [
        SELECT Id,
               Fee_Type__c,
               Tax__c,
               Charge_Sub_Type__c,
               Related_To__c,
               Amount__c
        FROM Fees__c
        WHERE Application__c = :appId
        ORDER BY CreatedDate
    ];
}else{
    // From Application exclude Login Fees
    return [
        SELECT Id,
               Fee_Type__c,
               Tax__c,
               Charge_Sub_Type__c,
               Related_To__c,
               Amount__c
        FROM Fees__c
        WHERE Application__c = :appId
        AND Fee_Type__c != 'Login Fees'
        ORDER BY CreatedDate
    ];
}
    }

    private static List<ChargeWrapper> calculateCharges(
        Id applicationId,
        String stageName
    ) {

        List<ChargeWrapper> rows = new List<ChargeWrapper>();

        Application__c app = [
            SELECT Id, Product__r.Product_Type__c,
                   Sanction_Amount__c, Charges_Visible__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        //if (app.Charges_Visible__c != true) return rows;

        Decimal sanctionAmt =
            app.Sanction_Amount__c == null ? 0 : app.Sanction_Amount__c;

        /*
         * CREDIT STAGE FEES (3 fees)
         */
        if (stageName == 'Credit Assessment') {

            addCersai(rows, app, sanctionAmt);
            addInsurance(rows, applicationId);
            addBalanceProcessing(rows, app, sanctionAmt);
        }

        /*
         * LATER STAGE FEES (2)
         */
        if (stageName == 'Cheque Printing') {
            addDocumentationCharges(rows, app);
            addNESLCharges(rows, app);
        }

        return rows;
    }

    private static void addCersai(List<ChargeWrapper> rows, Application__c app, Decimal sanctionAmt) {

        List<Charge_Master__c> listCM = [
            SELECT Amount_Based__c, GST_Percentage__c,
                   Charge_Sub_Type__c
            FROM Charge_Master__c
            WHERE Type_of_Charge__c = 'Cersai'
            AND Product_Type__c = :app.Product__r.Product_Type__c
            AND IsActive__c = true
            AND Lower_Range__c    <= :sanctionAmt
            AND Upper_Range__c    >= :sanctionAmt
            LIMIT 1
        ];

        if (!listCM.isEmpty()) {
            Charge_Master__c cm = listCM[0];

            rows.add(new ChargeWrapper(
                'Cersai',
                cm.GST_Percentage__c,
                cm.Charge_Sub_Type__c,
                'Application',
                parseDecimal(cm.Amount_Based__c)
            ));
        }
    }

    private static void addInsurance(List<ChargeWrapper> rows, Id applicationId) {
        for (Loan_Applicant__c la : [
            SELECT Name, Insurance_Verification__r.Premium_Amount__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            AND IsDeleted__c = false
        ]) {
            rows.add(new ChargeWrapper(
                'Insurance Premium',
                null,
                'Deductible',
                la.Name,
                la.Insurance_Verification__r?.Premium_Amount__c == null
                    ? 0
                    : la.Insurance_Verification__r.Premium_Amount__c
            ));
        }
    }

    private static void addBalanceProcessing(List<ChargeWrapper> rows, Application__c app, Decimal sanctionAmt) {

        List<Charge_Master__c> opsList = [
            SELECT Amount_Based__c, GST_Percentage__c, Charge_Sub_Type__c
            FROM Charge_Master__c
            WHERE Type_of_Charge__c = 'Balance Processing Fee'
            AND Product_Type__c = :app.Product__r.Product_Type__c
            AND IsActive__c = true
            LIMIT 1
        ];

        if (!opsList.isEmpty()) {
            Charge_Master__c cm = opsList[0];

            Decimal rate = parseDecimal(cm.Amount_Based__c);
            Decimal base = sanctionAmt * rate;
            Decimal gstPct = cm.GST_Percentage__c == null ? 0 : cm.GST_Percentage__c;
            Decimal gst = base * (gstPct / 100);
            Decimal total = base + gst;
            System.debug('Balance Processing Fee - base: ' + base + ', gst: ' + gst + ', total: ' + total);
            rows.add(new ChargeWrapper(
                'Balance Processing Fee',
                gstPct,
                cm.Charge_Sub_Type__c,
                'Application',
                total.setScale(2)
            ));
        }
    }

    private static void addDocumentationCharges(List<ChargeWrapper> rows, Application__c app) {

        List<Charge_Master__c> listCM = [
            SELECT Amount_Based__c, GST_Percentage__c, Charge_Sub_Type__c
            FROM Charge_Master__c
            WHERE Type_of_Charge__c = 'Loan Documentation Charges'
            AND Product_Type__c = :app.Product__r.Product_Type__c
            AND IsActive__c = true
            LIMIT 1
        ];

        if (!listCM.isEmpty()) {
            Charge_Master__c cm = listCM[0];

            Decimal rate = parseDecimal(cm.Amount_Based__c);
            Decimal gstPct = cm.GST_Percentage__c == null ? 0 : cm.GST_Percentage__c;
            Decimal gst = rate * (gstPct / 100);
            Decimal total = rate + gst;

            rows.add(new ChargeWrapper(
                'Loan Documentation Charges',
                cm.GST_Percentage__c,
                cm.Charge_Sub_Type__c,
                'Application',
                total.setScale(2)
            ));
        }
    }

    private static void addNESLCharges(List<ChargeWrapper> rows, Application__c app) {

        List<Charge_Master__c> listCM = [
            SELECT Amount_Based__c, GST_Percentage__c, Charge_Sub_Type__c
            FROM Charge_Master__c
            WHERE Type_of_Charge__c = 'NESL Data Submission Charge'
            AND Product_Type__c = :app.Product__r.Product_Type__c
            AND IsActive__c = true
            LIMIT 1
        ];

        if (!listCM.isEmpty()) {
            Charge_Master__c cm = listCM[0];

            rows.add(new ChargeWrapper(
                'NESL Data Submission Charge',
                cm.GST_Percentage__c,
                cm.Charge_Sub_Type__c,
                'Application',
                parseDecimal(cm.Amount_Based__c)
            ));
        }
    }

    private static Decimal parseDecimal(String s) {
        try {
            if (String.isBlank(s)) return 0;
            return Decimal.valueOf(s.replace(',', '').trim());
        } catch (Exception e) {
            return 0;
        }
    }
}