public class EnachResponseController {

    public String checkSumValue { get; set; }
    public String mandateResponse { get; set; }
    public String mandateStatus { get; set; }
    public String msgId { get; set; }
    public String refId { get; set; }

    public EnachResponseController() {

        // Read POST values coming to Visualforce Page
        checkSumValue   = ApexPages.currentPage().getParameters().get('CheckSumVal');
        mandateResponse = ApexPages.currentPage().getParameters().get('MandateRespDoc');

        if(String.isNotBlank(mandateResponse)) {
            // Parse JSON string received
            try {
                Map<String, Object> jsonMap = (Map<String, Object>)
                    JSON.deserializeUntyped(mandateResponse);

                mandateStatus = (String) jsonMap.get('Status');
                msgId         = (String) jsonMap.get('MsgId');
                refId         = (String) jsonMap.get('RefId');


            } catch (Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error parsing JSON: ' + ex.getMessage()));
            }
        }
    }
}