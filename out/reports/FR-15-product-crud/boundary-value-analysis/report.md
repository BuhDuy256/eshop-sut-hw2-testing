# FR-15 — Boundary Value Analysis Report

## Testing Model reference

- Variables: `name` (lexical/length boundary), `price` (numeric boundary), `category_id`
  (enum boundary) — see `work/FR-15-product-crud/testing-model.md`.
- Accepted Assumption `[[A1]]` (`work/FR-15-product-crud/assumptions.md`) fixes the concrete
  "just above zero" value for `price` at the integer `1` (DB column is `INTEGER`; all seed
  prices are whole VND).
- Single enforcement path for all three boundaries here (Stage 4.3): the admin frontend does
  not enforce a *different* rule for any of the three (no client-side `maxLength` on `name`,
  no `min`/`required` on `price`, and `category_id`'s `<select>` is merely a subset-of-existing
  constraint, not a conflicting rule) — see the domain-testing report's coverage rationale for
  the full reasoning. A single API-path case per boundary point suffices; no UI-path duplicate
  is designed.
- All cases below use an authenticated **admin** JWT, isolating the boundary under test from
  the actor/role forbidden-state axis (covered separately in the domain-testing report).

## Boundary set 1 — `name` length (max 255, inclusive)

Spec boundary: required (non-empty), max 255 characters, inclusive (`README.md` FR-15 line
195). The 0-length (empty) point is already covered by `TC-15-EP-002` in the domain-testing
report and is not repeated here; this set covers the length-specific points around the stated
maximum, plus the minimum non-empty length.

| Point | Value | Length | Spec class |
|---|---|---|---|
| min (just-valid) | `"A"` | 1 | valid |
| max (just-valid) | `"A"` × 255 | 255 | valid |
| max + 1 (just-invalid) | `"A"` × 256 | 256 | invalid |

### Test Cases

| ID | Value | Steps | Expected | `expected_source` | Status |
|---|---|---|---|---|---|
| TC-15-BVA-001 | `name` = 1-char string | Login as admin. `POST /api/products` with `name` = 1 char, valid `price`/`category_id`. `GET /api/products/:id`. | Persisted as the 1-character `name` (spec-valid must succeed). | `spec` line 195 | frozen |
| TC-15-BVA-002 | `name` = 255-char string | Same, with `name` = 255 chars. | Persisted as the 255-character `name` (spec-valid must succeed). | `spec` line 195 | frozen |
| TC-15-BVA-003 | `name` = 256-char string | Same, with `name` = 256 chars. | The create is rejected, or if created, `name` must not be persisted as the full 256-character string (spec-invalid must not end up stored as given). | `spec` line 195 | frozen |

## Boundary set 2 — `price` (must be `> 0`, exclusive lower bound; no stated upper bound)

Spec boundary: `README.md` FR-15 line 196 ("phải là số dương (> 0)") — an exclusive lower
bound only. No upper bound is stated, so no max-side boundary case is designed (inventing one
would assert more than the spec supports). Granularity per accepted `[[A1]]`: integer steps.

| Point | Value | Spec class |
|---|---|---|
| min − 1 | `-1` | invalid |
| min (boundary itself, excluded) | `0` | invalid |
| min + 1 (just-valid) | `1` | valid (per `[[A1]]`) |

### Test Cases

| ID | Value | Steps | Expected | `expected_source` | Status |
|---|---|---|---|---|---|
| TC-15-BVA-004 | `price` = `-1` | Login as admin. `POST /api/products` with `price:-1`, valid `name`/`category_id`. `GET /api/products/:id`. | The create is rejected, or if created, `price` must not be persisted as `-1`. | `spec` line 196 | frozen |
| TC-15-BVA-005 | `price` = `0` | Same, with `price:0`. | The create is rejected, or if created, `price` must not be persisted as `0` (boundary excluded by "> 0"). | `spec` line 196 | frozen |
| TC-15-BVA-006 | `price` = `1` | Same, with `price:1`. | Persisted as `price:1` (spec-valid must succeed). | `assumption: A1` (accepted 2026-07-06) for the concrete integer value; the `>0` validity rule itself is `spec` line 196. | frozen |

## Boundary set 3 — `category_id` (enum over existing `categories.id`; seeded `{1, 2, 3}`)

Spec boundary: `README.md` FR-15 line 197 ("phải chọn từ danh sách có sẵn") — an enum-type
boundary over whatever category ids currently exist. Per Stage 4.2 (enum boundary): first and
last defined member, plus one value adjacent to the set but not a member.

| Point | Value | Spec class |
|---|---|---|
| first member | `1` (Điện thoại) | valid |
| last member | `3` (Phụ kiện) | valid |
| adjacent, non-member | `4` (no such category) | invalid |

### Test Cases

| ID | Value | Steps | Expected | `expected_source` | Status |
|---|---|---|---|---|---|
| TC-15-BVA-007 | `category_id` = `1` | Login as admin. `POST /api/products` with `category_id:1`, valid `name`/`price`. `GET /api/products/:id`. | Persisted as `category_id:1` (spec-valid must succeed). | `spec` line 197 | frozen |
| TC-15-BVA-008 | `category_id` = `3` | Same, with `category_id:3`. | Persisted as `category_id:3` (spec-valid must succeed). | `spec` line 197 | frozen |
| TC-15-BVA-009 | `category_id` = `4` | Same, with `category_id:4`. | The create is rejected, or if created, `category_id` must not be persisted as `4` (no such category exists). | `spec` line 197 | frozen |

## Note on interpretation

As in the FR-04 BVA report, a "must not be persisted as `<value>`" expectation does not
prescribe *how* the SUT must behave instead (reject with an error, silently coerce, etc.) —
only that the exact spec-invalid value must not end up as the stored field. This keeps the
oracle strictly to what `README.md` defines, without inventing an error-handling contract the
spec does not provide.

## Coverage rationale

This is the full boundary set for the three variables in FR-15 with a spec-stated boundary
(`name` length, `price` range, `category_id` enum). The actor/role forbidden state and the
edit-isolation postcondition are not boundary-shaped in the Stage 4 sense (categorical/state
and system-invariant, respectively) and are covered entirely by EP in the domain-testing
report, the same treatment FR-08 gave its analogous auth-state and cart-clearing variables.

## AI Gap Analysis

See `out/reports/FR-15-product-crud/domain-testing/report.md` — recorded once, covers both
reports (same convention as FR-04).
