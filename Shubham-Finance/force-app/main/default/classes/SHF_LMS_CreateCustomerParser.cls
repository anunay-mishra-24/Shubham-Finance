/**
 * @File Name : SHF_LMS_CreateCustomerParser.cls
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
public class SHF_LMS_CreateCustomerParser {
    public String status;	//SUCCESS
	public String messageCode;	//msg.gcd.2000012
	public String messageDescription;	//Customer created successfully
	public String requestReferenceNumber;	//70444
	public String customerInfoFileNumber;	//GLBCUST00005623491
	public String hostCustomerInfoFileNumber;	//
	public String associatedLoanAppId;	//1111134253
	public cls_globalCustomerIdMapping globalCustomerIdMapping;
	public class cls_globalCustomerIdMapping {
		public cls_BANK_DETAILS[] BANK_DETAILS;
		public cls_FINALCIAL_DETAILS[] FINALCIAL_DETAILS;
		public cls_CONTACT_DETAILS[] CONTACT_DETAILS;
		public cls_ADDRESS[] ADDRESS;
		public cls_PHONE_NUMBER[] PHONE_NUMBER;
	}
	public class cls_BANK_DETAILS {
		public cls_clientId clientId;
		public String gcdId;	//34545
		public boolean mappingChanged;
	}
	public class cls_clientId {
	}
	public class cls_FINALCIAL_DETAILS {
		public cls_clientId clientId;
		public String gcdId;	//296039
		public boolean mappingChanged;
	}
	public class cls_CONTACT_DETAILS {
		public cls_clientId clientId;
		public String gcdId;	//731935
		public boolean mappingChanged;
	}
	public class cls_ADDRESS {
		public cls_clientId clientId;
		public String gcdId;	//1756744
		public boolean mappingChanged;
	}
	public class cls_PHONE_NUMBER {
		public cls_clientId clientId;
		public String gcdId;	//3320282
		public boolean mappingChanged;
	}
	public static SHF_LMS_CreateCustomerParser parse(String json){
		return (SHF_LMS_CreateCustomerParser) System.JSON.deserialize(json, SHF_LMS_CreateCustomerParser.class);
	}
}