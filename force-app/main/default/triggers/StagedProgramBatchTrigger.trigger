trigger StagedProgramBatchTrigger on Staged_Program_Batch__c (
    before insert, after insert,
    before update, after update,
    before delete, after delete,
    after undelete
) {
    new MetadataTriggerHandler().run();
}