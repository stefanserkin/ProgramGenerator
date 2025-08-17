@IsTest
private class BatchUtilities_Test {

    private static final String APEX_JOB_ID = '707000000000000AAA';
    private static final String APEX_JOB_STATUS_COMPLETED = 'Completed';
    private static final String APEX_CLASS_NAME = 'ProgramGeneratorBatch';

    public class AsyncApexJobDTO {
        public String Id;
        public String Status;
        public Integer TotalJobItems;
        public Integer JobItemsProcessed;
        public Integer NumberOfErrors;
        public ApexClassDTO ApexClass;   
        public CreatedByDTO CreatedBy;
    }

    public class ApexClassDTO {
        public String Name;
    }

    public class CreatedByDTO {
        public String Email;
    }

    private static AsyncApexJob getTestAsyncApexJob() {
        AsyncApexJobDTO r = new AsyncApexJobDTO();
        r.Id = APEX_JOB_ID;
        r.Status = APEX_JOB_STATUS_COMPLETED;
        r.TotalJobItems = 10;
        r.JobItemsProcessed = 10;
        r.NumberOfErrors = 0;

        r.ApexClass = new ApexClassDTO();
        r.ApexClass.Name = APEX_CLASS_NAME;

        r.CreatedBy = new CreatedByDTO();
        r.CreatedBy.Email = UserInfo.getUserEmail();

        String asyncApexJobJson = JSON.serialize(r);
        AsyncApexJob job = (AsyncApexJob) JSON.deserialize(asyncApexJobJson, AsyncApexJob.class);
        return job;
    }

    @IsTest
    static void testValidateTestJob() {
        Test.startTest();
        AsyncApexJob apexJob = getTestAsyncApexJob();
        Test.stopTest();
        System.Assert.areEqual(APEX_JOB_ID, apexJob.Id, 'Received unexpected id for the apex job');
        System.Assert.areEqual(APEX_CLASS_NAME, apexJob.ApexClass.Name, 'Received unexpected class name for the apex job');
    }
    
    @IsTest
    static void testPublishBatchResultEvent() {
        AsyncApexJob apexJob = getTestAsyncApexJob();
        String resultString = 'Test result string';

        Test.startTest();
        Database.SaveResult sr = BatchUtilities.publishBatchResultEvent(apexJob, resultString);
        Test.stopTest();

        System.Assert.isTrue(sr.isSuccess(), 'Should have successfully published the event');
    }

    @IsTest
    static void testSendJobCreatorEmailResult() {
        AsyncApexJob apexJob = getTestAsyncApexJob();
        Boolean sentSuccessfully = false;

        Test.startTest();
        try {
            BatchUtilities.sendJobCreatorEmailResult(apexJob);
            sentSuccessfully = true;
        } catch (Exception e) {
            System.Assert.fail('Should have called the sendJobCreatorEmailResult() method without an exception');
        }
        Test.stopTest();

        System.Assert.isTrue(sentSuccessfully, 'Should have called the sendJobCreatorEmailResult() method without an exception');
    }

    @IsTest
    static void testGetAsyncApexJobById() {
        TREX1__Session__c session = TestDataFactory.createSessions(1).get(0);
        insert session;

        Staged_Program_Batch__c stagedProgramBatch = TestDataFactory.createStagedProgramBatches(session, 1).get(0);
        insert stagedProgramBatch;

        ProgramGeneratorBatch pgb = new ProgramGeneratorBatch(stagedProgramBatch.Id);

        Test.startTest();
        Id jobId = Database.executeBatch(pgb, 50);
        Test.stopTest();

        AsyncApexJob apexJob = BatchUtilities.getAsyncApexJobById(jobId);
        System.Assert.areEqual(jobId, apexJob.Id, 'Received incorrect apex job');
    }

    @IsTest
    static void testIsOrgEmailEnabled() {
        Boolean emailDeliverabilityEnabled = true;
        try {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.reserveMassEmailCapacity(1);
        } catch (System.NoAccessException e) {
            emailDeliverabilityEnabled = false;
        }

        Test.startTest();
        Boolean result = BatchUtilities.isOrgEmailEnabled();
        Test.stopTest();

        System.Assert.areEqual(emailDeliverabilityEnabled, result, 'Email deliverability should be ' + emailDeliverabilityEnabled);
    }

}