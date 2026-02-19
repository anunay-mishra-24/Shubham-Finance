/**
* Send Back Quick Action Controller
* Object: Application__c
* Stage field: Application_Stage__c
*
* Custom Metadata:
* 1) SHF_Stage_Setup__mdt: Stage_Value__c, Sequence__c, RecordType_DevName__c, Is_Active__c
* 2) SHF_SendBack_Reason__mdt: From_RecordType_DevName__c, To_RecordType_DevName__c, Reasons__c, Is_Active__c
*/
public without sharing class SHF_MovetoPreviousStages {

    // ---------- UI DTOs ----------
    public class Option {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public Option(String l, String v) { label = l; value = v; }
    }

    public class InitData {
        @AuraEnabled public String currentStage;
        @AuraEnabled public String currentRecordTypeDevName;
        @AuraEnabled public List<Option> stageOptions;
        @AuraEnabled public List<Option> userOptions;
    }

    // ---------- Config cache ----------
    private static Boolean CFG_LOADED = false;
    private static List<String> ORDERED_STAGES;
    private static Map<String, Integer> STAGE_TO_SEQ;
    private static Map<String, String> STAGE_TO_RT_DEVNAME;

    private static Boolean REASON_CFG_LOADED = false;
    private static Map<String, String> RT_PAIR_TO_REASONS_TEXT;

    // Stop list at Applicant Details (change if your picklist value differs)
    private static final String MIN_STAGE_VALUE = 'Applicant Details';

    // Same RecordType (only stage change) reasons
    private static final List<String> SAME_RT_REASONS = new List<String>{ 'Incomplete Details', 'Others' };

    // Profile filters (update if needed)
    // NOTE: '%' means LIKE. Without '%' means exact Profile.Name match.
    private static final List<String> ADMIN_PROFILE_FILTERS  = new List<String>{ 'System Administrator', '%Admin%' };
    private static final List<String> CREDIT_PROFILE_FILTERS = new List<String>{ 'Credit%', '%Credit%' };
    private static final List<String> SALES_PROFILE_FILTERS  = new List<String>{ 'Sales%', '%Sales%' };

    // Notifications / Email
    private static final String CUSTOM_NOTIFICATION_DEVNAME = 'Loan_Application_Send_Back'; // change if needed
    // private static final String EMAIL_TEMPLATE_DEVNAME = 'Loan_Application_Send_Back_Email'; // if you use template later

    // Optional fields (if exist) to store reason/remarks
    private static final String FIELD_REASON_API  = 'Send_Back_Reason__c';
    private static final String FIELD_REMARKS_API = 'Send_Back_Remarks__c';

    // ---------- Public APIs ----------
    @AuraEnabled
    public static InitData getInitData(Id applicationId) {
        if (applicationId == null) return new InitData();
        ensureStageConfigLoaded();

        Application__c app = [
            SELECT Id, OwnerId, Application_Stage__c, RecordType.DeveloperName
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        InitData dto = new InitData();
        dto.currentStage = normalize(app.Application_Stage__c);
        dto.currentRecordTypeDevName = normalize(app.RecordType != null ? app.RecordType.DeveloperName : null);

        dto.stageOptions = buildPreviousStageOptions(dto.currentStage);

        // initial user list based on current page(recordtype)
        dto.userOptions  = buildUserOptionsForRt(applicationId, app.OwnerId, dto.currentRecordTypeDevName);
        return dto;
    }

    @AuraEnabled
    public static List<Option> getUserOptions(Id applicationId, String targetStage) {
        if (applicationId == null) return new List<Option>();
        ensureStageConfigLoaded();

        Application__c app = [
            SELECT Id, OwnerId, RecordType.DeveloperName
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        String toStage = normalize(targetStage);
        String targetRtDev = normalize(STAGE_TO_RT_DEVNAME.get(toStage));

        // Fallback: if metadata missing for stage, use current recordtype
        if (String.isBlank(targetRtDev)) {
            targetRtDev = normalize(app.RecordType != null ? app.RecordType.DeveloperName : null);
        }

        return buildUserOptionsForRt(applicationId, app.OwnerId, targetRtDev);
    }

    @AuraEnabled
    public static List<Option> getReasonOptions(String fromStage, String toStage) {
        ensureStageConfigLoaded();
        ensureReasonConfigLoaded();

        String fs = normalize(fromStage);
        String ts = normalize(toStage);
        if (String.isBlank(fs) || String.isBlank(ts)) return new List<Option>();

        String fromRt = normalize(STAGE_TO_RT_DEVNAME.get(fs));
        String toRt   = normalize(STAGE_TO_RT_DEVNAME.get(ts));

        if (String.isBlank(fromRt) || String.isBlank(toRt)) return new List<Option>();

        // Same record type => fixed reasons
        if (equalsIgnoreCase(fromRt, toRt)) {
            return toOptions(SAME_RT_REASONS);
        }

        // Record type change => reasons from CMDT
        String key = makeRtPairKey(fromRt, toRt);
        String txt = RT_PAIR_TO_REASONS_TEXT.get(key);
        List<String> parsed = parseReasons(txt);
        return toOptions(parsed);
    }

    @AuraEnabled
    public static void sendBack(
        Id applicationId,
        String targetStage,
        Id targetUserId,
        String sendBackReason,
        String remarks
    ) {
        if (applicationId == null) throw new AuraHandledException('Application Id is missing.');
        if (String.isBlank(targetStage)) throw new AuraHandledException('Target Stage is mandatory.');
        if (targetUserId == null) throw new AuraHandledException('User is mandatory.');
        if (String.isBlank(remarks)) throw new AuraHandledException('Remarks is mandatory.');

        ensureStageConfigLoaded();
        ensureReasonConfigLoaded();

        // FLS checks
        if (!Schema.sObjectType.Application__c.isUpdateable()
            || !Schema.sObjectType.Application__c.fields.Application_Stage__c.isUpdateable()) {
            throw new AuraHandledException('You do not have permission to update Application Stage.');
        }
        if (!Schema.sObjectType.Application__c.fields.OwnerId.isUpdateable()) {
            throw new AuraHandledException('You do not have permission to change Owner.');
        }
        if (!Schema.sObjectType.Application__c.fields.RecordTypeId.isUpdateable()) {
            throw new AuraHandledException('You do not have permission to change Record Type.');
        }

        Savepoint sp = Database.setSavepoint();
        try {
            Application__c app = [
                SELECT Id, Name, OwnerId, Application_Stage__c, Sendback_From__c, RecordTypeId, RecordType.DeveloperName
                FROM Application__c
                WHERE Id = :applicationId
                LIMIT 1
                FOR UPDATE
            ];

            String fromStage = normalize(app.Application_Stage__c);
            String toStage   = normalize(targetStage);
            String reason     = normalize(sendBackReason);
            String sendBackRemarks   = normalize(remarks);
            Integer fromSeq = STAGE_TO_SEQ.get(fromStage);
            Integer toSeq   = STAGE_TO_SEQ.get(toStage);


            if (fromSeq == null) throw new AuraHandledException('Current stage is not configured in SHF_Stage_Setup__mdt.');
            if (toSeq == null)   throw new AuraHandledException('Target stage is not configured in SHF_Stage_Setup__mdt.');
            if (toSeq >= fromSeq) throw new AuraHandledException('You can only send back to a previous stage.');

            String targetRtDev = normalize(STAGE_TO_RT_DEVNAME.get(toStage));
            if (String.isBlank(targetRtDev)) {
                throw new AuraHandledException('RecordType DevName missing in metadata for stage: ' + toStage);
            }

            Id targetRtId = getRecordTypeIdByDevName(targetRtDev);
            if (targetRtId == null) {
                throw new AuraHandledException('RecordType not found/available for DevName: ' + targetRtDev);
            }

            String currentRtDev = normalize(app.RecordType != null ? app.RecordType.DeveloperName : null);

            // Validate reason
            List<String> allowed = getAllowedReasons(currentRtDev, targetRtDev);
            if (allowed.isEmpty()) {
                throw new AuraHandledException('No Send Back Reasons configured for this change.');
            }
            if (String.isBlank(sendBackReason)) {
                throw new AuraHandledException('Send Back Reason is mandatory.');
            }
            if (!allowed.contains(sendBackReason != null ? sendBackReason.trim() : sendBackReason)) {
                throw new AuraHandledException('Invalid Send Back Reason selected.');
            }

            // update record
            app.Application_Stage__c = toStage;
            app.RecordTypeId = targetRtId;
            if(targetRtId == SHF_ConstantsUtil.APPLICATION_CREDIT_EVALUATION_RECORD_TYPE){
                app.Application_Status__c  = 'Recommended';
            }
            app.OwnerId = targetUserId;
            app.Send_Back_Reason__c = reason;
            app.Send_Back_Remarks__c = sendBackRemarks;
            if (app.Sendback_From__c != null){
            app.Sendback_From__c = fromStage;
            }
            // optional store (only if field exists + updateable)
            setIfFieldExistsAndUpdateable(app, FIELD_REASON_API, sendBackReason);
            setIfFieldExistsAndUpdateable(app, FIELD_REMARKS_API, remarks);

            update app;

            // Flag financial applicants for FC re-validation after sendback
            List<Loan_Applicant__c> financialApplicants = [
                SELECT Id
                FROM Loan_Applicant__c
                WHERE Application__c = :applicationId
                AND IsFinancial_Applicant__c = 'Yes'
            ];
            for (Loan_Applicant__c la : financialApplicants) {
                la.Financial_Calculator_Changed_After_SB__c = true;
            }
            if (!financialApplicants.isEmpty()) {
                update financialApplicants;
            }

            // bell notification (non-blocking)
            try { sendCustomNotification(app, targetUserId, toStage); } catch (Exception ignoreNotif) {}

            // email (non-blocking)
            try { sendEmailToNewOwner(app, targetUserId, toStage, sendBackReason, remarks); } catch (Exception ignoreEmail) {}

        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ---------- Helpers ----------
    private static void ensureStageConfigLoaded() {
        if (CFG_LOADED) return;

        ORDERED_STAGES = new List<String>();
        STAGE_TO_SEQ = new Map<String, Integer>();
        STAGE_TO_RT_DEVNAME = new Map<String, String>();

        List<SHF_Stage_Setup__mdt> rows = [
            SELECT Stage_Value__c, Sequence__c, RecordType_DevName__c, Is_Active__c
            FROM SHF_Stage_Setup__mdt
            WHERE Is_Active__c = true
            ORDER BY Sequence__c ASC
        ];

        for (SHF_Stage_Setup__mdt r : rows) {
            String stage = normalize(r.Stage_Value__c);
            if (String.isBlank(stage) || r.Sequence__c == null) continue;

            if (STAGE_TO_SEQ.containsKey(stage)) {
                throw new AuraHandledException('Duplicate stage found in metadata: ' + stage);
            }

            Integer seq = Integer.valueOf(r.Sequence__c);
            String rtDev = normalize(r.RecordType_DevName__c);

            ORDERED_STAGES.add(stage);
            STAGE_TO_SEQ.put(stage, seq);
            STAGE_TO_RT_DEVNAME.put(stage, rtDev);
        }

        if (ORDERED_STAGES.isEmpty()) {
            throw new AuraHandledException('Stage Setup metadata is empty. Please configure SHF_Stage_Setup__mdt.');
        }

        CFG_LOADED = true;
    }

    private static void ensureReasonConfigLoaded() {
        if (REASON_CFG_LOADED) return;

        RT_PAIR_TO_REASONS_TEXT = new Map<String, String>();

        List<SHF_SendBack_Reason__mdt> rows = [
            SELECT From_RecordType_DevName__c, To_RecordType_DevName__c, Reasons__c, Is_Active__c
            FROM SHF_SendBack_Reason__mdt
            WHERE Is_Active__c = true
        ];

        for (SHF_SendBack_Reason__mdt r : rows) {
            String fromRt = normalize(r.From_RecordType_DevName__c);
            String toRt   = normalize(r.To_RecordType_DevName__c);
            String txt    = r.Reasons__c;

            if (String.isBlank(fromRt) || String.isBlank(toRt) || String.isBlank(txt)) continue;
            RT_PAIR_TO_REASONS_TEXT.put(makeRtPairKey(fromRt, toRt), txt);
        }

        REASON_CFG_LOADED = true;
    }

    private static List<Option> buildPreviousStageOptions(String currentStage) {
        List<Option> options = new List<Option>();
        if (String.isBlank(currentStage)) return options;

        Integer curSeq = STAGE_TO_SEQ.get(currentStage);
        if (curSeq == null) return options;

        Integer minSeq = STAGE_TO_SEQ.get(normalize(MIN_STAGE_VALUE)); // can be null

        for (Integer i = ORDERED_STAGES.size() - 1; i >= 0; i--) {
            String st = ORDERED_STAGES[i];
            Integer seq = STAGE_TO_SEQ.get(st);
            if (seq == null) continue;

            if (seq < curSeq) {
                if (minSeq != null && seq < minSeq) continue;
                options.add(new Option(st, st));
            }
        }
        return options;
    }

    private static List<Option> buildUserOptionsForRt(Id appId, Id excludeUserId, String rtDev) {
        if (isCreditEvaluation(rtDev)) {
            List<String> filters = mergeFilters(ADMIN_PROFILE_FILTERS, CREDIT_PROFILE_FILTERS);
            return buildUsersByProfileFilters(filters, excludeUserId);
        }
        if (isPreDisbursementOrQDE(rtDev)) {
            List<String> filters = mergeFilters(ADMIN_PROFILE_FILTERS, SALES_PROFILE_FILTERS);
            return buildUsersByProfileFilters(filters, excludeUserId);
        }
        return buildPreviousUserOptionsFromHistory(appId, excludeUserId);
    }

    // Supports exact Profile.Name and LIKE patterns (with %)
    private static List<Option> buildUsersByProfileFilters(List<String> filters, Id excludeUserId) {
        if (filters == null || filters.isEmpty()) return new List<Option>();

        List<String> conds = new List<String>();
        for (String f : filters) {
            if (String.isBlank(f)) continue;
            String esc = String.escapeSingleQuotes(f.trim());
            if (esc.contains('%')) conds.add('Profile.Name LIKE \'' + esc + '\'');
            else conds.add('Profile.Name = \'' + esc + '\'');
        }
        if (conds.isEmpty()) return new List<Option>();

        String soql =
            'SELECT Id, Name FROM User ' +
            'WHERE IsActive = true ' +
            'AND (' + String.join(conds, ' OR ') + ')';

        if (excludeUserId != null) {
            soql += ' AND Id != \'' + String.escapeSingleQuotes(String.valueOf(excludeUserId)) + '\'';
        }
        soql += ' ORDER BY Name LIMIT 5000';

        List<User> users = Database.query(soql);

        List<Option> out = new List<Option>();
        for (User u : users) out.add(new Option(u.Name, String.valueOf(u.Id)));
        return out;
    }

    // history-based users (previous worked users) => except current owner
    private static List<Option> buildPreviousUserOptionsFromHistory(Id appId, Id currentOwnerId) {
        Set<Id> userIds = new Set<Id>();

        List<Application__History> hist = [
            SELECT Field, OldValue, NewValue, CreatedById
            FROM Application__History
            WHERE ParentId = :appId
            ORDER BY CreatedDate DESC
            LIMIT 2000
        ];

        for (Application__History h : hist) {
            if (h.CreatedById != null) userIds.add(h.CreatedById);

            if (h.Field == 'Owner' || h.Field == 'OwnerId') {
                addIfId(userIds, h.OldValue);
                addIfId(userIds, h.NewValue);
            }
        }

        if (currentOwnerId != null) {
            try { userIds.remove((Id)currentOwnerId); } catch (Exception ignore) {}
        }

        if (userIds.isEmpty()) return new List<Option>();

        List<User> users = [
            SELECT Id, Name
            FROM User
            WHERE Id IN :userIds
            AND IsActive = true
            ORDER BY Name
        ];

        List<Option> out = new List<Option>();
        for (User u : users) out.add(new Option(u.Name, String.valueOf(u.Id)));
        return out;
    }

    // No String.matches usage => safe cast only
    private static void addIfId(Set<Id> setIds, Object v) {
        if (v == null) return;

        if (v instanceof Id) {
            setIds.add((Id)v);
            return;
        }

        String s = String.valueOf(v).trim();
        if (s.length() == 15 || s.length() == 18) {
            try { setIds.add((Id)s); } catch (Exception ignore) {}
        }
    }

    private static void sendCustomNotification(Application__c app, Id userId, String targetStage) {
        List<CustomNotificationType> types = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = :CUSTOM_NOTIFICATION_DEVNAME
            LIMIT 1
        ];
        if (types.isEmpty()) return;

        Messaging.CustomNotification n = new Messaging.CustomNotification();
        n.setNotificationTypeId(types[0].Id);
        n.setTargetId(app.Id);
        n.setTitle('Loan Application Sent Back');

        String body = 'Loan Application ' + app.Name + ' has been sent back to you at ' + targetStage;
        n.setBody(body);

        // Works in orgs where send(Set<String>) is supported
        n.send(new Set<String>{ String.valueOf(userId) });
    }

    private static void sendEmailToNewOwner(Application__c app, Id userId, String targetStage, String reason, String remarks) {
        User u = [SELECT Id, Email, Name FROM User WHERE Id = :userId LIMIT 1];
        if (String.isBlank(u.Email)) return;

        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setToAddresses(new String[]{ u.Email });
        msg.setSubject('Loan Application ' + app.Name + ' – Sent Back');

        String b = 'Dear ' + u.Name + ',\n\n'
            + 'Loan Application ' + app.Name + ' has been Sent Back to you.\n'
            + 'Loan Application Number: ' + app.Name + '\n'
            + 'Current Stage: ' + targetStage + '\n'
            + 'Remarks entered during Send Back: ' + remarks + '\n'
            + (String.isBlank(reason) ? '' : ('Reason selected from dropdown: ' + reason + '\n'))
            + 'Sent Back By: ' + UserInfo.getName() + '\n\n';

        msg.setPlainTextBody(b);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ msg });
    }

    private static List<String> getAllowedReasons(String fromRt, String toRt) {
        if (String.isBlank(fromRt) || String.isBlank(toRt)) return new List<String>();

        if (equalsIgnoreCase(fromRt, toRt)) {
            return new List<String>(SAME_RT_REASONS);
        }

        String txt = RT_PAIR_TO_REASONS_TEXT.get(makeRtPairKey(fromRt, toRt));
        return parseReasons(txt);
    }

    // supports comma OR newline separated
    private static List<String> parseReasons(String txt) {
        if (String.isBlank(txt)) return new List<String>();
        List<String> out = new List<String>();

        for (String p : txt.split('\\s*,\\s*|\\r?\\n')) {
            String r = p == null ? null : p.trim();
            if (!String.isBlank(r)) out.add(r);
        }
        return out;
    }

    private static List<Option> toOptions(List<String> values) {
        List<Option> out = new List<Option>();
        if (values == null) return out;
        for (String v : values) out.add(new Option(v, v));
        return out;
    }

    private static void setIfFieldExistsAndUpdateable(SObject sob, String fieldApi, Object value) {
        if (sob == null || String.isBlank(fieldApi)) return;
        Map<String, Schema.SObjectField> fm = Schema.sObjectType.Application__c.fields.getMap();
        if (fm != null && fm.containsKey(fieldApi)) {
            Schema.DescribeFieldResult d = fm.get(fieldApi).getDescribe();
            if (d != null && d.isUpdateable()) {
                sob.put(fieldApi, value);
            }
        }
    }

    // recordtype detection (robust)
    private static Boolean isCreditEvaluation(String rtDev) {
        String r = normalize(rtDev);
        if (String.isBlank(r)) return false;
        String low = r.toLowerCase();
        return low.contains('credit');
    }

    private static Boolean isPreDisbursementOrQDE(String rtDev) {
        String r = normalize(rtDev);
        if (String.isBlank(r)) return false;
        String low = r.toLowerCase();
        return low.contains('qde') || low.contains('pre') || low.contains('disb');
    }

    private static List<String> mergeFilters(List<String> a, List<String> b) {
        List<String> out = new List<String>();
        if (a != null) out.addAll(a);
        if (b != null) out.addAll(b);
        return out;
    }

    private static String makeRtPairKey(String fromRt, String toRt) {
        return normalize(fromRt) + '__' + normalize(toRt);
    }

    private static String normalize(String s) {
        return s == null ? null : s.trim();
    }

    private static Boolean equalsIgnoreCase(String a, String b) {
        if (a == null || b == null) return false;
        return a.trim().toLowerCase() == b.trim().toLowerCase();
    }

    private static Id getRecordTypeIdByDevName(String devName) {
        String dn = normalize(devName);
        if (String.isBlank(dn)) return null;

        Map<String, Schema.RecordTypeInfo> byDev =
            Application__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        if (byDev != null && byDev.containsKey(dn)) {
            Schema.RecordTypeInfo rti = byDev.get(dn);
            if (rti != null && rti.isAvailable()) return rti.getRecordTypeId();
        }
        return null;
    }
}