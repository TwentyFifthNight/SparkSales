public virtual class BaseCaseTestDataBuilder extends TestDataBuilder {
    public BaseCaseTestDataBuilder() {
        record = new Case();
    }

    protected virtual override void prepare(){
        Case caseRecord = (Case) record;
        if (String.isBlank(caseRecord.Status)) {
            caseRecord.Status = 'New';
        }
        if (caseRecord.Origin == null) {
            caseRecord.Origin = 'Test';
        }
    }
}