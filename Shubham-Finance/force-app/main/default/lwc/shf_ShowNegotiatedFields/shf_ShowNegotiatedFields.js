import { LightningElement, api, track, wire } from 'lwc';
import getActivity from '@salesforce/apex/SHF_NegotiationApprovalController.getActivity';

const FIELDS = [
    'Activity_History__c.Owner.Profile.Name',
    'Activity_History__c.NegotiationApprovalJson__c'
];

export default class Shf_ShowNegotiatedFields extends LightningElement {
    @api recordId;

    @track applicationRows = [];
    @track insuranceSections = [];

    jsonString;
    ownerProfileName;
    isVisibleSection = false;


@wire(getActivity, { recordId: '$recordId' })
wiredActivity({ data, error }) {
    if (data) {
        this.ownerProfileName = data.Owner.Profile.Name;
        this.isVisibleSection = this.ownerProfileName === 'Credit';
        this.jsonString = data.NegotiationApprovalJson__c;
        this.parseJson();
    } else if (error) {
        console.error(error);
    }
}

    // ---------------- PARSE JSON ----------------
    parseJson() {
        if (!this.jsonString) return;

        let parsed;
        try {
            parsed = JSON.parse(this.jsonString);
        } catch (e) {
            console.error('Invalid JSON', e);
            return;
        }

        this.prepareApplicationTable(parsed.applicationDetail);
        this.prepareInsuranceTable(parsed.applicantsInsurance);
    }

    // ---------------- NORMALIZE LABEL ----------------
 normalizeLabel(label) {
    let cleaned = label.replace(/\s+/g, ' ').trim();

    // convert any ROI text to ROI%
    if (cleaned.toLowerCase().includes('roi')) {
        return 'ROI%';
    }

    if (cleaned.toLowerCase().includes('sanctioned loan amount') || cleaned.toLowerCase().includes('sanction loan amount')) {
        return 'Sanctioned Loan Amount';
    }

    return cleaned;
}

    // ---------------- APPLICATION DETAILS ----------------
    prepareApplicationTable(appDetail = {}) {
    const tempMap = {};

    Object.keys(appDetail).forEach(key => {
        if (key === 'Id') return;

        let type, label;

        if (key.startsWith('Negotiation')) {
            type = 'negotiation';
            label = key.replace('Negotiation', '');
        } else if (key.startsWith('Original')) {
            type = 'original';
            label = key.replace('Original', '');
        } else if (key.startsWith('RFC')) {
            type = 'rfc';
            label = key.replace('RFC', '');
        } else {
            return;
        }

        label = this.normalizeLabel(label);

        // 🔹 PROFILE BASED FIELD CONTROL
        if (this.ownerProfileName === 'Credit') {
            if (!['Sanctioned Loan Amount', 'Tenure'].includes(label)) return;
        } else {
           if (!['Processing Fee Percent', 'Processing Fee', 'ROI%'].includes(label))
             return;
        }

        if (!tempMap[label]) {
            tempMap[label] = {
                key: label,
                label,
                negotiation: '',
                original: '',
                rfc: ''
            };
        }

        tempMap[label][type] = appDetail[key];
    });

    // 🔹 show only changed values
    this.applicationRows = Object.values(tempMap).filter(
        row => row.negotiation && row.negotiation !== row.original
    );
}


    // ---------------- APPLICANTS INSURANCE ----------------
    prepareInsuranceTable(applicants = []) {
        const sectionMap = {};

        applicants.forEach(app => {
            if (!sectionMap[app.Name]) {
                sectionMap[app.Name] = {
                    applicant: app.Name,
                    rows: []
                };
            }

            const fieldMap = {};

            Object.keys(app).forEach(key => {
                if (key === 'applicationId' || key === 'Name') return;

                let type, label;

                if (key.startsWith('Negotiation')) {
                    type = 'negotiation';
                    label = key.replace('Negotiation', '');
                } else if (key.startsWith('Original')) {
                    type = 'original';
                    label = key.replace('Original', '');
                } else if (key.startsWith('RFC')) {
                    type = 'rfc';
                    label = key.replace('RFC', '');
                } else {
                    return;
                }

                label = this.normalizeLabel(label);

                if (!fieldMap[label]) {
                    fieldMap[label] = {
                        key: app.Name + '_' + label,
                        label,
                        negotiation: '',
                        original: '',
                        rfc: ''
                    };
                }

                fieldMap[label][type] = app[key];
            });

            Object.values(fieldMap).forEach(row => {
                if (row.negotiation) {
                    sectionMap[app.Name].rows.push(row);
                }
            });
        });

        this.insuranceSections = Object.values(sectionMap);
    }
}