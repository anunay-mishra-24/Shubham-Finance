/**
* @File Name          : SHF_ManualDeviationSharing.cls
* @Description        : 
* @Author             : Mansur 
* @Test Class         : 
*==============================================================================
* Ver         Date         Author     Modification
*==============================================================================
* 1.0         09-09-2025   Mansur     Initial Version
*/

public  class SHF_ManualDeviationSharing {
    @InvocableMethod(label='SHF_ManualDeviationSharing' description='SHF_ManualDeviationSharing' category='SHF_ManualDeviationSharing')
    public static void deviationrecordSharingwithManagers(List<String> applicationId) {
        system.debug('applicationId> ' +applicationId);
        if(!applicationId.isEmpty()){
         List<Deviation_and_Sanction_Condition__c> deviationList =  new SHF_DeviationAndSanctionSelector().selestByApplicationId(new Set<Id>{applicationId[0]});
            if(!deviationList.isEmpty()){
                //getting manager list to share the deviation record
            List<String> managerList = SHF_CommonUtil.getManagerOfManager(deviationList[0].Loan_Application__r.OwnerId);
            system.debug('managerList<>< '+managerList);
            if(!managerList.isEmpty()){
                List<SHF_GenericApexSharingUtility.SharingInput> sharingInputs = new List<SHF_GenericApexSharingUtility.SharingInput>();
                for(String managerId : managerList) {
                    for(Deviation_and_Sanction_Condition__c dev : deviationList){                    
                     SHF_GenericApexSharingUtility.SharingInput input = new SHF_GenericApexSharingUtility.SharingInput();
                        input.recordId = dev.Id;
                        input.objectApiName = 'Deviation_and_Sanction_Condition__c'; // Custom object API name
                        input.userOrGroupId = managerId;
                        input.accessLevel = SHF_ConstantsUtil.ACCESS_TYPE_EDIT; // Or 'Edit' based on your requirement
                        sharingInputs.add(input);
                }
            }
                system.debug('sharingInputs<>< ' + sharingInputs);
                if(!sharingInputs.isEmpty()){
                    SHF_GenericApexSharingUtility.createShare(sharingInputs);
                    System.debug('Successfully shared deviation record with ' + managerList.size() + ' managers');
                }
            }
            }
          
        }
    }
}