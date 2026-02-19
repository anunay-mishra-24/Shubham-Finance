/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_HunterValidatorOnStageMovement
 * Author          : Pankaj Anand
 * Created Date    : Feb 4, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Feb 4, 2026  │ Pankaj Anand   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class SHF_HunterValidatorOnStageMovement {

	public static String validateApplicantsFinalDecision(Id applicationId){

		List<Hunter_Verification__c> hunters = [
            SELECT Id, Loan_Applicant__r.Name, Final_Decision__c
            FROM Hunter_Verification__c
            WHERE Application__c = :applicationId
        ];

        for (Hunter_Verification__c hunter : hunters) {
            if (hunter.Final_Decision__c != 'Green') {
                return 'Hunter Verification for ' + hunter.Loan_Applicant__r.Name +
                    ' is ' + hunter.Final_Decision__c +
                    '. The loan application cannot move further';
            }
        }

		return '';
	}

}