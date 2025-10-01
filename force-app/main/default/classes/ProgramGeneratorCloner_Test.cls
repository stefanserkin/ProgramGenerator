@IsTest
private class ProgramGeneratorCloner_Test {

    @TestSetup
    static void makeData() {
        TREX1__Program__c program = TestDataFactory.createTractionRecProgramLibrary();
        TREX1__Session__c session = [SELECT Id, Name FROM TREX1__Session__c LIMIT 1];
        insert TestDataFactory.createStagedProgramBatches(session, 1).get(0);
    }
    
    @IsTest
    static void testCloner() {
        Staged_Program_Batch__c batch = [SELECT Id, Session__c FROM Staged_Program_Batch__c LIMIT 1];
        Set<Id> courseSessionOptionIds = new Set<Id>();
        List<TREX1__Course_Session_Option__c> csos = [
            SELECT Id
              FROM TREX1__Course_Session_Option__c
             WHERE TREX1__cso_Course_Session__r.TREX1__Session__c = :batch.Session__c
        ];
        for (TREX1__Course_Session_Option__c cso : csos) {
            courseSessionOptionIds.add(cso.Id);
        }

        List<Staged_Program__c> stagedPrograms;
        Test.startTest();
        ProgramGeneratorCloner cloner = new ProgramGeneratorCloner(
            batch.Id,
            batch.Session__c,
            batch.Session__c,
            courseSessionOptionIds
        );
        cloner.setDaysToAdd(10);
        stagedPrograms = cloner.createStagedPrograms();
        Test.stopTest();

        Assert.areEqual(
            csos.size(), 
            stagedPrograms.size(),
            'Should have received a staged program for each original record'
        );
    }

    @IsTest
    static void testCloneToNewSession() {
        TREX1__Session__c originalSession = [
            SELECT Id 
              FROM TREX1__Session__c 
             WHERE Id IN (SELECT TREX1__Session__c FROM TREX1__Course_Session__c) 
             LIMIT 1
        ];
        Set<Id> courseSessionOptionIds = new Set<Id>();
        List<TREX1__Course_Session_Option__c> csos = [
            SELECT Id
              FROM TREX1__Course_Session_Option__c
             WHERE TREX1__cso_Course_Session__r.TREX1__Session__c = :originalSession.Id
        ];
        for (TREX1__Course_Session_Option__c cso : csos) {
            courseSessionOptionIds.add(cso.Id);
        }

        // Create new session for staged programs
        TREX1__Session__c targetSession = TestDataFactory.createSessions(1).get(0);
        targetSession.Name = 'Target Session';
        insert targetSession;

        Staged_Program_Batch__c batch = TestDataFactory.createStagedProgramBatches(targetSession, 1).get(0);
        insert batch;

        List<Staged_Program__c> stagedPrograms;
        Test.startTest();
        ProgramGeneratorCloner cloner = new ProgramGeneratorCloner(
            batch.Id,
            originalSession.Id,
            targetSession.Id,
            courseSessionOptionIds
        );
        cloner.setDaysToAdd(10);
        stagedPrograms = cloner.createStagedPrograms();
        Test.stopTest();

        Assert.areEqual(
            csos.size(), 
            stagedPrograms.size(),
            'Should have received a staged program for each original record'
        );

        Assert.areEqual(
            targetSession.Id, 
            stagedPrograms[0].Session__c,
            'Staged programs should be associated with the target session'
        );
    }

}