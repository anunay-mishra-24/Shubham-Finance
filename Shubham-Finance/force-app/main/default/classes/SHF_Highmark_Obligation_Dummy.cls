public class SHF_Highmark_Obligation_Dummy {

    public static void execute() {
        System.debug('### Start HIGHMARK Obligation Processing');

        // Sample HIGHMARK XML
        String xmlData = 
            '<INDV-REPORT-FILE>' +
                '<INDV-REPORTS>' +
                    '<INDV-REPORT>' +
                        '<LOAN-DETAILS>' +
                            '<ACCT-NUMBER>1234567890</ACCT-NUMBER>' +
                            '<ACCT-TYPE>39</ACCT-TYPE>' +
                            '<ACCOUNT-STATUS>Active</ACCOUNT-STATUS>' +
                            '<ORIGINAL-TERM>240</ORIGINAL-TERM>' +
                            '<INSTALLMENT-AMT>20000</INSTALLMENT-AMT>' +
                            '<DISBURSED-AMT>1000000</DISBURSED-AMT>' +
                            '<CURRENT-BAL>900000</CURRENT-BAL>' +
                        '</LOAN-DETAILS>' +
                    '</INDV-REPORT>' +
                '</INDV-REPORTS>' +
            '</INDV-REPORT-FILE>';

        // Replace with real Application__c Id
        Id applicationId = 'a03C100000H8AZvIAN';

        // Parse XML into loan details
        List<Map<String, Object>> loanDetailsList = SHF_XmlToJsonParser.parseAllHighmarkLoans(xmlData);
        System.debug('### Parsed Loan Details List: ' + JSON.serializePretty(loanDetailsList));

        // Product Mapping
        Map<String, CIBIL_CRIF_Bureau_Product_Type__c> productTypeMap = new Map<String, CIBIL_CRIF_Bureau_Product_Type__c>();
        for (CIBIL_CRIF_Bureau_Product_Type__c cs : [
            SELECT Name, Value__c FROM CIBIL_CRIF_Bureau_Product_Type__c
        ]) {
            productTypeMap.put(cs.Name, cs);
        }
        System.debug('### Product Type Mapping: ' + productTypeMap);

        List<Obligation__c> obligationsToInsert = new List<Obligation__c>();

        for (Map<String, Object> loan : loanDetailsList) {
            Obligation__c obl = new Obligation__c();
            obl.Application__c = applicationId;
            obl.Source__c = 'CRIF';
            obl.Loan_Id__c = (String) loan.get('ACCT-NUMBER');
            obl.Loan_Status__c = (String) loan.get('ACCOUNT-STATUS');
            obl.Tenor__c = (String) loan.get('ORIGINAL-TERM');

            try {
                if (loan.containsKey('INSTALLMENT-AMT'))
                    obl.EMI__c = Decimal.valueOf((String) loan.get('INSTALLMENT-AMT'));
                if (loan.containsKey('CURRENT-BAL'))
                    obl.Outstanding_Amount__c = Decimal.valueOf((String) loan.get('CURRENT-BAL'));
                if (loan.containsKey('DISBURSED-AMT'))
                    obl.Sanctioned_Amount__c = Decimal.valueOf((String) loan.get('DISBURSED-AMT'));
            } catch (Exception e) {
                System.debug('### Parsing Number Error: ' + e.getMessage());
            }

            // Product mapping
            String acctType = (String) loan.get('ACCT-TYPE');
            if (productTypeMap.containsKey(acctType)) {
                obl.Product__c = productTypeMap.get(acctType).Value__c;
            }

            System.debug('### Prepared Obligation Record: ' + obl);
            obligationsToInsert.add(obl);
        }

        // Final insert
        if (!obligationsToInsert.isEmpty()) {
            insert obligationsToInsert;
            System.debug('### Obligations inserted: ' + obligationsToInsert.size());
        } else {
            System.debug('### No obligations to insert');
        }

        System.debug('### End HIGHMARK Obligation Processing');
    }
}