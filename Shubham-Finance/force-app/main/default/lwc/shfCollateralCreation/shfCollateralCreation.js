import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import APPLICATION_LVR_FIELD from '@salesforce/schema/Application__c.LVR__c';
import APPLICATION_LTV_FIELD from '@salesforce/schema/Application__c.LTV__c';
import deactivateCollateral from '@salesforce/apex/SHF_CollateralController.deactivateCollateral';
import getPicklistValues from '@salesforce/apex/SHF_CollateralController.getPicklistValues';
import saveCollateral from '@salesforce/apex/SHF_CollateralController.saveCollateral';
import getPincodeDetailsById from '@salesforce/apex/SHF_CollateralController.getPincodeDetailsById';
import checkDuplicateCollateral from '@salesforce/apex/SHF_CollateralController.checkDuplicateCollateral';
import getCollateralForEdit from '@salesforce/apex/SHF_CollateralController.getCollateralForEdit';
import isCollateralAlreadyLinked from '@salesforce/apex/SHF_CollateralController.isCollateralAlreadyLinked';

import BUILDER_TIER_FIELD from '@salesforce/schema/Builder_Master__c.Tier_of_Builder__c';

import BUILDING_WING_FIELD from '@salesforce/schema/Building_Detail_Master__c.Wing_Name__c';
import BUILDING_FLOOR_FIELD from '@salesforce/schema/Building_Detail_Master__c.Floor_No__c';
import BUILDING_FLAT_FIELD from '@salesforce/schema/Building_Detail_Master__c.Flat_Shop_No__c';
import BUILDING_COMPLETION_FIELD from '@salesforce/schema/Building_Detail_Master__c.Building_Completion_Percentage__c';

import PROJECT_BUILDER_FIELD from '@salesforce/schema/Builder_Project_Master__c.Builder_Master__c';
import PROJECT_APFNo_FIELD from '@salesforce/schema/Builder_Project_Master__c.APF_No__c';
import PROJECT_PROP_CLASS_FIELD from '@salesforce/schema/Builder_Project_Master__c.Property_Classification__c';
import PROJECT_PROP_OWNERSHIP_FIELD from '@salesforce/schema/Builder_Project_Master__c.Property_Ownership__c';
import PROJECT_APF_FIELD from '@salesforce/schema/Builder_Project_Master__c.Project_Type__c';

import UNIT_FLAT_FIELD from '@salesforce/schema/Unit_Details_Master__c.Unit_Name_or_Flat_No__c';
import UNIT_FLOOR_FIELD from '@salesforce/schema/Unit_Details_Master__c.Floor__c';
import UNIT_MARKET_VALUE_FIELD from '@salesforce/schema/Unit_Details_Master__c.Market_Value__c';
import UNIT_ACCEPTED_VAL_FIELD from '@salesforce/schema/Unit_Details_Master__c.Accepted_Valuation__c';
import UNIT_BUILTUP_FIELD from '@salesforce/schema/Unit_Details_Master__c.Built_Up_Area_sq_ft__c';
import UNIT_CARPET_FIELD from '@salesforce/schema/Unit_Details_Master__c.Carpet_Area_Sq_Ft__c';
import UNIT_AGE_Y_FIELD from '@salesforce/schema/Unit_Details_Master__c.Age_of_Property_in_Years__c';
import UNIT_AGE_M_FIELD from '@salesforce/schema/Unit_Details_Master__c.Age_of_Property_in_Months__c';

const BREAKUP_COST_VALUE = 'Break up cost';
const normalizePickVal = (v) => (v || '').toString().trim().toLowerCase();

const PROPERTY_CLASSIFICATION_OPTIONS = [
    { label: 'Rural Property', value: 'Rural Property' },
    { label: 'Urban Property', value: 'Urban Property' },
    { label: 'Semi Urban Property', value: 'Semi Urban Property' },
    { label: 'Semi Rural Property', value: 'Semi Rural Property' }
];

