public without sharing class ProgramGeneratorBatch implements Database.Batchable<sObject>, Database.Stateful {

    private static final String BATCH_NAME = 'Program Generator Batch';
    private static final String STATUS_STAGED = 'Staged';
    private static final String STATUS_COMPLETE = 'Complete';
    private static final String STATUS_PROCESSING = 'Processing';
    private static final String STATUS_PROCESSED = 'Processed';
    private static final String STATUS_FAILED = 'Processed with Errors';

    private static String query = 'SELECT Id FROM Staged_Program__c WHERE Staged_Program_Batch__c = :stagedProgramBatchId AND Status__c = :STATUS_STAGED';

    private Id stagedProgramBatchId;
    private Boolean isProcessing = false;
    private List<TREX1__Course_Option__c> courseOptions;
    private List<String> errorMessages = new List<String>();

    public ProgramGeneratorBatch(Id stagedProgramBatchId) {
        this.stagedProgramBatchId = stagedProgramBatchId;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Staged_Program__c> lstStagedPrograms) {
        if (!this.isProcessing) {
            update (new Staged_Program_Batch__c(Id = this.stagedProgramBatchId, Status__c = STATUS_PROCESSING));
            this.isProcessing = true;
        }

        if (this.courseOptions == null) {
            this.courseOptions = new List<TREX1__Course_Option__c>();
        }

        Set<Id> setStagedProgramIds = new Set<Id>();
        for (Staged_Program__c sp : lstStagedPrograms) {
            setStagedProgramIds.add(sp.Id);
        }

        ProgramGeneratorService service = new ProgramGeneratorService(setStagedProgramIds);
        try {
            List<TREX1__Course_Option__c> lstOptions = service.run();
            this.courseOptions.addAll(lstOptions);
        } catch (Exception e) {
            errorMessages.add('Error Type: ' + e.getTypeName() + '. ' + e.getCause() + ': ' + e.getMessage());
            /*
            Staged_Program_Batch__c spBatch = new Staged_Program_Batch__c();
            spBatch.Id = this.stagedProgramBatchId;
            spBatch.Status__c = STATUS_FAILED;
            spBatch.Error_Log__c = e.getMessage();
            Database.update(spBatch, AccessLevel.SYSTEM_MODE);
            */
        }
    }

    public void finish(Database.BatchableContext bc) {
        Staged_Program_Batch__c batch = [
            SELECT Id, Status__c, Batch_Completed_Date_Time__c, 
                   (SELECT Id FROM Staged_Programs__r WHERE Status__c != :STATUS_PROCESSED)
              FROM Staged_Program_Batch__c
             WHERE Id = :stagedProgramBatchId
             LIMIT 1
        ];

        if (batch.Staged_Programs__r.isEmpty()) {
            batch.Status__c = STATUS_COMPLETE;
            batch.Batch_Completed_Date_Time__c = System.now();
            Database.update(batch, AccessLevel.SYSTEM_MODE);
        }

        if (!Test.isRunningTest() && !this.courseOptions.isEmpty()) {
            TRecCourseOptionBookingBatch bookingBatch = new TRecCourseOptionBookingBatch(
                this.courseOptions,
                this.stagedProgramBatchId
            );
            Database.executeBatch(bookingBatch, 50);
        }

        AsyncApexJob apexJob = BatchUtilities.getAsyncApexJobById(bc.getJobId());
        BatchUtilities.sendJobCreatorEmailResult(apexJob);
    }

}