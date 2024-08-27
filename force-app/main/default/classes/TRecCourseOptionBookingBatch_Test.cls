@IsTest 
private class TRecCourseOptionBookingBatch_Test {

    @TestSetup
    static void makeData() {
        TREX1__Location__c location = TestDataFactory.createLocations(1).get(0);
        insert location;

        TREX1__Facility__c facility = TestDataFactory.createFacilities(1).get(0);
        facility.TREX1__Location__c = location.Id;
        insert facility;

        List<TREX1__Program__c> lstPrograms = TestDataFactory.createPrograms(1);
        insert lstPrograms;

        List<TREX1__Course__c> lstCourses = TestDataFactory.createCourses(lstPrograms, 1);
        insert lstCourses;

        TREX1__Session__c session = TestDataFactory.createSessions(1).get(0);
        insert session;

        List<TREX1__Course_Session__c> lstCourseSessions = TestDataFactory.createCourseSessions(lstCourses, session.Id, 1);
        insert lstCourseSessions;

        List<TREX1__Course_Session_Option__c> lstCourseSessionOptions = TestDataFactory.createCourseOptions(lstCourseSessions, 5);
        // Add a primary facility and day of week to each course option
        List<TREX1__Course_Option__c> lstCourseOptions = new List<TREX1__Course_Option__c>();
        for (TREX1__Course_Session_Option__c cso : lstCourseSessionOptions) {
            lstCourseOptions.add(
                new TREX1__Course_Option__c(
                    Id = cso.TREX1__Course_Option__c, 
                    Primary_Facility__c = facility.Id,
                    TREX1__Day_of_Week__c = 'Tuesday'
                )
            );
        }
        update lstCourseOptions;
    }

    @IsTest
    static void testCourseOptionBookingBatch() {
        // Get test data
        List<TREX1__Course_Option__c> courseOptions = [SELECT Id FROM TREX1__Course_Option__c];

        // Execute the batch job a single time in test context
        Id jobId;
        Test.startTest();
        TRecCourseOptionBookingBatch batch = new TRecCourseOptionBookingBatch(courseOptions);
        jobId = Database.executeBatch(batch);
        Test.stopTest();

        // Verify the job ran and provided an id
        Assert.isNotNull(jobId, 'Should have received a job id');
    }

}