const PROPERTY_TYPE_TO_NATURE_MAP = {
    'Apartment Condominum': [
        'Agricultural',
        'Commercial',
        'Industrial',
        'Institutional',
        'Residential'
    ],
    Flat: ['Residential'],
    'Individual Property': ['Residential', 'Commercial'],
    Khasra: ['Residential'],
    'Lal Dora': ['Residential', 'Commercial'],
    'Row House': ['Residential'],
    Villas: ['Residential'],
    'Commercial Shop': ['Residential', 'Commercial'],
    Villa: ['Residential']
};

export default class ShfCollateralCreation extends LightningElement {
    @api recordId; // Application Id
    @api collateralId; // Collateral Id (edit mode)
    @api isEdit = false;


    @api defaultPropertyIdentification;
    @api lockPropertyIdentification = false;

    @track collateralApplication = {
        LVR__c: null,
        LTV__c: null
    };

    _isOpen = false;
    @api get isOpen() {
        return this._isOpen;
    }
    set isOpen(value) {
        this._isOpen = value;

        if (value) {
            this.startLoading();

            const currentId = this.collateralRecord && this.collateralRecord.Id;
            if (this.isEdit && this.collateralId && this.collateralId !== currentId) {
                this.loadExistingCollateral();
            }
        }
    }

    get modalTitle() {
        return this.isEdit ? 'Edit Collateral' : 'Create Collateral';
    }

    get saveButtonLabel() {
        return this.collateralRecord?.Property_Identification__c === 'No'
            ? 'Save'
            : 'Save & Next';
    }

    get isSaveDisabled() {
        const pi = this.collateralRecord?.Property_Identification__c;
        if (!pi) return true;
        if (this.isSaving || this.isPageLoading) return true;
        if (this.isEdit && this.collateralId && !this.collateralRecord?.Id) return true;
        return false;
    }

    handleCloseClick() {
        this.dispatchEvent(new CustomEvent('close'));
    }


    @track collateralRecord = {
        Address_Type__c: 'Property Address',
        Property_cost_INR__c: null
    };

    builderId;
    projectId;
    buildingId;
    unitId;

    builderMatchingInfo = { primaryField: { fieldPath: 'Company_Name__c' } };
    builderDisplayInfo = { primaryField: 'Company_Name__c' };

    projectMatchingInfo = { primaryField: { fieldPath: 'Name' } };
    projectDisplayInfo = { primaryField: 'Name' };

    buildingMatchingInfo = { primaryField: { fieldPath: 'Name' } };
    buildingDisplayInfo = { primaryField: 'Name' };

    unitMatchingInfo = { primaryField: { fieldPath: 'Name' } };
    unitDisplayInfo = { primaryField: 'Name' };

    isPageLoading = false;
    isSaving = false;
    picklistsLoaded = false;
    loadingTimeout;

    propertyIdentificationOptions = [];
    collateralSubTypeOptions = [];
    typeOfPurchaseOptions = [];
    currentUsageOptions = [];
    propertyTypeOptions = [];
    natureOfPropertyOptions = [];
    typeOfPropertyOptions = [];
    propertyOwnershipOptions = [];
    consideredValueOptions = [];
    propertyPurposeOptions = [];
    residualAgeOptions = [];
    addressTypeOptions = [];
    propertyBreakupTypeOptions = [];
    residenceStatusOptions = [];
    residenceTypeOptions = [];
    propertyClassificationOptions = PROPERTY_CLASSIFICATION_OPTIONS;

    duplicateCollateralId;
    showDuplicateConfirm = false;

    apfOptions = [
        { label: 'APF', value: 'APF' },
        { label: 'Non APF', value: 'Non APF' },
        { label: 'Deemed APF', value: 'Deemed APF' }
    ];

    pincodeName = '';


    fireCollateralSaved(id, linkedFromExisting = false) {
        this.dispatchEvent(
            new CustomEvent('collateralsaved', {
                detail: {
                    collateralId: id,
                    propertyIdentification: this.collateralRecord?.Property_Identification__c,
                    typeOfPurchase: this.collateralRecord?.Type_Of_Purchase__c,
                    linkedFromExisting,
                    isPropertyCostDisabled: this.isPropertyCostDisabled
                }
            })
        );
    }

    @api
    openForCreate() {
        this.isEdit = false;
        this.collateralId = null;
        this.resetForm();
    }

