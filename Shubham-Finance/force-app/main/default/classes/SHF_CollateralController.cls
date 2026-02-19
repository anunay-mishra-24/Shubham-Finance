/**
 * @File Name          : SHF_CollateralController.cls
 * @Description        : Create Collateral and Link collateral to Application.
 * @Author             :Anunay Kumar
 *
 *==============================================================================
 * Ver         Date                     Author                 Modification
 *==============================================================================
 * 1.0         2025-11-28            Anunay Kumar         Initial Version
 */
public without sharing class SHF_CollateralController {

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistValues() {
        Map<String, List<String>> result = new Map<String, List<String>>();

        Schema.SObjectType sObjType = Collateral__c.SObjectType;
         Schema.SObjectType sObjType1 = Address__c.SObjectType;
        Map<String, Schema.SObjectField> fields = sObjType.getDescribe().fields.getMap();
        Map<String,Schema.SObjectField> addressfields = sObjType.getDescribe().fields.getMap();
        addPicklist(result, fields, 'Property_Identification__c');
        addPicklist(result, fields, 'Collateral_Sub_Type_Property_Details__c');
        addPicklist(result, fields, 'Type_Of_Purchase__c');
        addPicklist(result, fields, 'Current_Usage__c');
        addPicklist(result, fields, 'Property_Type__c');
        addPicklist(result, fields, 'Nature_of_Property__c');
        addPicklist(result, fields, 'Type_of_property__c');
        addPicklist(result, fields, 'Property_Ownership__c');
        addPicklist(result, fields, 'Considered_Value__c');
        addPicklist(result, fields, 'Property_Purpose__c');
        addPicklist(result, fields, 'Residual_Age_of_Property__c');
        addPicklist(result, fields, 'Address_Type__c');
        addPicklist(result, fields, 'Residence_Status__c');
        addPicklist(result, fields, 'Residence_Type__c');
        addPicklist(result, fields, 'Property_Breakup_type__c');
        addPicklist(result, addressfields, 'Address_Type__c');
        return result;
    }

    private static void addPicklist(Map<String, List<String>> result, Map<String, Schema.SObjectField> fields, String fieldApiName) {
        if (!fields.containsKey(fieldApiName)) {
            return;
        }

        List<String> values = new List<String>();
        Schema.DescribeFieldResult dfr = fields.get(fieldApiName).getDescribe();

        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe.isActive()) {
                values.add(pe.getLabel());
            }
        }

        result.put(fieldApiName, values);
    }
   



    @AuraEnabled(cacheable=true)
    public static PincodeInfo getPincodeDetailsById(Id pincodeId) {
        if (pincodeId == null) {
            return null;
        }

        Pincode_Master__c rec = [  SELECT Id, Name, State__c, City_Master__r.Name, City_Master__r.Country__c,City_Master__r.District__c
            FROM Pincode_Master__c
            WHERE Id = :pincodeId
            LIMIT 1
        ];

        if (rec == null) {
            return null;
        }

        PincodeInfo info = new PincodeInfo();
        info.pincodeId = rec.Id;
        info.name = rec.Name;
        info.state = rec.State__c;
        info.city = rec.City_Master__r != null ? rec.City_Master__r.Name : null;
        info.country = rec.City_Master__r != null ? rec.City_Master__r.Country__c : null;
        info.district = rec.City_Master__r != null ? rec.City_Master__r.District__c : null;
        return info;
    }

    public class PincodeInfo {
        @AuraEnabled public Id pincodeId;
        @AuraEnabled public String name;
        @AuraEnabled public String state;
        @AuraEnabled public String city;
        @AuraEnabled public String country;
         @AuraEnabled public String district;
    }

    @AuraEnabled
