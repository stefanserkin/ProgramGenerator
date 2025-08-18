public with sharing class TRecCourseOptionBookingHandler {

    private static Id facilityBookingRecTypeId = Schema.SObjectType.TREX1__Booking__c.getRecordTypeInfosByDeveloperName()
                                                    .get('Facility').getRecordTypeId();

    public static List<TREX1__Booking__c> createBookingsForCourseOptions(Set<Id> courseOptionsIds) {
        return createBookingsForCourseOptions(courseOptionsIds, null);
    }
    
    public static List<TREX1__Booking__c> createBookingsForCourseOptions(Set<Id> courseOptionsIds, Id stagedProgramBatchId) {
        List<TREX1__Booking__c> bookings = new List<TREX1__Booking__c>();

        List<TREX1__Course_Option__c> courseOptionsWithSingleStartTime = new List<TREX1__Course_Option__c>();
        List<TREX1__Course_Option__c> courseOptionsWithMultipleStartTimes = new List<TREX1__Course_Option__c>();
        for (TREX1__Course_Option__c co : getFilteredCourseOptions(courseOptionsIds)) {
            if (co.Staged_Program__c != null && co.Staged_Program__r.Has_Multiple_Start_Times__c) {
                courseOptionsWithMultipleStartTimes.add(co);
            } else {
                courseOptionsWithSingleStartTime.add(co);
            }
        }

        bookings.addAll(createBookingsForSingleStartTimes(courseOptionsWithSingleStartTime, stagedProgramBatchId));
        bookings.addAll(createBookingsForMultiStartTimes(courseOptionsWithMultipleStartTimes));

        return bookings;
    }

    private static List<TREX1__Booking__c> createBookingsForSingleStartTimes(List<TREX1__Course_Option__c> courseOptions, Id stagedProgramBatchId) {
        List<TREX1__Booking__c> bookings = new List<TREX1__Booking__c>();
        
        for (TREX1__Course_Option__c co : courseOptions) {
            if (!hasRequiredData(co)) {
                continue;
            }

            List<Date> classDates = findClassDates(
                co.TREX1__Start_Date__c,
                co.TREX1__End_Date__c,
                co.TREX1__Day_of_Week__c.split(';'),
                co.Exception_Dates__c
            );

            Time startTime = CommonUtilities.parseTimeString(co.TREX1__Start_Time__c);
            Time endTime = CommonUtilities.parseTimeString(co.TREX1__End_Time__c);

            for (Date classDate : classDates) {
                bookings.add(
                    createBooking(
                        co,
                        Datetime.newInstance(classDate, startTime),
                        Datetime.newInstance(classDate, endTime),
                        co.Primary_Facility__c
                    )
                );
            }
        }

        return bookings;
    }

    private static List<TREX1__Booking__c> createBookingsForMultiStartTimes(List<TREX1__Course_Option__c> courseOptions) {
        List<TREX1__Booking__c> bookings = new List<TREX1__Booking__c>();

        Set<Id> stagedProgramIds = new Set<Id>();
        for (TREX1__Course_Option__c co : courseOptions) {
            stagedProgramIds.add(co.Staged_Program__c);
        }

        Map<Id, Staged_Program__c> programMap = getStagedProgramBookingMap(stagedProgramIds);
        for (TREX1__Course_Option__c co : courseOptions) {
            Staged_Program__c sp = programMap.get(co.Staged_Program__c);
            List<Staged_Program_Booking__c> spBookings = sp.Staged_Program_Bookings__r;

            for (Staged_Program_Booking__c spb : spBookings) {
                List<Date> classDates = findClassDates(
                    co.TREX1__Start_Date__c,
                    co.TREX1__End_Date__c,
                    spb.Days_of_Week__c.split(';'),
                    co.Exception_Dates__c
                );

                Time startTime = CommonUtilities.parseTimeString(spb.Start_Time__c);
                Time endTime = CommonUtilities.parseTimeString(spb.End_Time__c);

                for (Date classDate : classDates) {
                    bookings.add(
                        createBooking(
                            co,
                            Datetime.newInstance(classDate, startTime),
                            Datetime.newInstance(classDate, endTime),
                            spb.Facility__c
                        )
                    );
                }
            }
        }

        return bookings;
    }

    private static TREX1__Booking__c createBooking(
        TREX1__Course_Option__c courseOption, 
        Datetime startTime, 
        Datetime endTime, 
        Id facilityId
    ) {
        TREX1__Booking__c bk = new TREX1__Booking__c();
        bk.RecordTypeId = facilityBookingRecTypeId;
        bk.TREX1__Status__c = 'Draft';
        bk.TREX1__Facility__c = facilityId;
        bk.TREX1__Start_Time__c = startTime;
        bk.TREX1__End_Time__c = endTime;
        bk.TREX1__Course_Option__c = courseOption.Id;
        bk.TREX1__Event_Name__c = courseOption.Name;
        bk.TREX1__Type__c = 'Course';
        bk.TREX1__Setup_Time_Required__c = 0;
        bk.TREX1__Tear_Down_Time_Required__c = 0;
        if (courseOption.Staged_Program_Batch__c != null) {
            bk.Staged_Program_Batch__c = courseOption.Staged_Program_Batch__c;
        }
        return bk;
    }

    private static Boolean hasRequiredData(TREX1__Course_Option__c courseOption) {
        return courseOption.TREX1__Start_Date__c != null && 
            courseOption.TREX1__End_Date__c != null && 
            !String.isBlank(courseOption.TREX1__Start_Time__c) && 
            !String.isBlank(courseOption.TREX1__End_Time__c) && 
            !String.isBlank(courseOption.TREX1__Day_of_Week__c);
    }

    private static List<Date> findClassDates(
        Date startDate,
        Date endDate,
        List<String> daysOfWeek,
        String exceptionDateString
    ) {
        List<Date> dates = new List<Date>();
        Set<Date> exceptionDates = parseExceptionDates(exceptionDateString);

        while (startDate <= endDate) {
            if (isClassDay(startDate, daysOfWeek) && !exceptionDates.contains(startDate)) {
                dates.add(startDate);
            }
            startDate = startDate.addDays(1);
        }

        return dates;
    }

    private static Set<Date> parseExceptionDates(String exceptionDatesString) {
        Set<Date> exceptionDates = new Set<Date>();
        if (String.isBlank(exceptionDatesString)) {
            return exceptionDates;
        }
    
        // Split the string by known delimiters
        List<String> dateStrings = exceptionDatesString.split(';');
        for (String dateString : dateStrings) {
            Date parsedDate = Date.parse(dateString.trim());
            if (parsedDate != null) {
                exceptionDates.add(parsedDate);
            }
        }
        return exceptionDates;
    }

    private static Boolean isClassDay(Date classDate, List<String> daysOfWeek) {
        DateTime dtValue = DateTime.newInstance(classDate, Time.newInstance(0, 0, 0, 0));
        String dayString = dtValue.format('EEEE');
        for (String day : daysOfWeek) {
            if (day.equalsIgnoreCase(dayString)) {
                return true;
            }
        }
        return false;
    }

    private static List<TREX1__Course_Option__c> getFilteredCourseOptions(Set<Id> courseOptionsIds) {
        return [
            SELECT Id, Name, Exception_Dates__c, 
                   TREX1__Start_Date__c, TREX1__Start_Time__c, 
                   TREX1__End_Date__c, TREX1__End_Time__c, 
                   TREX1__Day_of_Week__c, Primary_Facility__c,
                   Staged_Program__c, Staged_Program__r.Has_Multiple_Start_Times__c,
                   Staged_Program_Batch__c
              FROM TREX1__Course_Option__c
             WHERE Id IN :courseOptionsIds
               AND Do_Not_Create_Bookings__c = false
              WITH USER_MODE
             LIMIT 10000
        ];
    }

    private static Map<Id, Staged_Program__c> getStagedProgramBookingMap(Set<Id> stagedProgramIds) {
        return new Map<Id, Staged_Program__c>([
            SELECT Id, Name, Has_Multiple_Start_Times__c,
                   (SELECT Id, Days_of_Week__c, Start_Time__c, End_Time__c, Facility__c 
                      FROM Staged_Program_Bookings__r)
              FROM Staged_Program__c
             WHERE Id IN :stagedProgramIds
             LIMIT 10000
        ]);
    }

}