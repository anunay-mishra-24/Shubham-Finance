public without sharing class SHF_LAFPDFController {
    
    public Application__c application { get; set; }
    public List<ApplicantWrapper> applicantWrapperList { get; set; }
    public Map<Id, List<Address__c>> addressMap { get; set; }
    public String rmSelfieImageUrl { get; set; }
    public List<Reference_Member__c> familyList { get; set; }
    public List<Reference_Member__c> witnessList { get; set; }
    public List<Reference_Member__c> referenceList { get; set; }
    
    
    
    public SHF_LAFPDFController(ApexPages.StandardController std) {
        std.addFields(new List<String>{ 'Name','Lead__r.Name','Lead__r.Channel__c','Lead__r.Mitra_Code__c','Purpose_of_Loan__c','Applied_Loan_Amount__c','Tenure__c','Product__r.Product_Type__c', 'Product__r.Sub_Product__c','Product__r.Name','Lead__r.Lead_Partner_Code__c','Lead__r.Corporate_Lead_Partner_Code__c','Lead__r.DSA_Code__c','Lead__r.DSA_Code1__c'});
        this.application = (Application__c) std.getRecord();
        
        familyList = new List<Reference_Member__c>();
        witnessList = new List<Reference_Member__c>();
        referenceList = new List<Reference_Member__c>();
        
        // Fetch Members
        List<Reference_Member__c> members = [
            SELECT Id, Name, Age__c, Gender__c, Relationship__c,
            Mobile_Number__c, Witness_address__c, Type_of_Member__c
            FROM Reference_Member__c
            WHERE Application__c = :application.Id
            ORDER BY CreatedDate ASC
        ];
        
        for (Reference_Member__c m : members) {
            
            if (m.Type_of_Member__c == 'Family')
                familyList.add(m);
            
            else if (m.Type_of_Member__c == 'Witness')
                witnessList.add(m);
            
            else if (m.Type_of_Member__c == 'Reference')
                referenceList.add(m);
        }
        
        // ----------------------
        // Fetch RM Selfie Document & Latest Image
        // ----------------------
        
        try {
            
            Document__c selfieDoc = [ SELECT Id FROM Document__c WHERE Application__c = :application.Id AND File_Name__c = 'RM Selfie' AND Document_Category__c = 'Loan Specific Documents' LIMIT 1];
            
            
            
            // Try to fetch through ContentDocumentLink (Files)
            List<ContentDocumentLink> links = [ SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :selfieDoc.Id ];
            
            if (!links.isEmpty()) {
                Id cdId = links[0].ContentDocumentId;
                
                ContentVersion cv = [ SELECT Id FROM ContentVersion WHERE ContentDocumentId = :cdId ORDER BY CreatedDate DESC LIMIT 1];
                
                rmSelfieImageUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId='+ cv.Id;
                
            }
            else {
                
                // Fetch from Attachment (Notes & Attachments)
                List<Attachment> attList = [ SELECT Id, Name  FROM Attachment WHERE ParentId = :selfieDoc.Id ORDER BY CreatedDate DESC LIMIT 1 ];
                
                if (!attList.isEmpty()) {
                    
                    rmSelfieImageUrl = '/servlet/servlet.FileDownload?file=' + attList[0].Id;
                    
                }
                else {
                    rmSelfieImageUrl = null;
                }
            }
        }
        catch (Exception e) {
            rmSelfieImageUrl = null;
        }
        
        
        
        Map<Id, String> applicantPhotoMap = new Map<Id, String>();
        Map<Id, String> applicantSignatureMap = new Map<Id, String>();
        
        applicantWrapperList = new List<ApplicantWrapper>();
        addressMap = new Map<Id, List<Address__c>>();
        
        // Fetch Applicants
        List<Loan_Applicant__c> applicants = [
            SELECT Id, Name, First_Name__c, Middle_Name__c, Last_Name__c,Registration_Type__c,Group_Name__c,Sub_Group_Name__c,Date_Of_Incorporation1__c,Customer_Type__c,
            Voter_Id_Number__c, Driving_License_Number__c, GST_Number__c,Commencement_Date__c,Registration_No__c,Registration_Expiry_Date__c,Ration_Card_No__c,
            Mobile_Number__c, Alternate_Mobile_Number__c, Whatsapp_Number__c,
            Mothers_Name__c, Fathers_Name__c, Date_of_Birth__c, Applicant_Type__c,
            Passport_File_Number__c, Email__c, Is_Customer_Vernacular__c,
            Occupation__c, Industry__c, Sub_Industry__c,
            Marital_Status__c, Gender__c, Aadhar_Number__c,
            Total_Working_Experience__c, PAN_Number__c,
            Qualification__c, Religion__c, Caste_Category__c,
            Preferred_Language__c,RecordType.DeveloperName,Entity_Name__c,Company_Type__c
            FROM Loan_Applicant__c
            WHERE Application__c = :application.Id 
            AND IsDeleted__c = FALSE
            ORDER BY CreatedDate ASC
        ];
        
        // Move primary applicant to 1st position
        Integer pIndex = -1;
        Loan_Applicant__c pApp;
        for(Integer i=0; i<applicants.size(); i++){
            if(applicants[i].Applicant_Type__c == 'Primary Applicant'){
                pIndex = i;
                pApp = applicants[i];
                break;
            }
        }
        if(pIndex > 0){  
            applicants.remove(pIndex);
            applicants.add(0, pApp);
        }
        
        // ---------------------------------------------
        // FETCH Applicant Photo + Applicant Signature
        // ---------------------------------------------
        Map<Id, String> photoMap = new Map<Id, String>();
        Map<Id, String> signatureMap = new Map<Id, String>();
        
        List<Document__c> allDocs = [
            SELECT Id, Loan_Applicant__c, File_Name__c
            FROM Document__c
            WHERE Loan_Applicant__c IN :applicants
            AND Document_Category__c = 'KYC Documents'
            AND File_Name__c IN ('Applicant Photo', 'Applicant Signature')
        ];
        
        Set<Id> docIds = new Set<Id>();
        for (Document__c d : allDocs) {
            docIds.add(d.Id);
        }
        
        // Fetch all FILE LINKS at once
        Map<Id, Id> docToContentDoc = new Map<Id, Id>();
        for (ContentDocumentLink cdl : [
            SELECT LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :docIds
        ]) {
            docToContentDoc.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
        }
        
        // Fetch all latest file versions
        Map<Id, Id> contentDocToVersion = new Map<Id, Id>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :docToContentDoc.values()
            ORDER BY CreatedDate DESC
        ]) {
            if (!contentDocToVersion.containsKey(cv.ContentDocumentId)) {
                contentDocToVersion.put(cv.ContentDocumentId, cv.Id);
            }
        }
        
        Map<Id, Id> docToAttachment = new Map<Id, Id>();
        for (Attachment att : [
            SELECT Id, ParentId
            FROM Attachment
            WHERE ParentId IN :docIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!docToAttachment.containsKey(att.ParentId)) {
                docToAttachment.put(att.ParentId, att.Id);
            }
        }
        
        for (Document__c d : allDocs) {
            String finalUrl;
            
            if (docToContentDoc.containsKey(d.Id)) {
                Id verId = contentDocToVersion.get(docToContentDoc.get(d.Id));
                finalUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + verId;
            }
            else if (docToAttachment.containsKey(d.Id)) {
                finalUrl = '/servlet/servlet.FileDownload?file=' + docToAttachment.get(d.Id);
            }
            else {
                finalUrl = null;
            }
            
            if (d.File_Name__c == 'Applicant Photo') {
                photoMap.put(d.Loan_Applicant__c, finalUrl);
            }
            else if (d.File_Name__c == 'Applicant Signature') {
                signatureMap.put(d.Loan_Applicant__c, finalUrl);
            }
        }
        
        
        
        // Fetch Addresses
        List<Address__c> allAddresses = [
            SELECT Id, Name, Mailing_Address__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c,Is_Communication_Address__c,Address_Type__c,
            Landmark__c, City__c, State__c, Pincode__r.Name, Duration_at_current_city_In_Months__c,
            Duration_at_Current_Address__c, Duration_at_current_address_In_Months__c,Duration_at_Current_City__c, Loan_Applicant__c
            FROM Address__c
            WHERE Loan_Applicant__c IN :applicants
            ORDER BY CreatedDate ASC
        ];
        
        // Map to store Office Address for Individual and Non-Individual separately
        Map<Id, Address__c> individualOfficeAddressMap = new Map<Id, Address__c>();
        Map<Id, Address__c> nonIndividualOfficeAddressMap = new Map<Id, Address__c>();
        
        for(Address__c addr : allAddresses){
            if(addr.Loan_Applicant__c == null) continue;
            
            // For Individual employment
            if(addr.Mailing_Address__c == 'Office Address'){
                individualOfficeAddressMap.put(addr.Loan_Applicant__c, addr);
            }
            
            // For Non-Individual employment
            if(addr.Address_Type__c == 'Office/ Business Address'){ 
                nonIndividualOfficeAddressMap.put(addr.Loan_Applicant__c, addr);
            }
        }
        
        
        // FETCH Employment Records for all Applicants
        List<Employment__c> allEmployment = [
            SELECT Id, Loan_Applicant__c,Gross_Income_Monthly__c,Gross_Annual_Income_Yearly__c,Additional_Income__c	,Additional_Source__c,Loan_Applicant__r.Applicant_Type__c,
            Occupation__c, Nature_of_Business__c,Loan_Applicant__r.Total_Working_Experience__c,RecordType.DeveloperName,
            Business_Employer_Name__c, Business_Employer_Email_ID__c,Total_Years_Of_Operation_Years__c,
            Business_Employer_Contact_No__c, Employed_From__c,
            Designation__c, Industry__c, Sub_Industry__c
            FROM Employment__c
            WHERE Loan_Applicant__c IN :applicants
            ORDER BY CreatedDate ASC
        ];
        
        // Create a map to store empty list initially
        Map<Id, List<Employment__c>> empMap = new Map<Id, List<Employment__c>>();
        for (Loan_Applicant__c a : applicants) {
            empMap.put(a.Id, new List<Employment__c>());
        }
        
        Map<Id, List<EmploymentWrapper>> applicantToEmpList = new Map<Id, List<EmploymentWrapper>>();
        
        for(Employment__c emp : allEmployment){
            EmploymentWrapper ew = new EmploymentWrapper(emp);
            
            // Assign office address based on Employment record type
            if(emp.RecordType.DeveloperName == 'Individual'){
                Address__c officeAddr = individualOfficeAddressMap.get(emp.Loan_Applicant__c);
                if(officeAddr != null){
                    ew.officeLine1 = officeAddr.Address_Line_1__c;
                    ew.officeLine2 = officeAddr.Address_Line_2__c;
                    ew.officeLine3 = officeAddr.Address_Line_3__c;
                    ew.officeLandmark = officeAddr.Landmark__c;
                    ew.officeCity = officeAddr.City__c;
                    ew.officeState = officeAddr.State__c;
                    ew.officePincode = officeAddr.Pincode__r != null ? officeAddr.Pincode__r.Name : null;
                }
            }
            else if(emp.RecordType.DeveloperName == 'Non_Individual'){
                Address__c officeAddr = nonIndividualOfficeAddressMap.get(emp.Loan_Applicant__c);
                if(officeAddr != null){
                    ew.officeLine1 = officeAddr.Address_Line_1__c;
                    ew.officeLine2 = officeAddr.Address_Line_2__c;
                    ew.officeLine3 = officeAddr.Address_Line_3__c;
                    ew.officeLandmark = officeAddr.Landmark__c;
                    ew.officeCity = officeAddr.City__c;
                    ew.officeState = officeAddr.State__c;
                    ew.officePincode = officeAddr.Pincode__r != null ? officeAddr.Pincode__r.Name : null;
                }
            }
            
            if(!applicantToEmpList.containsKey(emp.Loan_Applicant__c)){
                applicantToEmpList.put(emp.Loan_Applicant__c, new List<EmploymentWrapper>());
            }
            applicantToEmpList.get(emp.Loan_Applicant__c).add(ew);
        }
        
        
        // Fill the map
        for (Employment__c emp : allEmployment) {
            if (empMap.containsKey(emp.Loan_Applicant__c)) {
                empMap.get(emp.Loan_Applicant__c).add(emp);
            }
        }
        
        
        
        
        // Prepare address map
        for(Loan_Applicant__c app : applicants) {
            addressMap.put(app.Id, new List<Address__c>());
        }
        
        for(Address__c addr : allAddresses) {
            addressMap.get(addr.Loan_Applicant__c).add(addr);
        }
        
        
        
        Integer index = 1;
        
        for(Loan_Applicant__c app : applicants) {
            ApplicantWrapper aw = new ApplicantWrapper(app);
            aw.employmentList = applicantToEmpList.get(app.Id);
            
            
            
            aw.applicantPhotoUrl = photoMap.get(app.Id);
            aw.applicantSignatureUrl = signatureMap.get(app.Id);
            aw.rowNumber = index; 
            
            
            List<Address__c> addrs = addressMap.get(app.Id);
            if(addrs != null){
                for(Address__c addr : addrs){
                    if(addr.Is_Communication_Address__c){
                        aw.communicationAddress = addr.Mailing_Address__c;
                        break;
                    }
                }
            }
            
            applicantWrapperList.add(aw); 
            index++; 
        }
        
        
        
    }
    
    public class ApplicantWrapper {
        public Id applicantId {get;set;}
        public String nameVal {get;set;}
        public String customerType {get;set;}
        public String firstName {get;set;}
        public String entityName {get;set;}
        public String middleName {get;set;}
        public String companyType {get;set;}        
        public String lastName {get;set;}
        public String registrationType {get;set;}
        public String voterId {get;set;}
        public String drivingLicense {get;set;}
        public String gst {get;set;}
        public String mobile {get;set;}
        public String altMobile {get;set;}
        public String whatsapp {get;set;}
        public String motherName {get;set;}
        public String groupName {get;set;}
        public String fatherName {get;set;}
        public String subGroupName {get;set;}
        public Date dob {get;set;}
        public Date doi {get;set;}
        public String applicantType {get;set;}
        public String passport {get;set;}
        public String rationCardNo {get;set;}
        public String email {get;set;}
        public String vernacular {get;set;}
        public String occupation {get;set;}
        public String industry {get;set;}
        public String subIndustry {get;set;}
        public String maritalStatus {get;set;}
        public Date bussinessCommencementDate {get;set;}
        public String gender {get;set;}
        public String aadhar {get;set;}
        public String registrationNo {get;set;}
        public Decimal totalExp {get;set;}
        public String pan {get;set;}
        public Date registrationExpiryDate {get;set;}
        public String qualification {get;set;}
        public String religion {get;set;}
        public String caste {get;set;}
        public String preferredLanguage {get;set;}
        public Boolean isIndividual { get; set; }
        public Boolean isNonIndividual { get; set; }
        public String communicationAddress { get; set; }
        public String applicantPhotoUrl { get; set; }
        public String applicantSignatureUrl { get; set; }
        public Integer rowNumber { get; set; }
        public EmploymentWrapper employment { get; set; }
        public List<EmploymentWrapper> employmentList { get; set; }
        
        
        
        
        public ApplicantWrapper(Loan_Applicant__c a){
            applicantId = a.Id;
            nameVal = a.Name;
            customerType = a.Customer_Type__c;
            firstName = a.First_Name__c;
            entityName = a.Entity_Name__c;
            middleName = a.Middle_Name__c;
            companyType = a.Company_Type__c;
            lastName = a.Last_Name__c;
            registrationType = a.Registration_Type__c;
            voterId = a.Voter_Id_Number__c;
            drivingLicense = a.Driving_License_Number__c;
            gst = a.GST_Number__c;
            mobile = a.Mobile_Number__c;
            altMobile = a.Alternate_Mobile_Number__c;
            whatsapp = a.Whatsapp_Number__c;
            motherName = a.Mothers_Name__c;
            groupName = a.Group_Name__c;
            fatherName = a.Fathers_Name__c;
            subGroupName = a.Sub_Group_Name__c;
            dob = a.Date_of_Birth__c;
            doi = a.Date_Of_Incorporation1__c;
            applicantType = a.Applicant_Type__c;
            passport = a.Passport_File_Number__c;
            rationCardNo = a.Ration_Card_No__c;
            email = a.Email__c;
            vernacular = a.Is_Customer_Vernacular__c;
            occupation = a.Occupation__c;
            industry = a.Industry__c;
            subIndustry = a.Sub_Industry__c;
            maritalStatus = a.Marital_Status__c;
            bussinessCommencementDate = a.Commencement_Date__c;
            gender = a.Gender__c;
            aadhar = a.Aadhar_Number__c;
            registrationNo = a.Registration_No__c;
            totalExp = a.Total_Working_Experience__c;
            pan = a.PAN_Number__c;
            registrationExpiryDate = a.Registration_Expiry_Date__c;
            qualification = a.Qualification__c;
            religion = a.Religion__c;
            caste = a.Caste_Category__c;
            preferredLanguage = a.Preferred_Language__c;
            isIndividual = (a.RecordType.DeveloperName == 'Individual');
            isNonIndividual = (a.RecordType.DeveloperName == 'Non_Individual');
            employmentList = new List<EmploymentWrapper>();
            
            
            
            
        }
    }
    
    public class EmploymentWrapper {
        public Employment__c emp { get; set; }
        public Boolean isEmpIndividual { get; set; }
        public Boolean isEmpNonIndividual { get; set; }
        
        public String officeLine1 { get; set; }
        public String officeLine2 { get; set; }
        public String officeLine3 { get; set; }
        public String officeLandmark { get; set; }
        public String officeCity { get; set; }
        public String officeState { get; set; }
        public String officePincode { get; set; }
        
        public EmploymentWrapper(Employment__c e) {
            emp = e;
            isEmpIndividual = (e.RecordType.DeveloperName == 'Individual');
            isEmpNonIndividual = (e.RecordType.DeveloperName == 'Non_Individual');
        }
    }
    
}