@isTest
private class ProductSearchControllerTest {

    @TestSetup
    static void setup(){
        List<String> familyNames = new List<String>{
            'Adapters',
            'Networking',
            'Cables'
        };

        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 30; i++){
            products.add(new Product2(Name = 'Product ' + i, ProductCode = 'Test ' + i, Family = familyNames[Math.mod(i, familyNames.size())], IsActive = true));
        }
        insert products;
    }

    @isTest
    static void testProductCountWithoutParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        Test.startTest();
        Integer count = ProductSearchController.getRecordCount(wrapper);
        Test.stopTest();
        System.assertEquals(30, count);
    }

    @isTest
    static void testProductCountWithoutFamily() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'Product 1';
        Test.startTest();
        Integer count = ProductSearchController.getRecordCount(wrapper);
        Test.stopTest();
        System.assertEquals(11, count);
    }

    @isTest
    static void testProductCountWithAllParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'est';
        wrapper.family = 'Adapters';
        Test.startTest();
        Integer count = ProductSearchController.getRecordCount(wrapper);
        Test.stopTest();
        System.assertEquals(10, count);
    }

    @isTest
    static void testProductListWithoutParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(10, products.size());
    }

    @isTest
    static void testProductListWithRecordLimit() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        wrapper.recordsPerPage = 35;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(30, products.size());
    }

    @isTest
    static void testProductListWithOffset() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        wrapper.offset = 5;
        wrapper.recordsPerPage = 30;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(25, products.size());
    }

    @isTest
    static void testProductListWithoutFamily() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'Test 1';
        wrapper.recordsPerPage = 30;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(11, products.size());
    }

    @isTest
    static void testProductListWithAllParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = 'est';
        wrapper.family = 'Adapters';
        wrapper.recordsPerPage = 30;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(10, products.size());
    }

    @isTest
    static void testProductListWithInvalidPaginationParameters() {
        ProductSearchController.ParameterWrapper wrapper = new ProductSearchController.ParameterWrapper();
        wrapper.nameAndCode = '';
        wrapper.offset = -1;
        wrapper.recordsPerPage = null;
        Test.startTest();
        List<Product2> products = ProductSearchController.getRecordList(wrapper);
        Test.stopTest();
        System.assertEquals(10, products.size());
    }
}