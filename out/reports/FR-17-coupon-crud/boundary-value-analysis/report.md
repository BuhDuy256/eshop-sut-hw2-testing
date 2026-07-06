# FR-17 — Boundary Value Analysis Report

## Testing Model reference

- Variables: `discount_value` (numeric boundary), `min_order_amount` (numeric boundary),
  `max_uses_per_user` (numeric boundary + a code-derived falsy/truthy coercion asymmetry),
  `type` (enum boundary), `expired_at` (presence boundary) — see
  `work/FR-17-coupon-crud/testing-model.md`.
- Accepted Assumption `[[A1]]` (`work/FR-17-coupon-crud/assumptions.md`) fixes the concrete
  "just above zero" value for `discount_value` at the integer `1` (DB column is `INTEGER`; all
  seed values are whole numbers) — same class of decision as FR-15's accepted `A1` for `price`.
- Single enforcement path for all boundaries here (Stage 4.3): the admin frontend does not
  enforce a *different* rule for any of the six fields (no client-side `min` on
  `discount_value`/`min_order_amount`, `max_uses_per_user`'s `min="1"` is client-only and
  non-blocking via direct API, `type`'s `<select>` is a subset-of-two-values constraint, not a
  conflicting rule) — see the domain-testing report's coverage rationale. A single API-path
  case per boundary point suffices; no UI-path duplicate is designed.
- All cases below use an authenticated **admin** JWT, isolating the boundary under test from
  the actor/role forbidden-state axis (covered separately in the domain-testing report). Note:
  unlike FR-15, verification `GET` calls here must also carry an admin token, since
  `GET /api/coupons` itself requires authentication.

## Boundary set 1 — `discount_value` (must be `> 0`, exclusive lower bound; no stated upper bound)

Spec boundary: `README.md` FR-17 line 216 ("discount_value (dương)") — an exclusive lower bound
only. No upper bound is stated (a type-dependent ceiling, e.g. `<=100` for `percent`, would be
FR-09 discount-formula scope creep — not modeled). Granularity per accepted `[[A1]]`: integer
steps.

| Point | Value | Spec class |
|---|---|---|
| min − 1 | `-1` | invalid |
| min (boundary itself, excluded) | `0` | invalid |
| min + 1 (just-valid) | `1` | valid (per `[[A1]]`) |

### Test Cases

| ID | Value | Steps | Expected | `expected_source` | Status |
|---|---|---|---|---|---|
| TC-17-BVA-001 | `discount_value` = `-1` | Login as admin. `POST /api/admin/coupons` with `discount_value:-1`, other fields valid, unique `code`. `GET /api/coupons` (as admin) for the created row. | The create is rejected, or if created, `discount_value` must not be persisted as `-1`. | `spec` line 216 | frozen |
| TC-17-BVA-002 | `discount_value` = `0` | Same, with `discount_value:0`. | The create is rejected, or if created, `discount_value` must not be persisted as `0` (boundary excluded by "dương" / `> 0`). | `spec` line 216 | frozen |
| TC-17-BVA-003 | `discount_value` = `1` | Same, with `discount_value:1`. | Persisted as `discount_value:1` (spec-valid must succeed). | `assumption: A1` (accepted 2026-07-07) for the concrete integer value; the `>0` validity rule itself is `spec` line 216. | frozen |

## Boundary set 2 — `min_order_amount` (must be `>= 0`, inclusive lower bound; no stated upper bound)

Spec boundary: `README.md` FR-17 line 216 ("min_order_amount (>= 0)") — an inclusive lower
bound. The omitted-field point is already covered by `TC-17-EP-009` in the domain-testing
report and is not repeated here.

| Point | Value | Spec class |
|---|---|---|
| min − 1 | `-1` | invalid |
| min (boundary itself, included) | `0` | valid |
| min + 1 (just-valid) | `1` | valid |

### Test Cases

