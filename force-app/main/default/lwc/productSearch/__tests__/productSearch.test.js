import { createElement } from '@lwc/engine-dom';
import ProductSearch from 'c/productSearch';
import getRecordList from '@salesforce/apex/ProductSearchController.getRecordList';
import getRecordCount from '@salesforce/apex/ProductSearchController.getRecordCount';

const mockData = [
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
]

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
        getRecordList.mockResolvedValue(mockData);
        
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
        getRecordList.mockResolvedValue(mockData);
        
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

    it('should not display datatable, error or no record message after loading page', async () => {    
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

    it('should not display datatable and clear inputs when reset filters button is pres', async () => {    
        getRecordCount.mockResolvedValue(2);
        getRecordList.mockResolvedValue(mockData);

        const element = createElement('c-product-search', {
            is: ProductSearch
        });
        
        document.body.appendChild(element);

        let nameCodeInput = element.shadowRoot.querySelector('[data-id="name-code-input"]');
        nameCodeInput.value = 'Test Product';
        nameCodeInput.dispatchEvent(new CustomEvent('change'));
        
        let categoryCombobox = element.shadowRoot.querySelector('[data-id="category-combobox"]');
        categoryCombobox.value = 'Networking';
        categoryCombobox.dispatchEvent(new CustomEvent('change'));

        const button = element.shadowRoot.querySelector('[data-id="search-button"]');
        button.click();
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        nameCodeInput = element.shadowRoot.querySelector('[data-id="name-code-input"]');
        expect(nameCodeInput.value).toBe('Test Product');
        categoryCombobox = element.shadowRoot.querySelector('[data-id="category-combobox"]');
        expect(categoryCombobox.value).toBe('Networking');

        const resetButton = element.shadowRoot.querySelector('[data-id="reset-button"]');
        resetButton.click();
        await flushPromises();

        const datatableAfter = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatableAfter).toBeNull();
        const nameCodeInputAfter = element.shadowRoot.querySelector('[data-id="name-code-input"]');
        expect(nameCodeInputAfter.value).toBe('');
        const categoryComboboxAfter = element.shadowRoot.querySelector('[data-id="category-combobox"]');
        expect(categoryComboboxAfter.value).toBe('');
    });
});