public with sharing class StagedProgramEditorController {
    
    @AuraEnabled
    public static List<Staged_Program__c> getStagedPrograms(Id recordId) {
        try {
            return [
                SELECT Id, 
                       Status__c, 
                       Location__c, 
                       Program__c, 
                       Course__c, 
                       Course_Session_Name__c, 
                       Course_Option_Name__c
                  FROM Staged_Program__c
                 WHERE Staged_Program_Batch__c = :recordId
                  WITH USER_MODE
                 LIMIT 2000
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String updateStagedPrograms() {
        try {
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String deleteStagedPrograms() {
        try {
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}