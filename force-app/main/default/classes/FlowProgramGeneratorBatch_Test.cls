@IsTest
private class FlowProgramGeneratorBatch_Test {

    private static List<FlowProgramGeneratorBatch.Result> results;
    private static List<FlowProgramGeneratorBatch.Request> requests = new List<FlowProgramGeneratorBatch.Request>();
    private static FlowProgramGeneratorBatch.Request request = new FlowProgramGeneratorBatch.Request();

    @TestSetup
    static void makeData() {
        TREX1__Program__c program = TestDataFactory.createTractionRecProgramLibrary();

        TREX1__Session__c session = [SELECT Id, Name FROM TREX1__Session__c LIMIT 1];

        insert TestDataFactory.createProgramGeneratorSettings();

        Staged_Program_Batch__c batch = TestDataFactory.createStagedProgramBatches(session, 1).get(0);
        insert batch;

        List<Staged_Program__c> stagedPrograms = TestDataFactory.createStagedPrograms(batch, program, 5);
        insert stagedPrograms;
    }

    @IsTest
    static void testRunBatch() {
        Staged_Program_Batch__c batch = [SELECT Id FROM Staged_Program_Batch__c LIMIT 1];

        request.batchId = batch.Id;
        requests.add(request);

        Test.startTest();
        results = FlowProgramGeneratorBatch.runProgramGeneratorBatch(requests);
        Test.stopTest();

        System.Assert.isNotNull(results[0].jobId, 'Should have received a job id for the processing batch');
    }

    @IsTest
    static void testRunBatchWithBatchSizeInput() {
        Staged_Program_Batch__c batch = [SELECT Id FROM Staged_Program_Batch__c LIMIT 1];

        request.batchId = batch.Id;
        request.batchSize = 50;
        requests.add(request);

        Test.startTest();
        results = FlowProgramGeneratorBatch.runProgramGeneratorBatch(requests);
        Test.stopTest();

        System.Assert.isNotNull(results[0].jobId, 'Should have received a job id for the processing batch');
    }
    
}