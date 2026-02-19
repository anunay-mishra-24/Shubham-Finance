public class SHF_DeleteEmailQueueable implements Queueable {

    private List<Id> emailIds;

    public SHF_DeleteEmailQueueable(List<Id> emailIds) {
        this.emailIds = emailIds;
    }

    public void execute(QueueableContext context) {
        List<EmailMessage> emails =
            [SELECT Id FROM EmailMessage WHERE Id IN :emailIds];

        if (!emails.isEmpty()) {
            delete emails;
        }
    }
}