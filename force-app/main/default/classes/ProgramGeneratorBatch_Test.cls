@IsTest
private class ProgramGeneratorBatch_Test {

    private static final Integer NUM_COURSE_OPTIONS = 10;

    @TestSetup
    static void makeData() {
        TREX1__Program__c program = TestDataFactory.createTractionRecProgramLibrary();
        TREX1__Session__c session = [SELECT Id, Name FROM TREX1__Session__c LIMIT 1];
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

        List<TREX1__Course_Option__c> lstCos = [
            SELECT Id FROM TREX1__Course_Option__c WHERE Staged_Program_Batch__c = :stagedProgramBatchId
        ];
        
        Assert.areEqual(
            NUM_COURSE_OPTIONS, 
            lstCos.size(), 
            'Should have received ' + NUM_COURSE_OPTIONS + ' course options'
        );
    }

    @IsTest
    static void testBatchWithException() {
        TREX1__Program__c program = [SELECT Id FROM TREX1__Program__c LIMIT 1];
        TREX1__Session__c session = TestDataFactory.createSessions(1).get(0);
        insert session;

        Staged_Program_Batch__c spb = TestDataFactory.createStagedProgramBatches(session, 1).get(0);
        insert spb;

        // Create upper east side location to force error when no free membership type is defined
        TREX1__Location__c location = TestDataFactory.createLocations(1).get(0);
        location.Name = 'Upper East Side';
        insert location;

        Staged_Program__c stagedProgram = TestDataFactory.createStagedPrograms(spb, program, 1).get(0);
        stagedProgram.Location__c = location.Id;
        stagedProgram.Session__c = session.Id;
        insert stagedProgram;
        
        Test.startTest();
        ProgramGeneratorBatch pgb = new ProgramGeneratorBatch(spb.Id);
        Id batchId = Database.executeBatch(pgb, 20);
        Test.stopTest();

        Staged_Program_Batch__c refreshedBatch = [SELECT Status__c FROM Staged_Program_Batch__c WHERE Id = :spb.Id LIMIT 1];

        Assert.areEqual('Processed with Errors', refreshedBatch.Status__c, 'Should have received a failed batch status');
    }

}