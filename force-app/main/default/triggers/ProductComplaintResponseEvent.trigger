trigger ProductComplaintResponseEvent on ProductComplaintResponseEvent__e (after insert) {
    new MetadataTriggerHandler().run();
}


