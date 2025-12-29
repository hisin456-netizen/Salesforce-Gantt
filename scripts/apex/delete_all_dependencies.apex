/**
 * Delete ALL Dependancy__c records.
 * Use this to reset the Gantt chart dependencies.
 */
List<Dependancy__c> allLinks = [SELECT Id FROM Dependancy__c];
if (!allLinks.isEmpty()) {
    delete allLinks;
    System.debug('✅ Deleted ' + allLinks.size() + ' dependencies.');
} else {
    System.debug('⚠️ No dependencies found to delete.');
}
