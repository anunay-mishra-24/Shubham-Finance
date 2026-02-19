public class SHF_HunterFutureCallout {

    @future(callout=true)
    public static void sendFinalDecision(List<Id> applicantIds, List<String> decisions) {

        for (Integer i = 0; i < applicantIds.size(); i++) {

            SHF_RecordOutcomes_Service.callRecordOutcome(applicantIds[i],decisions[i]);
        }
    }
}