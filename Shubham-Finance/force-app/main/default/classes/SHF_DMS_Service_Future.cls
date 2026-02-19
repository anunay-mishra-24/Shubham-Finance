/**
* @File Name          : SHF_DMS_Service_Future.cls
* @Description        : 
* @Author             : Preeti 
* @Test Class         : 
*==============================================================================
* Ver         Date         Author     Modification
*==============================================================================
* 1.0         03-06-2025   Preeti     Initial Version
*/
public class SHF_DMS_Service_Future {
    @future(callout=true)
    public static void createDocsAsync(List<String> docCategories,List<String> base64Docs,List<Id> loanApplicationIds,List<Id> docIds) {
        for (Integer i = 0; i < docCategories.size(); i++) {
            try {
                SHF_DMS_Service.createDoc(docCategories[i], base64Docs[i],loanApplicationIds[i],docIds[i]);
            } catch (Exception e) {
                Logger.error('error '+e.getMessage());
            }
        }
        
        try {
            if (!docIds.isEmpty()) {
                System.debug('Starting deletion for docIds => ' + docIds);
                
                List<ContentDocument> docsToDelete = [
                    SELECT Id 
                    FROM ContentDocument 
                    WHERE Id IN :docIds
                ];
                
                System.debug('Found ContentDocuments to delete => ' + docsToDelete);
                
                if (!docsToDelete.isEmpty()) {
                    Database.delete(docsToDelete, false); 
                    Logger.info('Deleted all ContentDocuments after cloud upload. Count: ' + docsToDelete.size());
                    System.debug('Deleted ContentDocuments count => ' + docsToDelete.size());
                } else {
                    System.debug('No ContentDocuments found for deletion.');
                }
            } else {
                System.debug('No docIds passed for deletion.');
            }
        } catch (Exception delEx) {
            Logger.error('Failed to delete ContentDocuments: ' + delEx.getMessage());
            System.debug('Deletion failed with exception => ' + delEx.getMessage());
        }
        
        
    }
}