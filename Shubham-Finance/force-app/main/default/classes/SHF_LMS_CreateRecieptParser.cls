public with sharing class SHF_LMS_CreateRecieptParser {
    public cls_error_Success[] error;
    public cls_error_Success[] success;
	public class cls_error_Success {
		public String i18nCode;	//msg.00000316
		public List<String> messageArguments;
		public String type;	//ERROR
		public boolean isParent;
		public String value;	//msg.00000316 : Receipt / Payment with id 12029274 already exists.
	}
	
    public SHF_LMS_CreateRecieptParser(){
        error = null;
        success = null;
    }
	public static SHF_LMS_CreateRecieptParser parse(String json){
		return (SHF_LMS_CreateRecieptParser) System.JSON.deserialize(json, SHF_LMS_CreateRecieptParser.class);
	}
}