/**
* @File Name          : SHF_CaseTATCalculator.cls
* @Author             : Harshita Rathod
* @Last Modified By   : Harshita Rathod
* @Last Modified On   : 02-07-2025
* @Description        : Calculates Actual TAT based on Business Hours and Case Category Matrix
* ================================================================================================
* Update Ver         Date           Author         Modification
* ================================================================================================
* 1.0                02-07-2025     Harshita Rathod   
*/

public class SHF_CaseTATCalculator { 
    /*
* Calculates Actual TAT for Cases using Business Hours and Case Category Matrix.
* @param caseList List of Case records triggered via Flow
*/
    @InvocableMethod(label = 'Calculate Actual TAT on Cases' description = 'Calculates Actual TAT based on Business Hours and Matrix')
    public static void calculateCaseTAT(List<Case> caseList) {
        if (caseList != null && !caseList.isEmpty()) { 
            try {
                fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
                    new List<SObjectType>{ Case.SObjectType }
                );
                
                Set<String> matrixKeys = new Set<String>();
                for (Case cs : caseList) {
                    if (String.isNotBlank(cs.Ticket_Type__c) &&
                        String.isNotBlank(cs.Request_Type__c) &&
                        String.isNotBlank(cs.Ticket_Sub_Type__c)) {                            
                            matrixKeys.add(cs.Ticket_Type__c + '-' + cs.Request_Type__c + '-' + cs.Ticket_Sub_Type__c);
                        }
                } 
                logger.info('matrixKeys map values : '+matrixKeys);
                
                List<Case_Categories_Matrix__c> caseCategoriesMatrix = new SHF_CaseCategoriesMatrixSelector().selectByIdsWithSendNotification();  
                logger.info('caseCategoriesMatrix values : '+caseCategoriesMatrix); 
                Map<String, Case_Categories_Matrix__c> matrixMap = new Map<String, Case_Categories_Matrix__c>();
                for (Case_Categories_Matrix__c m : caseCategoriesMatrix) {      
                    if (matrixKeys.contains( m.Ticket_Type__c + '-' + m.Request_Type__c + '-' + m.Ticket_Sub_Type__c)) {
                        matrixMap.put(m.Ticket_Type__c + '-' + m.Request_Type__c + '-' + m.Ticket_Sub_Type__c, m);
                    }
                }     
                logger.info('matrix map values : '+matrixMap);             
                
                Id businessHoursId;
                Id businessHoursId24;
                BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = :SHF_ConstantsUtil.BUSINESSHOURS  LIMIT 1];
                BusinessHours bh24 = [SELECT Id FROM BusinessHours WHERE Name = :SHF_ConstantsUtil.BUSINESSHOURS24  LIMIT 1];
                if (bh != null) {
                    businessHoursId = bh.Id;
                } else {
                    Logger.info('Business Hours not found');
                    return;
                }
                if (bh24 != null) {
                    businessHoursId24 = bh24.Id;
                } else {
                    Logger.info('Business Hours 24 not found');
                    return;
                }
                
                for (Case cs : caseList) {   
                    if(String.isNotBlank(cs.Status) && cs.Status != SHF_ConstantsUtil.RESPONSE_AWAITED_STATUS){
                        Long millis4Hours;
                        Datetime tat4Hours;
                        if(cs.Origin != SHF_ConstantsUtil.CASE_REGULALOR_COM_SOURCE){
                            millis4Hours =  Long.valueOf(label.Business_4_Hours);//14400000;                   
                            tat4Hours = BusinessHours.addGmt(businessHoursId, cs.CreatedDate, millis4Hours); //addGmt method used for UTC               
                            cs.Send_Notification_4_hours__c = tat4Hours;
                        }else{ // added by kunal
                            millis4Hours =  Long.valueOf(label.Business_4_Hours);//14400000;                   
                            tat4Hours = BusinessHours.addGmt(businessHoursId24, cs.CreatedDate, millis4Hours); //addGmt method used for UTC               
                            cs.Send_Notification_4_hours__c = tat4Hours;
                        }
                        
                        Logger.info('Going to update notification 4 hours values in Case : ' + tat4Hours);                    
                    }
                    // Register for update
                    uow.registerDirty(cs);
                    
                    Case_Categories_Matrix__c matrix = matrixMap.get(cs.Ticket_Type__c + '-' + cs.Request_Type__c + '-' + cs.Ticket_Sub_Type__c);
                    
                    if (matrix != null && matrix.Turnaround_Time__c != null) {  
                        Long tatMillis;
                        Datetime tatDateUtc;
                        
                        if(cs.Origin != SHF_ConstantsUtil.CASE_REGULALOR_COM_SOURCE){
                            tatMillis = matrix.Turnaround_Time__c.intValue() * Long.valueOf(Label.Business_9_5_Hours);             
                            tatDateUtc = BusinessHours.addGmt(businessHoursId, cs.CreatedDate, tatMillis);  
                        }else{ // added by kunal
                            tatMillis = matrix.Turnaround_Time__c.intValue() * Long.valueOf(Label.Business_24_Hours);             
                            tatDateUtc = BusinessHours.addGmt(businessHoursId24, cs.CreatedDate, tatMillis); 
                        }
                        cs.Actual_TAT__c = String.isNotBlank(cs.Status) && cs.Status != SHF_ConstantsUtil.RESPONSE_AWAITED_STATUS ? tatDateUtc : System.now();              
                        Logger.info('Going to update actual TAT values in Case : ' + tatDateUtc);  
                        
                        if(String.isNotBlank(cs.Status) && cs.Status != SHF_ConstantsUtil.RESPONSE_AWAITED_STATUS){
                            Long minusOneTATMillis;
                            Datetime minusOneTATDateUtc;
                            
                            if(cs.Origin != SHF_ConstantsUtil.CASE_REGULALOR_COM_SOURCE){
                                minusOneTATMillis = (matrix.Turnaround_Time__c.intValue()-1) * Long.valueOf(Label.Business_9_5_Hours);
                                minusOneTATDateUtc = BusinessHours.addGmt(businessHoursId, cs.CreatedDate, minusOneTATMillis);
                            }else{ // added by kunal
                                minusOneTATMillis = (matrix.Turnaround_Time__c.intValue()-1) * Long.valueOf(Label.Business_24_Hours);
                                minusOneTATDateUtc = BusinessHours.addGmt(businessHoursId24, cs.CreatedDate, minusOneTATMillis);
                            }
                            
                            cs.Actual_TAT_Before_1__c = minusOneTATDateUtc;
                            Logger.info('Going to update TAT before one day values in Case : ' + minusOneTATDateUtc);
                        }
                        
                        Decimal turnAroundTime = String.isNotBlank(cs.Status) && cs.Status != SHF_ConstantsUtil.RESPONSE_AWAITED_STATUS ? matrix.Turnaround_Time__c : 0;
                        Long plusOneTATMillis;
                        Datetime plusOneTATDateUtc;
                        if(cs.Origin != SHF_ConstantsUtil.CASE_REGULALOR_COM_SOURCE){
                            plusOneTATMillis = (turnAroundTime.intValue()+1) * Long.valueOf(Label.Business_9_5_Hours);                       
                            plusOneTATDateUtc = BusinessHours.addGmt(businessHoursId, cs.CreatedDate, plusOneTATMillis);
                        }else{ // added by kunal
                            plusOneTATMillis = (turnAroundTime.intValue()+1) * Long.valueOf(Label.Business_24_Hours);                       
                            plusOneTATDateUtc = BusinessHours.addGmt(businessHoursId24, cs.CreatedDate, plusOneTATMillis);
                        }
                                             
                        cs.Actual_TAT_After_1__c = plusOneTATDateUtc; 
                        Logger.info('Going to update TAT after one day values in Case : ' + plusOneTATDateUtc);   
                        
                        Long plusFourTATMillis;
                        Datetime plusFourTATDateUtc;
                        if(cs.Origin != SHF_ConstantsUtil.CASE_REGULALOR_COM_SOURCE){
                            plusFourTATMillis = (turnAroundTime.intValue()+4) * Long.valueOf(Label.Business_9_5_Hours);                       
                            plusFourTATDateUtc = BusinessHours.addGmt(businessHoursId, cs.CreatedDate, plusFourTATMillis);
                        }else{ // added by kunal
                            plusFourTATMillis = (turnAroundTime.intValue()+4) * Long.valueOf(Label.Business_24_Hours);                       
                            plusFourTATDateUtc = BusinessHours.addGmt(businessHoursId24, cs.CreatedDate, plusFourTATMillis);
                        }
                        
                        cs.Actual_TAT_After_4__c = plusFourTATDateUtc; 
                        Logger.info('Going to update TAT after four day values in Case : ' + plusFourTATDateUtc);  
                        
                        // Register for update
                        uow.registerDirty(cs);                        
                    }
                    if (matrix != null && matrix.Send_Notification_InDays__c != null && String.isNotBlank(cs.Status) && cs.Status != SHF_ConstantsUtil.RESPONSE_AWAITED_STATUS) { 
                        Long tatMillis;
                        Datetime tatDateUtc;
                        if(cs.Origin != SHF_ConstantsUtil.CASE_REGULALOR_COM_SOURCE){
                            tatMillis = matrix.Send_Notification_InDays__c.intValue() *  Long.valueOf(Label.Business_9_5_Hours);                      
                            tatDateUtc = BusinessHours.addGmt(businessHoursId, cs.CreatedDate, tatMillis); 
                        }else{
                            tatMillis = matrix.Send_Notification_InDays__c.intValue() *  Long.valueOf(Label.Business_24_Hours);                      
                            tatDateUtc = BusinessHours.addGmt(businessHoursId24, cs.CreatedDate, tatMillis);
                        }
                        cs.Escalation_Notification_Date__c = tatDateUtc;
                        Logger.info('Going to update escalation notifiction Date values in Case : ' + tatDateUtc); 
                        
                        // Register for update
                        uow.registerDirty(cs);                        
                    }
                }
                
                //Commit updates
                uow.commitWork();
                
            } catch (Exception ex) {
                Logger.error('CaseTATCalculator.calculateCaseTAT Exception: ' + ex.getMessage(), ex);
            }finally{
                Logger.saveLog();
            }
        }else{
            Logger.info('Case list is either empty or null');
        }
    }
}