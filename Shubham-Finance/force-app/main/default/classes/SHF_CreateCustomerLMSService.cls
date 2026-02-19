/**
* @File Name          : SHF_CreateCustomerLMSService.cls
* @Description        : Handles integration with external LMS service to get the accessToken and create customer.
* @Author             : Kunal Soni
* 
*==============================================================================
* Ver         Date              Author           Modification
*==============================================================================
* 1.0         13-08-2025        Kunal Soni       Initial Version
* 1.1         18-08-2025        Riteek Tiwari    Updated Version
*/
public class SHF_CreateCustomerLMSService {
    public SHF_HTTPCalloutService service;
    
    public static String createCustomer(Id applicantId){
        
        String formattedDate;
        String message = '';
        Savepoint sp;
        Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('AML_API');
        
        String accessToken = SHF_LMSCommonUtil.generateAccessToken();
        System.debug('accessToken--> '+accessToken);
        
        if(String.isNotBlank(accessToken)){
            try{
                Map<String, API_Fields_Mapping__mdt> fieldMap = SHF_CommonUtil.getAPIFieldsMappingsRecordByLabel('LMS');
                fflib_SObjectUnitOfWork applicantUow = new fflib_SObjectUnitOfWork(new List<SObjectType> { Loan_Applicant__c.SObjectType });
                
                // Fetch Loan Applicant Details
                List<Loan_Applicant__c> loanAppList = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ applicantId });
                if (loanAppList.isEmpty()) {
                    Logger.error('Loan Applicant not found for Id: ' + applicantId);
                    return null;
                }
                Loan_Applicant__c loanApp = loanAppList[0];
                
                // Fetch addresses
                List<Address__c> addressList = new SHF_AddressesSelector().selectByIdsApplicantName(new Set<Id>{ applicantId });
                if (addressList.isEmpty()) {
                    Logger.error('Address not found on Loan Applicant : ' + applicantId);
                    return null;
                }
                Address__c currentAddress, permanentAddress, officeAddress;
                for (Address__c addr : addressList) {
                    if (addr.Address_Type__c == 'Current Address') currentAddress = addr;
                    if (addr.Address_Type__c == 'Permanent Address') permanentAddress = addr;
                    if (addr.Address_Type__c == 'Office Address') officeAddress = addr;
                }
                
                SHF_CreateCustomerLMSService createCustomer = new SHF_CreateCustomerLMSService();
                if(loanApp.Constitution__c == 'Individual'){
                    createCustomer.service = new SHF_HTTPCalloutService('LMS_Create_Customer_Individual');
                }else{
                    createCustomer.service = new SHF_HTTPCalloutService('LMS_Create_Customer_Non_Individual');
                }
                createCustomer.service.setHeaderParameter('access_token', accessToken);
                
                if(loanApp.Date_of_Birth__c != null){
                    Date dob = loanApp.Date_of_Birth__c;
                    DateTime dobDT = DateTime.newInstanceGMT(dob.year(), dob.month(), dob.day(), 0, 0, 0);
                    formattedDate = dobDT.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                }
                String reqBody = createCustomer.service.getRequestBody();
                
                reqBody = reqBody
                    .replace('<Id>', loanApp.Id != null ? String.valueOf(loanApp.Id) : '')
                    .replace('<applicantName>', loanApp.Name != null ? loanApp.Name : '')
                    .replace('<mobile>', loanApp.Mobile_Number__c != null ? loanApp.Mobile_Number__c : '')
                    
                    // Current Address
                    .replace('<address1>', currentAddress != null && currentAddress.Address_Line_1__c != null ? currentAddress.Address_Line_1__c : '')
                    .replace('<address2>', currentAddress != null && currentAddress.Address_Line_2__c != null ? currentAddress.Address_Line_2__c : '')
                    .replace('<address3>', currentAddress != null && currentAddress.Address_Line_3__c != null ? currentAddress.Address_Line_3__c : '')
                    .replace('<addressType>', currentAddress != null && currentAddress.Address_Type__c != null ? currentAddress.Address_Type__c : 'ResidentialAddress')
                   // .replace('<city>', (currentAddress.City__r.Name != null && fieldMap.containsKey(currentAddress.City__r.Name)) ? fieldMap.get(currentAddress.City__r.Name).Code__c : 'GZB')
                    .replace('<district>', currentAddress != null && currentAddress.District__c != null ? currentAddress.District__c : '')
                   // .replace('<state>', (currentAddress != null && currentAddress.City__r != null && currentAddress.City__r.State_Master__r.Name != null) ? fieldMap.get(currentAddress.City__r.State_Master__r.Name).Code__c : 'UP')
                    .replace('<pinCode>', currentAddress != null && currentAddress.PinCode__c != null ? currentAddress.PinCode__c : '201009')
                    
                    // Office Address
                    .replace('<oaddress1>', officeAddress != null && officeAddress.Address_Line_1__c != null ? officeAddress.Address_Line_1__c : '')
                    .replace('<oaddress2>', officeAddress != null && officeAddress.Address_Line_2__c != null ? officeAddress.Address_Line_2__c : '')
                    .replace('<oaddress3>', officeAddress != null && officeAddress.Address_Line_3__c != null ? officeAddress.Address_Line_3__c : '')
                    .replace('<oaddressType>', officeAddress != null && officeAddress.Address_Type__c != null ? officeAddress.Address_Type__c : 'OfficeAddress')
                   // .replace('<ocity>', (officeAddress != null && officeAddress.City__r != null && officeAddress.City__r.Name != null && fieldMap.containsKey(officeAddress.City__r.Name)) ? fieldMap.get(officeAddress.City__r.Name).Code__c : 'GZB')
                    .replace('<odistrict>', officeAddress != null && officeAddress.District__c != null ? officeAddress.District__c : '')
                  //  .replace('<ostate>', (officeAddress.City__r.State_Master__r.Name != null && fieldMap.containsKey(officeAddress.City__r.State_Master__r.Name)) ? fieldMap.get(officeAddress.City__r.State_Master__r.Name).Code__c : 'UP')
                    .replace('<opinCode>', officeAddress != null && officeAddress.PinCode__c != null ? officeAddress.PinCode__c : '201009');
                
                // Permanent Address (only for Individual)
                if(loanApp.Constitution__c == 'Individual'){
                    reqBody = reqBody
                        .replace('<paddress1>', permanentAddress != null && permanentAddress.Address_Line_1__c != null ? permanentAddress.Address_Line_1__c : '')
                        .replace('<paddress2>', permanentAddress != null && permanentAddress.Address_Line_2__c != null ? permanentAddress.Address_Line_2__c : '')
                        .replace('<paddress3>', permanentAddress != null && permanentAddress.Address_Line_3__c != null ? permanentAddress.Address_Line_3__c : '')
                        .replace('<paddressType>', permanentAddress != null && permanentAddress.Address_Type__c != null ? permanentAddress.Address_Type__c : 'PermanentAddress')
                       // .replace('<pcity>', (permanentAddress != null && permanentAddress.City__r != null && permanentAddress.City__r.Name != null && fieldMap.containsKey(permanentAddress.City__r.Name)) ? fieldMap.get(permanentAddress.City__r.Name).Code__c : 'GZB')
                        .replace('<pdistrict>', permanentAddress != null && permanentAddress.District__c != null ? permanentAddress.District__c : '')
                       // .replace('<pstate>', (permanentAddress != null && permanentAddress.City__r != null && permanentAddress.City__r.State_Master__r != null && permanentAddress.City__r.State_Master__r.Name != null && fieldMap.containsKey(permanentAddress.City__r.State_Master__r.Name)) ? fieldMap.get(permanentAddress.City__r.State_Master__r.Name).Code__c : 'UP')
                        .replace('<ppinCode>', permanentAddress != null && permanentAddress.PinCode__c != null ? permanentAddress.PinCode__c : '201009');
                }
                
                // Personal Info
                reqBody = reqBody
                    .replace('<panNumber>', loanApp.Pan_Number__c != null ? loanApp.Pan_Number__c : '')
                    .replace('<constitution>', loanApp.Constitution__c != null ? loanApp.Constitution__c : 'Indivi')
                    .replace('<dob>', loanApp.Date_of_Birth__c != null ? formattedDate : '')
                    .replace('<fatherName>', loanApp.Fathers_Name__c != null ? loanApp.Fathers_Name__c : '')
                    .replace('<firstName>', loanApp.First_Name__c != null ? loanApp.First_Name__c : '')
                    .replace('<lastName>', loanApp.Last_Name__c != null ? loanApp.Last_Name__c : '')
                    .replace('<gender>', loanApp.Gender__c != null ? (loanApp.Gender__c == 'Male' ? 'MALE' : 'FEMALE') : '')
                    .replace('<maritalStatus>', loanApp.Marital_Status__c != null ? loanApp.Marital_Status__c : '')
                    .replace('<customerCate>', loanApp.Customer_Category__c != null && fieldMap.containsKey(loanApp.Customer_Category__c) ? fieldMap.get(loanApp.Customer_Category__c).Code__c : '')
                    .replace('<bankName>', loanApp.Bank_Details__r != null && loanApp.Bank_Details__r.Name != null ? loanApp.Bank_Details__r.Name : '')
                    .replace('<branchName>', loanApp.Bank_Details__r != null && loanApp.Bank_Details__r.Branch_Name__c != null ? loanApp.Bank_Details__r.Branch_Name__c : '')
                    .replace('<ifscCode>', loanApp.Bank_Details__r != null && loanApp.Bank_Details__r.IFSC_Code__c != null ? loanApp.Bank_Details__r.IFSC_Code__c : '');
                
                createCustomer.service.setRequestBody(reqBody);
                System.debug('body Request--> '+createCustomer.service.getRequestBody());
                
                HttpResponse response;
                if (createCustomer.service.getIsActive()) {
                    response = createCustomer.service.sendRequest();
                } else {
                    response = new HttpResponse();
                    response.setStatusCode(200);
                    response.setBody(createCustomer.service.getmockRespnse()); 
                }
                
                if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                    Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    if(rootMap.containsKey('customerInfoFileNumber')){
                        loanApp.Customer_Info_File_Number__c = String.valueOf(rootMap.get('customerInfoFileNumber'));
                    }
                }
                
                if(loanAppList.Size()>0){
                    applicantUow.registerDirty(loanAppList);
                    applicantUow.commitWork();
                }
                
            } catch (Exception ex) {
                if (sp != null) Database.rollback(sp);
                Logger.error('LMS Individual Customer Creation Error: ' + ex.getMessage());
            } finally {
                Logger.saveLog();
            }
        }
        
        return null;
    }
}