# Arrears “Daily As-Of” Project Plan (Phase 0 discovery)

## Scope & constraints
- **Production-sensitive**: minimal-touch, reuse-first, no refactors unless required.
- **Phase 0 only**: discovery + plan; no implementation.
- **Reporting** must ultimately query **persistent snapshot table** (never staging), but Phase 0 is read-only.

---

## Phase plan (Phases 1–9) with DoD

### Phase 1 — Yardi Export #10 (Daily + Closed Month-Ends) ✅ DONE
1. **Update file #10 export SQL** to return: last 10 daily dates (ending @AsOfEnd) + last 3 closed month-ends (EOMONTH(GETDATE(),-1), -2, -3).
   - DoD: export output includes required dates/columns; **HAP filtering identical** to legacy.
2. **Add commented diagnostics** in export SQL (total rows, distinct tenants, per-date counts).
   - DoD: diagnostics present, no behavioral change.
3. **Phase 1 Findings (Discovery)**:
   - File #10 persistent destination: `dbo.tblTenantARSummary` (defined in `_YardiExportSQL/FULL-PORTAL-DATABASE.sql`), with staging landing in `dbo.tblStg_TenantARSummary`.
   - Active property/unit flags: `dbo.tblProperties.isInactive`, `dbo.tblPropertyUnits.isExcluded`.
   - Post-import SQL runner: `clsReportHelper.RunAllReportSQL_Public(...)` in `LW_Common2/clsReportHelper.cs`.
   - Builder usage (Phase 1): `EXEC dbo.spRptBuilder_AR_DailySnapshot_Build @AsOfDate = 'YYYY-MM-DD', @Rebuild = 1;` (reads `dbo.tblTenantARSummary`).

### Phase 2 — DB Schema: Persistent Snapshot Table (Approved) ✅ DONE
1. **Create** `dbo.tblTenantAR_DailySnapshot` with required columns and unique key `(AsOfDate, yardiPersonRowID, yardiPropertyRowID, yardiUnitRowID)`.
   - DoD: table exists with correct datatypes + unique constraint.
2. **Add indexes** for AsOfDate and Tenant+AsOfDate queries.
   - DoD: nonclustered indexes added for AsOfDate and tenant/date lookups.

### Phase 3 — Snapshot Maintenance Procedures (Approved) ✅ DONE
1. **spAR_Snapshots_UpsertFromStaging**: delete+insert for date range (idempotent) using `dbo.tblTenantARSummary` as the source.
   - DoD: rerun produces no duplicates.
2. **spAR_Snapshots_Cleanup**: delete old daily rows, keep month-ends forever.
   - DoD: daily history bounded, month-ends retained.
3. **spAR_Snapshots_GetLatestAsOfDate**: MAX(AsOfDate).
   - DoD: returns latest date fast.
4. **spAR_Snapshots_GetNearestPriorAsOfDate**: MAX(AsOfDate) < @AsOfDate.
   - DoD: supports fallback.

### Phase 4 — Nightly Integration (Post-Import) ✅ DONE
1. **Run snapshot upsert** after file #10 import in `RunAllReportSQL_Public` sequence.
   - DoD: `spAR_Snapshots_RunNightly` called after `sp_Load_TenantARSummary_FromStaging`.
2. **Monthly cleanup** on day=1.
   - DoD: handled inside `spAR_Snapshots_RunNightly`.
3. **Guardrail validation** for last 3 closed month-ends.
   - DoD: handled inside `spAR_Snapshots_RunNightly` with RAISERROR on missing month-ends.

### Phase 5 — sp_Snapshot_Tenants_SCD_Range uses Persistent Table ✅ DONE
1. Replace staging AR source with persistent snapshot table.
   - DoD: proc now reads `dbo.tblTenantAR_DailySnapshot`.
2. Regression check vs known month-end output.
   - DoD: output unchanged for historical month-end (pending manual validation).

### Phase 6 — Report SQL: Route to Persistent Snapshot ✅ DONE
1. **Update spReport_ArrearsTracker** to read persistent table, **remove internal EOMONTH forcing**.
   - DoD: daily + month-end AsOfDate supported; no staging reads.
