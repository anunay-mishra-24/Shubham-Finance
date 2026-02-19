public class SHF_BureauComparisonService {
    
    @AuraEnabled
    public static BureauComparisonResult compareBureau(Id applicationId){
        List<Loan_Applicant__c> applicants = [
            SELECT Id, Name, Applicant_Type__c
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
        ];
        List<E_Verification__c> bureauRecords = [
            SELECT Loan_Applicant__c,
                   RecordType.Name,
                   Score__c
            FROM E_Verification__c
            WHERE Loan_Application__c = :applicationId
            AND RecordType.Name IN ('CRIF','CIBIL')
        ];
        
        Map<Id, Map<String, E_Verification__c>> bureauMap = new Map<Id, Map<String, E_Verification__c>>();

        for (E_Verification__c ev : bureauRecords) {
            if (!bureauMap.containsKey(ev.Loan_Applicant__c)) {
                bureauMap.put(ev.Loan_Applicant__c, new Map<String, E_Verification__c>());
            }
            bureauMap.get(ev.Loan_Applicant__c).put(ev.RecordType.Name, ev);
        }

		BureauComparisonResult response = new BureauComparisonResult();
        response.applicants = new List<ApplicantBureauResult>();
        
        for (Loan_Applicant__c applicant : applicants) {
        
            ApplicantBureauResult res = new ApplicantBureauResult();
            res.applicantName = applicant.Name;
            res.applicantType = applicant.Applicant_Type__c;
            res.mismatches = new List<String>();
        
            Map<String, E_Verification__c> bureauByType =
                bureauMap.get(applicant.Id);
        
            if (bureauByType != null) {
        
                E_Verification__c cibil = bureauByType.get('CIBIL');
                E_Verification__c crif = bureauByType.get('CRIF');
        
                if (cibil != null) {
                    res.cibilScore = Integer.valueOf(cibil.Score__c);
                    //res.cibilEnquiries = (Integer)cibil.Enquiry_Count__c;
                    //res.cibilDefaults = (Integer)cibil.Defaults_Count__c;
                }
        
                if (crif != null) {
                    res.crifScore = Integer.valueOf(crif.Score__c);
                    //res.crifEnquiries = (Integer)crif.Enquiry_Count__c;
                    //res.crifDefaults = (Integer)crif.Defaults_Count__c;
                }
        
                if (res.cibilScore != res.crifScore) {
                    res.mismatches.add('Score mismatch');
                }
        
                /*if (res.cibilDefaults != res.crifDefaults) {
                    res.mismatches.add('Default mismatch');
                }
        
                if (res.cibilEnquiries != res.crifEnquiries) {
                    res.mismatches.add('Enquiry mismatch');
                }
        
                // Risk rating
                if (res.cibilDefaults > 0 || res.crifDefaults > 0) {
                    res.internalRiskRating = 'High Risk';
                } else if (res.cibilEnquiries > 5 || res.crifEnquiries > 5) {
                    res.internalRiskRating = 'Medium Risk';
                } else {
                    res.internalRiskRating = 'Low Risk';
                }*/
            }
        
            response.applicants.add(res);
        }     
        return response;                   
    }
    
}