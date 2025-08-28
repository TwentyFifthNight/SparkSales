trigger ComplaintItemsCompleted on ComplaintItemCompleted__e (after insert) {
    new MetadataTriggerHandler().run();
}