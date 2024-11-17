@IsTest
private class TRecCourseOptionBookingHandler_Test {

    @TestSetup
    static void makeData() {
        TREX1__Location__c location = TestDataFactory.createLocations(1).get(0);
        insert location;
        TREX1__Facility__c facility = TestDataFactory.createFacilities(1).get(0);
        facility.TREX1__Location__c = location.Id;
        insert facility;
    }

    @IsTest
    static void testCreateBookingsForCourseOptions() {
        TREX1__Facility__c primaryFacility = [SELECT Id FROM TREX1__Facility__c LIMIT 1];

        TREX1__Course_Option__c testCourseOption = new TREX1__Course_Option__c(
            Name = 'Test Course Option',
            TREX1__Start_Date__c = Date.today(),
            TREX1__End_Date__c = Date.today().addDays(6),
            TREX1__Start_Time__c = '1:00 PM',
            TREX1__End_Time__c = '2:00 PM',
            TREX1__Day_of_Week__c = 'Monday;Wednesday',
            Primary_Facility__c = primaryFacility.Id
        );
        insert testCourseOption;

        Set<Id> courseOptionsIds = new Set<Id>{ testCourseOption.Id };

        Test.startTest();
        List<TREX1__Booking__c> bookings = TRecCourseOptionBookingHandler.createBookingsForCourseOptions(
            courseOptionsIds
        );
        Test.stopTest();

        System.assertEquals(2, bookings.size(), 'Should create bookings for two days');
        for (TREX1__Booking__c bk : bookings) {
            System.assertEquals('Draft', bk.TREX1__Status__c, 'Booking status should be Draft');
            System.assertEquals(testCourseOption.Id, bk.TREX1__Course_Option__c, 'Booking should be linked to the course option');
            System.assertNotEquals(null, bk.TREX1__Start_Time__c, 'Start time should not be null');
            System.assertNotEquals(null, bk.TREX1__End_Time__c, 'End time should not be null');
        }
    }

    @IsTest
    static void testCreateBookingsWithMissingData() {
        TREX1__Facility__c primaryFacility = [SELECT Id FROM TREX1__Facility__c LIMIT 1];

        // Setup test data with missing information - no start and end time
        TREX1__Course_Option__c testCourseOption = new TREX1__Course_Option__c(
            Name = 'Test Course Option',
            TREX1__Start_Date__c = Date.today(),
            TREX1__End_Date__c = Date.today().addDays(7),
            TREX1__Day_of_Week__c = 'Monday;Wednesday',
            Primary_Facility__c = primaryFacility.Id
        );
        insert testCourseOption;

        Set<Id> courseOptionsIds = new Set<Id>{ testCourseOption.Id };

        Test.startTest();
        List<TREX1__Booking__c> bookings = TRecCourseOptionBookingHandler.createBookingsForCourseOptions(courseOptionsIds);
        Test.stopTest();

        System.assertEquals(0, bookings.size(), 'No bookings should be created for missing data');
    }

    @IsTest
    static void testCreateBookingsWithSingleExceptionDate() {
        Date exceptionDate = Date.today();

        TREX1__Course_Option__c testCourseOption = createTestCourseOption(exceptionDate.format());
        insert testCourseOption;
    
        Set<Id> courseOptionsIds = new Set<Id>{ testCourseOption.Id };
    
        Test.startTest();
        List<TREX1__Booking__c> bookings = TRecCourseOptionBookingHandler.createBookingsForCourseOptions(courseOptionsIds);
        Test.stopTest();

        List<TREX1__Booking__c> lstExceptionDateBookings = [
            SELECT Id 
              FROM TREX1__Booking__c 
             WHERE Booking_Date__c = :exceptionDate
        ];

        Assert.isTrue(lstExceptionDateBookings.isEmpty(), 'No booking should be created on the exception date');
    }

    @IsTest
    static void testCreateBookingsWithMultipleExceptionDates() {
        List<Date> lstExceptionDates = new List<Date>{ Date.today(), Date.today().addDays(7) };
        List<String> lstExceptionDateStrings = new List<String>();
        for (Date ed : lstExceptionDates) lstExceptionDateStrings.add(ed.format());
        String strExceptionDates = String.join(lstExceptionDateStrings, '; ');

        TREX1__Course_Option__c testCourseOption = createTestCourseOption( strExceptionDates );
        insert testCourseOption;
    
        Set<Id> courseOptionsIds = new Set<Id>{ testCourseOption.Id };
    
        Test.startTest();
        List<TREX1__Booking__c> bookings = TRecCourseOptionBookingHandler.createBookingsForCourseOptions(courseOptionsIds);
        Test.stopTest();
    
        List<TREX1__Booking__c> lstExceptionDateBookings = [
            SELECT Id 
              FROM TREX1__Booking__c 
             WHERE Booking_Date__c IN :lstExceptionDates
        ];

        Assert.isTrue(lstExceptionDateBookings.isEmpty(), 'No booking should be created on the exception date');
    }

    @IsTest
    static void testDoNotCreateBookingsWithCourseOptionOptOut() {
        TREX1__Facility__c primaryFacility = [SELECT Id FROM TREX1__Facility__c LIMIT 1];

        TREX1__Course_Option__c testCourseOption = new TREX1__Course_Option__c(
            Name = 'Test Course Option',
            TREX1__Start_Date__c = Date.today(),
            TREX1__End_Date__c = Date.today().addDays(6),
            TREX1__Start_Time__c = '1:00 PM',
            TREX1__End_Time__c = '2:00 PM',
            TREX1__Day_of_Week__c = 'Monday;Wednesday',
            Primary_Facility__c = primaryFacility.Id,
            Do_Not_Create_Bookings__c = true
        );
        insert testCourseOption;

        Set<Id> courseOptionsIds = new Set<Id>{ testCourseOption.Id };

        Test.startTest();
        List<TREX1__Booking__c> bookings = TRecCourseOptionBookingHandler.createBookingsForCourseOptions(
            courseOptionsIds
        );
        Test.stopTest();

        Assert.isTrue(bookings.isEmpty(), 'Should not have received any bookings while the opt out is enabled');
    }
    
    private static TREX1__Course_Option__c createTestCourseOption(
        String exceptionDates
    ) {
        TREX1__Facility__c primaryFacility = [SELECT Id FROM TREX1__Facility__c LIMIT 1];

        return new TREX1__Course_Option__c(
            TREX1__Start_Date__c = Date.today(),
            TREX1__End_Date__c = Date.today().addDays(7),
            TREX1__Start_Time__c = '1:00 PM',
            TREX1__End_Time__c = '2:00 PM',
            TREX1__Day_of_Week__c = 'Monday;Wednesday',
            Exception_Dates__c = exceptionDates,
            Primary_Facility__c = primaryFacility.Id
        );
    }

}