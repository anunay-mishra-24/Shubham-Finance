/*
* @Author             : Riteek Tiwari
* @Created On         : 04 Sep 2025
* @Description        : Handles inbound emails to update CRIF_Score__c for multiple Leads if missing CSV (text + binary) attachments with comma/tab delimiter.
*============================================================================== 
* Ver         Date                     Author                 Modification
*============================================================================== 
* 1.6       06 Sep 2025           Riteek Tiwari             
*/
global class SHF_EmailServices implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            if (email == null) {
                Logger.info('Email is null. Exiting.');
                return result;
            }

            // Initialize Unit of Work
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new Schema.SObjectType[] { Lead__c.SObjectType });

            // Extract LeadId -> CRIF_Score mapping from attachments
            Map<Id, Decimal> leadIdToScoreMap = extractScoresFromAttachments(email);
            if (!leadIdToScoreMap.isEmpty()) {
                List<Lead__c> leadsToUpdate = new SHF_LeadSelector().selectByIdsForCrifScore(leadIdToScoreMap.keySet());
                Logger.info('Fetched ' + leadsToUpdate.size() + ' Leads to update.');

                Integer updatedCount = 0;
                for (Lead__c ld : leadsToUpdate) {
                    Decimal score = leadIdToScoreMap.get(ld.Id);
                    if (ld.CRIF_Score__c == null && score != null) {
                        ld.CRIF_Score__c = score;
                        uow.registerDirty(ld);
                        updatedCount++;
                    }
                }

                if (updatedCount > 0) {
                    uow.commitWork();
                    Logger.info('Updated ' + updatedCount + ' Leads from email attachments.');
                } else {
                    Logger.info('No Leads required update.');
                }
            } else {
                Logger.info('No valid LeadId->CRIF_Score mappings found in attachments.');
            }
        } catch (Exception ex) {
            Logger.error('Error processing inbound email: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }

        return result;
    }
    
    //* Extract LeadId -> CRIF_Score mapping from all attachments (CSV or Excel)
    private Map<Id, Decimal> extractScoresFromAttachments(Messaging.InboundEmail email) {
        Map<Id, Decimal> leadIdToScore = new Map<Id, Decimal>();

        try {
            if (email.textAttachments != null) {
                for (Messaging.InboundEmail.TextAttachment txtAttach : email.textAttachments) {
                    if (!String.isBlank(txtAttach.body)) {
                        parseCsvContent(txtAttach.body, leadIdToScore);
                        Logger.info('Processed text attachment: ' + txtAttach.fileName);
                    }
                }
            }

            // Binary attachments (CSV or Excel)
            if (email.binaryAttachments != null) {
                for (Messaging.InboundEmail.BinaryAttachment binAttach : email.binaryAttachments) {
                    if (binAttach != null && binAttach.Body != null) {
                        String fileName = binAttach.fileName != null ? binAttach.fileName.toLowerCase() : '';

                        if (fileName.endsWith('.csv')) {
                            String csvContent = binAttach.Body.toString();
                            parseCsvContent(csvContent, leadIdToScore);
                            Logger.info('Processed CSV binary attachment: ' + binAttach.fileName);
                        } 
                        else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
                            Logger.info('Excel file received: ' + binAttach.fileName);
                        }
                    }
                }
            }
        } catch (Exception ex) {
            Logger.error('Error extracting attachments: ' + ex.getMessage());
        }

        return leadIdToScore;
    }

   //* Helper: Parse CSV content into LeadId -> CRIF_Score map
    private void parseCsvContent(String csvContent, Map<Id, Decimal> leadIdToScore) {
        List<String> lines = csvContent.split('\n');
        if (lines.size() <= 1) return;

        try {
            // Detect delimiter: tab or comma
            String delimiter = lines[0].contains('\t') ? '\t' : ',';

            // Parse header
            List<String> headers = lines[0].split(delimiter);
            Integer leadIdIndex = -1;
            Integer scoreIndex = -1;

            for (Integer i = 0; i < headers.size(); i++) {
                String header = headers[i].trim();
                if (header.equalsIgnoreCase('LeadId') || header.equalsIgnoreCase('Lead: ID') || header.equalsIgnoreCase('Id')) {
                    leadIdIndex = i;
                }
                if (header.equalsIgnoreCase('CRIF_Score__c') || header.equalsIgnoreCase('CRIF Score')) {
                    scoreIndex = i;
                }
            }

            if (leadIdIndex == -1 || scoreIndex == -1) {
                Logger.warn('Required columns LeadId and CRIF Score not found in CSV.');
                return;
            }

            for (Integer i = 1; i < lines.size(); i++) {
                String line = lines[i].trim();
                if (String.isBlank(line)) continue;

                List<String> cols = line.split(delimiter);
                if (cols.size() > Math.max(leadIdIndex, scoreIndex)) {
                    String leadIdStr = cols[leadIdIndex].trim();
                    String scoreStr  = cols[scoreIndex].trim();

                    try {
                        Id leadId = (Id) leadIdStr;
                        Decimal score = Decimal.valueOf(scoreStr);
                        leadIdToScore.put(leadId, score);
                    } catch (Exception ex) {
                        Logger.warn('Skipping invalid CSV row: ' + line + ' Error: ' + ex.getMessage());
                    }
                }
            }
        } catch (Exception ex) {
            Logger.error('Error parsing CSV content: ' + ex.getMessage());
        }
    }
}