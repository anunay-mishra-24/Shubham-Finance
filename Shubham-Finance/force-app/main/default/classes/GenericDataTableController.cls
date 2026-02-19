/*
This is a extendable class use to create data table.
This class consume Data_Table__mdt & Data_Table_Content__mdt.

* Required Parameters - Metadata
* METADATA_NAME - Holds the developer name of custom metadata.

* Required Parameters - Fieldset
* IS_FIELDSET - Should be true in fieldset case.
* FIELD_SET_NAME - Fieldset API name.
* OBJECT_API_NAME - Object's API name.

* Optional Parameters - Fieldset/Metadata
* WHERE_CLAUSE - Holds the Where Condition for query.
* RECORD_LIMIT - Holds the Record Limit to be fetched from query.
* IDS_SET - Set of string holds values to be checked in query.
* LINK_NAMES_SET (For Fieldset only) - holds the API name of field which we habe to make as link.
*/
public class GenericDataTableController {
    @TestVisible private static final String METADATA_QUERY = 'SELECT '+GenericDataTableControllerHelper.DATA_TABLE_QUERY_FIELDS +', (SELECT '+GenericDataTableControllerHelper.CHILD_QUERY_FIELDS+' FROM '+GenericDataTableControllerHelper.CHILD_RELATIONSHIP_NAME+' ORDER BY Sequence__c ASC)  FROM '+GenericDataTableControllerHelper.PARENT_METADATA_API_NAME;  
    
    @TestVisible private GenericDataTableControllerHelper.DataParserWrapper identifiers;
    @TestVisible private String objectName;
    
    public String METADATA_NAME{get;set;}
    public String WHERE_CLAUSE{get;set;}
    public String RECORD_LIMIT{get;set;}
    public Set<String> IDS_SET{get;set;}
    public Boolean IS_READ_ONLY{get;set;}
    
    /*
	*This method is use to get all the properties from metadata and return them.
	*This method is use for metadata approach. 
	*/
    public DataTableResponse getTable(String recordId){
        DataTableResponse table = new DataTableResponse();
        table.isError = false;
        try{
            GenericDataTableControllerHelper helper = new GenericDataTableControllerHelper();
            GenericDataTableControllerHelper.InitializeWrapper initData = helper.initialize(METADATA_QUERY, METADATA_NAME);
            List<Data_Table__mdt> metadataRecord = initData.metadataRecords;
            if(!metadataRecord.isEmpty()){
                table.keyField = metadataRecord[0].Table_Key_Field_API_Name__c;
                table.isShowPagination = metadataRecord[0].Show_Pagination__c;
                table.numberOfRecords = metadataRecord[0].Default_Page_Size__c;
                table.showPagingPicklist = metadataRecord[0].Show_Paging_Picklist__c;
                table.showCheckboxes = metadataRecord[0].Show_Checkboxes__c;
                table.treatCheckboxesAsRadio = metadataRecord[0].Treat_Checkboxes_As_Radio__c;
                table.objectAPIName = metadataRecord[0].Object_API_Name__c;
                table.label = metadataRecord[0].MasterLabel;
                if(String.isNotEmpty(metadataRecord[0].Paging_Picklist_Values__c)){
                    table.pagingPicklistValues = new List<String>(metadataRecord[0].Paging_Picklist_Values__c.split(','));
                }
                table.showSearch = metadataRecord[0].Show_Search__c;
                objectName = metadataRecord[0].Object_API_Name__c;
                table.lstDataTableColumns = getHeaders(initData.cols);

                //Added by mansur alam to handle the header action visibility
                if(recordId != null && String.valueOf((Id.valueOf(recordId)).getSObjectType()) == SHF_ConstantsUtil.APPLICATION){

                Application__c applicationDetail = [SELECT Id,Owner.UserRole.Name,Is_Current_User__c,Owner.Profile.Name FROM Application__c WHERE Id =: recordId];
                List<String> allowedRolesOrProfileList = System.Label.Header_Action_Enabled.split(',');
                if(allowedRolesOrProfileList.contains(applicationDetail.Owner.Profile.Name) && applicationDetail.Is_Current_User__c){
                    table.headerActions  = getHeaderActions(metadataRecord[0].Id);
                    system.debug('inside if > ' + table.headerActions);
                }else{
                   
                    List<Action> actionList = new list<Action>();
                    for(Action action : getHeaderActions(metadataRecord[0].Id)){
                        action.isEnable = false;
                        actionList.add(action);
                    }
                    table.headerActions  = actionList;
                     system.debug('inside else > ' + table.headerActions);
                }
            }
                
                identifiers = helper.dataParser(initData.cols, initData.dataParse);
                table.defaultSortBy = identifiers.actualToDummyHyperLink.containsKey(metadataRecord[0].Sort_By__c) ? identifiers.actualToDummyHyperLink.get(metadataRecord[0].Sort_By__c) : metadataRecord[0].Sort_By__c;
                table.defaultSortDirection = metadataRecord[0].Sort_Direction__c;
                String query = selector();
                System.debug('querrrry -- '+ query);
                // System.debug('querrrry -- '+ String.join(parseInnerJson(query),','));
                table.strDataTableData = '[' + String.join(parseInnerJson(query),',')+ ']';
                // System.debug('table.strDataTableData -- '+table.strDataTableData);
                table.sortMap = identifiers.sortMapInner;
            }
        }catch(exception ex){
            table.isError = true;
            table.errorMessage = ex.getMessage();
        }
        return table;
    }
    
