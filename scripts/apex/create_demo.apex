// ================================
// Salesforce DHTMLX Gantt Demo Data Seeder (Org-safe version)
// - Auto maps common field API names per object
// - Skips optional objects if required fields not found
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

// ---- Helper: set field if exists ----
void putIf(SObject s, Map<String, Schema.SObjectField> m, String fieldApi, Object val){
    if(fieldApi != null && m.containsKey(fieldApi)) s.put(fieldApi, val);
}

// 0) Demo Contacts (for Assignment__c)
Account acc = new Account(Name = 'Gantt Demo Account');
insert acc;

List<Contact> demoContacts = new List<Contact>{
    new Contact(LastName='정회석', AccountId=acc.Id),
    new Contact(LastName='박준기', AccountId=acc.Id),
    new Contact(LastName='장민석', AccountId=acc.Id),
    new Contact(LastName='김범우', AccountId=acc.Id)
};
insert demoContacts;

// 1) Project
Project__c prj = new Project__c();
prj.Name = 'SF DHTMLX Gantt Demo - ' + String.valueOf(Date.today());
insert prj;
System.debug('✅ Project created: ' + prj.Id);

// ---- 날짜 베이스 ----
Date d0 = Date.today();

// ===== Field mapping for ProjectTask__c =====
Map<String, Schema.SObjectField> pt = Schema.SObjectType.ProjectTask__c.fields.getMap();

String PT_PROJECT   = pickField(pt, new List<String>{ 'Project__c' });
String PT_PARENT    = pickField(pt, new List<String>{ 'ParentId__c', 'ParentTask__c' }); // 너 org는 ParentId__c 가능성 높음
String PT_START     = pickField(pt, new List<String>{ 'TaskStartDate__c', 'StartDate__c' }); // 너 org: TaskStartDate__c
String PT_DURATION  = pickField(pt, new List<String>{ 'Duration__c' });
String PT_PCTDONE   = pickField(pt, new List<String>{ 'PercentDone__c', 'Percent_Done__c' });
String PT_ISLEAF    = pickField(pt, new List<String>{ 'IsLeaf__c', 'IsLeaf' });

if (PT_PROJECT == null) {
    System.debug('❌ ProjectTask__c 에 Project lookup 필드(Project__c)가 없어서 중단');
    return;
}
if (PT_START == null) {
    System.debug('❌ ProjectTask__c 에 시작일 필드(TaskStartDate__c/StartDate__c)가 없어서 중단');
    return;
}
if (PT_DURATION == null) {
    System.debug('❌ ProjectTask__c 에 Duration__c가 없어서 중단');
    return;
}
if (PT_ISLEAF == null) {
    System.debug('❌ ProjectTask__c 에 IsLeaf__c가 없어서 중단');
    return;
}

// 2) Create Summary Tasks (Phase 1~5)
List<ProjectTask__c> phases = new List<ProjectTask__c>();

ProjectTask__c ph1 = new ProjectTask__c(Name='Phase 1: 기반 설정 및 스키마 구축');
putIf(ph1, pt, PT_PROJECT, prj.Id);
putIf(ph1, pt, PT_ISLEAF, false);
putIf(ph1, pt, PT_START, d0);
putIf(ph1, pt, PT_DURATION, 2);
putIf(ph1, pt, PT_PCTDONE, pct(40));
phases.add(ph1);

ProjectTask__c ph2 = new ProjectTask__c(Name='Phase 2: 백엔드 데이터 서비스 개발');
putIf(ph2, pt, PT_PROJECT, prj.Id);
putIf(ph2, pt, PT_ISLEAF, false);
putIf(ph2, pt, PT_START, d0.addDays(2));
putIf(ph2, pt, PT_DURATION, 3);
putIf(ph2, pt, PT_PCTDONE, pct(20));
phases.add(ph2);

