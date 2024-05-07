// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

Set<Id> setIds = new Set<Id>();
for (Staged_Program__c sp : [SELECT Id FROM Staged_Program__c WHERE Status__c = 'Staged']) {
    setIds.add(sp.Id);
}
ProgramGeneratorService pgs = new ProgramGeneratorService(setIds);

pgs.run();