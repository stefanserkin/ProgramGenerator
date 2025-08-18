@IsTest 
private class TRecCourseOptionBookingBatch_Test {

    @TestSetup
    static void makeData() {
        TREX1__Program__c program = TestDataFactory.createTractionRecProgramLibrary();
        TREX1__Session__c session = [SELECT Id, Name FROM TREX1__Session__c LIMIT 1];
        Staged_Program_Batch__c batch = TestDataFactory.createStagedProgramBatches(session, 1).get(0);
        insert batch;
    }

    @IsTest
    static void testCourseOptionBookingBatch() {
        List<TREX1__Course_Option__c> courseOptions = [SELECT Id FROM TREX1__Course_Option__c];

        Id jobId;
        Test.startTest();
        TRecCourseOptionBookingBatch batch = new TRecCourseOptionBookingBatch(courseOptions);
        jobId = Database.executeBatch(batch);
        Test.stopTest();

        System.Assert.isNotNull(jobId, 'Should have received a job id');
    }

    @IsTest
    static void testCourseOptionBookingBatchForStagedPrograms() {
        List<TREX1__Course_Option__c> courseOptions = [SELECT Id FROM TREX1__Course_Option__c];
        Staged_Program_Batch__c spb = [SELECT Id FROM Staged_Program_Batch__c LIMIT 1];

        Id jobId;
        Test.startTest();
        TRecCourseOptionBookingBatch batch = new TRecCourseOptionBookingBatch(courseOptions, spb.Id);
        jobId = Database.executeBatch(batch);
        Test.stopTest();

        System.Assert.isNotNull(jobId, 'Should have received a job id');
    }

}