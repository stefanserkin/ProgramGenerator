@IsTest
private class CommonUtilities_Test {

    /***********************************************
     * Formatted Datetimes
     ***********************************************/
    
    @IsTest
    static void testGetFormattedTime() {
        Datetime dtInput = Datetime.newInstance(2022, 1, 1, 10, 0, 0);
        String expectedResult = '10am';

        Test.startTest();
        String strFormattedTime = CommonUtilities.getFormattedTime(dtInput);
        Test.stopTest();

        System.Assert.areEqual(
            expectedResult, 
            strFormattedTime, 
            'Returned string did not match expected formatted time'
        );
    }

    @IsTest
    static void testGetFormattedTimeWithMinutes() {
        Datetime dtInput = Datetime.newInstance(2022, 1, 1, 10, 30, 0);
        String expectedResult = '10:30am';

        Test.startTest();
        String strFormattedTime = CommonUtilities.getFormattedTime(dtInput);
        Test.stopTest();

        System.Assert.areEqual(
            expectedResult, 
            strFormattedTime, 
            'Returned string did not match expected formatted time'
        );
    }

    @IsTest
    static void testGetFormattedTimeInAfternoon() {
        Datetime dtInput = Datetime.newInstance(2022, 1, 1, 20, 30, 0);
        String expectedResult = '8:30pm';

        Test.startTest();
        String strFormattedTime = CommonUtilities.getFormattedTime(dtInput);
        Test.stopTest();

        System.Assert.areEqual(
            expectedResult, 
            strFormattedTime, 
            'Returned string did not match expected formatted time'
        );
    }

    @IsTest
    static void testGetFormattedDatetime() {
        Datetime dtInput = Datetime.newInstance(2022, 1, 1, 10, 0, 0);
        String expectedResult = '1/1/2022 at 10am';

        Test.startTest();
        String strFormattedTime = CommonUtilities.getFormattedDatetime(dtInput);
        Test.stopTest();

        System.Assert.areEqual(
            expectedResult, 
            strFormattedTime, 
            'Returned string did not match expected formatted time'
        );
    }

    @IsTest
    static void testGetFormattedDatetimeWithMinutes() {
        Datetime dtInput = Datetime.newInstance(2022, 1, 1, 10, 30, 0);
        String expectedResult = '1/1/2022 at 10:30am';

        Test.startTest();
        String strFormattedTime = CommonUtilities.getFormattedDatetime(dtInput);
        Test.stopTest();

        System.Assert.areEqual(
            expectedResult, 
            strFormattedTime, 
            'Returned string did not match expected formatted time'
        );
    }

    @IsTest
    static void testGetFormattedDatetimeInAfternoon() {
        Datetime dtInput = Datetime.newInstance(2022, 1, 1, 20, 30, 0);
        String expectedResult = '1/1/2022 at 8:30pm';

        Test.startTest();
        String strFormattedTime = CommonUtilities.getFormattedDatetime(dtInput);
        Test.stopTest();

        System.Assert.areEqual(
            expectedResult, 
            strFormattedTime, 
            'Returned string did not match expected formatted time'
        );
    }

    /***********************************************
     * Sortable Formatted Datetimes
     ***********************************************/

    @IsTest
    static void testGetSortableFormattedTime() {
        Datetime dtInput = Datetime.newInstance(2022, 1, 1, 8, 0, 0);
        String expectedResult = '08:00 AM';

        Test.startTest();
        String strFormattedTime = CommonUtilities.getSortableFormattedTime(dtInput);
        Test.stopTest();

        System.Assert.areEqual(
            expectedResult, 
            strFormattedTime, 
            'Returned string did not match expected formatted time'
        );
    }

    @IsTest
    static void testGetSortableFormattedDatetime() {
        Datetime dtInput = Datetime.newInstance(2022, 1, 1, 8, 0, 0);
        String expectedResult = '2022-01-01 at 08:00 AM';

        Test.startTest();
        String strFormattedTime = CommonUtilities.getSortableFormattedDatetime(dtInput);
        Test.stopTest();

        System.Assert.areEqual(
            expectedResult, 
            strFormattedTime, 
            'Returned string did not match expected formatted time'
        );
    }

    /***********************************************
     * Time Parsing
     ***********************************************/

    @IsTest
    static void testParseTimeString() {
        String timeString = '8:30 AM';

        Test.startTest();
        Time result = CommonUtilities.parseTimeString(timeString);
        Test.stopTest();

        System.Assert.areEqual(
            Time.newInstance(8, 30, 0, 0), 
            result, 
            'Did not parse time string correctly'
        );
    }

    @IsTest
    static void testParseTimeStringWithNullInput() {
        String timeString;

        Test.startTest();
        Time result = CommonUtilities.parseTimeString(timeString);
        Test.stopTest();

        System.Assert.isNull(
            result, 
            'Should have returned null for null string input'
        );
    }

    @IsTest
    static void testParseTimeStringMidnight() {
        String timeString = '12:00 AM';

        Test.startTest();
        Time result = CommonUtilities.parseTimeString(timeString);
        Test.stopTest();

        System.Assert.areEqual(
            Time.newInstance(0, 0, 0, 0),
            result,
            'Should have returned midnight as a Time value'
        );
    }

    /***********************************************
     * Org Email Deliverability
     ***********************************************/

    @IsTest
    static void testIsOrgEmailEnabled() {
        Boolean emailDeliverabilityEnabled = true;
        try {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.reserveMassEmailCapacity(1);
        } catch (System.NoAccessException e) {
            emailDeliverabilityEnabled = false;
        }

        Test.startTest();
        Boolean result = CommonUtilities.isOrgEmailEnabled();
        Test.stopTest();

        System.Assert.areEqual(
            emailDeliverabilityEnabled, 
            result,
            'Email deliverability should be ' + emailDeliverabilityEnabled
        );
    }

}