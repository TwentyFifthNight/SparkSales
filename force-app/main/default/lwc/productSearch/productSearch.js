import { LightningElement, wire, track, api} from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import getRecordList from '@salesforce/apex/ProductSearchController.getRecordList';
import getRecordCount from '@salesforce/apex/ProductSearchController.getRecordCount';
import getSelectedProducts from '@salesforce/apex/ProductSearchController.getOpportunityProducts';
import generateOrderItemsFromProducts from '@salesforce/apex/ProductSearchController.generateOrderItemsFromProducts';
import createNewOrder from '@salesforce/apex/ProductSearchController.createNewOrder';
import PRODUCT_OBJECT from '@salesforce/schema/Product2';
import FAMILY_FIELD from '@salesforce/schema/Product2.Family';
import { loadStyle } from 'lightning/platformResourceLoader';
import NoHeader from '@salesforce/resourceUrl/noHeader';
import { CloseActionScreenEvent } from 'lightning/actions';
import searchPage from './productSearch.html';
import summaryPage from './productListSummary.html';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";

const Page = {
    ProductSearch: 'productSearch',
    ProductSummary: 'productSummary'
}

export default class ProductSearch extends NavigationMixin(LightningElement) {
    currentLWCPage = Page.ProductSearch;
    columns = [
        { label: 'Name', fieldName: 'Name', type: 'text'},
        { label: 'Product Code', fieldName: 'ProductCode', type: 'text'},
        { label: 'Family', fieldName: 'Family', type: 'text'},
    ];
    orderColumns = [
        { label: 'Product Name', fieldName: 'name', type: 'text'},
        { label: 'Quantity', fieldName: 'quantity', type: 'number', editable: true },
        { label: 'Unit Price', fieldName: 'unitPrice', type: 'currency', editable: true},
    ];
    pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '15', value: '15' },
        { label: '20', value: '20' }
    ];

    @track selectedProductIds  = [];
    selectedProducts = [];
    
    _recordId = undefined;
    @api set recordId(value) {
        if(this._recordId === undefined){
            getSelectedProducts({ opportunityId: value})
                .then(result => {
                    this.selectedProducts = result;
                    this.selectedProductIds = result.map(record => record.Id);
                })
                .catch(error => {
                    this.error = error;
                });
        }
        this._recordId = value;
    }
    get recordId() {
        return this._recordId;
    }

    nameAndCode = '';
    family = '';
    products = undefined;
    familyOptions = [];
    error = undefined;
    isLoading = false;

    recordsPerPage = 10;
    currentPage = 1;
    totalPages = 0;
    allRecordsCount = 0;
    showSelected = false;
    afterFirstSearch = false;
    orderItems = undefined;
    totalPrice = 0;

    render() {
        switch(this.currentLWCPage) {
            case Page.ProductSearch:
                return searchPage;
            case Page.ProductSummary:
                return summaryPage;
        }
    }

    connectedCallback() {
        loadStyle(this, NoHeader)
            .then(result => {});
    }

    @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT })     
    productInfo;

    @wire(getPicklistValues, { recordTypeId: '$productInfo.data.defaultRecordTypeId', fieldApiName: FAMILY_FIELD})
    wiredFamilyValues({ error, data }) {         
        if (data) {             
            this.familyOptions = [
                ...data.values.slice()
            ];
        } else if (error) {             
            this.error = error;  
        }     
    }

    get familyFilterOptions() {
        return [
            {label: 'All', value: ''},
            ...this.familyOptions
        ]
    }

    handleRowSelection(event){
        switch (event.detail.config.action){
            case 'selectAllRows':
                for (let i = 0; i < event.detail.selectedRows.length; i++) {
                    if (!this.selectedProductIds.includes(event.detail.selectedRows[i].Id)){
                        this.selectedProductIds.push(event.detail.selectedRows[i].Id);
                        this.selectedProducts.push(event.detail.selectedRows[i]);
                    }
                }
                break;
            case 'deselectAllRows':
                let currentlyShownProducts = this.showSelected ? this.selectedProducts : this.products;
                let currentlyShownProductIds = currentlyShownProducts.map(product => product.Id);
                
                this.selectedProducts = this.selectedProducts
                    .filter(product => !currentlyShownProductIds.includes(product.Id));
                this.selectedProductIds = this.selectedProducts.map(product => product.Id);
                break;
            case 'rowSelect':
                let selectedId = event.detail.config.value;
                if (!this.selectedProductIds.includes(selectedId)){
                    this.selectedProductIds.push(selectedId);
                    let selectedProduct = this.products.find(product => product.Id === selectedId);
                    this.selectedProducts.push(selectedProduct);
                }
                break;
            case 'rowDeselect':
                const index = this.selectedProductIds.indexOf(event.detail.config.value);
                if (index > -1) {
                    this.selectedProductIds.splice(index, 1);
                    this.selectedProducts.splice(index, 1);
                }
                break;
            default:
                break;
        }
        this.selectedProducts = [...this.selectedProducts];
    }

    handleInputChange(event){
        this[event.target.name] = event.target.value;
    }

    draftValues;
    handleSummaryInputChange(event){
        const changedFields = event.detail.draftValues;
        const itemId = changedFields[0].product2Id;
        const field = Object.keys(changedFields[0])[0];
        const value = changedFields[0][field];
        this.orderItems = this.orderItems.map(item => {
            if (item.product2Id === itemId) {
                return { ...item, [field]: Math.round(parseFloat(value) * 100) / 100 }; // Cut off to 2 decimal places
            }
            return item;
        });
        this.draftValues = []; // Remove highlighted rows from datatable
        this.totalPrice = this.orderItems.reduce((total, item) => total + (item.quantity * item.unitPrice), 0);
    }

    async handleSearchButton(event) {
        this.currentPage = 1;
        await this.getPageCount();
        await this.handleRecordRequest(1);
        this.afterFirstSearch = true;
    }

    async getPageCount(){
        await this.getRecordCount();
        this.totalPages = Math.ceil(this.allRecordsCount/this.recordsPerPage);
    }
    
    async getRecordCount(){
        this.isLoading = true;
        await getRecordCount({ parameters: { nameAndCode: this.nameAndCode, family: this.family, opportunityId: this.recordId }})
            .then(result => {
                this.allRecordsCount = result;
            })
            .catch(error => {
                this.error = error;
            })
        this.isLoading = false;
    }

    async handleRecordRequest(pageNumber) {
        await this.getRecords(pageNumber);
        this.reloadSelectedRecords();
    }

    async getRecords(pageNumber){
        this.isLoading = true;
        let offsetValue = this.recordsPerPage * (pageNumber - 1);
        await getRecordList({ parameters: { nameAndCode: this.nameAndCode, family: this.family, offset: offsetValue, recordsPerPage: this.recordsPerPage, opportunityId: this.recordId} })
            .then(result => {
                this.products = result;
            })
            .catch(error => {
                this.error = error;
                this.products = undefined;
            })
        this.isLoading = false;
    }

    reloadSelectedRecords() {
        this.selectedProductIds = [...this.selectedProductIds];
    }

    handlePageSizeChange(event) {
        this.recordsPerPage = parseInt(event.detail.value);
        this.currentPage = 1;
        this.totalPages = Math.ceil(this.allRecordsCount/this.recordsPerPage);
        this.handleRecordRequest(this.currentPage);
    }

    handleFirstPageClick() {
        if( this.currentPage !== 1) {
            this.currentPage = 1;
            this.handleRecordRequest(1)
        }
    }

    handlePreviousPageClick() {
        if( this.currentPage > 1) {
            this.currentPage--;
            this.handleRecordRequest(this.currentPage)
        }
    }

    handleNextPageClick() {
        if( this.currentPage < this.totalPages) {
            this.currentPage++;
            this.handleRecordRequest(this.currentPage);
        }
    }       

    handleLastPageClick() {
        if( this.currentPage !== this.totalPages) {
            this.currentPage = this.totalPages;
            this.handleRecordRequest(this.totalPages)
        }
    }

    get pageInfo() {
        return `Page ${this.currentPage} of ${this.totalPages}`;
    }

    get disableFirstAndPreviousButton() {
        return this.currentPage === 1;
    }

    get disableNextAndLastButton() {
        return this.currentPage === this.totalPages || this.totalPages === 0;
    }

    get recordsPerPageString() {
        return this.recordsPerPage.toString();
    }

    get noResults() {
        return !this.isLoading && this.products?.length === 0 && !this.error;
    }

    resetFilters() {
        this.nameAndCode = '';
        this.family = '';
        this.products = undefined;
        this.error = undefined;
        this.currentPage = 1;
        this.totalPages = 0;
        this.allRecordsCount = 0;
    }

    handleDismiss(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleNextButton() {
        if(this.selectedProducts.length < 1) {
            const event = new ShowToastEvent({
                title: 'Missing products',
                message: 'Please select at least one product',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }

        await this.getOrderItemList();
        this.currentLWCPage = Page.ProductSummary;
    }

    async handleCreateButton(){
        if(this.validateOrderItems() === false) {
            return;
        }
        this.isLoading = true;

        await createNewOrder({orderItemWrappers: this.orderItems, opportunityId: this.recordId})
            .then(result => {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.error = error;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    validateOrderItems() {
        for (let i = 0; i < this.orderItems.length; i++) {
            if (!(this.orderItems[i].quantity > 0) || !(this.orderItems[i].unitPrice > 0)) {
                const event = new ShowToastEvent({
                    title: 'Invalid data',
                    message: `Quantity and Unit Price must be greater than 0 (${this.orderItems[i].name})`,
                    variant: 'error'
                });
                this.dispatchEvent(event);
                return false;
            }

        }
        return true;
    }

    async getOrderItemList(){
        this.isLoading = true;
        await generateOrderItemsFromProducts({products: this.selectedProducts, opportunityId: this.recordId})
            .then(result => {
                this.orderItems = result;
                this.totalPrice = this.orderItems.reduce((total, item) => total + (item.quantity * item.unitPrice), 0);
            })
            .catch(error => {
                this.error = error;
                this.orderItems = undefined;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get toggleListViewButtonLabel(){
        return this.showSelected ? 'View All' : 'Show Selected';
    }

    toggleListViewType(){
        this.showSelected = !this.showSelected;
    }

    get showAll(){
        return !this.showSelected;
    }

    get showNextButton(){
        return this.selectedProductIds.length > 0 && this.afterFirstSearch;
    }
}