    get isPropertyIdentificationLocked() {
        return !this.isEdit && this.lockPropertyIdentification;
    }

    get filteredNatureOfPropertyOptions() {
        const propertyType = this.collateralRecord?.Property_Type__c;
        if (!propertyType || !PROPERTY_TYPE_TO_NATURE_MAP[propertyType]) {
            return this.natureOfPropertyOptions;
        }
        const allowedValues = PROPERTY_TYPE_TO_NATURE_MAP[propertyType];
        return this.natureOfPropertyOptions.filter((opt) => allowedValues.includes(opt.value));
    }

    get canEditFlatAndFloor() {
        const apf = this.collateralRecord?.APF__c;
        return !(apf && apf !== 'APF');
    }

    get projectFilter() {
        if (!this.builderId) return null;
        return {
            criteria: [
                {
                    fieldPath: 'Builder_Master__c',
                    operator: 'eq',
                    value: this.builderId
                }
            ]
        };
    }

    get buildingFilter() {
        if (!this.projectId) return null;
        return {
            criteria: [
                {
                    fieldPath: 'Builder_Project_Master__c',
                    operator: 'eq',
                    value: this.projectId
                }
            ]
        };
    }

    get unitFilter() {
        if (this.buildingId) {
            return {
                criteria: [
                    {
                        fieldPath: 'Building_Detail_Master__c',
                        operator: 'eq',
                        value: this.buildingId
                    }
                ]
            };
        }
        if (this.projectId) {
            return {
                criteria: [
                    {
                        fieldPath: 'Builder_Project_Master__c',
                        operator: 'eq',
                        value: this.projectId
                    }
                ]
            };
        }
        return null;
    }

    get isProjectDisabled() {
        return !this.builderId;
    }
    get isBuildingDisabled() {
        return !this.projectId;
    }
    get isUnitDisabled() {
        return !this.projectId && !this.buildingId;
    }

    clearRecordPicker(refName) {
        const refs = this.refs || {};
        const elem = refs[refName];
        if (elem && typeof elem.clearSelection === 'function') {
            elem.clearSelection();
        }
    }

    clearRecordPickers(refNames = []) {
        refNames.forEach((name) => this.clearRecordPicker(name));
    }

    startLoading() {
        this.isPageLoading = true;
        if (this.picklistsLoaded) {
            window.clearTimeout(this.loadingTimeout);
            this.loadingTimeout = window.setTimeout(() => {
                this.isPageLoading = false;
            }, 300);
        }
    }
async deactivateOldIfSwitched(newCollateralId) {
    
    if (this.isEdit && this.collateralId && newCollateralId && this.collateralId !== newCollateralId) {
        await deactivateCollateral({ collateralId: this.collateralId });
    }
}

    resetForm() {
        this.collateralRecord = {
            Property_Identification__c: this.lockPropertyIdentification
                ? 'Yes'
                : this.defaultPropertyIdentification || null,
            Address_Type__c: 'Property Address',
            Property_cost_INR__c: null
        };

        this.builderId = null;
        this.projectId = null;
        this.buildingId = null;
        this.unitId = null;
        this.pincodeName = '';
        this.isSaving = false;
        this.duplicateCollateralId = null;
        this.showDuplicateConfirm = false;

        this.clearRecordPickers([
            'builderPicker',
            'projectPicker',
            'buildingPicker',
            'unitPicker',
            'pincodePicker'
        ]);
    }

    buildOptions(values) {
        if (!values) return [];
        return values.map((v) => ({ label: v, value: v }));
    }

