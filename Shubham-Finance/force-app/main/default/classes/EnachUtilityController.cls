/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : EnachUtilityController
 * Author          : Ashish Sharma
 * Created Date    : Feb 11, 2026
 * Last Modified By: Ashish Sharma
 * Last Modified On: Feb 11, 2026
 * Description     : This class implements for Enach Utility controller
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Feb 11, 2026  │ Ashish Sharma   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class EnachUtilityController {

	/**
     * Generate SHA-256 checksum in HEX format
     */
    public static String generateChecksum(String accountNo, String startDate, String expiryDate, String debitAmount, String maxAmount) {

        // Ensure null safety
        accountNo   = accountNo   == null ? '' : accountNo;
        startDate   = startDate   == null ? '' : startDate;
        expiryDate  = expiryDate  == null ? '' : expiryDate;
        debitAmount = debitAmount == null ? '' : debitAmount;
        maxAmount   = maxAmount   == null ? '' : maxAmount;

        // Concatenate in exact required order
        String rawString = accountNo + '|' +
                           startDate + '|' +
                           expiryDate + '|' +
                           debitAmount + '|' +
                           maxAmount;

        // Convert to Blob
        Blob inputBlob = Blob.valueOf(rawString);

        // Generate SHA-256 hash
        Blob hashBlob = Crypto.generateDigest('SHA-256', inputBlob);

        // Convert to HEX string (HDFC typically expects HEX)
        return EncodingUtil.convertToHex(hashBlob);
    }

	// **HDFC Provided Base64 Encoded AES Key need to store in Label
    private static final String BASE64_AES_KEY = 'MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=';

    /**
     * Encrypts value using AES-256-CBC with managed IV
     */
    public static String encryptAES256(String plainText) {

        if (String.isBlank(plainText)) {
            return '';
        }

        // Decode Base64 key to Blob
        Blob keyBlob = EncodingUtil.base64Decode(BASE64_AES_KEY);

        // Convert text to Blob (UTF-8)
        Blob dataBlob = Blob.valueOf(plainText);

        // Encrypt using AES256 with managed IV
        Blob encryptedBlob = Crypto.encryptWithManagedIV('AES256', keyBlob, dataBlob);

        // Return Base64 encoded encrypted string
        return EncodingUtil.base64Encode(encryptedBlob);
    }
}