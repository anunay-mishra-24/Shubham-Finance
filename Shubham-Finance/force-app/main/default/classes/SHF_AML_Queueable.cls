public class SHF_AML_Queueable implements Queueable, Database.AllowsCallouts {

    private Id applicantId;

    public SHF_AML_Queueable(Id applicantId) {
        this.applicantId = applicantId;
    }

    public void execute(QueueableContext context) {
        if (applicantId != null) {
            System.debug('Calling fetch AML details for applicantId: ' + applicantId + ' from AML Queueable');
            SHF_AML_Service.fetchAMLDetails(applicantId);
        }
    }
}