import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import returnRelatedRecords from '@salesforce/apex/SHF_SellerInfoDynamicListCtrl.returnRelatedRecords';

export default class Shf_SellerInfoDynamicTable extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api metadataName;
    @api userQuery;
    @api title;
    @api queryParameters;
    @track rowAction = [];
    showSpinner = false

    connectedCallback() {
        this.getRelatedRecords();
        console.log('recordId', this.recordId);
    }
    
    @api getRelatedRecords() {
        this.relatedRecords = undefined;
        console.log('recordId', this.recordId);
        console.log('metadataName', this.metadataName);
        console.log('userQuery', this.userQuery);
        console.log('queryParameters', this.queryParameters);
        if(this.queryParameters == undefined){
            this.queryParameters = '';
        }
        console.log('queryParameters', this.queryParameters);

        returnRelatedRecords({ verificationId: this.recordId, metadataName: this.metadataName, query: this.userQuery /*'Lead__c IN : IDS_SET'*/, queryParameters: this.queryParameters })
            .then((result) => {
                this.showSpinner = false;
                this.relatedRecords = JSON.parse(JSON.stringify(result));

                console.log('Results++ ', JSON.stringify(this.relatedRecords));
                this.objectAPIName = result.objectAPIName;
                this.title = result.label;
            }).catch((err) => {
                this.showSpinner = false;
                console.log('Error in returnRelatedRecords = ', err);
            });
    }

    
    // handleTableSelection(){
    //     console.log('handleTableSelection');
    // }
    // handleRowSelection(){
    //     console.log('handleRowSelection');
    // }
}