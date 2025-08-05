public with sharing class FlowUtils {
    public static List<String> parseCheckboxGroupString(String checkboxGroupValue) {
        List<String> selectedValues = new List<String>();
        if (String.isBlank(checkboxGroupValue)) {
            return selectedValues;
        }
        List<String> rawValues = checkboxGroupValue.split(';');
        for (String val : rawValues) {
            String trimmedVal = val.trim();
            if (String.isNotBlank(trimmedVal)) {
                selectedValues.add(trimmedVal);
            }
        }
        return selectedValues;
    }

    @InvocableMethod(
        label='Parse Checkbox Group String'
        description='Parses a semicolon-separated string from a Flow Checkbox Group into a collection of strings.'
        category='Flow Utils'
    )
    public static List<List<String>> parseCheckboxGroupForFlow(List<String> checkboxGroupStrings) {
        List<List<String>> results = new List<List<String>>();
        for (String singleCheckboxString : checkboxGroupStrings) {
            List<String> parsedValues = parseCheckboxGroupString(singleCheckboxString);
            results.add(parsedValues);
        }
        return results;
    }
}