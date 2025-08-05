public class RestrictUsedDiscountHelper {
    public static List<String> getUpdatedRestrictedFields(SObject oldObject, SObject newObject) {
        String sobjectApiName = Constants.Discount.OBJECT_NAME;
        String activeFieldName = Constants.Discount.IS_ACTIVE_FIELD.toLowerCase();

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField>(schemaMap.get(sobjectApiName).getDescribe().fields.getMap());
        // When the discount is used, we do not allow changes to any other fields than isActive__c
        if (fieldMap.containsKey(activeFieldName)) {
            fieldMap.keySet().remove(activeFieldName);
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