    async loadExistingCollateral() {
        this.isPageLoading = true;
        try {
            const result = await getCollateralForEdit({
                collateralId: this.collateralId
            });

            if (result) {
                this.collateralRecord = { ...result };

                this.builderId = result.Company_Name__c || null;
                this.projectId = result.Project_Name__c || null;
                this.buildingId = result.Building_Name__c || null;
                this.unitId = result.Unit_Details__c || null;

                if (result.Pincode__c) {
                    this.loadPincodeName(result.Pincode__c);
                }
            }
        } catch (error) {
            this.showError('Error loading collateral', error);
        } finally {
            this.isPageLoading = false;
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [APPLICATION_LVR_FIELD, APPLICATION_LTV_FIELD]
    })
    wiredApplication({ data, error }) {
        if (data) {
            this.collateralApplication = {
                ...this.collateralApplication,
                LVR__c: getFieldValue(data, APPLICATION_LVR_FIELD),
                LTV__c: getFieldValue(data, APPLICATION_LTV_FIELD)
            };
        } else if (error) {
            this.showError('Error loading application details', error);
        }
    }

    @wire(getPicklistValues)
    wiredPicklists({ error, data }) {
        if (data) {
            this.propertyIdentificationOptions = this.buildOptions(data.Property_Identification__c);


            if (this.lockPropertyIdentification && !this.isEdit) {
                this.propertyIdentificationOptions = this.propertyIdentificationOptions.filter(
                    (opt) => opt.value !== 'No'
                );
            }

            this.collateralSubTypeOptions = this.buildOptions(
                data.Collateral_Sub_Type_Property_Details__c
            );
            this.typeOfPurchaseOptions = this.buildOptions(data.Type_Of_Purchase__c);
            this.currentUsageOptions = this.buildOptions(data.Current_Usage__c);
            this.propertyTypeOptions = this.buildOptions(data.Property_Type__c);
            this.natureOfPropertyOptions = this.buildOptions(data.Nature_of_Property__c);
            this.typeOfPropertyOptions = this.buildOptions(data.Type_of_property__c);
            this.propertyOwnershipOptions = this.buildOptions(data.Property_Ownership__c);

            if (data.Property_Classification__c) {
                this.propertyClassificationOptions = this.buildOptions(data.Property_Classification__c);
            }

            this.consideredValueOptions = this.buildOptions(data.Considered_Value__c);
            this.propertyPurposeOptions = this.buildOptions(data.Property_Purpose__c);
            this.residualAgeOptions = this.buildOptions(data.Residual_Age_of_Property__c);
            this.addressTypeOptions = this.buildOptions(data.Address_Type__c);
            this.residenceStatusOptions = this.buildOptions(data.Residence_Status__c);
            this.residenceTypeOptions = this.buildOptions(data.Residence_Type__c);
            this.propertyBreakupTypeOptions = this.buildOptions(data.Property_Breakup_type__c);

            this.picklistsLoaded = true;

            if (this._isOpen) {
                window.clearTimeout(this.loadingTimeout);
                this.loadingTimeout = window.setTimeout(() => {
                    this.isPageLoading = false;
                }, 300);
            }
        } else if (error) {
            this.showError('Error loading picklist values', error);
        }
    }

    get isBreakupCostSelected() {
        return (
            normalizePickVal(this.collateralRecord?.Property_Breakup_type__c) ===
            normalizePickVal(BREAKUP_COST_VALUE)
        );
    }
    get isPropertyCostDisabled() {
        return this.isBreakupCostSelected;
    }
    get isPropertyCostRequired() {
        return !this.isPropertyCostDisabled;
    }

    @wire(getRecord, {
        recordId: '$builderId',
        fields: [BUILDER_TIER_FIELD]
    })
    wiredBuilder({ data, error }) {
        if (data) {
            const tier = getFieldValue(data, BUILDER_TIER_FIELD);
            this.collateralRecord = { ...this.collateralRecord, Tier_of_Builder__c: tier };
        } else if (error) {
            this.showError('Error loading builder', error);
        }
    }

    get builderTier() {
        return this.collateralRecord.Tier_of_Builder__c || '';
    }

    @wire(getRecord, {
        recordId: '$buildingId',
        fields: [BUILDING_WING_FIELD, BUILDING_FLOOR_FIELD, BUILDING_FLAT_FIELD, BUILDING_COMPLETION_FIELD]
    })
    wiredBuilding({ data, error }) {
        if (data) {
            const wing = getFieldValue(data, BUILDING_WING_FIELD);
            const completion = getFieldValue(data, BUILDING_COMPLETION_FIELD);

            this.collateralRecord = {
                ...this.collateralRecord,
                Wing_Name__c: wing,
                Building_Completion__c: completion
            };
        } else if (error) {
            this.showError('Error loading building details', error);
        }
    }

