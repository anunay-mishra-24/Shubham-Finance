public class UB_Perfios_API {
    @AuraEnabled
    public static void initiateTransaction(String customerId,string password, Date fromDate, Date toDate){
        system.debug('ApplicantId===>'+customerId);
        system.debug('fromDate===>'+fromDate);
        system.debug('toDate===>'+toDate);
        // UB_BANK_STATEMENT_Perfios_Integration queueableInstance = new UB_BANK_STATEMENT_Perfios_Integration(customerId,password,fromDate,toDate);
        // System.enqueueJob(queueableInstance);
    }
}