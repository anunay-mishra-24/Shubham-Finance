/**
* @File Name : FinancialCalculatorObligationController.cls
* @Description :
* @Author : Preeti
* @Last Modified By :
* @Last Modified On : July 7, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 7, 2025 |   | Initial Version
**/

public class SHF_FinancialCalObligationController {
    
    /*
* @description Fetches active obligations related to an application.
* @param applicationId - Id of the Application__c.
* @return List of active Obligation__c records.
*/
    @AuraEnabled
    public static List<Obligation__c> getObligations(Id applicationId, Id loanApplicantId) {
        try{
            return new SHF_ObligationSelector()
                .selectActiveObligationsByApplication(applicationId, loanApplicantId);
        }
        catch (Exception e) {
            Logger.error('Error in saveObligations: ' + e.getMessage());
            return new List<Obligation__c>();
        } finally {
            Logger.saveLog();
        }
    }
    
    
    /*
* @description Fetches obligations marked for deletion related to an application.
* @param applicationId - Id of the Application__c.
* @return List of deleted Obligation__c records.
*/
    @AuraEnabled
    public static List<Obligation__c> getDeletedObligations(Id applicationId,  Id loanApplicantId) {
        try{
            return new SHF_ObligationSelector()
                .selectDeletedObligationsByApplication(applicationId, loanApplicantId);
        }catch (Exception e) {
            Logger.error('Error in saveObligations: ' + e.getMessage());
            return new List<Obligation__c>();
        } finally {
            Logger.saveLog();
        }
    }
    
    /*
* @description Saves (upserts) a list of Obligation__c records.
* @param obligationList - List of Obligation__c records to save.
*/
    @AuraEnabled
    public static void saveObligations(List<Obligation__c> obligationList) {
        try {
            Logger.info('Start saveObligations. Number of records: ' + (obligationList != null ? obligationList.size() : 0));
            upsert obligationList;
        } catch (Exception e) {
            Logger.error('Error in saveObligations: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }
    
    /*
* @description Marks a specific obligation as deleted (soft delete).
* @param obligationId - Id of the Obligation__c record.
*/
    @AuraEnabled
    public static void deleteObligation(Id obligationId) {
        try{
            Logger.info('Start deleteObligation for Obligation Id: ' + obligationId);
            
            Obligation__c obl = new SHF_ObligationSelector().selectById(obligationId);
            if (obl != null) {
                obl.Consider_To_be_Deleted__c = true;
                obl.Cibil_Data_Deleted_On__c = System.now();
                update obl;
            }
            
        }catch (Exception e) {
            Logger.error('Error in deleteObligation: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
        
    }
    
    /*
* @description Fetches loan type options from CIBIL_CRIF_Bureau_Product_Type__c custom setting.
* @return List of Loan Type options.
*/
    @AuraEnabled(cacheable=true)
    public static List<String> getLoanTypeOptions() {
        try{
            List<String> options = new List<String>();
            for (CIBIL_CRIF_Bureau_Product_Type__c record : [SELECT Value__c FROM CIBIL_CRIF_Bureau_Product_Type__c]) {
                if (record.Value__c != null) {
                    options.add(record.Value__c);
                }
            }
            return options;
            
        }
        catch (Exception e) {
            Logger.error('Error in getLoanTypeOptions: ' + e.getMessage());
            return new List<String>();
        } finally {
            Logger.saveLog();
        }
        
    }


    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getFieldSetDescribe(String fieldSetName) {
        List<Map<String, String>> fieldSetFields = new List<Map<String, String>>();
        Schema.DescribeSObjectResult describeResult = Obligation__c.SObjectType.getDescribe();
        Schema.FieldSet fieldSet = describeResult.fieldSets.getMap().get(fieldSetName);
        for (Schema.FieldSetMember f : fieldSet.getFields()) {
            Map<String, String> fieldDetail = new Map<String, String>();
            fieldDetail.put('label', f.getLabel());
            fieldDetail.put('apiName', f.getFieldPath());
            fieldSetFields.add(fieldDetail);
        }
        return fieldSetFields;
    }
    
}