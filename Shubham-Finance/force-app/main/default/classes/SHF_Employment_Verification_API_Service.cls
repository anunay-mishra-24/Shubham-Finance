/**
* @File Name          : SHF_Employment_Verification_API_Service.cls
* @Description        : Step 1 - Employment Verification API Call.
* @Author             : Akshi Sharma 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         23-10-2025               Akshi Sharma           Split for multi-transaction callouts
*/
public with sharing class SHF_Employment_Verification_API_Service {
    
    public class VerificationResponse {
        @AuraEnabled public String message;
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String pdfLink;
    }

    @AuraEnabled
    public static void updateApplicantUAN(Id applicantId, String uanNumber) {
        if (String.isBlank(uanNumber) || !Pattern.matches('^[0-9]{12}$', uanNumber)) {
            throw new AuraHandledException('UAN must be exactly 12 digits');
        }
        try {
            Loan_Applicant__c la = [
                SELECT Id, UAN_Number__c
                FROM Loan_Applicant__c
                WHERE Id = :applicantId
                LIMIT 1
            ];
            la.UAN_Number__c = uanNumber;
            update la;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Unable to save UAN. Please try again or contact admin.'
            );
        }
    }

    @AuraEnabled
    public static VerificationResponse callEmploymentVerificationAPI(Id loanApplicantId) {
        System.debug('=== [API Service] START callEmploymentVerificationAPI for Applicant Id: ' + loanApplicantId + ' ===');
        VerificationResponse resultWrapper = new VerificationResponse();
        resultWrapper.isSuccess = false;

        Savepoint sp;
        Logger.info('--- Employment Verification API Call Started for Applicant: ' + loanApplicantId + ' ---');

        try {
            List<Loan_Applicant__c> applicants = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{loanApplicantId});
            System.debug('=== [API Service] Applicants fetched: ' + applicants.size());
            if (applicants.isEmpty()) 
                throw new AuraHandledException('Loan Applicant not found for Id: ' + loanApplicantId);

            Loan_Applicant__c applicant = applicants[0];
            System.debug('=== [API Service] Applicant details: ' + JSON.serialize(applicant));

            Callout_Framework__mdt metadata = SHF_CommonUtil.getCalloutMetadata('Employment_Verification_API').get('Employment_Verification_API');
            System.debug('=== [API Service] Metadata fetched: ' + metadata);
            if (metadata == null)
                throw new AuraHandledException('Employment Verification API metadata not configured');

            String requestBody = metadata.Body__c;
            // Replace placeholder with actual PAN
            if (String.isNotBlank(applicant.PAN_Number__c)) {
                requestBody = requestBody.replace('{panNumber}', applicant.PAN_Number__c);
                requestBody = requestBody.replace('{uanNumber}', applicant.UAN_Number__c);
            } else {
                // Optional: handle missing PAN
                System.debug('PAN_Number__c is blank. Placeholder not replaced.');
            }
            System.debug('=== [API Service] Request Body: ' + requestBody);

            SHF_HTTPCalloutService callout = new SHF_HTTPCalloutService('Employment_Verification_API');
            callout.setRequestMethod(metadata.HTTP_Method__c);
            callout.setEndpointURL(metadata.Endpoint__c);
            callout.setRequestBody(requestBody);
            callout.setHeaderParameter('Content-Type', 'application/json');

            HttpResponse response = callout.sendRequest();
            System.debug('=== [API Service] Response Status Code: ' +response.getStatusCode());
            System.debug('=== [API Service] Response Body: ' +response.getBody());
            Logger.info('--- Response: ' + response.getBody());

            sp = Database.setSavepoint();

            E_Verification__c verification = SHF_CommonUtil.createVerfication(
                applicant.Id,
                SHF_ConstantsUtil.EMPLOYMENT_VERIFICATION_RECORD_TYPE,
                SHF_ConstantsUtil.INITIATEDSTATUS
            );
            insert verification;
            System.debug('=== [API Service] Verification record inserted: ' + verification.Id);
            System.debug('=== [API Service] Verification record prepared ===');

            String pdfLink;
            Boolean isSuccess = false;

            if (response != null && response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('=== [API Service] Parsed Response: ' + JSON.serialize(parsed));

                if (parsed.containsKey('result')) {
                    Map<String, Id> evLineItemRTMap = SHF_CommonUtil.getRecordTypeMap(
                        E_Verification_Line_Item__c.SObjectType
                    );
                    
                    List<E_Verification_Line_Item__c> epfLineItems = new List<E_Verification_Line_Item__c>();
                    List<E_Verification_Line_Item__c> uanLineItems = new List<E_Verification_Line_Item__c>();
                    List<E_Verification_Line_Item__c> employerLineItems = new List<E_Verification_Line_Item__c>(); 
                    Map<String, Id> uanToLineItemId = new Map<String, Id>();

                    Map<String, Object> result = (Map<String, Object>) parsed.get('result');
                    if (result.containsKey('pdfLink')) {
                        pdfLink = (String) result.get('pdfLink');
                        verification.File_URL__c = pdfLink;
                        System.debug('=== [API Service] Extracted PDF Link: ' + pdfLink);
                    } else {
                        System.debug('=== [API Service] No pdfLink key found in result ===');
                    }
                    Map<String, Object> nameLookup;
                    if(result.containsKey('nameLookup') && result.get('nameLookup') != null){
                        nameLookup = (Map<String, Object>) result.get('nameLookup');
                        String organizationName = (String) nameLookup.get('organizationName');
                        //Boolean isNameExact     = (Boolean) nameLookup.get('isNameExact');
                        //Boolean isEmployed      = (Boolean) nameLookup.get('isEmployed');
                        //Boolean isRecent        = (Boolean) nameLookup.get('isRecent');
                        //Boolean isNameUnique    = (Boolean) nameLookup.get('isNameUnique');
                        //String employeeName     = (String) nameLookup.get('employeeName');    // Same As verification.PAN_Full_Name__c
                    }
                    
                    if (nameLookup != null && nameLookup.containsKey('epfHistory')) {
                        List<Object> epfHistoryList = (List<Object>) nameLookup.get('epfHistory');
                    
                        for (Object o : epfHistoryList) {
                            Map<String, Object> epf = (Map<String, Object>) o;
                    
                            epfLineItems.add(new E_Verification_Line_Item__c(
                                E_Verification__c = verification.Id,
                                RecordTypeId = evLineItemRTMap.get('Employment Verification EPF History'),
                                Total_Amount__c = (Decimal) epf.get('totalAmount'),
                                Total_Members__c = (String) epf.get('totalMembers'),
                                Wage_Month__c = (String) epf.get('wageMonth'),
                                Formatted_Wage_Month__c = (String) epf.get('formatted_wage_month')
                            ));
                        }
					}
                    if (result.containsKey('uan') && result.get('uan') != null) {
                        List<Object> uanList = (List<Object>) result.get('uan');
                    
                        for (Object u : uanList) {
                            Map<String, Object> uanMap = (Map<String, Object>) u;
                    
                            uanLineItems.add(new E_Verification_Line_Item__c(
                                E_Verification__c = verification.Id,
                                RecordTypeId = evLineItemRTMap.get('Employment Verification UAN'),
                                UAN_Number__c = (String) uanMap.get('uan'),
                                UAN_Source__c = (String) uanMap.get('uanSource')
                            ));
                        }
					}
                    
                    if (!epfLineItems.isEmpty()) {
                        insert epfLineItems;
                    }
                    
                    if (!uanLineItems.isEmpty()) {
                        insert uanLineItems;
                    
                        for (E_Verification_Line_Item__c li : uanLineItems) {
                            uanToLineItemId.put(li.UAN_Number__c, li.Id);
                        }
                    }
                    
                    if (result.containsKey('uan')) {
                        List<Object> uanList = (List<Object>) result.get('uan');
                    
                        for (Object u : uanList) {
                            Map<String, Object> uanMap = (Map<String, Object>) u;
                            String uanNumber = (String) uanMap.get('uan');
                    
                            Id parentUanLineItemId = uanToLineItemId.get(uanNumber);
                            if (parentUanLineItemId == null) continue;
                    
                            List<Object> employers = (List<Object>) uanMap.get('employer');
                    
                            for (Object e : employers) {
                                Map<String, Object> emp = (Map<String, Object>) e;
                    
                                employerLineItems.add(new E_Verification_Line_Item__c(
                                    E_Verification__c = verification.Id,
                                    Parent_Line_Item__c = parentUanLineItemId, // Self Lookup
                                    RecordTypeId = evLineItemRTMap.get('Employment Verification Employers'),
                    
                                    Employer_Name__c = (String) emp.get('name'),
                                    Member_Id__c = (String) emp.get('memberId'),
                                    Match_Name__c = (String) emp.get('matchName'),
                                    Start_Month_Year__c = (String) emp.get('startMonthYear'),
                                    Date_Of_Joining__c = parseDate(emp.get('dateOfJoining')),
                                    Date_Of_Exit__c = parseDate(emp.get('dateOfExit')),
                                    Is_Employed__c = (Boolean) emp.get('isEmployed'),
                                    Is_Recent__c = (Boolean) emp.get('isRecent'),
                                    Is_Name_Exact__c = (Boolean) emp.get('isNameExact'),
                                    Is_Name_Unique__c = (Boolean) emp.get('isNameUnique')
                                ));
                            }
                        }
                    }
                    
                    if (!employerLineItems.isEmpty()) {
                        insert employerLineItems;
                    }


                    /*if(nameLookup.containsKey('epfHistory')){
                        List<Object> epfHistoryList = (List<Object>) nameLookup.get('epfHistory');

                        for (Object o : epfHistoryList) {			// Handle in Child Record Of E-verification
                            Map<String, Object> epf = (Map<String, Object>) o;

                            Decimal totalAmount        = (Decimal) epf.get('totalAmount');
                            String totalMembers        = (String) epf.get('totalMembers');
                            String formattedWageMonth  = (String) epf.get('formatted_wage_month');
                            String wageMonth           = (String) epf.get('wageMonth');
                        }
                    }*/
                    /*if(result.containsKey('uan')){
                        List<Object> uanList = (List<Object>) result.get('uan');

                        for (Object u : uanList) {							// Handle in Child Record Of E-verification
                            Map<String, Object> uanMap = (Map<String, Object>) u;

                            String uanNumber = (String) uanMap.get('uan');
                            String uanSource = (String) uanMap.get('uanSource');

                            // Employers
                            List<Object> employers = (List<Object>) uanMap.get('employer');

                            for (Object e : employers) {							// Handle in Child Record Of E-verification (We Can Create Self Lookup Of Above)
                                Map<String, Object> employer = (Map<String, Object>) e;

                                String name              = (String) employer.get('name');
                                String memberId          = (String) employer.get('memberId');
                                String dateOfJoining     = (String) employer.get('dateOfJoining');
                                String dateOfExit        = (String) employer.get('dateOfExit');
                                Boolean isEmployedEmp    = (Boolean) employer.get('isEmployed');
                                Boolean isRecentEmp      = (Boolean) employer.get('isRecent');
                                Boolean isNameExactEmp   = (Boolean) employer.get('isNameExact');
                                Boolean isNameUniqueEmp  = (Boolean) employer.get('isNameUnique');
                                String matchName         = (String) employer.get('matchName');
                                String startMonthYear    = (String) employer.get('startMonthYear');
                            }
                        }
                    }*/
                    if(result.containsKey('personalInfo') && result.get('personalInfo') != null){
                        Map<String, Object> personalInfo = (Map<String, Object>) result.get('personalInfo');
                        verification.UAN__c = personalInfo != null && personalInfo.get('uan') != null ? String.valueOf(personalInfo.get('uan')) : null;
                        verification.PAN_Full_Name__c = personalInfo != null && personalInfo.get('name') != null ? String.valueOf(personalInfo.get('name')) : null;
                        verification.Date_of_Birth__c = personalInfo != null && personalInfo.get('dateOfBirth') != null ? Date.valueOf(String.valueOf(personalInfo.get('dateOfBirth'))) : null;
                        verification.Gender__c = personalInfo != null && personalInfo.get('gender') != null ? getGender(String.valueOf(personalInfo.get('gender'))) : null;
                        verification.PAN_Father_Name__c = personalInfo != null && personalInfo.get('fatherHusbandName') != null ? String.valueOf(personalInfo.get('fatherHusbandName')) : null;
                        verification.Relation__c = personalInfo != null && personalInfo.get('relation') != null ? String.valueOf(personalInfo.get('relation')) : null;
                        verification.Mobile__c = personalInfo != null && personalInfo.get('mobileNumber') != null ? String.valueOf(personalInfo.get('mobileNumber')) : null;
                        verification.Email__c = personalInfo != null && personalInfo.get('emailId') != null ? String.valueOf(personalInfo.get('emailId')) : null;
                        verification.PAN__c = personalInfo != null && personalInfo.get('pan') != null ? String.valueOf(personalInfo.get('pan')) : null;
                    }
                } else {
                    System.debug('=== [API Service] No result key found in parsed response ===');
                }

                String statusCode = (String) parsed.get('status-code');
                System.debug('=== [API Service] Parsed status-code: ' + statusCode);
                if (statusCode == '101') {
                    isSuccess = true;
                    verification.Status__c = SHF_ConstantsUtil.COMPLETEDSTATUS;
                    resultWrapper.message = 'Employment Verification Success';
                } else {
                    verification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                    verification.Failed_Reason__c = 'API returned status-code ' + statusCode;
                    resultWrapper.message = 'Employment Verification Failed';
                }
            } else {
                System.debug('=== [API Service] Invalid or Empty Response ===');
                verification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                verification.Failed_Reason__c = 'Invalid HTTP Response: ' + (response == null ? 'null' : String.valueOf(response.getStatusCode()));
                resultWrapper.message = 'Employment Verification HTTP Error';
            }

            update  verification;
            System.debug('=== [API Service] Verification record inserted: ' + verification.Id);

            applicant.Employment_Verification__c = verification.Id;
            if (isSuccess) applicant.Employment_Verification_Executed__c = true;
            applicant.Employment_Verification_Invalid__c = false;
            update applicant;
            System.debug('=== [API Service] Applicant updated. Success? ' + isSuccess);

            resultWrapper.isSuccess = isSuccess;
            resultWrapper.pdfLink = pdfLink;
            System.debug('=== [API Service] Final PDF Link being sent to LWC: ' + pdfLink);

        } catch (Exception e) {
            if (sp != null) Database.rollback(sp);
            Logger.error('Employment Verification API Error: ' + e.getMessage());
            System.debug('=== [API Service] Exception: ' + e.getMessage());
            resultWrapper.message = 'Error: ' + e.getMessage();
        } finally {
            Logger.saveLog();
        }

        Logger.info('--- Employment Verification API Call Finished ---');
        System.debug('=== [API Service] END callEmploymentVerificationAPI ===');
        return resultWrapper;
    }

    private static String getGender(String gender){
        Map<String, String> genderMap = new Map<String, String>{
            'F' => 'Female',
            'M' => 'Male',
            'N' => 'Not Specified',
            'T' => 'Transgender'
        };
        return genderMap.containsKey(gender) ? genderMap.get(gender) : '';
    }
    
	private static Date parseDate(Object val) {
        return val == null ? null : Date.valueOf(String.valueOf(val));
    }

}