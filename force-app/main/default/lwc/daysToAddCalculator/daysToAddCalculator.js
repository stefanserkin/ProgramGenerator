import { LightningElement, api, wire } from 'lwc';
import getSampleCourseOption from '@salesforce/apex/DaysToAddCalculatorController.getSampleCourseOption';

export default class DaysToAddCalculator extends LightningElement {
    @api programId;
    @api sessionId;
    @api daysToAdd;

    isLoading = false;
    error;

    wiredCourseOption = [];
    courseOption;
    oldStartDate;

    @wire(getSampleCourseOption, { programId: '$programId', sessionId: '$sessionId' })
    wiredResult(result) {
        this.isLoading = true;
        this.wiredCourseOption = result;
        if (result.data) {
            this.courseOption = JSON.parse( JSON.stringify(result.data) );
            this.oldStartDate = new Date(this.courseOption.TREX1__Start_Date__c);
            this.error = undefined;
        } else if (result.error) {
            this.courseOption = undefined;
            this.error = result.error;
            console.error(this.error);
        }
    }

    get newStartDate() {
        if (!this.oldStartDate || this.daysToAdd == null) {
            return;
        }

        const oldDate = new Date(this.oldStartDate);
        const newDate = new Date(oldDate.getTime() + this.daysToAdd * 24 * 60 * 60 * 1000);
        return this.formatDate(newDate);
    }

    get exampleMessage() {
        let message = '';
        if (this.courseOption) {
            message = `Example: ${this.courseOption.Name}, which began on ${this.formatDate(this.oldStartDate)}, will now have a start date of ${this.newStartDate}.`;
        }
        return message;
    }

    handleDaysToAddChange(event) {
        this.daysToAdd = event.detail.value;
    }

    formatDate(dt) {
        if (!dt) return null;
    
        return new Intl.DateTimeFormat('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        }).format(dt);
    }

}