/*
 * DoubleMe: Handler for Cloning the details.
 *
 *
 *
 * Created By: 			Revision Date
 * Sagarika Rout 		27th Sep		Updated: Added Null Check and try Catch
 * Mike N               29th Dec 2023   Updated: Added Course_Session_Name__c and Course_Option_Name__c
 */
public with sharing class DoubleMe {

    /**
     * Static variables
     */

    // Coming and going session information
    private static Id originalSessionId;
    private static String originalSessionName;
    private static String originalSessionCode;
    private static Id targetSessionId;
    private static String targetSessionName;
    private static String targetSessionCode;

    // Configuration options from flow input
    private static Integer daysToAdd;
    private static Date fixedStartDate;
    private static Date fixedEndDate;
    private static Boolean fixedDateMode = false;
    private static Boolean updateSessionNameMode = false;
    private static Boolean takeRegistrationFromSession = false;
    private static Boolean dontCloneProducts = false;

    private static string exceptionString = 'The following exception has occurred: ';
    private static String contactAdminError = ' kindly Contact to Admin';

    private static Map<Id, TREX1__Product__c> mapIdToClonedProductDiscount;
    private static Map<Id, TREX1__Product__c> mapIdToNonClonedProductDiscount;
    
    // Cache session data to avoid repeated queries
    private static TREX1__Session__c cachedSession;
    private static Map<Id, TREX1__Session__c> mapCachedSessions;
    
    /**
     * Invocable Method
     */

    @InvocableMethod(label='Double Me' description='Provide a collection of Course Session Options to clone')
    public static List<Result> doubleThisCollection(List<Request> lstRequests) {
        try {
            List<Result> lstResults = new List<Result>();
            List<TREX1__Course_Session_Option__c> lstCSOs = new List<TREX1__Course_Session_Option__c>();
            List<TREX1__Available_Discounts__c> lstAvailableDiscounts = new List<TREX1__Available_Discounts__c>();
            List<TREX1__Assigned_Question_Group__c> lstAQGs = new List<TREX1__Assigned_Question_Group__c>();

            if(lstRequests.size() > 0){
                lstCSOs = lstRequests.get(0).lstCSOs;
                lstAvailableDiscounts = lstRequests.get(0).lstAvailableDiscounts;
                lstAQGs = lstRequests.get(0).lstAQGs;
                originalSessionId = lstRequests.get(0).originalSessionId;
                targetSessionId = lstRequests.get(0).targetSessionId;
                fixedDateMode = lstRequests.get(0).fixedDateMode != null ? lstRequests.get(0).fixedDateMode : false;
                daysToAdd = lstRequests.get(0).daysToAdd != null ? lstRequests.get(0).daysToAdd : 0;
                fixedStartDate = lstRequests.get(0).fixedStartDate != null ? lstRequests.get(0).fixedStartDate : Date.today();
                fixedEndDate = lstRequests.get(0).fixedEndDate != null ? lstRequests.get(0).fixedEndDate : Date.today();
                updateSessionNameMode = lstRequests.get(0).updateSessionNameMode != null ? lstRequests.get(0).updateSessionNameMode : false;
                takeRegistrationFromSession = lstRequests.get(0).takeRegistrationFromSession != null ? lstRequests.get(0).takeRegistrationFromSession : false;
                dontCloneProducts = lstRequests.get(0).dontCloneProducts != null ? lstRequests.get(0).dontCloneProducts : false;
            }
            else{
                return null;
            }
            if (updateSessionNameMode) {
                setSessionDetails();
            }
            Set<Id> setCourseOptionIds = new Set<Id>();
            Set<Id> setCourseSessionIds = new Set<Id>();
            Set<Id> setProductDiscountids = new Set<Id>();
            Set<Id> setProductDiscountidsNonClone = new Set<Id>();

            // Create sets of ids for queries
            for (TREX1__Course_Session_Option__c cso : lstCSOs) {
                if(cso.TREX1__Course_Option__c != null){
                    setCourseOptionIds.add(cso.TREX1__Course_Option__c);
                }
                if(cso.TREX1__Course_Session__c != null){
                	setCourseSessionIds.add(cso.TREX1__Course_Session__c);
                }
            }
            for (TREX1__Available_Discounts__c availableDiscount : lstAvailableDiscounts) {
                if(availableDiscount.TREX1__Course_Option__c != null){
                    setCourseOptionIds.add(availableDiscount.TREX1__Course_Option__c);
                }
                if(availableDiscount.TREX1__Course_Session__c != null){
                	setCourseSessionIds.add(availableDiscount.TREX1__Course_Session__c);
                }
            }
            for (TREX1__Assigned_Question_Group__c aqg : lstAQGs) {
                if(aqg.TREX1__Course_Session__c != null){
                	setCourseSessionIds.add(aqg.TREX1__Course_Session__c);
                }
            }

            // Get map of records with only fields to clone
            Map<Id, TREX1__Course_Session__c> mapCourseSessions = getCourseSessionMap(setCourseSessionIds);
            Map<Id, TREX1__Course_Option__c> mapCourseOptions = getCourseOptionMap(setCourseOptionIds);

            //Iterate course session and option to get product and discount ids
            for(TREX1__Course_Session__c courseSession : mapCourseSessions.values()) {
                if(courseSession.TREX1__Product__c != null){
                    if(dontCloneProducts){
                        setProductDiscountidsNonClone.add(courseSession.TREX1__Product__c);
                    } else {
                        setProductDiscountids.add(courseSession.TREX1__Product__c);
                    }
                }
            }
            for(TREX1__Course_Option__c couseOption : mapCourseOptions.values()) {
                if(couseOption?.TREX1__Product__c != null){
                    setProductDiscountids.add(couseOption?.TREX1__Product__c);
                    setProductDiscountidsNonClone.add(couseOption?.TREX1__Product__c);
                }
            }
           
            // Get map of product and discount records based on  course sessions and course option
            Map<Id, TREX1__Product__c> mapProductAndDiscount = getProductDiscountMap(setProductDiscountids);
            Map<Id, TREX1__Product__c> mapProductAndDiscountNonClone = getProductDiscountMap(setProductDiscountidsNonClone);

            Map<Id, TREX1__Price_Level__c> mapPriceLevel = getPriceLevelMap(setProductDiscountids);

            Map<Id, TREX1__Planned_Billing_Schedule__c> mapPlannedBillingSch = getPlannedBillingSchMap(mapPriceLevel.keySet());
            Map<Id, List<PlannedBillingSchedule>> mapIdToPlannedBillingSch= new Map<Id, List<PlannedBillingSchedule>>();
            for(Id plannedBillingSchId : mapPlannedBillingSch.keySet()) {
                if(!mapIdToPlannedBillingSch.containsKey(mapPlannedBillingSch.get(plannedBillingSchId).TREX1__Price_Level__c)) {
                    mapIdToPlannedBillingSch.put(mapPlannedBillingSch.get(plannedBillingSchId).TREX1__Price_Level__c, new List<PlannedBillingSchedule>());
                }
                mapIdToPlannedBillingSch.get(mapPlannedBillingSch.get(plannedBillingSchId).TREX1__Price_Level__c).add(
                    new PlannedBillingSchedule(
                        mapPlannedBillingSch.get(plannedBillingSchId)
                    )
                );
            }

            Map<Id, List<PriceLevel>> mapIdToPriceLevel = new Map<Id, List<PriceLevel>>();
            for(Id priceLevelId : mapPriceLevel.keySet()) {
                if(!mapIdToPriceLevel.containsKey(mapPriceLevel.get(priceLevelId).TREX1__Product__c)) {
                    mapIdToPriceLevel.put(mapPriceLevel.get(priceLevelId).TREX1__Product__c, new List<PriceLevel>());
                }
                mapIdToPriceLevel.get(mapPriceLevel.get(priceLevelId).TREX1__Product__c).add(
                    new PriceLevel(
                        mapPriceLevel.get(priceLevelId),
                        mapIdToPlannedBillingSch.get(priceLevelId)
                    )
                );
            }


            List<ProductAndDiscount> productAndDiscountWrapper = new List<ProductAndDiscount>();
            for(TREX1__Product__c productDiscount : mapProductAndDiscount.values()) {
                productAndDiscountWrapper.add(
                    new ProductAndDiscount(
                        productDiscount,
                        mapIdToPriceLevel.get(productDiscount.Id)
                    )
                );
            }

            List<ProductAndDiscount> nonClonedproductAndDiscountWrapper = new List<ProductAndDiscount>();
            for(TREX1__Product__c productDiscount : mapProductAndDiscountNonClone.values()) {
                nonClonedproductAndDiscountWrapper.add(
                    new ProductAndDiscount(
                        productDiscount, new List<PriceLevel>()
                    )
                );
            }            
            //Clone product discount records, insert and return the cloned wrapper with the ids to product and discount records
            List<ProductAndDiscount> nonClonedProductAndDiscountWrap = new List<ProductAndDiscount>();
            if(dontCloneProducts){
                nonClonedProductAndDiscountWrap = getNonClonedProductDiscount(nonClonedproductAndDiscountWrapper);
            }
            List<ProductAndDiscount> clonedProductAndDiscountWrap = getClonedProductDiscount(productAndDiscountWrapper);
            
            //Enqueue job to handle large number of data and make this process async
            if(!clonedProductAndDiscountWrap.isEmpty())
            System.enqueueJob(new BatchDoubleMe(clonedProductAndDiscountWrap));
            
            // Create maps of cloned records and insert them
            Map<Id, TREX1__Course_Session__c> mapOldCourseSessionIdToClone = cloneCourseSessions(mapCourseSessions);

            if (!mapOldCourseSessionIdToClone.isEmpty()) {
                insert mapOldCourseSessionIdToClone.values();

            }
            Map<Id, TREX1__Course_Option__c> mapOldCourseOptionIdToClone = cloneCourseOptions(mapCourseOptions);
            if (!mapOldCourseOptionIdToClone.isEmpty()) {
                insert mapOldCourseOptionIdToClone.values();
            }

            // Create CSOs for each in request, pointing to cloned parent records
            List<TREX1__Course_Session_Option__c> lstClonedCSOs = new List<TREX1__Course_Session_Option__c>();
            for (TREX1__Course_Session_Option__c cso : lstCSOs) {
                lstClonedCSOs.add(
                    new TREX1__Course_Session_Option__c(
                        TREX1__Course_Session__c   = mapOldCourseSessionIdToClone.get(cso.TREX1__Course_Session__c).Id,
                        TREX1__Course_Option__c    = mapOldCourseOptionIdToClone.get(cso.TREX1__Course_Option__c).Id,
                        TREX1__Option_Available__c = cso.TREX1__Option_Available__c,
                        TREX1__Available_Online__c = cso.TREX1__Available_Online__c
                    )
                );
            }
            if (!lstClonedCSOs.isEmpty()) {
                insert lstClonedCSOs;
            }

            // Create Available Discounts
            List<TREX1__Available_Discounts__c> lstClonedAvailableDiscounts = new List<TREX1__Available_Discounts__c>();
            for (TREX1__Available_Discounts__c availableDiscounts : lstAvailableDiscounts) {
                TREX1__Available_Discounts__c clone = availableDiscounts.clone(false, false, false, false);
                clone.TREX1__Course_Session__c   = availableDiscounts.TREX1__Course_Session__c != null ? (
                                                        mapOldCourseSessionIdToClone.get(availableDiscounts.TREX1__Course_Session__c) != null ?
                                                        mapOldCourseSessionIdToClone.get(availableDiscounts.TREX1__Course_Session__c).Id : null) : null;
                clone.TREX1__Course_Option__c    = availableDiscounts.TREX1__Course_Option__c != null ? 
                                                        (mapOldCourseOptionIdToClone.get(availableDiscounts.TREX1__Course_Option__c) != null ?
                                                        mapOldCourseOptionIdToClone.get(availableDiscounts.TREX1__Course_Option__c).Id : null) : null;
                lstClonedAvailableDiscounts.add(clone);
            }
            if (!lstClonedAvailableDiscounts.isEmpty()) {
                insert lstClonedAvailableDiscounts;
            }

            // Create Available Discounts
            List<TREX1__Assigned_Question_Group__c> lstClonedAQGs = new List<TREX1__Assigned_Question_Group__c>();
            for (TREX1__Assigned_Question_Group__c aqg : lstAQGs) {
                TREX1__Assigned_Question_Group__c clone = aqg.clone(false, false, false, false);
                clone.TREX1__Course_Session__c   = mapOldCourseSessionIdToClone.get(aqg.TREX1__Course_Session__c).Id;
                lstClonedAQGs.add(clone);
            }
            if (!lstClonedAQGs.isEmpty()) {
                insert lstClonedAQGs;
            }

            Result result = new Result();
            result.lstClonedCSOs = lstClonedCSOs;
            result.lstClonedAvailableDiscounts = lstClonedAvailableDiscounts;
            result.lstClonedAQGs = lstClonedAQGs;
            result.lstClonedCourseSessions = mapOldCourseSessionIdToClone.values();
            result.lstClonedCourseOptions = mapOldCourseOptionIdToClone.values();

            lstResults.add(result);
            return lstResults;

        }catch (QueryException e) {
           System.debug('Query Exception hit' + e.getStackTraceString());
            throw new AuraHandledException( exceptionString +  e.getStackTraceString() + contactAdminError);


        }catch(DmlException e){
                //If a DML exception occurs it will go to this statement
                System.debug('DmlException hit ' + e.getStackTraceString());
            	throw new AuraHandledException( exceptionString +  e.getStackTraceString() + contactAdminError);

        }catch (Exception e) {
                //Any other exceptions that occur will go here
                System.debug('Exception hit' + e.getStackTraceString());
                throw new AuraHandledException( exceptionString +  e.getStackTraceString() + contactAdminError);
        } finally {
                // for future use
        }

    }

    /*
    * Clone product and discount records from the wrapper and return the cloned wrapper
    */
    public static List<ProductAndDiscount> getClonedProductDiscount(List<ProductAndDiscount> productDiscountWrapper) {
        List<ProductAndDiscount> clonedProductDiscountWrapper = productDiscountWrapper.clone();
        mapIdToClonedProductDiscount = new Map<Id, TREX1__Product__c>();
        List<TREX1__Product__c> listProductDiscount = new List<TREX1__Product__c>();
        for(ProductAndDiscount productDisc : clonedProductDiscountWrapper) {
            String productDiscountId = productDisc.productAndDiscount.Id;
            productDisc.productAndDiscount = productDisc.productAndDiscount.clone(false);
            mapIdToClonedProductDiscount.put(productDiscountId, productDisc.productAndDiscount);
            if(productDisc.productAndDiscount != null)
                listProductDiscount.add(productDisc.productAndDiscount);
        }
        //if(!dontCloneProducts){
            insert listProductDiscount;
        //}

        return clonedProductDiscountWrapper;
    }      
    public static List<ProductAndDiscount> getNonClonedProductDiscount(List<ProductAndDiscount> productDiscountWrapper) {
        mapIdToNonClonedProductDiscount = new Map<Id, TREX1__Product__c>();
        
        for(ProductAndDiscount productDisc : productDiscountWrapper) {
            String productDiscountId = productDisc?.productAndDiscount.Id;
            if(productDiscountId != null && productDisc.productAndDiscount != null){
                mapIdToNonClonedProductDiscount.put(productDiscountId, productDisc.productAndDiscount);
            }
        }                        
        return productDiscountWrapper;
    }
   
    /**
     * Clone records and modify clones to configuration input
     */

    public static Map<Id, TREX1__Course_Session__c> cloneCourseSessions(
        Map<Id, TREX1__Course_Session__c> mapCourseSessions
    ) {
        Map<Id, TREX1__Course_Session__c> mapOldCourseSessionIdToClone = new Map<Id, TREX1__Course_Session__c>();
        for (TREX1__Course_Session__c cs : mapCourseSessions.values()) {
            TREX1__Course_Session__c clonedCourseSession = cs.clone(false, false, false, false);
            if (fixedDateMode) {
                updateCourseSessionDatesInFixedMode(clonedCourseSession, fixedStartDate, fixedEndDate);
            } else {
                updateCourseSessionDates(clonedCourseSession, daysToAdd);
            }
            if (updateSessionNameMode) {
                updateCourseSessionName(clonedCourseSession);
            }
            clonedCourseSession.TREX1__Session__c = targetSessionId;
            clonedCourseSession.Course_Session_Name__c = clonedCourseSession.Name;
            if(dontCloneProducts){
                clonedCourseSession.TREX1__Product__c = cs.TREX1__Product__c != null ? mapIdToNonClonedProductDiscount.get(cs.TREX1__Product__c).Id : null;
            } else{
                clonedCourseSession.TREX1__Product__c = cs.TREX1__Product__c != null ? mapIdToClonedProductDiscount.get(cs.TREX1__Product__c).Id : null;
            }
            mapOldCourseSessionIdToClone.put(cs.Id, clonedCourseSession);
        }
        return mapOldCourseSessionIdToClone;
    }

    public static Map<Id, TREX1__Course_Option__c> cloneCourseOptions(
        Map<Id, TREX1__Course_Option__c> mapCourseOptions
    ) {
        Map<Id, TREX1__Course_Option__c> mapOldCourseOptionIdToClone = new Map<Id, TREX1__Course_Option__c>();
        for (TREX1__Course_Option__c co : mapCourseOptions.values()) {
            TREX1__Course_Option__c clonedCourseOption = co.clone(false, false, false, false);
            if (fixedDateMode) {
                updateCourseOptionDatesInFixedMode(clonedCourseOption, fixedStartDate, fixedEndDate);
            } else {
                updateCourseOptionDates(clonedCourseOption, daysToAdd);
            }
            if (updateSessionNameMode) {
                updateCourseOptionName(clonedCourseOption);
            }

            if(takeRegistrationFromSession){
                updateCourseOptionFromSession(clonedCourseOption);
            }
            clonedCourseOption.TREX1__Legacy_Id__c = co.Id;
            clonedCourseOption.Course_Option_Name__c = clonedCourseOption.Name;
            clonedCourseOption.TREX1__Product__c = co.TREX1__Product__c != null ? mapIdToClonedProductDiscount.get(co.TREX1__Product__c).Id : null;
            mapOldCourseOptionIdToClone.put(co.Id, clonedCourseOption);
        }
        return mapOldCourseOptionIdToClone;
    }

    /**
     * Helpers replace instances of Session Name or Session Code in record names
     * e.g. Baseball Spring 2022 Tournament => Baseball Summer 2022 Tournament
     */

    private static void updateCourseSessionName(
        TREX1__Course_Session__c cs
    ) {
        if (cs.Name.contains(originalSessionName)) {
            cs.Name = cs.Name.replace(originalSessionName, targetSessionName);
        }
        if (cs.Name.contains(originalSessionCode)) {
            cs.Name = cs.Name.replace(originalSessionCode, targetSessionCode);
        }
    }

    private static void updateCourseOptionName(
        TREX1__Course_Option__c co
    ) {
        if (co.Name.contains(originalSessionName)) {
            co.Name = co.Name.replace(originalSessionName, targetSessionName);
        }
        if (co.Name.contains(originalSessionCode)) {
            co.Name = co.Name.replace(originalSessionCode, targetSessionCode);
        }
    }

    private static void updateCourseOptionFromSession(TREX1__Course_Option__c co) {
        TREX1__Session__c targetSession = getCourseOptionValsFromSessionMap();

        co.TREX1__Available__c = targetSession.TREX1__Available__c;
        co.TREX1__Register_From_Date__c = targetSession.TREX1__Register_From_Date__c;
        co.TREX1__Register_To_Date__c = targetSession.TREX1__Register_To_Date__c;
        co.TREX1__Register_From_Time__c = targetSession.TREX1__Register_From_Time__c;
        co.TREX1__Register_To_Time__c = targetSession.TREX1__Register_To_Time__c;
        co.TREX1__Available_Online__c = targetSession.TREX1__Available_Online__c;
        co.TREX1__Register_Online_From_Date__c = targetSession.TREX1__Register_Online_From_Date__c;
        co.TREX1__Register_Online_To_Date__c = targetSession.TREX1__Register_Online_To_Date__c;
        co.TREX1__Register_Online_From_Time__c = targetSession.TREX1__Register_Online_From_Time__c;
        co.TREX1__Register_Online_To_Time__c = targetSession.TREX1__Register_Online_To_Time__c;
        co.TREX1__Early_Register__c = targetSession.TREX1__Early_Register__c;
        co.TREX1__Early_Register_From_Date__c = targetSession.TREX1__Early_Register_From_Date__c;
        co.TREX1__Early_Register_To_Date__c = targetSession.TREX1__Early_Register_To_Date__c;
        co.TREX1__Early_Register_From_Time__c = targetSession.TREX1__Early_Register_From_Time__c;
        co.TREX1__Early_Register_To_Time__c = targetSession.TREX1__Early_Register_To_Time__c;
        co.TREX1__Early_Register_Online__c = targetSession.TREX1__Early_Register_Online__c;
        co.TREX1__Early_Register_Online_From_Date__c = targetSession.TREX1__Early_Register_Online_From_Date__c;
        co.TREX1__Early_Register_Online_To_Date__c = targetSession.TREX1__Early_Register_Online_To_Date__c;
        co.TREX1__Early_Register_Online_From_Time__c = targetSession.TREX1__Early_Register_Online_From_Time__c;
        co.TREX1__Early_Register_Online_To_Time__c = targetSession.TREX1__Early_Register_Online_To_Time__c;
    }    

    /**
     * Date update helpers
     */

    // Add days to all dates

    private static void updateCourseSessionDates(
        TREX1__Course_Session__c cs,
        Integer daysToAdd
    ) {
        cs.TREX1__Available_Online_From__c = cs.TREX1__Available_Online_From__c != null ? cs.TREX1__Available_Online_From__c + daysToAdd : null;
        cs.TREX1__Available_Online_To__c = cs.TREX1__Available_Online_To__c != null ? cs.TREX1__Available_Online_To__c + daysToAdd : null;
    }

    private static void updateCourseOptionDates(
        TREX1__Course_Option__c co,
        Integer daysToAdd
    ) {
        co.TREX1__Start_Date__c = co.TREX1__Start_Date__c != null ? co.TREX1__Start_Date__c + daysToAdd : null;
        co.TREX1__End_Date__c = co.TREX1__End_Date__c != null ? co.TREX1__End_Date__c + daysToAdd : null;
        co.TREX1__Register_From_Date__c = co.TREX1__Register_From_Date__c != null ? co.TREX1__Register_From_Date__c + daysToAdd : null;
        co.TREX1__Register_To_Date__c = co.TREX1__Register_From_Date__c != null ? co.TREX1__Register_From_Date__c + daysToAdd : null;
        co.TREX1__Register_Online_From_Date__c = co.TREX1__Register_Online_From_Date__c != null ? co.TREX1__Register_Online_From_Date__c + daysToAdd : null;
        co.TREX1__Register_Online_To_Date__c = co.TREX1__Register_Online_To_Date__c != null ? co.TREX1__Register_Online_To_Date__c + daysToAdd : null;
        co.TREX1__Early_Register_From_Date__c = co.TREX1__Early_Register_From_Date__c != null ? co.TREX1__Early_Register_From_Date__c + daysToAdd : null;
        co.TREX1__Early_Register_To_Date__c = co.TREX1__Early_Register_To_Date__c != null ? co.TREX1__Early_Register_To_Date__c + daysToAdd : null;
        co.TREX1__Early_Register_Online_From_Date__c = co.TREX1__Early_Register_Online_From_Date__c != null ? co.TREX1__Early_Register_Online_From_Date__c + daysToAdd : null;
        co.TREX1__Early_Register_Online_To_Date__c = co.TREX1__Early_Register_Online_To_Date__c != null ? co.TREX1__Early_Register_Online_To_Date__c + daysToAdd : null;
        co.TREX1__Age_as_of_date__c = co.TREX1__Age_as_of_date__c != null ? co.TREX1__Age_as_of_date__c + daysToAdd : null;
    }

    // Update dates to configuration start and end dates

    private static void updateCourseSessionDatesInFixedMode(
        TREX1__Course_Session__c cs,
        Date startDate,
        Date endDate
    ) {
        cs.TREX1__Available_Online_From__c = startDate;
        cs.TREX1__Available_Online_To__c = endDate;
    }

    private static void updateCourseOptionDatesInFixedMode(
        TREX1__Course_Option__c co,
        Date startDate,
        Date endDate
    ) {
        co.TREX1__Start_Date__c = startDate;
        co.TREX1__End_Date__c = endDate;
        if(co.TREX1__Register_From_Date__c != null) co.TREX1__Register_From_Date__c = startDate;
        if(co.TREX1__Register_To_Date__c != null) co.TREX1__Register_To_Date__c = endDate;
        if(co.TREX1__Register_Online_From_Date__c !=null) co.TREX1__Register_Online_From_Date__c = startDate;
        if(co.TREX1__Register_Online_To_Date__c != null) co.TREX1__Register_Online_To_Date__c = endDate;
        if(co.TREX1__Early_Register_From_Date__c != null) co.TREX1__Early_Register_From_Date__c = startDate;
        if(co.TREX1__Early_Register_To_Date__c != null) co.TREX1__Early_Register_To_Date__c = endDate;
        if(co.TREX1__Early_Register_Online_From_Date__c != null) co.TREX1__Early_Register_Online_From_Date__c = startDate;
        if(co.TREX1__Early_Register_Online_To_Date__c != null) co.TREX1__Early_Register_Online_To_Date__c = endDate;
        co.TREX1__Age_as_of_date__c = co.TREX1__Age_as_of_date__c != null ? startDate : null;
    }

    /**
     * Set name and session code for original and target sessions
     */

    private static void setSessionDetails() {
        Map<Id, TREX1__Session__c> mapSessions = getSessionMap();
        if(mapSessions != null && !mapSessions.isEmpty()){
            TREX1__Session__c originalSession = mapSessions.get(originalSessionId);
            TREX1__Session__c targetSession = mapSessions.get(targetSessionId);
            if(originalSession != null){
            	originalSessionName = originalSession.Name;
            	originalSessionCode = originalSession.Session_Code__c != null ? originalSession.Session_Code__c : null;
            }
            if(targetSession != null){
                targetSessionName = targetSession.Name;
                targetSessionCode = targetSession.Session_Code__c != null ? targetSession.Session_Code__c : null;
            }
        }

    }



    /**
     * Queries
     */

    private static Map<Id, TREX1__Product__c> getProductDiscountMap(
        Set<Id> setProductDiscountIds
    ) {
        return new Map<Id, TREX1__Product__c>([
        SELECT Id, Name, TREX1__Allow_Multiple__c, TREX1__Available_Externally__c, TREX1__Available_for_Rentals__c, TREX1__Billing_Cancellation_Credit_Setting__c,
                    TREX1__Can_Backdate__c, TREX1__Cancellation_Credit_Setting__c, TREX1__Coupon_Code__c, TREX1__Global_Billing_Group__c, TREX1__Inventory_Group__c,
                    TREX1__Price_Description_Override__c, TREX1__Price_Description__c, TREX1__Require_Stored_Account__c, TREX1__Tax_Configuration__c,
                    TREX1__Discount_End_Date_Setting__c,RecordTypeId
            FROM TREX1__Product__c
            WHERE Id IN :setProductDiscountIds
            WITH SECURITY_ENFORCED
            LIMIT 10000
        ]);
    }

    private static Map<Id, TREX1__Price_Level__c> getPriceLevelMap (
        Set<Id> setProductDiscountIds
    ) {
            return new Map<Id, TREX1__Price_Level__c>([SELECT
                Name, RecordTypeId, TREX1__Booking_Price__c, TREX1__Commission_Fixed_Amount__c, TREX1__Deposit_Fee_Amount__c, TREX1__Deposit_Fee_Revenue_Recognition_Policy__c,
                TREX1__GL_Account_Deposit_Fee_Primary__c, TREX1__GL_Account_Initial_Fee_Primary__c, TREX1__GL_Account_Initial_Fee_Secondary__c, TREX1__GL_Account_Recurring_Fee_Primary__c,
                TREX1__GL_Account_Recurring_Fee_Secondary__c, TREX1__GL_Percent_Initial_Fee_Primary__c, TREX1__GL_Percent_Initial_Fee_Secondary__c, TREX1__GL_Percent_Recurring_Fee_Primary__c,
                TREX1__GL_Percent_Recurring_Fee_Secondary__c, TREX1__Hourly_Rate__c, TREX1__Immediate_Fee_Deferred_Recognition__c, TREX1__Include_Price_In_Public_Description__c,
                TREX1__Initial_Fee_Amount__c, TREX1__Initial_Fee_Revenue_Recognition_Policy__c, TREX1__Master_Sequential__c, TREX1__Number_Of_Terms__c, TREX1__Percentage__c,
                TREX1__Price_Type__c, TREX1__Product__c, TREX1__Public_Price_Note__c, TREX1__Recurring_Revenue_Recognition_Policy__c, TREX1__Sequence_Number__c, TREX1__Tax_Configuration__c,
                TREX1__Max_PBS_Term_Length__c, TREX1__Number_of_Percentage_Discounts__c, TREX1__Perpetual_PBS_Count__c, TREX1__Total_Billing_Schedule_Amount__c, 
                Price_Level_Case_Safe_ID__c
            FROM TREX1__Price_Level__c
            WHERE TREX1__Product__c IN :setProductDiscountIds
            WITH SECURITY_ENFORCED
             LIMIT 10000
            ]);

    }

    private static Map<Id, TREX1__Planned_Billing_Schedule__c> getPlannedBillingSchMap (
        Set<Id> setPriceLevelIds
    ) {
            return new Map<Id, TREX1__Planned_Billing_Schedule__c>([SELECT
                Id, Name, TREX1__Price_Level__c, TREX1__Amount__c, TREX1__Daily_Cost__c, TREX1__End_Date_Setting__c, TREX1__End_Date__c, 
                TREX1__Number_Of_Terms__c, TREX1__Percentage__c, TREX1__Proration_Setting__c, TREX1__Start_Date__c, TREX1__Term_Type__c, TREX1__Total_Billing_Amount__c,
                TREX1__Charging_End_Date_for_One_Time_BS__c,RecordTypeId
            FROM TREX1__Planned_Billing_Schedule__c
            WHERE TREX1__Price_Level__c IN :setPriceLevelIds
            WITH SECURITY_ENFORCED
             LIMIT 10000
            ]);

    }

    private static Map<Id, TREX1__Billing_Schedule__c> getBillingScheduleMap (
        Set<Id> setPlannedBillingSchIds
    ) {
            return new Map<Id, TREX1__Billing_Schedule__c>([SELECT
                Id, Name, TREX1__Transaction_Line_Item__c, TREX1__Amount_Before_Manual_Edit__c, TREX1__Amount_Before_Proration__c, TREX1__Amount_Remaining__c, TREX1__Amount__c,
                TREX1__Billing_Event_Count__c, TREX1__Billing_Finished__c, TREX1__Billing_Schedule_Group__c, TREX1__Billing_Schedule_To_Customize__c, TREX1__Billing_Schedule_To_Edit__c,
                TREX1__Billing_Schedule_To_Replace__c, TREX1__Charge_Immediately_Replacement__c, TREX1__Cloned_Billing_Schedule__c, TREX1__Deactivation_Time__c, TREX1__Discount_Amount__c,
                TREX1__Discount_Percent__c, TREX1__Do_Not_Generate_AR__c, TREX1__Edit_Reason__c, TREX1__End_Date__c, TREX1__Global_Billing_Group_Id__c, TREX1__Is_Billable__c,
                TREX1__Is_Converted_For_Immediate_Charge__c, TREX1__Is_Deactivated__c, TREX1__Is_Payment_Arrangement__c, TREX1__Is_Third_Party__c, TREX1__Last_Date_Billed__c,
                TREX1__Membership_Group__c, TREX1__Membership__c, TREX1__Net_Price__c, TREX1__Number_Of_Terms__c, TREX1__Original_Billing_Schedule_Amount__c,
                TREX1__Original_Discount_Percent__c, TREX1__Override_Reason__c, TREX1__Owned_Add_On__c, TREX1__Parent_Billing_Schedule__c, TREX1__Parent_Converted_Billing_Schedule__c,
                TREX1__Payment_Arrangement__c, TREX1__Planned_Billing_Schedule__c, TREX1__Price_Overridden__c, TREX1__Prorated_Percentage__c, TREX1__Prorated__c, TREX1__Registration__c,
                TREX1__Split_Number__c, TREX1__Split_Parent__c, TREX1__Start_Date__c, TREX1__Surcharge_Configuration__c, TREX1__Tax_Level_1_Amount__c, TREX1__Tax_Level_1_GL_Code__c, TREX1__Tax_Level_1_Name__c,
                TREX1__Tax_Level_1_Percentage__c, TREX1__Tax_Level_2_Amount__c, TREX1__Tax_Level_2_GL_Code__c, TREX1__Tax_Level_2_Name__c, TREX1__Tax_Level_2_Percentage__c, TREX1__Tax_Level_3_Amount__c,
                TREX1__Tax_Level_3_GL_Code__c, TREX1__Tax_Level_3_Name__c, TREX1__Tax_Level_3_Percentage__c, TREX1__Term_Type__c, TREX1__Total_Billing_Amount__c, Stored_Account__c, recpay_Bill_To_Account__c,
                recpay_CC_Surcharge_Percentage__c, recpay_Payer_Account__c, TREX1__bs_Global_Billing_Group__c, TREX1__bs_Planned_Billing_Schedule__c, TREX1__TP2StoredAccount__c, Stored_Account_Status__c,
                recpay_Is_SA_Mirror_Valid__c
            FROM TREX1__Billing_Schedule__c
            WHERE TREX1__Planned_Billing_Schedule__c IN :setPlannedBillingSchIds
            WITH SECURITY_ENFORCED
             LIMIT 10000
            ]);

    }


    private static Map<Id, TREX1__Course_Session__c> getCourseSessionMap(
        Set<Id> setCourseSessionIds
    ) {
        return new Map<Id, TREX1__Course_Session__c>([
            SELECT Id, Name, TREX1__Available__c, TREX1__Available_Online__c, TREX1__Available_Online_From__c,
                   TREX1__Available_Online_To__c, TREX1__Code__c, TREX1__Course__c, TREX1__Description__c, TREX1__Expiry_Extension_Seconds__c,
                   TREX1__External_Alert__c, TREX1__Free_Membership_End_Date__c, TREX1__Free_Membership_Start_Date__c, TREX1__Free_Membership_Type__c,
                   TREX1__Initial_Seconds_To_Expiry__c, TREX1__Internal_Alert__c, TREX1__Max_Expiry_Seconds__c, TREX1__Num_Classroom_Assignments__c,
                   TREX1__Num_Option_Entitlements__c, TREX1__Product__c, TREX1__Required_of_Employees_10_Registrants__c, TREX1__Reservation_Expiry_Seconds__c,
                   TREX1__Rich_Description__c, TREX1__Session__c, TREX1__Status__c, TREX1__Supervisor__c, TREX1__Supervisor_Email__c,
                   TREX1__Transfer_Fee__c, TREX1__Transfer_GL_Account__c, TREX1__Transfer_in_within_Program__c, TREX1__Transfer_out_within_Program__c,
                   TREX1__Waitlist_Message__c, TREX1__Withdrawal_Days__c, TREX1__Withdrawal_Fee__c, TREX1__Withdrawal_GL_Account__c, TREX1__Withdrawal_Policy__c,
                   Course_Session_Name__c

              FROM TREX1__Course_Session__c
             WHERE Id IN :setCourseSessionIds
              WITH SECURITY_ENFORCED
             LIMIT 10000
        ]);
    }

    private static Map<Id, TREX1__Course_Option__c> getCourseOptionMap(
        Set<Id> setCourseOptionIds
    ) {
        return new Map<Id, TREX1__Course_Option__c>([
            SELECT Id, Name, Day_of_Week_Code__c, TREX1__Age_as_of_date__c, TREX1__Age_Max__c, TREX1__Age_Min__c,
                   TREX1__Attendance_Group__c, TREX1__Available__c, TREX1__Available_Online__c, TREX1__Capacity__c,
                   TREX1__Code__c, TREX1__Day_of_Week__c, TREX1__Description__c, TREX1__Scanning_Location__c,
                   TREX1__Display_Number_of_Classes__c, TREX1__Early_Register__c, TREX1__Early_Register_From_Date__c,
                   TREX1__Early_Register_From_Time__c, TREX1__Early_Register_Online__c, TREX1__Early_Register_Online_From_Date__c,
                   TREX1__Early_Register_Online_From_Time__c, TREX1__Early_Register_Online_To_Date__c,
                   TREX1__Early_Register_Online_To_Time__c, TREX1__Early_Register_To_Date__c, TREX1__Early_Register_To_Time__c,
                   TREX1__Enable_Automated_Waitlist__c, TREX1__Enable_Calendar_Booking_Download__c, TREX1__Enable_Reservation__c,
                   TREX1__End_Date__c, TREX1__End_Time__c, TREX1__Grade_Range__c, TREX1__Instructor__c, TREX1__Location__c,
                   TREX1__Number_of_Classes__c, TREX1__Overbooking_Capacity__c, TREX1__Product__c, TREX1__Register_From_Date__c,
                   TREX1__Register_From_Time__c, TREX1__Register_Online_From_Date__c, TREX1__Register_Online_From_Time__c,
                   TREX1__Register_Online_To_Date__c, TREX1__Register_Online_To_Time__c, TREX1__Register_To_Date__c,
                   TREX1__Register_To_Time__c, TREX1__Setup_Notes__c, TREX1__Setup_Time_Required__c, TREX1__Show_Age_Range__c,
                   TREX1__Show_Capacity_Online__c, TREX1__Show_Cost__c, TREX1__Show_Days__c, TREX1__Show_Grade_Range__c,
                   TREX1__Show_Instructor__c, TREX1__Show_Location__c, TREX1__Show_Time_Window__c, TREX1__Show_Watlist_Capacity__c,
                   TREX1__Special_Instructions__c, TREX1__Start_Date__c, TREX1__Start_Time__c, TREX1__Status__c,
                   TREX1__Tear_Down_Notes__c, TREX1__Tear_Down_Time_Required__c, TREX1__Transfer_in_within_Program__c,
                   TREX1__Transfer_out_within_Program__c, TREX1__Type__c, TREX1__Unlimited_Capacity__c,
                   TREX1__Unlimited_Overbooking_Capacity__c, TREX1__Unlimited_Waitlist_Capacity__c,
                   TREX1__Unnamed_Group_Reg_Max_Tickets__c, TREX1__Unnamed_Group_Reg_Min_Tickets__c,
                   TREX1__Unnamed_Group_Registration__c, TREX1__Waitlist_Capacity__c, TREX1__Waitlist_Message__c,
                   TREX1__Waitlist_Pending_Confirmation_Total__c, TREX1__Waitlist_Total__c,
                   Course_Option_Name__c, Primary_Facility__c
              FROM TREX1__Course_Option__c
             WHERE Id IN :setCourseOptionIds
              WITH SECURITY_ENFORCED
             LIMIT 10000
        ]);
    }

    private static Map<Id, TREX1__Session__c> getSessionMap() {
        if (mapCachedSessions == null) {
            mapCachedSessions = new Map<Id, TREX1__Session__c>([
                SELECT Id, Name, Session_Code__c FROM TREX1__Session__c WHERE Id = :originalSessionId OR Id = :targetSessionId WITH SECURITY_ENFORCED LIMIT 2
            ]);
        }
        return mapCachedSessions;
    }
    private static TREX1__Session__c getCourseOptionValsFromSessionMap() {
        if (cachedSession == null) {
            cachedSession = [
                SELECT Id, Name, Session_Code__c, TREX1__Available__c,TREX1__Register_From_Date__c,TREX1__Register_To_Date__c,TREX1__Register_From_Time__c,TREX1__Register_To_Time__c,TREX1__Available_Online__c,TREX1__Register_Online_From_Date__c,TREX1__Register_Online_To_Date__c,TREX1__Register_Online_From_Time__c,TREX1__Register_Online_To_Time__c,TREX1__Early_Register__c,TREX1__Early_Register_From_Date__c,TREX1__Early_Register_To_Date__c,TREX1__Early_Register_From_Time__c,TREX1__Early_Register_To_Time__c,TREX1__Early_Register_Online__c,TREX1__Early_Register_Online_From_Date__c,TREX1__Early_Register_Online_To_Date__c,TREX1__Early_Register_Online_To_Time__c,TREX1__Early_Register_Online_From_Time__c
                FROM TREX1__Session__c WHERE Id = :targetSessionId WITH SECURITY_ENFORCED LIMIT 1
			];
        }
        return cachedSession;
    }

    /**
     * Wrappers
     */

    public class ProductAndDiscount {
        public TREX1__Product__c productAndDiscount {get; set;}
        public List<priceLevel> priceLevels {get; set;}
        public ProductAndDiscount(
            TREX1__Product__c productAndDiscount,
            List<priceLevel> priceLevels
        ){
            this.productAndDiscount = productAndDiscount;
            this.priceLevels = priceLevels;
        }
    }

    public class PriceLevel {
        public TREX1__Price_Level__c priceLevel {get; set;}
        public List<PlannedBillingSchedule> plannedBillingSchedules{get; set;}
        public PriceLevel(
            TREX1__Price_Level__c priceLevel,
            List<PlannedBillingSchedule> plannedBillingSchedules
        ){
            this.priceLevel = priceLevel;
            this.plannedBillingSchedules = plannedBillingSchedules;
        }
    }

    public class PlannedBillingSchedule {
        public TREX1__Planned_Billing_Schedule__c plannedBillingSch{get; set;}
        public PlannedBillingSchedule(
            TREX1__Planned_Billing_Schedule__c plannedBillingSch
        ){
            this.plannedBillingSch = plannedBillingSch;
        }
    }

    public class Request {
        @InvocableVariable(required=true description='Original Course Session Options')
        public List<TREX1__Course_Session_Option__c> lstCSOs;
        @InvocableVariable(required=true description='Original Session')
        public List<TREX1__Available_Discounts__c> lstAvailableDiscounts;
        @InvocableVariable(required=true description='Original Session')
        public List<TREX1__Assigned_Question_Group__c> lstAQGs;
        @InvocableVariable(required=true description='Original Session')
        public Id originalSessionId;
        @InvocableVariable(required=true description='Target Session')
        public Id targetSessionId;
        @InvocableVariable(description='Fixed Date Mode')
        public Boolean fixedDateMode;
        @InvocableVariable(description='Days to Add')
        public Integer daysToAdd;
        @InvocableVariable(description='Fixed Start Date')
        public Date fixedStartDate;
        @InvocableVariable(description='Fixed End Date')
        public Date fixedEndDate;
        @InvocableVariable(description='Update Session Names in Record Names')
        public Boolean updateSessionNameMode;
        @InvocableVariable(description='Take Registration Values from Target Session')
        public Boolean takeRegistrationFromSession;
        @InvocableVariable(description='Don\'t Clone Course Session Product')
        public Boolean dontCloneProducts;
    }

    public class Result {
        @InvocableVariable(description='Cloned Course Sessions')
        public List<TREX1__Course_Session__c> lstClonedCourseSessions;
        @InvocableVariable(description='Cloned Course Options')
        public List<TREX1__Course_Option__c> lstClonedCourseOptions;
        @InvocableVariable(description='Cloned Course Session Options')
        public List<TREX1__Course_Session_Option__c> lstClonedCSOs;
        @InvocableVariable(description='Cloned Available Discounts')
        public List<TREX1__Available_Discounts__c> lstClonedAvailableDiscounts;
        @InvocableVariable(description='Cloned Assigned Question Group')
        public List<TREX1__Assigned_Question_Group__c> lstClonedAQGs;
    }

}