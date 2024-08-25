import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getStagedPrograms from '@salesforce/apex/StagedProgramEditorController.getStagedPrograms';

const COLS = [
    { label: 'Name', fieldName: 'Name', editable: true },
    { label: 'Status', fieldName: 'Status__c', editable: true },
    { label: 'Location', fieldName: 'Location__c', editable: true }
];

export default class StagedProgramEditor extends LightningElement {
    @api recordId;
    error;

    isLoading = false;

    cols = COLS;

    wiredStagedPrograms = [];
    stagedPrograms;
    draftValues = [];
    selectedRows = [];

    @wire(getStagedPrograms, { recordId: '$recordId'})
    wiredStagedProgramResult(result) {
        this.isLoading = true;
        this.wiredStagedPrograms = result;

        if (result.data) {
            this.stagedPrograms = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.stagedPrograms = undefined;
            this.error = result.error;
        }
    }

    handleSave() {
        alert(`saving stuff`);
    }

    handleRowActions() {
        alert(`doing row action stuff`);
    }

}