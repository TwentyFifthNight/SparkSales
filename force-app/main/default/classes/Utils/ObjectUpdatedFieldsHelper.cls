public class ObjectUpdatedFieldsHelper {
    public static List<String> getUpdatedFields(SObject oldObject, SObject newObject, String objectName, List<String> fieldsToIgnore) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField>(schemaMap.get(objectName).getDescribe().fields.getMap());
        
        for (String fieldName : fieldsToIgnore) {
            fieldMap.keySet().remove(fieldName);
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