#project-overview (프로젝트 개요)
Salesforce 오그에 DHTMLX Gantt 차트 라이브러리를 이용하여 Lightning 앱 내에 간트차트를 배포하며, 커스텀 객체(Project__c, ProjectTask__c 등)와 실시간으로 데이터를 연계한다.

#feature-requirements (기능 요구사항)
1. 화면 구조 및 UI
Salesforce Lightning 페이지 내에서 간트 차트 화면을 표시한다.

작업 목록을 좌측 테이블 형태로 표시하며, 스크롤은 간트 영역과 동기화된다.

작업명(Name) 컬럼은 좌측 고정 컬럼으로 유지된다.

사용자는 테이블/간트 영역 비율을 드래그로 조정할 수 있다.

상위 작업 기준으로 하위 작업을 접고 펼칠 수 있는 트리 구조를 제공한다.

2. WBS 및 작업 관리 (ProjectTask__c 연계)
작업은 상위/하위 관계(WBS 구조)로 표시되며, ParentTask__c 필드를 참조하여 계층을 구성한다.

요약 작업(Summary Task): IsLeaf__c가 False인 레코드로 정의되며, 초록색 막대로 표시된다. 기간은 하위 작업의 최소 시작일(StartDate__c)~최대 종료일(TaskEndDate__c)을 기준으로 자동 계산된다.

일반 작업(Task): IsLeaf__c가 True인 레코드로 정의되며, 파란색 막대로 표시된다.

요약 작업은 직접 일정 편집이 불가능하며, 하위 작업 변경 시 Salesforce의 롤업 또는 간트 로직에 의해 자동 갱신된다.

마일스톤: Duration__c가 0인 작업은 다이아몬드(◆) 형태로 표시된다.

3. 데이터 매핑 및 연동 (Object Setup)
Salesforce 커스텀 오브젝트의 데이터를 DHTMLX 간트 구조로 다음과 같이 매핑한다:

Task ID: Id (신규 생성 시 PhantomId__c 사용)

Text: Name (작업명)

Start Date: StartDate__c

End Date: TaskEndDate__c

Duration: Duration__c (단위는 DurationUnit__c 참조)

Parent: ParentTask__c

Progress: PercentDone__c

좌측 테이블에는 Name, StartDate__c, Duration__c, Predecessors 컬럼이 기본 제공된다.

Duration__c는 StartDate__c와 TaskEndDate__c를 기준으로 자동 계산된다.

4. 일정 및 시간 관리
사용자는 Day / Week / Month / Quarter 단위로 시간 스케일(Zoom)을 전환할 수 있다.

전체 작업이 화면에 맞도록 자동 확대/축소(Fit to Screen)할 수 있다.

분할 작업(Split Task): 작업 중간에 공백이 필요한 경우 TaskSegment__c 객체 데이터를 기반으로 분할된 바를 렌더링한다.

5. 의존성 및 제약 조건 (Dependency__c 연계)
작업 간 선행/후행 관계는 Dependency__c 객체를 통해 화살표로 시각화된다.

Finish-Start(0), Start-Start(1), Finish-Finish(2), Start-Finish(3) 타입을 Type__c 필드 값에 따라 지원한다.

선행 작업 정보는 TaskFrom__c를 참조하여 좌측 테이블에 표시된다.

의존성 기반 일정 재계산 시 Lag__c와 LagUnit__c를 고려한다.

작업 제약 사항은 ConstraintType__c 및 ConstraintDate__c 필드 설정을 따른다.

6. 리소스 및 비용 관리 (Assignment, Time, Expense 연계)
리소스: Assignment__c를 통해 할당된 AssignedTo__c(Contact) 정보를 작업 바에 표시한다. 투입량은 Units__c를 참조한다.

시간/비용: 작업별 투입된 실제 시간(Time__c) 및 발생 비용(Expense__c) 정보를 툴팁 또는 상세 패널에서 조회할 수 있다.

7. 편집 및 권한
기본적으로 간트 차트는 조회 전용 모드로 제공되며, 특정 권한 세트(Permission Sets) 보유자만 편집 모드를 활성화할 수 있다.

편집 모드에서 수정된 일정은 Apex Controller를 통해 Salesforce 레코드에 저장된다. DML 실패 시 변경 사항은 Rollback(취소)된다.

신규 작업 생성 시 임시 식별자로 PhantomId__c를 부여하고, 서버 저장 성공 후 공식 Id로 교체한다.

편집 모드에서 작업 변경에 대해 Undo / Redo를 지원한다.

