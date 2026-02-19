public class NameComparisonQueueable implements Queueable, Database.AllowsCallouts {

    private String firstName;
    private String secondName;
    private Id eVericationId;
    private Id applicantId;

    public NameComparisonQueueable(String firstName, String secondName, Id eVericationId, Id applicantId) {
        this.firstName = firstName;
        this.secondName = secondName;
        this.eVericationId = eVericationId;
        this.applicantId = applicantId;
    }

    public void execute(QueueableContext context) {
        System.debug('Name comparison Queue started for: ' + firstName);
        System.debug('Name comparison Queue started for: ' + secondName);
        System.debug('Name comparison Queue started for: ' + eVericationId);
        System.debug('Name comparison Queue started for: ' + applicantId);
        
        SHF_NameMatch_Service.validateNameMatch(eVericationId, applicantId, firstName, secondName);
    }
}