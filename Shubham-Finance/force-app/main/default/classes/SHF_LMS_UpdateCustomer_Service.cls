/**
 * @File Name          : SHF_LMS_UpdateCustomer_Service.cls
 * @Description        : API to update customer for both Individual and Non-Individual
 * @Author             : Vikas Soni
 * @Test Class         :
 *==============================================================================
 * Ver          Date            Author            Modification
 *==============================================================================
 * 1.0       12-01-2026      Vikas Soni       Initial Version
 */
public with sharing class SHF_LMS_UpdateCustomer_Service {
    public SHF_HTTPCalloutService service;
    public static String updateCustomer(String applicationId, String applicantId, String customerType){
        String message = '';
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Loan_Applicant__c.SObjectType});
        try {
            if(String.isNotBlank(applicantId)){
                String accessToken = SHF_LMSCommonUtil.generateAccessToken();
                Logger.info('Access Token : '+accessToken);
                // get applicant details
                Loan_Applicant__c loanApplicant = new SHF_LoanApplicantsSelector().selectCreateCustomerLMSApplicant(applicantId);//Added By Vikas Soni
                
                system.debug('loanApplicant : '+loanApplicant);
                if(loanApplicant.Is_Customer_Updated_LMS__c){
                    if(String.isNotBlank(accessToken)){
                        
                        
                        //get api details from metadata
                        SHF_LMS_CreateCustomer_Service updateCustomerService = new SHF_LMS_CreateCustomer_Service();
                        updateCustomerService.service = new SHF_HTTPCalloutService('LMS_Update_Customer_Both');
                        updateCustomerService.service.setHeaderParameter('access_token', accessToken);
                        //body work pending here
                        
                        String requestJson = generateBody(loanApplicant,customerType);
                        updateCustomerService.service.setRequestBody(requestJson);
                        HttpResponse response;
                        if (updateCustomerService.service.getIsActive()) {
                            response = updateCustomerService.service.sendRequest();
                        } else {
                            response = new HttpResponse();
                            response.setStatusCode(200);
                            response.setBody(updateCustomerService.service.getmockRespnse());
                        }
                        Logger.info('Create Customer Request : '+updateCustomerService.service.getRequestBody());
                        Logger.info('Create Customer Response : '+response.getBody());
                        Logger.info('Create Customer Endpoint : '+updateCustomerService.service.getEndpointURL());
                        Logger.info('Create Customer Method : '+updateCustomerService.service.getRequestMethod());
                        
                        if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                            SHF_LMS_CreateCustomerParser createCustomerParser = new SHF_LMS_CreateCustomerParser();
                            createCustomerParser = SHF_LMS_CreateCustomerParser.parse(response.getBody());
                            if(createCustomerParser != null){
                                if(createCustomerParser.status.equals('SUCCESS')){
                                    loanApplicant.Customer_Info_File_Number__c =  createCustomerParser.customerInfoFileNumber;
                                    loanApplicant.Is_Customer_Updated_LMS__c = false;
                                    uow.registerDirty(loanApplicant);
                                    uow.commitWork();
                                    Logger.info('SUCCESS : '+createCustomerParser.messageDescription);
                                    message = 'SUCCESS';
                                }
                                else{
                                    Logger.error('Getting error message : '+createCustomerParser.messageDescription);
                                }
                            }else{
                                Logger.error('error please check and try again ');
                            }
                            uow.registerDirty(loanApplicant);
                            uow.commitWork();
                            Logger.info('SUCCESS');
                            message = 'SUCCESS';
                        }
                        else{
                            Logger.error('Getting this error : ' );
                        }
                    }
                    else{
                        Logger.error('Access token is blank');
                        return 'Access token is blank';
                    }
                }
                else{
                    Logger.info('NO LMS Details are changes for this applicant');
                    return 'NO LMS Details are changes for this applicant';
                }
            }
            else {
                message = 'Applicant Id Not present';
                Logger.error('Applicant Id Not present');
            }
        } catch (Exception e) {
            Logger.error('Getting Error : ' + e.getMessage() + 'at line - ' +e.getLineNumber() );
        }
        finally {
            Logger.saveLog();
        }
        
        return message;
    }
    private static String generateBody(Loan_Applicant__c applicant, String customerType){
        Boolean isIndiviual = false;
        if(customerType == 'Individual'){
            isIndiviual = true;
        }
        else if(customerType == 'Non Individual'){
            isIndiviual = false;
        }
        
        List<Address__c> addressList = new SHF_AddressesSelector().selectAddressesForLMS(applicant.Id);
        List<Bank_Details__c> bankDetailList = new SHF_BankDetails_Selector().selectByIds(applicant.Id);
        List<Employment__c> employmentList = new SHF_EmployerSelector().selectCreateCustomerLMSApplicant(applicant.Id);
        Set<String> selectedAPIs= new Set<String>();
        if(isIndiviual){
            selectedAPIs.add('LMS_Create_Customer_Individual');
        }
        else{
            selectedAPIs.add('LMS_Create_Customer_Non_Individual');
        }
        List<API_codes__mdt> apiCodesList = new SHF_APICodes_Selector().selectByIds(selectedAPIs);
        Map<String,String> apiCodesMap = new Map<String,String>();
        for(API_codes__mdt apiCode : apiCodesList){
            apiCodesMap.put(apiCode.Label, apiCode.Value__c);
        }
        Logger.info('apicodes map : '+apiCodesMap);
        System.debug('apiCodesMap - '+apiCodesMap);
        
        
        
        String requestJson = '';
        requestJson += '{';
        Logger.info('productProcessor :  '+apiCodesMap.get('productProcessor'));
        requestJson += '"productProcessor": "'+(apiCodesMap.containsKey('productProcessor') ? apiCodesMap.get('productProcessor') : '')+'",';
        requestJson += '"requestReferenceNumber": "';
        requestJson += applicant.Id;
        requestJson += '",';
        requestJson += '"updateGlobalCustomer": {';  // updateGlobalCustomer start here
        requestJson += '"associatedLoanAppId": "'+(String.isNotBlank(applicant.Application__r.Name) ? applicant.Application__r.Name : '')+'",';
        requestJson += '"customerInfoFileNumber": "'+(String.isNotBlank(applicant.Customer_Info_File_Number__c) ? applicant.Customer_Info_File_Number__c : '')+'",';
        
        // if(isIndiviual){
        //     requestJson += '"personInfo": {'; // personInfo start here
        //     requestJson += '"accountType": "",';
        //     // requestJson += '"aliasName": "qwe",';
        //     requestJson += '"constitutionCode": "';
        //     requestJson += apiCodesMap.containsKey('Individual')? apiCodesMap.get('Individual') : '';
        //     requestJson += '",';
        //     requestJson += '"customerCategoryCode": "';
        //     requestJson += applicant.Caste_Category__c;
        //     requestJson += '",';
        //     requestJson += '"customerSegmentCode": "",';// as per sheet
        //     requestJson += '"dateOfBirth": "';
        //     requestJson += String.valueOf(applicant.Date_of_Birth__c);
        //     requestJson += '",';
        //     requestJson += '"disability": "';
        //     requestJson += String.isNotBlank(applicant.Person_With_Disabilities__c) ? applicant.Person_With_Disabilities__c.toUpperCase() : '';
        //     requestJson += '",';
        //     requestJson += '"fatherName": "';
        //     requestJson += applicant.Fathers_Name__c;
        //     requestJson += '",';
        //     requestJson += '"firstName": "' + (String.isNotBlank(applicant.First_Name__c) ? applicant.First_Name__c : '' )+ '",';
        //     requestJson += '"fourthName": "",';
        //     requestJson += '"fullName": "'+ applicant.Name+'",';
        //     requestJson += '"genderCode": "';
        //     requestJson += applicant.Gender__c.toUpperCase();
        //     requestJson += '",';
        //     requestJson += '"guardianName": "",';
        //     requestJson += '"husbandName": "",';
        //     requestJson += '"lastName": "'+applicant.Last_Name__c+'",';
        //     requestJson += '"maidenFirstName": "",';
        //     requestJson += '"maidenLastName": "",';
        //     requestJson += '"maidenMiddleName": "",';
        //     requestJson += '"maidenSalutation": "",';
        //     requestJson += '"maritalStatusCode": "';
        //     requestJson += applicant.Marital_Status__c;
        //     requestJson += '",';
        //     requestJson += '"middleName": "'+(String.isNotBlank(applicant.Middle_Name__c) ? applicant.Middle_Name__c : '' )+'",';
        //     requestJson += '"motherName": "'+(String.isNotBlank(applicant.Mothers_Name__c) ? applicant.Mothers_Name__c : '' )+'",';
        //     requestJson += '"mothersMaidenName": "",';
        //     requestJson += '"nationality": "'+(apiCodesMap.containsKey('nationality') ? apiCodesMap.get('nationality') : '')+'",';
        //     requestJson += '"placeOfBirth": "",';
        //     requestJson += '"religion": "';
        //     requestJson += applicant.Religion__c;
        //     requestJson += '",';
        //     requestJson += '"residentType": "",';
        //     requestJson += '"salutationCode": "'+ applicant.Salutation__c.toUpperCase() +'"';
            
        //     requestJson += '},'; // personInfo end here
        // }
        // else{

            
        //     requestJson += '"personInfo": null,'; 
        // }
        if(isIndiviual){
            requestJson += '"personInfo": {';
            requestJson += '"recordId": 0,'; // Not present in intigration sheet but present in request
            requestJson += '"salutationCode": "'+ applicant.Salutation__c.toUpperCase() +'",'; //fixing now but then from metadata
            requestJson += '"salutationId": 0,'; // Not present in intigration sheet but present in request
            requestJson += '"firstName": "' + (String.isNotBlank(applicant.First_Name__c) ? applicant.First_Name__c : '' ) + '",';
            requestJson += '"middleName": "'+(String.isNotBlank(applicant.Middle_Name__c) ? applicant.Middle_Name__c : '' )+'",';
            requestJson += '"lastName": "'+applicant.Last_Name__c+'",';
            requestJson += '"fourthName": "",';  // Not present in intigration sheet but present in request passing blank as now
            requestJson += '"fullName": "'+ applicant.Name+'",';
            // requestJson += '"aliasName": "",'; // Not required
            requestJson += '"genderCode": "';
            requestJson += applicant.Gender__c.toUpperCase();
            requestJson += '",';
            // requestJson += '"genderId": 0,';// Not present in intigration sheet but present in request passing commenting as now
            requestJson += '"fatherName": "';
            requestJson += applicant.Fathers_Name__c;
            requestJson += '",';
            requestJson += '"mothersMaidenName": null,'; // as per sheet
            requestJson += '"husbandName": null,';  // as per sheet
            requestJson += '"guardianName": null,';  // as per sheet
            requestJson += '"dateOfBirth": "';
            requestJson += String.valueOf(applicant.Date_of_Birth__c); // as per document
            requestJson += '",';
            requestJson += '"placeOfBirth": null,'; // as per sheet
            requestJson += '"maritalStatusCode": "';
            requestJson += applicant.Marital_Status__c;
            requestJson += '",';
            // requestJson += '"maritalStatusId": 0,';// Not present in intigration sheet but present in request passing commenting as now
            requestJson += '"constitutionCode": "';
            requestJson += apiCodesMap.containsKey('Individual')? apiCodesMap.get('Individual') : '';   // need to discuss because passing code
            // requestJson += applicant.Constitution__c;   // need to discuss because passing code
            requestJson += '",';
            // requestJson += '"constitutionId": 0,';// Not present in intigration sheet but present in request passing commenting as now
            requestJson += '"customerSegmentCode": "",'; // passing null because it was optional in sheet but allowed value as per doc. are ( ALLOWED:New customer, Preferred Customer, HNI).
            // requestJson += '"customerSegmentId": 0,'; //Not present in intigration sheet but present in request passing commenting as now
            requestJson += '"customerCategoryCode": "';
            requestJson += applicant.Caste_Category__c; // as per sheet and doc
            requestJson += '",';
            // requestJson += '"customerCategoryId": 0,';   // Not present in intigration sheet but present in request passing commenting as now
            requestJson += '"householdTypeCode": "",';  // need discusstion
            // requestJson += '"householdTypeId": 0,';  // Not present in intigration sheet but present in request passing commenting as now
            requestJson += '"nationality": "'+(apiCodesMap.containsKey('nationality') ? apiCodesMap.get('nationality') : '')+'",'; //fixing now but then from metadata
            requestJson += '"residentType": null,'; // as per sheet
            // requestJson += '"residentTypeId": 0,';
            requestJson += '"disability": "';
            requestJson += String.isNotBlank(applicant.Person_With_Disabilities__c) ? applicant.Person_With_Disabilities__c.toUpperCase() : '';
            requestJson += '",';
            // requestJson += '"disabilityId": 0,';
            // requestJson += '"relationshipType": "string",';  // not in sheet but in request commenting as now
            // requestJson += '"relationshipTypeId": 0,';
            // requestJson += '"bankEmpId": "string",';
            // requestJson += '"bankEmpName": "string",';
            // requestJson += '"dynamicFormJson": "string",';
            requestJson += '"accountType": null,';  // as per sheet passing null non mandatory
            // requestJson += '"accountTypeId": 0,';
            requestJson += '"maidenSalutation": null,'; // as per sheet passing null non mandatory
            // requestJson += '"maidenSalutationId": 0,'; // not in sheet
            requestJson += '"maidenFirstName": null,'; // as per sheet passing null non mandatory
            requestJson += '"maidenMiddleName": null,'; // as per sheet
            requestJson += '"maidenLastName": null,'; // as per sheet
            requestJson += '"religion": "';
            requestJson += applicant.Religion__c;
            requestJson += '",';
            // requestJson += '"religionTypeId": 0,';
            // requestJson += '"photoUrl": "string",';
            // requestJson += '"signatureUrl": "string",';
            // requestJson += '"ekycFlag": "Y",';
            // requestJson += '"ekycMethod": "AADHAAR_NO",';
            // requestJson += '"consentReceived": "Y",';
            // requestJson += '"consentImageVersion": "1.0",';
            // requestJson += '"consentImage": "",';
            // requestJson += '"ekycVerificationType": "OTP_EKYC",';
            // requestJson += '"isPep": true';
            requestJson = requestJson.endsWith(',') ? requestJson.removeEnd(',') : requestJson;
            requestJson += '},';   // personInfo end here
        }
        else{
            requestJson += '"personInfo":null,'; //for non individual
        }
        
        requestJson += '"contactInfo": {';  // contactInfo start here
        
        
        
        
        // requestJson += '"clientId": "string",';  // not in sheet so commented
        // requestJson += '"gcdId": "string",'; // not in sheet so commented
        // requestJson += '"mappingChanged": true,';  // not in sheet so commented
        // requestJson += '"recordId": 0,'; // not in sheet so commented
        // requestJson += '"preferredTelephoneType": " ' + applicant.Contact_Number_2__c + '",'; // need dissucussion
        requestJson += '"preferredTelephoneType": "' + apiCodesMap.get('telephoneTypeCodeMobile') + '",'; // need dissucussion
        requestJson += '"addressInfo": [';
        for(Address__c address : addressList){
            
            requestJson += '{'; //  address info start
            requestJson += '"primaryAddress": "' + (String.isNotBlank(address.Is_Primary_Address__c) ? String.valueOf(address.Is_Primary_Address__c).equals('Yes') ? 'true' : 'false' : 'false')+'",';
            requestJson += '"addressInfoPojo": {';  // addressInfoPojo start here
            // requestJson += '"clientId": "",'; // not persent in doc
            // requestJson += '"gcdId": "string",';.// not present in doc
            // requestJson += '"mappingChanged": true,'; // not for create
            // requestJson += '"recordId": 0,';
            // requestJson += '"addressTypeCode": "'+ (String.isNotBlank(address.Is_Primary_Address__c) ? String.valueOf(address.Is_Primary_Address__c).equals('Yes') ? 'ResidentialAddress' : 'ResidentialAddress' : 'ResidentialAddress') +'",';
            requestJson += '"addressTypeCode": "'+ (String.isNotBlank(address.Mailing_Address__c)? (apiCodesMap.containsKey(address.Mailing_Address__c) ? apiCodesMap.get(address.Mailing_Address__c): '') :'') +'",';
            // requestJson += '"addressTypeId": 0,';
            requestJson += '"accomodationTypeCode": null,';  // need check
            // requestJson += '"accomodationTypeId": 0,';
            requestJson += '"addressLine1": "'+ (String.isNotBlank(address.Address_Line_1__c) ? address.Address_Line_1__c : '') +'",';
            requestJson += '"addressLine2": "'+ (String.isNotBlank(address.Address_Line_2__c) ? address.Address_Line_2__c : '') +'",';
            requestJson += '"addressLine3": "'+ (String.isNotBlank(address.Address_Line_3__c) ? address.Address_Line_3__c : '') +'",';
            requestJson += '"addressLine4": null,';
            // requestJson += '"sanitizedFullAddress": "string",'; as per sheet
            requestJson += '"area": "",'; // as per sheet
            // requestJson += '"areaId": 0,';
            // requestJson += '"villageCode": "string",';
            // requestJson += '"villageId": 0,';
            requestJson += '"village": "",';  // As per sheet
            // requestJson += '"village": "'+ (String.isNotBlank(address.Village__c) ? address.Village__c : '')+'",';  // As per sheet
            requestJson += '"city": "'+ (String.isNotBlank(address.Pincode__r.City_Master__r.Name) ? address.Pincode__r.City_Master__r.Name : '') +'",';
            // requestJson += '"cityId": 0,';
            // requestJson += '"district": "'+ (String.isNotBlank(address.District__c) ? address.District__c : '') +'",';
            requestJson += '"district": "",';
            // requestJson += '"districtId": 0,';
            requestJson += '"state": "'+ (String.isNotBlank(address.State__c) ? address.State__c : '') +'",';
            // requestJson += '"stateId": 0,';
            requestJson += '"country": "' + (apiCodesMap.containsKey('country') ? apiCodesMap.get('country') : '')+ '",';
            // requestJson += '"countryId": 0,';
            requestJson += '"zipcode": "'+ (String.isNotBlank(address.Pincode__r.Name) ? address.Pincode__r.Name : '') +'",';
            // requestJson += '"zipcodeId": 0,';
            requestJson += '"region": "'+ (String.isNotBlank(address.Region__c) ? address.Region__c : '') +'",';
            // requestJson += '"regionId": 0,';
            requestJson += '"landMark": "'+ (String.isNotBlank(address.Landmark__c) ? address.Landmark__c : '') +'",';
            requestJson += '"taluka": "'+ (String.isNotBlank(address.Taluka__c) ? address.Taluka__c : '') +'",';
            // requestJson += '"talukaId": 0,';
            requestJson += '"residenceTypeCode": "",';
            // requestJson += '"residenceTypeId": 0,';
            requestJson += '"numberOfYearsAtAddress": 0,'; // need help
            requestJson += '"numberOfMonthsAtAddress": '+  address.Duration_at_current_address_In_Months__c +','; // need help
            requestJson += '"yearsInCurrentCity": 0,';
            requestJson += '"monthsInCurrentCity": '+  address.Duration_at_current_city_In_Months__c +',';
            requestJson += '"phoneNumbers": null,'; // as per sheet
            // requestJson += '"phoneNumbers": [';
            // requestJson += '{';   //
            // requestJson += '"clientId": "string",';
            // requestJson += '"gcdId": "string",';
            // requestJson += '"mappingChanged": true,';
            // requestJson += '"recordId": 0,';
            // requestJson += '"telephoneExtension": "string",';
            // requestJson += '"isdCode": "string",';
            // requestJson += '"telephoneTypeCode": "Phone",';
            // requestJson += '"telephoneTypeId": 0,';
            // requestJson += '"telephoneNumber": "string",';
            // requestJson += '"stdCode": "string",';
            // requestJson += '"countryCode": "string",';
            // requestJson += '"verified": true,';
            // requestJson += '"phoneConnectionType": "Prepaid",';
            // requestJson += '"phoneConnectionTypeId": 0';
            // requestJson += '}';
            // requestJson += '],';
            // requestJson += '"tehsil": "string",'; as per sheet
            // requestJson += '"tehsilId": 0,'; as per sheet
            requestJson += '"activeAddress": false,';
            requestJson += '"additionalAddressPurpose": "string",';
            // requestJson += '"additionalAddressPurposeId": 0,';
            // requestJson += '"additionalField1": "string",';
            // requestJson += '"additionalField2": "string",';
            // requestJson += '"additionalField3": "string",';
            // requestJson += '"additionalField4": "string",';
            // requestJson += '"additionalField5": "string",';
            requestJson += '"remarks": "string",';
            requestJson += '"addressGeneric": "YES",';
            requestJson += '"addressGenericId": 0,';
            requestJson += '"verified": '+ address.Is_Address_Verified__c  +'';
            // requestJson += '"streetType": "string",';
            // requestJson += '"completeAddress": "string",';
            // requestJson += '"streetTypeId": 0,';
            // requestJson += '"gstInDetailsPojo": ['; // as per sheet not present in both
            // requestJson += '{';
            // requestJson += '"clientId": "string",';
            // requestJson += '"gcdId": "string",';
            // requestJson += '"mappingChanged": true,';
            // requestJson += '"recordId": 0,';
            // requestJson += '"gstIn": "string",';
            // requestJson += '"isDefaultGstIn": true';
            // requestJson += '}';
            // requestJson += '],';
            // requestJson += '"additionalDropdownField1": "string",';
            // requestJson += '"additionalDropdownField2": "string",';
            // requestJson += '"atCurrentAddressFrom": "2025-05-14T09:38:15Z",';
            // requestJson += '"atCurrentAddressTo": "2025-05-14T09:38:15Z",';
            // requestJson += '"atCurrentCityFrom": "2025-05-14T09:38:15Z",';
            // requestJson += '"atCurrentCityTo": "2025-05-14T09:38:15Z",';
            // requestJson += '"currentAddress": true,';
            // requestJson += '"postCodeType": "Post office Boxes"';
            requestJson += '}'; // addressInfoPojo end here
            requestJson += '}'; // address info end here
            requestJson += ',';
        } // addressinfo for loop end here
        if(requestJson.endsWith(',')){ requestJson = requestJson.removeEnd(',');}
        requestJson += '],';  // addressInfo loop end here
        requestJson += '"emailInfo": [';
        // requestJson += '{'; // as per sheet
        // requestJson += '"clientId": "string",';
        // requestJson += '"gcdId": "string",';
        // requestJson += '"mappingChanged": true,';
        // requestJson += '"recordId": 0,';
        // requestJson += '"emailAddress": "string",';
        // requestJson += '"primaryEmail": true,';
        // requestJson += '"emailTypeCode": "string"';
        // requestJson += '}';
        requestJson += '],';
        requestJson += '"telephoneInfo": [';
        requestJson += '{';  // telephoneInfo stat here
        requestJson += '"primaryTelephone": true,'; // metadata if primary number
        requestJson += '"phoneNumbers": {';  //phoneNumbers obj start here
        // requestJson += '"clientId": "string",';
        // requestJson += '"gcdId": "string",';
        // requestJson += '"mappingChanged": true,';
        // requestJson += '"recordId": 0,';
        requestJson += '"telephoneExtension": "",';
        requestJson += '"isdCode": "+91",';
        requestJson += '"telephoneTypeCode": "'+ (apiCodesMap.containsKey('telephoneTypeCodeMobile')? apiCodesMap.get('telephoneTypeCodeMobile'):'')+'",';
        // requestJson += '"telephoneTypeId": 0,';
        requestJson += '"telephoneNumber": "'+ (String.isNotBlank(applicant.Mobile_Number__c)?applicant.Mobile_Number__c:'') +'",';
        requestJson += '"stdCode": "",';
        requestJson += '"countryCode": "'+ (apiCodesMap.containsKey('countryCodeIn')? apiCodesMap.get('countryCodeIn'):'')+'",';
        requestJson += '"verified": '+ (applicant.Mobile_Verification__r.Status__c.equals('Completed')? 'true':'false') +'';
        // requestJson += '"phoneConnectionType": "Prepaid",';
        // requestJson += '"phoneConnectionTypeId": 0';
        requestJson += '}';  // phoneNumbers obj end here
        requestJson += '}'; // telephoneInfo obj end here
        requestJson += '],'; // telephoneInfo loop end here
        requestJson += '"prefferedLanguage": "English"'; // need dissussion
        // requestJson += '"prefferedLanguageId": 0,';
        // requestJson += '"defaultContactInfo": true,';
        // requestJson += '"faxNumber": {';
        // requestJson += '"clientId": "string",';
        // requestJson += '"gcdId": "string",';
        // requestJson += '"mappingChanged": true,';
        // requestJson += '"recordId": 0,';
        // requestJson += '"telephoneExtension": "string",';
        // requestJson += '"isdCode": "string",';
        // requestJson += '"telephoneTypeCode": "Phone",';
        // requestJson += '"telephoneTypeId": 0,';
        // requestJson += '"telephoneNumber": "string",';
        // requestJson += '"stdCode": "string",';
        // requestJson += '"countryCode": "string",';
        // requestJson += '"verified": true,';
        // requestJson += '"phoneConnectionType": "Prepaid",';
        // requestJson += '"phoneConnectionTypeId": 0';
        // requestJson += '},';
        // requestJson += '"associatedLoanAppId": "string",';
        // requestJson += '"consentToCall": true';
        
        requestJson += '},'; // contactInfo end here
        if(isIndiviual){
            requestJson += '"familyDetails": null,';
            // requestJson += '"familyDetails": [';  // familyDetails loop start here
            // requestJson += '{';  // familyDetails obj stat here
            // requestJson += '"clientId": "string",';
            // requestJson += '"gcdId": "string",';
            // requestJson += '"mappingChanged": true,';
            // requestJson += '"recordId": 0,';
            // requestJson += '"memberName": "string",';
            // requestJson += '"relationshipCode": "string",';
            // requestJson += '"relationshipId": 0,';
            // requestJson += '"dateOfBirth": "2025-05-14T09:38:15Z",';
            // // requestJson += '"educationStatus": "",';
            // requestJson += '"phoneNumber": "string",';
            // requestJson += '"emailID": "string",';
            // requestJson += '"occupation": "Player",';
            // requestJson += '"isDependent": true,';
            // requestJson += '"numberOfDependentChildren": 0,';
            // requestJson += '"numberOfChildDependents": 0,';
            // requestJson += '"numberOfAdultDependents": 0,';
            // requestJson += '"age": "string",';
            // requestJson += '"isMinor": true';
            // requestJson += '}'; // familyDetails obj end here
            // requestJson += '],'; // familyDetails loop end here
        }
        else {
            requestJson += '"familyDetails": null,';
        }
        
        requestJson += '"identificationInfo": ['; // identificationInfo loop start here
        if(isIndiviual){
            if(String.isNotBlank(applicant.Pan_Number__c)){
                requestJson += '{'; // identificationInfo obj start here  // right now for pan only because in sheet , but we can pass for PASSPORT_No, PAN, Driving_Licence as identificationTypeCode as loop
                // requestJson += '"clientId": "string",';
                // requestJson += '"gcdId": "string",';
                // requestJson += '"mappingChanged": true,';
                // requestJson += '"recordId": 0,';
                requestJson += '"expiryDate": "",';
                requestJson += '"identificationNumber": "'+ (String.isNotBlank(applicant.Pan_Number__c) ? applicant.Pan_Number__c : '') +'",';
                requestJson += '"identificationTypeCode": "'+ (apiCodesMap.containsKey('identificationTypeCodePAN') ? apiCodesMap.get('identificationTypeCodePAN') : '')+'",';
                // requestJson += '"identificationTypeId": 0,';
                requestJson += '"issueDate": "",';
                requestJson += '"issuingCountry": "'+(apiCodesMap.containsKey('issuingCountryPan') ? apiCodesMap.get('issuingCountryPan') : '') + '"';
                // requestJson += '"associatedLoanAppId": "string",';
                // requestJson += '"primaryId": true,';
                // requestJson += '"consent": true,';
                // requestJson += '"isRefNumber": true,';
                // requestJson += '"referenceNumber": "string"';
                requestJson += '},'; // identificationInfo obj end here
            }
            if(String.isNotBlank(applicant.Voter_Id_Number__c)){
                requestJson += '{';
                requestJson += '"expiryDate": "",';
                requestJson += '"identificationNumber": "'+ (String.isNotBlank(applicant.Voter_Id_Number__c) ? applicant.Voter_Id_Number__c : '') +'",';
                requestJson += '"identificationTypeCode": "'+ (apiCodesMap.containsKey('identificationTypeCodeVoterID') ? apiCodesMap.get('identificationTypeCodeVoterID') : '')+'",';
                requestJson += '"issueDate": "",';
                requestJson += '"issuingCountry": "'+(apiCodesMap.containsKey('issuingCountryPan') ? apiCodesMap.get('issuingCountryPan') : '') + '"';
                requestJson += '},';
            }
            if(String.isNotBlank(applicant.Passport_File_Number__c)){
                requestJson += '{';
                requestJson += '"expiryDate": "",';
                requestJson += '"identificationNumber": "'+ (String.isNotBlank(applicant.Passport_File_Number__c) ? applicant.Passport_File_Number__c : '') +'",';
                requestJson += '"identificationTypeCode": "'+ (apiCodesMap.containsKey('identificationTypeCodePassport') ? apiCodesMap.get('identificationTypeCodePassport') : '')+'",';
                requestJson += '"issueDate": "",';
                requestJson += '"issuingCountry": "'+(apiCodesMap.containsKey('issuingCountryPan') ? apiCodesMap.get('issuingCountryPan') : '') + '"';
                requestJson += '},';
            }
            if(String.isNotBlank(applicant.Driving_License_Number__c)){
                requestJson += '{';
                requestJson += '"expiryDate": "",';
                requestJson += '"identificationNumber": "'+ (String.isNotBlank(applicant.Driving_License_Number__c) ? applicant.Driving_License_Number__c : '') +'",';
                requestJson += '"identificationTypeCode": "'+ (apiCodesMap.containsKey('identificationTypeCodeDL') ? apiCodesMap.get('identificationTypeCodeDL') : '')+'",';
                requestJson += '"issueDate": "",';
                requestJson += '"issuingCountry": "'+(apiCodesMap.containsKey('issuingCountryPan') ? apiCodesMap.get('issuingCountryPan') : '') + '"';
                requestJson += '},';
            }
            if(String.isNotBlank(applicant.Aadhar_Number__c)){
                String  inputStr = applicant.Aadhar_Number__c;
                requestJson += '{';
                requestJson += '"expiryDate": "",';
                Integer maskLength = inputStr.length() - 4;
                String maskedStr = '*'.repeat(maskLength) + inputStr.substring(maskLength);
                requestJson += '"identificationNumber": "'+ (String.isNotBlank(applicant.Aadhar_Number__c) ? maskedStr : '') +'",';
                requestJson += '"identificationTypeCode": "'+ (apiCodesMap.containsKey('identificationTypeCodeAadhar') ? apiCodesMap.get('identificationTypeCodeAadhar') : '')+'",';
                requestJson += '"issueDate": "",';
                requestJson += '"issuingCountry": "'+(apiCodesMap.containsKey('issuingCountryPan') ? apiCodesMap.get('issuingCountryPan') : '') + '"';
                requestJson += '},';
            }
        }
        else{
            if(String.isNotBlank(applicant.Pan_Number__c)){
                requestJson += '{';
                requestJson += '"expiryDate": "",';
                requestJson += '"identificationNumber": "'+ (String.isNotBlank(applicant.Pan_Number__c) ? applicant.Pan_Number__c : '') +'",';
                requestJson += '"identificationTypeCode": "'+ (apiCodesMap.containsKey('identificationTypeCodePAN') ? apiCodesMap.get('identificationTypeCodePAN') : '')+'",';
                requestJson += '"issueDate": "",';
                requestJson += '"issuingCountry": "'+(apiCodesMap.containsKey('issuingCountryPan') ? apiCodesMap.get('issuingCountryPan') : '') + '"';
                requestJson += '},';
            }
            if(String.isNotBlank(applicant.GST_Number__c)){
                requestJson += '{';
                requestJson += '"expiryDate": "",';
                requestJson += '"identificationNumber": "'+ (String.isNotBlank(applicant.GST_Number__c) ? applicant.GST_Number__c : '') +'",';
                requestJson += '"identificationTypeCode": "'+ (apiCodesMap.containsKey('identificationTypeCodeGST') ? apiCodesMap.get('identificationTypeCodeGST') : '')+'",';
                requestJson += '"issueDate": "",';
                requestJson += '"issuingCountry": "'+(apiCodesMap.containsKey('issuingCountryPan') ? apiCodesMap.get('issuingCountryPan') : '') + '"';
                requestJson += '},';
            }
        }
        requestJson = (requestJson.endsWith(',') ? requestJson.removeEnd(',') : requestJson);
        
        requestJson += '],';  // identificationInfo loop end here
        
        requestJson += '"financialInfo": {'; // financialInfo obj start here // passing as per sheet
        // requestJson += '"clientId": "string",';
        // requestJson += '"gcdId": "string",';
        requestJson += '"assetDetail": null,';
        requestJson += '"incomeDetail": null,';
        requestJson += '"expenseDetail": null,';
        requestJson += '"otherIncomeDetail": null,';
        requestJson += '"liabilityDetail": null';
        requestJson += '},'; // financialInfo obj end here
        
        // if(isIndiviual){
            requestJson += '"bankDetails": ['; // bankDetails loop start here
            for(Bank_Details__c bankdetails : bankDetailList){ // Bank_Details__c loop start here
                
                requestJson += '{'; // bankDetails Obj start here
                requestJson += '"accountName": "'+(String.isNotBlank(bankdetails.Loan_Applicant__r.Name) ? bankdetails.Loan_Applicant__r.Name : '')+'",'; //Loan_Applicant__r.Name
                requestJson += '"accountNumber": "'+(String.isNotBlank(bankdetails.Account_No__c) ? bankdetails.Account_No__c : '')+'",'; // Account_No__c
                requestJson += '"accountTypeCode": "'+(apiCodesMap.containsKey(bankdetails.Type_of_Account__c) ? apiCodesMap.get(bankdetails.Type_of_Account__c) : '')+'",'; // type of accoutn
                requestJson += '"bankName": "'+(String.isNotBlank(bankdetails.Name) ? bankdetails.Name : '')+'",'; // Name 
                requestJson += '"branchName": "'+(String.isNotBlank(bankdetails.Branch_Name__c) ? bankdetails.Branch_Name__c : '')+'",'; // Branch_Name__c
                requestJson += '"ifscCode": "'+(String.isNotBlank(bankdetails.IFSC_Code__c) ? bankdetails.IFSC_Code__c : '')+'",'; // IFSC_Code__c
                requestJson += '"bankingEvaluationPeriodCode": "0"'; // pass zero as static 
                // requestJson += '"bankingEvaluationPeriodId": 0';
                requestJson += '},';  // bankDetails Obj end here
            } // Bank_Details__c loop end here
            requestJson = (requestJson.endsWith(',') ? requestJson.removeEnd(',') : requestJson);
            requestJson += '],'; // bankDetails loop end here
        // }
        // else{
        //     requestJson += '"bankDetails": null,';
        // }
        
        if(isIndiviual){
            requestJson += '"occupationInfo": ['; //
            for(Employment__c emp : employmentList){
                requestJson += '{';
                // requestJson += '"mappingChanged": true,';// update ';
                requestJson += '"occupationTypeCode": "'+(apiCodesMap.containsKey(emp.Occupation__c) ? apiCodesMap.get(emp.Occupation__c) : '')+'", ';// Occupation__c';
                requestJson += '"referenceNumber": "'+emp.Id+'", ';// employement id';
                requestJson += '"addresses": null,';
                requestJson += '"otherEmployer": "",';
                requestJson += '"employmentStatusCode": "'+(String.isNotBlank(emp.Employment_Status__c) ? emp.Employment_Status__c: '') +'", ';// Employment_Status__c';
                requestJson += '"employmentTypeCode": "'+(String.isNotBlank(emp.Employment_Type__c) ? emp.Employment_Type__c: '') +'", ';//Employment_Type__c';
                requestJson += '"employmentLocationCode": "", ';// blank as now';
                requestJson += '"typeOfCompanyCode": "", ';// blank as now';
                // DateTime dt = DateTime.newInstance(emp.Employed_From__c, Time.newInstance(0, 0, 0, 0));
                // String fromDate = dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                String fromDate = String.valueOf(emp.Employed_From__c);
                // Datetime dt2 = DateTime.newInstance(emp.Employed_Till__c, Time.newInstance(0, 0, 0, 0));
                // String toDate = dt2.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                String toDate = String.valueOf(emp.Employed_Till__c);
                requestJson += '"fromDate": "'+ fromDate+ '", ';//Employed_From__c';
                requestJson += '"toDate": "'+ toDate+ '", ';// Employed_Till__c';
                requestJson += '"contractExpiry": "'+ toDate+ '", ';// Employed_Till__c';
                // requestJson += '"ageOfRetirement": 0, ';// remove it';
                requestJson += '"departmentName": "'+emp.Department__c +'", ';//Department__c';
                requestJson += '"designation": "'+emp.Designation__c +'", ';// Designation__c';
                requestJson += '"employmentNumber": "'+emp.Employee_Number__c +'", ';// Employee_Number__c';
                requestJson += '"yearsInOccupation": '+(emp.Total_Years_Of_Operation_Years__c!=null ? emp.Total_Years_Of_Operation_Years__c : 0)+', ';// Total_Years_Of_Operation_Years__c';
                requestJson += '"monthsInOccupation": '+(emp.Total_Years_Of_Operation_Months__c!=null ? emp.Total_Years_Of_Operation_Months__c : 0)+', ';// Total_Years_Of_Operation_Months__c';
                requestJson += '"yearsInTotalOccupation": '+(emp.Total_Years_Of_Operation_Years__c!=null ? emp.Total_Years_Of_Operation_Years__c : 0)+',';// same ';
                requestJson += '"monthsInTotalOccupation": '+(emp.Total_Years_Of_Operation_Months__c!=null ? emp.Total_Years_Of_Operation_Months__c : 0)+',';// same';
                requestJson += '"incomeFromEmployment": {';
                requestJson += '"amount": '+emp.Gross_Annual_Income_Yearly__c+',';// Gross_Annual_Income_Yearly__c';
                requestJson += '"currencyCode": "'+(apiCodesMap.containsKey('currencyCode') ? apiCodesMap.get('currencyCode') : '')+'" ';// metadata';
                requestJson += '},';
                // requestJson += '"isMajorEmployment": true, ';// remove';
                // requestJson += '"remarks": "string",';// remove';
                requestJson += '"natureOfBusinessCode": "", ';// blank';
                // requestJson += '"natureOfBusinessId": 0,';// remove';
                // requestJson += '"natureOfProfessionCode": "Doctors",';
                // requestJson += '"natureOfProfessionId": 0,';
                // requestJson += '"natureOfOccupationCode": "Farmer",';
                // requestJson += '"natureOfOccupationId": 0,';
                // requestJson += '"typeOfOwnershipCode": "Single",';
                // requestJson += '"typeOfOwnershipId": 0,';
                // requestJson += '"employerCode": "string",';
                // requestJson += '"employerId": 0,';
                requestJson += '"industryCode": "'+(apiCodesMap.containsKey(emp.Industry__c) ? apiCodesMap.get(emp.Industry__c) : '0')+'", ';//Industry__c';
                // requestJson += '"industryId": 0,';
                requestJson += '"subIndustryCode": "'+(String.isNotBlank(emp.Sub_Industry__c) ? emp.Sub_Industry__c : '')+'", ';//Sub_Industry__c';
                // requestJson += '"subIndustryId": 0,';
                requestJson += '"tempEmployerName": "'+(String.isNotBlank(emp.Business_Employer_Name__c) ? emp.Business_Employer_Name__c : '')+'", ';//Business_Employer_Name__c';
                requestJson += '"organizationName": "'+(String.isNotBlank(emp.Business_Employer_Name__c) ? emp.Business_Employer_Name__c : '')+'", ';// Business_Employer_Name__c';
                // requestJson += '"organizationNameKana": "string", ';// remove';
                // requestJson += '"organizationNameKanji": "string", ';//remove';
                // requestJson += '"companySize": 0, ';
                requestJson += '"employerName": "'+(String.isNotBlank(emp.Business_Employer_Name__c) ? emp.Business_Employer_Name__c : '')+'", ';//Business_Employer_Name__c';
                // requestJson += '"otrNtrofBsnsName": "string", ';// remove';
                // requestJson += '"otrNtrofPfnName": "string",';
                // requestJson += '"otrNtrofOcpnName": "string",';
                requestJson += '"orgWebURL": "'+(String.isNotBlank(emp.Website__c) ? emp.Website__c : '')+'", ';// Website__c';
                requestJson += '"contractExpiryDate": "'+ toDate+ '", ';// till';
                requestJson += '"dateOfEstablishment": "'+ fromDate+ '", ';// from';
                // requestJson += '"lengthOfBusiness": 0, ';// remove';
                // requestJson += '"tradeLicenseNo": "string", ';// remove';
                // requestJson += '"licenseExpiryDate": "string", ';//remove';
                requestJson += '"income": {';
                requestJson += '"amount": '+emp.Gross_Annual_Income_Yearly__c+', ';// Gross_Annual_Income_Yearly__c';
                requestJson += '"currencyCode": "'+(apiCodesMap.containsKey('currencyCode') ? apiCodesMap.get('currencyCode') : '')+'"';// meta';
                requestJson += '},';
                requestJson += '"monthlyTakeHomeSalary": {';
                requestJson += '"amount": '+emp.Gross_Income_Monthly__c+', ';//Gross_Income_Monthly__c';
                requestJson += '"currencyCode": "'+(apiCodesMap.containsKey('currencyCode') ? apiCodesMap.get('currencyCode') : '') +'" ';//meta';
                requestJson += '},';
                requestJson += '"registrationNumber": "'+emp.Name+'", ';// blank';
                requestJson += '"isStaff": '+(apiCodesMap.containsKey(emp.Staff_Loan__c) ? apiCodesMap.get(emp.Staff_Loan__c) : 'false')+', ';//Staff_Loan__c';
                requestJson += '"salaryAccountNumber": "", ';// blank';
                requestJson += '"location": "", ';// blank';
                requestJson += '"costCenter": "", ';// blank';
                requestJson += '"dasFlag": "", ';// blank';
                requestJson += '"typeOfFarmerCode": "", ';
                // requestJson += '"typeOfFarmerId": 0,';
                requestJson += '"typeOfCropCode": "",';
                // requestJson += '"typeOfCropId": 0,';
                // requestJson += '"showHideAgriIncomeFlag": true, ';// remove';
                requestJson += '"associatedLoanAppId": "'+emp.Name+'", ';// name or id ';
                requestJson += '"otherNatureOfOccupationCode": "" ';// blank';
                requestJson += '},';
            }
            requestJson = (requestJson.endsWith(',') ? requestJson.removeEnd(',') : requestJson);
            requestJson += '],';
        }
        else{
            requestJson += '"institutionInfo": {';  // institutionInfo Obj start here
            requestJson += '"registrationTypeCode": "'+(apiCodesMap.containsKey(applicant.Registration_Type__c) ? apiCodesMap.get(applicant.Registration_Type__c) : '' )+'",';
            requestJson += '"registrationNumber": "'+applicant.Registration_No__c+'",';
            requestJson += '"registrationExpiryDate": "'+(applicant.Registration_Expiry_Date__c != null ? String.valueOf(applicant.Registration_Expiry_Date__c) : '')+'",';
            requestJson += '"accountHolderType": null,';
            requestJson += '"accountHolderTypeId": null,';
            requestJson += '"businessCategoryCode": null,';
            requestJson += '"businessCategoryId": null,';
            requestJson += '"ccidNumber": null,';
            requestJson += '"constitutionCode": "'+(apiCodesMap.containsKey('Private Limited Co') ? apiCodesMap.get('Private Limited Co'): '') + '",';
            requestJson += '"controllingPersonCount": '+(applicant.No_Of_Controlling_Person__c != null ? String.valueOf(applicant.No_Of_Controlling_Person__c) : '')+',';
            requestJson += '"dateOfCommencement": "'+(applicant.Commencement_Date__c != null ? String.valueOf(applicant.Commencement_Date__c) : '')+'",';
            requestJson += '"dynamicFormJson": null,';
            requestJson += '"employeeStrength": null,';
            requestJson += '"incorporationDate": "'+(applicant.Date_Of_Incorporation1__c != null ? String.valueOf(applicant.Date_Of_Incorporation1__c) : '')+'",';
            requestJson += '"industryClassCode": "Hawker",'; // static now as per sheet 
            // requestJson += '"industryClassId": null,';
            requestJson += '"industryCode": '+(apiCodesMap.containsKey(applicant.Industry__c) ? apiCodesMap.get(applicant.Industry__c) : '0')+',';
            // requestJson += '"industryId": null,';
            requestJson += '"instDescription": "'+(String.isNotBlank(applicant.Description__c) ? applicant.Description__c : '')+'",';
            requestJson += '"instName": "'+(String.isNotBlank(applicant.Name) ? applicant.Name : '')+'",';
            requestJson += '"totalYearsOfOccupation": '+(applicant.Total_Years_Of_Operation__c != null ? applicant.Total_Years_Of_Operation__c : 0);
            requestJson += '},'; // institutionInfo Obj end here
        }
        
        requestJson = (requestJson.endsWith(',') ? requestJson.removeEnd(',') : requestJson);
        requestJson += '}';  // updateGlobalCustomer end here
        requestJson += '}';
        
        // request pending here ;
        
        
        system.debug('RequestJson @@## -- '+requestJson);
        return requestJson;
    }
}