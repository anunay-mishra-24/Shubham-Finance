@IsTest
private class SHF_recomendedFuctionalityControllerTest {

    @TestSetup
    static void setupData() {
    
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        SHF_TestDataFactory.createUser('Alice', 'Sales', 'alice.sales@test.com', null, p.Id, true, null, null, true);
        SHF_TestDataFactory.createUser('Bob', 'Sales', 'bob.sales@test.com', null, p.Id, true, null, null, true);
        SHF_TestDataFactory.createUser('Carol', 'Support', 'carol.support@test.com', null, p.Id, true, null, null, true);

        UserRole salesMgrRole = new UserRole(DeveloperName = 'Sales_Manager', Name = 'Sales Manager');
        UserRole supportMgrRole = new UserRole(DeveloperName = 'Support_Manager', Name = 'Support Manager');
        insert new List<UserRole>{ salesMgrRole, supportMgrRole };

        List<User> created = [SELECT Id, LastName FROM User WHERE LastName IN ('Sales','Support') ORDER BY LastName, CreatedDate LIMIT 3];
        for (User u : created) {
            if (u.LastName == 'Sales') {
                u.UserRoleId = salesMgrRole.Id;
            } else if (u.LastName == 'Support') {
                u.UserRoleId = supportMgrRole.Id;
            }
        }
        update created;
    }

    @IsTest
    static void testGetUsersByRole_positive() {

        String roleName = [SELECT Name FROM UserRole WHERE Name = 'Sales Manager' LIMIT 1].Name;

        Test.startTest();
        List<User> result = SHF_recomendedFuctionalityController.getUsersByRole(roleName);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should return 2 users for Sales Manager role');
        System.assert(result[0].Name <= result[1].Name, 'Users should be ordered by Name');
    }

    @IsTest
    static void testGetUsersByRole_blankRole() {

        Test.startTest();
        List<User> resultNull = SHF_recomendedFuctionalityController.getUsersByRole(null);
        List<User> resultEmpty = SHF_recomendedFuctionalityController.getUsersByRole('');
        List<User> resultSpaces = SHF_recomendedFuctionalityController.getUsersByRole('   ');
        Test.stopTest();

        System.assertEquals(0, resultNull.size(), 'Null role should return empty list');
        System.assertEquals(0, resultEmpty.size(), 'Empty role should return empty list');
        System.assertEquals(0, resultSpaces.size(), 'Whitespace role should return empty list');
    }


    @IsTest
    static void testGetUsersByRole_nonExistingRole() {

        Test.startTest();
        List<User> result = SHF_recomendedFuctionalityController.getUsersByRole('Non Existing Role ' + System.now().getTime());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Unknown role should return empty list');
    }
}