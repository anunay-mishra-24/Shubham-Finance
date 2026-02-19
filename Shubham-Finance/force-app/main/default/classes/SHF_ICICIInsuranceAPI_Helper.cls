/*
* @File Name       : SHF_ICICIInsuranceAPI_Helper.cls
* @Author          : Preeti
* @Created Date    : Sept 19, 2025
* @Description     : Helper class for ICICI Insurance API integration.
*                    Provides utility methods to parse XML responses from ICICI SOAP API 
*                    and extract required values.
* @Last Modified By: Preeti
* @Last Modified On: Sept 19, 2025
* @Modification Log:
*==============================================================================
* Ver | Date       | Author | Modification
*==============================================================================
* 1.0 | 19-Sept-25  | Preeti | Initial Version
*/


public class SHF_ICICIInsuranceAPI_Helper {
    
    /*
* @description Extracts the text value of a specified XML tag from a parent XML node.
*              Traverses child nodes and handles nested 'PremiumSummary' nodes.
* @param parent  - The parent Dom.XMLNode to search within.
* @param tagName - The name of the XML tag whose value is to be extracted.
* @return String - Text value of the specified tag, or null if not found or on error.
*/
    
    
    public static String getTagValue(Dom.XMLNode parent, String tagName) {
        try {
            system.debug('i');
            if (parent == null || String.isBlank(tagName)) {
                logger.error('Invalid parameters passed to getTagValue. parent: ' + parent + ', tagName: ' + tagName);
                return null;
            }
            
            List<Dom.XMLNode> nodesToCheck = new List<Dom.XMLNode>();
            for (Dom.XMLNode child : parent.getChildElements()) {
                nodesToCheck.add(child);
                if (child.getName() == 'PremiumSummary') {
                    nodesToCheck.addAll(child.getChildElements());
                }
            }
            
            for (Dom.XMLNode node : nodesToCheck) {
                if (node.getName() == tagName) {
                    return node.getText();
                }
            }
            return null;
        } catch (Exception e) {
            logger.error('Error in getTagValue for tagName ' + tagName + ': ' + e.getMessage());
            return null;
        } finally {
            logger.saveLog();
        }
    }
}