@isTest
private class FlowStringParser_Test {
    
    @isTest
    static void parseString() {
        String input = 'Mets;Marlins;Phillies;Nationals;Braves';
        List<FlowStringParser.Result> lstResult;

        Test.startTest();
        FlowStringParser.Request request;
        request = new FlowStringParser.Request();
        request.input = input;
        lstResult = FlowStringParser.parseText(
            new List<FlowStringParser.Request>{ request }
        );
        Test.stopTest();

        Set<String> setResultStrings = new Set<String>(lstResult.get(0).lstStrings);
        System.assertEquals(5, setResultStrings.size(), 'Did not receive 5 strings in result');
        System.assert(setResultStrings.contains('Mets'), 'Did not find Mets in result');

    }

    @isTest
    static void parseStringWithWhitespace() {
        // Use one-word strings so that all whitespace should be removed
        String input = 'Pirates; Reds; Cardinals; Cubs; Brewers';
        List<FlowStringParser.Result> lstResult;

        Test.startTest();
        FlowStringParser.Request request;
        request = new FlowStringParser.Request();
        request.input = input;
        lstResult = FlowStringParser.parseText(
            new List<FlowStringParser.Request>{ request }
        );
        Test.stopTest();

        Set<String> setResultStrings = new Set<String>(lstResult.get(0).lstStrings);
        System.assertEquals(5, setResultStrings.size(), 'Did not receive 5 strings in result');
        for (String resultString : setResultStrings) {
            System.assert(!resultString.containsWhitespace(), 'Found separator whitespace in string');
        }

    }

    @isTest
    static void parseStringWithOddSpacing() {
        // Use one-word strings so that all whitespace should be removed
        String input = 'Dodgers;  Giants;Rockies;  Diamondbacks   ;  Padres ';
        List<FlowStringParser.Result> lstResult;

        Test.startTest();
        FlowStringParser.Request request;
        request = new FlowStringParser.Request();
        request.input = input;
        lstResult = FlowStringParser.parseText(
            new List<FlowStringParser.Request>{ request }
        );
        Test.stopTest();

        Set<String> setResultStrings = new Set<String>(lstResult.get(0).lstStrings);
        System.assertEquals(5, setResultStrings.size(), 'Did not receive 5 strings in result');
        for (String resultString : setResultStrings) {
            System.assert(!resultString.containsWhitespace(), 'Found separator whitespace in string');
        }

    }

    @isTest
    static void parseSingleString() {
        String input = 'New York Mets';
        List<FlowStringParser.Result> lstResult;

        Test.startTest();
        FlowStringParser.Request request;
        request = new FlowStringParser.Request();
        request.input = input;
        lstResult = FlowStringParser.parseText(
            new List<FlowStringParser.Request>{ request }
        );
        Test.stopTest();

        String[] lstResultStrings = lstResult.get(0).lstStrings;
        System.assertEquals(1, lstResultStrings.size(), 'Did not receive 1 string in result');
        System.assertEquals(input, lstResultStrings[0], 'Single output string is not equal to input');

    }

    @isTest
    static void parseEmptyString() {
        String input = '';
        List<FlowStringParser.Result> lstResult;

        Test.startTest();
        FlowStringParser.Request request;
        request = new FlowStringParser.Request();
        request.input = input;
        lstResult = FlowStringParser.parseText(
            new List<FlowStringParser.Request>{ request }
        );
        Test.stopTest();

        String[] lstResultStrings = lstResult.get(0).lstStrings;
        Assert.isTrue(lstResultStrings.isEmpty(), 'The returned collection of strings should be empty');
    }

    @isTest
    static void testNullInput() {
        List<FlowStringParser.Result> lstResult;

        Test.startTest();
        FlowStringParser.Request request;
        request = new FlowStringParser.Request();
        lstResult = FlowStringParser.parseText(
            new List<FlowStringParser.Request>{ request }
        );
        Test.stopTest();

        String[] lstResultStrings = lstResult.get(0).lstStrings;
        Assert.isTrue(lstResultStrings.isEmpty(), 'The returned collection of strings should be empty');
    }


}