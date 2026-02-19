import { LightningElement, api, track, wire } from 'lwc';
import getPDDetails from '@salesforce/apex/SHF_CreaditPDController.getPDDetails';
import { deleteRecord } from 'lightning/uiRecordApi';
import saveDetails from '@salesforce/apex/SHF_CreaditPDController.saveDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Shf_CreditPDSenpProfile extends LightningElement {

    _sectionName;
    _rowdata;
    _detailsFromServer;
    @api isFiancialExpenseCalculator;
    @api otherName;
    @api recordId;
    @track validField = false;
    @track deleteRecordId;

    @api
    set sectionName(value) {
        this._sectionName = value;
        this.applyServerData(); // if wire already loaded
    }
    get sectionName() {
        return this._sectionName;
    }

    @api
    set rowdata(value) {
        this._rowdata = value;

        if (!this._detailsFromServer && Array.isArray(value) && value.length) {
            this.loadFromRowdata(value);
        }
    }
    get rowdata() {
        return this._rowdata;
    }
    rules = {
        value: { type: 'number', minValue: 1, maxLength: 9 }
    }
    @api validateRequiredData() {
        console.log('validateRequiredData child12345 :', this.validField);
        let isFocused = false;
        let isValid = true;

        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea, lightning-record-picker'
        );

        inputs.forEach(element => {
            element.reportValidity();
            if (!element.checkValidity()) {
                isValid = false;
                if (!isFocused) {
                    if (typeof element.focus === 'function') {
                        element.focus();
                    }
                    isFocused = true;
                }
            }
        });
        console.log('validField child12345isValid :', isValid);
        this.validField = isValid;
        console.log('validField child12345 :', this.validField);
        const sendvalidforfinancial = new CustomEvent('sendisvalidforfinancial', {
            detail: {
                isValid: this.validField
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(sendvalidforfinancial);
        return isValid;
    }


    @track rows = [];
    grossDaily = 0;
    grossMonthly = 0;

    _tmpCounter = 0;

    connectedCallback() {
        console.log('this.isFiancialExpenseCalculator 12344:',this.isFiancialExpenseCalculator);
        this.loadPDDetails();
        this.ensureAtLeastOneRow();
    }

    /* -------------------- SERVER LOAD -------------------- */
    // @wire(getPDDetails, { parentRecordId: '$recordId' })
    // wiredPDDetails({ data, error }) {
    //     if (data) {
    //         this._detailsFromServer = data;
    //         this.applyServerData();
    //     } else if (error) {
    //         this._detailsFromServer = null;
    //         this.ensureAtLeastOneRow();
    //         this.showToast('Error', error?.body?.message || 'Failed to load details', 'error');
    //     }
    // }
    loadPDDetails() {
        if (!this.recordId) return;

        getPDDetails({ parentRecordId: this.recordId })
            .then(data => {
                this._detailsFromServer = data;
                this.applyServerData();
            })
            .catch(error => {
                this._detailsFromServer = null;
                this.ensureAtLeastOneRow();
                this.showToast(
                    'Error',
                    error?.body?.message || 'Failed to load details',
                    'error'
                );
            });
    }
    applyServerData() {
        if (!this._detailsFromServer || !this.sectionName) {
            return;
        }

        const targetSection = (this.sectionName || '').trim().toLowerCase();

        const filtered = (this._detailsFromServer || [])
            .filter(d => ((d.section || '').trim().toLowerCase() === targetSection))
            .sort((a, b) => (Number(a.orderNo) || 0) - (Number(b.orderNo) || 0));

        if (!filtered.length) {
            this.rows = [];
            this.ensureAtLeastOneRow();
            this.calculateGross();
            this.dispatchAllData();
            return;
        }

        this.rows = filtered.map((d, idx) => ({
            id: d.sfId || this.newTmpId(), // key for UI
            label: d.label || '',
            value: d.value !== null && d.value !== undefined ? Number(d.value) || 0 : null,
            sfId: d.sfId || null, // IMPORTANT for update
            orderNo: d.orderNo ? Number(d.orderNo) : (idx + 1)
        }));

        this.reindexRows();
        this.calculateGross();
        this.dispatchAllData();
    }

    loadFromRowdata(value) {
        const targetSection = (this.sectionName || '').trim().toLowerCase();

        const filtered = (value || [])
            .filter(r => ((r.section || '').trim().toLowerCase() === targetSection))
            .sort((a, b) => (Number(a.orderNo) || 0) - (Number(b.orderNo) || 0));

        if (!filtered.length) {
            this.ensureAtLeastOneRow();
            this.calculateGross();
            this.dispatchAllData();
            return;
        }

        this.rows = filtered.map((r, idx) => ({
            id: r.sfId || this.newTmpId(),
            label: r.label || '',
            value: r.value !== null && r.value !== undefined ? Number(r.value) || 0 : null,
            sfId: r.sfId || null,
            orderNo: r.orderNo ? Number(r.orderNo) : (idx + 1)
        }));

        this.reindexRows();
        this.calculateGross();
        this.dispatchAllData();
    }
    renderedCallback() {
        //this.loadPDDetails();
    }
    handleDelete() {
        deleteRecord(this.deleteRecordId)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted successfully',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.log('Error Delete :', error);
            });
    }

    newTmpId() {
        this._tmpCounter += 1;
        return `tmp-${this._tmpCounter}`;
    }

    ensureAtLeastOneRow() {
        if (!this.rows || !this.rows.length) {
            this.rows = [this.newEmptyRow(1)];
        }
    }

    newEmptyRow(orderNo) {
        return {
            id: this.newTmpId(),
            label: '',
            value: null,
            sfId: null,
            orderNo
        };
    }

    /* -------------------- DYNAMIC ROWS -------------------- */
    addRow() {
        this.rows = [...this.rows, this.newEmptyRow(this.rows.length + 1)];
        this.calculateGross();
        this.dispatchAllData();
    }

    removeRow(event) {
        const rowId = event.target.dataset.rowid;
        this.rows = this.rows.filter(r => r.id !== rowId);
        this.deleteRecordId = rowId;
        console.log('rowId :', rowId);
        if (rowId) {
            this.handleDelete();
        }
        this.ensureAtLeastOneRow();
        this.reindexRows();
        this.calculateGross();
        this.dispatchAllData();
    }

    get removeRowDisabled() {
        return !(this.rows && this.rows.length > 1);
    }

    handleRowChange(event) {
        const { rowid, field } = event.target.dataset;

        const value =
            field === 'value'
                ? (Number(event.target.value) || 0)
                : event.target.value;

        this.rows = this.rows.map(r =>
            r.id === rowid ? { ...r, [field]: value } : r
        );

        event.target.setCustomValidity('');

        // Apply rule if exists
        if (this.rules[field]) {
            const rule = this.rules[field];
            const valueStr = value ? value.toString() : '';

            // TEXT validation
            if (!rule.type || rule.type === 'text') {
                const len = valueStr.length;

                if (rule.min && len < rule.min) {
                    event.target.setCustomValidity(
                        `Minimum ${rule.min} characters required. Current: ${len}`
                    );
                } else if (rule.max && len > rule.max) {
                    event.target.setCustomValidity(
                        `Maximum ${rule.max} characters allowed. Current: ${len}`
                    );
                }
            }

            // NUMBER validation
            if (rule.type === 'number') {
                const num = Number(value);
                const len = valueStr.length;

                if (isNaN(num)) {
                    event.target.setCustomValidity('Only numbers are allowed.');
                }
                else if (rule.minValue && num < rule.minValue) {
                    event.target.setCustomValidity(
                        `Value must be greater than or equal to ${rule.minValue}.`
                    );
                }
                else if (rule.maxLength && len > rule.maxLength) {
                    event.target.setCustomValidity(
                        `Maximum ${rule.maxLength} digits allowed. Current: ${len}`
                    );
                }
            }
        }

        // Show validation immediately
        event.target.reportValidity();
        this.calculateGross();
        this.dispatchAllData();
    }

    reindexRows() {
        this.rows = this.rows.map((r, i) => ({
            ...r,
            orderNo: i + 1
        }));
    }

    /* -------------------- CALCULATION -------------------- */
    calculateGross() {
        const dynamicTotal = (this.rows || []).reduce(
            (sum, r) => sum + (Number(r.value) || 0),
            0
        );

        this.grossDaily = dynamicTotal;
        this.grossMonthly = dynamicTotal * 30; // as per your existing logic
    }

    /* -------------------- EMIT TO PARENT -------------------- */
    dispatchAllData() {
        const payload = [];

        (this.rows || []).forEach(row => {

            if (row.label || row.value !== null) {
                payload.push({
                    label: row.label,
                    value: Number(row.value) || 0,
                    section: this.sectionName,
                    sfId: row.sfId || null,       // IMPORTANT: existing row update
                    orderNo: row.orderNo
                });
            }
        });

        this.dispatchEvent(
            new CustomEvent('alldatacontentchange', {
                detail: {
                    sectionName: this.sectionName,
                    rows: payload,
                    grossDaily: this.grossDaily,
                    grossMonthly: this.grossMonthly
                },
                bubbles: true,
                composed: true
            })
        );
    }


    /* -------------------- TOAST -------------------- */
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}