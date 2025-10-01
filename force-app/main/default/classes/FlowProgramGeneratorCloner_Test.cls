@IsTest
private class FlowProgramGeneratorCloner_Test {

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
    static void testCloner() {
        Staged_Program_Batch__c batch = [SELECT Id, Session__c FROM Staged_Program_Batch__c LIMIT 1];
        List<Id> courseSessionOptionIds = new List<Id>();
        List<TREX1__Course_Session_Option__c> csos = [
            SELECT Id
              FROM TREX1__Course_Session_Option__c
             WHERE TREX1__cso_Course_Session__r.TREX1__Session__c = :batch.Session__c
        ];
        for (TREX1__Course_Session_Option__c cso : csos) {
            courseSessionOptionIds.add(cso.Id);
        }

        List<FlowProgramGeneratorCloner.Result> results;
        Test.startTest();
        FlowProgramGeneratorCloner.Request request = new FlowProgramGeneratorCloner.Request();
        request.batchId = batch.Id;
        request.originalSessionId = batch.Session__c;
        request.targetSessionId = batch.Session__c;
        request.courseSessionOptionIds = courseSessionOptionIds;
        request.daysToAdd = 10;

        results = FlowProgramGeneratorCloner.createStagedPrograms(
            new List<FlowProgramGeneratorCloner.Request>{ request }
        );
        Test.stopTest();

        Assert.areEqual(
            csos.size(), 
            results[0].stagedPrograms.size(),
            'Should have received a staged program for each original record'
        );
    }
    
}