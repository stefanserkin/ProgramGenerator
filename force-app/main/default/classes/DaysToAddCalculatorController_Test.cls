@IsTest
private class DaysToAddCalculatorController_Test {

    @TestSetup
    static void makeData() {
        TestDataFactory.createTractionRecProgramLibrary();
    }

    @IsTest 
    static void testGetSampleCourseOption() {
        Id programId = [SELECT Id FROM TREX1__Program__c LIMIT 1].Id;
        Id sessionId = [SELECT Id FROM TREX1__Session__c LIMIT 1].Id;

        TREX1__Course_Option__c sampleOption;
        Test.startTest();
        sampleOption = DaysToAddCalculatorController.getSampleCourseOption(programId, sessionId);
        Test.stopTest();

        System.Assert.isNotNull(sampleOption, 'Should have received a sample course option for the program and session');

        TREX1__Course_Session_Option__c cso = [
            SELECT TREX1__Course_Session__r.TREX1__Session__c, TREX1__Course_Session__r.TREX1__Course__r.TREX1__Program__c
              FROM TREX1__Course_Session_Option__c
             WHERE TREX1__Course_Option__c = :sampleOption.Id
             LIMIT 1
        ];

        System.Assert.areEqual(
            sessionId, 
            cso.TREX1__Course_Session__r.TREX1__Session__c, 
            'Course option should be within the provided session'
        );
        System.Assert.areEqual(
            programId, 
            cso.TREX1__Course_Session__r.TREX1__Course__r.TREX1__Program__c, 
            'Course option should be within the provided program'
        );
    }

    @IsTest 
    static void testGetSampleCourseOptionWithException() {
        Id programId = [SELECT Id FROM TREX1__Program__c LIMIT 1].Id;
        Id sessionId = [SELECT Id FROM TREX1__Session__c LIMIT 1].Id;

        User u = TestDataFactory.createStandardInternalUser();

        TREX1__Course_Option__c sampleOption;
        Test.startTest();
        System.runAs(u) {
            try {
                sampleOption = DaysToAddCalculatorController.getSampleCourseOption(programId, sessionId);
                System.Assert.fail('Should not have been able to retrieve sample course option without object/fls');
            } catch (Exception e) {
                System.Assert.areEqual(
                    'System.AuraHandledException', 
                    e.getTypeName(), 
                    'Should have received an aura handled exception'
                );
            }
        }
        Test.stopTest();
    }
    
}