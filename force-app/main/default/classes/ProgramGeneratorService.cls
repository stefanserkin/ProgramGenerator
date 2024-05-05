public with sharing class ProgramGeneratorService {

    private List<Staged_Program__c> stagedPrograms;
    private Map<Id, TREX1__Session__c> mapSessions;
    private Map<String, TREX1__Course_Session__c> mapCourseSessions = new Map<String, TREX1__Course_Session__c>();

    public ProgramGeneratorService(Set<Id> stagedProgramIds) {
        this.stagedPrograms = queryForStagedPrograms(stagedProgramIds);
    }

    /**
     * @description Main entry point for processing staged programs.
     * Processes staged programs provided in constructor
     * @returns void
     */
    public void run() {
        // Add pre-existing course sessions to map
        Map<String, TREX1__Course_Session__c> mapCourseSessions = getCourseSessionMap();

    }

    private Map<String, TREX1__Course_Session__c> getCourseSessionMap() {
        // Get existing course sessions from course session keys
        Map<String, Staged_Program__c> mapCsKeyToStagedProgram = new Map<String, Staged_Program__c>();
        for (Staged_Program__c sp : stagedPrograms) {
            mapCsKeyToStagedProgram.put(sp.Course_Session_Key__c, sp);
        }
        for (TREX1__Course_Session__c cs : queryForCourseSessions(mapCsKeyToStagedProgram.keySet())) {
            mapCourseSessions.put(cs.Name, cs);
        }

        // Create new course sessions for remaining course session keys
        List<Staged_Program__c> lstSpsWithNewCs = new List<Staged_Program__c>();
        for (String csKey : mapCsKeyToStagedProgram.keySet()) {
            if (!mapCourseSessions.containsKey(csKey)) {
                lstSpsWithNewCs.add(mapCsKeyToStagedProgram.get(csKey));
            }
        }
        for (TREX1__Course_Session__c newCs : createNewCourseSessions(lstSpsWithNewCs)) {
            mapCourseSessions.put(newCs.Name, newCs);
        }

        // Return course session map
        return mapCourseSessions;
    }

    private List<TREX1__Course_Session__c> createNewCourseSessions(
        List<Staged_Program__c> lstStagedPrograms
    ) {
        List<TREX1__Course_Session__c> lstCourseSessions = new List<TREX1__Course_Session__c>();
        for (Staged_Program__c newCsSp : lstStagedPrograms) {
            TREX1__Course_Session__c newCs = new TREX1__Course_Session__c(
                Name = newCsSp.Course_Session_Name__c,
                TREX1__Course__c = newCsSp.Course__c,
                TREX1__Session__c = newCsSp.Session__c
            );
            lstCourseSessions.add(newCs);
        }
        return lstCourseSessions;
    }

    private List<TREX1__Course_Session__c> queryForCourseSessions(
        Set<String> setCourseSessionKeys
    ) {
        return [
            SELECT Id, 
                   Name, 
                   Key__c
              FROM TREX1__Course_Session__c 
             WHERE Key__c IN :setCourseSessionKeys
              WITH USER_MODE
        ];
    }

    private Map<Id, TREX1__Session__c> getSessionMap() {
        if (mapSessions == null) {
            Set<Id> setSessionIds = new Set<Id>();
            for (Staged_Program__c sp : stagedPrograms) {
                setSessionIds.add(sp.Session__c);
            }
            mapSessions = new Map<Id, TREX1__Session__c>([
                SELECT Id,
                       Name,
                       BPC_Free_Membership_Type__c,
                       UES_Free_Membership_Type__c,
                       TREX1__Start_Date__c,
                       TREX1__End_Date__c,
                       TREX1__Register_From_Date__c,
                       TREX1__Register_To_Date__c,
                       TREX1__Register_From_Time__c,
                       TREX1__Register_To_Time__c,
                       TREX1__Register_Online_From_Date__c,
                       TREX1__Register_Online_To_Date__c,
                       TREX1__Register_Online_From_Time__c,
                       TREX1__Register_Online_To_Time__c
                  FROM TREX1__Session__c
                 WHERE Id IN :setSessionIds
            ]);
        }
        return mapSessions;
    }

    private List<Staged_Program__c> queryForStagedPrograms(
        Set<Id> stagedProgramIds
    ) {
        return [
            SELECT Id,
                   Status__c,
                   Error_Message__c,
                   Program__c,
                   Course__c,
                   GL_Account__c,
                   Session__c,
                   Primary_Facility__c,
                   Location__c,
                   Start_Date__c,
                   End_Date__c,
                   Start_Time__c,
                   End_Time__c,
                   Exception_Dates__c,
                   Days_of_Week__c,
                   Capacity__c,
                   Minimum_Participants__c,
                   Minimum_Age__c,
                   Maximum_Age__c,
                   Public_Price__c,
                   Member_Price__c,
                   Has_Member_Price__c,
                   Price_Level_Key__c,
                   Course_Session_Name__c,
                   Course_Session_Key__c,
                   Course_Option_Name__c,
                   Course_Option_Code__c,
                   Course_Session__c,
                   Course_Option__c
              FROM Staged_Program__c
             WHERE Id IN :stagedProgramIds
              WITH USER_MODE
             LIMIT 200
        ];
    }

}