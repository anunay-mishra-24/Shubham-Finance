public without sharing class DisbursementMemoController {

    @AuraEnabled(cacheable=false)
    public static DisbursementWrapper getDisbursementData(String disbursementId) {
        DisbursementWrapper wrapper = new DisbursementWrapper();
        
        try {
            // Fetch current user details
            User u = [SELECT Name, EmployeeNumber FROM User WHERE Id = :UserInfo.getUserId()];
            wrapper.currentUserName = u.Name;
            wrapper.currentUserEmployeeNumber = u.EmployeeNumber;

            // 1. Fetch the Disbursement record directly by its Id
            wrapper.disbursement = [SELECT Id, Name, Disbursal_Date__c, Disbursal_Amount__c, 
                                          Disbursement_Bank__c, Status__c, Actual_Payment_Amount__c,
                                          Application__c,
                                          CreatedBy.Name, CreatedBy.EmployeeNumber
                                   FROM Disbursement__c 
                                   WHERE Id = :disbursementId 
                                   LIMIT 1];
            
            // Override current user with Disbursement creator
            wrapper.currentUserName = wrapper.disbursement.CreatedBy.Name;
            wrapper.currentUserEmployeeNumber = wrapper.disbursement.CreatedBy.EmployeeNumber;

            // Derive the Application Id from the Disbursement
            String applicationId = wrapper.disbursement.Application__c;

            // 2. Fetch Application Details using the derived applicationId
            wrapper.application = [SELECT Id, Name, Loan_Product__c, Sub_Product__c, Product__r.Name, Tenure__c, 
                                          Branch__r.Name, Processing_Fee_percent__c,
                                          (SELECT Id, Fee_Type__c, Amount__c, Status__c, Tax__c, Charge_Sub_Type__c FROM Fees__r WHERE Fee_Type__c != 'Login Fees') 
                                   FROM Application__c 
                                   WHERE Id = :applicationId 
                                   LIMIT 1];

            // 3. Fetch Existing Payee Details for this Disbursement
            wrapper.payeeDetails = [SELECT Id, Name, DisbursalAmount__c, TypeOfPaymentMode__c, Instrument_Number__c, 
                                           InFavourOf__c, Customer_Bank__c, BeneficiaryAccountNumber__c,
                                           Payment_Amount__c, Account_Number__c
                                    FROM Payee_Details__c 
                                    WHERE Disbursement__c = :disbursementId];
            
            // 4. Populate Fee Details
            if (wrapper.application.Fees__r != null) {
                wrapper.feeDetails = wrapper.application.Fees__r;
            } else {
                wrapper.feeDetails = new List<Fees__c>();
            }

            // 5. Fetch Primary Applicant
            List<Loan_Applicant__c> applicants = [SELECT Name FROM Loan_Applicant__c 
                                                  WHERE Application__c = :applicationId 
                                                  AND Applicant_Type__c = 'Primary Applicant' 
                                                  LIMIT 1];
            if (!applicants.isEmpty()) {
                wrapper.primaryApplicantName = applicants[0].Name;
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return wrapper;
    }

    @AuraEnabled
    public static void saveDisbursement(Disbursement__c disbursement, List<Payee_Details__c> payeeDetails, List<Fees__c> feeDetails) {
        try {
            upsert disbursement;
            
            for (Payee_Details__c pd : payeeDetails) {
                pd.Disbursement__c = disbursement.Id;
            }
            upsert payeeDetails;

            // Mark selected cheques as Consumed
            Set<Id> chequeIds = new Set<Id>();
            for (Payee_Details__c pd : payeeDetails) {
                if (pd.Instrument_Number__c != null) {
                    chequeIds.add(pd.Instrument_Number__c);
                }
            }
            if (!chequeIds.isEmpty()) {
                List<Cheque_Master__c> cheques = [SELECT Id, Status__c FROM Cheque_Master__c WHERE Id IN :chequeIds];
                for (Cheque_Master__c c : cheques) {
                    c.Status__c = 'Consumed';
                }
                update cheques;
            }

            if (feeDetails != null && !feeDetails.isEmpty()) {
                for (Fees__c fee : feeDetails) {
                    if (String.isBlank(fee.Application__c) && disbursement.Application__c != null) {
                        fee.Application__c = disbursement.Application__c;
                    }
                }
                upsert feeDetails;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void deletePayeeDetail(Id payeeDetailId) {
        try {
            Payee_Details__c pd = [SELECT Id, Instrument_Number__c FROM Payee_Details__c WHERE Id = :payeeDetailId LIMIT 1];
            Id chequeId = pd.Instrument_Number__c;
            delete pd;

            // Release the cheque back to Available
            if (chequeId != null) {
                Cheque_Master__c cheque = [SELECT Id, Status__c FROM Cheque_Master__c WHERE Id = :chequeId LIMIT 1];
                cheque.Status__c = 'Available';
                update cheque;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Cheque_Master__c> getChequeMasters(String branchName) {
        try {
            return [SELECT Id, Name, Status__c FROM Cheque_Master__c 
                    WHERE Hub_Region__c = :branchName AND Status__c = 'Available'];
        } catch (Exception e) {
            return new List<Cheque_Master__c>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Bank_Master__c> getBankMasters(Boolean isDealingBank) {
        try {
            if (isDealingBank) {
                return [SELECT Id, Name FROM Bank_Master__c WHERE RecordType.Name = 'Dealing Disbursement Bank Master' LIMIT 2000];
            } else {
                return [SELECT Id, Name FROM Bank_Master__c WHERE RecordType.Name != 'Dealing Disbursement Bank Master' LIMIT 2000];
            }
        } catch (Exception e) {
            return new List<Bank_Master__c>();
        }
    }

    public class DisbursementWrapper {
        @AuraEnabled public Application__c application;
        @AuraEnabled public Disbursement__c disbursement;
        @AuraEnabled public List<Payee_Details__c> payeeDetails;
        @AuraEnabled public List<Fees__c> feeDetails;
        @AuraEnabled public String primaryApplicantName;
        @AuraEnabled public Decimal processingFee;
        @AuraEnabled public String currentUserName;
        @AuraEnabled public String currentUserEmployeeNumber;
    }
}