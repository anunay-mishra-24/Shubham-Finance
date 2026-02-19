import { LightningElement, api,wire } from 'lwc';
import updateAddressLocation from '@salesforce/apex/SHF_landmarksController.updateAddressLocation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

export default class Shf_LocationService extends LightningElement {
    @api recordId; // Must be set by the parent record page or component context

    latitude;
    longitude;
    locationSet = false;

 @wire(CurrentPageReference)
    getAddressId(currentPageReference) {
        if (currentPageReference.state.recordId) {
            this.recordId = currentPageReference.state.recordId;
        } else if (currentPageReference.attributes.recordId) {
            this.recordId = currentPageReference.attributes.recordId;
        }
        console.log('recordId-> ', this.recordId);
    }
    handleGetLocation() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    this.locationSet = true;
                    this.updateRecordLocation();
                },
                (error) => {
                    this.showToast('Error', 'Unable to fetch location: ' + error.message, 'error');
                },
                {
                    enableHighAccuracy: true,
                    timeout: 10000,
                    maximumAge: 0
                }
            );
        } else {
            this.showToast('Error', 'Geolocation is not supported by this browser.', 'error');
        }
    }

    updateRecordLocation() {
        console.log('ooo ', this.recordId);
        updateAddressLocation({
            recordId: this.recordId,
            latitude: this.latitude,
            longitude: this.longitude
        })
        .then((data, error) => {
            if(data){
            console.log('data>?> ', data);
            this.showToast('Success', 'Location updated successfully!', 'success');
            }if(error){
                 console.log('error>?> ', error);
            }
        })
        .catch((error) => {
            this.showToast('Error', 'Failed to update record: ' + error.body.message, 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}