    private List<Action> getHeaderActions(Id dataTableId){
        List<Action> headerActions = new List<Action>();
        for(Data_Table_Action__mdt dtAction : [SELECT Id, DeveloperName, MasterLabel, Label, Data_Table__c, Enable_Filter_Conditions__c, Error_Message__c, Is_Show_In_Modal__c, Link__c, New_Record_Default_Values__c, New_Record_sObject_API_Name__c, Success_Message__c, Type__c FROM Data_Table_Action__mdt  where Data_Table__c =:dataTableId]){
            headerActions.add(new Action(dtAction));
        }
        return headerActions;
    }
    
    /*This method is use to get headers for the table.*/
    @TestVisible private List<Header> getHeaders(List<Data_Table_Content__mdt>cols){
        List<Header> headers = new List<Header>();
        List<RowAction> rowActionsList = new List<RowAction>();
        if(!cols.isEmpty()){
            for(Data_Table_Content__mdt col : cols){
                if(col.DataType__c == 'date-local'){                    
                    TypeAttributes typeAttribute = new TypeAttributes('numeric', 'numeric', 'numeric');
                    headers.add(new Header(col.Sequence__c, col.MasterLabel, col.Field_API_Name__c, true, col.DataType__c, typeAttribute, col.Column_Width__c));
                } else if(col.DataType__c == 'date'){                    
                    TypeAttributes typeAttribute = new TypeAttributes('numeric', 'numeric', 'numeric','2-digit', '2-digit', '2-digit','Asia/Kolkata');
                    headers.add(new Header(col.Sequence__c, col.MasterLabel, col.Field_API_Name__c, true, col.DataType__c, typeAttribute, col.Column_Width__c));
                } else if(col.DataType__c == 'url'){                    
                    TypeAttributes typeAttribute = new TypeAttributes();
                    String dummyValue = GenericDataTableControllerHelper.arrangeDummies(col.URL_Target_Field_API_Name__c, false);
                    String dummyLabel = GenericDataTableControllerHelper.arrangeDummies(col.URL_Label_Field_API_Name__c, true);
                    typeAttribute.label = new label(dummyLabel);
                    headers.add(new Header(col.Sequence__c, col.MasterLabel, dummyValue, true, col.DataType__c, typeAttribute, col.Column_Width__c));
                }else if(col.DataType__c == 'action'){
                    if(IS_READ_ONLY){
                        List<String> readOnlyAllowedActions = System.Label.Read_Only_Allowed_Actions.split(';');
                        if(!readOnlyAllowedActions.isEmpty()){
                            if(readOnlyAllowedActions.contains(col.MasterLabel)){
                                rowActionsList.add(new RowAction(col));    
                            }
                        }
                    }else{
                        rowActionsList.add(new RowAction(col));
                    }
                }else{
                    headers.add(new Header(col.Sequence__c, col.MasterLabel, col.Field_API_Name__c, true, col.DataType__c, null, col.Column_Width__c));
                }
            }
            if (!rowActionsList.isEmpty()) {
                TypeAttributes ta = new TypeAttributes();
                ta.rowActions = rowActionsList;
                headers.add(new Header(null, 'Action', null, false, 'action', ta , 100));
                
            }
        }
        return headers;
    }
    
