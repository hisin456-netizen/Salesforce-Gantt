// ==========================================
// Create Demo Data for Task Segments (Split Tasks)
// ==========================================

// 1. Fetch Request Project & Task
Project__c prj = [SELECT Id FROM Project__c ORDER BY CreatedDate DESC LIMIT 1];
// We will split the 'Styling' task or 'Grid' task
List<ProjectTask__c> targets = [SELECT Id, Name, TaskStartDate__c FROM ProjectTask__c WHERE Project__c = :prj.Id AND Name LIKE '%Styling%' LIMIT 1];

if(targets.isEmpty()){
    System.debug('❌ Target Task (Styling) not found. Please run create_demo.apex first.');
    return;
}

ProjectTask__c targetTask = targets[0];
Date baseDate = (targetTask.TaskStartDate__c != null) ? targetTask.TaskStartDate__c : Date.today();

// 2. Prepare TaskSegment__c Fields
Map<String, Schema.SObjectField> segFields = Schema.SObjectType.TaskSegment__c.fields.getMap();

// Helper to pick valid field
String F_TASK  = (segFields.containsKey('ProjectTask__c')) ? 'ProjectTask__c' : 'Task__c';
String F_START = (segFields.containsKey('SegmentStart__c')) ? 'SegmentStart__c' : 'StartDate__c';
String F_END   = (segFields.containsKey('SegmentEnd__c'))   ? 'SegmentEnd__c'   : 'EndDate__c';
String F_NOTE  = (segFields.containsKey('Note__c'))         ? 'Note__c'         : null;

System.debug('🔎 Field Mapping: Task=' + F_TASK + ', Start=' + F_START + ', End=' + F_END);

if(F_TASK == null || F_START == null || F_END == null){
    System.debug('❌ Required fields for TaskSegment__c not found.');
    return;
}

// 3. Create Segments
List<TaskSegment__c> newSegments = new List<TaskSegment__c>();

// Segment 1: Day 1 ~ Day 2 (2 Days)
TaskSegment__c s1 = new TaskSegment__c();
s1.put(F_TASK, targetTask.Id);
s1.put(F_START, baseDate);
s1.put(F_END, baseDate.addDays(2));
if(F_NOTE != null) s1.put(F_NOTE, 'First Draft');
newSegments.add(s1);

// Gap: Day 3 (Break)

// Segment 2: Day 4 ~ Day 5 (2 Days)
TaskSegment__c s2 = new TaskSegment__c();
s2.put(F_TASK, targetTask.Id);
s2.put(F_START, baseDate.addDays(3));
s2.put(F_END, baseDate.addDays(5));
if(F_NOTE != null) s2.put(F_NOTE, 'Final Polish');
newSegments.add(s2);

try {
    insert newSegments;
    System.debug('✅ Created ' + newSegments.size() + ' Task Segments for Task: ' + targetTask.Name);
} catch(Exception e) {
    System.debug('❌ Failed to create segments: ' + e.getMessage());
}
