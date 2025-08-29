@isTest
private class ParseCheckboxGroupStringTest {

    @isTest
    static void testParseCheckboxGroupOutputToList() {
        List<String> input = new List<String>{'Option1;Option2;Option3', 'OptionA;OptionB'};
        List<List<String>> expected = new List<List<String>>{
            new List<String>{'Option1', 'Option2', 'Option3'},
            new List<String>{'OptionA', 'OptionB'}
        };
        List<List<String>> actual = FlowUtils.parseCheckboxGroupOutput(input);
        Assert.areEqual(expected, actual, 'The parsed checkbox group output does not match the expected result.');
    }

    @isTest
    static void testParseCheckboxGroupOutputToList_NullListElement() {
        List<String> input = new List<String>{'Option1;Option2;Option3', null};
        List<List<String>> expected = new List<List<String>>{
            new List<String>{'Option1', 'Option2', 'Option3'},
            new List<String>{}
        };
        List<List<String>> actual = FlowUtils.parseCheckboxGroupOutput(input);
        Assert.areEqual(expected, actual, 'The parsed checkbox group output does not match the expected result.');
    }

    @isTest
    static void testParseCheckboxGroupOutputToList_EmptyString() {
        List<String> input = new List<String>{''};
        List<List<String>> expected = new List<List<String>>{
            new List<String>{}
        };
        List<List<String>> actual = FlowUtils.parseCheckboxGroupOutput(input);
        Assert.areEqual(expected, actual, 'The parsed checkbox group output does not match the expected result.');
    }
}