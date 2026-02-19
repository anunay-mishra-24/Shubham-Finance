public class MobileQuickActionController {
    @AuraEnabled()
    public static List<Wrapper> getActions(Id recordId){
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        List<Wrapper> wrapperList = new List<Wrapper>();
        for(Mobile_Quick_Action__mdt objMdt:[SELECT Label,Component_Name__c,Filter_Condition__c,Order__c,Object_API_Name__c FROM Mobile_Quick_Action__mdt 
                                             WHERE Object_API_Name__c=:sObjName ORDER BY Order__c]){
                                                 Wrapper wrap= new Wrapper(); 
                                                 wrap.actionMetaDataObj=objMdt;
                                                 wrap.showAction=getVisibility(recordId,objMdt.Object_API_Name__c,objMdt.Filter_Condition__c);
                                                 wrapperList.add(wrap);
                                                 
                                             }
        return wrapperList;
    }
    
    private static boolean getVisibility(Id recordId,String objectName,String filter){
        String sQuery = '';
        if(String.isNotBlank(filter)){
            sQuery = 'SELECT Id FROM '+objectName+' WHERE Id=\''+recordId+'\' AND '+filter+'';
        }else{
            sQuery = 'SELECT Id FROM '+objectName+' WHERE Id=\''+recordId+'\'';
        }
        System.debug('sQuery'+sQuery);
        List<SObject> listData = Database.query(sQuery);
        return !listData.isEmpty()?true:false;
    }
    
    
    public class Wrapper{
        @AuraEnabled public Mobile_Quick_Action__mdt actionMetaDataObj  {get; set;}
        @AuraEnabled public Boolean showAction {get; set;}
    }
}