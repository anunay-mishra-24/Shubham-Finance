/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_CIBILCRIFDMS_Queueable
 * Author          : Preeti
 * Created Date    : Jan 21, 2026
 * Last Modified By: Preeti
 * Last Modified On: Jan 21, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jan 21, 2026  │ Preeti  │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class SHF_CIBILCRIFDMS_Queueable implements Queueable, Database.AllowsCallouts {

    private String docCategory;
    private String base64Doc;
    private Id applicationId;
    private Id documentId;

    public SHF_CIBILCRIFDMS_Queueable( String docCategory,String base64Doc,Id applicationId,Id documentId) {
        this.docCategory = docCategory;
        this.base64Doc = base64Doc;
        this.applicationId = applicationId;
        this.documentId = documentId;
    }

    public void execute(QueueableContext qc) {
        SHF_DMS_Service.createDoc(docCategory,base64Doc,applicationId,documentId);
    }
}