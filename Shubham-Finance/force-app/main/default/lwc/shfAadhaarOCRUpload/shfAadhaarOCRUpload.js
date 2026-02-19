import { LightningElement, api, track } from 'lwc';
import logDMSCall from '@salesforce/apex/SHF_DMSLogger.logDMSCall';

function serializeFormData(fd) {
    const obj = {};
    for (let [key, value] of fd.entries()) {
        if (key === 'document' && typeof value === 'string') {
            obj[key] = value.substring(0, 100) + '... [truncated]';
        } else if (key === 'token' && typeof value === 'string') {
            obj[key] = value.substring(0, 10) + '... [truncated]';
        } else if(key === 'frontUrl' && typeof value === 'string') {
            obj[key] = value.substring(0, 10) + '... [truncated]';
        }else {
            obj[key] = value;
        }
    }
    return obj;
}

export default class ShfAadhaarOCRUpload extends LightningElement {
    @track showSpinner = false;
    @track frontURL = 'data:image/png;base64,JVBERi0xLjUKJYCBgoMKMSAwIG9iago8PC9GaWx0ZXIvRmxhdGVEZWNvZGUvRmlyc3QgMTQxL04gMjAvTGVuZ3==';
    @api handleCallApi() {
        this.callAadhharOCR();
        // this.handleApiCall();
    }
    handleApiCall() {
        const url = 'https://cors-anywhere.herokuapp.com/https://api-preproduction.signzy.app/api/v3/studio/691ffac7700f4724f6f84cb8/id-extraction';
        const token = 'Adv24oFm2KUowYdYKGh9Tlmp7JwKGVMs';

        const xhr = new XMLHttpRequest();

        xhr.open('POST', url, true);

        // Required headers
        xhr.setRequestHeader('Content-Type', 'application/json');
        xhr.setRequestHeader('Authorization', token);

        xhr.onload = () => {
            console.log("Response:", xhr.responseText);

            // This is where X-CORS-Redirect headers will show (if redirect happened)
            console.log("Request URL:", xhr.getResponseHeader("X-Request-URL"));
            console.log("Final URL:", xhr.getResponseHeader("X-Final-URL"));
            console.log("Redirect 1:", xhr.getResponseHeader("X-CORS-Redirect-1"));
            console.log("Redirect 2:", xhr.getResponseHeader("X-CORS-Redirect-2"));
        };
        // Optional timeout
        xhr.timeout = 20000; // 20 seconds

        // Listen for response
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log('Status:', xhr.status);
                console.log('Response:', xhr.responseText);

                if (xhr.status === 200) {
                    // Success
                    const response = JSON.parse(xhr.responseText);
                    console.log('API Success:', response);
                } else {
                    console.error('API Error:', xhr.responseText);
                }
            }
        };

        // Handle timeout
        xhr.ontimeout = () => {
            console.error('API Timeout');
        };

        // Error handler (CORS will trigger this)
        xhr.onerror = (err) => {
            console.error('XHR Network Error:', err);
        };

        // Send Request Body
        const requestBody = {
            /* your body data */
        };

        xhr.send(JSON.stringify({
            frontUrl: this.frontURL}));
    }

    async callAadhharOCR() {
        let formData;
        try {
            console.log('insdie call aadhaar ocr ');

            formData = new FormData();
            formData.append('frontUrl', this.frontURL);
            // formData.append('Authorization', 'Adv24oFm2KUowYdYKGh9Tlmp7JwKGVMs');
            // console.log('formData:', formData);

            const serialized = serializeFormData(formData);
            console.log('Request payload (safe):', serialized);

            await logDMSCall({
                requestBody: JSON.stringify(serialized),
                responseBody: null,
                statusCode: null,
                isError: false
            });
            console.log(' Uploading to DMS...');
            const response = await fetch('https://api-preproduction.signzy.app/api/v3/studio/691ffac7700f4724f6f84cb8/id-extraction', {
                method: 'POST',
                headers: {
                    'Content-type': 'application/json',
                    'Authorization': 'Adv24oFm2KUowYdYKGh9Tlmp7JwKGVMs'
                },
                body: formData
            });
            console.log(' Response 2 :', response);
            const status = response.status;
            const success = response.ok;


            let responseText = '';
            try {
                responseText = await response.text();
            } catch (e) {
                responseText = '[no response body]';
            }

            // Log response
            console.log(' Response Status:', status);
            console.log(' Response Body:', responseText);
            await logDMSCall({
                requestBody: JSON.stringify(serialized),
                responseBody: responseText.substring(0, 2000),
                statusCode: status,
                isError: !success
            });

        } catch (error) {
            console.error('Upload failed:', error);
            console.error('Upload failed:', JSON.stringify(error));
        }
    }
}