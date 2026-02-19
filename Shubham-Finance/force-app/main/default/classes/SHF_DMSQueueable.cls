/**
* @File Name          : SHF_DMSQueueable.cls
* @Description        : DMS service Queueable class to create, export and get the accessToken "this queueable class using if multiple API's runnig parallelly".
* @Author             : Riteek Tiwari
* 
*==============================================================================
* Ver         Date              Author           Modification
*==============================================================================
* 1.0         22-07-2025        Riteek Tiwari    Initial Version
*/
public class SHF_DMSQueueable implements Queueable , Database.AllowsCallouts {

   E_Verification__c listOfEverifications;

    public SHF_DMSQueueable(E_Verification__c listOfEverifications) {
        this.listOfEverifications = listOfEverifications;
    }

    public void execute(QueueableContext context) {
        system.debug('Executing DMS Queue Invoker with parameters:');
         fflib_SObjectUnitOfWork eVerificationUow = new fflib_SObjectUnitOfWork(new List<SObjectType>{ E_Verification__c.SObjectType }); 
          eVerificationUow.registerDirty(listOfEverifications);
          eVerificationUow.commitWork();
       // SHF_DMS_Service.createDoc(docCategory, path, base64Doc, loanApplicationId, docId);

    }
}