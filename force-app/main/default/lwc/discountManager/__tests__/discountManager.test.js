import { createElement } from '@lwc/engine-dom';
import DiscountManager from 'c/discountManager';
import getRecordList from '@salesforce/apex/DiscountController.getRecordList';
import getRecordCount from '@salesforce/apex/DiscountController.getRecordCount';

jest.mock(
    '@salesforce/apex/DiscountController.getRecordList',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/DiscountController.getRecordCount',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/label/c.noRecordsFound',
    () => {
        return { default: "No record found" };
    },
    { virtual: true }
);

function flushPromises() {
    return new Promise(resolve => setTimeout(resolve));
}

describe('c-discount-manager', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('should display discount records when data is available', async () => {
        getRecordCount.mockResolvedValue(2);
        getRecordList.mockResolvedValue([
            {
                Id: '001',
                Name: 'Test Discount',
                Product__c: '002',
                Pricebook__c: '003',
                Product__r: { Name: 'Test Product' },
                Pricebook__r: { Name: 'Test Pricebook' },
                isActive__c: true
            },
            {
                Id: '002',
                Name: 'Test Discount',
                Product__c: '004',
                Pricebook__c: '006',
                Product__r: { Name: 'Test Product' },
                Pricebook__r: { Name: 'Test Pricebook' },
                isActive__c: true
            }
        ]);

        const element = createElement('c-discount-manager', {
            is: DiscountManager
        });

        document.body.appendChild(element);

        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data.length).toBe(2);
    });

    it('handles error from Apex in connectedCallback', async () => {
        getRecordList.mockRejectedValue({ 
            body: { message: 'An error occurred' },
            statusText: 'Error'
        });

        const element = createElement('c-discount-manager', {
            is: DiscountManager
        });
        document.body.appendChild(element);

        await flushPromises();

        const error = element.shadowRoot.querySelector('[data-id="error-message"]');
        expect(error).not.toBeNull();
        expect(error.textContent).toBe('An error occurred');
    });

    it('should show no records message for empty list', async () => {
        getRecordCount.mockResolvedValue(0);
        getRecordList.mockResolvedValue([]);

        const element = createElement('c-discount-manager', {
            is: DiscountManager
        });
        document.body.appendChild(element);

        await flushPromises();

        const noRecords = element.shadowRoot.querySelector('[data-id="no-records"]');
        expect(noRecords).not.toBeNull();
        expect(noRecords.textContent).toBe('No record found');
    });
});