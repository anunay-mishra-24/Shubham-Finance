public with sharing class SHF_LitigationinstantResultParser {
    public List<cls_cases> cases;
	public String flexi_search_id;	//526eb1e97a71461e999c57ba57418fe2
	public String flexi_source_id;	//
	// public group_by group_by;
	public String message;	//Processing done
	public Integer numresults;	//80
	public Integer status;	//1
	public class cls_cases {
		public String address;	//1A,Galaxy apartments B.J.Road,Band Stand Bandra W,Mumbai50.
		// public Integer address_score;	//62
		public String algo_risk;	//high risk
		public String asr_info;	//civil procedure code | order 9 rule 9
		public String business_category;	//
		public String case_category;	//civil
		public String case_no;	//208502013672015
		public String case_status;	//
		public String case_type_code;	//85
		public String case_type_description;	//
		public String case_type_name;	//Notice of Motion
		public String case_year;	//2015
		public String cnr;	//MHCC040034882015
		// public Integer court_code;	//3
		public String court_name;	//District and Session Court , Nandurbar
		public String decision_date;
		// public Integer dist_code;	//1
		public String dist_match;	//match
		public String dist_name;	//Nandurbar
		// public Integer es_rank;	//21
		// public Double falcon_score;	//87.19999999999999
		public String father_match_type;	//PARTIAL_EXACT
		public String fir_no;	//
		public String first_hearing_date;	//2015-06-15
		public String is_Bail;	//false
		// public Integer is_district;	//0
		// public Integer is_state;	//1
		public boolean jurisdiction;
		public String jurisdiction_type;	//STATE
		public String link;	//https://verify24x7.in/live/casehtml3.php?link=https%3A%2F%2Ffullhtml2.s3-us-west-2.amazonaws.com%2F59caf3708a04302743ee1276abfa4c3a&id=1-1-3
		public String matched_address;	//1A,Galaxy apartments B.J.Road,Band Stand Bandra W,Mumbai50.
		public String matched_name;	//Salman Khan
		// public Integer max_words_matched;	//3
		// public String md5;	//59caf3708a04302743ee1276abfa4c3a
		public String name;	//Salman Khan
		public String name_match_type;	//PARTIAL_EXACT
		// public Integer name_score;	//100
		public String nature_of_disposal;	//
		public String oparty;	//Manish D  Vorani
		public String police_station;
		public String purpose_of_hearing;	// FOR DIRECTIONS
		public String raw_address;	//     - 1A,Galaxy apartments B.J.Road,Band Stand Bandra W,Mumbai50.
		public String registration_date;	//2015-05-19
		// public Double score;	//87.19999999999999
		public String source;	//ecourt
		// public Integer state_code;	//1
		public String state_match;	//match
		public String state_name;	//Maharashtra
		// public Integer total_name_match;	//3
		// public Integer type;	//1
		public String under_acts;	// Civil Procedure Code
		public String under_sections;	// 9
		public String uniq_case_id;	//9b92d4fb90e054cedeaf3dccf4997302
		public String verifycode;	//BCAA
		public List<String> words_matched;
	}

	// public class group_by {
    //     public String test;
	// }
    public SHF_LitigationinstantResultParser(){
        cases = null;
        flexi_search_id = '';
        flexi_source_id = '';
        // group_by = null;
        message = '';
        numresults = 0;
        status = 0;
    }
	public static SHF_LitigationinstantResultParser parse(String json){
        system.debug('apex class - '+json);
		return (SHF_LitigationinstantResultParser) System.JSON.deserialize(json, SHF_LitigationinstantResultParser.class);
	}
}