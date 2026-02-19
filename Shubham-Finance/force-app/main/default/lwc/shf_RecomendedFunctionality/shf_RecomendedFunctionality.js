import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import USERNAME from '@salesforce/schema/User.Name';
import UserRoleName from '@salesforce/schema/User.UserRole.Name';
import validateBeforeStageChange from '@salesforce/apex/SHF_ApplicationMoveToNextController.validateBeforeStageChange';
import getUsersByRole from '@salesforce/apex/SHF_recomendedFuctionalityController.getUsersByRole';
import getQueueByName from '@salesforce/apex/SHF_recomendedFuctionalityController.getQueueIdByName';
import updateDeviation from '@salesforce/apex/SHF_recomendedFuctionalityController.updateDeviation';
import createActivityHistoryRecord from '@salesforce/apex/SHF_recomendedFuctionalityController.createActivityHistoryRecord';
import { NavigationMixin } from 'lightning/navigation';


const FIELDS = [
    'Application__c.Application_Stage__c',
    'Application__c.Recommended_Loan_Amount__c',
    'Application__c.Charges_Visible__c',
    'Application__c.OwnerId',
];

export default class Shf_RecomendedFunctionality extends NavigationMixin(LightningElement) {
    @api recordId;
    currentStage;
    showSpinner = false;
    @track isRecomendationModal = false;
    @track errorMessages = [];
    @track selectedUser;
    @track recomendation;
    @track isdependencePicklist = true;
    @track isLoading = false;
    @track showErrorModal = false;
    @track filteredOptions = [];
    @track currentUserRole;
    userName;
    formatted;
    actionName;
    @track recommendedLoanAmount;
    userLoaded = false;
    recordLoaded = false;
    userValue;
    isCommittee = false;
    queueId;
    curruntOwnerId;
    combinedValue;

    allRoles = [
        'Credit Head',
        'Zonal Manager',
        'Regional Manager',
        'State Head',
        'Area Credit Manager',
        'Branch Credit Manager',
        'Credit Manager/Officer'
    ];

    @track useOptions = [];

    @wire(CurrentPageReference)
    getAddressId(currentPageReference) {
        if (currentPageReference.state.recordId) {
            this.recordId = currentPageReference.state.recordId;
        } else if (currentPageReference.attributes.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }
        this.actionName = currentPageReference.attributes.apiName.split('.').pop();
        console.log('Clicked Action:', this.actionName);
        console.log('recordId-> ', this.recordId);
    }

