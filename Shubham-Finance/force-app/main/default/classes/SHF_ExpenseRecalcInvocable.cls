/**
 * @File Name : SHF_ExpenseRecalcInvocable.cls
 * @Description : Recalculate Loan Applicant Expense when key fields change on multiple objects (via Flow Invocable)
 *
 * Supported Objects (objectName):
 *  - Application__c          (Branch__c change)
 *  - Loan_Applicant__c       (Total_Income__c, No_Of_Dependents__c, IsFinancial_Applicant__c, Customer_Type__c)
 *  - Personal_Discussion__c  (Credit PD: Rent__c / Insurance__c)
 *  - Obligation__c           (EMI__c)
 *
 * Output:
 *  - Updates Expense field on Loan_Applicant__c
 */
public with sharing class SHF_ExpenseRecalcInvocable {


    private static final String EXPENSE_FIELD_API = 'Expense__c';

    public class Request {
        @InvocableVariable public Application__c oldApplicationRecord;
        @InvocableVariable public Application__c newApplicationRecord;

        @InvocableVariable public Loan_Applicant__c oldLoanApplicantRecord;
        @InvocableVariable public Loan_Applicant__c newLoanApplicantRecord;

        @InvocableVariable public Personal_Discussion__c oldPersonalDiscussionRecord;
        @InvocableVariable public Personal_Discussion__c newPersonalDiscussionRecord;

        @InvocableVariable public Obligation__c oldObligationRecord;
        @InvocableVariable public Obligation__c newObligationRecord;


        @InvocableVariable public Id applicationId;

        @InvocableVariable(required=true)
        public String objectName;


        @InvocableVariable
        public String expenseFieldApi;

        public Map<String, SObject> getOldMap() {
            Map<String, SObject> m = new Map<String, SObject>();
            m.put('Application__c', oldApplicationRecord);
            m.put('Loan_Applicant__c', oldLoanApplicantRecord);
            m.put('Personal_Discussion__c', oldPersonalDiscussionRecord);
            m.put('Obligation__c', oldObligationRecord);
            return m;
        }

        public Map<String, SObject> getNewMap() {
            Map<String, SObject> m = new Map<String, SObject>();
            m.put('Application__c', newApplicationRecord);
            m.put('Loan_Applicant__c', newLoanApplicantRecord);
            m.put('Personal_Discussion__c', newPersonalDiscussionRecord);
            m.put('Obligation__c', newObligationRecord);
            return m;
        }
    }

    @InvocableMethod(label='SHF_ExpenseRecalcInvocable')
    public static void recalc(List<Request> requests) {
        if (requests == null || requests.isEmpty()) return;


        Set<Id> appIdsToRecalc = new Set<Id>();
        Set<Id> laIdsToRecalc  = new Set<Id>();


        String expenseFieldApi = EXPENSE_FIELD_API;
        for (Request r0 : requests) {
            if (r0 != null && !String.isBlank(r0.expenseFieldApi)) {
                expenseFieldApi = r0.expenseFieldApi.trim();
                break;
            }
        }

        for (Request req : requests) {
            if (req == null || String.isBlank(req.objectName)) continue;

            SObject oldRec = req.getOldMap().get(req.objectName);
            SObject newRec = req.getNewMap().get(req.objectName);


            Id derivedAppId = req.applicationId;
            Id derivedLaId  = null;

            if (req.objectName == 'Application__c') {
                Application__c aNew = (Application__c) newRec;
                if (derivedAppId == null && aNew != null) derivedAppId = aNew.Id;

                Application__c aOld = (Application__c) oldRec;

                if (aNew != null && (aOld == null || changed(aNew.Branch__c, aOld.Branch__c))) {
                    if (derivedAppId != null) appIdsToRecalc.add(derivedAppId);
                }
            }
            else if (req.objectName == 'Loan_Applicant__c') {
                Loan_Applicant__c laNew = (Loan_Applicant__c) newRec;
                Loan_Applicant__c laOld = (Loan_Applicant__c) oldRec;

                if (laNew != null) {
                    derivedLaId = laNew.Id;
                    if (derivedAppId == null) derivedAppId = laNew.Application__c;
                }


                if (laNew != null && (laOld == null
                    || changed(laNew.Appraised_Income__c, laOld.Appraised_Income__c)
                    || changed(laNew.No_Of_Dependents__c, laOld.No_Of_Dependents__c)
                    || changed(laNew.IsFinancial_Applicant__c, laOld.IsFinancial_Applicant__c)
                    || changed(laNew.Customer_Type__c, laOld.Customer_Type__c)
                )) {
                    if (derivedLaId != null) laIdsToRecalc.add(derivedLaId);
                }
            }
            else if (req.objectName == 'Personal_Discussion__c') {
                Personal_Discussion__c pdNew = (Personal_Discussion__c) newRec;
                Personal_Discussion__c pdOld = (Personal_Discussion__c) oldRec;

                if (pdNew != null) derivedLaId = pdNew.Loan_Applicant__c;


                if (pdNew != null && (pdOld == null
                    || changed(pdNew.Rent__c, pdOld.Rent__c)
                    || changed(pdNew.Insurance__c, pdOld.Insurance__c)
                )) {
                    if (derivedLaId != null) laIdsToRecalc.add(derivedLaId);
                }
            }
            else if (req.objectName == 'Obligation__c') {
                Obligation__c obNew = (Obligation__c) newRec;
                Obligation__c obOld = (Obligation__c) oldRec;

                if (obNew != null) derivedLaId = obNew.Loan_Applicant__c;

                if (obNew != null && (obOld == null || changed(obNew.Emi__c, obOld.Emi__c))) {
                    if (derivedLaId != null) laIdsToRecalc.add(derivedLaId);
                }

            }
        }


        if (!appIdsToRecalc.isEmpty()) {
            for (Loan_Applicant__c la : [
                SELECT Id
                FROM Loan_Applicant__c
                WHERE Application__c IN :appIdsToRecalc
            ]) {
                laIdsToRecalc.add(la.Id);
            }
        }

        if (laIdsToRecalc.isEmpty()) return;



        List<Loan_Applicant__c> laList = [
            SELECT Id,
                   Application__c,
                   Appraised_Income__c,
                   No_Of_Dependents__c,
                   IsFinancial_Applicant__c,
                   Customer_Type__c,
                   Application__r.Branch__r.Branch_Value__c
            FROM Loan_Applicant__c
            WHERE Id IN :laIdsToRecalc
        ];


        Set<Id> appIds = new Set<Id>();
        for (Loan_Applicant__c la : laList) 
        if (la.Application__c != null) 
        appIds.add(la.Application__c);


        Map<Id, Personal_Discussion__c> laToPd = new Map<Id, Personal_Discussion__c>();
        for (Personal_Discussion__c pd : [
            SELECT Id, Loan_Applicant__c, Rent__c, Insurance__c
            FROM Personal_Discussion__c
            WHERE Loan_Applicant__c IN :laIdsToRecalc
              AND RecordType.DeveloperName = 'Credit_PD'
        ]) {

            laToPd.put(pd.Loan_Applicant__c, pd);
        }


        Map<Id, Decimal> laToEmi = new Map<Id, Decimal>();
            for (AggregateResult ar : [
                SELECT Loan_Applicant__c laId, SUM(Emi__c) totalEmi
                FROM Obligation__c
                WHERE Loan_Applicant__c IN :laIdsToRecalc AND Considered_for_FOIR__c ='Yes' AND ((Source__c = 'CRIF' AND Loan_Status__c !='Closed') OR Source__c = 'Manual')
                GROUP BY Loan_Applicant__c
            ]) {
                laToEmi.put((Id) ar.get('laId'), (Decimal) ar.get('totalEmi'));
            }

        System.debug('laIdsToRecalc: ' + laIdsToRecalc);
        List<Expense_Master_Configuration__mdt> allCfg = new List<Expense_Master_Configuration__mdt>();
        allCfg.addAll(Expense_Master_Configuration__mdt.getAll().values());


        List<Loan_Applicant__c> updates = new List<Loan_Applicant__c>();

        for (Loan_Applicant__c la : laList) {

            Boolean isIndividual = (String.valueOf(la.Customer_Type__c) == 'Individual');
            String finVal = String.valueOf(la.IsFinancial_Applicant__c);
            Boolean isFinancial = (finVal == 'Yes' || finVal == 'true' || finVal == 'True');

            Loan_Applicant__c upd = new Loan_Applicant__c(Id = la.Id);

            if (!(isIndividual && isFinancial)) {

                // upd.put(expenseFieldApi, null);
                // updates.add(upd);
                continue;
            }

            Personal_Discussion__c pd = laToPd.get(la.Id);
            Decimal rent = (pd != null && pd.Rent__c != null) ? pd.Rent__c : 0;
            Boolean isWithoutRent = (rent == 0);
            //System.debug('pd.insurance = '+pd.Insurance__c);
            Decimal insurance = (pd != null && pd.Insurance__c != null) ? pd.Insurance__c : 0;
            Decimal emi = (laToEmi.containsKey(la.Id) && laToEmi.get(la.Id) != null) ? laToEmi.get(la.Id): 0;


            Decimal totalIncome = la.Appraised_Income__c == null ? 0 : la.Appraised_Income__c;
            Decimal dependents  = la.No_Of_Dependents__c == null ? 0 : la.No_Of_Dependents__c;


            Decimal branchCodeFromMaster = la.Application__r != null && la.Application__r.Branch__r != null
                ? la.Application__r.Branch__r.Branch_Value__c : null;
               
            
            if (branchCodeFromMaster == null) branchCodeFromMaster = 0;

            Expense_Master_Configuration__mdt cfg = pickConfig(allCfg, isWithoutRent, totalIncome);

            if (cfg == null) {

                // upd.put(expenseFieldApi, null);
                // updates.add(upd);
                continue;
            }


            Decimal I    = nz(cfg.Intercept__c);
            Decimal BC   = nz(cfg.Branch_Code__c) * branchCodeFromMaster;


            Decimal NOFM = nz(cfg.Number_of_Family_Members__c) * dependents;

            Decimal TIC  = nz(cfg.Total_Income_Eligible__c) * totalIncome;


            Decimal HR   = nz(cfg.Rent_Multiplier__c) * nz(cfg.House_Rent__c);

            Decimal ELE  = emi;
            Decimal IP   = insurance;

            Decimal total = I + BC + NOFM + TIC + HR + ELE + IP;
            System.debug('i= '+I+' bc= '+BC+' nofm= '+NOFM+' tic= '+TIC+' hr= '+HR+' ele= '+ELE+' ip= '+IP+' = '+total);
            
            System.debug('total  =  '+total);
            upd.put(expenseFieldApi, total);
            
            updates.add(upd);
        }

        if (!updates.isEmpty()) {
            Database.update(updates, false);
        }
    }



    private static Boolean changed(Object newVal, Object oldVal) {
        if (newVal == null && oldVal == null) return false;
        if (newVal == null && oldVal != null) return true;
        if (newVal != null && oldVal == null) return true;
        return String.valueOf(newVal) != String.valueOf(oldVal);
    }

    private static Expense_Master_Configuration__mdt pickConfig(
        List<Expense_Master_Configuration__mdt> allCfg,
        Boolean isWithoutRent,
        Decimal totalIncome
    ) {
        String rentKey = isWithoutRent ? 'Yes' : 'No';

        for (Expense_Master_Configuration__mdt r : allCfg) {
            if (r == null) continue;
            if (r.Is_Without_Rent__c != rentKey) continue;
            if (matchesIncome(totalIncome, r.Operator__c, r.Total_Income__c)) return r;
        }
        return null;
    }

    private static Boolean matchesIncome(Decimal applicantIncome, String op, Decimal cfgIncome) {
        Decimal a = applicantIncome == null ? 0 : applicantIncome;
        Decimal c = cfgIncome == null ? 0 : cfgIncome;

        if (op == 'Less Than') return a < c;
        if (op == 'Less Than Equal To') return a <= c;
        if (op == 'Greater Than') return a > c;
        if (op == 'Greater Than Equal To') return a >= c;
        if (op == 'Equal To') return a == c;
        if (op == 'Not Equal To') return a != c;
        return false;
    }

    private static Decimal nz(Decimal d) { return d == null ? 0 : d; }

    private static Decimal parseDecimal(String s) {
        if (String.isBlank(s)) return null;
        try {
            return Decimal.valueOf(s.trim());
        } catch (Exception e) {
            return null;
        }
    }
}