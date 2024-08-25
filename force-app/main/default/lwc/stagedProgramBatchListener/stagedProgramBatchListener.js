import { LightningElement, api } from 'lwc';
import { subscribe, onError } from 'lightning/empApi';
import { RefreshEvent } from 'lightning/refresh';

export default class StagedProgramBatchListener extends LightningElement {
    @api recordId;
    isLoading = false;
    error;

    channelName = '/event/Staged_Program_Batch_Event__e';
    subscription = {};

    connectedCallback() {
        this.registerErrorListener();
        this.handleSubscribe();
    }

    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const messageCallback = response => {
            console.log('New message received: ', JSON.stringify(response));
            // Response contains the payload of the new message received
            const batchId = String(response.data.payload.Batch_ID__c);
            console.log('batchId --> ' + batchId);
            console.log('recordId --> ' + this.recordId);
            console.log('type of batchId --> ' + typeof recordId);
            console.log('type of recordId --> ' + typeof this.recordId);
            if (this.recordId === batchId) {
                this.refreshRecord();
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            // Response contains the subscription information on subscribe call
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );
            this.subscription = response;
        });
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }

    refreshRecord() {
        console.log(':::: called refreshRecord()');
        this.dispatchEvent(new RefreshEvent());
    }

}