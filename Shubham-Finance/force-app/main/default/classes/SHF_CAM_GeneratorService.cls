public class SHF_CAM_GeneratorService {

    public List<Loan_Applicant__c> loanApplicantList { get; set; }

    @AuraEnabled
    public static Map<String,Object> validateOnly(Id applicationId) {
        System.debug('ValidateOnly method called-->'+ applicationId);
        return validateAndGenerate(applicationId, false);
    }

    @AuraEnabled(cacheable=true)
    public static Id getPrimaryApplicant(Id applicationId) {
        Loan_Applicant__c primaryApplicant = [
            SELECT Id 
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
            AND Applicant_Type__c = 'Primary Applicant'
            LIMIT 1
        ];
        return primaryApplicant != null ? primaryApplicant.Id : null;
    }


    @AuraEnabled
    public static Map<String,Object> generatePDF(Id applicationId) {
        return validateAndGenerate(applicationId, true);
    }

    private static Map<String,Object> validateAndGenerate(Id applicationId, Boolean generate) {

        Map<String,Object> result = new Map<String,Object>();

        try {    
            
            List<String> missing = validateTheMissingFields(applicationId);
            System.debug('missing fields-->'+ missing);
            if(missing.size() > 0) {
                result.put('missing', missing);
                result.put('status','error');
                return result;
            }

                PageReference pr = Page.SHF_CAMGenerationReport;
                pr.setRedirect(false);
                pr.getParameters().put('id', applicationId);

                Blob pdfBlob = pr.getContentAsPDF();
            
            // PageReference pr = Page.SHF_CAMGenerationReport;
            // pr.getParameters().put('id', applicationId);
            // Blob pdfBlob = pr.getContentAsPDF();

            List<Document__c> docs = [
                SELECT Id, File_Name__c , Name
                FROM Document__c 
                WHERE Application__c = :applicationId
                  AND Document_Category__c = 'Loan Specific Documents'
                  AND Mandatory_Document__c = TRUE
                //   AND Name LIKE '%App CAM Report%'
                  AND File_Name__c LIKE '%App CAM Report%'
                LIMIT 1
            ];

            System.debug('docs --- ' + docs);

            String base64Pdf = EncodingUtil.base64Encode(pdfBlob);
            Document__c doc;

            if(!docs.isEmpty()) {
                doc = docs[0];
            } else {
                doc = new Document__c();
                doc.File_Name__c = 'App CAM Report';
                //doc.Name = 'Loan Application Form';
                doc.Stage__c = 'QDE';
                doc.Mandatory_Document__c = TRUE;
                doc.Document_Category__c = 'Loan Specific Documents';
                doc.Application__c = applicationId;
                doc.Status__c = 'Uploaded';
                doc.Document_Received_Date__c = Date.today();
                doc.Document_Source__c = 'API';
                
                System.debug('>>> Before Insert Source = ' + doc.Document_Source__c);
                insert doc;
                System.debug('>>> After Insert Source = ' + doc.Document_Source__c);
                System.debug('doc --- ' + doc.Id);
            }

            System.debug('doc --- 101');
            result.put('status','success');
            result.put('message','CAM Application Form generated successfully');
            result.put('docId', doc.Id);
            result.put('fileName', doc.File_Name__c);
            result.put('fileBase64', base64Pdf);
            System.debug('doc --- 102 -- ' + doc.Id + ' ' + doc.File_Name__c);
            return result;

        } catch(Exception e) {
            System.debug('doc --- 103');
            System.debug('LAF ERROR => ' + e.getMessage());
            result.put('status','error');
            result.put('message', e.getMessage());
            return result;
        }
    }

    @AuraEnabled
    public static void markCAMGenerated(Id applicationId){
        Application__c app = new Application__c(
            Id = applicationId,
            CAM_Generation_Date_Time__c = Datetime.now()
        );
        update app;
    }
    
    private static List<String> validateTheMissingFields(Id applicationId){
        List<String> missingFields = new List<String>();
        Boolean areAllApplicantsInsured = false;
        List<Loan_Applicant__c> loanApplicantList = new List<Loan_Applicant__c>();
        Set<Id> loanApplicantIds = new Set<Id>();
        List<Bureau_BSA_Detail__c> bureauList = new List<Bureau_BSA_Detail__c>();
        Map<Id,Bureau_BSA_Detail__c> bureauMap = new Map<Id, Bureau_BSA_Detail__c>();
        List<Employment__c> employmentList = new List<Employment__c>();
        Map<Id,Employment__c> employmentMap = new Map<Id, Employment__c>();
        List<Personal_Discussion__c> personalDList = new List<Personal_Discussion__c>();
        Map<Id,Personal_Discussion__c> personalDMap = new Map<Id, Personal_Discussion__c>();
        // Set<Id> insuranceIds = new Set<Id>();
        // List<E_Verification__c> evarificationList = new List<E_Verification__c>();
        // Map<Id,E_Verification__c> insuranceMap = new Map<Id, E_Verification__c>();
        
        // fetch Verification Details
        loanApplicantList = [SELECT Id, Name, Account_Name__c, Insurance_Verification__r.RecordType.Name
                             FROM Loan_Applicant__c 
                             WHERE Application__c = :applicationId AND IsDeleted__c = false ];

        // evarificationList = [SELECT Id, Name, RecordType.Name 
        //                     FROM E_Verification__c 
        //                     WHERE RecordType.Name='Insurance' and Loan_Application__c =: applicationId];
        
        for(Loan_Applicant__c applicant : loanApplicantList){
            loanApplicantIds.add(applicant.Id);
            // insuranceIds.add(applicant.Insurance_Verification__c);
        }

        bureauList = [SELECT Id, Name, Loan_Applicant__c
                      FROM Bureau_BSA_Detail__c
                      WHERE Loan_Applicant__c IN :loanApplicantIds];
        
        employmentList = [SELECT Id, Name, Loan_Applicant__c
                      FROM Employment__c
                      WHERE Loan_Applicant__c IN :loanApplicantIds];

        personalDList = [SELECT Id, Name, Loan_Applicant__c
                      FROM Personal_Discussion__c
                      WHERE Loan_Applicant__c IN :loanApplicantIds];
        
        // for(E_Verification__c evarForInsurance : insuranceIds){
        //     insuranceMap.put(evarForInsurance.Insurance_Verification__c, evarForInsurance);
        // }

        for(Bureau_BSA_Detail__c bureau : bureauList){
            bureauMap.put(bureau.Loan_Applicant__c, bureau);
        }
        
        for(Employment__c emp : employmentList){
            employmentMap.put(emp.Loan_Applicant__c, emp);
        }
        
        for(Personal_Discussion__c pd : personalDList){
            personalDMap.put(pd.Loan_Applicant__c, pd);
        }

        for(Loan_Applicant__c applicant : loanApplicantList){
            if(applicant.Insurance_Verification__r.RecordType.Name != 'Insurance'){
                missingFields.add('Applicant - ' + applicant.Account_Name__c + ' is not Insured Or This Applicant\'s Verification Type is other than Insurance');
            }
            if(!bureauMap.containsKey(applicant.Id)){
                //missingFields.add('Applicant - ' + applicant.Account_Name__c + ' does not have Bureau record');
            }

            if(!employmentMap.containsKey(applicant.Id)){
                missingFields.add('Applicant - ' + applicant.Account_Name__c + ' does not have employment record');
            }

            if(!personalDMap.containsKey(applicant.Id)){
                missingFields.add('Applicant - ' + applicant.Account_Name__c + ' does not have Personal Discussion record');
            }
        }

        //All Objects Records Availability Check
        if([SELECT Id FROM VAP__c WHERE Application__c = :applicationId].size() == 0){
            missingFields.add('VAP Record not found');
        }
        if([SELECT ID FROM Loan_Applicant__c WHERE Application__c = :applicationId].size() == 0){
            missingFields.add('Loan Applicant Record not found');
        }
        if([SELECT Id FROM E_Verification__c WHERE Loan_Application__c = :applicationId].size() == 0){
            missingFields.add('E Verification Record not found');
        }
        if([SELECT Id FROM Deviation_and_Sanction_Condition__c WHERE Loan_Application__c = :applicationId].size() == 0){
            //missingFields.add('Deviation Record not found');
        }
        if([SELECT Id FROM Bank_Details__c WHERE Application__c = :applicationId].size() == 0){
            //missingFields.add('Bank_Details Record not found');
        }
        if([SELECT Id FROM Obligation__c WHERE Application__c = :applicationId].size() == 0){
            //missingFields.add('Obligation Record not found');
        }

        return missingFields;
    }

}