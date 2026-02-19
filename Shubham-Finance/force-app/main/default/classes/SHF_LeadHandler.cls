/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_LeadHandler
 * Author          : Preeti
 * Created Date    : Feb 9, 2026
 * Last Modified By: Preeti
 * Last Modified On: Feb 9, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Feb 9, 2026  │ Preeti   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class SHF_LeadHandler {

    public static void handleBranchChange(List<Lead__c> listOfNewLeads, Map<Id, Lead__c> oldMap) {

        for (Lead__c record : listOfNewLeads) {

            Lead__c oldLead = oldMap.get(record.Id);

            if (oldLead == null) {
                continue;
            }


            // Check if branch changed
            if (record.Branch__c != oldLead.Branch__c) {

                Integer currentCount = record.Branch_Change_Count__c == null ? 0 : Integer.valueOf(record.Branch_Change_Count__c);
                currentCount++;

                // If limit exceeded error throw
                if (currentCount > 2) {

                    record.addError('The Sourcing Branch cannot be changed, Please Contact your admin');

                } else {

                    // Update count
                    record.Branch_Change_Count__c = currentCount;

                }

            } else {
                System.debug('No branch change detected');
            }
        }

    }
}