/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_Hunter_Future
 * Author          : Preeti
 * Created Date    : Jan 28, 2026
 * Last Modified By: Preeti
 * Last Modified On: Jan 28, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jan 28, 2026  │ Preeti │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */


public class SHF_Hunter_Future {
    
    // Future method to call Hunter API asynchronously for a given Loan Applicant

    @future(callout=true)
    public static void callHunter(Id loanApplicantId) {
            try {
                // API call
              SHF_Hunter_API_Service.callHunterAPI(loanApplicantId);
            } catch (Exception e) {
                Logger.error('Hunter API failed for Applicant ' + loanApplicantId + ' | ' + e.getMessage());
            }
        }
}