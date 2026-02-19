/**
 * @File Name  : SHF_AccountSelector.cls
 * @Description: Selector for Account object following fflib_SObjectSelector pattern
 * @Author     : Akshi
 * @Date       : September 29, 2025
 */
public with sharing class SHF_AccountSelector extends fflib_SObjectSelector {

    /**
     * Defines fields to be queried whenever Account is retrieved
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Account.Id,
            Account.Name,
            Account.FirstName,         // for Person Accounts
            Account.LastName,          // for Person Accounts
            Account.Phone,
            Account.Email_id__c,
            Account.PAN_Number__c,
            Account.Date_of_Birth__c,
            Account.Primary_Mobile_Number__c,
            Account.Type,
            Account.RecordTypeId,
            Account.CreatedDate,
            Account.Customer_Type__c

        };
    }

    /**
     * Returns the sObjectType this selector works on
     */
    public Schema.SObjectType getSObjectType() {
        return Account.sObjectType;
    }

    /**
     * Select Account by Id(s)
     */
    public List<Account> selectByIds(Set<Id> accountIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Id IN :accountIds');
        return (List<Account>) Database.query(query.toSOQL());
    }

    /**
     * Find Account by PAN
     */
    public List<Account> selectByPAN(String pan) {
        if (String.isBlank(pan)) return new List<Account>();
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('PAN_Number__c = :pan');
        return (List<Account>) Database.query(query.toSOQL());
    }

    /**
     * Find Account by Phone
     */
    public List<Account> selectByPhone(String phone) {
        if (String.isBlank(phone)) return new List<Account>();
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Phone = :phone');
        return (List<Account>) Database.query(query.toSOQL());
    }

    /**
     * Find Account by multiple conditions (PAN, Phone, DOB)
     */
//     public List<Account> selectByCriteria(String phone, String pan, Date dob, Id applicationId) {
//     fflib_QueryFactory query = newQueryFactory();

//     // Create a list to hold all conditions
//     List<String> conditions = new List<String>();

//     if (!String.isBlank(phone)) {
//         conditions.add('Phone = :phone');
//     }
//     else if (!String.isBlank(pan)) {
//         conditions.add('PAN_Number__c = :pan');
//     }
//     else if (dob != null) {
//         conditions.add('Date_of_Birth__c = :dob');
//     }
//     if (applicationId != null) {
//         conditions.add(
//             'Id NOT IN (' +
//                 'SELECT Account__c FROM Loan_Applicant__c ' +
//                 'WHERE Application__c = \'' + String.escapeSingleQuotes(applicationId) + '\' ' +
//                 'AND Account__c != NULL ' +
//                 'AND IsDeleted__c = false' +
//             ')'
//         );
//     }

//     // Join all conditions with AND and set it once
//     if (!conditions.isEmpty()) {
//         String finalCondition = String.join(conditions, ' AND ');
//         query.setCondition(finalCondition);
//     }

//     return (List<Account>) Database.query(query.toSOQL());
// }


    public List<Account> selectByCriteria(String phone, String pan, Date dob, Id applicationId) {
    fflib_QueryFactory query = newQueryFactory();

    List<String> orConditions = new List<String>();
    if (!String.isBlank(phone)) {
        orConditions.add('Phone = :phone');
    }
    if (!String.isBlank(pan)) {
        orConditions.add('PAN_Number__c = :pan');
    }
    if (dob != null) {
        orConditions.add('Date_of_Birth__c = :dob');
    }

    List<String> andConditions = new List<String>();
    if (!orConditions.isEmpty()) {
        andConditions.add('(' + String.join(orConditions, ' OR ') + ')');
    }
    if (applicationId != null) {
        andConditions.add(
            'Id NOT IN (' +
                'SELECT Account__c FROM Loan_Applicant__c ' +
                'WHERE Application__c = \'' + String.escapeSingleQuotes(applicationId) + '\' ' +
                'AND Account__c != NULL ' +
                'AND IsDeleted__c = false' +
            ')'
        );
    }

    if (!andConditions.isEmpty()) {
        String finalCondition = String.join(andConditions, ' AND ');
        query.setCondition(finalCondition);
    }

    return (List<Account>) Database.query(query.toSOQL());
}


}