public with sharing class DaysToAddCalculatorController {

    private static final String STATUS_CANCELLED = 'Cancelled';
    
    @AuraEnabled(cacheable=true)
    public static TREX1__Course_Option__c getSampleCourseOption(Id programId, Id sessionId) {
        try {
            return [
                SELECT Id, Name, TREX1__Start_Date__c
                  FROM TREX1__Course_Option__c
                 WHERE TREX1__Status__c != :STATUS_CANCELLED
                   AND Id IN (SELECT TREX1__Course_Option__c 
                                FROM TREX1__Course_Session_Option__c
                               WHERE TREX1__cso_Course_Session__r.TREX1__Course__r.TREX1__Program__c = :programId
                                 AND TREX1__cso_Course_Session__r.TREX1__Session__c = :sessionId)
                  WITH USER_MODE
                 ORDER BY TREX1__Start_Date__c ASC
                 LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}