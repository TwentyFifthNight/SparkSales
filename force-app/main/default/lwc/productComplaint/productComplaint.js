import { LightningElement, wire, api, track } from 'lwc';
import NoHeader from '@salesforce/resourceUrl/noHeader';
import getProducts from '@salesforce/apex/ProductComplaintController.getProducts';
import submitComplaints from '@salesforce/apex/ProductComplaintController.submitComplaints';
import { loadStyle } from 'lightning/platformResourceLoader';
import LABELS from './productComplaintLabels';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const CHANNEL_NAME = '/event/ProductComplaintResponseEvent__e';

export default class ProductComplaint extends LightningElement {
    @track products;
    error = undefined;
    isLoading = true;
    @track selectedProductIds = [];
    label = LABELS;
    blockButton = false;

    eventTrackingId = undefined;
    subscription;

    columns = [
        { label: this.label.name, fieldName: 'Name', type: 'text'},
        { label: this.label.productCode, fieldName: 'ProductCode', type: 'text'},
        { label: this.label.family, fieldName: 'Family', type: 'text'},
        { label: this.label.external, fieldName: 'IsExternal__c', type: 'boolean', initialWidth: 100 }
    ];

    @api recordId;

    @wire(getProducts, { orderId: '$recordId' })
    wiredProducts({ error, data}) {
        if (data) {
            this.products = data;
            this.error = undefined;
        } else if (error) {
            this.error = result.error;
            this.products = undefined;
        }
        this.isLoading = false;
    }

    connectedCallback() {
        loadStyle(this, NoHeader)
            .then(result => {});
    }

    handleSubscribe() {
        const messageCallback = (response) => { 
            if (this.eventTrackingId === undefined)
                return;

            const event = response.data.payload;
            if(event.TrackingId__c === this.eventTrackingId) {
                this.isLoading = false;
                if(event.Success__c) {
                    this.showToast(this.label.successTitle, this.label.complaintCreationSuccessMessage, 'success');
                } else {
                    this.showToast(this.label.errorTitle, this.label.complaintCreationFailMessage + event.Message__c, 'error');
                }
                this.handleDismiss();
            }
        };
        subscribe(CHANNEL_NAME, -1, messageCallback).then(response => {
            this.subscription = response;
        });
    }

    disconnectedCallback() {
        if (this.subscription === undefined)
            return;
        unsubscribe(this.subscription);
        this.subscription = undefined;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    handleRowSelection(event){
        switch (event.detail.config.action){
            case 'selectAllRows':
                for (let i = 0; i < event.detail.selectedRows.length; i++) {
                    if (!this.selectedProductIds.includes(event.detail.selectedRows[i].Id)){
                        this.selectedProductIds.push(event.detail.selectedRows[i].Id);
                    }
                }
                break;
            case 'deselectAllRows':
                this.selectedProductIds = [];
                break;
            case 'rowSelect':
                let selectedId = event.detail.config.value;
                if (!this.selectedProductIds.includes(selectedId)){
                    this.selectedProductIds.push(selectedId);
                }
                break;
            case 'rowDeselect':
                const index = this.selectedProductIds.indexOf(event.detail.config.value);
                if (index > -1) {
                    this.selectedProductIds.splice(index, 1);
                }
                break;
            default:
                break;
        }
    }

    get showCreateButton() {
        return this.selectedProductIds.length > 0;
    }

    handleCreateButton() {
        if (this.blockButton === true) {
            return;
        }
        this.isLoading = true;
        this.handleSubscribe();
        this.blockButton = true;
        submitComplaints({ productIds: this.selectedProductIds, orderId: this.recordId })
            .then(result => {
                console.log(JSON.stringify(result));

                if (result.status === 'SUCCESS'){
                    this.isLoading = false;
                    this.showToast(this.label.successTitle, this.label.complaintCreationSuccessMessage, 'success');
                    this.handleDismiss();
                } else {
                    this.eventTrackingId = result.trackingId;
                }
            })
            .catch(error => {
                this.isLoading = false;
                this.blockButton = false;
                this.error = error;
            })
        
    }

    get disableButton() {
        return this.blockButton;
    }

    handleDismiss() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}