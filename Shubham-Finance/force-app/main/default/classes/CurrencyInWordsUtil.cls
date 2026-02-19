/**
* @File Name          : CurrencyInWordsUtil.cls
* @Description        : For Converting figures in Words
* @Author             : Ashutosh Dubey
* @Test Class         : 
*==============================================================================
* Ver          Date            Author            Modification
*==============================================================================
* 1.0       30/01/2026      Ashutosh Dubey       Initial Version
*/

public class CurrencyInWordsUtil {

    private static final List<String> FIRST_TWENTY = new List<String>{'Zero','One','Two','Three','Four','Five','Six','Seven','Eight','Nine','Ten','Eleven','Twelve','Thirteen','Fourteen','Fifteen','Sixteen','Seventeen','Eighteen','Nineteen'};

    private static final List<String> TENS = new List<String>{'', '', 'Twenty','Thirty','Forty','Fifty','Sixty','Seventy','Eighty','Ninety'};

    private static final List<String> POWERS = new List<String>{'Crore','Lakh','Thousand','Hundred'};

    private static final List<Integer> THRESHOLDS = new List<Integer>{10000000, 100000, 1000, 100};

    private static List<String> convert(Integer value) {
        List<String> result = new List<String>();

        if (value == 0) {
            result.add(FIRST_TWENTY[0]);
            return result;
        }

        if (value < 20) {
            result.add(FIRST_TWENTY[value]);
            return result;
        }

        if (value < 100) {
            result.add(TENS[value / 10]);
            if (Math.mod(value, 10) > 0) {
                result.add(FIRST_TWENTY[Math.mod(value, 10)]);
            }
            return result;
        }

        for (Integer i = 0; i < THRESHOLDS.size(); i++) {
            Integer divisor = THRESHOLDS[i];
            if (value >= divisor) {
                result.addAll(convert(value / divisor));
                result.add(POWERS[i]);
                value = Math.mod(value, divisor);
            }
        }

        if (value > 0) {
            result.addAll(convert(value));
        }

        return result;
    }

    public static String formatINR(Decimal amount) {
        if (amount == null || amount < 0) {
            return '';
        }

        String numericPart = 'INR ' + amount.setScale(2).format();

        Integer rupees = amount.intValue();
        String words = String.join(convert(rupees), ' ')
            .toLowerCase();

        words = words.substring(0,1).toUpperCase() + words.substring(1);

        return numericPart + ' (INR ' + words + ' only)';
    }
}