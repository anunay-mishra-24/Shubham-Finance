public with sharing class SHF_LitigationAdvanceParser {
    public Integer statusCode;	//200
	public String statusMsg;	//Case Inserted Successfully
	public String verifyId;	//6981eb684e3aa0ed50568d38
	public String jobName;	//shubham_housing_development_mafa:03-02-2026 18:00
	public static SHF_LitigationAdvanceParser parse(String json){
		return (SHF_LitigationAdvanceParser) System.JSON.deserialize(json, SHF_LitigationAdvanceParser.class);
	}

}