    @wire(getRecord, {
        recordId: '$projectId',
        fields: [
            PROJECT_BUILDER_FIELD,
            PROJECT_APFNo_FIELD,
            PROJECT_PROP_CLASS_FIELD,
            PROJECT_PROP_OWNERSHIP_FIELD,
            PROJECT_APF_FIELD
        ]
    })
    wiredProject({ data, error }) {
        if (data) {
            const apfNo = getFieldValue(data, PROJECT_APFNo_FIELD);
            const apf = getFieldValue(data, PROJECT_APF_FIELD);
            const propClass = getFieldValue(data, PROJECT_PROP_CLASS_FIELD);
            const propOwnership = getFieldValue(data, PROJECT_PROP_OWNERSHIP_FIELD);

            this.collateralRecord = {
                ...this.collateralRecord,
                Project_Name__c: this.projectId,
                Property_Classification__c: propClass,
                Property_Ownership__c: propOwnership,
                APF_Number__c: apfNo,
                APF__c: apf
            };
        } else if (error) {
            this.showError('Error loading project details', error);
        }
    }

    @wire(getRecord, {
        recordId: '$unitId',
        fields: [
            UNIT_FLAT_FIELD,
            UNIT_FLOOR_FIELD,
            UNIT_MARKET_VALUE_FIELD,
            UNIT_ACCEPTED_VAL_FIELD,
            UNIT_BUILTUP_FIELD,
            UNIT_CARPET_FIELD,
            UNIT_AGE_Y_FIELD,
            UNIT_AGE_M_FIELD
        ]
    })
    wiredUnit({ data, error }) {
        if (data) {
            const flat = getFieldValue(data, UNIT_FLAT_FIELD);
            const floor = getFieldValue(data, UNIT_FLOOR_FIELD);
            const mktVal = getFieldValue(data, UNIT_MARKET_VALUE_FIELD);
            const accVal = getFieldValue(data, UNIT_ACCEPTED_VAL_FIELD);
            const bua = getFieldValue(data, UNIT_BUILTUP_FIELD);
            const ca = getFieldValue(data, UNIT_CARPET_FIELD);
            const ageY = getFieldValue(data, UNIT_AGE_Y_FIELD);
            const ageM = getFieldValue(data, UNIT_AGE_M_FIELD);

            this.collateralRecord = {
                ...this.collateralRecord,
                Market_Value_INR__c: mktVal,
                Accepted_Value_Valuation_Value_INR__c: accVal,
                Built_Up_Area__c: bua,
                Carpet_Area__c: ca,
                Age_Of_Property_In_Years__c: ageY,
                Age_Of_Property_In_Months__c: ageM,
                Accepted_Valuation_INR__c: accVal,
                Flat_Shop_No__c: flat,
                Floor_No__c: floor
            };
        } else if (error) {
            this.showError('Error loading unit details', error);
        }
    }

    get showCollateralFields() {
        return this.collateralRecord.Property_Identification__c === 'Yes';
    }

    get showNoCollateralMessage() {
        return this.collateralRecord.Property_Identification__c === 'No';
    }

    get showBuilderSection() {
        if (!this.showCollateralFields) return false;
        const subtype = this.collateralRecord.Collateral_Sub_Type_Property_Details__c;
        return subtype === 'Builder Property Under Construction';
    }

    get showOtherDetailsSection() {
        if (!this.showCollateralFields) return false;
        const subtype = this.collateralRecord.Collateral_Sub_Type_Property_Details__c;
        return (
            subtype === 'Construction On Land' ||
            subtype === 'Plot + Self Construction' ||
            subtype === 'Ready Property' ||
            subtype === 'Purchase a Plot'
        );
    }

