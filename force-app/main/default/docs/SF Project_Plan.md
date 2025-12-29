# Project Plan: Salesforce DHTMLX Gantt Chart Implementation

## 1. 프로젝트 개요 (Project Overview)
* **목표**: Salesforce 내 커스텀 객체(`Project__c`, `ProjectTask__c` 등) 데이터를 DHTMLX Gantt 라이브러리와 연동하여 고도화된 일정 관리 솔루션 구축.
* **핵심 기능**: WBS 계층 구조 시각화, 드래그 앤 드롭 일정 편집, 의존성(Dependency) 및 리소스(Assignment) 관리.

---

## 2. 기술 스택 (Technical Stack)
* **Platform**: Salesforce Lightning Experience
* **Frontend**: Lightning Web Components (LWC)
* **Library**: DHTMLX Gantt Chart (Static Resource)
* **Backend**: Apex (Controller, Service, Trigger)
* **Data Format**: JSON (Gantt-friendly structure)

---

## 3. 상세 이행 계획 (Implementation Phases)

### Phase 1: 스키마 및 환경 설정 (Setup)
* **Custom Objects**: `Project__c`, `ProjectTask__c`, `Assignment__c`, `Dependency__c`, `TaskSegment__c`, `Time__c`, `Expense__c` 생성 및 필드 구성.
* **Relationship**: Master-Detail 및 Lookup 관계 설정 (특히 `ProjectTask__c`의 자기 참조 Lookup `ParentTask__c` 설정).
* **Static Resource**: DHTMLX Gantt 라이브러리 파일 업로드.

### Phase 2: 백엔드 개발 (Apex & Logic)
* **GanttDataService.cls**: 간트차트 전용 JSON 모델을 생성하기 위한 데이터 변환 클래스 개발.
* **GanttController.cls**: LWC와 통신하여 데이터를 Load/Save 하는 인터페이스 구현.
* **Trigger (ProjectTaskTrigger)**: 
    * 하위 작업 변경 시 상위 요약 작업(Summary Task)의 날짜 자동 업데이트.
    * `IsLeaf__c` 여부에 따른 데이터 검증 로직 구현.

### Phase 3: 프론트엔드 개발 (LWC)
* **ganttContainer**: DHTMLX Gantt 초기화 및 라이브러리 마운트.
* **Mapping Logic**: Salesforce API 필드를 간트 속성(`id`, `text`, `start_date`, `duration` 등)으로 매핑.
* **UI Customization**: 
    * 요약 작업(초록색), 일반 작업(파란색) 색상 구분 렌더링.
    * 좌측 고정 테이블(Task Name, Start Date 등) 구성.
    * Zoom 레벨(Day/Week/Month) 전환 기능.

### Phase 4: 데이터 동기화 및 고급 기능
* **Data Processor**: 편집 모드에서 변경된 일정을 `PhantomId__c`를 통해 식별하고 Salesforce에 실시간 반영.
* **Dependency**: `Dependency__c` 객체를 연동하여 선/후행 관계 시각화 및 자동 일정 조정 로직 활성화.
* **Advanced**: 임계 경로(Critical Path) 표시 및 PDF/Excel 내보내기 연동.

---

## 4. 데이터 매핑 정의 (Core Mapping)

| DHTMLX Property | Salesforce API Field | Description |
| :--- | :--- | :--- |
| **id** | `Id` / `PhantomId__c` | 유니크 레코드 식별자 |
| **text** | `Name` | 작업 명칭 |
| **start_date** | `StartDate__c` | 작업 시작 일시 |
| **end_date** | `TaskEndDate__c` | 작업 종료 일시 |
| **duration** | `Duration__c` | 소요 기간 (`DurationUnit__c` 참조) |
| **parent** | `ParentTask__c` | WBS 트리 계층 구조 |
| **progress** | `PercentDone__c` | 진행률 (0~100%) |

---

## 5. 예상 일정 (Timeline Estimate)

1.  **객체 및 보안 설정**: 1-2일
2.  **Apex 데이터 서비스 개발**: 2-3일
3.  **LWC 기본 차트 렌더링**: 3-4일
4.  **편집/저장 및 동기화 로직**: 3-4일
5.  **의존성/리소스 고도화**: 2-3일
6.  **QA 및 배포**: 3일

---

## 6. 주의 사항 및 제약 (Rules)
* **거버너 제한**: 대량 데이터 로드 시 Apex의 Heap Size 및 SOQL 제한을 고려하여 데이터 호출 최적화.
* **편집 권한**: `Permission Set`을 통해 일반 사용자는 조회만 가능하도록 제어.
* **데이터 정합성**: 요약 작업의 날짜는 반드시 하위 작업에 의해 결정되도록 Apex Trigger에서 강제함.