public static Id saveCollateral(Collateral__c collateral, Id applicationId) {
    if (collateral == null) {
        throw new AuraHandledException('Collateral payload can’t be empty.');
    }

   new CollateralLinkHelper().saveCollaterals(collateral, applicationId);

    return collateral.Id;
}


   @AuraEnabled(cacheable=true)
    public static Id checkDuplicateCollateral(Collateral__c collateral) {
        System.debug('collateral: ' + collateral);
        if (collateral == null) {
            return null;
        }

        if ( String.isBlank(collateral.City__c)
            || collateral.Pincode__c == null) {
            return null;
        }

        List<Collateral__c> matches;

        if (collateral.Id == null) {
            matches = [
                SELECT Id
                FROM Collateral__c
                WHERE Address_Line_2__c   = :collateral.Address_Line_2__c
                  AND Address_Line_3__c   = :collateral.Address_Line_3__c
                  AND City__c             = :collateral.City__c
                  AND Pincode__c          = :collateral.Pincode__c
                LIMIT 1
            ];
            system.debug('matches: ' + matches);
        } else {
            matches = [
                SELECT Id
                FROM Collateral__c
                WHERE Address_Line_2__c   = :collateral.Address_Line_2__c
                  AND Address_Line_3__c   = :collateral.Address_Line_3__c
                  AND City__c             = :collateral.City__c
                  AND Pincode__c          = :collateral.Pincode__c
                 
                LIMIT 1
            ];
              System.debug('matches: ' + matches);
        }
        System.debug('matches: ' + matches);
        return matches.isEmpty() ? null : matches[0].Id;
    }


    @AuraEnabled(cacheable=true)
public static Collateral__c getCollateralById(Id collateralId) {
    if (collateralId == null) {
        return null;
    }

    List<Collateral__c> recs = [
        SELECT Id,
               Property_Identification__c,
               Property_Breakup_type__c,
               Collateral_Sub_Type_Property_Details__c,
               Type_Of_Purchase__c,
               Current_Usage__c,
               Property_Type__c,
               Nature_of_Property__c,
               Type_of_property__c,
               Property_Ownership__c,
               Considered_Value__c,
               Property_Purpose__c,
               Residual_Age_of_Property__c,
               Address_Type__c,
               Residence_Status__c,
               Residence_Type__c,
               Flat_Plot_Number__c,
               Address_Line_2__c,
               Address_Line_3__c,
               City__c,
               State__c,
               Country__c,
               Village__c,
               Taluka__c,
               Sub_Locality_Of_Property__c,
               Street_On_Which_Property_Located__c,
               Main_Locality_of_property__c,
               Landmark__c,
               Mobile_Phone__c,
               Property_Reference_Number__c,
               Property_Lot_Number__c,
               Built_Up_Area__c,
               Carpet_Area__c,
               Approximate_property_cost_INR__c,
               Property_cost_INR__c,
               Accepted_Value_Valuation_Value_INR__c,
               Accepted_Valuation_INR__c,
               Agreement_Value_INR__c,
               Down_payment_INR__c,
               Percentage_of_Down_payment__c,
               Age_Of_Property_In_Years__c,
               Age_Of_Property_In_Months__c,
               APF__c,
               APF_Number__c,
               Building_Completion__c,
               Building_Name__c,
               Company_Name__c,
               Flat_Shop_No__c,
               Floor_No__c,
               Project_Name__c,
               Tier_of_Builder__c,
               Wing_Name__c,
               Pincode__c,
               Pincode__r.Name
        FROM Collateral__c
        WHERE Id = :collateralId
        LIMIT 1
    ];

    if (recs.isEmpty()) {
        return null;
    }

    return recs[0];
}


  @AuraEnabled
public static Id linkExistingCollateralToApplication(Id collateralId, Id applicationId) {
    if (collateralId == null || applicationId == null) {
        throw new AuraHandledException('Collateral Id and Application Id are required.');
    }

   
    new CollateralLinkHelper().link(collateralId, applicationId);

    return collateralId;
}



    @AuraEnabled(cacheable=true)