    get fullAddress() {
        const r = this.collateralRecord || {};
        const parts = [];
        const add = (v) => {
            if (v) parts.push(v);
        };

        add(r.Flat_Plot_Number__c);
        add(r.Address_Line_2__c);
        add(r.Address_Line_3__c);
        add(r.Village__c);
        add(r.Taluka__c);
        add(r.City__c);
        add(r.State__c);
        add(r.Country__c);

        const base = parts.join(', ');
        if (this.pincodeName) {
            return base ? base + ' - ' + this.pincodeName : this.pincodeName;
        }
        return base;
    }

    handleInputChange(event) {
        const fieldApi = event.target.dataset.field;
        const value = event.detail?.value ?? event.target.value;
        if (!fieldApi) return;


        if (fieldApi === 'Property_Identification__c') {
            this.collateralRecord = { ...this.collateralRecord, Property_Identification__c: value };
            if (value === 'No') {
                this.resetCollateralFieldsExceptPropertyId();
            }
            return;
        }


        let updated = { ...this.collateralRecord, [fieldApi]: value };


        if (fieldApi === 'Property_Breakup_type__c') {
            const isBreakup =
                normalizePickVal(value) === normalizePickVal(BREAKUP_COST_VALUE);
            if (isBreakup) {
                updated.Property_cost_INR__c = null;
            }
        }


        if (fieldApi === 'Property_Type__c') {
            const allowed = PROPERTY_TYPE_TO_NATURE_MAP[value];
            const currentNature = updated.Nature_of_Property__c;
            if (allowed && currentNature && !allowed.includes(currentNature)) {
                updated.Nature_of_Property__c = null;
            }
        }

        this.collateralRecord = updated;


        if (fieldApi === 'Collateral_Sub_Type_Property_Details__c') {
            this.builderId = null;
            this.projectId = null;
            this.buildingId = null;
            this.unitId = null;

            this.collateralRecord = {
                ...this.collateralRecord,
                Company_Name__c: null,
                Project_Name__c: null,
                Building_Name__c: null,
                Unit_Details__c: null
            };

            this.clearRecordPickers(['builderPicker', 'projectPicker', 'buildingPicker', 'unitPicker']);
        }
    }

    resetCollateralFieldsExceptPropertyId() {
        const keepFields = ['Property_Identification__c', 'Collateral_ID__c', 'Id'];
        const newRec = {};
        keepFields.forEach((f) => {
            if (this.collateralRecord[f] !== undefined) {
                newRec[f] = this.collateralRecord[f];
            }
        });

        this.collateralRecord = newRec;

        this.builderId = null;
        this.projectId = null;
        this.buildingId = null;
        this.unitId = null;
        this.pincodeName = '';

        this.clearRecordPickers(['builderPicker', 'projectPicker', 'buildingPicker', 'unitPicker', 'pincodePicker']);
    }

    handleBuilderChange(event) {
        const newId = event.detail.recordId || event.detail.value || null;
        const oldId = this.builderId;

        this.builderId = newId;
        this.collateralRecord = { ...this.collateralRecord, Company_Name__c: newId };

        if (!newId) {
            this.projectId = null;
            this.buildingId = null;
            this.unitId = null;

            this.collateralRecord = {
                ...this.collateralRecord,
                Project_Name__c: null,
                Building_Name__c: null,
                Unit_Details__c: null,
                Property_Classification__c: null,
                Property_Ownership__c: null,
                APF_Number__c: null,
                APF__c: null,
                Tier_of_Builder__c: null,
                Wing_Name__c: null,
                Floor_No__c: null,
                Flat_Shop_No__c: null,
                Building_Completion__c: null
            };

            this.clearRecordPickers(['projectPicker', 'buildingPicker', 'unitPicker']);
            return;
        }

        if (oldId && newId !== oldId) {
            this.projectId = null;
            this.buildingId = null;
            this.unitId = null;

            this.collateralRecord = {
                ...this.collateralRecord,
                Project_Name__c: null,
                Building_Name__c: null,
                Unit_Details__c: null,
                Property_Classification__c: null,
                Property_Ownership__c: null,
                APF_Number__c: null,
                APF__c: null,
                Wing_Name__c: null,
                Floor_No__c: null,
                Flat_Shop_No__c: null,
                Building_Completion__c: null
            };

            this.clearRecordPickers(['projectPicker', 'buildingPicker', 'unitPicker']);
        }
    }