8. 고급 기능 및 성능
대량 작업 조회 시 렌더링 최적화(Smart Rendering)를 적용한다.

필수 값 누락 시 간트 표시 대신 안내 메시지를 출력한다.

프로젝트의 임계 경로(Critical Path)를 시각적으로 강조 표시한다.

간트 차트를 PDF, PNG, Excel, MS Project 형식으로 내보낼 수 있다.

관리자 설정 페이지를 통해 부가 기능의 노출 여부를 제어한다.

#relevant-codes (관련 코드)
(현재 비어 있음 - 개발 진행 시 Apex Controller 및 LWC JS 로직 추가 예정)

#Current-file-instruction (현재 파일 구조)
force-app/ └─ main/ └─ default/ ├─ classes/ # GanttDataController.cls 등 ├─ triggers/ # ProjectTaskTrigger.trigger 등 ├─ lwc/ # ganttChartContainer (DHTMLX 래퍼) ├─ objects/ # Project__c, ProjectTask__c, Dependency__c 등 ├─ layouts/ # 관련 객체 페이지 레이아웃 └─ permissionsets/ # Gantt_Admin, Gantt_User 권한 세트

#rules (규칙)
모든 데이터 조회 및 저장은 Salesforce 권한 모델(FLS/CRUD)을 준수해야 한다.

DHTMLX 라이브러리는 Static Resource를 통해 로드하며, LWC의 renderedCallback에서 초기화한다.

명명 규칙
PascalCase를 사용하여 개체명 작성.
예: HDC_Account
필드 라벨(Label): Country Code
필드 이름(API Name): CountryCode (Salesforce는 라벨에 띄어쓰기가 있으면 자동으로 밑줄을 제거함).
예: Country_Code → CountryCode
접두어 규칙
HDC_: 일반 업무와 관련된 Custom Object에 사용.
예: HDC_Account
IF_: Interface 관련 Custom Object에 사용하며, 중간에 대상 시스템명을 포함.
예: IF_ERP_Account
SM_: Summary 관련 Custom Object에 사용.
예: SM_MonthlyOpportunity
라벨 접두어 규칙
[HDC]: 일반 업무용
[IF]: Interface 용
[SM]: Summary 용
예시:
[HDC] 고객정보
[IF] ERP 고객정보
[SM] 월별 영업기회
일반 규칙
접두어 외 나머지 개체명은 CamelCase 사용.
예: HDC_AccountHistory
**설명(Description)**은 반드시 작성하며, 한글로 입력.
Fields
필드 명명 규칙
Formula 타입 필드: FM_ 접두어 사용.
예: FM_AccountType
Checkbox 타입 필드: Is 접두어 사용.
예: IsActive
그 외 필드명은 CamelCase로 작성.
예: AccountType
Picklist 관련
Picklist Value Sets를 사용하여 값 관리.
필드 타입별 예시
일반: AccountName__c
날짜: CreatedDate__c
날짜/시간: CreatedDatetime__c
시간: CheckoutTime__c
수량: ProductCnt__c
금액: SalesAmt__c
백분율: TotalRate__c
체크박스: IsActive__c
수식: FM_AccountType__c
자동번호: AI_BoardId__c
2. APEX
Apex Class
명명 규칙
형식: PascalCase | <네임스페이스>_<클래스명><선택 접미사>
예시:
일반 클래스: DKSRM_EmployeeVacationController
고객 채널 클래스: DE_EmployeeController
유틸리티 클래스: UTIL_Email
인터페이스 클래스: AccountIterable, AccountCloneable
접미사 예시
일반 접미사: Controller, Extension, Handler, Batch, Job, Queue
예: EmployeeVacationHandler
Apex Test Class
명명 규칙
형식: <Apex 클래스 이름>_Test
예: DKSRM_EmployeeVacationController_Test
Apex Methods
명명 규칙
형식: <동사><(선택적) 명사> (camelCase)
규칙:
첫 글자는 소문자로 시작.
밑줄(_) 사용 금지.
최대 길이는 255자
return 타입이 없으면 void 사용
예: sendEmail, updateAccount
Return 타입별 명명 규칙
Boolean: is로 시작.

public Boolean isClosed() {
    Boolean resultVal = false;
    return resultVal;
}
String: get + [Value명] 형태로 사용.

public String getId() {
    String resultVal = '';
    return resultVal;
}
Integer 또는 Decimal: get + [Object] + [Cnt | Amt | Order | Sum] 형태로 사용.

public Integer getNextOrder() {
    Integer resultVal = 0;
    return resultVal;
}
Date: get + [Object] + Date 형태로 사용.

