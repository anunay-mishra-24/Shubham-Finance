public class SHF_SMSFutureInvoker implements Queueable {

    private String mobileNumber;
    private String smsBody;

    public SHF_SMSFutureInvoker(String mobileNumber, String smsBody) {
        this.mobileNumber = mobileNumber;
        this.smsBody = smsBody;
    }

    public void execute(QueueableContext context) {
        // Call  future method here
        SHF_SMS_Service.sendNotificationToUser(mobileNumber, smsBody);
    }
}