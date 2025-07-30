import { LightningElement, wire } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import searchAccounts from '@salesforce/apex/AccountSearchController.searchAccounts';
import getAccountCount from '@salesforce/apex/AccountSearchController.getAccountCount';
import searchAccountsFromWiktor from '@salesforce/apex/AccountSearchController.searchAccountsFromWiktor';
import getAccountCountFromWiktor from '@salesforce/apex/AccountSearchController.getAccountCountFromWiktor';
import updateAccount from '@salesforce/apex/AccountSearchController.updateAccount';
import ACCOUNT_OBJECT from '@salesforce/schema/Account'; 
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';
import TYPE_FIELD from '@salesforce/schema/Account.Type';
import { loadStyle } from 'lightning/platformResourceLoader';
import NoHeader from '@salesforce/resourceUrl/noHeader';
import LightningToast from "lightning/toast";
import createNewAccount from '@salesforce/apex/AccountSearchController.createNewAccount';
import { refreshApex } from '@salesforce/apex';

const ACTIONS = [
    { label: 'Edit', name: 'edit' },
];

const NEW_ACCOUNT = {
    Name: '',
    Type: '',
    Industry: '',
    Destination: 'Local'
}

export default class AccountSearch extends LightningElement {
    columns = [
        { label: 'Name', fieldName: 'Name', type: 'text'},
        //{ label: 'Name', fieldName: 'URL', type: 'url', typeAttributes: { label: {fieldName: 'Name'}}},
        { label: 'Type', fieldName: 'Type', type: 'text'},
        { label: 'Industry', fieldName: 'Industry', type: 'text'},
        { label: 'Phone', fieldName: 'Phone', type: 'phone'},
        { label: 'Source', fieldName: 'Source', type: 'text'},
        { type: 'action', typeAttributes: { rowActions: ACTIONS } }
    ];
    pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '15', value: '15' },
        { label: '20', value: '20' },
        { label: '30', value: '30' }
    ];

    name = '';
    type = '';
    industry = '';
    accounts = undefined;
    industryOptions = [];
    typeOptions = [];
    destinationOptions = [{label: 'Local', value: 'Local'}, {label: 'External', value: 'External'}];
    error = undefined;
    isLoading = false;
    saveUserBlock = false;

    recordsPerPage = 10;
    currentPage = 1;
    localPages = 0;
    totalPages = 0;
    LocalRecordsCount = 0;
    ExternalRecordsCount = 0;

    editAccount = {};
    isEditModalOpen = false;
    isCreatingNewAccount= false;
  
    connectedCallback() {
        loadStyle(this, NoHeader)
            .then(result => {});
    }

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })     
    accountInfo;

    @wire(getPicklistValues, { recordTypeId: '$accountInfo.data.defaultRecordTypeId', fieldApiName: INDUSTRY_FIELD})
    wiredIndustryValues({ error, data }) {         
        if (data) {             
            this.industryOptions = [
                ...data.values.slice()
            ];
        } else if (error) {             
            this.error = error;  
        }     
    }

    @wire(getPicklistValues, { recordTypeId: '$accountInfo.data.defaultRecordTypeId', fieldApiName: TYPE_FIELD})
    wiredTypeValues({ error, data }) {         
        if (data) {             
            this.typeOptions = [
                ...data.values.slice()
            ];
        } else if (error) {             
            this.error = error;
        }     
    }

    get industryFilterOptions() {
        return [
            {label: 'All', value: ''},
            ...this.industryOptions
        ]
    }

    get typeFilterOptions() {
        return [
            {label: 'All', value: ''},
            ...this.typeOptions
        ]
    }

    handleInputChange(event){
        this[event.target.name] = event.target.value;
    }

    async handleSearchButton(event) {
        this.currentPage = 1;
        this.isLoading = true;
        await this.getAccountPageCount();
        await this.handleRecordRequest(1);
        this.isLoading = false;
    }

    async getAccountPageCount(){
        await this.getLocalAccountCount();
        await this.getExternalAccountCount();
        this.totalPages = Math.ceil((this.LocalRecordsCount + this.ExternalRecordsCount)/this.recordsPerPage);
    }

    async getLocalAccountCount(){
        await getAccountCount({ name: this.name, type: this.type, industry: this.industry })
            .then(result => {
                this.LocalRecordsCount = result;
                this.localPages = Math.ceil(this.LocalRecordsCount/this.recordsPerPage);
            })
            .catch(error => {
                this.error = error;
            })
    }

    async getExternalAccountCount(){
        await getAccountCountFromWiktor({ name: this.name, type: this.type, industry: this.industry })
            .then(result => {
                this.ExternalRecordsCount = result;
            })
            .catch(error => {
                this.error = error;
            })
    }

    async handleRecordRequest(pageNumber) {
        let length = 0;
        this.isLoading = true;
        if(this.localPages >= pageNumber){
            await this.getLocalAccounts(pageNumber);
            length = this.accounts.length;
        }
        if(length < this.recordsPerPage) {
            await this.getExternalAccounts(pageNumber);
        }
        this.isLoading = false;
    }

    async getLocalAccounts(pageNumber){
        await searchAccounts({ name: this.name, type: this.type, industry: this.industry, pageNumber: pageNumber, recordsPerPage: this.recordsPerPage})
            .then(result => {
                result = result.map(item => ({
                    ...item,
                    Source: 'Local',
                    URL: '/' + item.Id
                }));
                this.accounts = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.accounts = undefined;
            })
    }

    async getExternalAccounts(pageNumber){
        let recordsOverLocal = pageNumber * this.recordsPerPage - this.LocalRecordsCount;
        let numberOfRecords = Math.min(recordsOverLocal, this.recordsPerPage);
        let offsetValue = Math.max(recordsOverLocal - this.recordsPerPage, 0)

        await searchAccountsFromWiktor({ name: this.name, type: this.type, industry: this.industry, offset: offsetValue, recordsPerPage: numberOfRecords})
            .then(result => {
                result = result.map(item => ({
                    ...item,
                    Source: 'External',
                    URL: '/'
                }));
                if(numberOfRecords < this.recordsPerPage) {
                    this.accounts = this.accounts.concat(result);
                } else {
                    this.accounts = result;
                }
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.accounts = undefined;
            })
    }

    handlePageSizeChange(event) {
        this.recordsPerPage = parseInt(event.detail.value);
        this.currentPage = 1;
        this.totalPages = Math.ceil((this.LocalRecordsCount + this.ExternalRecordsCount)/this.recordsPerPage);
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
        this.name = '';
        this.type = '';
        this.industry = '';
        this.accounts = undefined;
        this.error = undefined;
        this.currentPage = 1;
        this.totalPages = 0;
        this.LocalRecordsCount = 0;
    }

    get noResults() {
        return !this.isLoading && this.accounts?.length === 0 && !this.error;
    }

    addNewAccountClick() {
        this.editAccount = NEW_ACCOUNT;
        this.isCreatingNewAccount = true;
        this.isEditModalOpen = true;
    }

    async handleSaveAccount() {
        if (this.saveUserBlock)
            return;
        if (!this.validateAccount(this.editAccount)) {
            await LightningToast.show({label: 'Error', message: 'Fill all fields before submiting', variant: 'error'}, this );
            return;
        }

        this.saveUserBlock = true;
        this.isLoading = true;
        try {
            this.error = null;
            await createNewAccount({ name: this.editAccount['Name'], type: this.editAccount['Type'], 
                industry: this.editAccount['Industry'], destination: this.editAccount['Destination']})
                .then(result => {
                    if (result === true){
                        LightningToast.show({label: 'Success',  message: 'Account created successfully!', variant: 'success'}, this);
                        this.closeEditModal();
                        this.reloadCurrentList();
                    }
                    else
                        LightningToast.show({ label: 'Error', message: 'Problem encountered when creating account', variant: 'error'}, this);
                })
                .catch(error => {
                    this.error = error;
                });
        } catch (error) {
            this.error = error;
        }
        finally {
            this.saveUserBlock = false;
            this.isLoading = false;
        }
    }

    validateAccount(account) {
        let valid = true;
        if (!('Name' in account) || account['Name'].length < 5 || account['Name'].length > 255) {
            valid = false;
        }
        if (!('Type' in account) || !(this.typeOptions.some(option => option.value === account['Type']))){
            valid = false;
        } 
        if (!('Industry' in account) || !(this.industryOptions.some(option => option.value === account['Industry']))){
            valid = false;
        }
        return valid;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === 'edit') {
            this.editAccount = { ...row, Destination: row['Source']};
            this.isCreatingNewAccount = false;
            this.isEditModalOpen = true;
        }
    }

    handleEditChange(event) {
        const { name, value } = event.target;
        this.editAccount = { ...this.editAccount, [name]: value };
    }

    closeEditModal() {
        this.isEditModalOpen = false;
        this.editAccount = NEW_ACCOUNT;
    }

    async saveEditedAccount() {
        if(this.isCreatingNewAccount)
            await this.handleSaveAccount();
        else
            await this.handleEditAccount();
    }

    async handleEditAccount() {
        if (this.saveUserBlock)
            return;
        if (!this.validateAccount(this.editAccount)) {
            await LightningToast.show({label: 'Error', message: 'Fill all fields before submiting', variant: 'error'}, this );
            return;
        }
        if(!('Id' in this.editAccount)){
            await LightningToast.show({label: 'Error', message: 'Couldn\'t find account Id', variant: 'error'}, this );
            return;
        }

        this.saveUserBlock = true;
        this.isLoading = true;
        try {
            this.error = null;
            await updateAccount({ accountId: this.editAccount['Id'], name: this.editAccount['Name'], type: this.editAccount['Type'], 
                industry: this.editAccount['Industry'], destination: this.editAccount['Destination']})
                .then(result => {
                    if (result === true){
                        LightningToast.show({label: 'Success',  message: 'Account created successfully!', variant: 'success'}, this);
                        this.closeEditModal();
                        this.reloadCurrentList();
                    }
                    else
                        LightningToast.show({ label: 'Error', message: 'Problem encountered when creating account', variant: 'error'}, this);
                })
                .catch(error => {
                    this.error = error;
                });
        } catch (error) {
            this.error = error;
        }
        finally {
            this.saveUserBlock = false;
            this.isLoading = false;
        }
    }

    async reloadCurrentList(){
        this.isLoading = true;
        await this.getAccountPageCount();
        await this.handleRecordRequest(this.currentPage);
        this.isLoading = false;
    }

    get modalTitle(){
        return this.isCreatingNewAccount ? "New Account" : "Edit Account";
    }
}