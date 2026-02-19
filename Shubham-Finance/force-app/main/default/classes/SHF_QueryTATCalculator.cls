public class SHF_QueryTATCalculator {
   // ---------- INPUT WRAPPER ----------
    public class InputWrapper {
        @InvocableVariable(required=true)
        public Id recordId;
    }

    // ---------- INVOCABLE METHOD ----------
    @InvocableMethod(label='Calculate Query TAT (Business Hours)')
    public static void calculateTAT(List<InputWrapper> inputs) {

        if (inputs == null || inputs.isEmpty()) return;

        Set<Id> queryIds = new Set<Id>();
        for (InputWrapper inp : inputs) {
            if (inp.recordId != null) {
                queryIds.add(inp.recordId);
            }
        }

        if (queryIds.isEmpty()) return;

        // Fetch Business Hours
        BusinessHours bh = [
            SELECT Id
            FROM BusinessHours
            WHERE Name = 'SHDFC Noida Business Hours'
            LIMIT 1
        ];

        List<Query__c> queriesToUpdate = new List<Query__c>();

        for (Query__c q : [
            SELECT Id, CreatedDate, Completed_Date__c
            FROM Query__c
            WHERE Id IN :queryIds
        ]) {
            if (q.Completed_Date__c == null) continue;

            Long diffMs = BusinessHours.diff(
                bh.Id,
                q.CreatedDate,
                q.Completed_Date__c
            );

            Decimal tatHours = diffMs / 1000.0 / 60 / 60;

            queriesToUpdate.add(new Query__c(
                Id = q.Id,
                TAT_in_hours__c = String.valueOf(tatHours.setScale(2))
            ));
        }

        if (!queriesToUpdate.isEmpty()) {
            update queriesToUpdate;
        }
    }
}