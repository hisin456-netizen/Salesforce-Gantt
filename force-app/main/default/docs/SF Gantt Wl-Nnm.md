# Work Load Plan: Salesforce DHTMLX Gantt Project

본 문서는 개발 팀원 4명의 역할 분담 및 단계별 업무 배분(Work Load)을 정의합니다. 모든 개발자는 Junior 개발자로서 상호 협력하며 담당 영역의 품질을 책임집니다.

---

## 1. 개발 팀 구성 및 역할 (Team Roles)

| 성명 | 주요 역할 | 상세 담당 범위 |
| :--- | :--- | :--- |
| **정회석** | **Backend & Data Service** | Apex Controller/Service 설계, 데이터 Load/Save 인터페이스, 트리거 로직 |
| **박준기** | **Frontend & Gantt Core** | LWC 구성 및 라이브러리 연동, 차트 렌더링 엔진, 그리드/스타일링 설정 |
| **장민석** | **Business Logic & Engine** | Dependency(의존성) 로직, Auto-scheduling, Milestone 및 Task 분할 |
| **김범우** | **Resource & Extension** | Assignment(리소스) 연동, 시간/비용(Time/Expense) 집계, Export 기능 |

---

## 2. 개발 단계별 상세 업무 (Task Allocation)

### Phase 1: 스키마 및 환경 설정 (Day 1-2)
* **공통**: 각자 담당 객체의 필드 API 명칭 검증 및 데이터 무결성 체크
* **정회석**: 프로젝트 전체 데이터 모델(ERD) 검토 및 권한 세트 설계
* **박준기**: DHTMLX 라이브러리 Static Resource 등록 및 LWC 스켈레톤 코드 작성

### Phase 2: 데이터 연동 및 기반 구축 (Day 3-6)
* **정회석**: `GanttDataService.cls` 개발 (JSON 모델 생성 및 SOQL 최적화)
* **박준기**: LWC `renderedCallback` 차트 초기화 및 Apex 데이터 바인딩
* **장민석**: `Dependency__c` 기반의 의존성 데이터 맵핑 및 렌더링 기초 구현
* **김범우**: `Assignment__c` 리소스 데이터 필터링 및 리소스 차트 베이스 구축

### Phase 3: 기능 고도화 및 이벤트 연동 (Day 7-11)
* **정회석**: `PhantomId` 기반의 실시간 Upsert 처리 및 저장 트랜잭션 관리
* **박준기**: 간트 바 드래그/리사이징 이벤트 핸들링 및 UI 실시간 반영
* **장민석**: 의존성 타입(FS/SS/FF/SF)별 일정 재계산 및 임계 경로(Critical Path) 로직
* **김범우**: 리소스별 부하량 계산 및 작업별 투입 실적(Time/Expense) 툴팁 연동

### Phase 4: 안정화 및 산출물 작성 (Day 12-15)
* **정회석**: Bulk Data 대응 성능 튜닝 및 Apex 예외 처리(Error Handling)
* **박준기**: Zoom Level(Day/Week/Month) UI 개선 및 전체 테마/CSS 조정
* **장민석**: 요약 작업(Summary Task)의 자동 일정 갱신 로직 최종 검증
* **김범우**: 내보내기(Export) API 연동 및 사용자 매뉴얼(Manual) 작성

---

## 3. 협업 규칙 (Collaboration Rules)
1. **Source Control**: 기능별 브랜치(`feature/name-task`) 운영 및 Pull Request를 통한 교차 코드 리뷰.
2. **Naming Convention**: 요구사항 정의서(`SF Gantt_Requirement.md`)의 API 명칭 및 camelCase/PascalCase 규칙 준수.
3. **Communication**: 매일 오전 짧은 데일리 스크럼을 통해 진행 상황 및 기술적 블로킹 포인트 공유.

---

## 4. 업무 로드 요약 (Workload Summary)
* **정회석**: 서버 안정성 및 데이터 정합성 (25%)
* **박준기**: 사용자 인터페이스 핵심 엔진 및 UI (25%)
* **장민석**: 복잡한 일정 계산 규칙 및 의존성 엔진 (25%)
* **김범우**: 리소스 활용 및 부가 편의 기능 (25%)