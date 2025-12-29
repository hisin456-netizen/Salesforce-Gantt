public with sharing class GanttResourceService {

    /**
     * @description Fetch active users for resource assignment
     * @return List of formatted resource objects {key, label} for DHTMLX
     */
    @AuraEnabled
    public static List<Map<String, String>> getResources() {
        List<Map<String, String>> resources = new List<Map<String, String>>();
        for(User u : [SELECT Id, LastName, FirstName FROM User WHERE IsActive = true ORDER BY LastName LIMIT 100]) {
            Map<String, String> res = new Map<String, String>();
            res.put('key', u.Id);
            res.put('label', u.LastName + (u.FirstName != null ? ' ' + u.FirstName : ''));
            resources.add(res);
        }
        return resources;
    }

    /**
     * @description Fetch existing assignments for a project map(TaskId -> OwnerId)
     * @param projectId The project ID
     * @return Map<Id, String> TaskId -> UserId
     */
    @AuraEnabled
    public static Map<String, String> getAssignments(String projectId) {
        Map<String, String> assignmentMap = new Map<String, String>();
        for(Assignment__c a : [SELECT Task__c, AssignedTo__c FROM Assignment__c WHERE Project__c = :projectId]) {
            if(a.AssignedTo__c != null) {
                assignmentMap.put(a.Task__c, a.AssignedTo__c);
            }
        }
        return assignmentMap;
    }

    /**
     * @description Create or replace assignment for a task (1:1 Single Mode)
     * @param taskId Task ID
     * @param ownerId Selected User ID
     */
    @AuraEnabled
    public static void assignResource(String taskId, String ownerId) {
        if(String.isBlank(taskId)) return;

        // 1. Delete existing assignments for this task
        delete [SELECT Id FROM Assignment__c WHERE Task__c = :taskId];

        // 2. Insert new if provided
        if(String.isNotBlank(ownerId)) {
            Id projId = [SELECT Project__c FROM ProjectTask__c WHERE Id = :taskId LIMIT 1].Project__c;
            Assignment__c assign = new Assignment__c();
            assign.Project__c = projId;
            assign.Task__c = taskId;
            assign.AssignedTo__c = ownerId;
            insert assign;
        }
    }
}