    handleProjectChange(event) {
        const newId = event.detail.recordId || null;
        const oldId = this.projectId;

        this.projectId = newId;
        this.collateralRecord = { ...this.collateralRecord, Project_Name__c: newId };

        if (!newId) {
            this.buildingId = null;
            this.unitId = null;

            this.collateralRecord = {
                ...this.collateralRecord,
                Building_Name__c: null,
                Unit_Details__c: null,
                Property_Classification__c: null,
                Property_Ownership__c: null,
                APF_Number__c: null,
                APF__c: null
            };

            this.clearRecordPickers(['buildingPicker', 'unitPicker']);
            return;
        }

        if (oldId && newId !== oldId) {
            this.buildingId = null;
            this.unitId = null;

            this.collateralRecord = {
                ...this.collateralRecord,
                Building_Name__c: null,
                Unit_Details__c: null
            };

            this.clearRecordPickers(['buildingPicker', 'unitPicker']);
        }
    }

    handleBuildingChange(event) {
        const newId = event.detail.recordId || null;
        const oldId = this.buildingId;

        this.buildingId = newId;
        this.collateralRecord = { ...this.collateralRecord, Building_Name__c: newId };

        if (!newId) {
            this.unitId = null;

            this.collateralRecord = {
                ...this.collateralRecord,
                Unit_Details__c: null,
                Wing_Name__c: null,
                Floor_No__c: null,
                Flat_Shop_No__c: null,
                Building_Completion__c: null
            };

            this.clearRecordPickers(['unitPicker']);
            return;
        }

        if (oldId && newId !== oldId) {
            this.unitId = null;

            this.collateralRecord = {
                ...this.collateralRecord,
                Unit_Details__c: null,
                Market_Value_INR__c: null,
                Accepted_Value_Valuation_Value_INR__c: null,
                Built_Up_Area__c: null,
                Carpet_Area__c: null,
                Age_Of_Property_In_Years__c: null,
                Age_Of_Property_In_Months__c: null,
                Accepted_Valuation_INR__c: null,
                Flat_Shop_No__c: null,
                Floor_No__c: null
            };

            this.clearRecordPickers(['unitPicker']);
        }
    }

    handleUnitChange(event) {
        const newId = event.detail.recordId || null;

        this.unitId = newId;
        this.collateralRecord = { ...this.collateralRecord, Unit_Details__c: newId };

        if (!newId) {
            this.collateralRecord = {
                ...this.collateralRecord,
                Market_Value_INR__c: null,
                Accepted_Value_Valuation_Value_INR__c: null,
                Built_Up_Area__c: null,
                Carpet_Area__c: null,
                Age_Of_Property_In_Years__c: null,
                Age_Of_Property_In_Months__c: null,
                Accepted_Valuation_INR__c: null,
                Flat_Shop_No__c: null,
                Floor_No__c: null
            };
        }
    }

    handlePincodeLookupChange(event) {
        const recordId = event.detail.recordId || event.detail.value;

        if (!recordId) {
            this.pincodeName = '';
            this.collateralRecord = {
                ...this.collateralRecord,
                City__c: null,
                State__c: null,
                Country__c: null,
                Pincode__c: null,
                District__c: null
            };
            return;
        }

        getPincodeDetailsById({ pincodeId: recordId })
            .then((result) => {
                if (result) {
                    this.pincodeName = result.name;
                    this.collateralRecord = {
                        ...this.collateralRecord,
                        City__c: result.city,
                        State__c: result.state,
                        Country__c: result.country,
                        Pincode__c: result.pincodeId,
                        District__c: result.district
                    };
                } else {
                    this.pincodeName = '';
                    this.collateralRecord = {
                        ...this.collateralRecord,
                        City__c: null,
                        State__c: null,
                        Country__c: null,
                        Pincode__c: null,
                        District__c: null
                    };
                    this.showError('Pincode not found', {
                        body: { message: 'No matching pincode found.' }
                    });
                }
            })
            .catch((error) => {
                this.pincodeName = '';
                this.collateralRecord = {
                    ...this.collateralRecord,
                    City__c: null,
                    State__c: null,
                    Country__c: null,
                    Pincode__c: null,
                    District__c: null
                };
                this.showError('Error fetching pincode details', error);
            });
    }

