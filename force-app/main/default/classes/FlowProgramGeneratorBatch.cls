public with sharing class FlowProgramGeneratorBatch {

    @InvocableMethod(label='Run Program Generator Batch' category='Traction Rec')
    public static List<Result> runProgramGeneratorBatch(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request request : requests) {
            ProgramGeneratorBatch pgb = new ProgramGeneratorBatch(request.batchId);
            Id jobId = Database.executeBatch(pgb, 50);

            Result result = new Result();
            result.jobId = jobId;
            results.add(result);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(label='Staged Program Batch ID' required=true)
        public String batchId;
    }

    public class Result {
        @InvocableVariable(label='Job ID' required=true)
        public String jobId;
    }
}