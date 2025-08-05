public abstract class TestDataBuilder {
    protected SObject record;

    protected virtual void prepare() {}

    public SObject create(){
        prepare();
        return record;
    }
}