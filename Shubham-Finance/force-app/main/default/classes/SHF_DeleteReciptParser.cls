/**
 * @File Name : SHF_ReciptStatusParser.cls
 * @Description :
 * @Author : Vikas Soni
 * @Last Modified By :
 * @Last Modified On : Jan 21, 2026
 * @Modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | Jan 21, 2026 |   | Initial Version
 **/
public with sharing class SHF_DeleteReciptParser {
    public cls_acknowledgement acknowledgement;
	public String responseCode;	//success
	public cls_responseString responseString;
	public cls_payload[] payload;
	public class cls_acknowledgement {
	}
	public class cls_responseString {
	}
	public class cls_payload {
		public String i18nCode;	//msg.00000271
		public List<String> messageArguments;
		public String type;	//INFO
		public boolean isParent;
		public String value;	//msg.00000271 : Receipt deleted successfully for receipt ref # 12029286. 
	}
	
	public static SHF_DeleteReciptParser parse(String json){
		return (SHF_DeleteReciptParser) System.JSON.deserialize(json, SHF_DeleteReciptParser.class);
	}
    
}