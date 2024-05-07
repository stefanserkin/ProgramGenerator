public with sharing class ProgramGeneratorBatch implements Database.Batchable<sObject> {

    private static final String BATCH_NAME = 'Program Generator Batch';
    private static final String STATUS_STAGED = 'Staged';
    private static String query = 'SELECT Id FROM Staged_Program__c WHERE Status__c = :STATUS_STAGED';
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Staged_Program__c> lstStagedPrograms) {
        Set<Id> setStagedProgramIds = new Set<Id>();
        for (Staged_Program__c sp : lstStagedPrograms) {
            setStagedProgramIds.add(sp.Id);
        }
        ProgramGeneratorService service = new ProgramGeneratorService(setStagedProgramIds);
        service.run();
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob apexJob = [
            SELECT Id, 
                   Status, 
                   NumberOfErrors, 
                   JobItemsProcessed, 
                   TotalJobItems, 
                   CreatedBy.Email
              FROM AsyncApexJob 
             WHERE Id = :bc.getJobId()
        ];
        
        // Send email to job creator with batch results
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {apexJob.CreatedBy.Email};
        email.setToAddresses(toAddress);
        email.setSubject(apexJob.Status + ': ' + BATCH_NAME);
        email.setPlainTextBody('The ' + BATCH_NAME + ' ran and processed ' + apexJob.TotalJobItems + ' batches with ' + apexJob.NumberOfErrors + ' failures. Job Id: ' + apexJob.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

}