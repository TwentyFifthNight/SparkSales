import { createElement } from '@lwc/engine-dom';
import ProductSearch from 'c/productSearch';
import getRecordList from '@salesforce/apex/ProductSearchController.getRecordList';
import getRecordCount from '@salesforce/apex/ProductSearchController.getRecordCount';

jest.mock(
    '@salesforce/apex/ProductSearchController.getRecordList',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/ProductSearchController.getRecordCount',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    'lightning/actions',
    () => {
        return {
            defailt: jest.fn()
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

describe('c-product-search', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('should display error message when getRecordCount throws an error', async () => {
        getRecordCount.mockRejectedValue({
            body: { message: 'An error occurred' },
            statusText: 'Error'
        });
        
        const element = createElement('c-product-search', {
            is: ProductSearch
        });
        
        document.body.appendChild(element);
        const button = element.shadowRoot.querySelector('[data-id="search-button"]');
        button.click();
        
        await flushPromises();
        
        const error = element.shadowRoot.querySelector('[data-id="error-message"]');
        expect(error).not.toBeNull();
        expect(error.textContent).toBe('An error occurred');
    });

    it('should display error message when getRecordList throws an error', async () => {
        getRecordCount.mockResolvedValue(2);
        getRecordList.mockRejectedValue({
            body: { message: 'An error occurred' },
            statusText: 'Error'
        });
        
        const element = createElement('c-product-search', {
            is: ProductSearch
        });
        
        document.body.appendChild(element);
        const button = element.shadowRoot.querySelector('[data-id="search-button"]');
        button.click();
        
        await flushPromises();
        
        const error = element.shadowRoot.querySelector('[data-id="error-message"]');
        expect(error).not.toBeNull();
        expect(error.textContent).toBe('An error occurred');
    });

    it('should display records when data is available and search button is clicked', async () => {
        getRecordCount.mockResolvedValue(2);
        getRecordList.mockResolvedValue([
            {
                Name: 'Test Product',
                ProductCode: 'GWE12',
                Family: 'Networking'
            },
            {
                Name: 'Test Product',
                ProductCode: 'ASD12',
                Family: 'Networking'
            }
        ]);
        
        const element = createElement('c-product-search', {
            is: ProductSearch
        });

        document.body.appendChild(element);
        const button = element.shadowRoot.querySelector('[data-id="search-button"]');
        button.click();

        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data.length).toBe(2);
    });

    it('should display no record message when data list is empty', async () => {
        getRecordCount.mockResolvedValue(0);
        getRecordList.mockResolvedValue([]);
        
        const element = createElement('c-product-search', {
            is: ProductSearch
        });

        
        document.body.appendChild(element);
        const button = element.shadowRoot.querySelector('[data-id="search-button"]');
        button.click();

        await flushPromises();

        
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeNull();

        const noRecords = element.shadowRoot.querySelector('[data-id="no-records"]');
        expect(noRecords).not.toBeNull();
        expect(noRecords.textContent).toBe('No record found');
    });

    it('should not display datatable error or no record message at the start', async () => {    
        
        const element = createElement('c-product-search', {
            is: ProductSearch
        });
        
        
        document.body.appendChild(element);
        
        await flushPromises();
        
        const error = element.shadowRoot.querySelector('[data-id="error-message"]');
        expect(error).toBeNull();
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeNull();
        const noRecords = element.shadowRoot.querySelector('[data-id="no-records"]');
        expect(noRecords).toBeNull();
    });
});