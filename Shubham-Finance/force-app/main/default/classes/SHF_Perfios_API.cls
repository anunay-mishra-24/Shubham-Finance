/**
* @File Name          : SHF_BANK_STATEMENT_Perfios_Integration
* @Description        : Class to get the Details to initiate Transaction
* @Author             : Karan Keswani
* 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0                           Initial Version
*/
public with sharing class SHF_Perfios_API {
    @AuraEnabled
    public static void initiateTransaction(String customerId,string password, Date fromDate, Date toDate){
        system.debug('ApplicantId===>'+customerId);
        system.debug('fromDate===>'+fromDate);
        system.debug('toDate===>'+toDate);
        SHF_BANK_STATEMENT_Perfios_Integration queueableInstance = new SHF_BANK_STATEMENT_Perfios_Integration(customerId,password,fromDate,toDate);
        System.enqueueJob(queueableInstance);
    }
    
    
    
    //Created by Karan
    public static void intiateAPITest(){
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        
        String endpoint = 'https://demo.perfios.com/KuberaVault/api/v3/organisations/shubhamHF/transactions';
        String host = 'demo.perfios.com';
        String path = '/KuberaVault/api/v3/organisations/shubhamHF/transactions';
        
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        
        String body =
            '<payload>'
            + '<txnId>Testing1234567</txnId>'
            + '<loanAmount>2000</loanAmount>'
            + '<loanDuration>6</loanDuration>'
            + '<loanType>Home</loanType>'
            + '<processingType>STATEMENT</processingType>'
            + '<transactionCompleteCallbackUrl>'
            + 'https://shubhamhousingfinance--dev.sandbox.my.salesforce.com/services/apexrest/TransactionCallback'
            + '</transactionCompleteCallbackUrl>'
            + '<proposedEmi>34555</proposedEmi>'
            + '<uploadingScannedStatements>true</uploadingScannedStatements>'
            + '<acceptancePolicy>atLeastOneTransactionInRange</acceptancePolicy>'
            + '<yearMonthFrom>2025-01</yearMonthFrom>'
            + '<autoDetectInstitution>true</autoDetectInstitution>'
            + '<yearMonthTo>2026-08</yearMonthTo>'
            + '<employmentType>Salaried</employmentType>'
            + '<employerName>TestingSSSSSSS</employerName>'
            + '</payload>';
        
        
        String perfiosDate = Datetime.now().formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
        String NL = '\n';
        
        String payloadHash = EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256', Blob.valueOf(body))
        );
        
        String privateKey =
            'MIIJKQIBAAKCAgEA3eDn4Czlf+uV7ffREML7P/ILU2fuAWavmz76dwR4N3rceDZO\r\n'
            + '0PSDGn3xEgMOJ7RfQx5iz1VYEoZWVrBEq+yk5tSEPT1IbHfnDZwV2uia4DbxZafu\r\n'
            + '0Ca2Eke8CY+QaWodH4fYZNV9xjV2QMwXgtKUgrpvqlAFNBUMeaM+HqTz6H2EEZlZ\r\n'
            + 'tR8CDK5JtpoJWDwDKjYlqWgNGBBG4sBovbzErvyywrOWtKL2ESSA1cSE+4hZqhAt\r\n'
            + 'aWkfRLRbL6+4vdMQ3Vkr6p2EQ2FwhN8SyfWQ/Bwwx5Pcrwwf0yfWhMRgxhcstiAk\r\n'
            + 'dZTP7SJUE8lyZH4OZS1CLpqdDrSB8YMvC7nNnN7T5a1F+CUCb0yIRav6gVkG/iuZ\r\n'
            + 'RW7GUNEqSSRnHt7D0hT2dzBrTeVG4rpHrTZxDeEpoxkqwLbrAZK36pXswTj/s3wS\r\n'
            + 'IDMghjhy6kgZ5O8os8yLWYLBYV8GKs15MN/V7uO42LCbIo6LJXJI7j8y8GYFKCQ1\r\n'
            + '6p/jPNsB1FgPMPmQhwmcB7ftHxiE+zXPNWImyHY/gTbts5M/KrxzppCqgyIRt2wW\r\n'
            + 'x9lMh4u84eQGrd8lBoQGAwOg2iZQmuAj6C5CFoPpvVrb+A2GaGoJQEhYBCaAyxVl\r\n'
            + '0Cd6flzx1338PvTW3po0kmCVL4+05dSzf4HfczTvFZrzAmV+3/2qkjAx2ZUCAwEA\r\n'
            + 'AQKCAgAJ51BKRg6/YTdZvho/lohq8AWX5TdvKhN0CUFaPyGTjmEZX4kwk/1nGRCB\r\n'
            + '1o+S757h6tELwpoyB3uClo8WInOw1vMJHbtmFgsC5UDnesLw95raR/7lnRi646dN\r\n'
            + 'wPH39pPStLhQtePNjVTYKxPwk7ArzqEN19EHpFngcwwih4fYjIOw2mix6C6p/LyP\r\n'
            + 'ETySCum0QGL5dwrAlHdphx+Vun+H9QEQpj33lZ+In9m9UO6DoLAp4lt4jUfnQ+qf\r\n'
            + 'DAeht3JVAvYuHHZLIKYKVD+tMpAUZLi7q8qpqI+iF/DgD7jnFqE5BuHButD2G3Zn\r\n'
            + 'xLHdsO+5DeZamK2ieqWjL1ESA6rc/J95gkExHmWaIWDyyLWXq84mp+qUOpyzzo68\r\n'
            + 'wviX2NB9UNgkq+k/ayq0QQae41S31OdHJ6cloVF23shqvwbCTvocnaKL9OOOXP+3\r\n'
            + '+lL07I5MVq4PYwdsLzU16bJKqNvycB1daegnd5kcEsCKs5GSVO36HXzNkhhvll41\r\n'
            + 'yOfZDXNx+hMz7kSKIMqtP0RWW8HY4qAFgjdjWrpdVGJuOPi/hK2X6nT6YUhZylgj\r\n'
            + '/tIXX1fZVHmpAbzEUW3a4zUZDy/sY8ZYUmTL4Oue6JOqb9fs8dbmR/6ukqOhjGfP\r\n'
            + '2ebyEGpMht6KbxG8Op/cTFCJKQbQ9hB/uP2VUCzVq+ZzJci4SQKCAQEA9P6vVYgP\r\n'
            + '9uzeilnypn3b3vfFHs20oj3mMqvcC3usiuqNOU+mlFWqLYuL2DqQGewGdKVrme02\r\n'
            + 'KKxcdq+EAMcPqn9xE9Y8yZx16+C16PcdpbK1wOP4EZrT8dlhxJsH0hjQLa1N9rJt\r\n'
            + 'XiHuuqp17waH51jwcn0m6zUxi0I1zUkrGz9p0fvRgRurfXOKU8qdwuL/bENoM7G7\r\n'
            + 'DCDW6XwBxfs87BsrKXXLE3ull67+y008qVO1QMY1qVmAOOMu/jITpTxtrHqQLtwp\r\n'
            + '1F1oREJbGNneO1Ux7qh5Rc76mlHY+muLKsDUDa1CsZ9/P13LbxXFksQTXzbKSddz\r\n'
            + 'C78dRoG3W55/GQKCAQEA59hlHufnH0DRGtNceyNkh0++8Ln2bfrp4qQ0SFfTm3ik\r\n'
            + 'anS70gWjrnHQEdKpd05XKQiexPwDJx+KBjHhN2XEqGPlk7xqlT/0rwReVK8FBuMc\r\n'
            + 'CvZr9S6Vxcq8v0AwQqdH9/A8Ljsc9WBLUSbuGOJyHwlqei3wwy9JREIW0d3wk47t\r\n'
            + 'WG2E03h7H/QC0TU3lthv4vvNNG0U8BJ8c9bAQf2UBGBudRcDnqe5C5+XAbNdcBUg\r\n'
            + 'I5eJUc9HAd5fx0ESlFtOmO3HWbcDkN76krmoVzbXxHWD2dcKaPhx4eExAzjXYEAC\r\n'
            + 'WgbyE+Rmh69YhDd9i0Fxp4QcXdYGhZo7BslfeyBJ3QKCAQEAjJXFOTiNqK09+ngp\r\n'
            + 'FL7uN6FIXSe/esY4XWVfLLu4RDLZ/UQmm8IYmHAWPGtGm4lkHvV5rGeBh494s6Z+\r\n'
            + 'AhA4ficJVU+/rBV7WXKmEFwViCrnvxtSE5AcBREv2Cj6MOaKN1vWfDThK34fRsBg\r\n'
            + 'UlwWCnxv5dLJTXlFx9qjkvxknwshhxyQmRyuqJtviiufoeCun4qCtf9MDWaezHab\r\n'
            + 'ced8iyP//ZeZg8GVQVhq33Cf2a6uONBEpLw2Ju6+3aEQwuXNLYdbS3iNDE7ZcSn+\r\n'
            + 'qmEC9Fsr/v5wMM3X4kwLTY/+2Paz+HEu70xOMad6AHGm4VRgpWeEZyEZ5GizvOzc\r\n'
            + 'sddeqQKCAQEAvWafvW7P9k06RkLzIzmXr57rKreQ5On9VgS1HYB6Q2F8V+eDZKDs\r\n'
            + 'xd7+jwDdJrUeKUx8gAos/TIbzNHE3j/KN5Jcg6OCIul7l9rmwSG15pl0WFRVf5gO\r\n'
            + 'DOaB6W+jvV/xQFDGqTHrh12iSeqWykd72XUUwjlzndCsdxHSmKJKHhG+PeZCg4vC\r\n'
            + 'cikigAyMnDO2u+TfD/wpBbLkbrG6oG5rFGQ++HLTpzH3ztISR/Zi1+S6O7lZGjdO\r\n'
            + 'F+21qw6zAfXRsMdXeygyxpASffkj2BPakwk5rKWrQHPufQw9wRcXg+7mvOs9qhiF\r\n'
            + '1kTd+C1o53GQSrx3fAUTkOOdYv7xfKG1FQKCAQBAOH5a06t6AmVlcEF3OihlAJJt\r\n'
            + 'kWlO0BXrhlkZbNLjbqv967iGz15kBr5K7S/85q6uV6cHTiIWp52SJy5MujpIbu2o\r\n'
            + 'hfwNK3DKmY6d9mPf6fv0/zn7m2gHfqBHdD8VsxjIwuWrdk0l+RimeN1pydDki1Bw\r\n'
            + '52tEUrqf1h7OfIzB156bHfhV5i5o/fCJr1MtyUthLUn2TSdWXtjNeGqjjFmjzbhn\r\n'
            + 'pf1bXoF4UB3H9UeD5lVJgzGvx/aCOwrqrOxY4OFI3ZjTMN7rLUgp92OObDJ7FmxE\r\n'
            + 'jBOi778lNp5gWVD2os1oc3p2imV/Sjc6n/263+hZGfGqqll4rU53EBnJVDnx';
        
        Blob privateKeyBlob = EncodingUtil.base64Decode(privateKey);
        
        String canonicalHeaders =
            'host:' + host + NL +
            'x-perfios-content-sha256:' + payloadHash + NL +
            'x-perfios-date:' + perfiosDate;
        
        String signedHeaders = 'host;x-perfios-content-sha256;x-perfios-date';
        
        String canonicalRequest =
            'POST' + NL +
            path + NL + NL +
            canonicalHeaders + NL + NL +
            signedHeaders + NL +
            payloadHash;
        
        String stringToSign =
            'PERFIOS-RSA-SHA256' + NL +
            perfiosDate + NL +
            EncodingUtil.convertToHex(
                Crypto.generateDigest('SHA-256', Blob.valueOf(canonicalRequest))
            );
        
        String signature = EncodingUtil.convertToHex(
            Crypto.sign('RSA-SHA256', Blob.valueOf(stringToSign), privateKeyBlob)
        ).toLowerCase();
        
        req.setHeader('Content-Type', 'application/xml');
        req.setHeader('Host', host);
        req.setHeader('X-Perfios-Algorithm', 'PERFIOS-RSA-SHA256');
        req.setHeader('X-Perfios-Date', perfiosDate);
        req.setHeader('X-Perfios-Content-Sha256', payloadHash);
        req.setHeader('X-Perfios-Signature', signature);
        req.setHeader('X-Perfios-Signed-Headers', signedHeaders);
        //req.setHeader('Cookie', 'cf_bm=WzYz2n5YXXGkMOdEypuA2UTUEpvILYsZgJ8CMZVWkm0-1768209910.078192-1.0.1.1-.y1CRy4AO8Zt4qpLoZwHsFi0ozmh0KUcdSVFhEp2Bp_jlq9u.LPsalJXJ3MtKrtFtyUSkTWqTuaY5hCpbjXoaeFLE8hDOw2x1rR4JsJG2ktc2iwmlrMJV4fDMAk1NR3F');
        
        
        req.setBody(body);
        
        System.debug('CanonicalRequest:\n' + canonicalRequest);
        System.debug('StringToSign:\n' + stringToSign);
        System.debug('Signature:\n' + signature);
        
        HttpResponse res = http.send(req);
        System.debug('Status Code: ' + res.getStatusCode());
        System.debug('Response: ' + res.getBody());
        
    }
    
    
    //--------------------------------------------------------------------
     static String privateKey = 
         	//+'-----BEGIN RSA PRIVATE KEY-----\r\n'
	  		 
            'MIIJKQIBAAKCAgEA3eDn4Czlf+uV7ffREML7P/ILU2fuAWavmz76dwR4N3rceDZO\r\n'
            + '0PSDGn3xEgMOJ7RfQx5iz1VYEoZWVrBEq+yk5tSEPT1IbHfnDZwV2uia4DbxZafu\r\n'
            + '0Ca2Eke8CY+QaWodH4fYZNV9xjV2QMwXgtKUgrpvqlAFNBUMeaM+HqTz6H2EEZlZ\r\n'
            + 'tR8CDK5JtpoJWDwDKjYlqWgNGBBG4sBovbzErvyywrOWtKL2ESSA1cSE+4hZqhAt\r\n'
            + 'aWkfRLRbL6+4vdMQ3Vkr6p2EQ2FwhN8SyfWQ/Bwwx5Pcrwwf0yfWhMRgxhcstiAk\r\n'
            + 'dZTP7SJUE8lyZH4OZS1CLpqdDrSB8YMvC7nNnN7T5a1F+CUCb0yIRav6gVkG/iuZ\r\n'
            + 'RW7GUNEqSSRnHt7D0hT2dzBrTeVG4rpHrTZxDeEpoxkqwLbrAZK36pXswTj/s3wS\r\n'
            + 'IDMghjhy6kgZ5O8os8yLWYLBYV8GKs15MN/V7uO42LCbIo6LJXJI7j8y8GYFKCQ1\r\n'
            + '6p/jPNsB1FgPMPmQhwmcB7ftHxiE+zXPNWImyHY/gTbts5M/KrxzppCqgyIRt2wW\r\n'
            + 'x9lMh4u84eQGrd8lBoQGAwOg2iZQmuAj6C5CFoPpvVrb+A2GaGoJQEhYBCaAyxVl\r\n'
            + '0Cd6flzx1338PvTW3po0kmCVL4+05dSzf4HfczTvFZrzAmV+3/2qkjAx2ZUCAwEA\r\n'
            + 'AQKCAgAJ51BKRg6/YTdZvho/lohq8AWX5TdvKhN0CUFaPyGTjmEZX4kwk/1nGRCB\r\n'
            + '1o+S757h6tELwpoyB3uClo8WInOw1vMJHbtmFgsC5UDnesLw95raR/7lnRi646dN\r\n'
            + 'wPH39pPStLhQtePNjVTYKxPwk7ArzqEN19EHpFngcwwih4fYjIOw2mix6C6p/LyP\r\n'
            + 'ETySCum0QGL5dwrAlHdphx+Vun+H9QEQpj33lZ+In9m9UO6DoLAp4lt4jUfnQ+qf\r\n'
            + 'DAeht3JVAvYuHHZLIKYKVD+tMpAUZLi7q8qpqI+iF/DgD7jnFqE5BuHButD2G3Zn\r\n'
            + 'xLHdsO+5DeZamK2ieqWjL1ESA6rc/J95gkExHmWaIWDyyLWXq84mp+qUOpyzzo68\r\n'
            + 'wviX2NB9UNgkq+k/ayq0QQae41S31OdHJ6cloVF23shqvwbCTvocnaKL9OOOXP+3\r\n'
            + '+lL07I5MVq4PYwdsLzU16bJKqNvycB1daegnd5kcEsCKs5GSVO36HXzNkhhvll41\r\n'
            + 'yOfZDXNx+hMz7kSKIMqtP0RWW8HY4qAFgjdjWrpdVGJuOPi/hK2X6nT6YUhZylgj\r\n'
            + '/tIXX1fZVHmpAbzEUW3a4zUZDy/sY8ZYUmTL4Oue6JOqb9fs8dbmR/6ukqOhjGfP\r\n'
            + '2ebyEGpMht6KbxG8Op/cTFCJKQbQ9hB/uP2VUCzVq+ZzJci4SQKCAQEA9P6vVYgP\r\n'
            + '9uzeilnypn3b3vfFHs20oj3mMqvcC3usiuqNOU+mlFWqLYuL2DqQGewGdKVrme02\r\n'
            + 'KKxcdq+EAMcPqn9xE9Y8yZx16+C16PcdpbK1wOP4EZrT8dlhxJsH0hjQLa1N9rJt\r\n'
            + 'XiHuuqp17waH51jwcn0m6zUxi0I1zUkrGz9p0fvRgRurfXOKU8qdwuL/bENoM7G7\r\n'
            + 'DCDW6XwBxfs87BsrKXXLE3ull67+y008qVO1QMY1qVmAOOMu/jITpTxtrHqQLtwp\r\n'
            + '1F1oREJbGNneO1Ux7qh5Rc76mlHY+muLKsDUDa1CsZ9/P13LbxXFksQTXzbKSddz\r\n'
            + 'C78dRoG3W55/GQKCAQEA59hlHufnH0DRGtNceyNkh0++8Ln2bfrp4qQ0SFfTm3ik\r\n'
            + 'anS70gWjrnHQEdKpd05XKQiexPwDJx+KBjHhN2XEqGPlk7xqlT/0rwReVK8FBuMc\r\n'
            + 'CvZr9S6Vxcq8v0AwQqdH9/A8Ljsc9WBLUSbuGOJyHwlqei3wwy9JREIW0d3wk47t\r\n'
            + 'WG2E03h7H/QC0TU3lthv4vvNNG0U8BJ8c9bAQf2UBGBudRcDnqe5C5+XAbNdcBUg\r\n'
            + 'I5eJUc9HAd5fx0ESlFtOmO3HWbcDkN76krmoVzbXxHWD2dcKaPhx4eExAzjXYEAC\r\n'
            + 'WgbyE+Rmh69YhDd9i0Fxp4QcXdYGhZo7BslfeyBJ3QKCAQEAjJXFOTiNqK09+ngp\r\n'
            + 'FL7uN6FIXSe/esY4XWVfLLu4RDLZ/UQmm8IYmHAWPGtGm4lkHvV5rGeBh494s6Z+\r\n'
            + 'AhA4ficJVU+/rBV7WXKmEFwViCrnvxtSE5AcBREv2Cj6MOaKN1vWfDThK34fRsBg\r\n'
            + 'UlwWCnxv5dLJTXlFx9qjkvxknwshhxyQmRyuqJtviiufoeCun4qCtf9MDWaezHab\r\n'
            + 'ced8iyP//ZeZg8GVQVhq33Cf2a6uONBEpLw2Ju6+3aEQwuXNLYdbS3iNDE7ZcSn+\r\n'
            + 'qmEC9Fsr/v5wMM3X4kwLTY/+2Paz+HEu70xOMad6AHGm4VRgpWeEZyEZ5GizvOzc\r\n'
            + 'sddeqQKCAQEAvWafvW7P9k06RkLzIzmXr57rKreQ5On9VgS1HYB6Q2F8V+eDZKDs\r\n'
            + 'xd7+jwDdJrUeKUx8gAos/TIbzNHE3j/KN5Jcg6OCIul7l9rmwSG15pl0WFRVf5gO\r\n'
            + 'DOaB6W+jvV/xQFDGqTHrh12iSeqWykd72XUUwjlzndCsdxHSmKJKHhG+PeZCg4vC\r\n'
            + 'cikigAyMnDO2u+TfD/wpBbLkbrG6oG5rFGQ++HLTpzH3ztISR/Zi1+S6O7lZGjdO\r\n'
            + 'F+21qw6zAfXRsMdXeygyxpASffkj2BPakwk5rKWrQHPufQw9wRcXg+7mvOs9qhiF\r\n'
            + '1kTd+C1o53GQSrx3fAUTkOOdYv7xfKG1FQKCAQBAOH5a06t6AmVlcEF3OihlAJJt\r\n'
            + 'kWlO0BXrhlkZbNLjbqv967iGz15kBr5K7S/85q6uV6cHTiIWp52SJy5MujpIbu2o\r\n'
            + 'hfwNK3DKmY6d9mPf6fv0/zn7m2gHfqBHdD8VsxjIwuWrdk0l+RimeN1pydDki1Bw\r\n'
            + '52tEUrqf1h7OfIzB156bHfhV5i5o/fCJr1MtyUthLUn2TSdWXtjNeGqjjFmjzbhn\r\n'
            + 'pf1bXoF4UB3H9UeD5lVJgzGvx/aCOwrqrOxY4OFI3ZjTMN7rLUgp92OObDJ7FmxE\r\n'
            + 'jBOi778lNp5gWVD2os1oc3p2imV/Sjc6n/263+hZGfGqqll4rU53EBnJVDnx';
    		//+ '-----END RSA PRIVATE KEY-----';
    
    String host = 'demo.perfios.com';
    String perfiosDate = Datetime.now().formatGMT('yyyyMMdd\'T\'HHmmss\'Z\''); //'20230315T050234Z'; //Datetime.now().formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
    String txnID ='TXNUKSB01';
    String algorithm = 'PERFIOS1-RSA-SHA256';
    
    public AuthPayload createCanonicalRequest(string method, string path, string payload){
        AuthPayload cPayload = new AuthPayload();
        system.debug('payload: \n '+payload);
        String payloadHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(payload)));
    	String canonicalUri = path; 
        String canonicalQueryString = '';
        string canonicalHeaders= 'host:' + host + '\n' 
            + 'x-perfios-content-sha256:' + payloadHash + '\n' 
            + 'x-perfios-date:' + perfiosDate;
        String signedHeaders = 'host;x-perfios-content-sha256;x-perfios-date';
        String canonicalRequest = method + '\n' 
            + canonicalUri + '\n'  
            + canonicalQueryString + '\n' 
            + canonicalHeaders + '\n' 
            + signedHeaders + '\n' 
            + payloadHash;
        
        System.debug('canonicalRequest: \n'+canonicalRequest);        
        String stringToSign = algorithm + '\n' +  perfiosDate + '\n' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', Blob.valueOf(canonicalRequest)));
        System.debug('stringToSign: \n'+stringToSign);
        
        String Checksum = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(StringToSign))) ; 
        System.debug('Checksum: \n'+Checksum);        
        
        Blob privateKeyBlob = EncodingUtil.base64Decode(privateKey);
        String signature = EncodingUtil.convertToHex(Crypto.sign('RSA-SHA256', Blob.valueOf(Checksum), privateKeyBlob)).toLowerCase();
        
        System.debug('Updated signature: \n'+signature);
        cPayload.signature = signature;
        cPayload.perfdate = perfiosDate;
        cPayload.payloadHash = payloadHash;
        return cPayload;
        
    }
    
    public AuthPayload createCanonicalRequest1(string method, string path, string payload){
         AuthPayload cPayload = new AuthPayload();
        system.debug('payload: \n '+payload);
        String payloadHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(payload)));
    	String canonicalUri = path; 
        String canonicalQueryString = 'types=json';
        string canonicalHeaders= 'host:' + host + '\n' 
            + 'x-perfios-content-sha256:' + payloadHash + '\n' 
            + 'x-perfios-date:' + perfiosDate;
        String signedHeaders = 'host;x-perfios-content-sha256;x-perfios-date';
        String canonicalRequest = method + '\n' 
            + canonicalUri + '\n'  
            + canonicalQueryString + '\n' 
            + canonicalHeaders + '\n' 
            + signedHeaders + '\n' 
            + payloadHash;
        
        System.debug('canonicalRequest: \n'+canonicalRequest);        
        String stringToSign = algorithm + '\n' +  perfiosDate + '\n' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', Blob.valueOf(canonicalRequest)));
        System.debug('stringToSign: \n'+stringToSign);
        
        String Checksum = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(StringToSign))) ; 
        System.debug('Checksum: \n'+Checksum);        
        
        Blob privateKeyBlob = EncodingUtil.base64Decode(privateKey);
        String signature = EncodingUtil.convertToHex(Crypto.sign('RSA-SHA256', Blob.valueOf(Checksum), privateKeyBlob)).toLowerCase();
        
        System.debug('Updated signature: \n'+signature);
        cPayload.signature = signature;
        cPayload.perfdate = perfiosDate;
        cPayload.payloadHash = payloadHash;
        return cPayload;
        
    }
    public void createTransaction(){
        String method = 'POST';
        String payload = '{"payload": {"loanAmount": "100000","loanDuration": "24","loanType": "Home","processingType":"STATEMENT","transactionCompleteCallbackUrl": "https://example.com/callback","txnId": "PQ1342687YTX","acceptancePolicy": "atLeastOneTransactionPerMonthInRange","yearMonthFrom": "2023-11","yearMonthTo": "2024-02","proposedEmi": "234536","employmentType": "Salaried","employerName": "ABCD.ltd"}}';  
    	String path = '/KuberaVault/api/v3/organisations/salesforceLOS/transactions';
    	String endpoint = 'https://demo.perfios.com/KuberaVault/api/v3/organisations/shubhamHF/transactions';
    
        AuthPayload cPayload = createCanonicalRequest(method, path, payload);
    	HTTP http = new HTTP();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('content-type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Host', host);
        req.setHeader('X-Perfios-Algorithm', algorithm);
        req.setHeader('X-Perfios-Content-Sha256', cPayload.payloadHash);
        req.setHeader('X-Perfios-Date', cPayload.perfdate);
        req.setHeader('X-Perfios-Signature', cPayload.signature);
        req.setHeader('X-Perfios-Signed-Headers', 'host;x-perfios-content-sha256;x-perfios-date');
        req.setBody(payload);
        system.debug('Request: \n'+req);
        HTTPResponse res = http.send(req);
        System.debug('Response: \n'+res.getStatus()+'---'+res.getBody());
    }    

    public class AuthPayload{
        public string signature;
        public string perfdate;
        public string payloadHash;
    }
}