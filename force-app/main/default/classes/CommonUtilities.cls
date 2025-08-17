public without sharing class CommonUtilities {

    /**********************************************
     * Date/Time
     **********************************************/

    public static String getFormattedDatetime(DateTime dtInput) {
        return dtInput.format('M/d/yyyy') + ' at ' + getFormattedTime(dtInput);
    }

    public static String getFormattedTime(DateTime dtInput) {
        String formattedTime;
        if (dtInput.format('mm') == '00') {
            formattedTime = dtInput.format('ha').toLowerCase();
        } else {
            formattedTime = dtInput.format('h:mma').toLowerCase();
        }
        return formattedTime;
    }

    public static String getSortableFormattedDatetime(DateTime dtInput) {
        return dtInput.format('yyyy-MM-dd') + ' at ' + getSortableFormattedTime(dtInput);
    }

    public static String getSortableFormattedTime(DateTime dtInput) {
        return dtInput.format('hh:mm a');
    }

    /**
     * Convert a validated 12-hour time string (e.g., "8:00 AM", "12:15 pm")
     * into a Time. Assumes formatting per:
     * (0?[1-9]|1[012]):[0-5]\d\s[APap][mM]
     *
     * @param input The validated time string, or null/blank.
     * @return Time value with seconds/millis = 0, or null if input is blank.
     */
    public static Time parseTimeString(String input) {
        if (String.isBlank(input)) {
            return null;
        }

        String s = input.trim();
        List<String> parts = s.split('\\s'); // "<h>:<mm>" and "AM|PM"
        List<String> hm = parts[0].split(':');

        Integer hour12 = Integer.valueOf(hm[0]);
        Integer minute = Integer.valueOf(hm[1]);
        String ampm = parts[1].toUpperCase();

        Integer hour24 = Math.mod(hour12, 12); // ensures 12 -> 0
        if (ampm == 'PM') hour24 += 12;

        return Time.newInstance(hour24, minute, 0, 0);
    }

    /**********************************************
     * Check Email Deliverability
     **********************************************/

    /**
     * Check if there is remaining email capacity in Messaging limits
     * @return True if email deliverability is enabled
     */
    public static Boolean isOrgEmailEnabled() {
        Boolean emailDeliverabilityEnabled = true;
        try {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.reserveMassEmailCapacity(1);
        } catch (System.NoAccessException e) {
            emailDeliverabilityEnabled = false;
        }
        return emailDeliverabilityEnabled;
    }
    
}