    @wire(getRecord, { recordId: Id, fields: [ProfileName, UserRoleName, USERNAME] })
    userDetails({ error, data }) {
        console.log('Id>><>< ', Id);
        if (error) {
            this.error = error;
        } else if (data) {
            if (data.fields.UserRole.value != null && data.fields.UserRole.value != undefined) {
                this.currentUserRole = data.fields.UserRole.value.fields.Name.value;
            } if (data.fields.Name.value != null && data.fields.Name.value != undefined) {
                this.userName = data.fields.Name.value;
            }
            this.userLoaded = true;
            this.tryBuildRoles();
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        console.log(' this.recor ', this.recordId);
        this.isLoading = true;
        if (data) {
            this.recommendedLoanAmount = data.fields.Recommended_Loan_Amount__c.value;
            this.currentStage = data.fields.Application_Stage__c.value;
            this.curruntOwnerId = data.fields.OwnerId.value;
            console.log(' this.currentStage ', this.currentStage);
            this.recordLoaded = true;
            this.tryBuildRoles();
            this.stageMovementAndValidation();
        } else if (error) {
            console.error('Error fetching record: ', error);
            this.currentStage = null;
        }
    }

    tryBuildRoles() {
        if (this.userLoaded && this.recordLoaded) {
            this.getUpperHierarchyRoles(this.currentUserRole);
        }
    }

    getUpperHierarchyRoles(currentRole) {
        // Conditionally add Committee at the top
        const loanAmount = Number(this.recommendedLoanAmount || 0);
        if (loanAmount > 3000000) {
            this.filteredOptions = [{
                label: 'Committee',
                value: 'Committee'
            }];
            console.log('Filtered Roles (Committee Only):',
                JSON.stringify(this.filteredOptions));
        } else {
            let roles = [...this.allRoles]; // clone to avoid mutation
            console.log('roles:', JSON.stringify(roles));
            const currentIndex = roles.indexOf(currentRole);
            if (currentIndex > -1) {
                const upperRoles = roles.slice(0, currentIndex);
                this.filteredOptions = upperRoles.map(role => ({
                    label: role,
                    value: role
                }));
            } else {
                // fallback — role not found
                this.filteredOptions = roles.map(role => ({
                    label: role,
                    value: role
                }));
            }
            console.log('Filtered Roles:', JSON.stringify(this.filteredOptions));
        }

    }

    stageMovementAndValidation() {
        console.log(' this.currentStage ', this.currentStage);
        // this.showSpinner = true;
        if (this.currentStage === 'DDE' || this.currentStage === 'Credit Assessment') {
            console.log('')
            // Validate first before proceeding
            validateBeforeStageChange({
                applicationId: this.recordId,
                currentStage: this.currentStage,
                buttonLabel: this.actionName
            })
                .then(result => {
                    if (result) {
                        console.log('result>> ', result);
                        // Error message returned from Apex
                        this.isLoading = false;
                        this.showErrorModal = true;
                        // this.showToast('Error', result, 'error');
                        const cleanMsg = result;
                        this.errorMessages = cleanMsg
                            .split(/[\n;]+/)
                            .map((msg) => msg.trim())
                            .filter((msg) => msg);

                    } else {
                        // Validation passed
                        console.log('about to open the modal');
                        this.isLoading = false;
                        this.isRecomendationModal = true; // recomendation part start from here , after passing all the validation.
                    }
                })
                .catch(error => {
                    this.showToast('Error', error.body?.message || 'Validation failed.', 'error');
                    this.dispatchEvent(new CloseActionScreenEvent());
                });
        }
        else {
           // this.showToast('Info', `Cannot move stage from ${this.currentStage}`, 'info');
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }
    //added by mansur alam

    handleChange(event) {
        const fieldName = event.target.name;
        const fieldValue = event.detail.value;

        if (fieldName === 'Authority') {
            if (fieldValue === 'Committee') {
                this.userValue = 'Committee';
                this.useOptions = [
                    { label: 'Committee', value: 'Committee' }
                ];
                this.isdependencePicklist = true;
                this.isCommittee = true;
                //fetching Committee Queue using this apex method
                this.getQueue('Committee Queue');
            } else {
                this.userValue = null;
                this.useOptions = [];
                this.isdependencePicklist = false;
                this.getUsers(fieldValue);
            }
        }
        else if (fieldName === 'User') {
            this.selectedUser = fieldValue;
        }
        else if (fieldName === 'Recommendation') {
            this.recomendation = fieldValue;
            //getting current day and time
            this.formatted = new Intl.DateTimeFormat('en-IN', {
                dateStyle: 'full',
                timeStyle: 'short'
            }).format(new Date());

            console.log('formatted ', this.formatted);
        }
    }

    async getUsers(selectedRole) {
        try {
            const users = await getUsersByRole({ roleName: selectedRole, applicationId: this.recordId });
            console.log('User :', users);
            if (users && users.length > 0) {
                // this.userName = users[0].Name;
                console.log('User Name:', this.userName);

                this.useOptions = users.map(u => ({
                    label: u.Name,
                    value: u.Id
                }));
            }
        } catch (error) {
            console.error('Error fetching users: ', error);
            this.useOptions = [];
        }
    }

    async getQueue(queueName) {
        try {
            const queue = await getQueueByName({ queueName: queueName });
            console.log('queue :', queue);
            if (queue && queue.length > 0) {
                this.selectedUser = queue;
                console.log(' this.queueId ++++ ', this.queueId);
            }
        } catch (error) {
            console.error('Error fetching Queue: ', error);
        }
    }

    handleSubmit() {
        this.isLoading = true;
        // Query all input elements inside this template
        const allInputs = this.template.querySelectorAll(
            'lightning-combobox, lightning-textarea, lightning-input'
        );
        let isValid = true;

        allInputs.forEach(input => {
            // Check each field validity
            if (!input.checkValidity()) {
                input.reportValidity(); // shows red message
                isValid = false;
            }
        });

        if (!isValid) {
            // If validation fails, stop execution
            this.showToast('Error', 'Please fill all required fields before proceeding.', 'error');
            this.isLoading = false;
            return;
        }
        //  All fields have values going for update
        this.handleUpdateDeviation();
    }

    handleUpdateDeviation() {
        updateDeviation({ applicationId: this.recordId })
            .then(result => {
                console.log('Apex Response:', result);
                if (result.startsWith('ERROR')) {
                    this.showToast('Error', result, 'error');
                } else {
                    if (this.currentStage == 'Credit Assessment' || this.currentStage == 'Credit Sanction') {
                        this.updateStage('Credit Sanction', true, true);
                    }
                    else {
                        this.updateStage('Credit Assessment', true, true);
                    }

                }
            })
            .catch(error => {
                console.error('Apex Error:', error);
                this.showToast('Apex Exception', error.body.message, 'error');
            })
    }

    updateStage(nextStage, isRecomended, setChargesVisible = true) {
        console.log('isRecomended ', isRecomended);
        const fields = {
            Id: this.recordId,
            Application_Stage__c: nextStage
        };
        if (isRecomended === true) {
            console.log('this.selectedUser >>>>> ', this.selectedUser);
            fields.Application_Status__c = 'Recommended';
            fields.OwnerId = this.selectedUser;
            console.log(' fields.OwnerId  >>>>> ', fields.OwnerId);
            this.combinedValue = `${this.userName} , ${this.formatted}
Comment:  ${this.recomendation}`;
            console.log('combinedValue>> ', this.combinedValue);
            fields.Recomendation_comment__c = this.combinedValue;
        }

        if (setChargesVisible === true) {
            // set the flag so the Charges tab will render the items
            fields.Charges_Visible__c = true;
        }
        if (this.isCommittee) {
            fields.Previous_Credit_User__c = this.curruntOwnerId;
            fields.Final_Committee_Approval_Status__c = 'Pending';
            this.createApprovalTaskForCommittee();
        }

        updateRecord({ fields })
            .then(() => {
                this.isLoading = false;
                this.isRecomendationModal = false;
                this.showToast('Success', `Application is recommended successfully.`, 'success');

                // Close the modal
                this.dispatchEvent(new CloseActionScreenEvent());

                // Refresh the record page (does NOT reopen modal)
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                console.error(' Update error object:', JSON.stringify(error, null, 2));
                const message =
                    error?.body?.output?.errors?.[0]?.message ||
                    error?.body?.message ||
                    "Unknown error";
                this.isLoading = false;
                this.showToast('Error', message, 'error');
            });
    }

    createApprovalTaskForCommittee() {
        createActivityHistoryRecord({ applicationId: this.recordId, recomendationComment: this.combinedValue })
            .then(result => {
                if (result.startsWith('ERROR')) {
                    console.log('error in approval taks creation');
                } else if (result.startsWith('SUCCESS')) {
                    console.log('Approval task created successfully');
                }

            }).catch(error => {

            })

    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    closeModal() {
        this.isRecomendationModal = false;
        this.showErrorModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}