public static List<Collateral_Seller_Owner__c> getSellerOwners(Id collateralId) {
    if (collateralId == null) {
        return new List<Collateral_Seller_Owner__c>();
    }

    return [
        SELECT Id,
               Name,
               Owner_Applicant_Id__c,
                ownerType__c,
                   ownershipStatus__c,
                   ownerName__c,
                   Linked_Applicant__c,
                   Percent_Share__c,
                   Percentage_Share__c ,
                    ownershipDates__c,
                    To_Date__c,
                    From_Date__c,
                   Collateral__c,
                   presentRegistered__c,
                   tctCctNo__c,
                   lotNo__c,
                   dobIncorporationDate__c,
                   identificationNumber__c,
                   otherRemarks__c,
                   individualNonIndividual__c,
                   RecordTypeId,
                   RecordType.DeveloperName
        FROM Collateral_Seller_Owner__c
        WHERE Collateral__c = :collateralId
    ];
}


    @AuraEnabled(cacheable=true)
    public static Collateral_Seller_Owner__c getSellerOwner(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Collateral_Seller_Owner__c> recs = [
            SELECT Id,
                   Name,
                   ownerType__c,
                   ownershipStatus__c,
                   ownerName__c,
                   Linked_Applicant__c,
                   Percent_Share__c,
                   Percentage_Share__c, 
                    ownershipDates__c,
                    From_Date__c,
                    To_Date__c,
                   Collateral__c,
                   presentRegistered__c,
                   tctCctNo__c,
                   lotNo__c,
                   dobIncorporationDate__c,
                   identificationNumber__c,
                   otherRemarks__c,
                   individualNonIndividual__c,
                   RecordTypeId,
                   RecordType.DeveloperName
            FROM Collateral_Seller_Owner__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        if (recs.isEmpty()) {
            return null;
        }

        return recs[0];
    }

    
@AuraEnabled
public static Id saveSellerOwner(Collateral_Seller_Owner__c record, Id applicationId) {
    if (record == null) throw new AuraHandledException('Empty payload');
    if (record.Collateral__c == null) throw new AuraHandledException('Collateral is required.');

    Boolean isOwnerRT=true;
    String rtName = null;
    if (record.RecordTypeId != null) {
        RecordType rt = [SELECT Id, DeveloperName FROM RecordType WHERE Id = :record.RecordTypeId LIMIT 1];
        rtName = rt.DeveloperName;
         isOwnerRT = (rt.DeveloperName == 'Owner');
    }

    
    if (rtName == null || rtName == 'Owner') {
        
        List<Collateral_Seller_Owner__c> others = [
            SELECT Id, ownershipStatus__c, Percent_Share__c
            FROM Collateral_Seller_Owner__c
            WHERE Collateral__c = :record.Collateral__c
              AND Id != :record.Id
              AND RecordType.DeveloperName = 'Owner'
        ];

        
        Boolean otherHasSingle = false;
        for (Collateral_Seller_Owner__c o : others) {
            if (o.ownershipStatus__c != null && o.ownershipStatus__c.equalsIgnoreCase('Single')) {
                otherHasSingle = true;
                break;
            }
        }
        Boolean hasOthers = !others.isEmpty();
        String incomingStatus = (record.ownershipStatus__c == null)
                                ? '' : record.ownershipStatus__c.trim().toLowerCase();

        
        if (incomingStatus == 'single' && hasOthers) {
            throw new AuraHandledException('Ownership Status is Single. Only one owner is allowed for this collateral.');
        }

        
        if (incomingStatus == 'joint' && otherHasSingle) {
            throw new AuraHandledException('A Single owner already exists for this collateral. You cannot add Joint owners.');
        }

       
        if (incomingStatus == 'joint') {
            Decimal total = 0;
            for (Collateral_Seller_Owner__c o : others) {
                if (o.ownershipStatus__c != null && o.ownershipStatus__c.equalsIgnoreCase('Joint') && o.Percent_Share__c != null) {
                    total += o.Percent_Share__c;
                }
            }
            if (record.Percent_Share__c != null) total += record.Percent_Share__c;
            if (total > 100) {
                throw new AuraHandledException('Total Percentage Share for Joint owners cannot exceed 100%.');
            }
        }
        if (isOwnerRT) {
       
        if (!String.isBlank(record.Owner_Applicant_Id__c)) {
            Integer cnt = [
                SELECT COUNT()
                FROM Collateral_Seller_Owner__c
                WHERE Collateral__c = :record.Collateral__c
                  AND RecordType.DeveloperName = 'Owner'
                  AND Owner_Applicant_Id__c = :record.Owner_Applicant_Id__c
                  AND Id != :record.Id
            ];
            if (cnt > 0) {
                throw new AuraHandledException('This applicant is already added as Owner for this collateral.');
            }
        }

        
        if (!String.isBlank(record.Owner_Applicant_Id__c) && String.isBlank(record.ownerName__c)) {
            Loan_Applicant__c la = [
                SELECT Name FROM Loan_Applicant__c WHERE Id = :record.Owner_Applicant_Id__c LIMIT 1
            ];
            if (la != null) record.ownerName__c = la.Name;
        }
    }
    }

    upsert record;
    return record.Id;
}


    

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getSellerOwnerPicklists() {
        Map<String, List<String>> result = new Map<String, List<String>>();

        Schema.SObjectType sObjType = Collateral_Seller_Owner__c.SObjectType;
        Map<String, Schema.SObjectField> fields = sObjType.getDescribe().fields.getMap();

        addSellerPicklist(result, fields, 'ownerType__c');
        addSellerPicklist(result, fields, 'ownershipStatus__c');
        addSellerPicklist(result, fields, 'individualNonIndividual__c');

        return result;
    }

    private static void addSellerPicklist(Map<String, List<String>> result, Map<String, Schema.SObjectField> fields, String fieldApiName) {
        if (!fields.containsKey(fieldApiName)) {
            return;
        }

        List<String> values = new List<String>();
        Schema.DescribeFieldResult dfr = fields.get(fieldApiName).getDescribe();

        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe.isActive()) {
                values.add(pe.getLabel());
            }
        }

        result.put(fieldApiName, values);
    }
