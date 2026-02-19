/**
 * @File Name          : UB_CommonUtil.cls
 * @Description        : Common class to define reusable methods
 * @Author             : Riteek Tiwari
 *
 *==============================================================================
 * Ver         Date                     Author                 Modification
 *==============================================================================
 * 1.0         19-06-2025            Riteek Tiwari         Initial Version
 */

public class SHF_CommonUtil {
    
    /**
     * @Description : Method to fetch MetaDataRecord based on source value.
     * @Author      : Riteek
     * @Date        : 24/06/2025
     */
    public static Map<String,Messages_Config__mdt> getMessageRecord(String source) {
        Map<String,Messages_Config__mdt> messageConfigMap = new Map<String,Messages_Config__mdt>();
        for(Messages_Config__mdt metaDataRecord :[SELECT  Id,Message__c,Message_Type__c,DeveloperName  FROM Messages_Config__mdt WHERE Source__c = :source]) {
            messageConfigMap.put(metaDataRecord.DeveloperName , metaDataRecord );
        }
        return messageConfigMap;
    }
     /**
     * @Description : Method to fetch All MetaData Records .
     * @Author      : Mansur
     * @Date        : 18/09/2025
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Messages_Config__mdt> getMessageConfigurations() {
        Map<String, Messages_Config__mdt> messagesMap = new Map<String, Messages_Config__mdt>();
        
        // Get all records of the custom metadata type
        List<Messages_Config__mdt> messages = Messages_Config__mdt.getAll().values();
        
        for (Messages_Config__mdt message : messages) {
            messagesMap.put(message.DeveloperName, message);
        }
        
        return messagesMap;
    }
    /**
     * @Description : Method to fetch  MetaData Records on the basis of source.
     * @Author      : Mansur
     * @Date        : 17/10/2025
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Messages_Config__mdt> getMessageConfigurationsBySource(String source) {
        Map<String, Messages_Config__mdt> messagesMap = new Map<String, Messages_Config__mdt>();
        
        // Get all records of the custom metadata type
        List<Messages_Config__mdt> messages = [SELECT Id,DeveloperName,Source__c,Message__c,Message_Type__c FROM Messages_Config__mdt  WHERE Source__c =:source ];
        
        for (Messages_Config__mdt message : messages) {
            messagesMap.put(message.DeveloperName, message);
        }
        return messagesMap;
    }
    /**
     * @Description : Method to fetch API Fields MetaDataRecord based on source value.
     * @Author      : Riteek
     * @Date        : 10/07/2025
     */
     @AuraEnabled(cacheable=true)
    public static Map<String,API_Fields_Mapping__mdt> getAPIFieldsMappingsRecord(String source) {
        Map<String,API_Fields_Mapping__mdt> messageConfigMap = new Map<String,API_Fields_Mapping__mdt>();
        for(API_Fields_Mapping__mdt metaDataRecord :[SELECT  Id,Code__c,MasterLabel,DeveloperName  FROM API_Fields_Mapping__mdt WHERE Source__c = :source]) {
            messageConfigMap.put(metaDataRecord.DeveloperName , metaDataRecord );
        }
        system.debug('messageConfigMap>> ' + messageConfigMap);
        return messageConfigMap;
    }
    
    /**
     * @Description : Method to fetch API Fields MetaDataRecord based on source value using label.
     * @Author      : Kunal
     * @Date        : 14/08/2025
     */
    public static Map<String,API_Fields_Mapping__mdt> getAPIFieldsMappingsRecordByLabel(String source) {
        Map<String,API_Fields_Mapping__mdt> messageConfigMap = new Map<String,API_Fields_Mapping__mdt>();
        for(API_Fields_Mapping__mdt metaDataRecord :[SELECT  Id,Code__c,MasterLabel,DeveloperName  FROM API_Fields_Mapping__mdt WHERE Source__c = :source]) {
            messageConfigMap.put(metaDataRecord.MasterLabel , metaDataRecord );
        }
        return messageConfigMap;
    }
    