| ID | Value | Steps | Expected | `expected_source` | Status |
|---|---|---|---|---|---|
| TC-17-BVA-004 | `min_order_amount` = `-1` | Login as admin. `POST /api/admin/coupons` with `min_order_amount:-1`, other fields valid, unique `code`. `GET /api/coupons` (as admin) for the created row. | The create is rejected, or if created, `min_order_amount` must not be persisted as `-1`. | `spec` line 216 | frozen |
| TC-17-BVA-005 | `min_order_amount` = `0` | Same, with `min_order_amount:0`. | Persisted as `min_order_amount:0` (spec-valid, boundary included by ">=0"). | `spec` line 216 | frozen |
| TC-17-BVA-006 | `min_order_amount` = `1` | Same, with `min_order_amount:1`. | Persisted as `min_order_amount:1` (spec-valid, confirms no off-by-one on the ">=0" check). | `spec` line 216 | frozen |

## Boundary set 3 — `max_uses_per_user` (must be `>= 1`; code's own `|| 1` falsy-coercion is a second, differing boundary)

Spec boundary: `README.md` FR-17 line 216 ("max_uses_per_user (>= 1)") — an inclusive lower
bound. **Second boundary, code-derived, differs from the spec's:** `server.js` L474,
`max_uses_per_user || 1`, coerces every *falsy* input (`0`, `null`, omitted/`undefined`) to the
literal `1` — accidentally landing inside the spec-valid range, not because the code checks
`>= 1`. A *truthy* invalid value (`-1`) bypasses this fallback entirely (`-1 || 1` evaluates to
`-1` in JavaScript) and is expected, per the code, to persist unprotected. This set therefore
covers both the spec's own numeric boundary **and** the falsy/truthy asymmetry as distinct
points, per Step 1.2 (second, code-revealed boundary tagged separately).

| Point | Value | Spec class | Code-derived hypothesis (where to look, not the oracle) |
|---|---|---|---|
| `0` (falsy, spec-invalid) | `0` | invalid | `0 \|\| 1` → coerced to `1` |
| `null` (falsy, spec-invalid, explicit) | `null` | invalid | `null \|\| 1` → coerced to `1` |
| omitted (falsy, spec-invalid, key absent) | *(absent)* | invalid | `undefined \|\| 1` → coerced to `1` |
| `-1` (truthy, spec-invalid) | `-1` | invalid | `-1 \|\| 1` → **not** coerced, stays `-1` |
| `1` (boundary itself, valid) | `1` | valid | inserted as-is |
| `2` (just-valid) | `2` | valid | inserted as-is |

### Test Cases

| ID | Value | Steps | Expected | `expected_source` | Status |
|---|---|---|---|---|---|
| TC-17-BVA-007 | `max_uses_per_user` = `0` | Login as admin. `POST /api/admin/coupons` with `max_uses_per_user:0`, other fields valid, unique `code`. `GET /api/coupons` (as admin) for the created row. | The create is rejected, or if created, `max_uses_per_user` must not be persisted **as `0`** — the spec-level expectation is stated only at the outcome ("not persisted as the invalid value given"), regardless of whether some other mechanism happens to substitute a different, valid value instead. | `spec` line 216 | frozen |
| TC-17-BVA-008 | `max_uses_per_user` = `null` | Same, with `max_uses_per_user:null` (explicit JSON `null`). | The create is rejected, or if created, `max_uses_per_user` must not be persisted as `null`. | `spec` line 216 | frozen |
| TC-17-BVA-009 | `max_uses_per_user` omitted | Same, with the `max_uses_per_user` key omitted entirely. | The create is rejected, or if created, `max_uses_per_user` must not be persisted as `null`/absent. | `spec` line 216 (required) | frozen |
| TC-17-BVA-010 | `max_uses_per_user` = `-1` | Same, with `max_uses_per_user:-1`. | The create is rejected, or if created, `max_uses_per_user` must not be persisted as `-1` (a value `< 1`) — this is the point most likely to expose the falsy/truthy asymmetry as a real defect, since the code's own fallback offers this value no protection. | `spec` line 216 | frozen |
| TC-17-BVA-011 | `max_uses_per_user` = `1` | Same, with `max_uses_per_user:1`. | Persisted as `max_uses_per_user:1` (spec-valid, boundary included). | `spec` line 216 | frozen |
| TC-17-BVA-012 | `max_uses_per_user` = `2` | Same, with `max_uses_per_user:2`. | Persisted as `max_uses_per_user:2` (spec-valid, confirms no off-by-one). | `spec` line 216 | frozen |

