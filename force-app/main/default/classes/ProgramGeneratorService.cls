public with sharing class ProgramGeneratorService {

    private static final String STATUS_STAGED = 'Staged';
    private static final String STATUS_PROCESSED = 'Processed';
    private static final String LOCATION_BPC = 'Battery Park City';
    private static final String LOCATION_UES = 'Upper East Side';
    private static final String NEW_COURSE_SESSION_STATUS = 'Draft';
    private static final String COURSE_OPTION_APPROVAL_STATUS = 'Pending Approval';
    private static final String NEW_COURSE_OPTION_STATUS = 'Draft';
    private static final String PRICE_TYPE_PUBLIC = 'Non-Member';
    private static final String PRICE_TYPE_MEMBER = 'Member';
    private static final String RECORD_TYPE_PRODUCT = 'Registration_Fee';
    private static final String RECORD_TYPE_PRICE_LEVEL = 'Dollar';
    private static final String RECORD_TYPE_PBS = 'Fee';
    private static final String GBG_NAME = 'Asphalt Green';
    private static final String COURSE_OPTION_TYPE = 'Standard Course Option';

    private static final Decimal TRANSFER_FEE = 15.00;
    private static final Decimal WITHDRAWAL_FEE = 15.00;
    private static final Decimal INITIAL_FEE_AMOUNT = 25.00;

    private static Id gbgId;
    private static Date pbsStartDate = Date.newInstance(2024,1,1);

    private Map<Id, Staged_Program__c> stagedPrograms;
    private Map<Id, TREX1__Session__c> sessions;
    private Map<String, TREX1__Course_Session__c> courseSessions = new Map<String, TREX1__Course_Session__c>();
    private Map<String, TREX1__Course_Option__c> courseOptions = new Map<String, TREX1__Course_Option__c>();
    private Map<String, TREX1__Product__c> products = new Map<String, TREX1__Product__c>();

    // Utility maps
    private Map<String, Staged_Program__c> mapProdKeyToStagedProgram;
    private Map<String, Staged_Program__c> mapCsKeyToStagedProgram;

    /**
     * Record types
     */
    private static Id productRecordTypeId = Schema.SObjectType.TREX1__Product__c
        .getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_PRODUCT).getRecordTypeId();

    private static Id priceLevelRecordTypeId = Schema.SObjectType.TREX1__Price_Level__c
        .getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_PRICE_LEVEL).getRecordTypeId();
    
    private static Id pbsRecordTypeId = Schema.SObjectType.TREX1__Planned_Billing_Schedule__c
        .getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_PBS).getRecordTypeId();

    /**
     * Constructor
     */
    public ProgramGeneratorService(Set<Id> stagedProgramIds) {
        this.stagedPrograms = queryForStagedPrograms(stagedProgramIds);
    }

    /**
     * @description Main entry point for processing staged programs.
     * Processes staged programs provided in constructor
     * @returns void
     */
    public void run() {
        try {
            // Get map of course sessions
            System.debug(':::: Getting course session map');
            Map<String, TREX1__Course_Session__c> mapCourseSessions = getCourseSessionMap();
    
            // Get map of products
            System.debug(':::: Getting product map');
            Map<String, TREX1__Product__c> mapProducts = getProductMap();
    
            // Create course options
            System.debug(':::: Creating course options');
            List<TREX1__Course_Option__c> lstCos = createCourseOptions();
    
            // Update staged programs
            System.debug(':::: Updating staged programs');
            List<Staged_Program__c> lstStagedProgramsToUpdate = new List<Staged_Program__c>();
            for (Staged_Program__c sp : stagedPrograms.values()) {
                lstStagedProgramsToUpdate.add(
                    new Staged_Program__c(
                        Id = sp.Id,
                        Status__c = STATUS_PROCESSED,
                        Course_Session__c = courseSessions.get(sp.Course_Session_Key__c).Id,
                        Course_Option__c = courseOptions.get(sp.Id).Id
                    )
                );
            }
            Database.update(lstStagedProgramsToUpdate, true, AccessLevel.USER_MODE);
        } catch (Exception e) {
            System.debug('::::: received exception --> ' + e.getMessage());
        }
    }

    /**
     * Get a map of course sessions by course session key
     * Includes pre-existing and newly created course sessions
     */
    private Map<String, TREX1__Course_Session__c> getCourseSessionMap() {
        // Get existing course sessions from course session keys
        mapCsKeyToStagedProgram = new Map<String, Staged_Program__c>();
        for (Staged_Program__c sp : stagedPrograms.values()) {
            mapCsKeyToStagedProgram.put(sp.Course_Session_Key__c, sp);
        }
        for (TREX1__Course_Session__c cs : queryForCourseSessions(mapCsKeyToStagedProgram.keySet())) {
            courseSessions.put(cs.Key__c, cs);
        }

        // Create new course sessions for remaining course session keys
        List<Staged_Program__c> lstSpsWithNewCs = new List<Staged_Program__c>();
        for (String csKey : mapCsKeyToStagedProgram.keySet()) {
            if (!courseSessions.containsKey(csKey)) {
                lstSpsWithNewCs.add(mapCsKeyToStagedProgram.get(csKey));
            }
        }
        for (TREX1__Course_Session__c newCs : createNewCourseSessions(lstSpsWithNewCs)) {
            String newCsKey = newCs.Name + '-' + String.valueOf(newCs.TREX1__Course__c) + '-' + String.valueOf(newCs.TREX1__Session__c);
            courseSessions.put(newCsKey, newCs);
        }

        // Return course session map
        return courseSessions;
    }

    /**
     * Get a map of products with non-member price level by price level key
     */
    private Map<String, TREX1__Product__c> getProductMap() {
        System.debug(':::: Entered get product map');
        // Get existing products for price level keys
        mapProdKeyToStagedProgram = new Map<String, Staged_Program__c>();
        for (Staged_Program__c sp : stagedPrograms.values()) {
            mapProdKeyToStagedProgram.put(sp.Price_Level_Key__c, sp);
        }
        System.debug(':::: Populated mapProdKeyToStagedProgram map ');
        for (TREX1__Product__c prod : queryForProducts(mapProdKeyToStagedProgram.keySet())) {
            products.put(prod.TREX1__Price_Levels__r[0].Key__c, prod);
        }
        System.debug(':::: Populated products map with existing products');

        // Create new products, price levels, and pbs
        Map<String, Staged_Program__c> mapSpsWithNewProds = new Map<String, Staged_Program__c>();
        for (String prodKey : mapProdKeyToStagedProgram.keySet()) {
            if (!products.containsKey(prodKey)) {
                if (!mapProdKeyToStagedProgram.containsKey(prodKey)) {
                    System.debug(':::: NO KEY!');
                    System.debug(':::: prodKey --> ' + prodKey);
                    System.debug(':::: mapProdKeyToStagedProgram --> ' + mapProdKeyToStagedProgram);
                    for (String val : mapProdKeyToStagedProgram.keySet()) {
                        System.debug(':::: entry --> ' + val);
                    }
                }
                mapSpsWithNewProds.put(
                    prodKey, 
                    mapProdKeyToStagedProgram.get(prodKey)
                );
            }
        }
        System.debug(':::: Ready to create new products');
        List<TREX1__Product__c> lstNewProducts = createNewProducts(mapSpsWithNewProds.values());
        System.debug(':::: Adding new products to product map');
        for (TREX1__Product__c newProd : lstNewProducts) {
            products.put(newProd.Key__c, newProd);
        }

        // Return map of products
        return products;
    }

    /**
     * Create course sessions for unmatched course session keys in staged programs
     */
    private List<TREX1__Course_Session__c> createNewCourseSessions(
        List<Staged_Program__c> lstStagedPrograms
    ) {
        List<TREX1__Course_Session__c> lstCourseSessions = new List<TREX1__Course_Session__c>();

        for (Staged_Program__c newCsSp : lstStagedPrograms) {
            TREX1__Session__c session = getSessionMap().get(newCsSp.Session__c);
            TREX1__Course_Session__c newCs = new TREX1__Course_Session__c();
            newCs.Name = newCsSp.Course_Session_Name__c;
            newCs.TREX1__Course__c = newCsSp.Course__c;
            newCs.TREX1__Session__c = session.Id;
            newCs.TREX1__Status__c = NEW_COURSE_SESSION_STATUS;
            newCs.TREX1__Product__c = session.Free_Product__c;

            // Set location-specific properties
            if (newCsSp.Location__r.Name == LOCATION_BPC) {
                newCs.TREX1__Free_Membership_Type__c = session.BPC_Free_Membership_Type__c;
                newCs.TREX1__Transfer_GL_Account__c = session.BPC_Other_Fees_GL_Account__c;
                newCs.TREX1__Withdrawal_GL_Account__c = session.BPC_Other_Fees_GL_Account__c;
            } 
            else if (newCsSp.Location__r.Name == LOCATION_UES) {
                newCs.TREX1__Free_Membership_Type__c = session.UES_Free_Membership_Type__c;
                newCs.TREX1__Transfer_GL_Account__c = session.UES_Other_Fees_GL_Account__c;
                newCs.TREX1__Withdrawal_GL_Account__c = session.UES_Other_Fees_GL_Account__c;
            }

            // Free membership dates
            newCs.TREX1__Free_Membership_Start_Date__c = session.TREX1__Start_Date__c;
            newCs.TREX1__Free_Membership_End_Date__c = session.TREX1__End_Date__c;

            // Transfer/withdrawal policies
            newCs.TREX1__Transfer_Fee__c = TRANSFER_FEE;
            newCs.TREX1__Withdrawal_Fee__c = WITHDRAWAL_FEE;
            newCs.TREX1__Transfer_in_within_Program__c = true;
            newCs.TREX1__Transfer_out_within_Program__c = true;

            // Availability
            newCs.TREX1__Available__c = true;
            newCs.TREX1__Available_Online__c = true;
            newCs.TREX1__Available_Online_From__c = session.TREX1__Available_Online_From__c;
            newCs.TREX1__Available_Online_To__c = session.TREX1__Available_Online_To__c;
            newCs.Send_Welcome_Email__c = true;

            newCs.TREX1__Legacy_Id__c = String.valueOf(newCsSp.Id);

            lstCourseSessions.add(newCs);
        }

        Database.insert(lstCourseSessions, true, AccessLevel.USER_MODE);

        return lstCourseSessions;
    }

    /**
     * Create course option records from staged program details
     */
    private List<TREX1__Course_Option__c> createCourseOptions() {
        List<TREX1__Course_Option__c> lstOptions = new List<TREX1__Course_Option__c>();

        for (Staged_Program__c sp : stagedPrograms.values()) {
            TREX1__Session__c session = getSessionMap().get(sp.Session__c);

            TREX1__Course_Option__c co = new TREX1__Course_Option__c();
            co.Name = sp.Course_Option_Name__c;
            co.TREX1__Code__c = sp.Course_Option_Code__c;
            co.TREX1__Type__c = COURSE_OPTION_TYPE;
            co.Approval_Status__c = COURSE_OPTION_APPROVAL_STATUS;
            co.TREX1__Status__c = NEW_COURSE_OPTION_STATUS;
            co.Minimum_Participants__c = sp.Minimum_Participants__c;
            co.TREX1__Capacity__c = sp.Capacity__c;
            co.TREX1__Age_Min__c = sp.Minimum_Age__c;
            co.TREX1__Age_Max__c = sp.Maximum_Age__c;
            co.TREX1__Age_as_of_date__c = sp.Start_Date__c;
            co.TREX1__Start_Date__c = sp.Start_Date__c;
            co.TREX1__End_Date__c = sp.End_Date__c;
            co.TREX1__Start_Time__c = sp.Start_Time__c;
            co.TREX1__End_Time__c = sp.End_Time__c;
            co.Exception_Dates__c = sp.Exception_Dates__c;
            co.Primary_Facility__c = sp.Primary_Facility__c;
            co.TREX1__Location__c = sp.Location__c;
            co.TREX1__Day_of_Week__c = sp.Days_of_Week__c;
            co.NonMemberPrice__c = sp.Public_Price__c;
            co.TREX1__Available__c = true;
            co.TREX1__Available_Online__c = true;

            // Product
            co.TREX1__Product__c = products.get(sp.Price_Level_Key__c).Id;

            // Static values
            co.TREX1__Enable_Automated_Waitlist__c = true;
            co.TREX1__Overbooking_Capacity__c = 2;
            co.TREX1__Pending_Active_Total__c = 0;
            co.TREX1__Setup_Time_Required__c = 0;
            co.TREX1__Tear_Down_Time_Required__c = 0;
            co.TREX1__Transfer_in_within_Program__c = true;
            co.TREX1__Transfer_out_within_Program__c = true;
            co.TREX1__Unlimited_Capacity__c = false;
            co.TREX1__Unlimited_Overbooking_Capacity__c = false;
            co.TREX1__Unlimited_Waitlist_Capacity__c = true;
            co.TREX1__Waitlist_Capacity__c = 0;
            co.TREX1__Waitlist_Pending_Confirmation_Total__c = 0;
            co.TREX1__Waitlist_Total__c = 0;
            co.TREX1__Registration_Total__c = 0;
            co.TREX1__Enable_Calendar_Booking_Download__c = false;

            // Online display card
            co.TREX1__Display_Number_of_Classes__c = true;
            co.TREX1__Show_Age_Range__c = true;
            co.TREX1__Show_Capacity_Online__c = true;
            co.TREX1__Show_Cost__c = true;
            co.TREX1__Show_Days__c = true;
            co.TREX1__Show_Grade_Range__c = false;
            co.TREX1__Show_Instructor__c = false;
            co.TREX1__Show_Location__c = true;
            co.TREX1__Show_Time_Window__c = true;
            co.TREX1__Show_Watlist_Capacity__c = false;

            // Registration availability info
            co.TREX1__Register_From_Date__c = session.TREX1__Register_From_Date__c;
            co.TREX1__Register_To_Date__c = sp.End_Date__c;
            co.TREX1__Register_Online_From_Date__c = session.TREX1__Register_Online_From_Date__c;
            co.TREX1__Register_Online_To_Date__c = sp.End_Date__c;
            co.TREX1__Register_From_Time__c = '8:30 AM';
            co.TREX1__Register_To_Time__c = sp.Start_Time__c;
            co.TREX1__Register_Online_From_Time__c = '8:30 AM';
            co.TREX1__Register_Online_To_Time__c = sp.Start_Time__c;
            co.TREX1__Early_Register__c = false;
            co.TREX1__Early_Register_Online__c = false;
            co.TREX1__Early_Register_From_Time__c = '12:00 AM';
            co.TREX1__Early_Register_Online_From_Time__c = '12:00 AM';
            co.TREX1__Early_Register_Online_To_Time__c = '11:59 PM';
            co.TREX1__Early_Register_To_Time__c = '11:59 PM';
            
            co.TREX1__Legacy_Id__c = sp.Id;
            lstOptions.add(co);
        }

        Database.insert(lstOptions, true, AccessLevel.USER_MODE);

        // Create csos
        List<TREX1__Course_Session_Option__c> lstCsos = new List<TREX1__Course_Session_Option__c>();
        for (TREX1__Course_Option__c co : lstOptions) {
            TREX1__Course_Session_Option__c newCso = new TREX1__Course_Session_Option__c();
            String csKey = stagedPrograms.get(co.TREX1__Legacy_Id__c).Course_Session_Key__c;
            newCso.TREX1__Course_Session__c = courseSessions.get(csKey).Id;
            newCso.TREX1__Course_Option__c = co.Id;
            newCso.TREX1__Option_Available__c = true;
            newCso.TREX1__Available_Online__c = true;
            lstCsos.add(newCso);
            courseOptions.put(co.TREX1__Legacy_Id__c, co);
        }
        Database.insert(lstCsos, true, AccessLevel.USER_MODE);

        return lstOptions;
    }

    /**
     * Create new products, price levels, and pbs for unmatched price level keys
     */
    private List<TREX1__Product__c> createNewProducts(
        List<Staged_Program__c> lstStagedPrograms
    ) {
        // Products
        System.debug(':::: Adding products');
        List<TREX1__Product__c> lstProducts = new List<TREX1__Product__c>();
        for (Staged_Program__c sp : lstStagedPrograms) {
            TREX1__Product__c prod = new TREX1__Product__c();
            prod.Name = sp.GL_Account__r.Name.left(70) + ' - $' + sp.Public_Price__c.format();
            prod.RecordTypeId = productRecordTypeId;
            prod.Key__c = sp.Price_Level_Key__c;
            prod.TREX1__Global_Billing_Group__c = getGlobalBillingGroupId();
            prod.TREX1__Price_Description_Override__c = true;
            prod.TREX1__Price_Description__c = sp.Has_Member_Price__c
                ? 'Public $' + sp.Public_Price__c.format() + '/Member $' + sp.Member_Price__c.format()
                : '$' + sp.Public_Price__c.format();
            prod.TREX1__Billing_Cancellation_Credit_Setting__c = 'Active Days Prorated Credit';
            prod.NonMemberPrice__c = sp.Public_Price__c;
            prod.TREX1__Allow_Multiple__c = true;
            prod.TREX1__Available_Externally__c = true;
            prod.TREX1__Legacy_Id__c = sp.Id;
            lstProducts.add(prod);
        }
        Database.insert(lstProducts, true, AccessLevel.USER_MODE);

        // Price Levels
        System.debug(':::: Adding price levels');
        List<TREX1__Price_Level__c> lstPriceLevels = new List<TREX1__Price_Level__c>();
        for (TREX1__Product__c prod : lstProducts) {
            lstPriceLevels.add( getNewPriceLevel(prod, PRICE_TYPE_PUBLIC) );
            if (mapProdKeyToStagedProgram.get(prod.Key__c).Has_Member_Price__c) {
                lstPriceLevels.add( getNewPriceLevel(prod, PRICE_TYPE_MEMBER) );
            }
        }
        Database.insert(lstPriceLevels, true, AccessLevel.USER_MODE);

        // Planned Billing Schedules
        System.debug(':::: Adding pbs');
        List<TREX1__Planned_Billing_Schedule__c> lstPbs = new List<TREX1__Planned_Billing_Schedule__c>();
        for (TREX1__Price_Level__c pl : lstPriceLevels) {
            Staged_Program__c sp = stagedPrograms.get(pl.TREX1__Legacy_Id__c);
            TREX1__Planned_Billing_Schedule__c pbs = new TREX1__Planned_Billing_Schedule__c();
            pbs.RecordTypeId = pbsRecordTypeId;
            pbs.Name = pl.Name;
            pbs.TREX1__Price_Level__c = pl.Id;
            pbs.TREX1__End_Date_Setting__c = 'Fixed End Date';
            pbs.TREX1__Number_Of_Terms__c = 1;
            pbs.TREX1__Proration_Setting__c = 'Do Not Prorate';
            pbs.TREX1__Start_Date__c = pbsStartDate;
            pbs.TREX1__Term_Type__c = 'One Time';
            pbs.TREX1__Amount__c = pl.TREX1__Price_Type__c == PRICE_TYPE_PUBLIC ? sp.Public_Price__c : sp.Member_Price__c;
            pbs.TREX1__Legacy_Id__c = sp.Id;
            lstPbs.add(pbs);
        }
        Database.insert(lstPbs, true, AccessLevel.USER_MODE);

        // Return products
        return lstProducts;
    }

    /**
     * Returns a single price level sobject for a given produce and price type
     */
    private TREX1__Price_Level__c getNewPriceLevel(
        TREX1__Product__c product,
        String priceType
    ) {
        System.debug(':::: Getting new price level for price type --> ' + priceType);
        Staged_Program__c sp = mapProdKeyToStagedProgram.get(product.Key__c);
        System.debug(':::: Getting session');
        TREX1__Session__c session = getSessionMap().get(sp.Session__c);
        System.debug(':::: Getting admin gl account');
        Id adminGlAccountId = sp.Location__r.Name == LOCATION_BPC 
            ? session.BPC_Admin_GL_Account__c 
            : session.UES_Admin_GL_Account__c;

        TREX1__Price_Level__c pl = new TREX1__Price_Level__c();
        pl.Name = product.Name + ' ' + priceType;
        pl.RecordTypeId = priceLevelRecordTypeId;
        pl.TREX1__Product__c = product.Id;
        pl.TREX1__Price_Type__c = priceType;
        pl.Initial_Fee_is_Administrative__c = true;
        pl.TREX1__Initial_Fee_Amount__c = INITIAL_FEE_AMOUNT;
        pl.TREX1__Deposit_Fee_Revenue_Recognition_Policy__c = 'On Transaction Firmed';
        pl.TREX1__Initial_Fee_Revenue_Recognition_Policy__c = 'On Transaction Firmed';
        pl.TREX1__Recurring_Revenue_Recognition_Policy__c = 'On Start Date';
        pl.TREX1__GL_Account_Deposit_Fee_Primary__c = sp.GL_Account__c;
        pl.TREX1__GL_Account_Initial_Fee_Primary__c = adminGlAccountId;
        pl.TREX1__GL_Account_Initial_Fee_Secondary__c = adminGlAccountId;
        pl.TREX1__GL_Account_Recurring_Fee_Primary__c = sp.GL_Account__c;
        pl.TREX1__GL_Account_Recurring_Fee_Secondary__c = sp.GL_Account__c;
        pl.TREX1__GL_Percent_Initial_Fee_Primary__c = 100;
        pl.TREX1__GL_Percent_Initial_Fee_Secondary__c = 0;
        pl.TREX1__GL_Percent_Recurring_Fee_Primary__c = 100;
        pl.TREX1__GL_Percent_Recurring_Fee_Secondary__c = 0;
        pl.TREX1__Include_Price_In_Public_Description__c = true;

        pl.TREX1__Legacy_Id__c = sp.Id;

        return pl;
    }

    /**
     * Query for existing course sessions records based on a set of course session keys
     */
    private List<TREX1__Course_Session__c> queryForCourseSessions(
        Set<String> setCourseSessionKeys
    ) {
        return [
            SELECT Id, 
                   Name, 
                   Key__c
              FROM TREX1__Course_Session__c 
             WHERE Key__c IN :setCourseSessionKeys
              WITH USER_MODE
        ];
    }

    /**
     * Query for existing product records based on a set of price level keys
     */
    private List<TREX1__Product__c> queryForProducts(
        Set<String> setPriceLevelKeys
    ) {
        return [
            SELECT Id, 
                   Name,
                   (SELECT Id, 
                           Key__c
                      FROM TREX1__Price_Levels__r
                     WHERE TREX1__Price_Type__c = :PRICE_TYPE_PUBLIC)
              FROM TREX1__Product__c 
             WHERE Id IN (SELECT TREX1__Product__c 
                            FROM TREX1__Price_Level__c
                           WHERE Key__c IN :setPriceLevelKeys)
              WITH USER_MODE
        ];
    }

    /**
     * Get a map of sessions by record id
     */
    private Map<Id, TREX1__Session__c> getSessionMap() {
        if (sessions == null) {
            Set<Id> setSessionIds = new Set<Id>();
            for (Staged_Program__c sp : stagedPrograms.values()) {
                setSessionIds.add(sp.Session__c);
            }
            sessions = new Map<Id, TREX1__Session__c>([
                SELECT Id,
                       Name,
                       BPC_Free_Membership_Type__c,
                       UES_Free_Membership_Type__c,
                       UES_Admin_GL_Account__c,
                       BPC_Admin_GL_Account__c,
                       UES_Other_Fees_GL_Account__c,
                       BPC_Other_Fees_GL_Account__c,
                       Free_Product__c,
                       TREX1__Start_Date__c,
                       TREX1__End_Date__c,
                       TREX1__Available_Online_From__c,
                       TREX1__Available_Online_To__c,
                       TREX1__Register_From_Date__c,
                       TREX1__Register_To_Date__c,
                       TREX1__Register_From_Time__c,
                       TREX1__Register_To_Time__c,
                       TREX1__Register_Online_From_Date__c,
                       TREX1__Register_Online_To_Date__c,
                       TREX1__Register_Online_From_Time__c,
                       TREX1__Register_Online_To_Time__c
                  FROM TREX1__Session__c
                 WHERE Id IN :setSessionIds
            ]);
        }
        return sessions;
    }

    /**
     * Query for staged program details
     */
    private Map<Id, Staged_Program__c> queryForStagedPrograms(
        Set<Id> stagedProgramIds
    ) {
        return new Map<Id, Staged_Program__c>([
            SELECT Id,
                   Status__c,
                   Error_Message__c,
                   Program__c,
                   Course__c,
                   GL_Account__c,
                   GL_Account__r.Name,
                   Session__c,
                   Primary_Facility__c,
                   Location__c,
                   Location__r.Name,
                   Start_Date__c,
                   End_Date__c,
                   Start_Time__c,
                   End_Time__c,
                   Exception_Dates__c,
                   Days_of_Week__c,
                   Capacity__c,
                   Minimum_Participants__c,
                   Minimum_Age__c,
                   Maximum_Age__c,
                   Public_Price__c,
                   Member_Price__c,
                   Has_Member_Price__c,
                   Price_Level_Key__c,
                   Course_Session_Name__c,
                   Course_Session_Key__c,
                   Course_Option_Name__c,
                   Course_Option_Code__c,
                   Course_Session__c,
                   Course_Option__c
              FROM Staged_Program__c
             WHERE Id IN :stagedProgramIds
               AND Status__c = :STATUS_STAGED
              WITH USER_MODE
             LIMIT 200
        ]);
    }

    /**
     * Caches and returns cached gbg id
     */
    private static Id getGlobalBillingGroupId() {
        if (gbgId == null) {
            List<TREX1__Global_Billing_Group__c> lstGbgs = [
                SELECT Id 
                  FROM TREX1__Global_Billing_Group__c 
                 WHERE Name = :GBG_NAME 
                  WITH USER_MODE 
                 LIMIT 1
            ];
            gbgId = lstGbgs[0].Id;
        }
        return gbgId;
    }

}