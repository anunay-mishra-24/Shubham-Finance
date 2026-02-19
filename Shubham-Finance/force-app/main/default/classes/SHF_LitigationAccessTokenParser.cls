public with sharing class SHF_LitigationAccessTokenParser {
    public Integer statusCode;	//200
	public String statusMsg;	//Success
	public String user;	//shubham_housing_development
	public String ApiKeyExpirationTime;	//After every 259200 seconds (72 hours)
	public String apiKey;	//eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InNodWJoYW1faG91c2luZ19kZXZlbG9wbWVudCIsImRhdGUiOjE3NzAxMDE5NDIyMjAsImlhdCI6MTc3MDEwMTk0Mn0.sO22J51fsVLx4-riXljgZXRA7wccRyAY8NOhdvtWdfI
	public static SHF_LitigationAccessTokenParser parse(String json){
		return (SHF_LitigationAccessTokenParser) System.JSON.deserialize(json, SHF_LitigationAccessTokenParser.class);
	}
}