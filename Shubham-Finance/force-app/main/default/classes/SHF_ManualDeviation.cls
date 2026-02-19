/**
* @File Name          : SHF_ManualDeviation.cls
* @Description        : 
* @Author             : Mansur 
* @Test Class         : 
*==============================================================================
* Ver         Date         Author     Modification
*==============================================================================
* 1.0         09-09-2025   Mansur     Initial Version
*/
public with Sharing class SHF_ManualDeviation {
    @InvocableMethod( label='Split String into Collection'
        description='Takes a semicolon-separated string and returns a collection of values. Useful for multi-select picklists.')
    public static List<List<String>> callSplitStringIntoCollection(List<String> flowInput){ //['RCM;NCM;ZCM']
    system.debug('flowInput > ' + flowInput);
       return SHF_CommonUtil.splitStringIntoCollection(flowInput);
    }
}