2. If needed, adjust tenant snapshot join to range `@AsOfDate BETWEEN ValidFrom AND ISNULL(ValidTo,'9999-12-31')`.
   - DoD: daily AsOfDate works with month-end SCD snapshots (pending manual validation).

### Phase 7 — App Backend Effective Date Logic
1. **Reuse-first search** for existing date/report helpers (documented below).
   - DoD: decision documented before new helper.
2. Implement **single EffectiveAsOfDate method** (inputs: requested date, checkbox; uses snapshot procs).
   - DoD: returns requested/effective dates + warnings consistently.
3. Replace unconditional month-end rounding in code path with EffectiveAsOfDate.
   - DoD: 90-day rule + checkbox honored.

### Phase 8 — UI: Checkbox + Display
1. Add checkbox and bind to model.
2. Client-side immediate rounding while checked.
3. Display Requested vs Reporting-through + warnings.
   - DoD: UX matches spec without breaking export.

### Phase 9 — Validation Queries + Manual Test Plan
1. Add SQL validation snippets to this file.
2. Manual test plan for nightly import, SCD snapshot, daily report, fallback behavior, regression checks.
   - DoD: tests documented + results recorded when run.

---

## Expected files/classes/procs to modify (minimal set)
**App/UI**
- `LW_Web/Views/Shared/LegalReportingPage.cshtml` (UI additions for checkbox/warnings).
- `LW_Web/Models/LegalReportingPageModel.cs` (new fields for checkbox + warnings).
- `LW_Web/Controllers/LegalReportingController.cs` (effective date logic plumbing).

**Helpers / Import / Reporting**
- `LW_Common2/clsReportHelper.cs` (remove forced EOM, use effective date; RunAllReportSQL_Public integration).
- `LW_Common2/clsFunc.cs` (reuse only; avoid new helpers unless necessary).
- `LW_Common2/clsYardiHelper.cs` (import mapping awareness only; likely unchanged).
- `LW_Common2/clsEmailImport.cs` (import orchestration awareness only; likely unchanged).
- `LW_Common2/clsGeneralImportHelper.cs` (staging table mapping awareness only; likely unchanged).

**SQL scripts**
- `LW_Data2/SQL scripts/FULL Portal Database Script Backup.sql` (add new table/procs; update spReport_ArrearsTracker + sp_Snapshot_Tenants_SCD_Range; reference for lineage).
- `LW_Web/_YardiExportSQL/FULL-PORTAL-DATABASE.sql` or file #10 export script (update export SQL).

**SQL objects**
- `spReport_ArrearsTracker`
- `sp_Snapshot_Tenants_SCD_Range`
- New: `tblAR_SnapshotsByTenantUnit`, `spAR_Snapshots_UpsertFromStaging`, `spAR_Snapshots_Cleanup`, `spAR_Snapshots_GetLatestAsOfDate`, `spAR_Snapshots_GetNearestPriorAsOfDate`
- `RunAllReportSQL_Public` (call new procs)

---

## Reuse-first checks (existing helpers to consider)
- **Date utility**: `clsFunc.GetEndOfMonth(DateTime?)` in `LW_Common2/clsFunc.cs` (L26–L30).
- **Report orchestration**: `clsReportHelper.RunAllReportSQL_Public(...)` in `LW_Common2/clsReportHelper.cs` (L395–L423) already runs arrears-related SPs.
- **Excel report execution**: `clsReportHelper.FillExcel_TenantArrearsReport(...)` in `LW_Common2/clsReportHelper.cs` (L83–L128).
- **Import orchestration**: `EmailImporter.CheckEmailAndImport()` in `LW_Common2/clsEmailImport.cs` (L122–L252) drives file imports.
- **Staging cleanup**: `clsGeneralImportHelper.ClearTempImportTable(...)` in `LW_Common2/clsGeneralImportHelper.cs` (L99–L142).
- **File #10 import**: `clsYardiHelper.Import_Staging_TenantARSummary(...)` in `LW_Common2/clsYardiHelper.cs` (L803–L877).

---

## Discovery notes (evidence with file/line references)

