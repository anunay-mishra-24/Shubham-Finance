/**
* @File Name          : SHF_EmailMessageTrigger
* @Author             : Kunal Soni
* @Last Modified By   : Kunal Soni
* @Last Modified On   : 21-01-2026
* @Description        : This Trigger is used to performe automation on email message.
**/
trigger SHF_EmailMessageTrigger on EmailMessage (after insert) {
    system.debug('Trigger Called');
	if (Trigger.isAfter && Trigger.isInsert) {
        system.debug('Inside Trigger Called');
        SHF_EmailMessageHandler.createNewCaseForEmail(Trigger.new);
    }
}