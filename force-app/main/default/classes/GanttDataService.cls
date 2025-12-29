public with sharing class GanttDataService {

    /**
     * @description Fetch all tasks and dependencies for a specific Project
     * @param projectId The ID of the Project__c record
     * @return Map<String, Object> containing 'data' (tasks) and 'links' (dependencies)
     */
    @AuraEnabled
    public static Map<String, Object> getGanttData(String projectId) {
        Map<String, Object> resultMap = new Map<String, Object>();
        List<GanttTask> taskList = new List<GanttTask>();
        List<GanttLink> linkList = new List<GanttLink>();

        // 0. Fetch Project Name
        try {
            Project__c proj = [SELECT Name FROM Project__c WHERE Id = :projectId LIMIT 1];
            resultMap.put('projectName', proj.Name);
        } catch (Exception e) {
             resultMap.put('projectName', 'Unknown Project');
        }

        // 1. Query Project Tasks
        // Adjust fields based on actual object definition
        List<ProjectTask__c> sfTasks = [
            SELECT Id, Name, TaskStartDate__c, Duration__c, PercentDone__c, ParentId__c, IsLeaf__c,
                   Description__c, Priority__c, Index__c 
            FROM ProjectTask__c 
            WHERE Project__c = :projectId 
            ORDER BY Index__c ASC, TaskStartDate__c ASC
        ];

        // ...


        for (ProjectTask__c t : sfTasks) {
            taskList.add(new GanttTask(t));
        }

        // 2. Query Dependencies
        // Assuming we want dependencies where the Source Task belongs to this Project
        List<Dependancy__c> sfLinks = [
            SELECT Id, TaskForm__c, TaskTo__c, Type__c, Lag__c 
            FROM Dependancy__c 
            WHERE TaskForm__r.Project__c = :projectId
        ];

        for (Dependancy__c l : sfLinks) {
            linkList.add(new GanttLink(l));
        }

        // 3. (Optional) Any specific post-processing
        
        // Note: Resources are handled by GanttResourceService
        // and injected on the client side using ProjectResource__c

        resultMap.put('data', taskList);
        resultMap.put('links', linkList);
        
        return resultMap;
    }

    /**
     * @description Fetch the most recently created Project ID (Fallback for App Page)
     * @return String Project Id
     */
    @AuraEnabled
    public static String getLastProjectId() {
        List<Project__c> p = [SELECT Id FROM Project__c ORDER BY CreatedDate DESC LIMIT 1];
        return (p.isEmpty()) ? null : p[0].Id;
    }

    /**
     * @description Fetch all Project records for selection
     * @return List<Project__c>
     */
    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjects() {
        return [SELECT Id, Name FROM Project__c ORDER BY Name ASC];
    }

    // --- Wrapper Classes for DHTMLX Format ---

    public class GanttTask {
        @AuraEnabled public String id;
        @AuraEnabled public String text;
        @AuraEnabled public String start_date; // String format for better compatibility
        @AuraEnabled public Integer duration;
        @AuraEnabled public Decimal progress;
        @AuraEnabled public String parent;
        @AuraEnabled public Boolean open;
        // Owners handled separately or via generic 'map_to' if needed later
        @AuraEnabled public String description; // Description__c
        @AuraEnabled public Integer priority; // Priority__c

        public GanttTask(ProjectTask__c t) {
            this.id = t.Id;
            this.text = t.Name;
            // Format Date to YYYY-MM-DD
            this.start_date = (t.TaskStartDate__c != null) ? 
                String.valueOf(t.TaskStartDate__c) : ''; 
                
            this.duration = (t.Duration__c != null) ? Integer.valueOf(t.Duration__c) : 1;
            
            // Convert Percent (Salesforce 50.0) to Scale (0.5)
            this.progress = (t.PercentDone__c != null) ? (t.PercentDone__c / 100) : 0;
            
            this.parent = t.ParentId__c;
            this.open = true; // Default open
            
            this.description = t.Description__c;
            this.priority = (t.Priority__c != null) ? Integer.valueOf(t.Priority__c) : 2; // Default Medium(2)
        }
    }

    public class GanttLink {
        @AuraEnabled public String id;
        @AuraEnabled public String source;
        @AuraEnabled public String target;
        @AuraEnabled public String type;
        @AuraEnabled public Integer lag;

        public GanttLink(Dependancy__c l) {
            this.id = l.Id;
            this.source = l.TaskForm__c;
            this.target = l.TaskTo__c;
            // Map Type 0,1,2 directly or convert if needed. 
            // DHTMLX uses "0", "1", "2" strings usually
            this.type = (l.Type__c != null) ? String.valueOf(l.Type__c) : '0'; 
            this.lag = (l.Lag__c != null) ? Integer.valueOf(l.Lag__c) : 0;
        }
    }
    // --- CRUD Methods ---

    /**
     * @description Create a new Task
     * @param taskData JSON string representing the new task (from DHTMLX)
     * @return Id of the newly created ProjectTask__c
     */
    @AuraEnabled
    public static Id saveTask(String taskData) {
        // ... (existing saveTask logic) ...
        // (Make sure to keep the previous fix: String.valueOf checks)
        System.debug('📥 saveTask Received: ' + taskData);
        
        Map<String, Object> taskMap = (Map<String, Object>) JSON.deserializeUntyped(taskData);
        
        ProjectTask__c newTask = new ProjectTask__c();
        newTask.Project__c = String.valueOf(taskMap.get('parent_project_id')); 
        newTask.Name = (String) taskMap.get('text');
        
        String startDateStr = (String) taskMap.get('start_date');
        if(startDateStr != null) {
            newTask.TaskStartDate__c = Date.valueOf(startDateStr);
        }
        // Safe casting for Duration (handle potential Decimal/Long)
        Object dur = taskMap.get('duration');
        newTask.Duration__c = (dur != null) ? Integer.valueOf(String.valueOf(dur)) : 1;

        // PhantomID might be a large number (Long) from DHTMLX, safe convert to String
        newTask.PhantomId__c = String.valueOf(taskMap.get('id')); 
        
        // Handle Parent Task (if not root)
        String parentId = String.valueOf(taskMap.get('parent'));
        if(String.isNotBlank(parentId) && parentId != '0') {
            newTask.ParentId__c = parentId;
        }

        // Set Initial Progress if provided
        Object prog = taskMap.get('progress');
        if(prog != null) {
             newTask.PercentDone__c = Decimal.valueOf(String.valueOf(prog)) * 100;
        }

        // Additional Fields (Description, Priority)
        if(taskMap.containsKey('description')) {
            newTask.Description__c = (String) taskMap.get('description');
        }
        
        Object prio = taskMap.get('priority');
        if(prio != null) {
            newTask.Priority__c = Decimal.valueOf(String.valueOf(prio));
        }

        newTask.IsLeaf__c = true;
        
        // Auto-set Index (Basic: put at end)
        // Ideally we query MAX(Index__c), but for now we rely on reorder or default 0
        // DHTMLX often sends 'index' or 'sortorder' if configured, but let's keep it simple
        
        insert newTask;
        
        System.debug('✅ Created Task: ' + newTask.Id);
        
        return newTask.Id;
    }

    /**
     * @description Update an existing Task
     * @param taskData JSON string representing the task to update
     */
    @AuraEnabled
    public static void updateTask(String taskData) {
        System.debug('📥 updateTask Received: ' + taskData);
        
        Map<String, Object> taskMap = (Map<String, Object>) JSON.deserializeUntyped(taskData);
        
        String taskId = String.valueOf(taskMap.get('id'));
        if(String.isBlank(taskId)) return;

        ProjectTask__c t = new ProjectTask__c(Id = taskId);
        
        if(taskMap.containsKey('text')) t.Name = (String) taskMap.get('text');
        
        if(taskMap.containsKey('start_date')) {
            String startDateStr = (String) taskMap.get('start_date');
             if(startDateStr != null) t.TaskStartDate__c = Date.valueOf(startDateStr);
        }
        
        if(taskMap.containsKey('duration')) {
            Object durVal = taskMap.get('duration');
            t.Duration__c = (durVal != null) ? Integer.valueOf(String.valueOf(durVal)) : 1;
        }
        
        if(taskMap.containsKey('parent')) {
            String parentId = String.valueOf(taskMap.get('parent'));
            if(String.isNotBlank(parentId) && parentId != '0') {
                t.ParentId__c = parentId;
            } else {
                t.ParentId__c = null; // Moved to root?
            }
        }
        
        if(taskMap.containsKey('description')) {
            t.Description__c = (String) taskMap.get('description');
        }
        
        if(taskMap.containsKey('priority')) {
             Object prio = taskMap.get('priority');
             if(prio != null) {
                 t.Priority__c = Decimal.valueOf(String.valueOf(prio));
             }
        }
        
        update t;
        
        System.debug('✅ Updated Task: ' + t.Id);
    }

    /**
     * @description Create a new Dependency Link
     * @param linkData JSON string representing the new link
     * @return Id of the newly created Dependancy__c
     */
    @AuraEnabled
    public static Id saveLink(String linkData) {
        System.debug('📥 saveLink Received: ' + linkData);
        
        Map<String, Object> linkMap = (Map<String, Object>) JSON.deserializeUntyped(linkData);
        
        Dependancy__c newLink = new Dependancy__c();
        
        // Populate Master-Detail Project
        newLink.Project__c = String.valueOf(linkMap.get('parent_project_id'));
        
        // Map DHTMLX source/target to Salesforce Fields
        // Ensure we are using String.valueOf for safety with numeric IDs
        newLink.TaskForm__c = String.valueOf(linkMap.get('source')); 
        newLink.TaskTo__c   = String.valueOf(linkMap.get('target'));
        
        // Type: "0", "1", "2" -> Decimal/Integer
        Object typeObj = linkMap.get('type');
        newLink.Type__c = (typeObj != null) ? Decimal.valueOf(String.valueOf(typeObj)) : 0;
        
        // Lag
        Object lagObj = linkMap.get('lag'); 
        if(lagObj != null) {
            newLink.Lag__c = Decimal.valueOf(String.valueOf(lagObj));
        }

        // Check for duplicates before inserting
        List<Dependancy__c> existingLinks = [
            SELECT Id 
            FROM Dependancy__c 
            WHERE TaskForm__c = :newLink.TaskForm__c 
              AND TaskTo__c = :newLink.TaskTo__c 
            LIMIT 1
        ];

        if (!existingLinks.isEmpty()) {
            System.debug('⚠️ Link already exists: ' + existingLinks[0].Id);
            return existingLinks[0].Id;
        }

        insert newLink;
        System.debug('✅ Created Link: ' + newLink.Id);
        
        return newLink.Id;
    }

    /**
     * @description Delete a Task
     * @param taskId The ID of the ProjectTask__c to delete
     */
    @AuraEnabled
    public static void deleteTask(String taskId) {
        System.debug('🗑️ deleteRequest TaskId: ' + taskId);
        if(String.isNotBlank(taskId)) {
            try {
                // 1. Delete related Dependencies (Lookup relationship, so manual delete needed)
                List<Dependancy__c> relatedLinks = [
                    SELECT Id 
                    FROM Dependancy__c 
                    WHERE TaskForm__c = :taskId OR TaskTo__c = :taskId
                ];
                
                if(!relatedLinks.isEmpty()) {
                    System.debug('🔗 Deleting ' + relatedLinks.size() + ' related dependencies');
                    delete relatedLinks;
                }

                // 2. Delete the Task (Cascade deletes Master-Detail children: Assignment, Time, Expense, TaskSegment)
                delete new ProjectTask__c(Id = taskId);
                System.debug('✅ Deleted Task: ' + taskId);
            } catch(Exception e) {
                System.debug('❌ Error deleting task: ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        }
    }

    /**
     * @description Delete a Link
     * @param linkId The ID of the Dependancy__c to delete
     */
    @AuraEnabled
    public static void deleteLink(String linkId) {
        System.debug('🗑️ deleteRequest LinkId: ' + linkId);
        if(String.isNotBlank(linkId)) {
            try {
                delete new Dependancy__c(Id = linkId);
                System.debug('✅ Deleted Link: ' + linkId);
            } catch(Exception e) {
                 System.debug('❌ Error deleting link: ' + e.getMessage());
                 throw new AuraHandledException(e.getMessage());
            }
        }
    }

    /**
     * @description Reorder Task (Row Drag & Drop)
     * @param taskId The ID of the task being moved
     * @param targetId The ID of the task it is placed BEFORE (or null if last) -> DHTMLX logic varies
     * @param parentId The new parent ID (if hierarchy changed)
     * @param index The new index (0-based)
     */
    @AuraEnabled
    public static void reorderTask(String taskId, String parentId, Integer index) {
        System.debug('🔄 reorderTask: ' + taskId + ' to parent: ' + parentId + ' at index: ' + index);
        
        // 1. Update the moved task's Parent and Index
        ProjectTask__c t = new ProjectTask__c(Id = taskId);
        t.Index__c = index;
        
        // Handle Parent Logic
        if(String.isNotBlank(parentId) && parentId != '0') {
             t.ParentId__c = parentId;
        } else {
             t.ParentId__c = null; // Root
        }
        update t;

        // 2. We SHOULD shift other tasks' indices in the same parent grouping to avoid collisions
        // But for a simple "visual" reorder where we rely on DHTMLX sending correct indices for all/next
        // It's complex. DHTMLX only sends "Where I dropped this one".
        // A robust solution usually requires re-indexing the siblings.
        
        // Logic:
        // Query all siblings in the new parent group, excluding the moved task, ordered by Index/Name
        // Insert the moved task at the correct position in the list
        // Update ALL indices in that group
        
        // (Simplified for this MVP: Just update this one. DHTMLX might get out of sync on refresh 
        // if we don't shift others. Let's do a bulk update of siblings for correctness.)
        
        String pId = (String.isNotBlank(parentId) && parentId != '0') ? parentId : null;
        
        // Fetch Project ID first
        Id projId = [SELECT Project__c FROM ProjectTask__c WHERE Id = :taskId LIMIT 1].Project__c;
        
        List<ProjectTask__c> siblings = [
            SELECT Id, Index__c 
            FROM ProjectTask__c 
            WHERE Project__c = :projId
              AND ParentId__c = :pId
              AND Id != :taskId
            ORDER BY Index__c ASC, TaskStartDate__c ASC
        ];
        
        List<ProjectTask__c> toUpdate = new List<ProjectTask__c>();
        
        // Insert moved task into list logic? 
        // DHTMLX gives us the ABSOLUTE index in that branch string.
        
        Integer currentIndex = 0;
        for(ProjectTask__c sib : siblings) {
            if(currentIndex == index) {
                currentIndex++; // Skip the slot for the moved task
            }
            if(sib.Index__c != currentIndex) {
                sib.Index__c = currentIndex;
                toUpdate.add(sib);
            }
            currentIndex++;
        }
        
        if(!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}
