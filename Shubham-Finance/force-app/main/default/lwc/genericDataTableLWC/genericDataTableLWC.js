import { LightningElement, api, track } from 'lwc';
export default class GenericDataTableLWC extends LightningElement {
    @api result;
    @api btns;
    @api selectedRows = [];
    @track _showSpinner = true;
    @track _checkboxesStatus;
    //Data
    @api _columns;
    // Complete Set of Data
    @track _allData = [];
     //Data which should show on page
    @track _recordsInPage;
     //SHOULD COME FROM MDT
    @track _keyField;
    //SORTING
    @api _sortMap;
    @track sortByUI;
    @track sortByBackhand;
    @track sortDirection;
    @track sortDirectionDefault;
    //Paging
    @api _showPagination = false;
    @track _pageNumber = 1;
    @track _maxPage = 1;
    @track _numOfRecord;
    @track _startRecord;
    @track _endRecord;
    @track _recordCount;
    @track _eventStorage;
    //Searching
    @api _showSearch = false;
    @track searchGridClass = 'slds-grid slds-grid_align-spread slds-m-vertical_x-small';
    //Number of Record PickList
    @api _showPagingPicklist = false;
    @api _pagingPicklistValues;
    //Error
    @track _errors = '';
    @track _isFieldSet = false;
    @api maxRowSelection = 0;
    @track _treatCheckboxesAsRadio;
    //Connected Callback
    connectedCallback(){
        this.init(this.result);
        this._showSpinner = false;
    }
    //Initilize Data
    @api init(datamap){
        this.result = datamap;    
        if(this.result && !this.result.isError){
            this._isFieldSet = this.propertyNullCheck(this.result,'isFieldSet');
            this._keyField = this.propertyNullCheck(this.result,'keyField');
            this._showPagination = this.propertyNullCheck(this.result,'isShowPagination');
            this._showSearch = this.propertyNullCheck(this.result,'showSearch');
            this._showPagingPicklist = this.propertyNullCheck(this.result,'showPagingPicklist');
            this._pagingPicklistValues = this.arrangePagingPicklist(this.propertyNullCheck(this.result,'pagingPicklistValues'));
            this.searchGridClass = this.searchGridClass + (this._showSearch && !this._showPagingPicklist ? ' slds-grid_align-end' : '');
            this._numOfRecord = this.propertyNullCheck(this.result,'numberOfRecords');
            this._columns = this.propertyNullCheck(this.result,'lstDataTableColumns');
            
            if(this.btns){
                console.log('before concat ',JSON.stringify(this._columns));
                this._columns = this._columns.concat(this.btns);
                console.log('after concat ',JSON.stringify(this._columns));
                // this.btns.forEach(element =>{
                //     this._columns.push(element);
                // });
            }
            if(this._isFieldSet){
                this.handleSortingMapForFieldSet(this._columns);                
            }else{
                this._sortMap = this.propertyNullCheck(this.result,'sortMap');
            }
            this.sortByUI = this._sortMap[this.result.defaultSortBy];
            this.sortByBackhand = this.propertyNullCheck(this.result,'defaultSortBy');
            this.sortDirection = this.propertyNullCheck(this.result,'defaultSortDirection');
            this.sortDirectionDefault = this.sortDirection;
            this.arrangeTableRows(this.propertyNullCheck(this.result,'strDataTableData'));
            this._checkboxesStatus = !Boolean(this.propertyNullCheck(this.result,'showCheckboxes'));
            this._treatCheckboxesAsRadio = this.propertyNullCheck(this.result,'treatCheckboxesAsRadio');
            console.log(' this._treatCheckboxesAsRadio', this._treatCheckboxesAsRadio);
            if(this._treatCheckboxesAsRadio){
                this._maxRowSelection = 1;
            }     

        }else{
            this._errors = this.result.errorMessage;
        }
        this._showSpinner = false;
    }
    //Handle Data
    async arrangeTableRows(rowData){
        console.log('rowdata is'+ rowData);
        await this.resetPaging();
        if(this._isFieldSet){
            this._allData = rowData;
        }else{
            this._allData = JSON.parse(rowData);
        }
        this._maxPage = Math.ceil((this._allData.length)/this._numOfRecord);
        this.sortHelper(this._allData,this.sortByBackhand,this.sortDirection);
        //this.resetSorting(this._allData); - IF NEEDED
    }
    //Disable First and Previous Button
    get disableFirstAndPrevious(){
        return this._pageNumber === 1;
    }
    //Disable Next and Last Button
    get disableNextAndLast(){
        return this._pageNumber === this._maxPage;
    }
    //Pagination First
    first(){
        this._pageNumber = 1;
        this.renderContent(this._allData);
    }
    //Pagination Last
    last(){
        this._pageNumber = this._maxPage;
        this.renderContent(this._allData);
    }
    //Pagination Next
    next(){
        this._pageNumber = Math.min(this._pageNumber+1, this._maxPage);
        this.renderContent(this._allData);
    }
    //Pagination Previous
    previous(){
        this._pageNumber = Math.max(this._pageNumber-1, 1);
        this.renderContent(this._allData);
    }
    //Paging
    renderContent(data){
        let _dataList = data;
        console.log('_dataList  ',_dataList);
        let pageNumber = this._pageNumber;
        console.log('pageNumber  ',pageNumber);
        let pageRecords = _dataList.slice((pageNumber-1)*this._numOfRecord, pageNumber*this._numOfRecord);
        console.log('pageRecords  ',pageRecords);
        this._recordsInPage = pageRecords;
        console.log('_recordsInPage : ',JSON.parse(JSON.stringify(pageRecords)))
        this.dateCount(data);
        this._showSpinner = false;
        this._showTable = pageRecords && pageRecords.length > 0 ? true:false;
    }
    //Counting Records
    dateCount(data){
        let start = (this._pageNumber - 1) * parseInt(this._numOfRecord);
        let end = parseInt(start) + parseInt(this._numOfRecord);
        this._startRecord = start + parseInt(1);
        this._endRecord = end > data.length ? data.length : end;
        this._recordCount = data.length;
    }
    //Reset Paging on Update And Filter Change
    resetPaging(){
        this._pageNumber = 1;
        this._maxPage = 1;
    }
    //Sorting handler
    handleSortdata(event) {
        this.sortByBackhand = this._sortMap[event.detail.fieldName];
        this.sortByUI = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortHelper(this._allData,this.sortByBackhand,this.sortDirection);
    }
    //Sort Helper
    sortHelper(dataToSort,sortBy,direction){
        let fieldValue = row => row[sortBy] || '';
        let reverse = direction === 'asc' ? 1 : -1;
        if(dataToSort !== undefined && dataToSort.length > 0){
            try{
                var records = Object.assign([], dataToSort);
                records = records.sort((a, b) => {
                    a = fieldValue(a) ? fieldValue(a) : '';
                    b = fieldValue(b) ? fieldValue(b) : '';
                    return reverse * ((a > b) - (b > a));
                });
                this._maxPage = Math.ceil((records.length)/this._numOfRecord);
                this._allData = records;
                this.renderContent(records);
            }
            catch(error){
                console.error('error-> ', error);
            }
        }
    }
    handleTextChange(event){
        this.resetPaging();
        let _searchVar = event.detail.value;
        let _dataList;
        if(this._isFieldSet){
            _dataList = this.result.strDataTableData;
        }else{
            _dataList = JSON.parse(this.result.strDataTableData);
        }
        let _filterList = [];
        if(_searchVar){
            _filterList = this.arrayContainsValue(_dataList,_searchVar);
        }else{
            _filterList = this._allData;
        }
        this._maxPage = Math.ceil((_filterList.length)/this._numOfRecord);
        this.renderContent(_filterList);
    }
    arrayContainsValue(arr, val){
        var records=[];
        var _regex = new RegExp(val, "i");
        for (var i = 0; i < arr.length; i++) {
            for (var key in arr[i]){
                if(arr[i][key].search( _regex ) !== -1){
                    records.push(arr[i]);
                    break;
                }
            }
        }
        return records;
    }
    arrangePagingPicklist(arr){
        var records = [];
        if(arr){
        for (var i = 0; i < arr.length; i++) {
            records.push({
                "label" : arr[i],
                "value" : arr[i]
            });
        }
    }
        return records;
    }
    handlePagingChange(event){
        this.resetPaging();
        this._numOfRecord = event.detail.value;
        this._maxPage = Math.ceil((this._allData.length)/this._numOfRecord);
        this.renderContent(this._allData);
    }
    //Map for Sorting
    handleSortingMapForFieldSet(headerData){
        if(headerData){
            let finalSortMap = {};
            headerData.forEach((record) => {
                if(record.type === 'url'){
                    finalSortMap[record.fieldName] = record.typeAttributes.label.fieldName;
                }else{
                    finalSortMap[record.fieldName] = record.fieldName;
                }
            });
            this._sortMap = finalSortMap;
        }
    }
    propertyNullCheck(arr,propertyToCheck){
        let returnVar = '';
        if(arr){
            returnVar = arr.hasOwnProperty(propertyToCheck) ? arr[propertyToCheck] : '';
        }
        return returnVar;
    } 
    handleRowAction(event) {
        console.log('method called...');
        try{
            var dataToSend = {};
            let row = event.detail.row;
            for (var k in row){
                if (row[k].length === 1) {
                    row[k] = row[k].trim();
                }
            }
            dataToSend['ActionName'] = event.detail.action.label;
            dataToSend['recordData'] = row;
            console.log('dataToSend: '+JSON.stringify(dataToSend.recordData));
            const selectedEvent = new CustomEvent('selected', { detail: dataToSend });
            this.dispatchEvent(selectedEvent);
        } catch(error){
            console.log(error);
        }
    }

    handleRowSelection(event) {
        this.dispatchEvent(new CustomEvent('rowselectionevent', { detail: event.detail.selectedRows }));
    }
}