## Boundary set 4 — `type` (enum over `{"percent", "fixed"}`)

Spec boundary: `README.md` FR-17 line 216 ("type (percent/fixed)") — a 2-member enum. Per Stage
4.2 (enum boundary): first and last defined member, plus one value adjacent to the set but not
a member. The invalid-member point is already covered generally by `TC-17-EP-004`; this set
adds the enum-specific first/last/adjacent framing.

| Point | Value | Spec class |
|---|---|---|
| first member | `"percent"` | valid |
| last member | `"fixed"` | valid |
| adjacent, non-member (case variant) | `"Percent"` | invalid |

### Test Cases

| ID | Value | Steps | Expected | `expected_source` | Status |
|---|---|---|---|---|---|
| TC-17-BVA-013 | `type` = `"percent"` | Login as admin. `POST /api/admin/coupons` with `type:"percent"`, other fields valid, unique `code`. `GET /api/coupons` (as admin) for the created row. | Persisted as `type:"percent"` (spec-valid must succeed). | `spec` line 216 | frozen |
| TC-17-BVA-014 | `type` = `"fixed"` | Same, with `type:"fixed"`. | Persisted as `type:"fixed"` (spec-valid must succeed). | `spec` line 216 | frozen |
| TC-17-BVA-015 | `type` = `"Percent"` (case variant) | Same, with `type:"Percent"`. | The create is rejected, or if created, `type` must not be persisted as `"Percent"` (not a member of the exact literal set `{"percent","fixed"}`). | `spec` line 216 | frozen |

## Boundary set 5 — `expired_at` (presence boundary)

Spec boundary: `README.md` FR-17 line 216 (required, no further qualifier). Per Stage 4.2
(optional/presence boundary): field entirely absent, present but empty, present with a value.
The "entirely absent" point is already covered by `TC-17-EP-007` and the "present with a value"
point by `TC-17-EP-001`'s happy path; this set adds only the new point, "present but empty".

| Point | Value | Spec class |
|---|---|---|
| present but empty | `""` | invalid |

### Test Cases

| ID | Value | Steps | Expected | `expected_source` | Status |
|---|---|---|---|---|---|
| TC-17-BVA-016 | `expired_at` = `""` | Login as admin. `POST /api/admin/coupons` with `expired_at:""`, other fields valid, unique `code`. `GET /api/coupons` (as admin) for the created row. | The create is rejected, or if created, `expired_at` must not be persisted as `""` (an empty value is not a genuine date). | `spec` line 216 (required) | frozen |

## Note on interpretation

As in the FR-04/FR-15 BVA reports, a "must not be persisted as `<value>`" expectation does not
prescribe *how* the SUT must behave instead (reject with an error, silently substitute a
different value, etc.) — only that the exact spec-invalid value must not end up as the stored
field. This is deliberately what lets `TC-17-BVA-007`/`008`/`009` state a single spec-level
expectation without presupposing which way the falsy/truthy asymmetry resolves: the oracle is
"not persisted as the invalid value given," which holds whether the SUT rejects the request
outright or (as the code suggests) happens to substitute an accidentally-valid `1` instead —
whereas `TC-17-BVA-010`'s `-1` case has no such accidental protection and is the point most
likely to show a genuine spec violation.

## Coverage rationale

This is the full boundary set for the five variables in FR-17 with a spec-stated or
code-revealed boundary (`discount_value` range, `min_order_amount` range, `max_uses_per_user`
range **plus** its falsy/truthy coercion asymmetry, `type` enum, `expired_at` presence).
`code`'s only boundary is uniqueness (a state-comparison, not a range/enum/presence kind) and is
fully covered by EP (`TC-17-EP-002`/`003`); the actor/role forbidden state is not boundary-shaped
in the Stage 4 sense (categorical/state) and is covered entirely by EP in the domain-testing
report, the same treatment FR-08/FR-15 gave their analogous actor-state variables.

## AI Gap Analysis

See `out/reports/FR-17-coupon-crud/domain-testing/report.md` — recorded once, covers both
reports (same convention as FR-04/FR-15).
