@isTest
private class ComplaintItemsCompletedTriggerTest {
    private static final String externalId = 'TestExternalId';
    private static final Decimal refundAmount = 100;
    
    @testSetup
    static void setup() {
        List<Product2> products = (List<Product2>)new ProductTestDataFactory().buildData(1, new ExternalProductTetsDataBuilder().withExternalId(externalId));

        Case testCase = (Case)new BaseCaseTestDataBuilder().create();
        insert testCase;
    }

    @isTest
    static void testComplaintItemUpdate_Success() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE ExternalId__c = :externalId LIMIT 1];

        ComplaintItem__c complaintItem = (ComplaintItem__c)new BaseComplaintItemTestDataBuilder().withCase(testCase).withProduct(product).create();
        insert complaintItem;

        List<Object> complaints = new List<Object>{
            new Map<String, Object>{
                'CaseId' => testCase.Id,
                'ProductId' => externalId,
                'Status' => Constants.ComplaintItem.Status.APPROVED,
                'RefundType' => Constants.ComplaintItem.RefundType.FULL,
                'RefundAmount' => refundAmount
            }
        };
        String jsonBody = JSON.serialize(complaints);
        ComplaintItemCompleted__e event = (ComplaintItemCompleted__e)new BaseComplaintItemCompletedTestBuilder().withComplaintItems(jsonBody).create();

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(event);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), 'Event should be published successfully');
        ComplaintItem__c updatedItem = [
            SELECT Status__c, RefundType__c, RefundAmount__c
            FROM ComplaintItem__c
            WHERE Id = :complaintItem.Id
        ];
        Assert.areEqual(Constants.ComplaintItem.Status.APPROVED, updatedItem.Status__c, 'Complaint item status should be updated');
        Assert.areEqual(Constants.ComplaintItem.RefundType.FULL, updatedItem.RefundType__c, 'Complaint item refund type should be updated');
        Assert.areEqual(refundAmount, updatedItem.RefundAmount__c, 'Complaint item refund amount should be updated');
    }

    @isTest
    static void testComplaintItemUpdate_NoMatch() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE ExternalId__c = :externalId LIMIT 1];

        List<Object> complaints = new List<Object>{
            new Map<String, Object>{
                'CaseId' => testCase.Id,
                'ProductId' => externalId,
                'Status' => Constants.ComplaintItem.Status.APPROVED,
                'RefundType' => Constants.ComplaintItem.RefundType.PARTIAL,
                'RefundAmount' => 50
            }
        };
        String jsonBody = JSON.serialize(complaints);
        ComplaintItemCompleted__e event = (ComplaintItemCompleted__e)new BaseComplaintItemCompletedTestBuilder().withComplaintItems(jsonBody).create();

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(event);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), 'Event should be published successfully');
        Integer countComplaintItems = [SELECT COUNT() FROM ComplaintItem__c WHERE Product__c = :product.Id AND Case__c = :testCase.Id];
        Assert.areEqual(0, countComplaintItems, 'No complaint item should be updated or created');
    }

    @isTest
    static void testComplaintItemUpdate_InvalidJson() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE ExternalId__c = :externalId LIMIT 1];

        ComplaintItem__c complaintItem = (ComplaintItem__c)new BaseComplaintItemTestDataBuilder().withCase(testCase).withProduct(product).create();
        insert complaintItem;

        List<Object> complaints = new List<Object>{
            new Map<String, Object>{
                'CaseId' => testCase.Id,
                'ProductId' => externalId,
                'Status' => Constants.ComplaintItem.Status.APPROVED,
                'RefundType' => Constants.ComplaintItem.RefundType.PARTIAL,
                'RefundAmount' => 'Not a number'
            }
        };
        String jsonBody = JSON.serialize(complaints);
        ComplaintItemCompleted__e event = (ComplaintItemCompleted__e)new BaseComplaintItemCompletedTestBuilder().withComplaintItems(jsonBody).create();
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(event);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), 'Event should be published successfully');
        ComplaintItem__c updatedItem = [
            SELECT Status__c, RefundType__c
            FROM ComplaintItem__c
            WHERE Id = :complaintItem.Id
        ];
        Assert.areNotEqual(Constants.ComplaintItem.Status.APPROVED, updatedItem.Status__c, 'Complaint item status shouldn\'t be updated');
        Assert.areNotEqual(Constants.ComplaintItem.RefundType.PARTIAL, updatedItem.RefundType__c, 'Complaint item refund type shouldn\'t be updated');
    }

    @isTest
    static void testComplaintItemUpdate_PartialValid() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE ExternalId__c = :externalId LIMIT 1];

        String secondExternalId = 'secondExternalId';
        List<Product2> products = new ProductTestDataFactory().buildData(1, new ExternalProductTetsDataBuilder().withExternalId(secondExternalId));

        List<ComplaintItem__c> complaintItems = new List<ComplaintItem__c>{
            (ComplaintItem__c)new BaseComplaintItemTestDataBuilder().withCase(testCase).withProduct(product).create(),
            (ComplaintItem__c)new BaseComplaintItemTestDataBuilder().withCase(testCase).withProduct(products[0]).create()
        };
        insert complaintItems;

        List<Object> complaints = new List<Object>{
            new Map<String, Object>{
                'CaseId' => testCase.Id,
                'ProductId' => externalId,
                'Status' => Constants.ComplaintItem.Status.APPROVED,
                'RefundType' => Constants.ComplaintItem.RefundType.PARTIAL,
                'RefundAmount' => 50
            },
            new Map<String, Object>{
                'CaseId' => testCase.Id,
                'ProductId' => secondExternalId,
                'Status' => Constants.ComplaintItem.Status.APPROVED,
                'RefundType' => 'Invalid refund type',
                'RefundAmount' => 100
            }
        };
        String jsonBody = JSON.serialize(complaints);
        ComplaintItemCompleted__e event = (ComplaintItemCompleted__e)new BaseComplaintItemCompletedTestBuilder().withComplaintItems(jsonBody).create();
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(event);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), 'Event should be published successfully');
        List<ComplaintItem__c> updatedItems = [
            SELECT Status__c, RefundType__c, RefundAmount__c
            FROM ComplaintItem__c
            WHERE Id IN :complaintItems AND RefundAmount__c != null
        ];
        Assert.areEqual(1, updatedItems.size(), 'Only one complaint item should be updated');
        Assert.areEqual(Constants.ComplaintItem.Status.APPROVED, updatedItems[0].Status__c, 'Complaint item status should be updated');
        Assert.areEqual(Constants.ComplaintItem.RefundType.PARTIAL, updatedItems[0].RefundType__c, 'Complaint item refund type should be updated');
        Assert.areEqual(50, updatedItems[0].RefundAmount__c, 'Complaint item refund amount should be updated');
        
        List<ComplaintItem__c> InvalidItems = [
            SELECT Status__c, RefundType__c, RefundAmount__c
            FROM ComplaintItem__c
            WHERE Id IN :complaintItems AND RefundAmount__c = null
        ];
        Assert.areEqual(1, InvalidItems.size(), 'One complaint item should be invalid');
    }

    private class ExternalProductTetsDataBuilder extends BaseProductTestDataBuilder {
        public ExternalProductTetsDataBuilder withExternalId(String externalId) {
            Product2 product = (Product2) record;
            product.ExternalId__c = externalId;
            return this;
        }
    }
}