    /*
	*This method is use to create records Json.
	*/
    @TestVisible private List<String> parseInnerJson(String query){
        List<String> jsonList = new List<String>();
        System.debug('records 22--- '+query);
        // List<sObject> records = new List<sObject>(Database.Query(String.escapeSingleQuotes(query)));
        List<sObject> records = new List<sObject>(Database.Query(query)); // added by vikas on 23/11/25
        System.debug('records 23--- '+records);
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;  
        for(sObject record : records){
            List<String> innerJsonList = new List<String>();            
            Map<String,String> fieldToValue = parseQuery(record, new List<String>(identifiers.fieldToQuery));
            for(String field : fieldToValue.KeySet()){
                if(field.equalsIgnoreCase('ID')){
                    innerJsonList.add('"' + field + '" : "' + fieldToValue.get(field).replaceAll('[\r\n]',' ') + '"');
                }
                if(identifiers.actualToDummyHyperLink.containsKey(field)){
                    if(identifiers.urlIdentifier.contains(identifiers.actualToDummyHyperLink.get(field))){
                        innerJsonList.add('"' + identifiers.actualToDummyHyperLink.get(field) + '" : "/lightning/_classic/' + fieldToValue.get(field).replaceAll('[\r\n]',' ') + '"');
                    }else{
                        innerJsonList.add('"' + identifiers.actualToDummyHyperLink.get(field) + '" : "' + fieldToValue.get(field).replaceAll('[\r\n]',' ') + '"');
                    }
                }
                else if (identifiers.dateIdentifier.contains(field)){
                    String parsedDate = (String.isNotBlank(fieldToValue.get(field)) ? String.valueOf(Date.valueOf(fieldToValue.get(field))) : '');
                    innerJsonList.add('"' + field + '" : "' + parsedDate + '"');
                }
                else if (identifiers.dateTimeIdentifier.contains(field)){
                    String parsedDate ='';
                    if(String.isNotBlank(fieldToValue.get(field))){
                        DateTime dt = DateTime.valueOf(fieldToValue.get(field));
                        dt = dt.addHours(5);
                        dt = dt.addMinutes(30);
                        parsedDate = dt.format('dd/MM/yyyy','Asia/Kolkata');
                    }
                    //parsedDate = (String.isNotBlank(fieldToValue.get(field)) ? String.valueOf(DateTime.valueOf(fieldToValue.get(field))) : '');
                    innerJsonList.add('"' + field + '" : "' + parsedDate + '"');
                }
                else if(identifiers.booleanIdentifier.contains(field)){
                    innerJsonList.add('"' + field + '" : ' + fieldToValue.get(field).replaceAll('[\r\n]',' ') + '');
                }
                else{
                    innerJsonList.add('"' + field + '" : "' + fieldToValue.get(field).replaceAll('[\r\n\t]','') + '"');
                }               
            }
            String json = '{' + String.join(innerJsonList, ',') + '}';
            jsonList.add(json);
        }
        system.debug('jsonList--- '+jsonList);
        System.debug('jsonList--- '+jsonList.size());
        return jsonList;
    }
    
    /*
	*This method is use to parse the query result.
	*/
    private Map<String,String> parseQuery(sObject record, List<String> fieldToQuery){
        Map<String,String> returnMap = new Map<String,String>();        
        for(String field : fieldToQuery){
            if(field.contains('.')){
                String relName = field.substringBefore('.');
                String fldName = field.substringAfter('.');
                sObject childObj = record.getSObject(relName);
                
                if(childObj != null && String.isNotBlank(String.valueOf(childObj.get(fldName)))){
                    returnMap.put(field,String.valueOf(childObj.get(fldName)));
                }else{
                    returnMap.put(field,' ');
                }
            }else{
                if(String.isNotBlank(String.valueOf(record.get(field)))){
                    returnMap.put(field,String.valueOf(record.get(field)));
                }else{
                    returnMap.put(field,' ');
                }
            }
        }
        return returnMap;
    }
    
    /*
	*This method is use to create the query string.
	*/
    private String selector(){
        String simpleQuery = 'select {0} FROM {1}';
        String queryWithConditional = 'select {0} FROM {1} WHERE {2}';
        String fields = String.join(new List<String>(identifiers.fieldToQuery),',');
        String query;
        if(String.isNotBlank(WHERE_CLAUSE)){
            query = String.format(queryWithConditional, new List<Object>{fields, objectName, WHERE_CLAUSE});
        }else{
            query = String.format(simpleQuery, new List<Object>{fields, objectName});
        }
        if(String.isNotBlank(RECORD_LIMIT)){
            query += ' LIMIT ' + RECORD_LIMIT;
        }
        return query;
    }
    
