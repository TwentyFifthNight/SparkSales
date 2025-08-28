public with sharing class ParseObjectListToIds {
    @InvocableMethod(
        label='Parse Object List To Ids'
        description='Parses a list of SObjects from Flow and returns a list of their Ids.'
        category='Flow Utils'
    )
    public static List<List<String>> parseObjectListToIds(List<List<SObject>> records) {
        List<List<String>> results = new List<List<String>>();
        if (records == null) {
            return results;
        }
        for (List<SObject> recordList : records) {
            List<String> ids = new List<String>();
            if (recordList == null) {
                results.add(ids);
                continue;
            }
            for (SObject record : recordList) {
                if (record != null && record.Id != null) {
                    ids.add(record.Id);
                }
            }
            results.add(ids);
        }
        return results;
    }
}