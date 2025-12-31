public inherited sharing class ProgramGeneratorSettings {
    private static ProgramGeneratorSettings instance;

    public Program_Generator_Settings__c settings { get; private set; }

    private ProgramGeneratorSettings() {
        settings = getSettings();
    }

    public static ProgramGeneratorSettings getInstance() {
        if (ProgramGeneratorSettings.instance == null) {
            ProgramGeneratorSettings.instance = new ProgramGeneratorSettings();
        }
        return ProgramGeneratorSettings.instance;
    }

    private Program_Generator_Settings__c getSettings() {
        List<Program_Generator_Settings__c> settings = [
            SELECT Batch_Size__c
              FROM Program_Generator_Settings__c
             LIMIT 1
        ];

        if (settings.isEmpty()) {
            throw new ProgramGeneratorException('Program Generator Settings not found');
        }

        return settings[0];
    }
    
}