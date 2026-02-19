public with sharing class ExpenseCalculatorController {


    public class ExpenseCalculatorDTO {
        @AuraEnabled public Id loanApplicantId;
        @AuraEnabled public Id applicationId;


        @AuraEnabled public String branchName;
        @AuraEnabled public String branchCodeText;       
        @AuraEnabled public Decimal totalIncome;
        @AuraEnabled public Integer familyMembers;       
        @AuraEnabled public String residenceTypeYesNo;   
        @AuraEnabled public Decimal existingLoanEmi;      
        @AuraEnabled public Decimal insurancePremium;     
        @AuraEnabled public Decimal totalExpenses;


        @AuraEnabled public Decimal intercept;
        @AuraEnabled public Decimal bc;
        @AuraEnabled public Decimal nofm;
        @AuraEnabled public Decimal tic;
        @AuraEnabled public Decimal hr;
        @AuraEnabled public Decimal ele;
        @AuraEnabled public Decimal ip;


        @AuraEnabled public Boolean showCalculator;  
        @AuraEnabled public Boolean isReadOnly;      

    }


    @AuraEnabled(cacheable=false)
    public static ExpenseCalculatorDTO getExpense(String loanApplicantId) {
        ExpenseCalculatorDTO dto = new ExpenseCalculatorDTO();
        dto.loanApplicantId = loanApplicantId;
        dto.isReadOnly = true; 
        System.debug('loanApplicantId: ' + loanApplicantId);
        Loan_Applicant__c la = [
            SELECT Id,
                   Application__c,
                   Customer_Type__c,
                   IsFinancial_Applicant__c,
                   No_Of_Dependents__c,
                   Appraised_Income__c
            FROM Loan_Applicant__c
            WHERE Id = :loanApplicantId
            LIMIT 1
        ];
        dto.applicationId = la.Application__c;


        Boolean isIndividual = (la.Customer_Type__c == 'Individual');
        Boolean isFinancial  = (la.IsFinancial_Applicant__c == 'Yes');

        dto.showCalculator = (isIndividual && isFinancial);
       

        
        Application__c app = [
            SELECT Id,
                   Branch__c,
                   Branch__r.Name,
                   Branch__r.Branch_Value__c
            FROM Application__c
            WHERE Id = :la.Application__c
            LIMIT 1
        ];

        dto.branchName = (app.Branch__r != null) ? app.Branch__r.Name : null;
        
        dto.branchCodeText = (app.Branch__r != null) ? String.ValueOf(app.Branch__r.Branch_Value__c) : null;


        Decimal branchCodeFromMaster = parseDecimal(dto.branchCodeText);
        if (branchCodeFromMaster == null) {
            branchCodeFromMaster = 0;
           
        }


        dto.existingLoanEmi = getExistingEmiSum(la.Id);


        

        Personal_Discussion__c creditPd = getCreditPd(la.Id);

        Decimal rent = (creditPd != null && creditPd.Rent__c != null) ? creditPd.Rent__c : 0;
        Boolean isWithoutRent = (rent == 0);
        dto.residenceTypeYesNo = isWithoutRent ? 'No' : 'Yes';

        dto.insurancePremium = (creditPd != null && creditPd.Insurance__c != null) ? creditPd.Insurance__c : 0;


        dto.totalIncome = (la.Appraised_Income__c != null) ? la.Appraised_Income__c : 0;
        dto.familyMembers = (la.No_Of_Dependents__c != null) ? Integer.valueOf(la.No_Of_Dependents__c) : 0;

        Expense_Master_Configuration__mdt cfg = pickConfig(isWithoutRent, dto.totalIncome);
        if (cfg == null) {
            dto.totalExpenses = null;
            return dto;
        }

        Decimal I    = nz(cfg.Intercept__c);
        Decimal BC   = nz(cfg.Branch_Code__c) * branchCodeFromMaster;
        Decimal NOFM = nz(cfg.Number_of_Family_Members__c) * nzInt(dto.familyMembers);
        Decimal TIC  = nz(cfg.Total_Income_Eligible__c) * nz(dto.totalIncome);
        Decimal HR   = nz(cfg.Rent_Multiplier__c) * nz(cfg.House_Rent__c);

        Decimal ELE  = nz(dto.existingLoanEmi);
        Decimal IP   = nz(dto.insurancePremium);
        
        System.debug('cfg = '+cfg.Branch_Code__c+' ==  '+branchCodeFromMaster);
        System.debug('I = '+I);
        System.debug('BC = '+BC);
        System.debug('----  '+cfg.Number_of_Family_Members__c+' ==  '+dto.familyMembers);
        System.debug('NOFM = '+NOFM);
        System.debug('cfg.Number_of_Family_Members__c = '+dto.totalIncome);
        System.debug('TIC = '+TIC);
        System.debug('HR = '+HR);
        System.debug('ELE = '+ELE);
        System.debug('IP = '+IP);
       

        Decimal total = I + BC + NOFM + TIC + HR + ELE + IP;
         System.debug('i= '+I+' bc= '+BC+' nofm= '+NOFM+' tic= '+TIC+' hr= '+HR+' ele= '+ELE+' ip= '+IP+' = '+total);
        dto.intercept = I;
        dto.bc = BC;
        dto.nofm = NOFM;
        dto.tic = TIC;
        dto.hr = HR;
        dto.ele = ELE;
        dto.ip = IP;

        dto.totalExpenses = total;

        return dto;
    }


 
   private static Decimal getExistingEmiSum(Id loanApplicantId) {
    AggregateResult ar = [
        SELECT SUM(Emi__c) totalEmi
        FROM Obligation__c
        WHERE Loan_Applicant__c = :loanApplicantId AND Considered_for_FOIR__c ='Yes' AND ((Source__c = 'CRIF' AND Loan_Status__c !='Closed') OR Source__c = 'Manual')
    ];
    Decimal sumEmi = (Decimal) ar.get('totalEmi');
    return (sumEmi == null) ? 0 : sumEmi;
}


   

    private static Personal_Discussion__c getCreditPd(Id loanApplicantId) {

        List<Personal_Discussion__c> rows = [
            SELECT Id, Rent__c, Insurance__c
            FROM Personal_Discussion__c
            WHERE Loan_Applicant__c = :loanApplicantId
              AND RecordType.DeveloperName = 'Credit_PD'
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private static Expense_Master_Configuration__mdt pickConfig(Boolean isWithoutRent, Decimal totalIncome) {
        String rentKey = isWithoutRent ? 'Yes' : 'No';

        List<Expense_Master_Configuration__mdt> rows = [
            SELECT Is_Without_Rent__c,
                   Total_Income__c,
                   Operator__c,
                   Intercept__c,House_Rent__c,
                   Branch_Code__c,
                   Number_of_Family_Members__c,
                   Total_Income_Eligible__c,
                   Rent_Multiplier__c
            FROM Expense_Master_Configuration__mdt
            WHERE Is_Without_Rent__c = :rentKey
        ];

        for (Expense_Master_Configuration__mdt r : rows) {
            if (matchesIncome(totalIncome, r.Operator__c, r.Total_Income__c)) {
                System.debug('cfg = '+r);
                return r;
            }
        }
        return null;
    }

    private static Boolean matchesIncome(Decimal applicantIncome, String op, Decimal cfgIncome) {
        Decimal a = (applicantIncome == null) ? 0 : applicantIncome;
        Decimal c = (cfgIncome == null) ? 0 : cfgIncome;

        if (op == 'Less Than') return a < c;
        if (op == 'Less Than Equal To') return a <= c;
        if (op == 'Greater Than') return a > c;
        if (op == 'Greater Than Equal To') return a >= c;
        if (op == 'Equal To') return a == c;
        if (op == 'Not Equal To') return a != c;
        return false;
    }

    private static Decimal nz(Decimal d) { return d == null ? 0 : d; }
    private static Integer nzInt(Integer i) { return i == null ? 0 : i; }

   
    private static Decimal parseDecimal(String s) {
        if (String.isBlank(s)) return null;
        String t = s.trim();
        try {
           
            return Decimal.valueOf(t);
        } catch (Exception e) {
            return null;
        }
    }

    
}