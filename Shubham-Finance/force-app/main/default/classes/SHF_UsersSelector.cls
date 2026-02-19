/**
* @File Name          : SHF_UsersSelector.cls
* @Description        : This class is used to fetch/query User records based on conditions.
* @Author             : Riteek Tiwari
* @Test Class         : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         01-07-2025              Riteek Tiwari          
*/
public class SHF_UsersSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ 
            User.Id,
                User.Name,
                User.MobilePhone,
                User.Phone,
                User.Email,
                User.UserName,
                User.ProfileId,
                User.IsActive,
                User.ManagerId
                }; 
                    }
    
    public Schema.SObjectType getSObjectType() { 
        return User.SObjectType; 
    }
    
    public User selectUserWithPhone(string phone) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Phone = :phone AND Phone != null');
        List<User> users = (List<User>) Database.query(query.toSOQL());
        return users.isEmpty() ? null : users[0];
    }
    
    // Fetch users by Ids and return Name field (you can add more as needed)
    public List<User> selectByIdsUserName(Set<Id> userIds) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Name');
        query.selectField('ManagerId');
        query.selectField('UserRole.name');
        query.selectField('Profile.name');
        query.selectField('Manager.name');
        query.setCondition('Id IN :userIds');
        return (List<User>) Database.query(query.toSOQL());
    }
    // get user on the basis of Userrole
    public List<User> selectByRoleNameName(String userRoleName) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Name');
        query.selectField('ManagerId');
        query.selectField('UserRole.name');
        query.selectField('Profile.name');
        query.selectField('Manager.name');
        query.setCondition('UserRole.Name = :userRoleName');
        return (List<User>) Database.query(query.toSOQL());
    }
    
    // Example: Select first active user with specific profile
    public List<User> selectActiveUsersByProfile(Set<Id> profileIds) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('UserRole.name');
        query.selectField('Profile.name');
        query.selectField('Manager.name');
        query.setCondition('ProfileId IN :profileIds AND IsActive = true');
        query.setLimit(1); // Optional: limit result
        return (List<User>) Database.query(query.toSOQL());
    }
    
    // Example: Select first active user with Sales profile
    
    public List<User> selectActiveSalesUsers(String profileName){
        String query = newQueryFactory()
            .selectField('ManagerId')
            .selectField('Manager.Email')
            .selectField('UserRole.name')
            .setCondition('IsActive = true AND ManagerId != null AND Profile.Name =: profileName')
            .toSOQL();
        return (List<User>) Database.query(query);
    }
    //  Select active Customer Service Profile users
    public List<User> selectActiveCustomerServiceUsers(String profileName) {
        String query = newQueryFactory()
            .selectField('ManagerId')
            .selectField('Manager.Name')
            .selectField('Manager.Email')
            .selectField('Manager.MobilePhone')
            .selectField('Manager.Phone')
            .selectField('Email')
            .selectField('MobilePhone')
            .selectField('Phone')
            .selectField('Name')
            .selectField('UserRole.DeveloperName')
            .setCondition('Profile.Name =: profileName AND IsActive = true')
            .toSOQL();
        return (List<User>) Database.query(query);
    }
    //  select active users for multiple profiles SHF-306
public List<User> selectActiveCustomerServiceUsers(Set<String> profileNames) {
    if (profileNames == null || profileNames.isEmpty()) {
        return new List<User>();
    }

    String query = newQueryFactory()
        .selectField('ManagerId')
        .selectField('Manager.Name')
        .selectField('Manager.Email')
        .selectField('Manager.MobilePhone')
        .selectField('Manager.Phone')
        .selectField('Email')
        .selectField('MobilePhone')
        .selectField('Phone')
        .selectField('Name')
        .selectField('UserRole.DeveloperName')
        .setCondition('Profile.Name IN :profileNames AND IsActive = true')
        .toSOQL();
    return (List<User>) Database.query(query);
}
    
     // Fetch users by Ids and return Name field (you can add more as needed)
    public List<User> selectManagerByUserId(Set<Id> userIds) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectField('Name');
        query.selectField('Manager.Name');
        query.selectField('Manager.Email');
        query.selectField('Manager.MobilePhone');
        query.selectField('Manager.Manager.Name');
        query.selectField('Manager.Manager.Email');
        query.selectField('Manager.Manager.MobilePhone');
        query.selectField('Manager.Manager.Manager.Name');
        query.selectField('Manager.Manager.Manager.Email');
        query.selectField('Manager.Manager.Manager.MobilePhone');
         query.selectField('ManagerId');
         query.selectField('Manager.ManagerId');
         query.selectField('Manager.Manager.ManagerId');
        query.selectField('Manager.Manager.Manager.Manager.ManagerId');
         query.selectField('Manager.Manager.Manager.Manager.Manager.ManagerId');
         query.selectField('Manager.Manager.Manager.Manager.Manager.Manager.ManagerId');
        query.setCondition('Id IN :userIds');
        return (List<User>) Database.query(query.toSOQL());
    }
}