@AuraEnabled(cacheable=true)
public static Id getOwnerRecordTypeId() {
    Map<String, Schema.RecordTypeInfo> rtMap =
        Collateral_Seller_Owner__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

    if (rtMap.containsKey('Owner')) {
        return rtMap.get('Owner').getRecordTypeId();
    }
    throw new AuraHandledException('Owner record type not found for Collateral_Seller_Owner__c.');
}

    @AuraEnabled(cacheable=true)
    public static Id getSellerRecordTypeId() {
        List<RecordType> rts = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Collateral_Seller_Owner__c'
              AND DeveloperName = 'Seller'
            LIMIT 1
        ];

        if (rts.isEmpty()) {
            return null;
        }

        return rts[0].Id;
    }

    @AuraEnabled(cacheable=true)
    public static String getLinkedApplicantText(Id applicationId) {
        if (applicationId == null) {
            return null;
        }

        List<Loan_Applicant__c> applicants = [
            SELECT Id, Name
            FROM Loan_Applicant__c
            WHERE Application__c = :applicationId
        ];

        List<String> names = new List<String>();
        for (Loan_Applicant__c la : applicants) {
            if (la.Name != null) {
                names.add(la.Name);
            }
        }

        if (names.isEmpty()) {
            return null;
        }

        return String.join(names, ', ');
    }

    @AuraEnabled(cacheable=true)
    public static List<Identification_Details__c> getIdentificationDetails(Id collateralId) {
        if (collateralId == null) {
            return new List<Identification_Details__c>();
        }

        return [
            SELECT Id,
                   Name,
                   Identification_Type__c,
                   Identification_No__c,
                   Issue_Date__c,
                   Expiry_Date__c,
                   Country_of_Issue__c,
                   Collateral_Seller_Owner__c,
                   Collateral_Seller_Owner__r.Name
            FROM Identification_Details__c
            WHERE Collateral_Seller_Owner__r.Collateral__c = :collateralId
        ];
    }

    @AuraEnabled
    public static void saveIdentificationDetails(String identificationJson) {
        if (String.isBlank(identificationJson)) {
            return;
        }

        Identification_Details__c record = (Identification_Details__c) JSON.deserialize(identificationJson, Identification_Details__c.class);
        upsert record;
    }

    @AuraEnabled(cacheable=true)
    public static List<Address__c> getSellerAddresses(Id collateralId) {
        if (collateralId == null) {
            return new List<Address__c>();
        }

        return [
            SELECT Id,
                   Name,
                   Address_Type__c,
                   Flat_Plot_Number__c,
                   Address_Line_2__c,
                   Address_Line_3__c,
                   Full_Address__c,
                   Pincode__c,
                   Pincode__r.Name,
                   Landmark__c,
                   Residence_Status__c,
                   Residence_Type__c,
                   Mobile_Phone__c,
                   Collateral_Seller_Owner__c,
                   Collateral_Seller_Owner__r.Name,
                   Duration_at_Current_City__c,
                   Duration_at_Current_Address__c
            FROM Address__c
            WHERE Collateral_Seller_Owner__r.Collateral__c = :collateralId
        ];
    }

    @AuraEnabled
    public static void saveSellerAddress(String addressJson) {
        if (String.isBlank(addressJson)) {
            return;
        }

        Address__c record = (Address__c) JSON.deserialize(addressJson, Address__c.class);
        upsert record;
    }

    @AuraEnabled(cacheable=true)
    public static List<Pincode_Master__c> searchPincodes(String searchKey) {
        if (String.isBlank(searchKey)) {
            return new List<Pincode_Master__c>();
        }

        String key = '%' + searchKey.trim() + '%';

        return [
            SELECT Id, Name
            FROM Pincode_Master__c
            WHERE Name LIKE :key
            ORDER BY Name
            LIMIT 50
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Collateral_Agreement__c> getCollateralAgreements(Id collateralId) {
        if (collateralId == null) {
            return new List<Collateral_Agreement__c>();
        }

        return [
            SELECT Id,
                   Name,
                   Registration_Number__c,
                   Agreement_Type__c,
                   SRO_Master__c,
                   SRO_Master__r.Name,
                   Sale_Deed_Number__c,
                   Registration_Date__c,
                   Sale_Deed_Date__c,
                   Agreement_Value_INR__c,
                   Amenities_Agreement_Value_INR__c,
                   Remarks__c,
                   Collateral__c
            FROM Collateral_Agreement__c
            WHERE Collateral__c = :collateralId
        ];
    }

    @AuraEnabled
    public static void saveCollateralAgreement(String agreementJson) {
        if (String.isBlank(agreementJson)) {
            return;
        }

        Collateral_Agreement__c rec = (Collateral_Agreement__c) JSON.deserialize(agreementJson, Collateral_Agreement__c.class);
        upsert rec;
    }
    @AuraEnabled(cacheable=true)
public static List<Builder_Master__c> searchBuilders(String searchKey) {
    if (String.isBlank(searchKey)) {
        return new List<Builder_Master__c>();
    }

    String key = '%' + searchKey.trim() + '%';

    return [
        SELECT Id,Company_Name__c, Tier_of_Builder__c
        FROM Builder_Master__c
        WHERE Company_Name__c LIKE :key
        ORDER BY Company_Name__c
        LIMIT 50
    ];
}


   @AuraEnabled(cacheable=true)
public static List<Bank_Details__c> getBankDetails(Id collateralId) {
    if (collateralId == null) {
        return new List<Bank_Details__c>();
    }

    return [
        SELECT Id,
               Name,
               Account_No__c,
               Type_of_Account__c,
               Branch_Name__c,
               IFSC_Code_Master__r.Branch_Name__c,
               IFSC_Code_Master__c,
               IFSC_Code_Master__r.Name,
               IFSC_Code_Master__r.Bank_Name__c,
               Collateral_Seller_Owner__c,
               Collateral_Seller_Owner__r.Name
        FROM Bank_Details__c
        WHERE Collateral_Seller_Owner__r.Collateral__c = :collateralId
    ];
}



    @AuraEnabled
    public static void saveBankDetail(String bankDetailJson) {
        if (String.isBlank(bankDetailJson)) {
            return;
        }

        Bank_Details__c rec =
            (Bank_Details__c) JSON.deserialize(bankDetailJson, Bank_Details__c.class);


        if (rec.RecordTypeId == null) {
            Id rtId = getBankDetailsRecordTypeId();
            if (rtId != null) {
                rec.RecordTypeId = rtId;
            }
        }

        upsert rec;
    }

    private static Id getBankDetailsRecordTypeId() {
        List<RecordType> rts = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Bank_Details__c'
              AND (DeveloperName = 'Collateral_Seller' OR Name = 'Collateral Seller')
            LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }
    @AuraEnabled
public static void deactivateCollateral(Id collateralId) {
    if (collateralId == null) return;

    update new Collateral__c(
        Id = collateralId,
        IsActive__c = false
    );
}


@AuraEnabled(cacheable=true)
public static List<Collateral_Application__c> getApplicationCollaterals(Id applicationId) {
    if (applicationId == null) return new List<Collateral_Application__c>();

    return [
        SELECT  Id,
                Name,
                Collateral_Address__c,
                Collateral__c,
                Collateral__r.Name,
                Collateral__r.APF__c,
                Collateral__r.Property_Identification__c,
                Application__r.Application_Stage__c,
                Collateral__r.IsActive__c
        FROM    Collateral_Application__c
        WHERE   Application__c = :applicationId
          AND   Collateral__r.IsActive__c = true
        ORDER BY CreatedDate DESC
    ];
}

    @AuraEnabled(cacheable=true)
    public static List<Collateral_Application__c> searchCollateralsByLoanAgreement(String loanAgreementNo) {
        
        if (String.isBlank(loanAgreementNo)) {
            return new List<Collateral_Application__c>();
        }

        return [
            SELECT  Id,
                    Name,
                    Application__c,
                    Application__r.Loan_Agreement_No__c,
                    Collateral__c,
                    Collateral__r.Name,
                    Collateral__r.APF__c,
                    Collateral_Address__c
            FROM    Collateral_Application__c
            WHERE   Application__r.Loan_Agreement_No__c = :loanAgreementNo
            LIMIT 50
        ];
    }
    @AuraEnabled(cacheable=false)
public static Boolean isCollateralAlreadyLinked(Id collateralId, Id applicationId) {
    System.System.debug('collateralId: ' + collateralId);
    System.System.debug('applicationId: ' + applicationId);
    if (collateralId == null || applicationId == null) {
        return false;
    }

    Integer cnt = [
        SELECT COUNT()
        FROM Collateral_Application__c
        WHERE Collateral__c = :collateralId
        AND Application__c = :applicationId
    ];
    System.System.debug('cnt: ' + cnt);

    return cnt > 0;
}
@AuraEnabled(cacheable=true)
public static List<Collateral__c> searchCollaterals(String collateralName, String applicationKey) {
    Set<Id> collateralIds = new Set<Id>();
    List<Collateral__c> results = new List<Collateral__c>();

    
    if (!String.isBlank(collateralName)) {
        String nameKey = '%' + collateralName.trim() + '%';
        for (Collateral__c col : [
            SELECT Id,
                   Name,
                   APF__c,
                   Flat_Plot_Number__c,
                   Address_Line_2__c,
                   Address_Line_3__c,
                   City__c,
                   State__c,
                   Country__c
            FROM Collateral__c
            WHERE IsActive__c= TRUE and Name LIKE :nameKey
            LIMIT 200
        ]) {
            results.add(col);
            collateralIds.add(col.Id);
        }
    }


    if (!String.isBlank(applicationKey)) {
        String appKey = '%' + applicationKey.trim() + '%';


        List<Collateral_Application__c> caList = [
            SELECT Id,
                   Collateral__c,
                   Application__r.Name
            FROM Collateral_Application__c
            WHERE Application__r.Name LIKE :appKey
                  AND Collateral__c != null
            LIMIT 500
        ];

        Set<Id> moreCollateralIds = new Set<Id>();
        for (Collateral_Application__c ca : caList) {
            moreCollateralIds.add(ca.Collateral__c);
        }

        if (!moreCollateralIds.isEmpty()) {
            moreCollateralIds.removeAll(collateralIds); // jo pehle se aa chuke unko hata do

            for (Collateral__c col : [
                SELECT Id,
                       Name,
                       APF__c,
                       Flat_Plot_Number__c,
                       Address_Line_2__c,
                       Address_Line_3__c,
                       City__c,
                       State__c,
                       Country__c
                FROM Collateral__c
                WHERE Id IN :moreCollateralIds
                LIMIT 200
            ]) {
                results.add(col);
                collateralIds.add(col.Id);
            }
        }
    }

    return results;
}




@AuraEnabled(cacheable=true)
public static Collateral__c getCollateralForEdit(Id collateralId) {
    if (collateralId == null) {
        return null;
    }

    return [
        SELECT  Id,
                Name,
                Property_Breakup_type__c,
                Property_Identification__c,
                Collateral_Sub_Type_Property_Details__c,
                Type_Of_Purchase__c,
                Property_Type__c,
                Nature_of_Property__c,
                Type_of_property__c,
                Property_Reference_Number__c,
                Current_Usage__c,
                Approximate_property_cost_INR__c,
                Property_Description__c,
                Property_Classification__c,
                Unit_Details__c,
                Property_Ownership__c,
                Market_Value_INR__c,
                Accepted_Value_Valuation_Value_INR__c,
                Considered_Value__c,
                Built_Up_Area__c,
                Carpet_Area__c,
                Property_Purpose__c,
                Age_Of_Property_In_Years__c,
                Age_Of_Property_In_Months__c,
                Residual_Age_of_Property__c,
                Accepted_Valuation_INR__c,
                Plan_Type__c,
                Plan_Number__c,
                Property_Lot_Number__c,
                Agreement_Value_INR__c,
                Property_cost_INR__c,
                Percentage_of_Down_payment__c,
                Down_payment_INR__c,
                Address_Type__c,
                Country__c,
                Flat_Plot_Number__c,
                Address_Line_2__c,
                Address_Line_3__c,
                Pincode__c,
                Pincode__r.Name,
                State__c,
                City__c,
                District__c,
                Taluka__c,
                Village__c,
                Residence_Status__c,
                Residence_Type__c,
                Landmark__c,
                Sub_Locality_Of_Property__c,
                Street_On_Which_Property_Located__c,
                Main_Locality_of_property__c,
                Mobile_Phone__c,
                Project_Name__c,
                Company_Name__c,
                Building_Name__c,
                Tier_of_Builder__c,
                Wing_Name__c,
                Floor_No__c,
                Flat_Shop_No__c,
                Building_Completion__c,
                APF_Number__c,
                APF__c
        FROM Collateral__c
        WHERE Id = :collateralId
        LIMIT 1
    ];
}
public class IdNameDTO implements Comparable {
    @AuraEnabled public String id;
    @AuraEnabled public String name;
    public IdNameDTO(String i, String n) { id = i; name = n; }

    public Integer compareTo(Object other) {
        IdNameDTO o = (IdNameDTO) other;
        String a = (this.name == null ? '' : this.name.toLowerCase());
        String b = (o.name == null ? '' : o.name.toLowerCase());
        return a.compareTo(b); 
    }
}

@AuraEnabled(cacheable=true)
public static List<IdNameDTO> getAvailableOwnerApplicants(
    Id applicationId,
    Id collateralId,
    Id currentApplicantId,
    String refreshNonce
){
    List<Loan_Applicant__c> allApps = [
        SELECT Id, Name
        FROM Loan_Applicant__c
        WHERE Application__c = :applicationId
    ];

    List<IdNameDTO> outp = new List<IdNameDTO>();
    for (Loan_Applicant__c a : allApps) {
        outp.add(new IdNameDTO(a.Id, a.Name));
    }
    outp.sort();
    return outp;
}



@AuraEnabled(cacheable=true)
public static List<Cost_of_property__c> getCostOfPropertyRecords(Id collateralId) {
    return [
        SELECT Id,
               Break_Up_Head__c,
               Break_Up_Cost__c,
               Break_Up_Description__c,
               Collateral__c
               
        FROM Cost_of_property__c
        WHERE Collateral__c = :collateralId
    ];
}

@AuraEnabled
public static Id saveCostOfPropertyRecord(String costJson) {
    Cost_of_Property__c c =
    (Cost_of_Property__c) JSON.deserialize(costJson, Cost_of_Property__c.class);

if (c.Collateral__c != null && String.isNotBlank(c.Break_Up_Head__c)) {
    // Cost_of_Property__c dup = [
    //     SELECT Id
    //     FROM Cost_of_Property__c
    //     WHERE Collateral__c = :c.Collateral__c
    //       AND Break_Up_Head__c = :c.Break_Up_Head__c
    //       AND Id != :c.Id
    //     LIMIT 1
    // ];
    // if (dup != null) {
    //     throw new AuraHandledException('This Break Up Head already exists for this collateral.');
    // }
    
}
    upsert c;
    return c.Id;
}





private without sharing class CollateralLinkHelper {
    void link(Id collateralId, Id applicationId) {
Decimal appLvr = 0;
    Decimal appLtv = 0;

    Application__c app = [
        SELECT LVR__c, LTV__c
        FROM Application__c
        WHERE Id = :applicationId
        LIMIT 1
    ];
    appLvr = app.LVR__c;
    appLtv = app.LTV__c;

        List<Collateral_Application__c> existingLinks = [
            SELECT Id
            FROM Collateral_Application__c
            WHERE Collateral__c = :collateralId
              AND Application__c = :applicationId
            LIMIT 1
        ];

        if (existingLinks.isEmpty()) {
            Collateral_Application__c ca = new Collateral_Application__c(
                Application__c = applicationId,
                Collateral__c  = collateralId,
                LVR__c         = appLvr,
                LTV__c         = appLtv
            );
            insert ca;   // yahan cross-reference sharing check bypass ho jayega
        }
    }
    Void saveCollaterals(Collateral__c collateral, Id applicationId){
         upsert collateral;

    if (applicationId != null) {
        
        Application__c app = [
            SELECT Id, LVR__c, LTV__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        Decimal appLvr = app.LVR__c;
        Decimal appLtv = app.LTV__c;

        
        List<Collateral_Application__c> links = [
            SELECT Id
            FROM Collateral_Application__c
            WHERE Collateral__c = :collateral.Id
              AND Application__c = :applicationId
            LIMIT 1
        ];

        if (links.isEmpty()) {
            
            Collateral_Application__c ca = new Collateral_Application__c(
                Application__c = applicationId,
                Collateral__c  = collateral.Id,
                LVR__c         = appLvr,
                LTV__c         = appLtv
            );
            insert ca;
        } else {
            Collateral_Application__c ca = links[0];
            ca.LVR__c = appLvr;
            ca.LTV__c = appLtv;
            update ca;
        }
    }
    }
}


@AuraEnabled(cacheable=true)
public static List<String> getBreakUpHeadPicklistValues() {
    List<String> vals = new List<String>();
    for (Schema.PicklistEntry pe :
         Cost_of_Property__c.Break_Up_Head__c.getDescribe().getPicklistValues()) {
        if (pe.isActive()) vals.add(pe.getValue());
    }
    return vals;
}
@AuraEnabled(cacheable=true)
public static Map<String, List<String>> getAddressTypeValues() {
    Map<String, List<String>> result = new Map<String, List<String>>();
    Map<String, Schema.SObjectField> f = Address__c.SObjectType.getDescribe().fields.getMap();

    result.put('Address_Type__c', new List<String>());
    for (Schema.PicklistEntry pe : f.get('Address_Type__c').getDescribe().getPicklistValues()) {
        if (pe.isActive()) result.get('Address_Type__c').add(pe.getValue()); // value use karo
    }

    result.put('Residence_Status__c', new List<String>());
    for (Schema.PicklistEntry pe : f.get('Residence_Status__c').getDescribe().getPicklistValues()) {
        if (pe.isActive()) result.get('Residence_Status__c').add(pe.getValue());
    }

    result.put('Residence_Type__c', new List<String>());
    for (Schema.PicklistEntry pe : f.get('Residence_Type__c').getDescribe().getPicklistValues()) {
        if (pe.isActive()) result.get('Residence_Type__c').add(pe.getValue());
    }

    return result;
}



}