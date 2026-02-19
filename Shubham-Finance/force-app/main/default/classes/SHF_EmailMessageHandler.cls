/**
* @File Name          : SHF_EmailMessageHandler
* @Author             : Kunal Soni
* @Description        : Handles EmailMessage based case creation
**/
public class SHF_EmailMessageHandler {

    private static Boolean isRunning = false;

    public static void createNewCaseForEmail(List<EmailMessage> newEmails) {

        if (isRunning) return;
        isRunning = true;

        // Collect Case Ids
        Set<Id> caseIds = new Set<Id>();
        for (EmailMessage em : newEmails) {
            if (em.ParentId != null &&
                em.ParentId.getSObjectType() == Case.SObjectType) {
                caseIds.add(em.ParentId);
            }
        }
        if (caseIds.isEmpty()) return;

        // Fetch only Resolved cases
        Map<Id, Case> resolvedCases = new Map<Id, Case>(
            [SELECT Id, Status, OwnerId, Origin, Priority,
                    SuppliedEmail, SuppliedName, AccountId
             FROM Case
             WHERE Id IN :caseIds
             AND Status =: SHF_ConstantsUtil.RESOLVED_STATUS]
        );
        if (resolvedCases.isEmpty()) return;

        // Map Case → EmailMessage (first email per case)
        Map<Id, EmailMessage> caseToEmailMap = new Map<Id, EmailMessage>();
        for (EmailMessage em : newEmails) {
            if (!caseToEmailMap.containsKey(em.ParentId)) {
                caseToEmailMap.put(em.ParentId, em);
            }
        }

        // Create new Cases
        Map<Id, Case> oldToNewCaseMap = new Map<Id, Case>();
        List<Case> casesToInsert = new List<Case>();

        for (Id oldCaseId : resolvedCases.keySet()) {
            EmailMessage em = caseToEmailMap.get(oldCaseId);
            if (em == null) continue;

            String body = em.TextBody != null ? em.TextBody : em.HtmlBody;
            if (body != null && body.length() > 32000) {
                body = body.substring(0, 32000);
            }

            Case newCase = new Case(
                Subject        = em.Subject,
                Status         = SHF_ConstantsUtil.NEW_STATUS,
                Origin         = resolvedCases.get(oldCaseId).Origin,
                Priority       = resolvedCases.get(oldCaseId).Priority,
                OwnerId        = resolvedCases.get(oldCaseId).OwnerId,
                SuppliedEmail  = resolvedCases.get(oldCaseId).SuppliedEmail,
                SuppliedName   = resolvedCases.get(oldCaseId).SuppliedName,
                Description    = body,
                AccountId      = resolvedCases.get(oldCaseId).AccountId
            );

            casesToInsert.add(newCase);
            oldToNewCaseMap.put(oldCaseId, newCase);
        }

        if (casesToInsert.isEmpty()) return;
        insert casesToInsert;

        // Clone emails & collect originals for delete
        List<EmailMessage> clonedEmails = new List<EmailMessage>();
        List<Id> emailIdsToDelete = new List<Id>();

        for (EmailMessage em : newEmails) {
            if (oldToNewCaseMap.containsKey(em.ParentId)) {
                EmailMessage cloned = em.clone(false, true, false, false);
                cloned.ParentId = oldToNewCaseMap.get(em.ParentId).Id;
                clonedEmails.add(cloned);

                emailIdsToDelete.add(em.Id);
            }
        }

        if (!clonedEmails.isEmpty()) {
            insert clonedEmails;
        }

        // Delete original emails asynchronously
        if (!emailIdsToDelete.isEmpty()) {
            System.enqueueJob(
                new SHF_DeleteEmailQueueable(emailIdsToDelete)
            );
        }
    }
}