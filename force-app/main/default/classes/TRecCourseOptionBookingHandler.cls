public with sharing class TRecCourseOptionBookingHandler {

    private static Id facilityBookingRecTypeId = Schema.SObjectType.TREX1__Booking__c
        .getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
    
    public static List<TREX1__Booking__c> createBookingsForCourseOptions(
        Set<Id> courseOptionsIds
    ) {
        List<TREX1__Booking__c> lstBookings = new List<TREX1__Booking__c>();

        // Get course options
        List<TREX1__Course_Option__c> lstOptions = getCourseOptions(courseOptionsIds);

        // Create bookings
        for (TREX1__Course_Option__c co : lstOptions) {
            if (!hasRequiredData(co)) {
                continue;
            }

            List<Date> classDates = findClassDates(co);
            Time startTime = parseTime(co.TREX1__Start_Time__c);
            Time endTime = parseTime(co.TREX1__End_Time__c);

            for (Date classDate : classDates) {
                TREX1__Booking__c bk = new TREX1__Booking__c();
                bk.RecordTypeId = facilityBookingRecTypeId;
                bk.TREX1__Status__c = 'Draft';
                bk.TREX1__Facility__c = co.Primary_Facility__c;
                bk.TREX1__Start_Time__c = Datetime.newInstance(classDate, startTime);
                bk.TREX1__End_Time__c = Datetime.newInstance(classDate, endTime);
                bk.TREX1__Course_Option__c = co.Id;
                bk.TREX1__Event_Name__c = co.Name;
                bk.TREX1__Type__c = 'Course';
                bk.TREX1__Setup_Time_Required__c = 0;
                bk.TREX1__Tear_Down_Time_Required__c = 0;
                lstBookings.add(bk);
            }
        }

        // Return bookings
        return lstBookings;
    }

    private static Boolean hasRequiredData(
        TREX1__Course_Option__c courseOption
    ) {
        return courseOption.TREX1__Start_Date__c != null && 
            courseOption.TREX1__End_Date__c != null && 
            !String.isBlank(courseOption.TREX1__Start_Time__c) && 
            !String.isBlank(courseOption.TREX1__End_Time__c) && 
            !String.isBlank(courseOption.TREX1__Day_of_Week__c);
    }

    private static Set<Date> parseExceptionDates(
        String exceptionDatesString,
        TREX1__Course_Option__c courseOption
    ) {
        Set<Date> exceptionDates = new Set<Date>();
        if (String.isBlank(exceptionDatesString)) {
            return exceptionDates;
        }
    
        // Split the string by known delimiters
        List<String> dateStrings = exceptionDatesString.split('[, &]+');
        for (String dateString : dateStrings) {
            Date parsedDate = tryParseDate(dateString.trim(), courseOption);
            if (parsedDate != null) {
                exceptionDates.add(parsedDate);
            }
        }
        return exceptionDates;
    }

    private static Date tryParseDate(
        String dateString,
        TREX1__Course_Option__c courseOption
    ) {
        List<String> formats = new List<String>{ 'M/d', 'M/d/yy', 'M/d/yyyy' };
        for (String format : formats) {
            String strFormattedDate = dateString;
            try {
                if (format == 'M/d') {
                    // Add the current year if the format is without year
                    strFormattedDate = dateString + '/' + courseOption.TREX1__Start_Date__c.year();
                }
                DateTime tempDateTime = DateTime.newInstanceGmt(
                    Date.valueOf(dateString), 
                    Time.newInstance(0, 0, 0, 0)
                );
                return tempDateTime.date();
            } catch (Exception e) {
                System.debug('::: found unknown format. Moving to next format');
            }
        }
        return null;
    }

    private static List<Date> findClassDates(
        TREX1__Course_Option__c courseOption
    ) {
        List<Date> dates = new List<Date>();
        Set<Date> exceptionDates = parseExceptionDates(courseOption.Exception_Dates__c, courseOption);
        Date startDate = courseOption.TREX1__Start_Date__c;
        Date endDate = courseOption.TREX1__End_Date__c;
        String[] daysOfWeek = courseOption.TREX1__Day_of_Week__c.split(';');

        while (startDate <= endDate) {
            if (isClassDay(startDate, daysOfWeek) && !exceptionDates.contains(startDate)) {
                dates.add(startDate);
            }
            startDate = startDate.addDays(1);
        }

        return dates;
    }

    private static Boolean isClassDay(
        Date classDate, 
        String[] daysOfWeek
    ) {
        DateTime dtValue = DateTime.newInstance(classDate, Time.newInstance(0, 0, 0, 0));
        String dayString = dtValue.format('EEEE');
        for (String day : daysOfWeek) {
            if (day.equalsIgnoreCase(dayString)) {
                return true;
            }
        }
        return false;
    }

    private static Time parseTime(
        String timeString
    ) {
        // Example input: "1:00 PM"
        // Convert this String into a Time object
        if (String.isEmpty(timeString)) {
            return null;
        }
    
        // Split the timeString into components
        String[] parts = timeString.split(':');
        String[] hourAndMeridian = parts[1].split('\\s+');
        Integer hour = Integer.valueOf(parts[0]);
        Integer minute = Integer.valueOf(hourAndMeridian[0]);
        String meridian = hourAndMeridian[1].toLowerCase();
    
        // Convert 12-hour time to 24-hour time
        if (meridian == 'pm' && hour < 12) {
            hour += 12;
        } else if (meridian == 'am' && hour == 12) {
            hour = 0;
        }
    
        return Time.newInstance(hour, minute, 0, 0);
    }

    private static List<TREX1__Course_Option__c> getCourseOptions(
        Set<Id> courseOptionsIds
    ) {
        return [
            SELECT Id, Name, Exception_Dates__c, 
                   TREX1__Start_Date__c, TREX1__Start_Time__c, 
                   TREX1__End_Date__c, TREX1__End_Time__c, 
                   TREX1__Day_of_Week__c, Primary_Facility__c
              FROM TREX1__Course_Option__c
             WHERE Id IN :courseOptionsIds
              WITH USER_MODE
             LIMIT 10000
        ];
    }

}