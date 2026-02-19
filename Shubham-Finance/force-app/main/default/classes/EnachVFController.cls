public without sharing class EnachVFController {

   public String applicationId { get; set; }

    // User Editable Inputs
    public String customerName { get; set; }
    public String accountNo    { get; set; }
    public String mobile       { get; set; }
    public String email        { get; set; }
    public String debitAmount  { get; set; }
    public String maxAmount    { get; set; }

    public String startDate    { get; set; }
    public String expiryDate   { get; set; }

    public String debitFrequency { get; set; }
    public String sequenceType   { get; set; }
    public String accountType    { get; set; }
    //Encrypt
    public String encUtilCode     { get; set; }
    public String encShortCode    { get; set; }
    public String encCustomerName { get; set; }
    public String encAccountNo    { get; set; }
    public String encMobile       { get; set; }
    public String encEmail        { get; set; }

    public String checkSum { get; set; }
    public String msgId    { get; set; }

    public Boolean readyToPost { get; set; }

    public EnachVFController() {

        // Get parameter from URL
        applicationId = ApexPages.currentPage().getParameters().get('applicationId');

        if(String.isBlank(applicationId)) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Invalid Application Id'
            ));
            return;
        }

        // Query application manually
        Application__c application = [SELECT Id, Customer_First_Name__c, Loan_Account_Number__c,Contact_No1__c FROM Application__c WHERE Id = :applicationId LIMIT 1];
        System.debug('application==>'+application);
        customerName = application.Customer_First_Name__c;
        accountNo    = application.Loan_Account_Number__c;
        mobile       = application.Contact_No1__c;
        email        = 'dummy@gmail.com';

        debitAmount  = '1000.00';
        startDate   = String.valueOf(Date.today());
        expiryDate   = String.valueOf(Date.today().addYears(1));
        debitFrequency  = 'MNTH';
        sequenceType    = 'RCUR';
        accountType     = 'S';
        maxAmount = '';

        msgId = 'MSG' + Datetime.now().getTime();
        encUtilCode  = EnachUtilityController.encryptAES256('NACH00000000000020');
        System.debug('encUtilCode==>'+encUtilCode);
        encShortCode = EnachUtilityController.encryptAES256('SHUBH');
        System.debug('encShortCode==>'+encShortCode);
        readyToPost = false;
    }


    public void encryptAndPrepare() {

        encCustomerName = EnachUtilityController.encryptAES256(customerName);
        encAccountNo    = EnachUtilityController.encryptAES256(accountNo);
        encMobile       = EnachUtilityController.encryptAES256(mobile);
        encEmail        = EnachUtilityController.encryptAES256(email);
        
        System.debug('accountNo==>'+accountNo);
        System.debug('startDate==>'+startDate);
        System.debug('expiryDate==>'+expiryDate);
        System.debug('debitAmount==>'+debitAmount);
        System.debug('maxAmount==>'+maxAmount);
        checkSum = EnachUtilityController.generateChecksum(accountNo,startDate,expiryDate, debitAmount, maxAmount);
        System.debug('checkSum===>'+checkSum);
        readyToPost = true;
    }
}