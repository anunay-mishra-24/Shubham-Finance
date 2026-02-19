public with sharing class SHF_LitigationAdvanceReportParser {
    public Integer statusCode;	//201
	public String statusMsg;	//Report is Ready
	public Integer idc;	//1
	public String name;	//salman salim khan
	public cls_addresses[] addresses;
	public cls_matchedCaseDetails[] matchedCaseDetails;
	public String report;	//Red
	public String reportUrl;	//https://firhtml.s3.us-west-2.amazonaws.com/4f9108bfadbaba489410f0bf3b76a53f.pdf
	public String job_name;	//shubham_housing_development_mafa:04-02-2026 22:30
	public String dateOfVerification;	//2026-02-06T07:01:27.325Z
	public class cls_addresses {
		public String address;	//Galaxy Apartments Bandra Mumbai maharashtra
	}
	public class cls_matchedCaseDetails {
		public String id;	//69839a4cdf695705bc3d3268
		public String address;	//3,GALAXY APT, B J ROAD,BAND STAND ,BANDRAW MUM 50
		public Integer address_wc;	//11
		public String algo_risk;	//high risk
		public List<String> all_candidates;
		public List<String> all_orders;
		public String analysts;	//
		public String asr_info;	//negotiable instrument | 138
		public String auto_report;	//g
		public Integer auto_rr;	//0
		public String case_category;	//criminal
		public String case_code;	//
		public String case_filter;	//
		public String case_id;	//
		public String case_no;	//200312075332005
		public Integer case_no2;	//0
		public String case_stage;	//
		public String case_status;	//disposed
		public String case_type;	//
		public String case_type_code;	//3
		public String case_type_name;	//Ss casess
		public String case_year;	//2005
		public String clean_name;	//salman salim khan
		public String cnr;	//MHMM180125912007
		public String cnr_no;	//
		public String condition;	//
		public Integer court_code;	//13
		public String court_complex_code;	//1010271
		public String court_name;	//---
		public String court_no;	//
		public String court_number_and_judge;	//12 - METROPOLITAN MAGISTRATE, 12TH COURT
		public String custom_dist_code;	//00210017
		public String custom_state_code;	//0021
		public String decision;	//
		public String decision_date;	//
		public Integer dist_code;	//23
		public String dist_match;	//match
		public String dist_name;	//Mumbai
		public String dob;	//
		public String father_match_type;	//PARTIAL_EXACT
		public String father_name;	//
		public Integer father_name_match_tokens;	//0
		public String father_name_score;
		public String filing_date;	//2007-07-12
		public String filing_no;	//
		public String filing_year;	//
		public List<String> fir_copy;
		public String fir_no;	//
		public String fir_year;	//
		public String first_hearing_date;	//12th July 2007
		public Integer flexi;	//0
		public Integer gpt3;	//0
		public String gpt_raw_decision;	//
		public String gptdecision;	//
		public Integer gog;	//1
		public Integer groupValue;	//1
		public boolean jurisdiction;
		public String jurisdiction_type;	//DISTRICT
		public String lawyer_comment;	//The matching logic involves comparing key identifiers between the provided details and the court details. In this case, the name "salman salim khan" matches with "MR  SALMAN SALIM KHAN," and the father’s name "salim khan" aligns with the surname in the court name. Additionally, the address details show similarities in "Galaxy Apartments" and "Galaxy APT" as well as both locations being in Bandra, Mumbai, indicating a close match.
		public String link;	//https://mvp.verify24x7.in/live_cnr?cnr=MHMM180125912007&site=v6
		public String manual_client_qc_from_red_audit;	//r
		public String manual_report_qc;	//
		public String match_score;	//
		public String case_match_type;	//
		public String matching_criteria;	//
		public Integer max_words_matched;	//3
		public String md5;	//07e3b805330656ae21e2c305bffa4d20
		public String meta_data;
		public String name;	//MR  SALMAN SALIM KHAN
		public String name_father_score;
		public String name_match_type;	//
		public Integer name_score;	//100
		public Integer name_wc;	//4
		public String nature_of_disposal;	//Uncontested--Case Withdrawn
		public String next_hearing_date;	//N/A
		public String oparty;	//1 MS CINEVISTAAS LTD
		public Integer other_results;	//0
		public Integer partition;	//0
		public String pet_name;	//
		public String police_station;	//
		public String purpose_of_hearing;	//PART HEARD
		public String raw_address;	//3,GALAXY APT, B J ROAD,BAND STAND ,BANDRAW MUM 50
		public String raw_name;	//
		public String red_audit_comment;	//
		public String ref;	//69837becba21a69d6e677646
		public String ref_uniq_case_id;	//
		public String registration_date;	//2005-09-19
		public String registration_no;	//
		public String registration_year;	//
		public String res_name;	//
		public String repeat_address;	//
		public String risk_type;	//No Risk
		public String search_algo;	//
		public String severity;	//
		public String source;	//ecourt
		public Integer state_code;	//1
		public String state_match;	//match
		public String state_name;	//Maharashtra
		public String star_qc;	//
		public String sub_type;	//
		public String time_stamp;	//
		public Integer type;	//0
		public String type_text;	//petitioner
		public String under_acts;	//Negotiable Instrument Act
		public String under_acts_under_sections_explanation;	//**Negotiable Instruments Act**: If the cheque is dishonored for insufficiency then the defaulter should be punished with imprisonment for a term which may extend to two years, or with fine which may extend to twice the amount of the cheque, or both.
		public String under_sections;	//138
		public String uniq_case_id;	//2c3408f78a607422f88f73cb97a841c7
		public Integer watson;	//0
		public String year;	//
		public String business_category;	//Cheque Bounce
	}
	
	public static SHF_LitigationAdvanceReportParser parse(String json){
		return (SHF_LitigationAdvanceReportParser) System.JSON.deserialize(json, SHF_LitigationAdvanceReportParser.class);
	}
}