    /**
     * @Description : Method to create E-Verification record
     * @Author      : Riteek
     * @Date        : 19/06/2025
     */
    //Create E-verification Record
    public static E_Verification__c createVerfication (String loanApplicantId, String recordTypeId, String appStatus){
        E_Verification__c obj = new E_Verification__c(
        Loan_Applicant__c = loanApplicantId,
        RecordTypeId      = recordTypeId,
        Status__c         = appStatus
            );
        return obj;
    }
    
    /**
     * @Description : Method to create Address record
     * @Author      : Riteek
     * @Date        : 19/06/2025
     */
    //Create Address Record
    public static Address__c createAddress (String loanApplicantId, String addressType){
        Address__c obj = new Address__c(
            Loan_Applicant__c = loanApplicantId,
        // RecordTypeId      = recordTypeId,
        Address_Type__c   = addressType
            );
        return obj;
    }
    
    /**
     * @Description : Method to create Document__c record
     * @Author      : Riteek
     * @Date        : 21/07/2025
     */
    public static Document__c createDocument(String name, String applicationId, String docType) {
        Document__c doc = new Document__c(
        File_Name__c              = name,
        Application__c = applicationId,
        Document_Type__c  = docType
            );
        System.debug('doc-> '+doc);
        return doc;
    }
    
