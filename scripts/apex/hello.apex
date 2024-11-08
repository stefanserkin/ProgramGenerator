// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

String str = 'SELECT TREX1__Course_Option__r.Available_On_Website__c, TREX1__Course_Session__r.TREX1__Available_Online__c, TREX1__Course_Option__r.Website_Availability_Start__c, TREX1__Course_Option__r.Website_Availability_End__c, TREX1__Course_Option__r.Name, TREX1__Course_Session__r.Website_Description__c, Registration_URL__c, TREX1__Course_Option__r.TREX1__Start_Time__c, TREX1__Course_Option__r.TREX1__End_Time__c, TREX1__Course_Option__r.TREX1__Start_Date__c, TREX1__Course_Option__r.TREX1__End_Date__c, TREX1__Course_Option__r.TREX1__Day_of_Week__c, TREX1__Course_Option__r.Exception_Dates__c, TREX1__Course_Option__r.TREX1__Product__r.TREX1__Price_Description__c, TREX1__Course_Option__r.TREX1__Location__r.Name, TREX1__Course_Session__r.TREX1__Course__r.TREX1__Program__r.Program_Category_Tags__c, TREX1__Course_Option__r.TREX1__Age_Min__c, TREX1__Course_Option__r.TREX1__Age_Max__c'+
 ' FROM TREX1__Course_Session_Option__c' +
 ' WHERE TREX1__Course_Option__r.Available_On_Website__c = true' + 
 ' LIMIT 1';
    

String queryString = str.replace(' ','+');
System.debug(queryString);