import { LightningElement, wire, track} from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import getRecordList from '@salesforce/apex/ProductSearchController.getRecordList';
import getRecordCount from '@salesforce/apex/ProductSearchController.getRecordCount';
import PRODUCT_OBJECT from '@salesforce/schema/Product2';
import FAMILY_FIELD from '@salesforce/schema/Product2.Family';
import { loadStyle } from 'lightning/platformResourceLoader';
import NoHeader from '@salesforce/resourceUrl/noHeader';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ProductSearch extends LightningElement {
    isSummaryVisible = false;

    columns = [
        { label: 'Name', fieldName: 'Name', type: 'text'},
        //{ label: 'Name', fieldName: 'URL', type: 'url', typeAttributes: { label: {fieldName: 'Name'}}},
        { label: 'Product Code', fieldName: 'ProductCode', type: 'text'},
        { label: 'Family', fieldName: 'Family', type: 'text'},
        //{ type: 'action', typeAttributes: { rowActions: ACTIONS } }
    ];
    pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '15', value: '15' },
        { label: '20', value: '20' }
    ];

    @track selectedProductIds  = [];
    @track selectedProducts = [];

    nameAndCode = '';
    family = '';
    products = undefined;
    familyOptions = [];
    error = undefined;
    isLoading = false;
    nextBlock = false;

    recordsPerPage = 10;
    currentPage = 1;
    localPages = 0;
    totalPages = 0;
    LocalRecordsCount = 0;

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

    handleNextButton() {
        this.isSummaryVisible = true;
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
                let pageProductIds = this.products.map(product => product.Id);
                this.selectedProductIds = this.selectedProductIds
                    .filter(productId => !pageProductIds.includes(productId));
                this.selectedProducts = this.selectedProducts
                    .filter(product => !pageProductIds.includes(product.Id));
                break;
            case 'rowSelect':
                if (!this.selectedProductIds.includes(event.detail.config.value)){
                    this.selectedProductIds.push(event.detail.config.value);
                    let product = this.products.find(product => product.Id === event.detail.config.value);
                    this.selectedProducts.push(product);
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

    async handleSearchButton(event) {
        this.currentPage = 1;
        await this.getAccountPageCount();
        await this.handleRecordRequest(1);
    }

    async getAccountPageCount(){
        await this.getLocalRecordCount();
        this.totalPages = Math.ceil(this.LocalRecordsCount/this.recordsPerPage);
    }
    
    async getLocalRecordCount(){
        this.isLoading = true;
        await getRecordCount({ parameters: { nameAndCode: this.nameAndCode, family: this.family } })
            .then(result => {
                this.LocalRecordsCount = result;
                this.localPages = Math.ceil(this.LocalRecordsCount/this.recordsPerPage);
            })
            .catch(error => {
                this.error = error;
            })
        this.isLoading = false;
    }

    async handleRecordRequest(pageNumber) {
        await this.getLocalRecords(pageNumber);
        this.reloadSelectedRecords();
    }

    async getLocalRecords(pageNumber){
        this.isLoading = true;
        let offsetValue = this.recordsPerPage * (pageNumber - 1);
        await getRecordList({ parameters: { nameAndCode: this.nameAndCode, family: this.family, offset: offsetValue, recordsPerPage: this.recordsPerPage } })
            .then(result => {
                this.products = result;
            })
            .catch(error => {
                this.error = error;
                this.products = undefined;
            })
        this.isLoading = false;
    }

    handlePageSizeChange(event) {
        this.recordsPerPage = parseInt(event.detail.value);
        this.currentPage = 1;
        this.totalPages = Math.ceil(this.LocalRecordsCount/this.recordsPerPage);
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

    resetFilters() {
        this.nameAndCode = '';
        this.family = '';
        this.products = undefined;
        this.error = undefined;
        this.currentPage = 1;
        this.totalPages = 0;
        this.LocalRecordsCount = 0;
    }

    get noResults() {
        return !this.isLoading && this.products?.length === 0 && !this.error;
    }

    reloadSelectedRecords() {
        this.selectedProductIds = [...this.selectedProductIds];
    }

    handleDismiss(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}