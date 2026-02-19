/**
* @File Name : SHF_addressController.cls
* @Description :
* @Author : Mansur alam
* @Last Modified By :
* @Last Modified On : October 12, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 12, 2025 |   | Initial Version
**/
public class SHF_addressController {

//method use in aura component
@AuraEnabled(cacheable=true)
public static Address__c getAddressData(Id addressId) {
    return [
        SELECT Id, Loan_Applicant__c, Pincode__c
        FROM Address__c
        WHERE Id = :addressId
        LIMIT 1
    ];
}

@AuraEnabled
public static Pincode_Master__c getPinCodeDetails(String selectedPincodeId){
try{
        system.debug('selectedPincodeId ' + selectedPincodeId);
        if (Schema.sObjectType.Pincode_Master__c.isAccessible() && Schema.sObjectType.Pincode_Master__c.isQueryable() && String.isNotBlank(selectedPincodeId)) {

    List<Pincode_Master__c> pinCodeList = new SHF_pincodeSelector().selectByIds(new Set<Id>{selectedPincodeId});
    if(pinCodeList != null && pinCodeList.size() > 0){
        system.debug('pinCodeList[0]> ' + pinCodeList[0]);
        return pinCodeList[0];
    }
        }
}catch(Exception e){
    System.debug('getPinCodeDetails=> ' + e.getMessage());
    System.debug('line no ' + e.getLineNumber());
}
return new Pincode_Master__c();
}
@AuraEnabled(cacheable=true)
public static Boolean hasCommunicationAddress(String loanApplicantId) {
if (String.isBlank(loanApplicantId)) {
return false;
}
List<Address__c> addrs = [
SELECT Id, Communication_Address__c
FROM Address__c
WHERE Loan_Applicant__c = :loanApplicantId
AND Communication_Address__c = 'Yes'
LIMIT 1
];
return !addrs.isEmpty();
}
@AuraEnabled
public static Address__c getAddressById(String addressId) {
    try {
        if (String.isBlank(addressId)) return null;
        
        List<Address__c> addresses = [
            SELECT Id, 
                   Address_Line_1__c, 
                   Address_Line_2__c, 
                   Address_Line_3__c, 
                   District__c, 
                   Pincode__c, 
                   City__c, 
                   State__c, 
                   Country__c, 
                   Landmark__c,
                   Duration_at_current_address_In_Months__c, 
                   Duration_at_Current_Address__c,
                   Duration_at_current_city_In_Months__c,
                   Duration_at_Current_City__c,
                   Mailing_Address__c, 
                   Address_Type__c	
            FROM Address__c 
            WHERE Id = :addressId 
            LIMIT 1
        ];
        
        return addresses.isEmpty() ? null : addresses[0];
    } catch(Exception e) {
        System.debug('getAddressById error: ' + e.getMessage());
        throw new AuraHandledException('Unable to fetch source address: ' + e.getMessage());
    }
}



@AuraEnabled
public static List<Address__c> getexistingAddresses(String loanApplicantId){
try{
    List<Address__c> addresses = new AddressesSelector().allAddressByApplicantIds(new set<Id>{loanApplicantId});
    if(!addresses.isEmpty()){
        system.debug('addresses>>> ' +addresses);
        return addresses;
    }
}catch(Exception e){
    System.debug('getPinCodeDetails=> ' + e.getMessage());
    System.debug('line no ' + e.getLineNumber());
}
return new List<Address__c>();
}
 @AuraEnabled
    public static List<Address__c> updateAddressLocation(Id recordId, Decimal latitude, Decimal longitude) {
        String branchId='';
        Decimal latitude2 = 0.00;
         Decimal longitude2 = 0.00;
System.debug('latitude>>'+latitude);
System.debug('longitude>>'+longitude);
     List<Address__c> addressRecord =    new AddressesSelector().selectByIdsApplicantName(new Set<Id>{recordId});
     if(!addressRecord.isEmpty()){
        //update location field
        addressRecord[0].Address_Location__Latitude__s = latitude;
        addressRecord[0].Address_Location__Longitude__s = longitude;
      branchId =  addressRecord[0].Loan_Applicant__r.Application__r.Branch__c;
        //getting branch location
        if(branchId != null){
             List<Branch_Master__c> branchList = new SHF_BranchSelector().getBranchById(new Set<Id>{branchId});
             if(!branchList.isEmpty()){
                latitude2 = branchList[0].Branch_Location__Latitude__s;
                longitude2 = branchList[0].Branch_Location__Longitude__s;
             }
        }
        //calculating distance between branch and user current location
         Location l1 = Location.newInstance(latitude, longitude);
        Location l2 = Location.newInstance(latitude2, longitude2);
        Double distance = Location.getDistance(l1, l2, 'km');
        system.debug('distance>  ' + distance);
        addressRecord[0].Distance_From_Branch__c = distance;
        if(addressRecord[0].Distance_From_Branch__c != null){
           if(addressRecord[0].Distance_From_Branch__c > SHF_ConstantsUtil.OGL_IN_KM ){
            addressRecord[0].OGL__c = true ;
        }else{
             addressRecord[0].OGL__c = false;
        }
        }
        addressRecord[0].ODV__c = false;
     
     }
      system.debug('longitude2?> ' +longitude2);
system.debug('latitude2?>>> ' +latitude2);
        system.debug('addressRecord[0] > ' + addressRecord[0]);
        update addressRecord[0];
        return addressRecord;
    }
}