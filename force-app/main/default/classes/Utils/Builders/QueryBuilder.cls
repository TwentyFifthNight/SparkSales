public with sharing class QueryBuilder {
    private String objectName;
    private Set<String> fieldsNameSet;
    private String limitValue;
    private String offsetVale;
    private Set<String> orderBySet;
    private ConditionsManager conditionsManager;

    public QueryBuilder(String objectName) {
        this.objectName = objectName;
        this.fieldsNameSet = new Set<String>();
        this.orderBySet = new Set<String>();
        this.limitValue = '';
        this.offsetVale = '';
        this.conditionsManager = new ConditionsManager(this);
    }

    public QueryBuilder addField(String fieldName){
        this.fieldsNameSet.add(fieldName);
        return this;
    }

    public QueryBuilder addFields(List<String> fieldsNameList){
        this.fieldsNameSet.addAll(fieldsNameList);
        return this;
    }

    public QueryBuilder setLimit(Integer limitValue){
        this.limitValue = String.valueOf(limitValue);
        return this;
    }

    public QueryBuilder setOffset(Integer offsetValue){
        this.offsetVale = String.valueOf(offsetValue);
        return this;
    }

    public QueryBuilder addOrderBy(String fieldName){
        this.orderBySet.add(fieldName);
        return this;
    }

    public ConditionsManager addConditions() {
        return this.conditionsManager;
    }

    public ConditionsManager addConditionsWithOrder(String conditionOrder) {
        return this.conditionsManager.setConditionOrder(conditionOrder);
    }

    public override String toString(){
        String result = 'SELECT ';
        if(this.fieldsNameSet.isEmpty()){
            result += 'Id';
        }
        else {
            result += String.join(new List<String>(this.fieldsNameSet), ', ');
        }

        result += ' FROM ' + this.objectName;

        if (this.conditionsManager.hasConditions()) {
            result += ' WHERE ' + this.conditionsManager.builtCondition;
        }

        if(!this.orderBySet.isEmpty()){
            result += ' ORDER BY ';
            result += String.join(new List<String>(this.orderBySet), ', ');
        }

        if(!String.isBlank(this.limitValue)){
            result += ' LIMIT ' + this.limitValue;
        }

        if(!String.isBlank(this.offsetVale)){
            result += ' OFFSET ' + this.offsetVale;
        }

        return result.trim();
    }

    public String toStringCount() {
        String result = 'SELECT ';
        String countString = 'count() ';
        result += countString;
        result += 'FROM ' + this.objectName + ' ';
        if (this.conditionsManager.hasConditions()) {
            result += 'WHERE ' + this.conditionsManager.builtCondition;
        }
        if(!String.isBlank(this.limitValue)){
            result += ' LIMIT ' + this.limitValue;
        }

        if(!String.isBlank(this.offsetVale)){
            result += ' OFFSET ' + this.offsetVale;
        }
        return result.trim();
    }

    public class ConditionsManager {

        private final String BRACKET_L = '{';
        private final String BRACKET_R = '}';

        public List<Condition> conditions;
        private String conditionOrder;
        private final QueryBuilder queryBuilder;

        private String builtCondition;

        public ConditionsManager(QueryBuilder queryBuilder) {
            this.queryBuilder = queryBuilder;
            this.conditions = new List<Condition>();
        }

        public ConditionsManager add(Condition condition) {
            if (condition.isEmpty()) {
                return this;
            }
            this.conditions.add(condition);
            return this;
        }

        public ConditionsManager setConditionOrder(String conditionOrder) {
            this.conditionOrder = conditionOrder;
            return this;
        }

        public QueryBuilder endConditions() {
            this.builtCondition = this.toString();
            return this.queryBuilder;
        }

        public override String toString() {
            String result = this.conditionOrder;
            if (String.isEmpty(result)) {
                result = '1';
            }
            result = this.bracketConditions(result);
            for (Integer i = 0; i < this.conditions.size(); i++) {
                Condition condition = this.conditions[i];
                String conditionNumber = this.bracket('' + (i + 1));
                if (result.contains(conditionNumber)) {
                    result = result.replace(conditionNumber, condition.toString());
                }
            }
            return result;
        }

        private Boolean hasConditions() {
            return !this.conditions.isEmpty();
        }

        private String bracketConditions(String conditions) {
            this.conditions.size();
            for (Integer i = 1; i <= this.conditions.size(); i++) {
                String conditionNumber = '' + i;
                conditions = conditions.replaceFirst(conditionNumber, this.bracket(conditionNumber));
            }
            return conditions;
        }

        private String bracket(String condition) {
            return this.BRACKET_L + condition.trim() + this.BRACKET_R;
        }
    }

    public abstract class Condition {

        public final String QUOTE = '\'';
        public final String BRACKET_L = '(';
        public final String BRACKET_R = ')';
        protected String formedCondition;

        public Condition() {
            this.formedCondition = '';
        }

        protected String quote(String field) {
            return this.QUOTE + String.escapeSingleQuotes(field.trim()) + this.QUOTE;
        }

        public virtual override String toString() {
            return this.formedCondition;
        }

        public virtual Boolean isEmpty() {
            return String.isEmpty(this.toString());
        }
    }

    public class SimpleCondition extends Condition {

        public SimpleCondition() {
            super();
        }

        public SimpleCondition(String condition) {
            super();
            this.formedCondition = condition;
        }
    }

    public abstract class FieldCondition extends Condition {

        protected String fieldName;

        public FieldCondition(String fieldName) {
            super();
            this.fieldName = fieldName;
        }

        public override Boolean isEmpty() {
            return String.isEmpty(this.fieldName);
        }
    }

    public class LikeCondition extends FieldCondition {

        public LikeCondition(String fieldName) {
            super(fieldName);
        }

        public Condition likeAnyBoth(String fieldValue) {
            this.formedCondition = this.fieldName + ' LIKE ' + this.quote('%' + fieldValue + '%');
            return this;
        }

        public Condition likeAnyLeft(String fieldValue) {
            this.formedCondition = this.fieldName + ' LIKE ' + this.quote('%' + fieldValue);
            return this;
        }

        public Condition likeAnyRight(String fieldValue) {
            this.formedCondition = this.fieldName + ' LIKE ' + this.quote(fieldValue + '%');
            return this;
        }

        public Condition notLikeAnyBoth(String fieldValue){
            this.formedCondition = ' (NOT ' + this.fieldName + ' LIKE ' + this.quote('%' + fieldValue + '%') + ')';
            return this;
        }
    }
}