// ================================
// Salesforce DHTMLX Gantt - Create Remaining Demo Data
// (For users who already created Project/Tasks)
// ================================

// ---- Helper: safe percent(0~100) ----
Integer pct(Integer v){ return Math.max(0, Math.min(100, v)); }

// ---- Helper: pick first existing field from candidates ----
String pickField(Map<String, Schema.SObjectField> m, List<String> candidates){
    for(String c : candidates){
        if(m.containsKey(c)) return c;
    }
    return null;
}

// 1) Fetch Latest Project
Project__c prj = [SELECT Id, Name FROM Project__c ORDER BY CreatedDate DESC LIMIT 1];
System.debug('✅ Found Project: ' + prj.Name + ' (' + prj.Id + ')');

List<ProjectTask__c> tasks = [SELECT Id, Name FROM ProjectTask__c WHERE Project__c = :prj.Id];
System.debug('✅ Found Tasks: ' + tasks.size());

// Map tasks by Name for easy reference
Map<String, Id> tMap = new Map<String, Id>();
for(ProjectTask__c t : tasks){
    tMap.put(t.Name, t.Id);
    System.debug('Task Found: ' + t.Name + ' => ' + t.Id);
}

// Helper to get ID by Name
Id getTaskId(Map<String, Id> m, String name){
    // Partial match logic or exact match
    if(m.containsKey(name)) return m.get(name);
    // Find partial
    for(String key : m.keySet()){
        if(key.contains(name)) return m.get(key);
    }
    System.debug('❌ Could not find Task containing: ' + name);
    return null;
}

// Define specific task IDs for relationships
Id tWrapper  = getTaskId(tMap, 'Wrapper');
Id tService  = getTaskId(tMap, 'GanttDataService');
Id tTrigger  = getTaskId(tMap, 'Trigger');
Id tMount    = getTaskId(tMap, 'Library');
Id tGrid     = getTaskId(tMap, 'Grid');
Id tStyle    = getTaskId(tMap, 'Styling');
Id tCrud     = getTaskId(tMap, 'CRUD');
Id tDepLogic = getTaskId(tMap, 'Dependency');
Id tResource = getTaskId(tMap, 'Resource');
Id tExport   = getTaskId(tMap, 'Export');
Id tPerf     = getTaskId(tMap, 'Performance');
Id msGoLive  = getTaskId(tMap, 'Go-Live');

Date d0 = Date.today();

// 2) Assignment Setup (Need Contacts)
// Check if Contacts exist, if not create basic ones
List<Contact> demoContacts = [SELECT Id FROM Contact WHERE Account.Name = 'Gantt Demo Account' LIMIT 4];
if(demoContacts.isEmpty()){
    Account acc = new Account(Name = 'Gantt Demo Account');
    insert acc;
    demoContacts = new List<Contact>{
        new Contact(LastName='정회석', AccountId=acc.Id),
        new Contact(LastName='박준기', AccountId=acc.Id),
        new Contact(LastName='장민석', AccountId=acc.Id),
        new Contact(LastName='김범우', AccountId=acc.Id)
    };
    insert demoContacts;
}

// ===== Dependancy__c =====
try{
    Map<String, Schema.SObjectField> depF = Schema.SObjectType.Dependancy__c.fields.getMap();
    String DF_FROM = pickField(depF, new List<String>{ 'TaskFrom__c', 'TaskForm__c' }); 
    String DF_TO   = pickField(depF, new List<String>{ 'TaskTo__c' });
    String DF_TYPE = pickField(depF, new List<String>{ 'Type__c' });

    // Check for Project field in Dependency
    String DF_PRJ = pickField(depF, new List<String>{ 'Project__c' });

    if(DF_FROM != null && DF_TO != null && DF_TYPE != null){
        List<Dependancy__c> deps = new List<Dependancy__c>();
        
        // tWrapper -> tService
        if(tWrapper != null && tService != null) {
            Dependancy__c d1 = new Dependancy__c();
            d1.put(DF_FROM, tWrapper); d1.put(DF_TO, tService); d1.put(DF_TYPE, 0); 
            if(DF_PRJ != null) d1.put(DF_PRJ, prj.Id); // Set Master Project
            deps.add(d1);
        } else { System.debug('⚠️ Skipping Dep 1: tWrapper or tService missing'); }

        // tService -> tTrigger
        if(tService != null && tTrigger != null) {
            Dependancy__c d2 = new Dependancy__c();
            d2.put(DF_FROM, tService); d2.put(DF_TO, tTrigger); d2.put(DF_TYPE, 0); 
            if(DF_PRJ != null) d2.put(DF_PRJ, prj.Id);
            deps.add(d2);
        } else { System.debug('⚠️ Skipping Dep 2: tService or tTrigger missing'); }

        // tCrud -> tDepLogic
        if(tCrud != null && tDepLogic != null) {
            Dependancy__c d3 = new Dependancy__c();
            d3.put(DF_FROM, tCrud); d3.put(DF_TO, tDepLogic); d3.put(DF_TYPE, 0); 
            if(DF_PRJ != null) d3.put(DF_PRJ, prj.Id);
            deps.add(d3);
        } else { System.debug('⚠️ Skipping Dep 3: tCrud or tDepLogic missing'); }

        if(!deps.isEmpty()) {
            insert deps;
            System.debug('✅ Dependancy__c created: ' + deps.size());
        } else {
             System.debug('⚠️ No Dependancy rows prepared (check missing tasks)');
        }
    } else {
        System.debug('ℹ️ Dependancy__c Skipped: Fields not found');
    }
}catch(Exception e){
    System.debug('ℹ️ Dependancy__c Error: ' + e.getMessage());
}