ProjectTask__c ph3 = new ProjectTask__c(Name='Phase 3: 프론트엔드 코어 구축');
putIf(ph3, pt, PT_PROJECT, prj.Id);
putIf(ph3, pt, PT_ISLEAF, false);
putIf(ph3, pt, PT_START, d0.addDays(6));
putIf(ph3, pt, PT_DURATION, 4);
putIf(ph3, pt, PT_PCTDONE, pct(0));
phases.add(ph3);

ProjectTask__c ph4 = new ProjectTask__c(Name='Phase 4: 편집 및 동기화 고도화');
putIf(ph4, pt, PT_PROJECT, prj.Id);
putIf(ph4, pt, PT_ISLEAF, false);
putIf(ph4, pt, PT_START, d0.addDays(10));
putIf(ph4, pt, PT_DURATION, 3);
putIf(ph4, pt, PT_PCTDONE, pct(0));
phases.add(ph4);

ProjectTask__c ph5 = new ProjectTask__c(Name='Phase 5: 부가 기능 및 안정화');
putIf(ph5, pt, PT_PROJECT, prj.Id);
putIf(ph5, pt, PT_ISLEAF, false);
putIf(ph5, pt, PT_START, d0.addDays(13));
putIf(ph5, pt, PT_DURATION, 3);
putIf(ph5, pt, PT_PCTDONE, pct(0));
phases.add(ph5);

insert phases;

// 2.1) Leaf tasks
List<ProjectTask__c> leafTasks = new List<ProjectTask__c>();

ProjectTask__c leaf(String name, Id parentId, Date start, Integer dur, Integer percent){
    ProjectTask__c t = new ProjectTask__c(Name=name);
    putIf(t, pt, PT_PROJECT, prj.Id);
    putIf(t, pt, PT_ISLEAF, true);
    putIf(t, pt, PT_START, start);
    putIf(t, pt, PT_DURATION, dur);
    putIf(t, pt, PT_PCTDONE, pct(percent));
    if(PT_PARENT != null) t.put(PT_PARENT, parentId);
    return t;
}

leafTasks.add(leaf('객체/필드 생성 (7개 Custom Objects)', ph1.Id, d0, 1, 60));
leafTasks.add(leaf('관계 설정 (WBS/MD/Lookup)',            ph1.Id, d0.addDays(1), 1, 20));
leafTasks.add(leaf('정적 자원 등록 (DHTMLX Gantt)',         ph1.Id, d0.addDays(1), 1, 0));

ProjectTask__c tWrapper  = leaf('Wrapper 설계 (DHTMLX JSON 매핑)',      ph2.Id, d0.addDays(2), 1, 0);
ProjectTask__c tService  = leaf('GanttDataService 구현 (Load/Save)',     ph2.Id, d0.addDays(3), 1, 0);
ProjectTask__c tTrigger  = leaf('Trigger 로직 (요약작업 날짜 롤업)',      ph2.Id, d0.addDays(4), 1, 0);

ProjectTask__c tMount    = leaf('Library Mounting (renderedCallback)',   ph3.Id, d0.addDays(6), 1, 0);
ProjectTask__c tGrid     = leaf('Grid/컬럼 설정',                         ph3.Id, d0.addDays(7), 1, 0);
ProjectTask__c tStyle    = leaf('Styling (요약/일반/마일스톤)',           ph3.Id, d0.addDays(8), 2, 0);

ProjectTask__c tCrud     = leaf('CRUD Sync (간트 이벤트 → Salesforce)',   ph4.Id, d0.addDays(10), 1, 0);
ProjectTask__c tDepLogic = leaf('Dependency Logic (FS/SS/FF/SF)',         ph4.Id, d0.addDays(11), 1, 0);
ProjectTask__c tResource = leaf('Resource UI (Assignment 담당자 표시)',    ph4.Id, d0.addDays(12), 1, 0);

ProjectTask__c tExport   = leaf('Export (PDF/Excel/MS Project)',          ph5.Id, d0.addDays(13), 1, 0);
ProjectTask__c tPerf     = leaf('Performance (Smart Rendering)',          ph5.Id, d0.addDays(14), 1, 0);

