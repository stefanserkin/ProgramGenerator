@IsTest
private class ProgramGeneratorBatch_Test {

    private static final Integer NUM_COURSE_OPTIONS = 10;

    @TestSetup
    static void makeData() {
        TREX1__Program__c program = TestDataFactory.createTractionRecProgramLibrary();

        TREX1__Session__c session = [SELECT Id, Name FROM TREX1__Session__c LIMIT 1];

        insert TestDataFactory.createProgramGeneratorSettings();

        Staged_Program_Batch__c batch = TestDataFactory.createStagedProgramBatches(session, 1).get(0);
        insert batch;
        
        List<Staged_Program__c> stagedPrograms = TestDataFactory.createStagedPrograms(
            batch, 
            program, 
            NUM_COURSE_OPTIONS
        );
        insert stagedPrograms;
    }

    @IsTest
    static void testBatch() {
        Id stagedProgramBatchId = [SELECT Id FROM Staged_Program_Batch__c LIMIT 1].Id;
        
        Test.startTest();
        ProgramGeneratorBatch pgb = new ProgramGeneratorBatch(stagedProgramBatchId);
        Id batchId = Database.executeBatch(pgb, 20);
        Test.stopTest();

        List<TREX1__Course_Option__c> lstCos = [SELECT Id FROM TREX1__Course_Option__c WHERE Staged_Program_Batch__c = :stagedProgramBatchId];
        System.Assert.areEqual(NUM_COURSE_OPTIONS, lstCos.size(), 'Should have received ' + NUM_COURSE_OPTIONS + ' course options');
    }

    @IsTest
    static void testBatchWithException() {
        String testErrorMessage = 'Ruhroh';

        Staged_Program__c sp = [SELECT Id, Status__c, Staged_Program_Batch__c FROM Staged_Program__c LIMIT 1];
        sp.Status__c = 'Error';
        sp.Error_Message__c = 'Ruhroh';
        update sp;

        ProgramGeneratorBatch pgb = new ProgramGeneratorBatch(sp.Staged_Program_Batch__c);
        pgb.errorMessages.add(testErrorMessage);

        Test.startTest();
        Id jobId = Database.executeBatch(pgb, 50);
        Test.stopTest();

        Staged_Program_Batch__c spb = [SELECT Id, Status__c, Error_Log__c FROM Staged_Program_Batch__c WHERE Id = :sp.Staged_Program_Batch__c LIMIT 1];
        System.Assert.areEqual('Processed with Errors', spb.Status__c, 'Received unexpected status');
        System.Assert.isTrue(spb.Error_Log__c.contains(testErrorMessage), 'The collection of batch error messages should include the test message');
    }

}