/**
* @File Name : shf_ApplicationSearchController.cls
* @Description : to handle case/application search/creation 
* @Author : Kunal Soni
* @Last Modified On : October 24, 2025
*==============================================================================
* 1.0 | October 24, 2025 |   | Initial Version
**/

public class shf_ApplicationSearchController {

	// private SHF_ApplicationSelector applicationSelector = new SHF_ApplicationSelector();

	/** Search Accounts by PAN / Phone / DOB **/
    @AuraEnabled(cacheable=true)
    public static List<Application__c> searchApplications(String name, String loanAggrement, String phone) {
        return new SHF_ApplicationSelector().selectByCriteria(name, loanAggrement, phone);
    }

}