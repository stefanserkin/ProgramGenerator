/****************************************************
 * @date 2024
 ****************************************************/
public with sharing class FlowProgramGeneratorCloner {

    @InvocableMethod()
    public static List<Result> createStagedPrograms(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request request : requests) {
            Set<Id> csoIds = new Set<Id>(request.courseSessionOptionIds);
            ProgramGeneratorCloner cloner = new ProgramGeneratorCloner(csoIds);

            Result result = new Result();
            result.stagedPrograms = cloner.createStagedPrograms();
            results.add(result);
        }
        return results;
    }
    
    public class Request {
        @InvocableVariable(label='Course Session Option IDs' required=true)
        public List<Id> courseSessionOptionIds;
    }

    public class Result {
        @InvocableVariable(label='Staged Programs')
        public List<Staged_Program__c> stagedPrograms;
    }

}