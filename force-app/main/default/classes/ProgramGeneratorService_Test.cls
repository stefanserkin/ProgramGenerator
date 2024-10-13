@IsTest
private class ProgramGeneratorService_Test {
    
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
    static void testCreateNewCourseOptions() {
        Staged_Program__c sp = [SELECT Id, Capacity__c FROM Staged_Program__c LIMIT 1];
        ProgramGeneratorService pgs = new ProgramGeneratorService(new Set<Id>{sp.Id});
        Test.startTest();
        pgs.run();
        Test.stopTest();
        Staged_Program__c refreshedSp = [
            SELECT Status__c 
              FROM Staged_Program__c 
             WHERE Id = :sp.Id LIMIT 1
        ];
        TREX1__Course_Option__c co = [
            SELECT Id, Name, TREX1__Capacity__c 
              FROM TREX1__Course_Option__c 
             WHERE Id IN (SELECT Course_Option__c 
                            FROM Staged_Program__c 
                           WHERE Id = :sp.Id)
             LIMIT 1
        ];
        Assert.areEqual('Processed', refreshedSp.Status__c, 'Final status should be processed');
        Assert.areEqual(sp.Capacity__c, co.TREX1__Capacity__c, 'Should have received the capacity from the staged program');
    }
    
}