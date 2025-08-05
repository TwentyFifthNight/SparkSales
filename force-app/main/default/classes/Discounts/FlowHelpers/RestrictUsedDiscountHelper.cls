public class RestrictUsedDiscountHelper {
    public static List<String> getUpdatedRestrictedFields(SObject oldObject, SObject newObject) {
        String SobjectApiName = 'Discount__c';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField>(schemaMap.get(SobjectApiName).getDescribe().fields.getMap());
        if (fieldMap.containsKey('isactive__c')) {
            fieldMap.keySet().remove('isactive__c');
        }
        List<String> changedFields = getChangedFields(oldObject, newObject, fieldMap);
        return changedFields;
    }

    private static List<String> getChangedFields(SObject oldObject, SObject newObject, Map<String, Schema.SObjectField> fieldMap) {
        List<String> changedFields = new List<String>();

        for (String fieldName : fieldMap.keySet()) {
            Schema.sObjectField field = fieldMap.get(fieldName);
            Object v1 = oldObject.get(field);
            Object v2 = newObject.get(field);
            if (didFieldChange(v1, v2)) {
                changedFields.add(fieldName);
            }
        }
        return changedFields;
    }

    private static Boolean didFieldChange(Object v1, Object v2) {
        if (v1 == null && v2 == null) {
            return false;
        }
        if (v1 != v2) {
            return true;
        }
        return false;
    }
}