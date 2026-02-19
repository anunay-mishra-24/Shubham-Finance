/**
* @File Name          : SHF_RecordOutcomes_Service.cls
* @Description        : Record Outcome XML API to fetch the details and create E-Verification Record
* @Author             : Riteek Tiwari
*
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0         31-01-2026            Riteek Tiwari        Initial Version
*/
public with sharing class SHF_RecordOutcomes_Service {

    SHF_HTTPCalloutService service;
    public static String callRecordOutcome(Id loanApplicantId, String finalDecision) {

        String message = '';
        Savepoint sp;

        try {
            Map<String, Messages_Config__mdt> messageConfigMap = SHF_CommonUtil.getMessageRecord('Record_Outcome_API');
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ E_Verification__c.SObjectType });
            Loan_Applicant__c applicant = new SHF_LoanApplicantsSelector().selectById(new Set<Id>{ loanApplicantId })[0];

            if (applicant == null) {
                return messageConfigMap.get('Applicant_Not_Found').Message__c;
            }

            SHF_RecordOutcomes_Service recordOutcomeService = new SHF_RecordOutcomes_Service();
            recordOutcomeService.service = new SHF_HTTPCalloutService('Record_Outcome_API');

            String requestBody = recordOutcomeService.service.getRequestBody();
            requestBody = requestBody.replace('<username>', 'SHDFC_SERVICES');
            requestBody = requestBody.replace('<password>', 'Experian.1');
            requestBody = requestBody.replace('<identifier>', applicant.Name);
            requestBody = requestBody.replace('<note>', 'Testing SOAP Call for ' + applicant.Name);
            requestBody = requestBody.replace('<privacy>', 'PUBL');
            requestBody = requestBody.replace('<workStatus>', 'WORKED');
            requestBody = requestBody.replace('<reason>', 'NC21');
            requestBody = requestBody.replace('<fraudStatus>', finalDecision);
            
            recordOutcomeService.service.setHeaderParameter('Content-Type', 'text/xml; charset=UTF-8');
            recordOutcomeService.service.requestCertificate = 'HunterClientCert';

            recordOutcomeService.service.setRequestBody(requestBody);

            HttpResponse response;
            if (recordOutcomeService.service.getIsActive()) {
                response = recordOutcomeService.service.sendRequest();
                sp = Database.setSavepoint();
            } else {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody(recordOutcomeService.service.getmockRespnse());
            }

            // Create E_Verification record
            E_Verification__c Everification = SHF_CommonUtil.createVerfication(applicant.Id, SHF_ConstantsUtil.DISCOVER_RECORD_TYPE, SHF_ConstantsUtil.INPROGRESS_STATUS);

            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {

                Everification.Raw_Response__c = response.getBody();

                Dom.Document doc = new Dom.Document();
                doc.load(response.getBody());

                Dom.XmlNode root = doc.getRootElement();
                Dom.XmlNode body = root.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');
                Dom.XmlNode actionAllEntities = body.getChildElement('ActionAllEntitiesResponse', null);
                if(actionAllEntities == null) {
                    actionAllEntities = body.getChildElement('ActionAllEntitiesResult', null);
                }

                if (actionAllEntities != null) {
                    Everification.Message__c = actionAllEntities.getText() != null ? actionAllEntities.getText() : 'Response Received';
                }

                message = messageConfigMap.get('Record_Outcome_SUCCESS').Message__c;

            } else {
                message = messageConfigMap.get('Record_Outcome_ERROR').Message__c;
            }

            uow.registerNew(Everification);
            uow.commitWork();

            Logger.info('RecordOutcome Request :: ' + requestBody);
            Logger.info('RecordOutcome Response :: ' + response.getBody());

        } catch (Exception ex) {
            if (sp != null) Database.rollback(sp);
            Logger.error('RecordOutcome API Error :: ' + ex.getMessage());
        } finally {
            Logger.saveLog();
        }

        return message;
    }
}