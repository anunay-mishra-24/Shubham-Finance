/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SHF_HRMS_UserSync
 * Author          : Pankaj Anand
 * Created Date    : Feb 9, 2026
 * Last Modified By: Pankaj Anand
 * Last Modified On: Feb 9, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Feb 9, 2026  │ Pankaj Anand  │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class SHF_HRMS_UserSync implements Schedulable, Database.Batchable<Object>, Database.AllowsCallouts {
    
    public void execute(SchedulableContext sc) {
        SHF_HRMS_UserSync batch = new SHF_HRMS_UserSync();
        Database.executeBatch(batch, 200);
    }
    
    public Iterable<Object> start(Database.BatchableContext bc) {
        List<Object> hrmsUserList = new List<Object>();
        
        try {

            List<Object> activeEmployees = SHF_HRMS_API.getActiveEmployeeList();
            if (activeEmployees != null && !activeEmployees.isEmpty()) {
                hrmsUserList.addAll(activeEmployees);
            }
            
            List<Object> inactiveEmployees = SHF_HRMS_API.getInactiveEmployeeList();
            if (inactiveEmployees != null && !inactiveEmployees.isEmpty()) {
                hrmsUserList.addAll(inactiveEmployees);
            }
                        
        } catch (Exception e) {
            System.debug('Exception StackTrace: ' + e.getStackTraceString());
        }         
        return hrmsUserList;
    }
    
    public void execute(Database.BatchableContext bc, List<Object> scope) {
        try {            
            List<User> usersToUpdate = new List<User>();
            List<User> usersToInsert = new List<User>();
            
            Set<String> employeeIds = new Set<String>();
            for (Object obj : scope) {
                Map<String, Object> hrmsUser = (Map<String, Object>) obj;
                String empId = String.valueOf(hrmsUser.get('employee_id'));
                if (String.isNotBlank(empId) && empId != 'null') {
                    employeeIds.add(empId);
                }
            }
                        
            Map<String, User> existingUsersMap = new Map<String, User>();
            for (User usr : [SELECT Id, EmployeeNumber, IsActive, FirstName, LastName, Email, 
                            Username, ProfileId, UserRoleId, Department, Title
                            FROM User 
                            WHERE EmployeeNumber IN :employeeIds]) {
                existingUsersMap.put(usr.EmployeeNumber, usr);
            }
                        
            for (Object obj : scope) {
                Map<String, Object> hrmsUser = (Map<String, Object>) obj;
                String empId = String.valueOf(hrmsUser.get('employee_id'));
                String employeeStatus = String.valueOf(hrmsUser.get('employee_status'));
                
                Boolean shouldBeActive = (employeeStatus != null && employeeStatus.equalsIgnoreCase('Active'));
                
                if (String.isBlank(empId) || empId == 'null') {
                    continue;
                }
                
                User existingUser = existingUsersMap.get(empId);
                
                if (existingUser == null) {
                    User newUser = createUserFromHRMS(hrmsUser);
                    if (newUser != null) {
                        usersToInsert.add(newUser);
                    }
                } else {
                    if (shouldBeActive && !existingUser.IsActive) {
                        existingUser.IsActive = true;
                        usersToUpdate.add(existingUser);
                    } else if (!shouldBeActive && existingUser.IsActive) {
                        existingUser.IsActive = false;
                        usersToUpdate.add(existingUser);
                    } else {
						continue;
                    }
                }
            }
            
            if (!usersToInsert.isEmpty()) {
                List<Database.SaveResult> insertResults = Database.insert(usersToInsert, false);
                System.debug('insertResults-->'+ insertResults);
            }
            
            if (!usersToUpdate.isEmpty()) {
                List<Database.SaveResult> updateResults = Database.update(usersToUpdate, false);
				System.debug('updateResults-->'+ updateResults);
            }
            
        } catch (Exception e) {
            System.debug('Exception StackTrace: ' + e.getStackTraceString());
        }
    }
    
    public void finish(Database.BatchableContext bc) {

        System.debug('User Syncing Completed...');
    }
    
    private User createUserFromHRMS(Map<String, Object> hrmsUser) {
        try {
            List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            
            if (profiles.isEmpty()) {
                return null;
            }
            
            Id defaultProfileId = profiles[0].Id;
            
            String firstName = String.valueOf(hrmsUser.get('first_name'));
            String lastName = String.valueOf(hrmsUser.get('last_name'));
            String email = String.valueOf(hrmsUser.get('company_email_id'));
            String empId = String.valueOf(hrmsUser.get('employee_id'));
            String department = String.valueOf(hrmsUser.get('department_name'));
            String designation = String.valueOf(hrmsUser.get('designation'));
            String employeeStatus = String.valueOf(hrmsUser.get('employee_status'));
            
            Boolean isActive = (employeeStatus != null && employeeStatus.equalsIgnoreCase('Active'));
            
            if (String.isBlank(firstName) || String.isBlank(lastName)) {
                return null;
            }
            
            if (String.isBlank(email) || email == 'null') {
                return null;
            }
            
            String username = email;
            
            User newUser = new User();
            newUser.EmployeeNumber = empId;
            newUser.FirstName = firstName;
            newUser.LastName = lastName;
            newUser.Email = email;
            newUser.Username = username;
            newUser.Alias = generateAlias(firstName, lastName);
            newUser.TimeZoneSidKey = 'Asia/Kolkata';
            newUser.LocaleSidKey = 'en_IN';
            newUser.EmailEncodingKey = 'UTF-8';
            newUser.LanguageLocaleKey = 'en_US';
            newUser.ProfileId = defaultProfileId;
            newUser.IsActive = isActive;
            
            if (String.isNotBlank(department) && department != 'null') {
                newUser.Department = department;
            }
            
            if (String.isNotBlank(designation) && designation != 'null') {
                newUser.Title = designation;
            }
            
            String mobileNo = String.valueOf(hrmsUser.get('personal_mobile_no'));
            if (String.isNotBlank(mobileNo) && mobileNo != 'null') {
                newUser.MobilePhone = mobileNo;
            }
            
            return newUser;
            
        } catch (Exception e) {
            System.debug('Exception StackTrace: ' + e.getStackTraceString());
            return null;
        }
    }
    
    private String generateAlias(String firstName, String lastName) {
        String alias = '';
        
        if (String.isNotBlank(firstName) && firstName.length() > 0) {
            alias += firstName.substring(0, 1);
        }
        
        if (String.isNotBlank(lastName)) {
            Integer lastNameLength = lastName.length() > 4 ? 4 : lastName.length();
            alias += lastName.substring(0, lastNameLength);
        }
        
        if (String.isBlank(alias)) {
            alias = 'user' + String.valueOf(Math.random()).substring(2, 6);
        }
        
        alias = alias.toLowerCase();
        return alias.length() > 8 ? alias.substring(0, 8) : alias;
    }
    
}