    /**
     * @Description : Utility method to format encoded characters from SMS templates
     * @Author      : Harshita Rathod
     * @Date        : 17/07/2025
     */
    public static String formatSMSTemplate(String templateText) {
        if (String.isBlank(templateText)) return templateText;
        String checkSMS = templateText.replace(' ','%20').replace('\r\n','%0A').replace('\n','%0A').replace('\r','%0A').replace('&','%26');// added by vikas Soni on 6 december
        return checkSMS;
    }
    
    
    @AuraEnabled
    public static String fetchVerificationId(Id customerId, String apiName) {
        if (String.isNotBlank(customerId) && String.isNotBlank(apiName)) {
            System.debug('apiName<<>> ' + apiName);
            System.debug('customerId<<>> ' + customerId);
            
            Schema.SObjectType sObjType = customerId.getSObjectType();
            System.debug('SObject Type: ' + sObjType);
            
            if (sObjType == Loan_Applicant__c.SObjectType) {
                List<Loan_Applicant__c> listOfApplicantRec = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ customerId });
                Loan_Applicant__c applicantRec = listOfApplicantRec[0];
                if (apiName == SHF_ConstantsUtil.PAN_API) {
                    return applicantRec.PAN_Verification__c;
                } else if (apiName == SHF_ConstantsUtil.Mobile_MNRL_API) {
                    return applicantRec.Mobile_Verification__c;
                }else if (apiName == SHF_ConstantsUtil.MNR_API) {
                    return applicantRec.Mobile_Verification__c;
                } else if (apiName == SHF_ConstantsUtil.KYC_DigiLocker_API || apiName == SHF_ConstantsUtil.KYC_DigilockerDetailsService_API || apiName == SHF_ConstantsUtil.AADAR_DIGILOCKER_API) {
                    return applicantRec.Digilocker_Verification__c;
                } else if (apiName == SHF_ConstantsUtil.GST_API) {
                    return applicantRec.GST_Verification__c;
                } else if (apiName == SHF_ConstantsUtil.PENNY_DROP_API) {
                    return applicantRec.Penny_Drop_Verification__c;
                } else if (apiName == SHF_ConstantsUtil.ELECTRICITY_API) {
                    return applicantRec.Electricity_Verification__c;
                } else if (apiName == SHF_ConstantsUtil.UDYAM_API) {
                    return applicantRec.Udyam_Verification__c;
                } else if (apiName == SHF_ConstantsUtil.INSURANCE_API) {
                    return applicantRec.Insurance_Verification__c;
                }
                else if (apiName == SHF_ConstantsUtil.AML_API) {
                    return applicantRec.AML_Verification__c;
                }
                 //Added by Dimple for Hunter Verification
                else if (apiName == SHF_ConstantsUtil.Hunter_API) {
                    return applicantRec.Hunter_Verification__c;
                }
                else if (apiName == SHF_ConstantsUtil.VOTERID_API) {
                    return applicantRec.VoterId_Verification__c;
                }
                else if (apiName == SHF_ConstantsUtil.PASSPORT_API) {
                    return applicantRec.Passport_Verification__c;
                }
                 else if (apiName == SHF_ConstantsUtil.DLVERIFICATION_API) {
                    return applicantRec.DL_Verification__c;
                }
                else if (apiName == SHF_ConstantsUtil.SMSConsent_API) {
                    return applicantRec.SMS_Consent__c;
                }
                 else if (apiName == SHF_ConstantsUtil.EMAIL_VERIFICATION) {
                    return applicantRec.Email_Verification__c;
                }
                else if(apiName == 'EMPLOYMENT API'){
                    return applicantRec.Employment_Verification__c;
                }
                else if(apiName == 'Discover API'){
                    return applicantRec.Discover_Verification__c;
                }
                else if(apiName == SHF_ConstantsUtil.INSTANT_LITIGATION){
                    return applicantRec.Litigation_Instant_Verification__c;
                }
                else if(apiName == SHF_ConstantsUtil.INSTANT_LITIGATION_RESULT){
                    return applicantRec.Litigation_Instant_Verification__c;
                }
                else if(apiName == SHF_ConstantsUtil.ADVANCE_LITIGATION){
                    return applicantRec.Litigation_Advance_Verification__c;
                }
                
            } else if (sObjType == Application__c.SObjectType) {
                Application__c appRec = new SHF_ApplicationSelector().selectApplicationForCIBIL(customerId);
                if (apiName == SHF_ConstantsUtil.LOGIN_FEE_API) {
                    return appRec.Login_Fee_Verification__c;
                }
            } else {
                System.debug('Unsupported or unknown SObject type: ' + sObjType);
            }
        }
        return null;
    }
    
    
    /**
     *
     * @Description : Method to Sends a custom notification to a set of users.
     * @Author      : Kunal soni
     * @Date        : 01/07/2025
     *
     * @param recipientsIds Set of User IDs who will receive the notification.
     * @param targetId      The record ID the notification should link to.
     * @param title         Title of the notification.
     * @param body          Body text of the notification.
     */
    public static void notifyUsersByNotification(Set<String> recipientsIds, String targetId, String title, String body, string DeveloperName) {
        
        // Fetch the custom notification type by DeveloperName
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName 
            FROM CustomNotificationType 
            WHERE DeveloperName =: DeveloperName
        ];
        
        // Create and configure the custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
        
        // Send the notification
        notification.send(recipientsIds);
        
    }
    
    /**
     *
     * @Description : Method to Prepares a list of email messages to be sent to users.
     * @Author      : Kunal soni
     * @Date        : 01/07/2025
     *
     * @param recipientsIds List of email addresses to send the email to.
     * @param emailBody     Body of the email in plain text.
     * @return              List of Messaging.SingleEmailMessage to be used with Messaging.sendEmail().
     */
    public static List<Messaging.SingleEmailMessage> notifyUsersByEmail(List<String> recipientsIds, String emailBody, string subject) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Create and configure the email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(recipientsIds);
        mail.setSubject(subject); // Subject from a custom label
        mail.setPlainTextBody(emailBody);
        mail.setSenderDisplayName('SHF Salesforce');
        mail.setSaveAsActivity(true); // Logs email as an activity on recipient record
        
        emails.add(mail);
        return emails;
    }
    
    // Harshita Rathod - For internal emails
    public static List<Messaging.SingleEmailMessage> notifyUsersByEmail(List<String> recipientsIds, String emailBody, String subject, String displayName) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Query OrgWideEmailAddress only once
        OrgWideEmailAddress orgWide = [
            SELECT Id FROM OrgWideEmailAddress 
            WHERE DisplayName = :SHF_ConstantsUtil.ORG_WIDE_ADDRESS 
            LIMIT 1
        ];
        
        // Create and configure the email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(recipientsIds);
        mail.setSubject(subject); // Subject from a custom label
        mail.setPlainTextBody(emailBody);
        mail.setOrgWideEmailAddressId(orgWide.Id);
        mail.setSaveAsActivity(true); // Logs email as an activity on recipient record
        
        emails.add(mail);
        return emails;
    }
