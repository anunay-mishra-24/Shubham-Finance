global class SHF_TATsEscalationScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
       
       Database.executeBatch(new SHF_SendNotificationForTATsEscalation());
    }
}