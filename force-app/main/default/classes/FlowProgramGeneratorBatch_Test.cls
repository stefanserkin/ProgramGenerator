@IsTest
private class FlowProgramGeneratorBatch_Test {

    @TestSetup
    static void makeData() {
        TREX1__Program__c program = TestDataFactory.createTractionRecProgramLibrary();
        TREX1__Session__c session = [SELECT Id, Name FROM TREX1__Session__c LIMIT 1];
        Staged_Program_Batch__c batch = TestDataFactory.createStagedProgramBatches(session, 1).get(0);
        insert batch;
        List<Staged_Program__c> stagedPrograms = TestDataFactory.createStagedPrograms(batch, program, 5);
        insert stagedPrograms;
    }

    @IsTest
    static void testRunBatch() {
        Staged_Program_Batch__c batch = [SELECT Id FROM Staged_Program_Batch__c LIMIT 1];

        List<FlowProgramGeneratorBatch.Result> results;
        Test.startTest();
        FlowProgramGeneratorBatch.Request request = new FlowProgramGeneratorBatch.Request();
        request.batchId = batch.Id;
        results = FlowProgramGeneratorBatch.runProgramGeneratorBatch(
            new List<FlowProgramGeneratorBatch.Request>{ request }
        );
        Test.stopTest();

        Assert.isNotNull(results[0].jobId, 'Should have received a job id for the processing batch');
    }
    
}