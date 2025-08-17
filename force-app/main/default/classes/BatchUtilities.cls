public class BatchUtilities {
    
    /*
    * TODO - Deprecate this method in favor of the version in CommonUtilities
    *        Need to remove from batch classes first
    */
    public static Boolean isOrgEmailEnabled() {
        Boolean emailDeliverabilityEnabled = true;
        try {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.reserveMassEmailCapacity(1);
        } catch (System.NoAccessException e) {
            emailDeliverabilityEnabled = false;
        }
        return emailDeliverabilityEnabled;
    }

    public static Database.SaveResult publishBatchResultEvent(AsyncApexJob apexJob, String results) {
        Batch_Result__e batchResultEvent = new Batch_Result__e();
        batchResultEvent.Job_ID__c = apexJob.Id;
        batchResultEvent.Batch_Class__c = apexJob.ApexClass.Name;
        batchResultEvent.Status__c = apexJob.Status;
        batchResultEvent.Total_Job_Items__c = apexJob.TotalJobItems;
        batchResultEvent.Job_Items_Processed__c = apexJob.JobItemsProcessed;
        batchResultEvent.Number_of_Errors__c = apexJob.NumberOfErrors;
        if (results != null) {
            batchResultEvent.Results__c = results;
        }
        return EventBus.publish(batchResultEvent);
    }

    public static void sendJobCreatorEmailResult(AsyncApexJob apexJob) {
        String createdByEmail = apexJob.CreatedBy.Email;
        if (CommonUtilities.isOrgEmailEnabled() && !createdByEmail.startsWith('autoproc')) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] toAddress = new String[] {createdByEmail};
            email.setToAddresses(toAddress);
            email.setSubject(apexJob.Status + ': ' + apexJob.ApexClass.Name);
            email.setPlainTextBody('The ' + apexJob.ApexClass.Name + ' ran and processed ' + apexJob.TotalJobItems + 
                                   ' batches with ' + apexJob.NumberOfErrors + ' failures. Job Id: ' + apexJob.Id);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }

    public static AsyncApexJob getAsyncApexJobById(Id jobId) {
        return [
            SELECT Id, 
                   Status, 
                   NumberOfErrors, 
                   JobItemsProcessed, 
                   TotalJobItems, 
                   CreatedBy.Email,
                   ApexClass.Name
              FROM AsyncApexJob 
             WHERE Id = :jobId
              WITH SYSTEM_MODE
        ];
    }

}