// Milestone (Duration=0)
ProjectTask__c msGoLive  = leaf('Milestone: Go-Live',                     ph5.Id, d0.addDays(15), 0, 0);

leafTasks.addAll(new List<ProjectTask__c>{
    tWrapper, tService, tTrigger,
    tMount, tGrid, tStyle,
    tCrud, tDepLogic, tResource,
    tExport, tPerf, msGoLive
});

insert leafTasks;

// ===== Dependancy__c (optional) =====
try{
    Map<String, Schema.SObjectField> depF = Schema.SObjectType.Dependancy__c.fields.getMap();
    String DF_FROM = pickField(depF, new List<String>{ 'TaskFrom__c', 'TaskForm__c' }); // 오타 대비
    String DF_TO   = pickField(depF, new List<String>{ 'TaskTo__c' });
    String DF_TYPE = pickField(depF, new List<String>{ 'Type__c' });

    if(DF_FROM != null && DF_TO != null && DF_TYPE != null){
        List<Dependancy__c> deps = new List<Dependancy__c>();
        Dependancy__c d1 = new Dependancy__c();
        d1.put(DF_FROM, tWrapper.Id);
        d1.put(DF_TO,   tService.Id);
        d1.put(DF_TYPE, 0);
        deps.add(d1);

        Dependancy__c d2 = new Dependancy__c();
        d2.put(DF_FROM, tService.Id);
        d2.put(DF_TO,   tTrigger.Id);
        d2.put(DF_TYPE, 0);
        deps.add(d2);

        Dependancy__c d3 = new Dependancy__c();
        d3.put(DF_FROM, tCrud.Id);
        d3.put(DF_TO,   tDepLogic.Id);
        d3.put(DF_TYPE, 0);
        deps.add(d3);

        insert deps;
        System.debug('✅ Dependancy__c created: ' + deps.size());
    } else {
        System.debug('ℹ️ Dependancy__c 스킵: 필드 매핑 실패 (From/To/Type 확인 필요)');
    }
}catch(Exception e){
    System.debug('ℹ️ Dependancy__c 생성 스킵: ' + e.getMessage());
}

// ===== Assignment__c (optional) =====
try{
    Map<String, Schema.SObjectField> asF = Schema.SObjectType.Assignment__c.fields.getMap();
    String AF_TASK   = pickField(asF, new List<String>{ 'ProjectTask__c', 'Task__c' });
    String AF_USER   = pickField(asF, new List<String>{ 'AssignedTo__c', 'Assignee__c' });
    String AF_UNITS  = pickField(asF, new List<String>{ 'Units__c', 'Unit__c' });

    if(AF_TASK != null && AF_USER != null){
        List<Assignment__c> assigns = new List<Assignment__c>();

        Assignment__c a1 = new Assignment__c();
        a1.put(AF_TASK, tService.Id);
        a1.put(AF_USER, demoContacts[0].Id);
        if(AF_UNITS != null) a1.put(AF_UNITS, 1);
        assigns.add(a1);

        Assignment__c a2 = new Assignment__c();
        a2.put(AF_TASK, tMount.Id);
        a2.put(AF_USER, demoContacts[1].Id);
        if(AF_UNITS != null) a2.put(AF_UNITS, 1);
        assigns.add(a2);

        insert assigns;
        System.debug('✅ Assignment__c created: ' + assigns.size());
    } else {
        System.debug('ℹ️ Assignment__c 스킵: 필드 매핑 실패 (Task/AssignedTo 확인 필요)');
    }
}catch(Exception e){
    System.debug('ℹ️ Assignment__c 생성 스킵: ' + e.getMessage());
}

