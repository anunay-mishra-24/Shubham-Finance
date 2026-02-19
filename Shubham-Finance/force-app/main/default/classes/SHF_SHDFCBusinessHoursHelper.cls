/**
* @File Name : SHF_SHDFCBusinessHoursHelper.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 22, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 22, 2025 |   | Initial Version
**/

public with sharing class SHF_SHDFCBusinessHoursHelper {
	

    public class InputWrapper {
        @InvocableVariable(required=true)
        public Datetime startDate;

        @InvocableVariable(required=true)
        public Integer businessDays;

        @InvocableVariable(required=true)
        public Decimal hoursPerDay;
    }

    public class OutputWrapper {
        @InvocableVariable
        public Datetime dueDate;
    }

    @InvocableMethod(label='Calculate Due Date')
    public static List<OutputWrapper> calculateDueDate(List<InputWrapper> inputs) {


        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'SHDFC Service Business Hours' LIMIT 1];

        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {

            Long millisToAdd = (Long)(input.businessDays * input.hoursPerDay * 60 * 60 * 1000);

            Datetime dueDt = BusinessHours.add(bh.Id,input.startDate, millisToAdd );

            OutputWrapper out = new OutputWrapper();
            out.dueDate = dueDt;
            results.add(out);
        }

        return results;
    }
}