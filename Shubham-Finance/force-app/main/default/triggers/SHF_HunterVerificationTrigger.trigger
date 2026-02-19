/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : HunterVerificationTrigger
 * Author          : Preeti
 * Created Date    : Jan 28, 2026
 * Last Modified By: Preeti
 * Last Modified On: Jan 28, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jan 28, 2026  │ Preeti │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */


trigger SHF_HunterVerificationTrigger on Hunter_Verification__c (before update, after update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        SHF_HunterVerificationTriggerHandler.beforeUpdate(Trigger.new,Trigger.oldMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        SHF_HunterVerificationTriggerHandler.handleAfterUpdate(Trigger.new,Trigger.oldMap);
    }
}