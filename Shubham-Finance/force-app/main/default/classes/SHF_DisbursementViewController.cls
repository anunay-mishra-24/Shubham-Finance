public with sharing class SHF_DisbursementViewController {

    public class ViewData {
        @AuraEnabled public String applicationId;
        @AuraEnabled public String branchName;
        @AuraEnabled public String applicantName;
        @AuraEnabled public Date sanctionDate;

        @AuraEnabled public Decimal maximumSanctionedAmount;
        @AuraEnabled public Decimal sanctionedAmount;

        @AuraEnabled public Decimal disbursedAmount;
        @AuraEnabled public Decimal availableAmount;

        @AuraEnabled public Boolean loanCurtailment;

        @AuraEnabled public Decimal tenure;
        @AuraEnabled public Decimal roi;
        @AuraEnabled public String applicationStatus;
        @AuraEnabled public String applicationStage;

        @AuraEnabled public String loanAccountNumber;
        @AuraEnabled public Id lanToBeLinkedId;
        @AuraEnabled public String lanToBeLinkedName;
        @AuraEnabled public Boolean lanToBeLinkedLocked;
    }

    public class TrancheRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String trancheId;
        @AuraEnabled public Date disbursalDate;
        @AuraEnabled public Decimal disbursalAmount;
        @AuraEnabled public Decimal adjustmentAmount;
        @AuraEnabled public Decimal actualPaymentAmount;
        @AuraEnabled public String trancheLinkBase;

        // ✅ NEW (JS openEditModal expects these)
        @AuraEnabled public Boolean principalRecovery;
        @AuraEnabled public Date principalRecoveryFrom;
        @AuraEnabled public Date principalRecoveryOn;
        @AuraEnabled public Id disbursementBankId;
        @AuraEnabled public String status;
    }

    public class ScreenData {
        @AuraEnabled public ViewData application;
        @AuraEnabled public String disbursalType;
        @AuraEnabled public List<TrancheRow> tranches;
        @AuraEnabled public Boolean autoCreated;
    }

    private static final Set<String> ALLOWED_STATUS = new Set<String>{
        'Tranche Request Initiation',
        'Tranche Approval',
        'Tranche Disbursement',
        'Disbursed'
    };

    // ---------------- LOAD ----------------
    @AuraEnabled
    public static ScreenData loadScreen(Id applicationId) {
        if (applicationId == null) throw new AuraHandledException('Application Id is required.');

        Application__c app = [
            SELECT Id, Name, Branch__r.Name, Sanction_Date__c, Sanction_Amount__c, Maximum_Sanctioned_Amount__c,
                   Tenure__c, Revised_Rate__c, Application_Status__c, Application_Stage__c, Loan_Account_Number__c,
                   Loan_Curtailment__c, LAN_Master__c, LAN_Master__r.Name
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        String primaryApplicantName;
        List<Loan_Applicant__c> prim = [
            SELECT Id, Name
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
              AND Applicant_Type__c = 'Primary Applicant'
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        if (!prim.isEmpty()) primaryApplicantName = prim[0].Name;

        String disbursalType = getDisbursalType(applicationId);

        ScreenData dto = new ScreenData();
        dto.disbursalType = disbursalType;
        dto.tranches = queryTranches(applicationId);
        dto.autoCreated = false;

        // NOTE: auto-create tranche (kept as-is)
        if (dto.disbursalType == 'Single' && (dto.tranches == null || dto.tranches.isEmpty())) {
            Decimal disb = getDisbursedSum(applicationId);
            Decimal sanctioned = (app.Sanction_Amount__c == null ? 0 : app.Sanction_Amount__c);

            Decimal availableBefore = sanctioned - disb;
            if (availableBefore < 0) availableBefore = 0;

            createTrancheInternal(applicationId, Date.today(), availableBefore);
            dto.tranches = queryTranches(applicationId);
            dto.autoCreated = true;
        }

        dto.application = mapViewData(app, primaryApplicantName, applicationId);
        return dto;
    }
    @AuraEnabled
    public static Disbursement__c loadDisbursementRecord(Id disbursementId){
        if (disbursementId == null) throw new AuraHandledException('Disbursement Id is required.');

        //List<Disbursement__c> disbList = [SELECT Id, Status__c FROM Disbursement__c WHERE Id = :disbursementId LIMIT 1];
        List<Payee_Details__c> disbList = [SELECT Id,Disbursement__r.Status__c FROM Payee_Details__c WHERE Disbursement__c =:disbursementId LIMIT 1];
        return disbList.isEmpty() ? null : disbList[0].Disbursement__r;
    }
    @AuraEnabled(cacheable=true)
    public static Group getQueueByDeveloperName() {

        List<Group> queues = [
            SELECT Id, Name, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Pending_Tranche_Records'
            LIMIT 1
        ];

        return queues.isEmpty() ? null : queues[0];
    }

    // ---------------- SAVE APPLICATION ----------------
    @AuraEnabled
    public static void saveApplication(
        Id applicationId,
        Boolean loanCurtailment,
        Decimal maximumSanctionedAmount,
        Id lanToBeLinkedId
    ) {
        if (applicationId == null) throw new AuraHandledException('Application Id is required.');

        Application__c app = [
            SELECT Id, Sanction_Amount__c, Maximum_Sanctioned_Amount__c, LAN_Master__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        Decimal disbursed = getDisbursedSum(applicationId);


        Decimal maxToUse = app.Maximum_Sanctioned_Amount__c;
        if (maxToUse == null) {
            maxToUse = (maximumSanctionedAmount != null) ? maximumSanctionedAmount : app.Sanction_Amount__c;
        }
        if (maxToUse == null) maxToUse = 0;

        Decimal newSanction = (loanCurtailment == true) ? disbursed : maxToUse;

        if (newSanction < disbursed) {
            throw new AuraHandledException('Sanctioned Amount cannot be less than Disbursed Amount.');
        }

        Application__c upd = new Application__c(Id = applicationId);
        upd.Sanction_Amount__c = newSanction;


        if (app.Maximum_Sanctioned_Amount__c == null) {
            upd.Maximum_Sanctioned_Amount__c = maxToUse;
        }


        upd.Loan_Curtailment__c = loanCurtailment;

        // LAN locking rule
        if (app.LAN_Master__c != null) {
            if (lanToBeLinkedId != null && lanToBeLinkedId != app.LAN_Master__c) {
                throw new AuraHandledException('LAN is already linked and cannot be changed.');
            }
        } else {
            if (lanToBeLinkedId != null) {
                upd.LAN_Master__c = lanToBeLinkedId;
            }
        }

        update upd;
    }

    // ---------------- CREATE TRANCHE (✅ UPDATED SIGNATURE to match JS) ----------------
    @AuraEnabled
    public static Id createNewTranche(
        Id applicationId,
        Date disbursalDate,
        Decimal disbursalAmount,
        Boolean principalRecovery,
        Date principalRecoveryFrom,
        Date principalRecoveryOn,
        Id disbursementBankId,
        String status
    ) {
        if (applicationId == null) throw new AuraHandledException('Application Id is required.');

        // Mandatory as per UI requirement
        if (disbursementBankId == null) throw new AuraHandledException('Disbursement Bank is required.');
       

        validateDisbursementBank(disbursementBankId);

        Application__c app = [
            SELECT Id, Sanction_Amount__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        String disbursalType = getDisbursalType(applicationId);
        Integer existingCount = [
            SELECT COUNT()
            FROM Disbursement__c
            WHERE Application__c = :applicationId
        ];

        if (disbursalType == 'Single' && existingCount > 0) {
            throw new AuraHandledException('Disbursal Type is Single. Only one tranche is allowed.');
        }

        if (disbursalDate == null) disbursalDate = Date.today();
        if (disbursalDate > Date.today()) throw new AuraHandledException('Disbursal Date cannot be a future date.');
        if (disbursalAmount == null || disbursalAmount <= 0) throw new AuraHandledException('Disbursal Amount must be greater than 0.');

        Decimal disb = getDisbursedSum(applicationId);
        Decimal sanctioned = (app.Sanction_Amount__c == null ? 0 : app.Sanction_Amount__c);

        Decimal available = sanctioned - disb;
        if (available < 0) available = 0;

        if (disbursalAmount > available) {
            throw new AuraHandledException('Disbursal Amount cannot be greater than Available Amount.');
        }

        return createTrancheInternalFull(
            applicationId,
            disbursalDate,
            disbursalAmount,
            (principalRecovery == true),
            principalRecoveryFrom,
            principalRecoveryOn,
            disbursementBankId,
            status
        );
    }

    // ---------------- UPDATE TRANCHE (✅ supports new fields) ----------------
    @AuraEnabled
    public static void updateTranches(Id applicationId, List<Disbursement__c> updates) {
        if (applicationId == null) throw new AuraHandledException('Application Id is required.');
        if (updates == null || updates.isEmpty()) return;

        Application__c app = [
            SELECT Id, Sanction_Amount__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];
        Decimal sanctioned = (app.Sanction_Amount__c == null) ? 0 : app.Sanction_Amount__c;

        List<Disbursement__c> existing = [
            SELECT Id, Disbursal_Date__c, Disbursal_Amount__c,
                   Disbursement_Bank__c, Status__c
            FROM Disbursement__c
            WHERE Application__c = :applicationId
        ];
        Map<Id, Disbursement__c> exMap = new Map<Id, Disbursement__c>(existing);

        // Validate and compute total
        Decimal newTotal = 0;
        for (Disbursement__c exRec : existing) {
            newTotal += (exRec.Disbursal_Amount__c == null ? 0 : exRec.Disbursal_Amount__c);
        }

        Set<Id> bankIdsToValidate = new Set<Id>();

        for (Disbursement__c u : updates) {
            if (u.Id == null || !exMap.containsKey(u.Id)) continue;

            Disbursement__c oldRec = exMap.get(u.Id);

            if (u.Disbursal_Date__c != null && u.Disbursal_Date__c > Date.today()) {
                throw new AuraHandledException('Disbursal Date cannot be a future date.');
            }
            if (u.Disbursal_Amount__c != null && u.Disbursal_Amount__c <= 0) {
                throw new AuraHandledException('Disbursal Amount must be greater than 0.');
            }

            // Mandatory bank + status final state check
            Id finalBankId = (u.Disbursement_Bank__c != null) ? u.Disbursement_Bank__c : oldRec.Disbursement_Bank__c;
            String finalStatus = (!String.isBlank(u.Status__c)) ? u.Status__c : oldRec.Status__c;

            if (finalBankId == null) throw new AuraHandledException('Disbursement Bank is required.');
           

            bankIdsToValidate.add(finalBankId);

            Decimal oldAmt = oldRec.Disbursal_Amount__c == null ? 0 : oldRec.Disbursal_Amount__c;
            Decimal newAmt = (u.Disbursal_Amount__c == null) ? oldAmt : u.Disbursal_Amount__c;
            newTotal = newTotal - oldAmt + newAmt;
        }

        if (!bankIdsToValidate.isEmpty()) validateDisbursementBanks(bankIdsToValidate);

        if (newTotal > sanctioned) {
            throw new AuraHandledException('Total Disbursed Amount cannot exceed Sanctioned Amount.');
        }

        List<Disbursement__c> toUpdate = new List<Disbursement__c>();
        for (Disbursement__c u : updates) {
            if (u.Id == null) continue;

            Disbursement__c d = new Disbursement__c(Id = u.Id);

            if (u.Disbursal_Date__c != null) d.Disbursal_Date__c = u.Disbursal_Date__c;
            if (u.Disbursal_Amount__c != null) d.Disbursal_Amount__c = u.Disbursal_Amount__c;

            // ✅ NEW fields
            if (u.PrincipalRecovery__c != null) d.PrincipalRecovery__c = u.PrincipalRecovery__c;
            if (u.PrincipalRecoveryFrom__c != null) d.PrincipalRecoveryFrom__c = u.PrincipalRecoveryFrom__c;
            if (u.PrincipalRecoveryOn__c != null) d.PrincipalRecoveryOn__c = u.PrincipalRecoveryOn__c;

            if (u.Disbursement_Bank__c != null) d.Disbursement_Bank__c = u.Disbursement_Bank__c;
            if (!String.isBlank(u.Status__c)) d.Status__c = u.Status__c;

            toUpdate.add(d);
        }

        if (!toUpdate.isEmpty()) update toUpdate;
    }

    // ---------------- DELETE ----------------
    @AuraEnabled
    public static void deleteTranche(Id applicationId, Id trancheId) {
        if (applicationId == null) throw new AuraHandledException('Application Id is required.');
        if (trancheId == null) throw new AuraHandledException('Tranche Id is required.');

        Disbursement__c d = [
            SELECT Id, Application__c,IsDeleted__c
            FROM Disbursement__c
            WHERE Id = :trancheId
            LIMIT 1
        ];
        if (d.Application__c != applicationId) {
            throw new AuraHandledException('Invalid tranche for this application.');
        }
        d.IsDeleted__c = true;
        update d;
    }

    // ---------------- VIEW MAPPER ----------------
    private static ViewData mapViewData(Application__c app, String primaryApplicantName, Id applicationId) {
        Decimal disb = getDisbursedSum(applicationId);

        Decimal maxAmt = app.Maximum_Sanctioned_Amount__c;
        if (maxAmt == null) maxAmt = app.Sanction_Amount__c;

        Boolean loanCurt = (app.Loan_Curtailment__c == true);

        Decimal sanctionedToShow = loanCurt ? disb : (app.Sanction_Amount__c == null ? 0 : app.Sanction_Amount__c);
        Decimal availableToShow = sanctionedToShow - disb;
        if (availableToShow < 0) availableToShow = 0;

        ViewData v = new ViewData();
        v.applicationId = app.Name;
        v.branchName = (app.Branch__r != null) ? app.Branch__r.Name : null;
        v.applicantName = primaryApplicantName;
        v.sanctionDate = app.Sanction_Date__c;

        v.maximumSanctionedAmount = maxAmt;
        v.sanctionedAmount = sanctionedToShow;

        v.disbursedAmount = disb;
        v.availableAmount = availableToShow;

        v.loanCurtailment = loanCurt;

        v.tenure = app.Tenure__c;
        v.roi = app.Revised_Rate__c;
        v.applicationStatus = app.Application_Status__c;
        v.applicationStage = app.Application_Stage__c;

        v.lanToBeLinkedId = app.LAN_Master__c;
        v.lanToBeLinkedName = (app.LAN_Master__r != null) ? app.LAN_Master__r.Name : null;
        v.lanToBeLinkedLocked = (app.LAN_Master__c != null);

        if (app.Application_Stage__c == 'Disbursement Checker') {
            v.loanAccountNumber = app.Loan_Account_Number__c;
        } else {
            v.loanAccountNumber = null;
        }

        return v;
    }

    private static String getDisbursalType(Id applicationId) {
        List<Bank_Details__c> bankList = [
            SELECT Id, Disbursal_Type__c
            FROM Bank_Details__c
            WHERE Application__c = :applicationId
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        return bankList.isEmpty() ? null : bankList[0].Disbursal_Type__c;
    }

    private static Decimal getDisbursedSum(Id applicationId) {
        AggregateResult ar = [
            SELECT SUM(Disbursal_Amount__c) s
            FROM Disbursement__c
            WHERE Application__c = :applicationId
        ];
        Decimal sumDisbursed = (Decimal) ar.get('s');
        return (sumDisbursed == null) ? 0 : sumDisbursed;
    }

    // ---------------- ADJUSTMENT (same as your code) ----------------
    private static Decimal getAdjustmentAmountInternal(Id applicationId) {
        if (applicationId == null) return 0;

        Application__c app = [
            SELECT Id, Sanction_Amount__c, Charges_Visible__c, Product__r.Product_Type__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        if (app.Charges_Visible__c != true) return 0;

        Decimal sanctionAmt = (app.Sanction_Amount__c == null) ? 0 : app.Sanction_Amount__c;
        String productType = app.Product__r != null ? app.Product__r.Product_Type__c : null;

        Decimal sumAmt = 0;

        List<Charge_Master__c> cersaiList = [
            SELECT Amount_Based__c, Lower_Range__c, Upper_Range__c
            FROM Charge_Master__c
            WHERE Type_of_Charge__c = 'Cersai'
              AND Product_Type__c   = :productType
              AND IsActive__c       = true
              AND Lower_Range__c    <= :sanctionAmt
              AND Upper_Range__c    >= :sanctionAmt
            LIMIT 1
        ];
        if (!cersaiList.isEmpty()) {
            sumAmt += parseDecimalLocal(cersaiList[0].Amount_Based__c);
        }

        List<Charge_Master__c> opsList = [
            SELECT Amount_Based__c, GST_Percentage__c
            FROM Charge_Master__c
            WHERE Type_of_Charge__c = 'Balance Processing Fee'
              AND Product_Type__c   = :productType
              AND IsActive__c       = true
            LIMIT 1
        ];
        if (!opsList.isEmpty()) {
            Charge_Master__c cm = opsList[0];

            Decimal rate   = parseDecimalLocal(cm.Amount_Based__c);
            Decimal base   = sanctionAmt * rate;

            Decimal gstPct = (cm.GST_Percentage__c == null) ? 0 : cm.GST_Percentage__c;
            Decimal gst    = base * (gstPct / 100);

            Decimal total  = (base + gst).setScale(2);
            sumAmt += total;
        }

        return sumAmt;
    }

    private static Decimal parseDecimalLocal(String s) {
        try {
            if (String.isBlank(s)) return 0;
            return Decimal.valueOf(s.replace(',', '').trim());
        } catch (Exception e) {
            return 0;
        }
    }

    
    private static List<TrancheRow> queryTranches(Id applicationId) {
    List<Disbursement__c> recs = [
        SELECT Id, Name, Disbursal_Date__c, Disbursal_Amount__c,
               Adjustment_Amount__c, Actual_Payment_Amount__c,
               Status__c, CreatedDate
        FROM Disbursement__c
        WHERE Application__c = :applicationId and IsDeleted__c = false
        ORDER BY CreatedDate ASC
    ];

    Decimal adjFromCharges = getAdjustmentAmountInternal(applicationId);

    List<TrancheRow> rows = new List<TrancheRow>();
    List<Disbursement__c> adjUpdates = new List<Disbursement__c>();

    Integer idx = 0;
    for (Disbursement__c d : recs) {

        Decimal computedAdj = (idx == 0) ? adjFromCharges : 0;
        Decimal storedAdj   = (d.Adjustment_Amount__c == null) ? 0 : d.Adjustment_Amount__c;

        // scale safe compare
        Decimal c1 = computedAdj.setScale(2);
        Decimal c2 = storedAdj.setScale(2);

        if (c1 != c2) {
            adjUpdates.add(new Disbursement__c(
                Id = d.Id,
                Adjustment_Amount__c = computedAdj
            ));
        }

        TrancheRow r = new TrancheRow();
        r.id = d.Id;
        r.trancheId = d.Name;
        r.disbursalDate = d.Disbursal_Date__c;
        r.disbursalAmount = d.Disbursal_Amount__c;

        r.adjustmentAmount = computedAdj; 
        r.status = d.Status__c;            

        r.actualPaymentAmount =
            ((d.Actual_Payment_Amount__c == null) ? 0 : d.Actual_Payment_Amount__c)
            - r.adjustmentAmount;

        if (r.actualPaymentAmount < 0) r.actualPaymentAmount = 0;

        r.trancheLinkBase = '/' + d.Id;
        rows.add(r);

        idx++;
    }

    if (!adjUpdates.isEmpty()) update adjUpdates; // ✅ persist adjustment

    return rows;
}


    // ---------------- CREATE HELPERS ----------------
    private static Id createTrancheInternal(Id applicationId, Date disbursalDate, Decimal disbursalAmount) {
        Disbursement__c d = new Disbursement__c();
        d.Application__c = applicationId;
        d.Disbursal_Date__c = disbursalDate;
        d.Disbursal_Amount__c = disbursalAmount;
        d.Adjustment_Amount__c = 0;
        insert d;
        return d.Id;
    }

    private static Id createTrancheInternalFull(
        Id applicationId,
        Date disbursalDate,
        Decimal disbursalAmount,
        Boolean principalRecovery,
        Date principalRecoveryFrom,
        Date principalRecoveryOn,
        Id disbursementBankId,
        String status
    ) {
        Disbursement__c d = new Disbursement__c();
        d.Application__c = applicationId;
        d.Disbursal_Date__c = disbursalDate;
        d.Disbursal_Amount__c = disbursalAmount;
        d.Adjustment_Amount__c = 0;

        d.PrincipalRecovery__c = (principalRecovery == true);
        d.PrincipalRecoveryFrom__c = principalRecoveryFrom;
        d.PrincipalRecoveryOn__c = principalRecoveryOn;
        d.Disbursement_Bank__c = disbursementBankId;
        d.Status__c = status;

        insert d;
        return d.Id;
    }

    // ---------------- BANK VALIDATION ----------------
    private static void validateDisbursementBank(Id bankId) {
        validateDisbursementBanks(new Set<Id>{ bankId });
    }

    private static void validateDisbursementBanks(Set<Id> bankIds) {
        if (bankIds == null || bankIds.isEmpty()) return;

        Map<Id, Bank_master__c> bm = new Map<Id, Bank_master__c>([
            SELECT Id, RecordType.Name,Name
            FROM Bank_master__c
            WHERE Id IN :bankIds
        ]);

        for (Id idVal : bankIds) {
            if (!bm.containsKey(idVal)) {
                throw new AuraHandledException('Invalid Disbursement Bank.');
            }
            String rtName = (bm.get(idVal).RecordType != null) ? bm.get(idVal).RecordType.Name : null;
            if (rtName != 'Dealing Disbursement Bank Master') {
                throw new AuraHandledException('Disbursement Bank must be of record type "Dealing Disbursement Bank Master".');
            }
        }
    }
}