public virtual class TestDataFactory {
    public virtual List<sObject> buildData(Integer count, TestDataBuilder builder){
        List<sObject> records = new List<sObject>();
        SObject record = builder.create();
        for(Integer i = 0; i < count; i++){
            records.add(record.clone(false, false, false, false));
        }
        insert records;
        return records;
    }
}