public Date getTodayDate() {
    Date resultVal = new Date();
    return resultVal;
}
Time: get + [Object] + Time 형태로 사용.

public Time getCurrentTime() {
    Time resultVal = new Time();
    return resultVal;
}
DateTime: get + [Object] + Datime 형태로 사용.

public DateTime getCurrentDatime() {
    DateTime resultVal = new DateTime();
    return resultVal;
}
Map: get + [Object] + Map 형태로 사용.

public Map<String, Object> getUserMap(String userId) {
    Map<String, Object> resultMap = new Map<String, Object>();
    return resultMap;
}
Wrapper Class 또는 Object: get + [Object] + Detail 형태로 사용.

public User getUserDetail(String userId) {
    User resultClass = new User();
    return resultClass;
}
List 또는 Array: get + [Object] + List 형태로 사용.

public List<Map<String, Object>> getUserList() {
    List<Map<String, Object>> resultList = new List<Map<String, Object>>();
    return resultList;
}
Set: get + [Object] + Set 형태로 사용.

public Set<String> getUserSet() {
    Set<String> resultSet = new Set<String>();
    return resultSet;
}
Return 관련 변수명: result + [List | Map | Class | Val] 형태로 사용.

public List<User> getUserList() {
    List<User> resultList = new List<User>();
    return resultList;
}
Apex Variables
명명 규칙
짧지만 의미 있는 이름을 사용하며, camelCase 사용.
예: parentAccount, recordId
Apex Constants
명명 규칙
상수는 SNAKE_CASE로 작성.
동사종류
Label	Name	Example
등록	insert 	insertAccount
수정 	update	updateAccount
등록 또는 수정	upsert	save
삭제	delete	deleteAccount
전송	send	sendEmail
업로드	upload	uploadFile
다운로드	download	downloadFile
가져오기	get	getDetail
세팅하기	set	setDetail
실행	run	runBatch
확인	confirm	confirmApproval
체크	check	checkApproval
여부	is	isUsed  
3. PLATFORM
Platform Event
명명 규칙
형식: PascalCase | <액션> <대상> Event
예: New Order Event
Platform Cache
명명 규칙
형식: PascalCase | <짧지만 의미 있는 이름>Cache
예: EmployeeInfoCache
4. RULES
Validation Rule
명명 규칙
형식: Natural Text | <필드><규칙명>
예: Street Address < 60 chars
5. APPROVAL
Approval Process
명명 규칙
형식: Natural Text | <프로세스 시작 조건>
예: Submit Vacation Record
Approval Process Step
명명 규칙
형식: Natural Text | <결정 결과> - <짧은 설명>
예: Auto Approved - 100만원 이상 결재
6. Buttons, Links and Actions
Actions
명명 규칙
형식: PascalCase | <동사> <Action명>
예: Send Contract
7. FRONT-END
Lightning App
명명 규칙: PascalCase | <네임스페이스>_<App 명>App
설명:
네임스페이스: 선택적으로 사용.
App 명: 앱의 기능을 명확히 설명하는 명사로 작성.
예시: DKSRM_AccountManagementApp
Lightning Component
명명 규칙: PascalCase | <네임스페이스>_<Component 명>Cmp
설명:
네임스페이스: 선택적으로 사용.
Component 명: 구성 요소의 기능적 목적을 설명하며 줄임말, 약어 사용 금지.
예시: DKSRM_AccountLookupCmp
Lightning Web Component
명명 규칙: camelCase | <네임스페이스><Component 명>
설명:
네임스페이스: 선택적으로 사용.
Component 명: 기능적 목적을 설명하며 줄임말, 약어 사용 금지.
예시:
DKSRMAccountLookupCmp
CommFileUploadcmp (공통 LWC)
VisualForce Page
명명 규칙: PascalCase | <네임스페이스>_<페이지명>
예시: DKSRM_BundleConfigurations
Lightning Event
명명 규칙: PascalCase | <네임스페이스>_<Component 명>Evt
설명:
네임스페이스: 선택적으로 사용.
Class 명: 동작을 설명하는 과거형 동사로 작성.
예시: DKSRM_AccountSelectedEvt
Lightning Message Channel
명명 규칙: camelCase | <네임스페이스>_<MessageChannel 명>MsgCh
설명:
네임스페이스: 선택적으로 사용.
Class 명: 동작을 설명하는 과거형 동사로 작성.
예시: DKSRM_AccountSelectedMsgChd
Lightning Page
명명 규칙: PascalCase | <네임스페이스>_<Page Type>_Page
설명:
네임스페이스: 선택적으로 사용.
Page Type명: 해당하는 Page Type 작성.
예시1: Invoice_Record_Page
예시2: Evaluation_Home_Page
8. FLOW
Flow Screen Component
명명 규칙: PascalCase | <관련 화면 약어>_<Component 설명>
설명:
관련 화면 약어(옵션): 플로우에 여러 화면이 있을 경우 사용.
Component 설명: 간결하고 명확하게 작성, 줄임말/약어 사용 금지.
예시: Get Record Type ID
Flow Resource
명명 규칙: camelCase | <짧은 의미있는 명사>
설명:
한 글자 변수 이름 사용 금지.
간결하고 명확하게 작성.
Collection 변수는 복수형으로 작성 (e.g., childContacts).
예시: parentAccountId
Flow
Label 규칙: Natural Text
API 명 규칙: PascalCase
API 명 주의사항: API명은 프로젝트별로 일관성있게 _를 사용하거나, Space를 제거하는 두가지의 방식 중 선택.
플로우 유형별 명명 규칙
Screen Flow:
Label: <동사> <짧은 프로세스 설명> / Reschedule Order Delivery
API( _ 사용): <네임스페이스>_<Flow명> / Reschedule_Order_Delivery
API(Space 제거): <네임스페이스><Flow명> / RescheduleOrderDelivery
Autolaunched Flow:
Label: <동사> <짧은 프로세스 설명> / Add Default Opportunity Team Members
API( _ 사용): <동사>_<선택적 명사 대상> / Add_Default_Opportunity_Team_Members
API(Space 제거): <동사><선택적 명사 대상> / AddDefaultOpportunityTeamMembers
Flow Trigger:
Label: <개체명> <작업 시작 유형> <짧은 설명> / Case Before Handler
API( _ 사용): <개체 API명>_<작업 시작 유형>_<Flow Trigger명> / Case_Before_Handler
API(Space 제거): <개체 API명><작업 시작 유형><Flow Trigger명> / CaseBeforeHandler
Scheduled Flow:
Label: <동사> <짧은 프로세스 설명> / Remind Opportunity Owners
API( _ 사용): <개체 API명>_<SCH>_<Flow Scheduled명> / Remind_Opportunity_Owners
API(Space 제거): <개체 API명><SCH><Flow Scheduled명> / RemindOpportunityOwners
작업 시작 유형(Operation Type)
Before: Field Fast Record (필드 빠른 업데이트)
After: Action and Related Records (액션 및 관련 레코드)
Flow Element
Label 규칙: Natural Text
API 명 규칙: PascalCase
Element 유형별 명명 규칙
레코드 가져오기(Get Records):
Label: Get <(선택적) 형용사> <개체명> / Get Related Contacts
API: Get_<형용사>_<개체명> / Get_RelatedContacts
레코드 만들기(Create Records):
Label: Create <(선택적) 형용사> <개체명> / Create Account
API: Create_<형용사>_<개체명> / Create_Account
레코드 업데이트(Update Records):
Label: Update <(선택적) 형용사> <개체명> / Update Opportunity
API: Update_<형용사>_<개체명> / Update_Opportunity
레코드 삭제(Delete Records):
Label: Delete <(선택적) 형용사> <개체명> / Delete Opportunity Products
API: Delete_<형용사>_<개체명> / Delete_OpportunityProducts
롤백 레코드(Rollback Records):
Label: Rollback <(선택적) 형용사> <짧은 설명> / Rollback Error Transaction
API: Rollback_<형용사>_<짧은 설명> / Rollback_ErrorTransaction
화면(Screen):
Label: <동사> <짧은 설명> / Collect Contact Details
API: <동사>_<짧은 설명> / Collect_Contact_Details
서브플로/작업(Subflow/Action):
Label: 서브플로/작업의 참조 레이블과 API명 또는 짧은 설명 / Get Record Type ID
API: /Get_Record_Type_ID
9. 라벨 명명 규칙
라벨(Label) 작성 규칙
라벨 작성 시 다음 항목을 반드시 포함:
Short Description: 라벨의 간단한 설명. 영어로 입력할 경우 동일하게 사용.
Name (API Name): <Object>_<의미 있는 명사>
Category: <개체명>, <단위 기능명>
Description: 필수 작성. 짧고 의미 있게 설명.
Value: <라벨 값> (라벨의 실제 표시 값)
예시
항목	내용
Short Description	Record Type의 ID 가져오기
Name (API Name)	RecordType_GetID
Category	Record Type
Description	레코드 타입의 ID를 조회
Value	Get Record Type ID