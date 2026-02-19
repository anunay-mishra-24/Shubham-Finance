import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import FORM_FACTOR from '@salesforce/client/formFactor';
import saveLocation from '@salesforce/apex/SHF_GeoTaggingController.saveLocation';

export default class TagMyLocation extends LightningElement {

    @api recordId;

    // Show Capture Image only on Phone
    get isPhone() {
        return FORM_FACTOR === 'Small';
    }

    /* ---------------- TAG GEO LOCATION ---------------- */

    handleGeoLocation() {
        if (!navigator.geolocation) {
            this.showError(
                'Location or GPS is not enabled. Please enable it and try again.'
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
                    'Location or GPS is not enabled. Please enable it and try again.'
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
        })
        .catch(() => {
            this.showError('Unable to save location. Please try again.');
        });
    }

    /* ---------------- CAPTURE IMAGE ---------------- */

    handleCaptureImage() {
        const docName = 'Verification_Document';

        const url = `shubhamshf://imagecapture?recordId=${this.recordId}&docName=${docName}`;
        window.location.href = url;
    }

    /* ---------------- COMMON ---------------- */

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