//SHF-306 
public static List<Messaging.SingleEmailMessage> notifyUsersByEmailHTMLApplication(
    List<String> recipientsIds,
    String emailBody,
    String subject,
    String displayName
) {
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(recipientsIds);
    mail.setSubject(subject);

    // FIX: Convert newline to HTML line break
    emailBody = emailBody.replace('\n', '<br/>');

    mail.setHtmlBody(emailBody);
    mail.setSenderDisplayName(displayName);
    mail.setSaveAsActivity(true);

    emails.add(mail);
    return emails;
}

    
    //Added by Riteek: Supports HTML content in the email body

     public static List<Messaging.SingleEmailMessage> notifyUsersByEmailHTML(List<String> recipientsIds, String emailBody, String subject, String displayName) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Create and configure the email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(recipientsIds);
        mail.setSubject(subject); // Subject from a custom label
         mail.setHtmlBody(emailBody);
        mail.setSenderDisplayName(displayName);
        mail.setSaveAsActivity(true); // Logs email as an activity on recipient record
        
        emails.add(mail);
        return emails;
    } 
    
    
    
    public static Id selectRecordTypeId(String sObjectTypeName, String developerName) {
        List<RecordType> recordTypes = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = :sObjectTypeName 
            AND DeveloperName = :developerName 
            LIMIT 1
        ];
        
        return recordTypes.isEmpty() ? null : recordTypes[0].Id;
    }
    
    
    /**
     * @Description : Converts the given Datetime value to the current user's local timezone
     * @Author      : Harshita Rathod
     * @Date        : 02/07/2025
     */
    public static Datetime formatToUserLocalTimezone(Datetime dtTime) {
        if (dtTime == null) return null;
        
        Integer offsetMillis = UserInfo.getTimeZone().getOffset(dtTime);
        return dtTime.addSeconds(offsetMillis / 1000);
    }
    
    public static Long calculateHours(Datetime date1, Datetime date2) {
        date1 = formatToUserLocalTimezone(date1);
        date2 = formatToUserLocalTimezone(date2);
        Long diffInMillis = date1.getTime() - date2.getTime();
        Decimal diffInMinutes = Decimal.valueOf(diffInMillis) / (1000 * 60);
        return Math.ceil(diffInMinutes).longValue(); // Round up fraction value
    }
    
    public static Datetime calculateBusinessHours(Integer days, Datetime date1){
        Id businessHoursId;
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = :SHF_ConstantsUtil.BUSINESSHOURS  LIMIT 1];
        if (bh != null) {
            businessHoursId = bh.Id;
        } else {
            Logger.info('Business Hours not found');
            businessHoursId = null;
        }
        
        Long millisDays =  days*24*60*60*1000;//14400000;
        return BusinessHours.addGmt(businessHoursId, date1, millisDays); //addGmt method used for UTC
        
    }
    
    
    /*
     * @Author      : Preeti
     * @Date        : 02/07/2025
     * @description Fetches Callout Framework metadata records based on the provided developer name.
     * This method retrieves API request templates and endpoint URLs dynamically from Custom Metadata.
     * @param developerName - The DeveloperName of the Callout_Framework__mdt record to retrieve.
     * @return Map of DeveloperName to Callout_Framework__mdt records.
     */
    public static Map<String, Callout_Framework__mdt> getCalloutMetadata(String developerName) {
        Map<String, Callout_Framework__mdt> calloutMetaMap = new Map<String, Callout_Framework__mdt>();
        
        for (Callout_Framework__mdt metaDataRecord : [
            SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, SystemModstamp, Active__c, Auth_Token_c__c, Body__c, Certificate_Name__c, Class_Name__c, Endpoint__c, Extra_Param_s__c, HeaderParams__c, Host__c, Mock_Response__c, Named_Credential__c, Timeout_Time__c, URL_Parameter_s__c, HTTP_Method__c
            FROM Callout_Framework__mdt 
            WHERE DeveloperName = :developerName
        ]) {
            calloutMetaMap.put(metaDataRecord.DeveloperName, metaDataRecord);
        }
        
        return calloutMetaMap;
    }
    
    
    
    /*
     * @Author      : Preeti
     * @Date        : 02/07/2025
     * @description Fetches Address Metadata for the given Callout Framework Id.
     * This method retrieves JSON key mappings and static values for dynamic address construction in API requests.
     * @param calloutFrameworkId - The Id of the Callout_Framework__mdt record to filter address metadata.
     * @return Map of JSON Key to Loan_Applicant_Address__mdt records.
     */
    
    public static Map<String, Loan_Applicant_Address__mdt> getAddressMetadata(Id calloutFrameworkId) {
        Map<String, Loan_Applicant_Address__mdt> addressMetaMap = new Map<String, Loan_Applicant_Address__mdt>();
        
        for (Loan_Applicant_Address__mdt metaDataRecord : [
            SELECT Id, Callout_Framework__c, JSON_Key__c, Static_Value__c
            FROM Loan_Applicant_Address__mdt 
            WHERE Callout_Framework__c = :calloutFrameworkId
        ]) {
            addressMetaMap.put(metaDataRecord.JSON_Key__c, metaDataRecord);
        }
        
        return addressMetaMap;
    }
    
    /**
     *
     * @Description : Method to Prepares a list of email messages to be sent to users Without setTargetObjectId.
     * @Author      : Kunal soni
     * @Date        : 09/07/2025
     *
     * @param recipientsIds   - List of email addresses to send the email to.
     * @param emailTemplateId - Id of email template.
     * @param whatId          - Object If for Merge Fields.
     * @return              List of Messaging.SingleEmailMessage to be used with Messaging.sendEmail().
     */
    public static List<Messaging.SingleEmailMessage> notifyingUsersByEmail(List<String> recipientsIds, string emailTemplateId, string whatId) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Create and configure the email
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        Messaging.SingleEmailMessage renderResult = Messaging.renderStoredEmailTemplate(
            emailTemplateId,
        NULL,
        whatId
            );
        message.setToAddresses(recipientsIds);
        message.setSubject(renderResult.getSubject());
        // Set the email body
        if(renderResult.getHtmlBody() == NULL)
            message.setPlainTextBody(renderResult.getPlainTextBody());
        else
            message.setHtmlBody(renderResult.getHtmlBody());
        
        // Specify OrgWideEmailAddress for sender type
        message.setOrgWideEmailAddressId([SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id);
        message.setSaveAsActivity(false);
        emails.add(message);
        return emails;
    }
    
    
    
    /*
     * @Author      : Preeti
     * @Date         : 11/07/2025
     * Retrieves all custom setting records (Name → SObject map) for the given custom setting API name.
     * @param settingApiName The API name of the custom setting object.
     * @return A Map where the key is the Name of each custom setting record, and the value is the full SObject record.
     */
    
    public static Map<String, SObject> getCustomSettingMap(String settingApiName) {
        Map<String, SObject> mapResult = new Map<String, SObject>();
        
        List<SObject> records = Database.query('SELECT Name,Value__c FROM ' + settingApiName);
        for (SObject record : records) {
            mapResult.put((String)record.get('Name'), record);
        }
        
        return mapResult;
    }
    
    
    /*
     * @Author      : Preeti
     * @Date         : 21/07/2025
     * Utility method to fetch Group Id using DeveloperName and Type.
     *
     * @param developerName The DeveloperName of the Group.
     * @param type The Type of the Group.
     * @return Id of the Group if found, null otherwise.
     */
    public static Id getGroupIdByDeveloperName(String developerName, String type) {
        Group grp = [
            SELECT Id 
            FROM Group 
            WHERE DeveloperName = :developerName AND Type = :type
            LIMIT 1
        ];
        return grp != null ? grp.Id : null;
    }
    
    public class NotifyEmailInput {
        @InvocableVariable(label='Recipient Emails')
        public List<String> recipientEmails;
        
        @InvocableVariable(label='Email Template Id')
        public String emailTemplateId;
        
        @InvocableVariable(label='What Id')
        public String whatId;
    }
    
    @InvocableMethod(label = 'Send Notification Email')
    public static void notifyUsersByEmail(List<NotifyEmailInput> inputList) {
        if (inputList == null || inputList.isEmpty()) return;
        
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        // Query OrgWideEmailAddress only once
        OrgWideEmailAddress orgWide = [
            SELECT Id FROM OrgWideEmailAddress 
            WHERE Address = :SHF_ConstantsUtil.ORG_WIDE_ADDRESS 
            LIMIT 1
        ];
        
        for (NotifyEmailInput input : inputList) {
            // Skip if recipients or template/whatId are missing
            if (input.recipientEmails == null || input.recipientEmails.isEmpty() ||
            String.isBlank(input.emailTemplateId) || String.isBlank(input.whatId)) {
                continue;
            }
            
            // Render the template for this record
            Messaging.SingleEmailMessage renderResult = Messaging.renderStoredEmailTemplate(
                input.emailTemplateId,
            null,
            input.whatId
                );
            
            // Create the actual email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(input.recipientEmails);
            email.setSubject(renderResult.getSubject());
            
            if (renderResult.getHtmlBody() == null) {
                email.setPlainTextBody(renderResult.getPlainTextBody());
            } else {
                email.setHtmlBody(renderResult.getHtmlBody());
            }
            
            email.setOrgWideEmailAddressId(orgWide.Id);
            email.setSaveAsActivity(false);
            
            emailsToSend.add(email);
        }
        
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
    
    /**
     * @File Name          : splitStringIntoCollection
     * @Description        :
     * @Author             : Mansur
     * @Test Class         :
     *==============================================================================
     * Ver         Date         Author     Modification
     *==============================================================================
     * 1.0         09-09-2025   Mansur     Initial Version
     */
    
    public static List<List<String>> splitStringIntoCollection(List<String> flowInput){ //['RCM;NCM;ZCM']
        system.debug('flowInput> ' + flowInput);
        List<List<String>> outPutCollection = new List<List<String>>();
        //logic to split string in to collection
        if(flowInput != null && !flowInput.isEmpty()){
            if(String.isNotBlank(flowInput[0])){
                List<String> splitInput = flowInput[0].split(';');
                system.debug('splitInput> ' + splitInput);
                // Trim any whitespace from each value in the resulting list
                List<String> trimmedValues = new List<String>();
                for (String value : splitInput) {
                    trimmedValues.add(value.trim());
                }
                system.debug('trimmedValues> '+ trimmedValues);
                // Add the list of trimmed, split values to our final output list
                outputCollection.add(trimmedValues);
            }else {
                // If the input string is blank, return a list containing an empty list to avoid errors in Flow
                outputCollection.add(new List<String>());
            }
        } else {
            // If the flowInputs list itself is null/empty, return a list containing an empty list
            outputCollection.add(new List<String>());
        }
        system.debug('outPutCollection> ' + outPutCollection);
        return outPutCollection;
    }
    
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
    @AuraEnabled
    public static List<String> getManagerOfManager(String userId){
        List<String> managerOfManagerList = new List<String>();
        Map<String,String> managerMap = new Map<String,String>();
        Set<String> hierarchyUsers  = new Set<String>();
        String profileName = '';
        try {
            SHF_UsersSelector userSelection = new SHF_UsersSelector();
            if(userId != null){
                Set<Id> userIdSet = new Set<Id>{userId};
                list<User> currentUserList = userSelection.selectByIdsUserName(userIdSet);
                profileName = currentUserList[0].Profile.Name;
            }
            
            list<User> userList = userSelection.selectActiveCustomerServiceUsers(profileName);
            if(!userList.isEmpty()){
                for(User user : userList){
                    managerMap.put(user.Id,user.ManagerId);
                }
            }
            Boolean valueExists = managerMap.values().contains(userId);
            if (managerMap.containsKey(userId) || valueExists) {
                // Add the user itself
                hierarchyUsers.add(userId);
                
                // Get all managers above (up the hierarchy)
                hierarchyUsers.addAll(getAllManagers(userId, managerMap));
                
                // Get all subordinates below (down the hierarchy)
                hierarchyUsers.addAll(getAllSubordinates(userId, managerMap));
            }
            
        } catch (Exception e) {
            system.debug('line no > ' + e.getLineNumber() + ' error message > ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        system.debug('All manager list>> ' +managerOfManagerList);
        //AuraEnabled methods do not support return type of Set..converitng set into LIst
        List<String>listOfAllManagers = new List<String>(hierarchyUsers);
        return listOfAllManagers;
    }
    //get all managers
    private static Set<String> getAllManagers(String userId, Map<String, String> managerMap) {
        Set<String> managers = new Set<String>();
        String currentUser = userId;
        
        // Traverse up the hierarchy
        while (managerMap.containsKey(currentUser)) {
            String manager = managerMap.get(currentUser);
            managers.add(manager);
            currentUser = manager;
        }
        return managers;
    }
    
    // get all the subordinate of the user
    private static Set<String> getAllSubordinates(String userId, Map<String, String> managerMap) {
        Set<String> subordinates = new Set<String>();
        
        // Find direct subordinates
        for (String subordinate : managerMap.keySet()) {
            if (managerMap.get(subordinate) == userId) {
                subordinates.add(subordinate);
                
                // Recursively get subordinates of subordinates
                subordinates.addAll(getAllSubordinates(subordinate, managerMap));
            }
        }
        return subordinates;
    }

    // get upper manager's id
    @AuraEnabled(cacheable=true)
    public static List<String> getUpperManagers(String roleName){
        List<User> users = new SHF_UsersSelector().selectByRoleNameName(roleName);
         String ProfileName = '';
         String userId = '';
          Set<String> hierarchyUsers  = new Set<String>();
          Map<String,String> managerMap = new Map<String,String>();
        if(!users.isEmpty()){
             ProfileName = users[0].Profile.Name;
            userId = users[0].Id;
        }
        if(profileName != null){
            list<User> userList = new SHF_UsersSelector().selectActiveCustomerServiceUsers(profileName);
            if(!userList.isEmpty()){
                for(User user : userList){
                    managerMap.put(user.Id,user.ManagerId);
                }
                if(managerMap.containsKey(userId)){
                    // Get all managers above (up the hierarchy)
                hierarchyUsers.addAll(getAllManagers(userId, managerMap));
                }
            }
        }
       
        if(!hierarchyUsers.contains(userId)){
            hierarchyUsers.add(userId);
        }
        List<String> upperManagerIds = new List<String>(hierarchyUsers);
        return upperManagerIds;
    }
    

    /**
     * @Author      : Preeti
     * @Date        : 01/10/2025
     * Fetch message from Messages_Config__mdt by DeveloperName
     * @param recordDevName - DeveloperName of the metadata record
     * @return Map<String, String> - keys: Message, MessageType
     */
    @AuraEnabled(cacheable=false)
    public static Map<String,String> getMessageFromMetadata(String recordDevName) {
        Map<String,String> result = new Map<String,String>{'Message'=>'', 'MessageType'=>'Info'};
        if(String.isBlank(recordDevName)) return result;

        try {
            Messages_Config__mdt md = [
                SELECT Message__c, Message_Type__c 
                FROM Messages_Config__mdt 
                WHERE DeveloperName = :recordDevName
                LIMIT 1
            ];
            result.put('Message', md.Message__c);
            result.put('MessageType', md.Message_Type__c);
        } catch(Exception e) {
            result.put('Message', 'Message not found.');
            result.put('MessageType', 'Error');
        }

        return result;
    }


    /**
     * Fetch Notification Template from Custom Metadata
     * @param developerName - API developer name of CMDT record
     * @return Map containing template fields OR null
     */
    public static Map<String, String> getNotificationTemplate(String developerName) {

        if (String.isBlank(developerName)) {
            return null;
        }

        try {
            Notification_Template__mdt rec = [
                SELECT Id,DeveloperName, Label,Bell_Notification__c,SMS_Notification__c, Email_Template__c FROM Notification_Template__mdt WHERE DeveloperName = :developerName LIMIT 1
            ];

            Map<String, String> result = new Map<String, String>();
            result.put('DeveloperName', rec.DeveloperName);
            result.put('Label', rec.Label);
            result.put('Bell_Notification', rec.Bell_Notification__c);
            result.put('SMS_Notification', rec.SMS_Notification__c);
            result.put('Email_Template', rec.Email_Template__c);

            return result;

        } catch (Exception e) {
            System.debug('Error fetching template: ' + e.getMessage());
            return null;
        }
    }
    
    // Cache to avoid repeated SOQL in same transaction
    private static Map<String, Map<String, Id>> recordTypeCache =
        new Map<String, Map<String, Id>>();

    /**
     * Returns a map of RecordType Name -> RecordTypeId for a given sObject
     *
     * Usage:
     * Map<String, Id> rtMap =
     *     SHF_CommonUtil.getRecordTypeMap(E_Verification_Line_Item__c.SObjectType);
     */
    public static Map<String, Id> getRecordTypeMap(Schema.SObjectType sObjType) {

        String objectName = sObjType.getDescribe().getName();

        // Return from cache if already queried
        if (recordTypeCache.containsKey(objectName)) {
            return recordTypeCache.get(objectName);
        }

        Map<String, Id> rtMap = new Map<String, Id>();

        for (RecordType rt : [
            SELECT Id, Name
            FROM RecordType
            WHERE SObjectType = :objectName
        ]) {
            rtMap.put(rt.Name, rt.Id);
        }

        recordTypeCache.put(objectName, rtMap);
        return rtMap;
    }


    /*
    //use this method to share the record with user or group of users--added by mansur on 12-09-2005
    public class FlowInputs{
        @InvocableVariable
        public String recordId;
        @InvocableVariable
        public String userOrGroupId;
        @InvocableVariable
        public String recordAccessLevel;
        
    }
    
    // @InvocableMethod(Label='Apex Record Sharing')
    public static void shareRecord(List<FlowInputs> request){
        if(request.size() > 0){
            system.debug('request'+request[0].recordId);
            system.debug('request'+request[0].userOrGroupId);
            system.debug('request'+request[0].recordAccessLevel);
            if(String.isNotBlank(request[0].recordId) && String.isNotBlank(request[0].userOrGroupId) && String.isNotBlank(request[0].recordAccessLevel)){
                createCustomObjectShare(request[0].recordId, request[0].userOrGroupId, request[0].recordAccessLevel, true);
            }
        }
    }
    
    public static sObject createCustomObjectShare(Id recordId, Id userOrGroupId, String recordAccessLevel, Boolean isShareRecord){
        String sObjLabel = recordId.getSObjectType().getDescribe().getName();
        system.debug('sObjLabel-> ' + sObjLabel);
        // Create new sharing object for the custom object Job.
        sObjLabel = sObjLabel.contains('__c') ? sObjLabel.remove('__c') : sObjLabel;
        system.debug('sObjLabel-> ' + sObjLabel);
        sObject sObj = Schema.getGlobalDescribe().get(sObjLabel + '__Share').newSObject();
        system.debug('sObj-> ' + sObj);
        // Set the ID of record being shared.
        sObj.put('ParentId',recordId);
        // Set the ID of user or group being granted access.
        sObj.put('UserOrGroupId',userOrGroupId);
        // Set the access level.
        sObj.put('AccessLevel',recordAccessLevel);
        // Set rowCause to 'manual' for manual sharing.
        // This line can be omitted as 'manual' is the default value for sharing objects.
        //sObj.put('RowCause',Schema.Loan_Application__Share.RowCause.Manual);
        
        if(isShareRecord){
            // Insert the sharing record and capture the save result.
            Database.SaveResult sr = Database.insert(sObj,false);
        }
        return sObj;
    }
     */
    
    
}