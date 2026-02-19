public class CaseSequentialOwnerAssignmentRule {
    /**
* Wrapper class to receive Case Ids from Flow
*/
    public class CaseWrapper {
        @InvocableVariable(required = true)
        public Id caseId;
    }
    
    /**
* Invocable method used by Flow
* Assigns Case Owner using Round Robin logic
* when Case Sub-Type is not Statement
*/
    
    @InvocableMethod(
        label = 'Case Sequential Owner Assignment for Email-to-Cases'
        description = 'Assigns Case owner using sequential logic when case is created from email'
    )
    public static void caseOwnerAssignment(List<CaseWrapper> caseWrappers) {
        
        /* ---------------- Collect Case Ids ---------------- */
        List<Id> caseIds = new List<Id>();
        for (CaseWrapper wrapper : caseWrappers) {
            caseIds.add(wrapper.caseId);
        }
        
        /* ---------------- Fetch Cases using Selector ---------------- */
        List<Case> caseList = new SHF_CaseSelector()
            .selectCasesByIds(new Set<Id>(caseIds));
        
        /* ---------------- Initialize Unit Of Work ---------------- */
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType> {
                Case.SObjectType            }
        );
        
        Map<String,Id> userMap = new Map<String,Id>();
        Set<String> ownerEmails = new Set<String>{
            'dimple.kapri@techmatrixconsulting.com',
            'karan@techmatrixconsulting.in'
                };
        for(User usr : [SELECT Id,Email FROM user WHERE Email IN :ownerEmails]){
            userMap.put(usr.Email,usr.Id);
            Logger.info('User Map '+userMap);
        }
        List<Case> casesToUpdate = new List<Case>();
        
        try{
            if(!caseList.isEmpty()){
                Time nowTime = System.now().time();
                
                // Define time boundaries
                Time startAM = Time.newInstance(0, 0, 0, 0);   // 12:00 AM
                Time endAM   = Time.newInstance(13, 59, 59, 0); // 01:59:59 PM
                
                Time startPM = Time.newInstance(14, 0, 0, 0);  // 02:00 PM
                Time endPM   = Time.newInstance(23, 59, 59, 0); // 11:59:59 PM
                
                
                for(Case cse : caseList){
                    if(nowTime >= startAM && nowTime <= endAM){
                        System.debug('Time is between 12:00 AM and 01:59 PM');
                        if(userMap.containsKey('dimple.kapri@techmatrixconsulting.com')){
                            cse.OwnerId = userMap.get('dimple.kapri@techmatrixconsulting.com');
                            casesToUpdate.add(cse);
                            Logger.info('Case To Update '+casesToUpdate);
                        }
                         
                    }
                    else if(nowTime >= startPM && nowTime <= endPM){
                        if(userMap.containsKey('karan@techmatrixconsulting.in')){
                            cse.OwnerId = userMap.get('karan@techmatrixconsulting.in');
                            casesToUpdate.add(cse);
                            Logger.info('Case To Update '+casesToUpdate);
                        }
                    }
                }
                /* ---------------- Register Updates with UOW ---------------- */
                if (!casesToUpdate.isEmpty()) {
                    uow.registerDirty(casesToUpdate);
                	uow.commitWork();
                }
                
            }
        } catch (Exception ex) {
            
            Logger.error(
                'Error during Case Round Robin Assignment: '
                + ex.getMessage()
            );
            
        } finally {
            Logger.saveLog();
        }
    }
}