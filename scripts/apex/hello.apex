// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

ProgramGeneratorService pgs = new ProgramGeneratorService(
    new Set<Id>{ 'a6oVB0000000km1YAA' }
);

pgs.run();
System.debug(':::: ran service');