import { LightningElement, api } from 'lwc';

export default class ProductListSummary extends LightningElement {
    @api products = [];
    columns = [
        { label: 'Name', fieldName: 'Name', type: 'text'},
        //{ label: 'Name', fieldName: 'URL', type: 'url', typeAttributes: { label: {fieldName: 'Name'}}},
        { label: 'Product Code', fieldName: 'ProductCode', type: 'text'},
        { label: 'Family', fieldName: 'Family', type: 'text'},
        //{ type: 'action', typeAttributes: { rowActions: ACTIONS } }
    ];
}