### 1) Arrears report UI + controller call chain
**View (AsOfDate input)**
- `LW_Web/Views/Shared/LegalReportingPage.cshtml` shows **Tenant Arrears Report** form with `ArrearsReportDate` textbox and note about month-end rounding. (L30–L38)

**Controller action**
- `LW_Web/Controllers/LegalReportingController.cs` handles POST `GetTenantArrearsReport(...)` and parses `model.ArrearsReportDate`, then calls `FillExcel_TenantArrearsReport(...)`. (L49–L75)

**Helper/service**
- `LW_Common2/clsReportHelper.cs` method `FillExcel_TenantArrearsReport(...)` runs `spReport_ArrearsTracker`. (L83–L128)

**Current month-end forcing (code)**
- `LW_Common2/clsReportHelper.cs` forces month-end: `AsOfDate = clsFunc.GetEndOfMonth(AsOfDate)` (L87–L88).
- `LW_Common2/clsFunc.cs` `GetEndOfMonth(...)` implementation (L26–L30).

### 2) SQL report path
- `spReport_ArrearsTracker` is defined in `LW_Data2/SQL scripts/FULL Portal Database Script Backup.sql` around lines **3734–3744**.
- It **forces month-end** internally:
  - `SET @AsOfDate = EOMONTH(GETDATE());` (L3758)
  - `SET @AsOfDate = EOMONTH(@AsOfDate);` (L3760)

### 3) Import pipeline entry + post-import hook
**Entry point**
- `LW_Web/Controllers/ImportController.cs` `ImportLatestEmailAttachments()` calls `EmailImporter.CheckEmailAndImport()` (L33–L41).

**File #10 import**
- `LW_Common2/clsEmailImport.cs` dispatches file #10 to `Import_Staging_TenantARSummary(...)` after `ClearTempImportTable(...)` (L180–L182).
- `LW_Common2/clsYardiHelper.cs` imports file #10 into `dbo.tblStg_TenantARSummary` (L843–L861).
- `LW_Common2/clsGeneralImportHelper.cs` maps `DailyARbyTenant10` to `TenantARSummary` file type (L93–L133).

**Post-import SQL**
- `LW_Common2/clsReportHelper.cs` `RunAllReportSQL_Public(...)` runs SQL procs in order (L395–L423):
  1) `spRptBuilder_Inventory_01_Import`
  2) `spRptBuilder_WOReview_01_WOs`
  3) `spRptBuilder_WOReview_02_POs`
  4) `spRptBuilder_WOReview_03_Labor`
  5) `spRptBuilder_WOReview_04_SortlyFixes`
  6) `spRptBuilder_WOReview_05_Materials`
  7) `spRptBuilder_WOReview_06_Calcs`
  8) `sp_Load_Tenants_FromStaging`
  9) `sp_Load_LegalCases_FromStaging`
  10) `sp_Load_LegalActions_FromStaging`
  11) `sp_Snapshot_Tenants_SCD_Range`
  12) `sp_AttorneyAssignments_LoadFromStg`

### 4) sp_Snapshot_Tenants_SCD_Range dependency
- Definition: `LW_Data2/SQL scripts/FULL Portal Database Script Backup.sql` line **2671**.
- **Month-end date range** (EOMONTH-based): lines **2692–2707**.
- **AR source is staging**: reads `dbo.tblStg_TenantARSummary` (L2791).

### 5) Existing reusable helpers (date/report/import)
- **Date utility**: `clsFunc.GetEndOfMonth(...)` in `LW_Common2/clsFunc.cs` (L26–L30).
- **Reporting**: `clsReportHelper.FillExcel_TenantArrearsReport(...)` + `RunAllReportSQL_Public(...)` in `LW_Common2/clsReportHelper.cs` (L83–L128; L395–L423).
- **Import orchestration**: `EmailImporter.CheckEmailAndImport()` in `LW_Common2/clsEmailImport.cs` (L122–L252).
- **Staging utilities**: `clsGeneralImportHelper.ClearTempImportTable(...)` in `LW_Common2/clsGeneralImportHelper.cs` (L99–L142).

---

## Open questions / missing items
- None found in Phase 0 discovery. All required call chains and proc definitions located.