// ===== Time__c (optional) =====
try{
    Map<String, Schema.SObjectField> tmF = Schema.SObjectType.Time__c.fields.getMap();
    String TF_TASK = pickField(tmF, new List<String>{ 'ProjectTask__c', 'Task__c' });
    String TF_DATE = pickField(tmF, new List<String>{ 'WorkDate__c', 'Date__c', 'Work_Date__c' });
    String TF_HRS  = pickField(tmF, new List<String>{ 'Hours__c', 'Hour__c' });

    if(TF_TASK != null && TF_DATE != null && TF_HRS != null){
        List<Time__c> times = new List<Time__c>();
        Time__c tA = new Time__c(); tA.put(TF_TASK, tService.Id); tA.put(TF_DATE, d0.addDays(3)); tA.put(TF_HRS, 6); times.add(tA);
        Time__c tB = new Time__c(); tB.put(TF_TASK, tService.Id); tB.put(TF_DATE, d0.addDays(4)); tB.put(TF_HRS, 5); times.add(tB);
        insert times;
        System.debug('✅ Time__c created: ' + times.size());
    } else {
        System.debug('ℹ️ Time__c 스킵: 필드 매핑 실패 (Task/WorkDate/Hours 확인 필요)');
    }
}catch(Exception e){
    System.debug('ℹ️ Time__c 생성 스킵: ' + e.getMessage());
}

// ===== Expense__c (optional) =====
try{
    Map<String, Schema.SObjectField> exF = Schema.SObjectType.Expense__c.fields.getMap();
    String EF_TASK  = pickField(exF, new List<String>{ 'ProjectTask__c', 'Task__c' });
    String EF_AMT   = pickField(exF, new List<String>{ 'Amount__c', 'Cost__c' });
    String EF_DATE  = pickField(exF, new List<String>{ 'ExpenseDate__c', 'Date__c' });

    if(EF_TASK != null && EF_AMT != null && EF_DATE != null){
        List<Expense__c> expenses = new List<Expense__c>();
        Expense__c e1 = new Expense__c(); e1.put(EF_TASK, tService.Id); e1.put(EF_AMT, 120000); e1.put(EF_DATE, d0.addDays(4)); expenses.add(e1);
        Expense__c e2 = new Expense__c(); e2.put(EF_TASK, tExport.Id);  e2.put(EF_AMT, 300000); e2.put(EF_DATE, d0.addDays(13)); expenses.add(e2);
        insert expenses;
        System.debug('✅ Expense__c created: ' + expenses.size());
    } else {
        System.debug('ℹ️ Expense__c 스킵: 필드 매핑 실패 (Task/Amount/Date 확인 필요)');
    }
}catch(Exception e){
    System.debug('ℹ️ Expense__c 생성 스킵: ' + e.getMessage());
}

// ===== TaskSegment__c (optional) =====
try{
    Map<String, Schema.SObjectField> sgF = Schema.SObjectType.TaskSegment__c.fields.getMap();
    String SF_TASK  = pickField(sgF, new List<String>{ 'ProjectTask__c', 'Task__c' });
    String SF_S     = pickField(sgF, new List<String>{ 'StartDate__c', 'SegmentStart__c' });
    String SF_E     = pickField(sgF, new List<String>{ 'EndDate__c', 'SegmentEnd__c' });

    if(SF_TASK != null && SF_S != null && SF_E != null){
        List<TaskSegment__c> segs = new List<TaskSegment__c>();
        TaskSegment__c s1 = new TaskSegment__c(); s1.put(SF_TASK, tStyle.Id); s1.put(SF_S, d0.addDays(8));  s1.put(SF_E, d0.addDays(9));  segs.add(s1);
        TaskSegment__c s2 = new TaskSegment__c(); s2.put(SF_TASK, tStyle.Id); s2.put(SF_S, d0.addDays(10)); s2.put(SF_E, d0.addDays(11)); segs.add(s2);
        insert segs;
        System.debug('✅ TaskSegment__c created: ' + segs.size());
    } else {
        System.debug('ℹ️ TaskSegment__c 스킵: 필드 매핑 실패 (Task/Start/End 확인 필요)');
    }
}catch(Exception e){
    System.debug('ℹ️ TaskSegment__c 생성 스킵: ' + e.getMessage());
}

System.debug('✅ Demo Seed Done. ProjectId=' + prj.Id);
