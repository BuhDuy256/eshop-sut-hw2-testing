# execution-results.md — FR-04 Personal Profile (Step 4 pilot)

> Execution Result artifacts. Per architecture.md §4.4(2): no `expected` field — verdict is
> computed by comparing `actual` against the referenced frozen Test Case. All 16 cases
> executed via Model C (native Bash `curl`/`node`), against a freshly reseeded DB
> (`docker exec eshop-backend node database.js`), user `test@eshop.com`.

## Equivalence Partitioning (ref: `out/reports/FR-04-personal-profile/domain-testing/report.md`)

| Result id | Ref | Actual | Verdict |
|---|---|---|---|
| ER-04-EP-001 | TC-04-EP-001 | `PUT {"name":"Nguyen Van A","phone":"0912345678","shipping_address":"123 Le Loi, TP.HCM"}` → 200; `GET` returns all three fields exactly as sent. | **PASS** |
| ER-04-EP-002 | TC-04-EP-002 | `PUT {"name":"",...}` → 200; `GET` returns `name:""` — empty name persisted with no rejection. | **FAIL** |
| ER-04-EP-003 | TC-04-EP-003 | `PUT {"shipping_address":"",...}` → 200; `GET` returns `shipping_address:""`. | **PASS** |
| ER-04-EP-004 | TC-04-EP-004 | `PUT {"phone":"1912345678",...}` (spec-invalid, no leading `0`) → 200; `GET` returns `phone:"1912345678"` — persisted unchanged. | **FAIL** |
| ER-04-EP-005 | TC-04-EP-005 | `PUT {..., "role":"admin"}` as a `user`-role account → 200; `GET` returns `role:"admin"` — role successfully changed by the client. | **FAIL** |
| ER-04-EP-006 | TC-04-EP-006 | `PUT {..., "email":"changed@eshop.com"}` → 200; `GET` returns `email:"test@eshop.com"` — unchanged. | **PASS** |

## Boundary Value Analysis — `phone` (ref: `out/reports/FR-04-personal-profile/boundary-value-analysis/report.md`)

### UI-path (literal frontend regex `^[1-9][0-9]{8,9}$`, evaluated via `node -e`)

| Result id | Ref | Value | `regex.test()` actual | Verdict |
|---|---|---|---|---|
| ER-04-BVA-001 | TC-04-BVA-001 | `091234567` (9 digits) | `false` (rejected) | **PASS** |
| ER-04-BVA-002 | TC-04-BVA-002 | `0912345678` (10 digits, spec-valid) | `false` (rejected) | **FAIL** |
| ER-04-BVA-003 | TC-04-BVA-003 | `09123456789` (11 digits, spec-valid) | `false` (rejected) | **FAIL** |
| ER-04-BVA-004 | TC-04-BVA-004 | `091234567890` (12 digits) | `false` (rejected) | **PASS** |
| ER-04-BVA-005 | TC-04-BVA-005 | `1912345678` (leading `1`) | `true` (accepted) | **FAIL** |

### API-path (`PUT /api/users/me` direct, then `GET`)

| Result id | Ref | Value | Persisted actual | Verdict |
|---|---|---|---|---|
| ER-04-BVA-006 | TC-04-BVA-006 | `091234567` (9 digits) | `091234567` | **FAIL** |
| ER-04-BVA-007 | TC-04-BVA-007 | `0912345678` (10 digits) | `0912345678` | **PASS** |
| ER-04-BVA-008 | TC-04-BVA-008 | `09123456789` (11 digits) | `09123456789` | **PASS** |
| ER-04-BVA-009 | TC-04-BVA-009 | `091234567890` (12 digits) | `091234567890` | **FAIL** |
| ER-04-BVA-010 | TC-04-BVA-010 | `1912345678` (leading `1`) | `1912345678` | **FAIL** |

## Summary

16 cases executed: **6 PASS**, **10 FAIL**. FAIL results cluster into 4 distinct root-cause
defects (grouped for bug reporting, not one report per test case):

1. **Empty `name` accepted** (ER-04-EP-002).
2. **Backend performs zero phone-format validation** — any spec-invalid value persists via
   direct API call (ER-04-EP-004, ER-04-BVA-006/009/010).
3. **Frontend phone regex contradicts the spec** — rejects spec-valid numbers, accepts
   spec-invalid ones (ER-04-BVA-002/003/005; ER-04-BVA-001/004 happen to reject for the wrong
   reason — same defective regex, evidenced together).
4. **Role injection succeeds** (ER-04-EP-005) — **critical**, direct SEC-06 violation:
   a `user`-role account can self-promote to `admin` via the profile-update endpoint.

Evidence: `out/reports/FR-04-personal-profile/bug-reports/evidence/BUG-04-{001..004}-request-response.txt`.

## Human gate: `FAIL → real bug?`

- [x] Are these 10 FAILs real defects (not test/setup artifacts)? Evidence for ruling out setup
  error: DB was freshly reseeded before the EP run and again before the BVA API-path run; each
  case used a fresh login; the UI-path cases used the literal, unmodified regex read from
  `Profile.jsx` (no test-side transcription); the API-path cases varied only the field under
  test while keeping the other two fields at known-valid values.

  **Decision (2026-07-04), reviewed per defect group:**
  - Defect 2 (backend zero phone validation) — **confirmed real bug**. `spec`-sourced
    (`README.md` line 65).
  - Defect 3 (frontend regex contradicts spec) — **confirmed real bug**. `spec`-sourced.
  - Defect 4 (role injection) — **confirmed real bug, Critical**. `spec`-sourced (`README.md`
    line 67, SEC-06).
  - Defect 1 (empty `name` accepted) — **confirmed as a real observation, but reclassified**:
    `README.md` states `name` is mandatory **at registration** (FR-01 line 32: "Người dùng
    phải cung cấp: Họ Tên..."); FR-04 (line 64) does not explicitly restate that an update may
    not blank it out. There is no direct FR-04 citation for "must not be empty" — the
    expectation rests on **accepted assumption A2** (`work/FR-04-personal-profile/assumptions.md`),
    not an explicit spec statement. Reported as an **assumption-grounded** defect, distinct in
    kind from Defects 2–4 (which cite `README.md` FR-04 directly). See `BUG-04-001` for the
    explicit `expected_source: assumption` labeling.
