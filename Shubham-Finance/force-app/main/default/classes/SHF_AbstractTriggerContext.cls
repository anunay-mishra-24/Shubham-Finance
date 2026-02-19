/**
* @File Name          : SHF_AbstractTriggerContext.cls
* @Description        : 
* @Author             : Akshi 
* @Test Class         : 
*==============================================================================
* Ver         Date         Author     Modification
*==============================================================================
* 1.0         03-06-2025   Akshi     Initial Version
*/
global abstract class SHF_AbstractTriggerContext {
	@TestVisible
    private static List<TriggerContext__mdt> testMetaData;
    
    global static void run(String objectName, System.TriggerOperation operationType, List<sObject> newList, List<sObject> oldList, Map<Id, sObject> newMap, Map<Id, sObject> oldMap){
        //query the meta data 
        for(TriggerContext__mdt record : getMetaData(objectName, operationType)){
            //get the instance 
            SHF_AbstractTriggerContext instance = (SHF_AbstractTriggerContext)Type.forName(record.Class_Name__c).newinstance();
            //call the method 
            if(operationType == System.Triggeroperation.BEFORE_INSERT){
                instance.beforeInsert(newList, oldList, newMap, oldMap);
            }
          
            if(operationType == System.Triggeroperation.AFTER_INSERT){
                instance.afterInsert(newList, oldList, newMap, oldMap);
            }
            else if(operationType == System.TriggerOperation.BEFORE_UPDATE){
                instance.beforeUpdate(newList, oldList, newMap, oldMap);
            }
           
        }
    }
    
    global virtual void beforeInsert(List<sObject> newList, List<sObject> oldList, Map<Id, sObject> newMap, Map<Id, sObject> oldMap){
        //override for before insert logic 
    }
    
    global virtual void beforeUpdate(List<sObject> newList, List<sObject> oldList, Map<Id, sObject> newMap, Map<Id, sObject> oldMap){
        //override for before update logic
    }
    
    global virtual void afterInsert(List<sObject> newList, List<sObject> oldList, Map<Id, sObject> newMap, Map<Id, sObject> oldMap){
        //override for after insert logic 
    }
    
    global static List<TriggerContext__mdt> getMetaData(String objectName, System.Triggeroperation operationType){
  
        // Use test metadata first (for test coverage)
        if(testMetaData != null && !testMetaData.isEmpty()){
            List<TriggerContext__mdt> filtered = new List<TriggerContext__mdt>();
            for(TriggerContext__mdt rec : testMetaData){
                Boolean matchObject = rec.Object_Name__c == objectName;
                Boolean matchOperation = false;
                if(operationType == System.TriggerOperation.BEFORE_INSERT) {
                    matchOperation = rec.Context__c == 'Before' && rec.Operation__c == 'Insert';
                } else if(operationType == System.TriggerOperation.AFTER_INSERT) {
                    matchOperation = rec.Context__c == 'After' && rec.Operation__c == 'Insert';
                } else if(operationType == System.TriggerOperation.BEFORE_UPDATE) {
                    matchOperation = rec.Context__c == 'Before' && rec.Operation__c == 'Update';
                }
                if(matchObject && matchOperation && rec.Is_Active__c){
                    filtered.add(rec);
                }
            }
            return filtered;
        }
        
        String query = 'Select Class_Name__c from TriggerContext__mdt where Class_Name__c != null AND Is_Active__c = true AND Object_Name__c =: objectName';
        String context;
        if(operationType == System.TriggerOperation.BEFORE_INSERT){
            context = ' AND Context__c = \'Before\' AND Operation__c = \'Insert\'';
        }

        if(operationType == System.TriggerOperation.AFTER_INSERT){
            context = ' AND Context__c = \'After\' AND Operation__c = \'Insert\'';
        }
        else if(operationType == System.TriggerOperation.BEFORE_UPDATE){
            context = ' AND Context__c = \'Before\' AND Operation__c = \'Update\'';
        }
        
        query += context;
        
        return (List<TriggerContext__mdt>)Database.query(query);
    } 
}