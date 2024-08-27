public with sharing class TRecCourseOptionBookingBatch implements Database.Batchable<sObject> {

    private static final String BATCH_NAME = 'TRecCourseOptionBookingBatch';
    
    private List<sObject> source;

    public TRecCourseOptionBookingBatch(List<sObject> source) {
        this.source = source;
    }

    public Iterable<sObject> start(Database.BatchableContext BC) {
        BatchSObjectFeeder bsof = new BatchSObjectFeeder(source);
        return bsof;
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> courseOptionIds = new Set<Id>();
        for (sObject obj : scope) {
            TREX1__Course_Option__c co = (TREX1__Course_Option__c) obj;
            courseOptionIds.add(co.Id);
        }

        List<TREX1__Booking__c> lstBookings = TRecCourseOptionBookingHandler.createBookingsForCourseOptions(courseOptionIds);
        insert lstBookings;
    }

    public void finish(Database.BatchableContext BC) {
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