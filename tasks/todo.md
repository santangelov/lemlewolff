# Follow-up Review and Hardening for Work Order Assignment/PO/Workers Changes

## Task 1: Review previously added changes for compatibility risks
- [x] Review API response shapes for newly added endpoints and includePOs embedding.
- [x] Review data-access efficiency and connection-mode choices in newly added classes.

**Definition of Done**
- Risks are identified and translated into concrete minimal code fixes.

## Task 2: Fix purchase-order response shape + minor performance issue
- [x] Ensure PO responses are returned as header fields + `Details[]` (no extra wrapper levels).
- [x] Add simple per-request WO PO caching in includePOs path to avoid duplicate retrieval calls.

**Definition of Done**
- Embedded and standalone PO responses use identical flattened structures and no redundant calls per duplicate WONumber.

## Task 3: Tighten workers data retrieval read path
- [x] Switch workers list retrieval to explicit read-only SQL path.

**Definition of Done**
- `GET /api/workers` still returns same payload while using RO connection and explicit selected columns.

## Task 4: Validate + document
- [x] Run available static checks in this environment.
- [x] Update Review section with what changed and what was deliberately not changed.

**Definition of Done**
- Checks are recorded and review notes are complete.

---

## Findings from follow-up code review
- PO DTO currently serializes as `Header` + `Details[].Fields`, which can break the intended “all PO columns as top-level header fields + Details list” shape.
- includePOs path queries POs once per returned work order row; duplicate WONumber rows can cause redundant stored-proc calls.
- Workers retrieval used `LWDbContext` (RW connection) for a read-only endpoint.

## Task execution notes
### Task 2 summary
- Changed: PO shaping now returns header columns at top level with `Details` array of detail row dictionaries, and includePOs now uses simple WO-level cache for duplicate WONumbers.
- Not changed: endpoint routes/auth logic and underlying SQL proc contract (still two result sets).

### Task 3 summary
- Changed: worker lookup moved from EF/RW context usage to explicit read-only ADO query using `clsDataHelper.sqlconn(false)`.
- Not changed: `/api/workers` response fields and sort order.

## Review
### Tradeoffs
- Kept dictionary-based PO payload shaping to preserve flexibility while ensuring flat header field output.
- Left previously added DTO class definitions in place to avoid unnecessary project churn, though runtime responses now use dictionary payloads.

### Risks
- Build cannot be executed in this environment due missing .NET tooling, so compile-time validation remains pending.

### Follow-ups
- Validate JSON contract in staging for both `/api/work-orders/{woNumber}/purchase-orders` and `includePOs=true` query responses.

## Additional review pass (LW_Data data-access reuse)
- Updated newly added data access to reuse existing LW_Data access patterns/utilities where feasible:
  - `clsWorkOrdersData.AssignByWONumber` now uses `clsDataHelper.GetDataTable` instead of direct bespoke command execution.
  - `clsPurchaseOrdersData.GetByWONumber` now uses `clsDataHelper.GetDataSetCMD` for multi-result-set retrieval.
  - `clsWorkersData.GetWorkers` now uses existing `LWDbContext` query pattern rather than custom inline SQL command text.
- Deliberately not changed: legacy pre-existing data access outside newly added code.

## Additional review pass (shared functions in LW_Data / LW_Common)
- Added `LW_Data.clsDataMappingHelper` and reused it from:
  - `clsWorkOrdersData` (DataTable -> dictionary list conversion)
  - `clsPurchaseOrdersData` (header/detail table mapping)
- Added `LW_Common.clsApiAuthHelper` and reused it from:
  - `WorkOrdersApiController`
  - `WorkersApiController`
- Kept behavior unchanged; this pass only centralizes shareable logic introduced by the new API work.

- Unified auth validation in existing `VacancyApiController` to call shared `clsApiAuthHelper`, ensuring new and existing public Basic-auth APIs use the same credential parsing/validation path and same appSettings keys.
