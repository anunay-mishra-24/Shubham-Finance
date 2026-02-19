trigger caseTrigger on Case (before insert) {
	if (Trigger.isBefore && Trigger.isInsert) {
        for (Case cs : Trigger.new) {
            System.debug('Created Case Record → ' + cs);
        }
    }
}