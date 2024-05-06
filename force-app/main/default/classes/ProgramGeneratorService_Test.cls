@IsTest
private class ProgramGeneratorService_Test {
    
    @TestSetup
    static void makeData() {
        TREX1__Location__c location = TestDataFactory.createLocations(1).get(0);
        location.Name = 'Upper East Side';
        insert location;

        TREX1__Facility__c facility = TestDataFactory.createFacilities(1).get(0);
        facility.TREX1__Location__c = location.Id;
        insert facility;

        List<TREX1__Program__c> lstPrograms = TestDataFactory.createPrograms(1);
        insert lstPrograms;

        List<TREX1__Course__c> lstCourses = TestDataFactory.createCourses(lstPrograms, 1);
        insert lstCourses;

        List<TREX1__Membership_Category__c> lstMemCats = TestDataFactory.createMembershipCategories(1);
        insert lstMemCats;

        List<TREX1__Membership_Type__c> lstMemTypes = TestDataFactory.createMembershipTypes(lstMemCats, location, 1);
        insert lstMemTypes;

        List<TREX1__GL_Account__c> lstGlAccounts = TestDataFactory.createGlAccounts(4);
        insert lstGlAccounts;

        TREX1__Product__c product = new TREX1__Product__c();
        product.Name = 'Free Product';
        product.TREX1__Billing_Cancellation_Credit_Setting__c = 'Active Days Prorated Credit';
        product.TREX1__Allow_Multiple__c = true;
        product.TREX1__Available_Externally__c = true;
        product.TREX1__Global_Billing_Group__c = TestDataFactory.getGlobalBillingGroupId();
        insert product;

        TREX1__Session__c session = TestDataFactory.createSessions(1).get(0);
        session.UES_Free_Membership_Type__c = lstMemTypes[0].Id;
        session.UES_Admin_GL_Account__c = lstGlAccounts[0].Id;
        session.UES_Other_Fees_GL_Account__c = lstGlAccounts[1].Id;
        session.Free_Product__c = product.Id;
        insert session;

        Staged_Program__c sp = new Staged_Program__c(
            Status__c = 'Staged',
            Program__c = lstPrograms.get(0).Id,
            Course__c = lstCourses.get(0).Id,
            Session__c = session.Id,
            GL_Account__c = lstGlAccounts[3].Id,
            Location__c = location.Id,
            Primary_Facility__c = facility.Id,
            Public_Price__c = 100.00,
            Has_Member_Price__c = true,
            Start_Date__c = session.TREX1__Start_Date__c,
            End_Date__c = session.TREX1__End_Date__c,
            Start_Time__c = '08:00 AM',
            End_Time__c = '09:00 AM',
            Capacity__c = 20,
            Minimum_Participants__c = 1,
            Minimum_Age__c = 7,
            Maximum_Age__c = 10,
            Course_Option_Name__c = 'Test CO',
            Course_Option_Code__c = 'MyTestCoCode',
            Course_Session_Name__c = 'Test CS',
            Days_of_Week__c = 'Monday;Thursday'
        );
        insert sp;
    }

    @IsTest
    static void testCreateNewCourseOptions() {
        Staged_Program__c sp = [SELECT Id FROM Staged_Program__c LIMIT 1];
        ProgramGeneratorService pgs = new ProgramGeneratorService(new Set<Id>{sp.Id});
        Test.startTest();
        pgs.run();
        Test.stopTest();
        Staged_Program__c refreshedSp = [SELECT Id, Status__c, Course_Option_Name__c, Capacity__c, Course_Option__c FROM Staged_Program__c WHERE Id = :sp.Id LIMIT 1];
        TREX1__Course_Option__c co = [SELECT Id, Name, TREX1__Capacity__c FROM TREX1__Course_Option__c WHERE Name = :refreshedSp.Course_Option_Name__c LIMIT 1];
        Assert.areEqual('Processed', refreshedSp.Status__c, 'Final status should be processed');
        Assert.areEqual(refreshedSp.Capacity__c, co.TREX1__Capacity__c, 'Should have received the capacity from the staged program');
        Assert.areEqual(co.Id, refreshedSp.Course_Option__c, 'Should have written the new course option back to the staged program');
    }
    
}