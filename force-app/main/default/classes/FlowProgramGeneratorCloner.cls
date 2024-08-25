/****************************************************
 * @date 2024
 ****************************************************/
public with sharing class FlowProgramGeneratorCloner {

    @InvocableMethod(label='Generate Staged Programs' category='Traction Rec')
    public static List<Result> createStagedPrograms(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request request : requests) {
            System.debug(':::: request --> ' + request);
            // Set<Id> csoIds = new Set<Id>(request.courseSessionOptionIds);
            ProgramGeneratorCloner cloner = new ProgramGeneratorCloner(request);

            Result result = new Result();
            result.stagedPrograms = cloner.createStagedPrograms();
            results.add(result);
        }
        return results;
    }
    
    public class Request {
        @InvocableVariable(label='Course Session Option IDs' required=true)
        public List<Id> courseSessionOptionIds;
        @InvocableVariable(description='Original Session' required=true)
        public Id originalSessionId;
        @InvocableVariable(description='Target Session' required=true)
        public Id targetSessionId;
        @InvocableVariable(description='Days to Add' required=true)
        public Integer daysToAdd;
    }

    public class Result {
        @InvocableVariable(label='Staged Programs')
        public List<Staged_Program__c> stagedPrograms;
    }

}