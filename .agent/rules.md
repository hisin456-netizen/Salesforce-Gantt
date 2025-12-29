# Project Rules

## Data Model & Schema Verification
- **CRITICAL**: Before writing any Apex, SOQL, or JavaScript that references Salesforce fields, **ALWAYS** check the actual existing metadata in `force-app/main/default/objects/`.
- Do NOT guess field names. Verify spelling (e.g., `Dependancy__c`) and field types.
- Check for required lookup filters or Master-Detail relationships (like `Project__c` on `Assignment__c`).

## Reference Documentation
- Prioritize context found in `force-app/main/default/docs/` for business logic, user roles, and workload planning.

## Naming Conventions
**(Derived from SF Gantt_Requirement.md - Strict Compliance Required)**

### 1. Objects & Fields
- **Custom Objects**: PascalCase. Prefixes: `HDC_` (General), `IF_` (Interface), `SM_` (Summary).
- **Fields**: CamelCase (e.g., `AccountType`).
  - **Checkbox**: Must start with `Is` (e.g., `IsActive__c`).
  - **Formula**: Must start with `FM_` (e.g., `FM_AccountType__c`).
  - **Picklist**: Use Global Picklist Value Sets where possible.

### 2. Apex
- **Classes**: PascalCase. Suffixes: `Controller`, `Handler`, `Batch`, `Test` (e.g., `EmployeeVacationHandler`).
- **Methods**: camelCase. Verb-Noun pattern (e.g., `sendEmail`, `getTodayDate`).
  - **Boolean Return**: `is...` (e.g., `isClosed`).
  - **Variables**: camelCase (e.g., `recordId`).
  - **Constants**: UPPER_SNAKE_CASE.

### 3. Frontend (LWC)
- **Component Name**: camelCase (e.g., `ganttChartContainer`).
- **Files**: PascalCase for Classes, camelCase for LWC bundles.

### 4. Automation (Flow)
- **API Name**: PascalCase.
- **Label**: Natural Text (Verb + Noun).

## Schema Map
![Schema Map](file:///C:/Users/%EC%A0%95%ED%9A%8C%EC%84%9D%EB%8C%80%EB%A6%AC/.gemini/antigravity/brain/15d17f30-b6dd-4bcc-b52e-1774126180dc/uploaded_image_1766972194901.png)
