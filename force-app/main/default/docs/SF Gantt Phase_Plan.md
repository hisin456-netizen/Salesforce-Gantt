# Phase Plan: Salesforce DHTMLX Gantt Implementation

본 문서는 Salesforce 연계 간트차트 개발을 위한 단계별 실행 계획을 정의합니다. 모든 단계는 이전 단계의 완료를 전제로 진행됩니다.

---

## Phase 1: 기반 설정 및 스키마 구축 (Environment Setup)
**목표:** 데이터 모델링 완료 및 라이브러리 환경 구성
* **기간**: Day 1 ~ Day 2
* **주요 과업**:
    1. **객체 생성**: 7개 커스텀 객체(`Project__c`, `ProjectTask__c`, `Assignment__c`, `Dependency__c`, `TaskSegment__c`, `Time__c`, `Expense__c`) 및 필드 생성.
    2. **관계 설정**: `ParentTask__c` 자기 참조 룩업 및 각 객체 간 Master-Detail 관계 구축.
    3. **정적 자원**: DHTMLX Gantt 라이브러리를 `Static Resource`로 등록.
* **산출물**: Salesforce Object Schema, Static Resource.

---

## Phase 2: 백엔드 데이터 서비스 개발 (Apex Development)
**목표:** 간트차트와 Salesforce 간의 데이터 통신 브릿지 구축
* **기간**: Day 3 ~ Day 5
* **주요 과업**:
    1. **Data Model Wrapper**: DHTMLX가 요구하는 JSON 구조(`id`, `start_date`, `parent` 등)에 맞춘 Apex Wrapper 클래스 작성.
    2. **GanttDataService**: 프로젝트 ID를 기반으로 작업, 의존성, 할당 데이터를 한 번에 조회하는 비즈니스 로직 구현.
    3. **GanttController**: LWC에서 호출 가능한 `@AuraEnabled` 메서드(Load/Save) 구현.
    4. **Trigger Logic**: 하위 작업 변경 시 상위 작업의 날짜를 재계산하는 롤업 트리거 로직 작성.
* **산출물**: `GanttController.cls`, `GanttDataService.cls`, `ProjectTaskTrigger.trigger`.

---

## Phase 3: 프론트엔드 코어 구축 (LWC & UI)
**목표:** 간트차트 렌더링 및 기본 UI 기능 구현
* **기간**: Day 6 ~ Day 9
* **주요 과업**:
    1. **Library Mounting**: LWC `renderedCallback`을 통한 라이브러리 초기화 및 DOM 바인딩.
    2. **Data Mapping**: Apex에서 가져온 데이터를 간트 인스턴스에 로드.
    3. **Grid Configuration**: 좌측 테이블 컬럼(`Name`, `StartDate__c`, `Duration__c`) 설정 및 고정.
    4. **Styling**: `IsLeaf__c` 값에 따른 막대 색상(초록/파랑) 및 마일스톤(다이아몬드) 처리.
* **산출물**: `ganttChartContainer` (LWC Component).

---

## Phase 4: 편집 및 동기화 고도화 (Interactive Features)
**목표:** 실시간 데이터 편집 및 복잡한 비즈니스 로직 연동
* **기간**: Day 10 ~ Day 12
* **주요 과업**:
    1. **CRUD Synchronization**: 간트 내 생성/수정/삭제 이벤트를 감지하여 Salesforce에 즉시 반영.
    2. **Phantom ID 처리**: 저장 전 레코드에 가상 ID를 부여하고 저장 후 실제 DB ID로 치환하는 로직 구현.
    3. **Dependency Logic**: 작업 간 화살표 연결 및 의존성 타입(`Type__c`)에 따른 일정 자동 밀림 구현.
    4. **Resource UI**: `Assignment__c` 데이터를 활용하여 작업 담당자 시각화.
* **산출물**: 저장 로직이 포함된 LWC JS, 고도화된 Apex Handler.

---

## Phase 5: 부가 기능 및 안정화 (Finalization)
**목표:** 성능 최적화 및 최종 배포 준비
* **기간**: Day 13 ~ Day 15
* **주요 과업**:
    1. **Export Service**: PDF, Excel, MS Project 내보내기 기능 연동.
    2. **Performance Tuning**: 스마트 렌더링 적용으로 대량 데이터 처리 속도 개선.
    3. **Critical Path**: 임계 경로 계산 및 강조 로직 활성화.
    4. **Permission Set**: 관리자/사용자 권한별 편집 제한 테스트.
* **산출물**: 최종 패키지, 권한 세트, 사용자 가이드.

---

## 단계별 체크리스트 (Summary)
- [ ] 객체 필드 API 명칭이 요구사항 정의서와 일치하는가?
- [ ] 상위 작업(Summary Task) 수정 제한 로직이 반영되었는가?
- [ ] 의존성(Dependency) 연결 시 무한 루프 검증 로직이 있는가?
- [ ] Lightning App Builder에서 컴포넌트가 정상 노출되는가?