/*
* @File Name         : SHF_XmlToJsonParser.cls
* @Author            : Preeti
* @Created Date      : July 11, 2025
* @Description       : This utility class is responsible for parsing HIGHMARK XML responses
*                      and converting <LOAN-DETAILS> sections into a list of key-value maps
*                      for further processing into obligations.
* @Last Modified By  : Preeti
* @Last Modified On  : July 11, 2025
* @Modification Log  :
*==============================================================================
* Ver | Date         | Author | Modification
*==============================================================================
* 1.0 | July 11, 2025 | Preeti | Initial Version
*/



public with sharing class SHF_XmlToJsonParser {
// MAIN METHOD
    public static String convertXmlToJson(String xmlString) {
          Object result;
try{
        Dom.Document doc = new Dom.Document();
        doc.load(xmlString);

        Dom.XmlNode root = doc.getRootElement();

        // Convert recursively to a Map<String, Object>
         result = parseNode(root);
    }catch(exception ex){
          system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
        }

        // Serialize to JSON
        return JSON.serialize(result);
    }

    // RECURSIVE PARSER
    private static Object parseNode(Dom.XmlNode node) {
        // If node has no children -> return its text or CDATA
         Map<String, Object> jsonObj = new Map<String, Object>();
        try{
        if (node.getChildElements().isEmpty()) {
            return node.getText().trim();
        }

       

        for (Dom.XmlNode child : node.getChildElements()) {

            String tag = child.getName();
            Object parsed = parseNode(child);

            // Handle repeated elements → convert to List
            if (jsonObj.containsKey(tag)) {
                // Already exists → must convert to list
                Object existing = jsonObj.get(tag);

                if (existing instanceof List<Object>) {
                    ((List<Object>)existing).add(parsed);
                } else {
                    List<Object> lst = new List<Object>();
                    lst.add(existing);
                    lst.add(parsed);
                    jsonObj.put(tag, lst);
                }
            } else {
                jsonObj.put(tag, parsed);
            }
        }
        }catch(exception ex){
          system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
        }

        return jsonObj;
    }

     /**
     * Removes <PRINTABLE-REPORT> ... </PRINTABLE-REPORT> section from XML
     */
    public static String removePrintableReport(String xmlInput) {
        system.debug('xmlInput>>> ' + xmlInput);
        String cleanedXml = '';
        try{
        if (String.isBlank(xmlInput)) {
            return xmlInput;
        }

        // Regex to remove entire node including content
        String regexPattern = '<PRINTABLE-REPORT>[\\s\\S]*?</PRINTABLE-REPORT>';

        // Replace the whole block with an empty string
         cleanedXml = xmlInput.replaceAll(regexPattern, '');
        system.debug('xmlInput>>>1 ' + cleanedXml);
        }catch(exception ex){
          system.debug('error> ' + ex.getMessage()+' Line:- '+ ex.getlineNumber());
        }
        return cleanedXml;
    }






    
    /*
* Parses HIGHMARK XML string to extract all <LOAN-DETAILS> blocks inside <INDV-REPORT> nodes.
* @param xmlData The raw HIGHMARK XML string from the bureau API response.
* @return A list of maps, where each map contains field name-value pairs from <LOAN-DETAILS>.
*/
    
 /*   public static List<Map<String, Object>> parseAllHighmarkLoans(String xmlData) {
        System.debug('#Raw XML Data: ' + xmlData);
        
        List<Map<String, Object>> loanList = new List<Map<String, Object>>();
        Dom.Document doc = new Dom.Document();
       
        // Load the XML data into a DOM document
        try {
            doc.load(xmlData);
        } catch (Exception ex) {
            System.debug('#XML Parsing Failed: ' + ex.getMessage());
            return loanList;
        }
        
        
        // Get the root element (<INDV-REPORT-FILE>)
        Dom.XmlNode root = doc.getRootElement();
        Dom.XmlNode reportsNode = root.getChildElement('INDV-REPORTS', null);
        
        if (reportsNode == null) {
            return loanList;
        }
        
        List<Dom.XmlNode> reports = reportsNode.getChildElements();
        System.debug('#Number of <INDV-REPORT> elements' + reports.size());
        
        Integer reportIndex = 0;
        for (Dom.XmlNode report : reports) {
            reportIndex++;
            Map<String, Object> loanMap = parseLoanDetails(report, reportIndex);
            
            if (!loanMap.isEmpty()) {
                loanList.add(loanMap);
                System.debug('#Added loanMap' + reportIndex + ': ' + JSON.serializePretty(loanMap));
            }
        }
        
        System.debug('#Total Loans Parsed' + loanList.size());
        return loanList;
    }
    
    
    /*
* Parses a single <INDV-REPORT> node to extract key-value pairs from its <LOAN-DETAILS> block.
* @param report A Dom.XmlNode representing the <INDV-REPORT> block.
* @param index  The index of the report being parsed.
* @return A map of field names and values from <LOAN-DETAILS>.
/
    
    private static Map<String, Object> parseLoanDetails(Dom.XmlNode report, Integer index) {
        Map<String, Object> loanMap = new Map<String, Object>();
        
        // Locate the <LOAN-DETAILS> node within the current report
        Dom.XmlNode loanNode = report.getChildElement('LOAN-DETAILS', null);
        
        if (loanNode == null) {
            System.debug('#LOAN-DETAILS not found' + index);
            return loanMap;
        }
        
        List<Dom.XmlNode> loanFields = loanNode.getChildElements();
        System.debug('#Parsing LOAN-DETAILS' + index);
        
        // Add each field in <LOAN-DETAILS> to the map
        for (Dom.XmlNode child : loanFields) {
            loanMap.put(child.getName(), child.getText());
            System.debug(' - ' + child.getName() + ': ' + child.getText());
        }
        
        return loanMap;
    }*/



}