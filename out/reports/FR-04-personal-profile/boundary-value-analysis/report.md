# FR-04 — Boundary Value Analysis Report

## Testing Model reference

- Variable: `phone` — see `work/FR-04-personal-profile/testing-model.md`.
- Oracle: `README.md` FR-04 line 65 ("bắt đầu bằng số 0, từ 10–11 chữ số"), applied
  **path-agnostically** per the reframed [[A4]] (rejected as originally drafted — no
  assumption needed; see `work/FR-04-personal-profile/assumptions.md`).
- Two independent execution paths test the same boundary values, since the SUT has two
  separate (and disagreeing) points that could enforce the rule:
  - **UI-path** — evaluate the exact frontend regex (`frontend-web/src/pages/Profile.jsx`
    line 43, `^[1-9][0-9]{8,9}$`) against the boundary value. Executed for real (Model C: `node
    -e` running the literal regex), not inferred by reading — this is the actual client-side
    behavior a browser would produce for that input.
  - **API-path** — `PUT /api/users/me` directly, bypassing the browser, then `GET /api/users/me`
    to see what was persisted.

## Boundary set (5 values)

Spec boundary: valid length is 10–11 digits, must start with `0`.

| Point | Value | Digit length | Leading digit | Spec class |
|---|---|---|---|---|
| min − 1 | `091234567` | 9 | `0` | invalid (too short) |
| min | `0912345678` | 10 | `0` | **valid** |
| max | `09123456789` | 11 | `0` | **valid** |
| max + 1 | `091234567890` | 12 | `0` | invalid (too long) |
| leading-digit boundary | `1912345678` | 10 | `1` | invalid (wrong leading digit) |

## Test Cases

Each boundary value is tested via both paths → 10 cases, `TC-04-BVA-001`…`010`.

### UI-path (frontend regex evaluation)

| ID | Value | Expected (per spec class) | `expected_source` | Status |
|---|---|---|---|---|
| TC-04-BVA-001 | `091234567` (9 digits) | Regex should reject (spec-invalid). | `spec` line 65 | frozen |
| TC-04-BVA-002 | `0912345678` (10 digits) | Regex should **accept** (spec-valid). | `spec` line 65 | frozen |
| TC-04-BVA-003 | `09123456789` (11 digits) | Regex should **accept** (spec-valid). | `spec` line 65 | frozen |
| TC-04-BVA-004 | `091234567890` (12 digits) | Regex should reject (spec-invalid). | `spec` line 65 | frozen |
| TC-04-BVA-005 | `1912345678` (leading `1`) | Regex should reject (spec-invalid, wrong leading digit). | `spec` line 65 | frozen |

**Steps (each row):** run `node -e "console.log(/^[1-9][0-9]{8,9}$/.test('<value>'))"` (the
literal frontend regex) and record `true`/`false`. Compare against the Expected column.

**Preconditions:** none (pure client-side logic evaluation; no auth/server needed for this path).

### API-path (direct backend call)

| ID | Value | Expected (persisted value after call) | `expected_source` | Status |
|---|---|---|---|---|
| TC-04-BVA-006 | `091234567` (9 digits) | Not persisted as `091234567` (spec-invalid must not end up stored). | `spec` line 65 | frozen |
| TC-04-BVA-007 | `0912345678` (10 digits) | Persisted as `0912345678` (spec-valid must succeed). | `spec` line 65 | frozen |
| TC-04-BVA-008 | `09123456789` (11 digits) | Persisted as `09123456789` (spec-valid must succeed). | `spec` line 65 | frozen |
| TC-04-BVA-009 | `091234567890` (12 digits) | Not persisted as `091234567890` (spec-invalid must not end up stored). | `spec` line 65 | frozen |
| TC-04-BVA-010 | `1912345678` (leading `1`) | Not persisted as `1912345678` (spec-invalid must not end up stored). | `spec` line 65 | frozen |

**Steps (each row):** 1. Login as `test@eshop.com`. 2. `PUT /api/users/me` with `phone: "<value>"`
(plus valid `name`/`shipping_address` so only `phone` varies). 3. `GET /api/users/me`, read
the persisted `phone`.

**Preconditions:** user authenticated (JWT).

## Note on interpretation

A "not persisted as `<value>`" expectation does not prescribe *how* the SUT must behave instead
(reject with an error, silently coerce, truncate, etc.) — only that the exact spec-invalid value
must not end up as the stored `phone`. This keeps the oracle strictly to what `README.md` line 65
states (a definition of validity) without inventing an error-handling contract the spec does not
provide.

## Coverage rationale

This is the full boundary set for the one variable in FR-04 with a spec-stated numeric/ordinal
boundary (`phone`). `name` and `shipping_address` have no spec-stated boundary (see `work/FR-04-personal-profile/assumptions.md`
A1) and are covered by EP only, in the domain-testing report. The UI-path/API-path duplication
is deliberate: it is the mechanism by which the Phase 0 discovery finding (frontend regex
contradicts the spec boundary; backend has no validation at all) becomes falsifiable evidence
rather than a code-reading impression.

## AI Gap Analysis

See `out/reports/FR-04-personal-profile/domain-testing/report.md` — recorded once, covers both
reports (plan Step 4.6).
