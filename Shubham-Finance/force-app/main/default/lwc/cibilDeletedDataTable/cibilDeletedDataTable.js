import { LightningElement, api } from 'lwc';

export default class CibilDeletedDataTable extends LightningElement {
    @api obligationCibilDeletedList;
    @api cibilDeletedTableColumns;
}