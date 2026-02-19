/**
 * @File Name : SHF_ReciptStatusParser.cls
 * @Description :
 * @Author : Vikas Soni
 * @Last Modified By :
 * @Last Modified On : Jan 21, 2026
 * @Modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | Jan 21, 2026 |   | Initial Version
 **/
public with sharing class SHF_ReciptStatusParser {
    public cls_success[] success;
    public cls_error[] error;
	public class cls_error {
		public String i18nCode;	//msg.00001791
		public List<String> messageArguments;
		public String type;	//ERROR
		public boolean isParent;
		public String value;	//msg.00001791 : Atleast one of the search criteria is required - receiptId / applicationId / fileNumber / loanId.
	}
	public class cls_success {
		public String requestHeader;
		public Integer id;	//12028544
		public String transactionDate;
		public String receiptPayOutType;
		public String receiptPayOutMode;
		public String paymentSubMode;
		public String loanId;
		public String paymentBatchId;
		public String accountNumber;
		public String productId;
		public String bpTypeId;
		public String businessPartnerId;
		public String currencyCode;
		public String transactionCurrencyCode;
		public String loanBranch;
		public String transactionBranch;
		public String instrumentReferenceNumber;
		public String instrumentDate;
		public Integer receiptOrPayoutAmount;	//100
		public String drawnOn;
		public String transactionValueDate;
		public String status;	//R
		public String autoAllocation;
		public String manuallyAllocated;
		public String finalAllocationDone;
		public String reversalAllowed;
		public String receiptNo;	//EB6792
		public String receiptPayoutChannel;
		public String receiptPurpose;
		public String holdDate;
		public String unholdDate;
		public String bounceCancelReasonCode;
		public String bounceCancelReasonId;
		public String payInSlipReference;
		public String beneficiaryAccountType;
		public String beneficiaryAccountNumber;
		public String sourceAccountNumber;
		public String clearingHouseId;
		public String makeAuthorizeStatus;	//N
		public String bulkClearanceAmount;
		public String pmdFlag;
		public String allocationLevel;
		public String actionDate;
		public String cityId;
		public String bankId;
		public String bankBranchId;
		public String micrCode;
		public String micrNonMICR;
		public String bulkClearanceReference;
		public String bulkClearanceReferenceDate;
		public String rejectCancelDeleteIndicator;
		public String transactionReferenceId;
		public String stage;
		public String receiptAgainst;
		public String fileNumber;
		public String applicationId;
		public String drawerName;
		public String statusDescription;	//Entered
		public String creditDebitCard;
		public String cardApprovalReferenceNumber;
		public String allocationBreakUpDetails;
	}
	public static SHF_ReciptStatusParser parse(String json){
		return (SHF_ReciptStatusParser) System.JSON.deserialize(json, SHF_ReciptStatusParser.class);
	}

    public SHF_ReciptStatusParser() {
        success = null;

    }

}