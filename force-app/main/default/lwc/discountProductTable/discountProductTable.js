import { LightningElement, track, api} from 'lwc';
import LABELS from './discountProductTableLabels';

export default class DiscountProductTable extends LightningElement {
    label = LABELS;

    columns = [
        { label: this.label.product, fieldName: 'Name', type: 'text' }
    ];

    @api selectedProductIds = [];

    products = [];
    @api set pricebookEntries(value) {
        let productList = value.map(pricebookEntry => {
            let product = {
                Id: pricebookEntry.Product2Id,
                Name: pricebookEntry.Name
            };
            return product;
        });
        this.products = productList;
    }
    get pricebookEntries() {
        return [];
    }

    @api
    validate() {
        let currentProductIds = this.products.map(product => {
            return product.Id;
        });
        this.selectedProductIds = this.selectedProductIds.filter(productId => {
            return currentProductIds.includes(productId);
        });
        if(this.selectedProductIds.length > 0) {
            return { isValid: true };
            }
        else {
            return {
                isValid: false,
                errorMessage: 'Select at least one product'
            };
        }
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
}