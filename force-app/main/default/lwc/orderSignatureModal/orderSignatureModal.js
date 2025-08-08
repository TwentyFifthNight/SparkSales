import { LightningElement, api, wire } from 'lwc';
import saveSignature from '@salesforce/apex/SignatureController.saveSignature';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { CloseActionScreenEvent } from 'lightning/actions';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import CONTRACT_OBJECT from '@salesforce/schema/Contract';
import USER_OBJECT from '@salesforce/schema/User';
import LABELS from './orderSignatureModalLabels';

export default class SignatureCanvas extends LightningElement {
    label = LABELS;

    @api recordId;
    headerText='Sign the invoice';
    blockButton=false;
    isLoading=false;
    contractNumberLabel;
    accountNameLabel;
    orderOwnerNameLabel;

    @wire(getObjectInfo, { objectApiName: CONTRACT_OBJECT })
    contractInfo({data, error}){
        if(data){
            this.contractNumberLabel = data.fields.ContractNumber.label;
        }
    }
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountInfo({data, error}){
        if(data){
            this.accountNameLabel = data.fields.Name.label;
        }
    }
    @wire(getObjectInfo, { objectApiName: USER_OBJECT })
    userInfo({data, error}){
        if(data){
            this.orderOwnerNameLabel = data.fields.Name.label;
        }
    }

    handleSaveButton(e) {
        if(this.blockButton === true)
            return;
        this.blockButton = true;
        this.isLoading = true;
        let convertedDataURI = this.template.querySelector("c-signature-canvas").getSignatureData();
        saveSignature({signElement: convertedDataURI, recId: this.recordId})
        .then(result => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Signature Image saved. If there is an Invoice file, it will be updated.',
                    variant: 'success',
                }),
            );
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error uploading signature in Salesforce record',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        })
        .finally(() => {
            this.blockButton = false;
            this.isLoading = false;
            this.closeQuickAction();
        });
    }

    handleClearClick() {
        if(this.blockButton)
            return;
        this.template.querySelector("c-signature-canvas").clearCanvas();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}