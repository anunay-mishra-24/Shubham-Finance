/**
* @File Name          : SHF_Discover_Service.cls
* @Description        : Discover API to fetch the details and create E-Verification Record
* @Author             : Riteek Tiwari
*
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         31-01-2026            Riteek Tiwari        Initial Version
*/
public with sharing class SHF_Discover_Service {
    
    SHF_HTTPCalloutService service;
    
    public static String callDiscoverAPI(Id loanApplicantId) {
        
        String message = '';
        Savepoint sp;
        
        try {
            Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('DISCOVER_API');
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType });
            Loan_Applicant__c applicant =  new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ loanApplicantId })[0];
            
            if (applicant == null) {
                return messageConfigMap.get('Applicant_Not_Found').Message__c;
            }
            
            /*Address Fetch*/
            List<Address__c> addresses = new SHF_AddressesSelector().fetchAddressesForAPI(applicant.Id);
            Address__c currentAddress;
            Address__c permanentAddress;
            Address__c otherAddress;
            
            for (Address__c addr : addresses) {
                if (addr.Mailing_Address__c == 'Current Address' && currentAddress == null) {
                    currentAddress = addr;
                }
                if (addr.Mailing_Address__c == 'Permanent Address' && permanentAddress == null) {
                    permanentAddress = addr;
                }
                if ((addr.Mailing_Address__c == 'Residential Address' || addr.Mailing_Address__c == 'Office Address') && otherAddress == null) {
                    otherAddress = addr;
                }
            }
            
            List<Employment__c> employments = new SHF_EmployerSelector().selectCreateCustomerLMSApplicant(applicant.Id);            
            Employment__c emp;
            if (!employments.isEmpty()) {
                emp = employments[0]; 
            } 
            
            //Father Full Name
            String fatherFullName = applicant.Fathers_Name__c;
            String fatherFirst = '';
            String fatherMiddle = '';
            String fatherLast = '';
            
            if (!String.isBlank(fatherFullName)) {
                fatherFullName = fatherFullName.replace('MR ', '').replace('MRS ', '').replace('MS ', '').trim();
                List<String> nameParts = fatherFullName.split('\\s+');
                if (nameParts.size() == 1) {
                    fatherFirst = nameParts[0];
                }
                else if (nameParts.size() == 2) {
                    fatherFirst = nameParts[0];
                    fatherLast  = nameParts[1];
                }
                else if (nameParts.size() >= 3) {
                    fatherFirst = nameParts[0];
                    fatherLast  = nameParts[nameParts.size() - 1];
                    for (Integer i = 1; i < nameParts.size() - 1; i++) {
                        fatherMiddle += nameParts[i] + ' ';
                    }
                    fatherMiddle = fatherMiddle.trim();
                }
            }
            
            Map<String, String> genderMap = new Map<String, String>{ 'Male' => 'MALE', 'Female' => 'FEMALE', 'Third Gender' => 'TRANSGENDER' };
                String genderValue = genderMap.containsKey(applicant.Gender__c) ? genderMap.get(applicant.Gender__c) : '';
            
            Map<String, String> maritalMap = new Map<String, String>{'Single' => 'UN_MARRIED','Divorced' => 'UN_MARRIED','Widow' => 'UN_MARRIED', 'Married'  => 'MARRIED'};
                String maritalValue = maritalMap.containsKey(applicant.Marital_Status__c)? maritalMap.get(applicant.Marital_Status__c) : '';
            
            Map<String, String> employmentMap = new Map<String, String>{'Salaried' => 'SALARIED', 'Self-Employed' => 'SELF_EMPLOYED'};
                String empTypeValue = employmentMap.containsKey(applicant.Employment_Type__c) ? employmentMap.get(applicant.Employment_Type__c) : '';
            
            SHF_Discover_Service discoverService = new SHF_Discover_Service();
            discoverService.service = new SHF_HTTPCalloutService('DISCOVER_API');
            
            String requestBody = discoverService.service.getRequestBody();
            requestBody = requestBody.replace('<firstName>', applicant.First_Name__c != null ? applicant.First_Name__c : '');
            requestBody = requestBody.replace('<lastName>', applicant.Last_Name__c != null ? applicant.Last_Name__c : '');
            requestBody = requestBody.replace('<middleName>', applicant.Middle_Name__c != null ? applicant.Middle_Name__c : '');
            requestBody = requestBody.replace('<dob>', applicant.Date_of_Birth__c != null ? String.valueOf(applicant.Date_of_Birth__c) : '');            
            requestBody = requestBody.replace('<fatherFirstName>', fatherFirst != null ? fatherFirst : '');
            requestBody = requestBody.replace('<fatherMiddleName>', fatherMiddle != null ? fatherMiddle : '');
            requestBody = requestBody.replace('<fatherLastName>', fatherLast != null ? fatherLast : '');            
            requestBody = requestBody.replace('<gender>', genderValue);
            requestBody = requestBody.replace('<employmentType>', empTypeValue);           
            requestBody = requestBody.replace('<mobile>', applicant.Mobile_Number__c != null ? applicant.Mobile_Number__c : '');
            requestBody = requestBody.replace('<email>', applicant.Email__c != null ? applicant.Email__c : '');            
            requestBody = requestBody.replace('<pan>', applicant.PAN_Number__c != null ? applicant.PAN_Number__c : '');
            requestBody = requestBody.replace('<voterId>', applicant.Voter_Id_Number__c != null ? applicant.Voter_Id_Number__c : '');
            requestBody = requestBody.replace('<dlNumber>', applicant.Driving_License_Number__c != null ? applicant.Driving_License_Number__c : '');
            requestBody = requestBody.replace('<maritalStatus>', maritalValue); 
            requestBody = requestBody.replace('<accountNumber>', '916010051050251'); 
            requestBody = requestBody.replace('<ifsc>', 'UTIB0000653'); 
            requestBody = requestBody.replace('<caseId>', '123456');            
            //requestBody = requestBody.replace('<notificationEmail>', applicant.Email__c != null ? applicant.Email__c : '');
            //requestBody = requestBody.replace('<notificationEmail>','shf_discoveremail@4-156h6cd6l1x8zf056bs5i32plpkmd10m161hp68dbqbibw8zz9.c1-2wotpmas.ind16s.apex.sandbox.salesforce.com');
            requestBody = requestBody.replace('<notificationEmail>', getDiscoverNotificationEmail());
            requestBody = requestBody.replace('<entityId>',emp != null && emp.entityId__c != null ? emp.entityId__c : '');
            requestBody = requestBody.replace('<uan1>',emp != null && emp.uans__c != null ? String.valueOf(emp.uans__c) : '100241731095');
            requestBody = requestBody.replace('<uan2>',emp != null && emp.uans__c != null ? String.valueOf(emp.uans__c) : '100946379154');
            requestBody = requestBody.replace('<employerName>',emp != null && emp.Business_Employer_Name__c != null ? emp.Business_Employer_Name__c : 'test'); 
            requestBody = requestBody.replace('<employmentStart>',emp != null && emp.Employed_From__c != null ? formatDate(emp.Employed_From__c) : '2020-08-09');
            requestBody = requestBody.replace('<employmentEnd>',emp != null && emp.Employed_Till__c != null ? formatDate(emp.Employed_Till__c) : '2021-08-09'); 
            requestBody = requestBody.replace('<salaryPerMonth>',applicant.Total_Income__c != null ? String.valueOf(applicant.Total_Income__c.setScale(0)) : '20000');
            requestBody = requestBody.replace('<employerAddressLine1>', '1302, Orchid, Bg Kher Road Campacola Compound, Worli'); 
            requestBody = requestBody.replace('<employerAddressLine2>', 'Worli, Mumbai');
            requestBody = requestBody.replace('<employerCity>', 'MUMBAI');
            requestBody = requestBody.replace('<employerState>', 'MAHARASHTRA');
            requestBody = requestBody.replace('<employerPincode>', '400018');
            
            
            /*Current Address*/
            if (currentAddress != null) {
                requestBody = requestBody.replace('<currentAddressLine1>', currentAddress.Address_Line_1__c != null ? currentAddress.Address_Line_1__c : 'Current NO 16 9TH CROSS 8TH MAIN BHUVANESHWARINAGAR T');
                requestBody = requestBody.replace('<currentAddressLine2>', currentAddress.Address_Line_2__c != null ? currentAddress.Address_Line_2__c : 'BANGALORE NORTH TQ BANGALORE');
                requestBody = requestBody.replace('<currentCity>', currentAddress.City__c != null ? currentAddress.City__c : 'BANGALORE');
                requestBody = requestBody.replace('<currentState>', currentAddress.State__c != null ? currentAddress.State__c : 'KARNATAKA');
                String currentPincode = currentAddress != null && currentAddress.Pincode__r != null ? currentAddress.Pincode__r.Name : '560057';
                requestBody = requestBody.replace('<currentPincode>', currentPincode);
            }
            
            /*Permanent Address*/
            if (permanentAddress != null) {
                requestBody = requestBody.replace('<permAddressLine1>', permanentAddress.Address_Line_1__c != null ? permanentAddress.Address_Line_1__c : 'Permanent NO 16 9TH CROSS 8TH MAIN BHUVANESHWARINAGAR T');
                requestBody = requestBody.replace('<permAddressLine2>', permanentAddress.Address_Line_2__c != null ? permanentAddress.Address_Line_2__c : 'BANGALORE NORTH TQ BANGALORE');
                requestBody = requestBody.replace('<permCity>', permanentAddress.City__c != null ? permanentAddress.City__c : 'BANGALORE');
                requestBody = requestBody.replace('<permState>', permanentAddress.State__c != null ? permanentAddress.State__c : 'KARNATAKA');
                String permanentPincode = permanentAddress != null && permanentAddress.Pincode__r != null ? permanentAddress.Pincode__r.Name : '560057';
                requestBody = requestBody.replace('<permPincode>', permanentPincode);
            }
            
            /*Other Address*/
            if (otherAddress != null) {
                requestBody = requestBody.replace('<otherAddressLine1>', otherAddress != null && otherAddress.Address_Line_1__c != null ? otherAddress.Address_Line_1__c : '');
                requestBody = requestBody.replace('<otherAddressLine2>', otherAddress != null && otherAddress.Address_Line_2__c != null ? otherAddress.Address_Line_2__c : '');
                requestBody = requestBody.replace('<otherCity>', otherAddress != null && otherAddress.City__c != null ? otherAddress.City__c : '');
                requestBody = requestBody.replace('<otherState>', otherAddress != null && otherAddress.State__c != null ? otherAddress.State__c : '');
                String otherPincode = otherAddress != null && otherAddress.Pincode__r != null ? otherAddress.Pincode__r.Name : '560057';
                requestBody = requestBody.replace('<otherPincode>', otherPincode);
            }
            
            discoverService.service.setRequestBody(requestBody);
            
            HttpResponse response;
            if (discoverService.service.getIsActive()) {
                response = discoverService.service.sendRequest();
                sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(discoverService.service.getmockRespnse());
            }
            
            E_Verification__c Everification = SHF_CommonUtil.createVerfication( applicant.Id, SHF_ConstantsUtil.DISCOVER_RECORD_TYPE, SHF_ConstantsUtil.INPROGRESS_STATUS );
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if (responseMap != null) {
                    Everification.Raw_Response__c = response.getBody();
                    
                    // Store Request Id
                    Everification.Request_Id__c = responseMap.get('request_id') != null ? String.valueOf(responseMap.get('request_id')) : '';
                    
                    // Store Status Code
                    Everification.Description__c = responseMap.get('status-code') != null ? String.valueOf(responseMap.get('status-code')) : '';
                    
                    // Store Result Message
                    if (responseMap.containsKey('result')) {
                        Map<String, Object> resultMap = (Map<String, Object>) responseMap.get('result');
                        Everification.Message__c = resultMap.get('message') != null ? String.valueOf(resultMap.get('message')) : '';
                    }
                    
                    // Store CaseId
                    if (responseMap.containsKey('clientData')) {
                        Map<String, Object> clientMap = (Map<String, Object>) responseMap.get('clientData');
                        Everification.CaseId__c = clientMap.get('caseId') != null ? String.valueOf(clientMap.get('caseId')) : '';
                    }
                    Everification.Status__c = SHF_ConstantsUtil.COMPLETEDSTATUS;
                    message = messageConfigMap.get('DISCOVER_SUCCESS').Message__c;
                    
                }
            } else {
                Everification.Status__c = SHF_ConstantsUtil.FAILED_STATUS;
                message = messageConfigMap.get('DISCOVER_ERROR').Message__c;
            }
            
            uow.registerNew(Everification);
            uow.commitWork();
            
            if (Everification.Id != null) {
                Loan_Applicant__c laUpdate = new Loan_Applicant__c();
                laUpdate.Id = applicant.Id;
                laUpdate.Discover_Verification__c = Everification.Id;
                update laUpdate;
            }
            
            
            Logger.info('Discover Request :: ' + requestBody);
            Logger.info('Discover Response :: ' + response.getBody());
            
        } catch (Exception ex) {
            if (sp != null) Database.rollback(sp);
            Logger.error('Discover API Error :: ' + ex.getMessage() +' LineNumber >> '+ex.getLineNumber());
        } finally {
            Logger.saveLog();
        }
        
        return message;
    }
    
    public static String formatDate(Date dt) {
        if (dt == null) return '';
        return dt.year() + '-' +
            String.valueOf(dt.month()).leftPad(2, '0') + '-' +
            String.valueOf(dt.day()).leftPad(2, '0');
    }
    
    public static String getDiscoverNotificationEmail() {
        EmailServicesAddress esa = [SELECT EmailDomainName FROM EmailServicesAddress WHERE DeveloperName = 'SHF_Discover' LIMIT 1];
        return 'shf_discoveremail@' + esa.EmailDomainName;
    }
}