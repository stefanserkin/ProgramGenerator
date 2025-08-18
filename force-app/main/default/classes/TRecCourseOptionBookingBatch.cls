public without sharing class TRecCourseOptionBookingBatch implements Database.Batchable<sObject>, Database.Stateful {

    private static final String BATCH_NAME = 'TRecCourseOptionBookingBatch';
    private static final String ADMIN_EMAIL = 'sserkin@asphaltgreen.org';
    
    private List<sObject> source;
    private Id stagedProgramBatchId;

    public TRecCourseOptionBookingBatch(List<sObject> source) {
        this.source = source;
    }

    public TRecCourseOptionBookingBatch(List<sObject> source, Id stagedProgramBatchId) {
        this.source = source;
        this.stagedProgramBatchId = stagedProgramBatchId;
    }

    public Iterable<sObject> start(Database.BatchableContext BC) {
        BatchSObjectFeeder bsof = new BatchSObjectFeeder(source);
        return bsof;
    }

    public void execute(Database.BatchableContext BC, List<TREX1__Course_Option__c> scope) {
        Set<Id> courseOptionIds = new Set<Id>();
        for (TREX1__Course_Option__c co : scope) {
            courseOptionIds.add(co.Id);
        }

        List<TREX1__Booking__c> lstBookings = TRecCourseOptionBookingHandler.createBookingsForCourseOptions(
            courseOptionIds,
            this.stagedProgramBatchId
        );
        insert lstBookings;
    }

    public void finish(Database.BatchableContext BC) {
        BatchUtilities.sendJobCreatorEmailResult(bc.getJobId());
    }

}