import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import BATCH_OBJECT from '@salesforce/schema/Staged_Program_Batch__c';
import NAME_FIELD from '@salesforce/schema/Staged_Program_Batch__c.Name';
import STATUS_FIELD from '@salesforce/schema/Staged_Program_Batch__c.Status__c';
import DESCRIPTION_FIELD from '@salesforce/schema/Staged_Program_Batch__c.Description__c';

const FIELDS = [NAME_FIELD, STATUS_FIELD, DESCRIPTION_FIELD];

export default class StagedProgramBatchManager extends LightningElement {
    @api recordId;
    error;
    isLoading = false;

    reviewFlowName = 'SPB_SFRP_ReviewStagedPrograms';

    batchRecordInfo;
    name;
    status;
    description;

    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            this.handleError(error);
        } else if (data) {
            this.batchRecordInfo = data;
            this.name = this.batchRecordInfo.fields.Name.value;
            this.status = this.batchRecordInfo.fields.Status__c.value;
            this.description = this.batchRecordInfo.fields.Description__c.value;
        }
    }

    get cardTitle() {
        return this.name ? this.name : '';
    }

    get inputVariables() {
        let results = [];
        if (this.recordId) {
            results.push({
                name: 'recordId',
                type: 'String',
                value: this.recordId
            });
        }
        return results;
    }

    handleFlowStatusChange() {
        const { status, flowTitle, guid } = event.detail;
        console.log('::::: flow status --> ',status);
        console.log('::::: flow title --> ',flowTitle);
        console.log('::::: flow guid --> ',guid);

        /*
        These are the valid status values for a flow interview.
        STARTED: The interview is started and ongoing.
        PAUSED: The interview is paused successfully.
        FINISHED: The interview for a flow with screens is finished.
        FINISHED_SCREEN: The interview for a flow without screens is finished.
        ERROR: Something went wrong and the interview failed.

        https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowinterview.htm
         */
        if (status === 'FINISHED') {
            console.log(':::: completed the flow');
            this.dispatchEvent(new CustomEvent('finished'));
        }
    }

    handleError(error) {
        let message = "Unknown error";
        if (Array.isArray(error.body)) {
            message = error.body.map((e) => e.message).join(", ");
        } else if (typeof error.body.message === "string") {
            message = error.body.message;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: "An Error Occurred",
                message,
                variant: "error",
            })
        );
    }

}