    loadPincodeName(pincodeId) {
        if (!pincodeId) {
            this.pincodeName = '';
            return;
        }

        getPincodeDetailsById({ pincodeId })
            .then((result) => {
                this.pincodeName = result ? result.name : '';
            })
            .catch((error) => {
                this.pincodeName = '';
                this.showError('Error fetching pincode details', error);
            });
    }

    validateRequiredData() {
        let isFocused = false;
        let isValid = true;

        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea, lightning-record-picker'
        );

        inputs.forEach((element) => {
            element.reportValidity();
            if (!element.checkValidity()) {
                isValid = false;
                if (!isFocused && typeof element.focus === 'function') {
                    element.focus();
                    isFocused = true;
                }
            }
        });

        return isValid;
    }

    async handleDuplicateYes() {
        this.isSaving = true;
        try {
            const payload = { ...this.collateralRecord, Id: this.duplicateCollateralId };

            const id = await saveCollateral({
                collateral: payload,
                applicationId: this.recordId
            });
            await this.deactivateOldIfSwitched(id);
            this.collateralRecord = { ...this.collateralRecord, Id: id };

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Existing collateral linked to the application.',
                    variant: 'success'
                })
            );


            this.fireCollateralSaved(id, true);
        } catch (error) {
            this.showError('Error saving/linking collateral', error);
        } finally {
            this.showDuplicateConfirm = false;
            this.isSaving = false;
        }
    }

    handleDuplicateNo() {
        this.showDuplicateConfirm = false;
    }

    async handleSave() {
        const allValid = this.validateRequiredData();
        if (!allValid) return;

        const pi = this.collateralRecord?.Property_Identification__c;


        if (pi === 'No') {
            this.isSaving = true;
            try {
                const id = await saveCollateral({
                    collateral: { ...this.collateralRecord },
                    applicationId: this.recordId
                });
                await this.deactivateOldIfSwitched(id);

                this.collateralRecord = { ...this.collateralRecord, Id: id };

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Collateral saved successfully.',
                        variant: 'success'
                    })
                );

                this.fireCollateralSaved(id, false);
                return;
            } catch (error) {
                this.showError('Error saving collateral', error);
            } finally {
                this.isSaving = false;
            }
            return;
        }


        const payload = { ...this.collateralRecord };
        if (this.isEdit && this.collateralId && !payload.Id) {
            payload.Id = this.collateralId;
        }

        this.isSaving = true;
        try {
            const duplicateId = await checkDuplicateCollateral({ collateral: payload });

            if (duplicateId) {
                const alreadyLinked = await isCollateralAlreadyLinked({
                    collateralId: duplicateId,
                    applicationId: this.recordId
                });

                if (alreadyLinked) {
                    const payloadWithId = { ...payload, Id: duplicateId };

                    const id = await saveCollateral({
                        collateral: payloadWithId,
                        applicationId: this.recordId
                    });

                    this.collateralRecord = { ...this.collateralRecord, Id: id };

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Info',
                            message:
                                'This collateral is already linked with this application. Details have been updated.',
                            variant: 'info'
                        })
                    );

                    
                    this.fireCollateralSaved(id, true);
                    return;
                }

                this.duplicateCollateralId = duplicateId;
                this.showDuplicateConfirm = true;
                return;
            }

            const id = await saveCollateral({
                collateral: payload,
                applicationId: this.recordId
            });

            this.collateralRecord = { ...this.collateralRecord, Id: id };

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Collateral saved successfully.',
                    variant: 'success'
                })
            );


            this.fireCollateralSaved(id, false);
        } catch (error) {
            this.showError('Error saving collateral', error);
        } finally {
            this.isSaving = false;
        }
    }

    showError(title, error) {
        let message = 'Unknown error';
        if (error?.body?.pageErrors && error?.body?.pageErrors[0]?.message) {
            message = error.body.pageErrors[0].message;
        } else if (error?.body?.message) {
            message = error.body.message;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant: 'error'
            })
        );
    }
}