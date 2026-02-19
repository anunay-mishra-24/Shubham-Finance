@isTest
private class SFDCAccessControlExceptionTest {

    @isTest
    static void doTest(){
        SFDCAccessControlException ex = new SFDCAccessControlException('This is test', SFDCAccessControlException.ExceptionType.GENERIC, 
                                                                       SFDCAccessControlException.ExceptionReason.GENERIC, 'TestObject', 'TestField');
        
        String message = ex.getMessage();
        System.assertEquals('This is test:: GENERIC access violation for TestObject.TestField', message);
    }
}