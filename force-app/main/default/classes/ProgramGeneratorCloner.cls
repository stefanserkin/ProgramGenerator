/****************************************************
 * @date 2024
 ****************************************************/
public with sharing class ProgramGeneratorCloner {

    private static final String STATUS_DRAFT = 'Draft';
    private static final Integer QUERY_LIMIT = 10000;

    private List<TREX1__Course_Session_Option__c> courseSessionOptions;
    private Map<Id, TREX1__Price_Level__c> productIdToPriceLevelMap;

    public ProgramGeneratorCloner(Set<Id> courseSessionOptionIds) {
        this.courseSessionOptions = queryForCourseSessionOptions(courseSessionOptionIds);
    }

    public List<Staged_Program__c> createStagedPrograms() {
        return insertStagedPrograms( createStagedProgramsFromCSOs() );
    }

    private List<Staged_Program__c> insertStagedPrograms(List<Staged_Program__c> stagedPrograms) {
        Database.insert(stagedPrograms, AccessLevel.USER_MODE);
        return stagedPrograms;
    }

    private List<Staged_Program__c> createStagedProgramsFromCSOs() {
        List<Staged_Program__c> stagedPrograms = new List<Staged_Program__c>();
        for (TREX1__Course_Session_Option__c cso : courseSessionOptions) {
            stagedPrograms.add( createStagedProgramFromCSO(cso) );
        }
        return stagedPrograms;
    }

    private Staged_Program__c createStagedProgramFromCSO(TREX1__Course_Session_Option__c cso) {
        Staged_Program__c stagedProgram = new Staged_Program__c();
        stagedProgram.Status__c = STATUS_DRAFT;
        stagedProgram.Program__c = cso.TREX1__Course_Session__r.TREX1__Course__r.TREX1__Program__c;
        stagedProgram.Program_Name__c = cso.TREX1__Course_Session__r.TREX1__Course__r.TREX1__Program__r.Name;
        stagedProgram.Course_Name__c = cso.TREX1__Course_Session__r.TREX1__Course__r.Name;
        stagedProgram.Course__c = cso.TREX1__Course_Session__r.TREX1__Course__c;
        stagedProgram.Session__c = cso.TREX1__Course_Session__r.TREX1__Session__c;
        stagedProgram.Session_Name__c = cso.TREX1__Course_Session__r.TREX1__Session__r.Name;
        stagedProgram.Course_Session_Name__c = cso.TREX1__Course_Session__r.Name;
        stagedProgram.Course_Option_Name__c = cso.TREX1__Course_Option__r.Name;
        stagedProgram.Days_of_Week__c = cso.TREX1__Course_Option__r.TREX1__Day_of_Week__c;
        stagedProgram.Start_Date__c = cso.TREX1__Course_Option__r.TREX1__Start_Date__c;
        stagedProgram.End_Date__c = cso.TREX1__Course_Option__r.TREX1__End_Date__c;
        stagedProgram.Start_Time__c = cso.TREX1__Course_Option__r.TREX1__Start_Time__c;
        stagedProgram.End_Time__c = cso.TREX1__Course_Option__r.TREX1__End_Time__c;
        stagedProgram.Exception_Dates__c = cso.TREX1__Course_Option__r.Exception_Dates__c;
        stagedProgram.Location__c = cso.TREX1__Course_Option__r.TREX1__Location__c;
        stagedProgram.Location_Name__c = cso.TREX1__Course_Option__r.TREX1__Location__r.Name;
        if (cso.TREX1__Course_Option__r.Primary_Facility__c != null) {
            stagedProgram.Primary_Facility__c = cso.TREX1__Course_Option__r.Primary_Facility__c;
            stagedProgram.Primary_Facility_Name__c = cso.TREX1__Course_Option__r.Primary_Facility__r.Name;
        }
        stagedProgram.Minimum_Age__c = cso.TREX1__Course_Option__r.TREX1__Age_Min__c;
        stagedProgram.Maximum_Age__c = cso.TREX1__Course_Option__r.TREX1__Age_Max__c;
        stagedProgram.Capacity__c = cso.TREX1__Course_Option__r.TREX1__Capacity__c;

        // Pricing
        TREX1__Price_Level__c priceLevel = getPriceLevelMap().get(cso.TREX1__Course_Option__r.TREX1__Product__c);
        stagedProgram.Public_Price__c = priceLevel.TREX1__Total_Billing_Schedule_Amount__c;
        stagedProgram.Has_Member_Price__c = true;
        stagedProgram.GL_Account_Number__c = priceLevel.TREX1__GL_Account_Recurring_Fee_Primary__r.TREX1__GL_Account_Number__c;
        stagedProgram.GL_Account__c = priceLevel.TREX1__GL_Account_Recurring_Fee_Primary__c;

        // stagedProgram.Course_Option_Code__c;
        return stagedProgram;
    }

    private Map<Id, TREX1__Price_Level__c> getPriceLevelMap() {
        if (productIdToPriceLevelMap == null) {
            productIdToPriceLevelMap = new Map<Id, TREX1__Price_Level__c>();
            for (TREX1__Price_Level__c priceLevel : queryForPriceLevels()) {
                productIdToPriceLevelMap.put(priceLevel.TREX1__Product__c, priceLevel);
            }
        }
        return productIdToPriceLevelMap;
    }

    private List<TREX1__Price_Level__c> queryForPriceLevels() {
        return [
            SELECT Id, 
                   TREX1__Product__c, 
                   TREX1__Total_Billing_Schedule_Amount__c, 
                   TREX1__GL_Account_Recurring_Fee_Primary__c, 
                   TREX1__GL_Account_Recurring_Fee_Primary__r.TREX1__GL_Account_Number__c
              FROM TREX1__Price_Level__c
             WHERE TREX1__Product__c IN :getProductIds()
              WITH USER_MODE
             LIMIT :QUERY_LIMIT
        ];
    }

    private Set<Id> getProductIds() {
        Set<Id> productIds = new Set<Id>();
        for (TREX1__Course_Session_Option__c cso : courseSessionOptions) {
            productIds.add(cso.TREX1__Course_Option__r.TREX1__Product__c);
        }
        return productIds;
    }

    private List<TREX1__Course_Session_Option__c> queryForCourseSessionOptions(
        Set<Id> courseSessionOptionIds
    ) {
        return [
            SELECT Id, 
                   TREX1__Course_Option__c, 
                   TREX1__Course_Option__r.Name, 
                   TREX1__Course_Option__r.TREX1__Code__c, 
                   TREX1__Course_Option__r.TREX1__Start_Date__c,
                   TREX1__Course_Option__r.TREX1__End_Date__c,
                   TREX1__Course_Option__r.TREX1__Day_of_Week__c,
                   TREX1__Course_Option__r.TREX1__Start_Time__c,
                   TREX1__Course_Option__r.TREX1__End_Time__c,
                   TREX1__Course_Option__r.TREX1__Location__c,
                   TREX1__Course_Option__r.TREX1__Location__r.Name,
                   TREX1__Course_Option__r.Exception_Dates__c,
                   TREX1__Course_Option__r.TREX1__Age_Min__c,
                   TREX1__Course_Option__r.TREX1__Age_Max__c,
                   TREX1__Course_Option__r.TREX1__Capacity__c,
                   TREX1__Course_Option__r.Primary_Facility__c,
                   TREX1__Course_Option__r.Primary_Facility__r.Name,
                   TREX1__Course_Option__r.TREX1__Product__c,
                   TREX1__Course_Session__c, 
                   TREX1__Course_Session__r.Name, 
                   TREX1__Course_Session__r.TREX1__Session__c, 
                   TREX1__Course_Session__r.TREX1__Session__r.Name,
                   TREX1__Course_Session__r.TREX1__Course__c,
                   TREX1__Course_Session__r.TREX1__Course__r.Name,
                   TREX1__Course_Session__r.TREX1__Course__r.TREX1__Program__r.Name
              FROM TREX1__Course_Session_Option__c
             WHERE Id IN :courseSessionOptionIds
              WITH USER_MODE
             LIMIT :QUERY_LIMIT
        ];
    }

}