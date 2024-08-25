@IsTest
private class ProgramGeneratorCloner_Test {

    @TestSetup
    static void makeData() {
        List<TREX1__Program__c> programs = TestDataFactory.createPrograms(1);
        insert programs;

        List<TREX1__Course__c> courses = TestDataFactory.createCourses(programs, 1);
        insert courses;

        TREX1__Session__c session = TestDataFactory.createSessions(1).get(0);
        insert session;

        List<TREX1__Course_Session__c> courseSessions = TestDataFactory.createCourseSessions(courses, session.Id, 1);
        insert courseSessions;
    }
    
    @IsTest
    static void testCloner() {}

}