    public class DataTableResponse{
        @AuraEnabled
        public String keyField{get;set;}
        @AuraEnabled
        public Boolean isShowPagination{get;set;}
        @AuraEnabled
        public String objectAPIName{get;set;}
        @AuraEnabled
        public String label{get;set;}
        @AuraEnabled
        public Boolean showSearch{get;set;}
        @AuraEnabled
        public Boolean showPagingPicklist{get;set;}
        @AuraEnabled
        public List<String> pagingPicklistValues{get;set;}
        @AuraEnabled
        public Decimal numberOfRecords{get;set;}
        @AuraEnabled
        public String defaultSortBy{get;set;}
        @AuraEnabled
        public String defaultSortDirection{get;set;}
        @AuraEnabled
        public List<Header> lstDataTableColumns{get;set;}
        @AuraEnabled
        public List<Action> headerActions {get;set;}
        @AuraEnabled
        public String strDataTableData{get;set;}
        @AuraEnabled
        public Map<String,String> sortMap{get;set;}
        @AuraEnabled
        public List<Object> fieldSetResult{get;set;}
        @AuraEnabled
        public Boolean isError{get;set;}
        @AuraEnabled
        public String errorMessage{get;set;}
        @AuraEnabled
        public Boolean showCheckboxes{get;set;}
        @AuraEnabled
        public Boolean treatCheckboxesAsRadio{get;set;}
    }
    
    public class Header{
        @AuraEnabled
        public Decimal order;
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String fieldName {get;set;}
        @AuraEnabled
        public Decimal fixedWidth {get;set;}
        @AuraEnabled
        public Boolean sortable {get;set;}
        @AuraEnabled
        public String type {get;set;}
        @AuraEnabled
        public TypeAttributes typeAttributes;
        @AuraEnabled
        public Boolean wrapText {get;set;}
        @AuraEnabled
        public cellAttributes cellAttributes{get;set;}
        
        
        public Header(Decimal o, String l, String fn, boolean s, String t, TypeAttributes ta, Decimal iw){
            this.order = o;
            this.label = l;
            this.fieldName = fn;
            this.sortable = s;
            this.type = t;
            this.wrapText = true;
            if(type == 'url' || type == 'date-local' || type == 'action' || type == 'date'){
                this.typeAttributes = ta;
            }
            if(type == 'currency'){
                this.cellAttributes = new cellAttributes();
            }
            this.fixedWidth = iw != null ? iw : 150;
            //this.initialWidth = 400;
        }
    }
    
    public class TypeAttributes {
        @AuraEnabled
        public Label label{get;set;}
        @AuraEnabled
        public String day{get;set;}
        @AuraEnabled
        public String month{get;set;}
        @AuraEnabled
        public String year{get;set;}
        @AuraEnabled
        public String hour{get;set;}
        @AuraEnabled
        public String minute{get;set;}
        @AuraEnabled
        public String second{get;set;}
        @AuraEnabled
        public String timeZone{get;set;}
        @AuraEnabled
        public List<RowAction> rowActions {get;set;}
        
        
        // Default Constructor
        public TypeAttributes(){}
        
        public TypeAttributes(String d, String m, String y){
            this.day = d;
            this.month = m;
            this.year = y;
        }
        public TypeAttributes(String d, String m, String y,String hr, String min, String sec,String tz){
            this.day = d;
            this.month = m;
            this.year = y;
            this.hour = hr;
            this.minute = min;
            this.second = sec;
            this.timeZone = tz;
        }
    }
    
    public class Label{
        @AuraEnabled
        public String fieldName{get;set;}
        
        public Label(String fn){
            this.fieldName = fn;
        }
    }
    
    public class RowAction {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String name {get;set;}
        
        public RowAction(Data_Table_Content__mdt col) {
            this.label = col.MasterLabel;
            this.name = col.Field_API_Name__c;
        }
    }
    
    public class cellAttributes{
        @AuraEnabled
        public String alignment = 'left';
    }
    public class Action {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String type {get;set;}
        @AuraEnabled
        public String errorMessage {get;set;}
        @AuraEnabled
        public String successMessage {get;set;}
        @AuraEnabled
        public String sObjectAPIName {get;set;}
        @AuraEnabled
        public String defaultValues {get;set;}
        @AuraEnabled
        public String link{get;set;}
        @AuraEnabled
        public Boolean isShowModal {get;set;}
        @AuraEnabled
        public String enableFilterConditions {get;set;}
        @AuraEnabled
        public Boolean isEnable {get;set;}
        public Action(Data_Table_Action__mdt col) {
            this.label = col.MasterLabel;
            this.name = col.DeveloperName;
            this.errorMessage = col.Error_Message__c;
            this.successMessage = col.Success_Message__c;
            this.type = col.Type__c;
            this.sObjectAPIName = col.New_Record_sObject_API_Name__c;
            this.defaultValues = col.New_Record_Default_Values__c;
            this.link = col.Link__c;
            this.isShowModal = col.Is_Show_In_Modal__c;
            this.enableFilterConditions = col.Enable_Filter_Conditions__c;
            this.isEnable = true;
        }
    }
}