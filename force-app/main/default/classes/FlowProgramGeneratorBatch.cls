public with sharing class FlowProgramGeneratorBatch {

    @InvocableMethod(label='Run Program Generator Batch' category='Traction Rec' iconName='resource:agGlyph:Layer_1')
    public static List<Result> runProgramGeneratorBatch(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request request : requests) {
            Integer batchSize = request.batchSize != null 
                ? request.batchSize 
                : (Integer) Program_Generator_Settings__c.getOrgDefaults().Batch_Size__c;

            ProgramGeneratorBatch pgb = new ProgramGeneratorBatch(request.batchId);
            Id jobId = Database.executeBatch(pgb, batchSize);

            Result result = new Result();
            result.jobId = jobId;
            results.add(result);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(label='Staged Program Batch ID' required=true)
        public String batchId;

        @InvocableVariable(label='Batch Size')
        public Integer batchSize;
    }

    public class Result {
        @InvocableVariable(label='Job ID' required=true)
        public String jobId;
    }
    
}