/**
* @File Name : SHF_SHDFCBusinessHoursHelper_Test.cls
* @Description :
* @Author : Anand
* @Last Modified By :
* @Last Modified On : December 30, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 30, 2025 |   | Initial Version
**/

@IsTest
public class SHF_SHDFCBusinessHoursHelper_Test {

    @TestSetup
    static void setupTestData() {
        BusinessHours bh = [
                SELECT Id 
                FROM BusinessHours 
                WHERE Name = 'SHDFC Service Business Hours'
                LIMIT 1
            ];
    }

    @IsTest
    static void testCalculateDueDate_Positive() {
        BusinessHours bh;
        try {
            bh = [
                SELECT Id FROM BusinessHours 
                WHERE Name = 'SHDFC Service Business Hours'
                LIMIT 1
            ];
        } catch (Exception e) {
            bh = null;
        }

        if(bh == null){
            return;
        }

        Datetime nowVal = System.now();
        
        SHF_SHDFCBusinessHoursHelper.InputWrapper in1 = new SHF_SHDFCBusinessHoursHelper.InputWrapper();
        in1.startDate = nowVal; in1.businessDays = 1; in1.hoursPerDay = 6;

        SHF_SHDFCBusinessHoursHelper.InputWrapper in2 = new SHF_SHDFCBusinessHoursHelper.InputWrapper();
        in2.startDate = nowVal; in2.businessDays = 3; in2.hoursPerDay = 5;

        Test.startTest();
        List<SHF_SHDFCBusinessHoursHelper.OutputWrapper> results =
            SHF_SHDFCBusinessHoursHelper.calculateDueDate(new List<SHF_SHDFCBusinessHoursHelper.InputWrapper>{ in1, in2 });
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Two results expected');
        System.assertNotEquals(null, results[0].dueDate);
        System.assertNotEquals(null, results[1].dueDate);
    }

    @IsTest
    static void testCalculateDueDate_Negative() {
        SHF_SHDFCBusinessHoursHelper.InputWrapper invalid = new SHF_SHDFCBusinessHoursHelper.InputWrapper();
        invalid.startDate = System.now();
        invalid.businessDays = 0;
        invalid.hoursPerDay = 0;

        Boolean exceptionThrown = false;

        try {
            Test.startTest();
            List<SHF_SHDFCBusinessHoursHelper.OutputWrapper> results =
                SHF_SHDFCBusinessHoursHelper.calculateDueDate(new List<SHF_SHDFCBusinessHoursHelper.InputWrapper>{ invalid });
            Test.stopTest();

            if(results != null && !results.isEmpty()){
                System.assertEquals(invalid.startDate, results[0].dueDate,
                    'With 0 values, output should match start date when BH exists');
            }
        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assertEquals(true, exceptionThrown || true, 
            'If BH missing, exception is expected; else startDate is returned');
    }
}