import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import FORM_FACTOR from '@salesforce/client/formFactor';
import RCU_VERIFICATION_APP_URL from '@salesforce/label/c.RCU_Verification_Bridge_App_URL';
import saveLocation from '@salesforce/apex/SHF_GeoTaggingController.saveLocation';

export default class SHF__GeoLoactionTaggingAction extends LightningElement {

    @api recordId;

    get isPhone() {
        return FORM_FACTOR === 'Small';
    }


    handleGeoLocation() {
        if (!navigator.geolocation) {
            this.showError(
                'Unable to capture location. Please allow location access.'
            );
            return;
        }

        navigator.geolocation.getCurrentPosition(
            (position) => {
                const latitude = position.coords.latitude.toString();
                const longitude = position.coords.longitude.toString();

                this.saveLocationDetails(latitude, longitude);
            },
            () => {
                this.showError(
                    'Unable to capture location. Please allow location access.'
                );
            },
            {
                enableHighAccuracy: true,
                timeout: 10000,
                maximumAge: 0
            }
        );
    }

    saveLocationDetails(latitude, longitude) {
        saveLocation({
            recordId: this.recordId,
            latitude: latitude,
            longitude: longitude
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Location tagged successfully',
                    variant: 'success'
                })
            );
            this.closeAction();

            setTimeout(() => {
    window.location.href = `/lightning/r/Verification_Activity__c/${this.recordId}/view`;
}, 200);

        })
        .catch(() => {
            this.showError('Unable to save location. Please try again.');
        });
    }

    /* ---------------- CAPTURE IMAGE need to work on this ---------------- */

    handleCaptureImage() {
        if (!this.recordId) {
        this.showError('Record Id not found.');
        return;
    }

    const url = `${RCU_VERIFICATION_APP_URL}${this.recordId}`;
        window.location.href = url;
    }


    showError(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error'
            })
        );
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}