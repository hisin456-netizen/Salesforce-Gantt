/**
 * Delete all Assignment__c records to reset data.
 */
List<Assignment__c> allAssignments = [SELECT Id FROM Assignment__c];
if (!allAssignments.isEmpty()) {
    delete allAssignments;
    System.debug('✅ Deleted ' + allAssignments.size() + ' Assignment__c records.');
} else {
    System.debug('ℹ️ No Assignment__c records found.');
}
