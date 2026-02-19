public class ApplicantBureauResult {
        @AuraEnabled public String applicantName;
        @AuraEnabled public String applicantType;
    
        @AuraEnabled public Integer cibilScore;
        @AuraEnabled public Integer crifScore;
    
       //@AuraEnabled public Integer cibilEnquiries;
       //@AuraEnabled public Integer crifEnquiries;
    
       //@AuraEnabled public Integer cibilDefaults;
       //@AuraEnabled public Integer crifDefaults;
    
       //@AuraEnabled public String internalRiskRating;
       @AuraEnabled public List<String> mismatches;
}