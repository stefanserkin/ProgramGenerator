public with sharing class FlowStringParser {

    @InvocableMethod(
        label='Parse Text' 
        description='Provide a semi-colon separated string (such as input from a MSP) and receive a collection of strings' 
        category='Utilities'
        iconName='resource:agGlyph:Layer_1'
    )
    public static List<Result> parseText(List<Request> lstRequests) {
        List<Result> lstResults = new List<Result>();
        for (Request req : lstRequests) {
            Result result = new Result();
            List<String> lstStrings = new List<String>();
            if (req.input != null && !String.isBlank(req.input)) {
                lstStrings = req.input.normalizeSpace().replace('; ',';').replace(' ;',';').split(';');
            }
            result.lstStrings = lstStrings;
            lstResults.add(result);
        }
        return lstResults;
    }

    public class Request {
        @InvocableVariable(label='Semi-colon Separated String')
        public String input;
    }

    public class Result {
        @InvocableVariable(label='Collection of Strings')
        public List<String> lstStrings;
    }

}