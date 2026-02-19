public with sharing class SHF_LitigationinstantParser {
    public Integer status;	//1
	public String verify_id;	//1a821e29c4635c00086a813f
    public String error_message;	//Authentication failed
	public static SHF_LitigationinstantParser parse(String json){
		return (SHF_LitigationinstantParser) System.JSON.deserialize(json, SHF_LitigationinstantParser.class);
	}
    public SHF_LitigationinstantParser(){
        status = null;
        verify_id = '';
        error_message = '';
    }
}