// ===== Assignment__c =====
try{
    Map<String, Schema.SObjectField> asF = Schema.SObjectType.Assignment__c.fields.getMap();
    String AF_TASK   = pickField(asF, new List<String>{ 'Task__c' });
    String AF_USER   = pickField(asF, new List<String>{ 'AssignedTo__c' });
    String AF_UNITS  = pickField(asF, new List<String>{ 'Units__c' });
    String AF_PRJ    = pickField(asF, new List<String>{ 'Project__c' }); // Project Master-Detail

    System.debug('🔎 Assignment Fields: Task=' + AF_TASK + ', User=' + AF_USER + ', Units=' + AF_UNITS + ', Prj=' + AF_PRJ);

    if(AF_TASK != null && AF_USER != null){
        // 2) User Setup (Create if not exists with Fallback)
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        String emailSuffix = '@gantt.demo.test';

        // Pre-fetch current user for fallback
        User fallbackUser = new User(Id=UserInfo.getUserId());

        // Helper Function (Local Interface approach not supported in Execute Anon, using Map logic)
        Map<String, User> targetUsers = new Map<String, User>();
        List<String> userNames = new List<String>{'정회석', '박준기', '장민석', '김범우'};
        Map<String, String> userAliases = new Map<String, String>{
            '정회석'=>'jeong', '박준기'=>'park', '장민석'=>'jang', '김범우'=>'kim'
        };

        // 2-1. Check Existing
        for(User u : [SELECT Id, LastName FROM User WHERE LastName IN :userNames]){
            targetUsers.put(u.LastName, u);
        }

        // 2-2. Create Missing (Try-Catch for License Limits)
        for(String name : userNames){
            if(!targetUsers.containsKey(name)){
                try {
                    String alias = userAliases.get(name);
                    User u = new User(
                        Alias = alias, 
                        Email = alias + emailSuffix, 
                        EmailEncodingKey='UTF-8', 
                        LastName=name, 
                        LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', 
                        ProfileId = p.Id, 
                        TimeZoneSidKey='Asia/Seoul', 
                        UserName = alias + '_' + System.currentTimeMillis() + emailSuffix
                    );
                    insert u;
                    targetUsers.put(name, u);
                    System.debug('✅ Created User: ' + name);
                } catch(Exception e) {
                    System.debug('⚠️ Failed to create User (' + name + '): ' + e.getMessage());
                    System.debug('🔄 Fallback: Assigning ' + name + '\'s work to Current User.');
                    targetUsers.put(name, fallbackUser);
                }
            }
        }

        User uJeong = targetUsers.get('정회석');
        User uPark  = targetUsers.get('박준기');
        User uJang  = targetUsers.get('장민석');
        User uKim   = targetUsers.get('김범우');

        System.debug('✅ Users Finalized: Jeong=' + uJeong.Id + ', Park=' + uPark.Id + ', Jang=' + uJang.Id + ', Kim=' + uKim.Id);

        List<Assignment__c> assigns = new List<Assignment__c>();

        // 정회석: Backend & Data (Service, Wrapper, Trigger, CRUD, Performance)
        if(tService != null) { Assignment__c a = new Assignment__c(); a.put(AF_TASK, tService); a.put(AF_USER, uJeong.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }
        if(tWrapper != null) { Assignment__c a = new Assignment__c(); a.put(AF_TASK, tWrapper); a.put(AF_USER, uJeong.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }
        if(tTrigger != null) { Assignment__c a = new Assignment__c(); a.put(AF_TASK, tTrigger); a.put(AF_USER, uJeong.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }
        if(tCrud != null)    { Assignment__c a = new Assignment__c(); a.put(AF_TASK, tCrud);    a.put(AF_USER, uJeong.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }
        if(tPerf != null)    { Assignment__c a = new Assignment__c(); a.put(AF_TASK, tPerf);    a.put(AF_USER, uJeong.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }

        // 박준기: Frontend (Library, Grid, Style)
        if(tMount != null)  { Assignment__c a = new Assignment__c(); a.put(AF_TASK, tMount); a.put(AF_USER, uPark.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }
        if(tGrid != null)   { Assignment__c a = new Assignment__c(); a.put(AF_TASK, tGrid); a.put(AF_USER, uPark.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }
        if(tStyle != null)  { Assignment__c a = new Assignment__c(); a.put(AF_TASK, tStyle); a.put(AF_USER, uPark.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }

        // 장민석: Logic (Dependency, Go-Live Sync)
        if(tDepLogic != null){ Assignment__c a = new Assignment__c(); a.put(AF_TASK, tDepLogic); a.put(AF_USER, uJang.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }
        if(msGoLive != null) { Assignment__c a = new Assignment__c(); a.put(AF_TASK, msGoLive);  a.put(AF_USER, uJang.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }
        
        // 김범우: Resource (Resource, Export)
        if(tResource != null){ Assignment__c a = new Assignment__c(); a.put(AF_TASK, tResource); a.put(AF_USER, uKim.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }
        if(tExport != null)  { Assignment__c a = new Assignment__c(); a.put(AF_TASK, tExport); a.put(AF_USER, uKim.Id); if(AF_UNITS != null) a.put(AF_UNITS, 1); if(AF_PRJ != null) a.put(AF_PRJ, prj.Id); assigns.add(a); }

        if(!assigns.isEmpty()) {
            insert assigns;
            System.debug('✅ Assignment__c created: ' + assigns.size());
        }
    }
}catch(Exception e){
    System.debug('ℹ️ Assignment__c Error: ' + e.getMessage());
}

// ===== Time__c =====
try{
    Map<String, Schema.SObjectField> tmF = Schema.SObjectType.Time__c.fields.getMap();
    String TF_TASK  = pickField(tmF, new List<String>{ 'Task__c' });
    String TF_START = pickField(tmF, new List<String>{ 'StartDate__c' });
    String TF_END   = pickField(tmF, new List<String>{ 'EndDate__c' });
    String TF_NAME  = pickField(tmF, new List<String>{ 'Name__c' });
    String TF_WHO   = pickField(tmF, new List<String>{ 'Incurred_by__c', 'IncurredBy__c' }); // Check 'Who' field

    System.debug('🔎 Time Fields: Task=' + TF_TASK + ', Start=' + TF_START + ', End=' + TF_END + ', Who=' + TF_WHO);

    if(TF_TASK != null && TF_START != null && TF_END != null && tService != null){
        List<Time__c> times = new List<Time__c>();
        Id currentUser = UserInfo.getUserId(); // Use current user for demo

        Time__c tA = new Time__c(); 
        tA.put(TF_TASK, tService); 
        tA.put(TF_START, d0.addDays(3)); 
        tA.put(TF_END, d0.addDays(3)); 
        if(TF_NAME != null) tA.put(TF_NAME, 'Morning Session');
        if(TF_WHO != null)  tA.put(TF_WHO, currentUser);
        times.add(tA);

        Time__c tB = new Time__c(); 
        tB.put(TF_TASK, tService); 
        tB.put(TF_START, d0.addDays(4)); 
        tB.put(TF_END, d0.addDays(4));
        if(TF_NAME != null) tB.put(TF_NAME, 'Afternoon Session');
        if(TF_WHO != null)  tB.put(TF_WHO, currentUser);
        times.add(tB);
        
        insert times;
        System.debug('✅ Time__c created: ' + times.size());
    }
}catch(Exception e){
    System.debug('ℹ️ Time__c Error: ' + e.getMessage());
}

// ===== Expense__c =====
try{
    Map<String, Schema.SObjectField> exF = Schema.SObjectType.Expense__c.fields.getMap();
    String EF_TASK  = pickField(exF, new List<String>{ 'Task__c' });
    String EF_AMT   = pickField(exF, new List<String>{ 'Amount__c' });
    String EF_DATE  = pickField(exF, new List<String>{ 'DateIncurred__c' });

    if(EF_TASK != null && EF_AMT != null && EF_DATE != null){
        List<Expense__c> expenses = new List<Expense__c>();
        if(tService != null){
            Expense__c e1 = new Expense__c(); e1.put(EF_TASK, tService); e1.put(EF_AMT, 120000); e1.put(EF_DATE, d0.addDays(4)); expenses.add(e1);
        }
        if(tExport != null){
            Expense__c e2 = new Expense__c(); e2.put(EF_TASK, tExport);  e2.put(EF_AMT, 300000); e2.put(EF_DATE, d0.addDays(13)); expenses.add(e2);
        }
        if(!expenses.isEmpty()){
            insert expenses;
            System.debug('✅ Expense__c created: ' + expenses.size());
        }
    }
}catch(Exception e){
    System.debug('ℹ️ Expense__c Error: ' + e.getMessage());
}
