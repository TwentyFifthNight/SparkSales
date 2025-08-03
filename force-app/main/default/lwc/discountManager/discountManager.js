import { LightningElement } from 'lwc';
import getRecordList from '@salesforce/apex/DiscountController.getRecordList';
import getRecordCount from '@salesforce/apex/DiscountController.getRecordCount';
import { loadStyle } from 'lightning/platformResourceLoader';
import spinnerHeight from '@salesforce/resourceUrl/spinnerHeight'

export default class DiscountManager extends LightningElement {
    discounts;
    error = undefined;
    isModalOpen = false;
    isLoading = false;
    recordsPerPage = 10;
    currentPage = 1;
    totalPages = 0;
    allRecordsCount = 0;

    columns = [
        {
            label: 'Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        {
            label: 'Product',
            fieldName: 'productLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'productName' }, target: '_blank' }
        },
        {
            label: 'Pricebook',
            fieldName: 'pricebookLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'pricebookName' }, target: '_blank' }
        },
        {
            label: 'Active',
            fieldName: 'active',
            type: 'boolean'
        }
    ];

    pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '15', value: '15' },
        { label: '20', value: '20' }
    ];

    connectedCallback() {
        loadStyle(this, spinnerHeight);
        this.loadData();
    }

    async loadData(){
        await this.getRecordCount();
        this.totalPages = Math.ceil(this.allRecordsCount/this.recordsPerPage);
        await this.getRecords(1);
    }

    async getRecordCount(){
        this.isLoading = true;
        await getRecordCount()
            .then(result => {
                this.allRecordsCount = result;
            })
            .catch(error => {
                this.error = error;
            })
        this.isLoading = false;
    }

    async getRecords(pageNumber){
        this.isLoading = true;
        let offsetValue = this.recordsPerPage * (pageNumber - 1);
        await getRecordList({ recordsPerPage: this.recordsPerPage, offset: offsetValue })
            .then(result => {
                this.discounts = result.map(discount => ({
                    ...discount,
                    recordLink: `/${discount.Id}`,
                    productLink: `/${discount.Product__c}`,
                    pricebookLink: `/${discount.Pricebook__c}`,
                    productName: discount.Product__r.Name,
                    pricebookName: discount.Pricebook__r.Name,
                    active: discount.isActive__c
                }));
                this.error = undefined;
                this.discounts.forEach(discount => {
                    console.log(discount.active);
                });
            })
            .catch(error => {
                this.error = error;
                this.discounts = undefined;
            })
        this.isLoading = false;
    }

    handlePageSizeChange(event) {
        this.recordsPerPage = parseInt(event.detail.value);
        this.currentPage = 1;
        this.totalPages = Math.ceil(this.allRecordsCount/this.recordsPerPage);
        this.getRecords(this.currentPage);
    }

    handleFirstPageClick() {
        if( this.currentPage !== 1) {
            this.currentPage = 1;
            this.getRecords(1)
        }
    }

    handlePreviousPageClick() {
        if( this.currentPage > 1) {
            this.currentPage--;
            this.getRecords(this.currentPage)
        }
    }

    handleNextPageClick() {
        if( this.currentPage < this.totalPages) {
            this.currentPage++;
            this.getRecords(this.currentPage);
        }
    }       

    handleLastPageClick() {
        if( this.currentPage !== this.totalPages) {
            this.currentPage = this.totalPages;
            this.getRecords(this.totalPages)
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
        return !this.isLoading && this.discounts?.length === 0 && !this.error;
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.closeModal();
            this.loadData();
        }
    }
}