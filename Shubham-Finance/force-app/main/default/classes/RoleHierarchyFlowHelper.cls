public with sharing class RoleHierarchyFlowHelper {

    @InvocableMethod(label='Get Users Above RCU/FCU Manager')
    public static List<List<User>> getUsersAboveRole(List<String> roleNames) {

        String roleName = roleNames[0];

        UserRole baseRole = [
            SELECT Id, ParentRoleId
            FROM UserRole
            WHERE Name = :roleName
            LIMIT 1
        ];

        Map<Id, UserRole> roleMap = new Map<Id, UserRole>(
            [SELECT Id, ParentRoleId FROM UserRole]
        );

        Set<Id> higherRoleIds = new Set<Id>();
        Id currentRoleId = baseRole.Id;

        while (roleMap.containsKey(currentRoleId)) {
            Id parentId = roleMap.get(currentRoleId).ParentRoleId;
            if (parentId == null) break;

            higherRoleIds.add(parentId);
            currentRoleId = parentId;
        }

        List<User> users = [
            SELECT Id, Name, Email, UserRole.Name
            FROM User
            WHERE UserRoleId IN :higherRoleIds
              AND IsActive = true
        ];

        // Flow receives ONLY this User list
        return new List<List<User>>{ users };
    }
}