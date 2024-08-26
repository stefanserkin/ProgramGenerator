import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, onError } from 'lightning/empApi';
import { RefreshEvent } from 'lightning/refresh';

export default class StagedProgramBatchListener extends LightningElement {
    @api recordId;
    isLoading = false;
    error;

    batchStatus;

    channelName = '/event/Staged_Program_Batch_Event__e';
    subscription = {};

    connectedCallback() {
        this.registerErrorListener();
        this.handleSubscribe();
    }

    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const messageCallback = response => {
            const batchId = String(response.data.payload.Batch_ID__c);
            if (this.recordId === batchId) {
                this.batchStatus = String(response.data.payload.Status__c);
                this.showToast();
                this.refreshRecord();
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            this.subscription = response;
        });
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
        });
    }

    refreshRecord() {
        this.dispatchEvent(new RefreshEvent());
    }

    showToast() {
        let title = 'Batch Completed';
        let message = 'The batch finished processing';
        let variant = 'info';

        if (this.batchStatus === 'Complete') {
            message = 'The batch was successfully processed';
            variant = 'success';
        } else if (this.batchStatus === 'Processed with Errors') {
            message = 'The batch has completed processing, but encountered errors. Review errors in the Error Log.';
            variant = 'warning';
        }

        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }

}