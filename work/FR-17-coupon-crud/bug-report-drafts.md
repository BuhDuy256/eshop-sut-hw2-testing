# bug-report-drafts.md — FR-17 Coupon Management CRUD

> Stage 1 (confirm): environment was freshly reseeded (`node database.js`) immediately before
> execution; each case varied only its own field under test from an otherwise-valid baseline;
> no retries were needed and no case depended on another case's outcome (except the deliberate
> `DUPTEST1` duplicate-code pair, which itself PASSed). **All 16 FAILs are confirmed genuine
> defects — none rejected as test/setup artifacts.**
>
> Stage 2 (grouping): 16 confirmed failures group into **8 distinct defects**. Checked for real
> per the skill's own test ("would a merged report need two or more independent fixes?"): the
> five "zero validation" fields (`code`, `type`, `discount_value`, `expired_at`,
> `min_order_amount`) each get their own report because each requires its own independent
> validation check added to the same handler — merging them would still be one handler, but
> five different rules, so they stay separate defects (matching FR-15's precedent of one report
> per field even when the underlying handler is shared). `max_uses_per_user`'s two failures
> share one root cause (the `\|\| 1` fallback's truthy/falsy blind spot) and are one report.
> `GET /api/coupons` and `POST /api/admin/coupons` missing their role check are two **separate**
> reports even though they're the same defect *class* — different routes, different
> independent fixes (same reasoning FR-15 used to keep `BUG-15-004/005/006` as three reports).

## Draft BUG-17-001 — `code` has no required-ness validation

| Field | Value |
|---|---|
| **Severity** | Medium — a required identifier field can be created with a `null` value, contrary to `README.md` FR-17 line 216. Proven mechanism is limited to persistence: this pass did not execute the customer-facing apply-coupon lookup (`WHERE code = ?`, FR-09, out of scope) against a null-code row, so no downstream lookup-failure chain is claimed as demonstrated — only that a required field is missing entirely from a persisted coupon. |
| **Priority** | Medium — reachable only by an actor bypassing the admin form's client-side `required` attribute (a direct API call), not by normal UI use. |
| **Ref** | `TC-17-EP-003` / `ER-17-EP-003` |
| **GitHub Issue** | [#17](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/17) |

**Expected** (per `README.md` FR-17 line 216, oracle): `code` is a required field; an omitted
`code` must not end up persisted as `null`.

**Actual:** sent `POST /api/admin/coupons` with the `code` key omitted (other fields valid) —
the request succeeded (`200`, id 7) and a follow-up `GET /api/coupons` confirmed the row
persisted with `"code":null`.

**Steps to reproduce:**
1. Login as admin.
2. `POST /api/admin/coupons` with no `code` key, other fields valid (`type`, `discount_value`, `min_order_amount`, `expired_at`, `max_uses_per_user`).
3. `GET /api/coupons` (as admin) for the created row — observe `code: null`.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
`POST /api/admin/coupons` (~L457–481) destructures `code` from `req.body` and binds it straight
into the parameterized `INSERT` with no presence check; `coupons.code` (database.js line 31) is
`TEXT UNIQUE` but not `NOT NULL`, so a `null` value is accepted at the DB level too.

**Evidence:** raw request/response capture,
[`evidence/fr17-raw-execution-log.txt`](../out/reports/FR-17-coupon-crud/bug-reports/evidence/fr17-raw-execution-log.txt) lines 31–41 (API-level bug, no browser involved).

---

## Draft BUG-17-002 — `type` has no validation (accepts non-enum values and omission)

| Field | Value |
|---|---|
| **Severity** | Medium — a required enum field (`percent`/`fixed`) can be created with an arbitrary string, a case-variant of a valid member, or `null`. `type` determines which discount-calculation branch the (out-of-scope, FR-09) apply-coupon logic takes; this pass did not execute that calculation against an invalid `type`, so no proven miscalculation is claimed — only that the field's own required/enum constraint is entirely unenforced at creation. |
| **Priority** | Medium — reachable only via a direct API call; the admin form's fixed 2-option `<select>` cannot submit a third value through normal UI use. |
| **Ref** | `TC-17-EP-004`/`ER-17-EP-004`, `TC-17-EP-005`/`ER-17-EP-005`, `TC-17-BVA-015`/`ER-17-BVA-015` |
| **GitHub Issue** | [#18](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/18) |

**Expected** (per `README.md` FR-17 line 216, oracle): `type` must be exactly `"percent"` or
`"fixed"`; a missing or non-member value must not end up persisted as given.

**Actual:** three distinct invalid inputs were each accepted and persisted verbatim:
`type:"discount"` → persisted as `"discount"` (id 8); `type` key omitted → persisted as
`null` (id 9, confirming the column's own `DEFAULT 'percent'` never fires through this
endpoint); `type:"Percent"` (case variant) → persisted as `"Percent"` (id 31). All confirmed
via a follow-up `GET`.

**Steps to reproduce:**
1. Login as admin.
2. `POST /api/admin/coupons` with `type:"discount"` (or omit `type`, or send `"Percent"`), other fields valid.
3. `GET /api/coupons` (as admin) — observe the invalid `type` persisted unchanged.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
`POST /api/admin/coupons` binds `type` straight into the `INSERT` with no enum check;
`coupons.type` (database.js line 32) is `TEXT DEFAULT 'percent'` with no `CHECK` constraint,
and since the `INSERT`'s column list always names `type` explicitly, an omitted request field
binds SQL `NULL` rather than triggering the schema default.

**Evidence:** raw request/response capture,
[`evidence/fr17-raw-execution-log.txt`](../out/reports/FR-17-coupon-crud/bug-reports/evidence/fr17-raw-execution-log.txt) lines 43–65 (`TC-17-EP-004`), 287–292 (`TC-17-BVA-015`).

---

## Draft BUG-17-003 — `discount_value` has no validation (accepts zero and negative values)

| Field | Value |
|---|---|
| **Severity** | High — `discount_value` is core transactional data feeding the (out-of-scope, FR-09) discount-amount calculation; a zero or negative value, if ever reached by that calculation, could produce an incorrect final charge (e.g., a negative `fixed` discount would *increase* `final_amount` above the order total). Proven mechanism is limited to **persistence**: this pass did not execute the apply-coupon/checkout flow against one of these corrupted coupons, so no end-to-end financial-loss chain is claimed as demonstrated — only that invalid discount data enters and stays in the system with no server-side gate at all, the same discipline applied to FR-15's analogous `price` finding (`BUG-15-002`). |
| **Priority** | High |
| **Ref** | `TC-17-EP-006`/`ER-17-EP-006`, `TC-17-BVA-001`/`ER-17-BVA-001`, `TC-17-BVA-002`/`ER-17-BVA-002` |
| **GitHub Issue** | [#19](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/19) |

**Expected** (per `README.md` FR-17 line 216, oracle): `discount_value` must be `> 0`; a value
`≤ 0` must not end up persisted.

**Actual:** `discount_value:-1000` → persisted as `-1000` (id 10). `discount_value:-1` →
persisted as `-1` (id 17). `discount_value:0` → persisted as `0` (id 18). All confirmed via a
follow-up `GET`.

**Steps to reproduce:**
1. Login as admin.
2. `POST /api/admin/coupons` with `discount_value:-1` (or `0`, or any negative number), other fields valid.
3. `GET /api/coupons` (as admin) — observe the invalid `discount_value` persisted unchanged.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
`POST /api/admin/coupons` binds `discount_value` straight into the `INSERT` with no positivity
check; `coupons.discount_value` (database.js line 33) is `INTEGER` with no `CHECK (> 0)`.

**Evidence:** raw request/response capture,
[`evidence/fr17-raw-execution-log.txt`](../out/reports/FR-17-coupon-crud/bug-reports/evidence/fr17-raw-execution-log.txt) lines 67–77 (`TC-17-EP-006`), 189–201 (`TC-17-BVA-001`/`002`).

---

## Draft BUG-17-004 — `expired_at` has no validation (accepts omission and an empty value)

| Field | Value |
|---|---|
| **Severity** | Medium — a required date field can be created with `null` or an empty string. `expired_at` gates the (out-of-scope, FR-09) expiry check (`new Date(coupon.expired_at) < now`); this pass did not execute that check against a null/empty value, so no proven "coupon never expires" consequence is claimed — only that the field's own required-ness is entirely unenforced at creation. |
| **Priority** | Medium — reachable only via a direct API call bypassing the admin form's `required` attribute. |
| **Ref** | `TC-17-EP-007`/`ER-17-EP-007`, `TC-17-BVA-016`/`ER-17-BVA-016` |
| **GitHub Issue** | [#20](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/20) |

**Expected** (per `README.md` FR-17 line 216, oracle): `expired_at` is required; an omitted or
empty value must not end up persisted.

**Actual:** `expired_at` key omitted → persisted as `null` (id 11). `expired_at:""` → persisted
as `""` (id 32). Both confirmed via a follow-up `GET`.

**Steps to reproduce:**
1. Login as admin.
2. `POST /api/admin/coupons` with no `expired_at` key (or `expired_at:""`), other fields valid.
3. `GET /api/coupons` (as admin) — observe the invalid `expired_at` persisted unchanged.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
`POST /api/admin/coupons` binds `expired_at` straight into the `INSERT` with no presence check;
`coupons.expired_at` (database.js line 35) is `DATETIME` with no `NOT NULL`.

**Evidence:** raw request/response capture,
[`evidence/fr17-raw-execution-log.txt`](../out/reports/FR-17-coupon-crud/bug-reports/evidence/fr17-raw-execution-log.txt) lines 79–89 (`TC-17-EP-007`), 294–299 (`TC-17-BVA-016`).

---

## Draft BUG-17-005 — `min_order_amount` has no validation (accepts negative values and omission)

| Field | Value |
|---|---|
| **Severity** | Medium — a required, non-negative threshold field can be created negative or `null`. `min_order_amount` gates the (out-of-scope, FR-09) minimum-order check; this pass did not execute that check against a negative/null threshold, so no proven bypass-of-minimum-order chain is claimed — only that the field's own `>= 0` and required-ness constraints are entirely unenforced at creation. |
| **Priority** | Medium — reachable only via a direct API call; the admin form's own local state defaults this field to `0` (a valid value) when untouched. |
| **Ref** | `TC-17-EP-008`/`ER-17-EP-008`, `TC-17-EP-009`/`ER-17-EP-009`, `TC-17-BVA-004`/`ER-17-BVA-004` |
| **GitHub Issue** | [#21](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/21) |

**Expected** (per `README.md` FR-17 line 216, oracle): `min_order_amount` must be `>= 0` and is
a required field; a negative value or an omitted field must not end up persisted as given.

**Actual:** `min_order_amount:-500` → persisted as `-500` (id 12). `min_order_amount` key
omitted → persisted as `null` (id 13, confirming the column's own `DEFAULT 0` never fires
through this endpoint). `min_order_amount:-1` → persisted as `-1` (id 20). All confirmed via a
follow-up `GET`.

**Steps to reproduce:**
1. Login as admin.
2. `POST /api/admin/coupons` with `min_order_amount:-1` (or omit the key entirely), other fields valid.
3. `GET /api/coupons` (as admin) — observe the invalid `min_order_amount` persisted unchanged.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
`POST /api/admin/coupons` binds `min_order_amount` straight into the `INSERT` with no `>= 0`
check; `coupons.min_order_amount` (database.js line 34) is `INTEGER DEFAULT 0` with no `CHECK`,
and since the `INSERT`'s column list always names `min_order_amount` explicitly, an omitted
request field binds SQL `NULL` rather than triggering the schema default.

**Evidence:** raw request/response capture,
[`evidence/fr17-raw-execution-log.txt`](../out/reports/FR-17-coupon-crud/bug-reports/evidence/fr17-raw-execution-log.txt) lines 91–113 (`TC-17-EP-008`/`009`), 210–215 (`TC-17-BVA-004`).

---

## Draft BUG-17-006 — `max_uses_per_user`'s fallback protects against falsy invalid input but not negative values

| Field | Value |
|---|---|
| **Severity** | Medium — unlike the fields above, this one has a real (if incomplete) protection mechanism; the proven gap is narrower: only a *negative* `max_uses_per_user` value bypasses it. `max_uses_per_user` gates the (out-of-scope, FR-09) per-user usage-limit check (`usage_count >= coupon.max_uses_per_user`); this pass did not execute that check against a negative limit, so no proven "coupon unusable from first attempt" consequence is claimed — only that a value `< 1` can persist unprotected, contrary to `README.md` FR-17 line 216. |
| **Priority** | Medium — reachable only via a direct API call sending a negative number; the admin form's `min="1"` (client-side only) and default value of `1` mean normal UI use never produces this input. |
| **Ref** | `TC-17-EP-010`/`ER-17-EP-010`, `TC-17-BVA-010`/`ER-17-BVA-010` |
| **GitHub Issue** | [#22](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/22) |

**Expected** (per `README.md` FR-17 line 216, oracle): `max_uses_per_user` must be `>= 1`; a
value `< 1` must not end up persisted as given.

**Actual:** `max_uses_per_user:-5` → persisted as `-5` (id 14). `max_uses_per_user:-1` →
persisted as `-1` (id 26). Both confirmed via a follow-up `GET`. By contrast (not a failure,
cited for the asymmetry): `max_uses_per_user:0`, `null`, and an omitted key were each
*coerced* to `1` and persisted correctly (`ER-17-BVA-007/008/009`, all PASS) — the code's own
fallback catches every *falsy* invalid input but has no effect on a *truthy* invalid input like
`-1` or `-5`.

**Steps to reproduce:**
1. Login as admin.
2. `POST /api/admin/coupons` with `max_uses_per_user:-1` (any negative number), other fields valid.
3. `GET /api/coupons` (as admin) — observe the negative value persisted unchanged (contrast with `max_uses_per_user:0`, which is silently corrected to `1`).

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
line 474, `max_uses_per_user || 1` — a JavaScript falsy-coercion fallback, not a `>= 1` check.
Falsy inputs (`0`, `null`, `undefined`/omitted) are replaced with `1` before insertion; a
negative number is truthy in JavaScript, so `-1 || 1` evaluates to `-1` and bypasses the
fallback entirely.

**Evidence:** raw request/response capture,
[`evidence/fr17-raw-execution-log.txt`](../out/reports/FR-17-coupon-crud/bug-reports/evidence/fr17-raw-execution-log.txt) lines 115–125 (`TC-17-EP-010`), 252–257 (`TC-17-BVA-010`).

---

## Draft BUG-17-007 — `GET /api/coupons` has no access control (any authenticated user can view all coupons)

| Field | Value |
|---|---|
| **Severity** | High — a security boundary explicitly required by `README.md` FR-17 line 215 ("Admin có thể ... Xem ... mã giảm giá") and `SEC-03` is completely absent: evidence proves a non-admin authenticated user can retrieve the full coupon list, including every code, discount value, and threshold. Rated High rather than Critical: the proven impact is unauthorized **read** disclosure of coupon terms, not data creation/modification/deletion (contrast with `BUG-17-008` and FR-15's `BUG-15-004/005/006`, which are unauthorized **writes**). |
| **Priority** | High |
| **Ref** | `TC-17-EP-012`/`ER-17-EP-012` |
| **GitHub Issue** | [#23](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/23) |

**Expected** (per `README.md` FR-17 line 215 + `SEC-03`, oracle): `GET /api/coupons` must
require a valid JWT with `role='admin'`; a request from a non-admin (or unauthenticated) actor
must be rejected, with no coupon data returned.

**Actual:** `GET /api/coupons` with a valid `test@eshop.com` JWT (`role:user`) returned `200`
with the full coupon list (14 rows at the time of the request), identical to what an admin
would see.

**Steps to reproduce:**
1. Login as a non-admin user (`test@eshop.com`).
2. `GET /api/coupons` with that user's token.
3. Observe the full coupon list is returned, not a rejection.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
line 356, `GET /api/coupons` — carries only `authenticateToken` (checks JWT validity), never
inspects `req.user.role`.

**Evidence:** raw request/response capture,
[`evidence/fr17-raw-execution-log.txt`](../out/reports/FR-17-coupon-crud/bug-reports/evidence/fr17-raw-execution-log.txt) lines 134–139.

---

## Draft BUG-17-008 — `POST /api/admin/coupons` has no access control (any authenticated user can create coupons)

| Field | Value |
|---|---|
| **Severity** | Critical — a security boundary explicitly required by `README.md` FR-17 line 215, FR-12 lines 176–179, and `SEC-03` is completely absent: evidence proves a non-admin authenticated user can create an arbitrary coupon with no compensating control anywhere in the route — an unauthorized **write**, the same class of finding as FR-15's `BUG-15-004` (rated Critical there for the analogous product-creation endpoint). |
| **Priority** | P1 |
| **Ref** | `TC-17-EP-014`/`ER-17-EP-014` |
| **GitHub Issue** | [#24](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/24) |

**Expected** (per `README.md` FR-17 line 215 + FR-12 lines 176–179 + `SEC-03`, oracle):
`POST /api/admin/coupons` must require a valid JWT with `role='admin'`; a request from a
non-admin actor must be rejected, with no coupon created.

**Actual:** `POST /api/admin/coupons` with a valid `test@eshop.com` JWT (`role:user`) and body
`code:"USERROLECR8"` succeeded (`200`, id 15 created). Confirmed present via a follow-up admin
`GET /api/coupons`.

**Steps to reproduce:**
1. Login as a non-admin user (`test@eshop.com`).
2. `POST /api/admin/coupons` with a valid body and that user's token.
3. Observe `200` and a new coupon id; confirm via an admin `GET /api/coupons` that the coupon exists.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
line 457, `POST /api/admin/coupons` — carries only `authenticateToken`, never inspects
`req.user.role`.

**Evidence:** raw request/response capture,
[`evidence/fr17-raw-execution-log.txt`](../out/reports/FR-17-coupon-crud/bug-reports/evidence/fr17-raw-execution-log.txt) lines 153–163.

---

## Not filed as a bug (untested, not a confirmed defect)

`DELETE /api/admin/coupons/:id`'s role check was **not** executed with a `role='user'` token in
this pass (scope decision recorded in the domain-testing report's coverage rationale, mirroring
FR-15's identical reasoning: all three coupon routes share the exact same middleware shape, so
this sub-state was tested once on View and once on Create, not repeated a third time). Given
`BUG-17-007`/`008` above, it is highly likely `DELETE` has the same gap — but per MODEL ≠ ORACLE
and Stage 1's own discipline, this is stated as a strong suspicion, not filed as a confirmed
defect, since it was never actually executed.

## Stage 7 — Summary

**Executed:** 31 frozen cases (15 EP + 16 BVA). **PASS:** 15. **FAIL:** 16, all confirmed as
real defects (no failure was rejected as a test/setup artifact) and grouped into **8 confirmed
defects**.

**By severity:** Critical — 1 (`BUG-17-008`, `POST /api/admin/coupons` access control). High —
2 (`BUG-17-003` `discount_value` validation, `BUG-17-007` `GET /api/coupons` access control).
Medium — 5 (`BUG-17-001` `code`, `BUG-17-002` `type`, `BUG-17-004` `expired_at`, `BUG-17-005`
`min_order_amount`, `BUG-17-006` `max_uses_per_user` asymmetry).

**Evidence basis:** all 8 confirmed defects are `spec`-grounded — every expected result traces
directly to a `README.md` citation (FR-17 line 216 for the six field constraints, or line 215 +
FR-12 lines 176–179 + `SEC-02`/`SEC-03` for the two access-control defects). No
assumption-grounded claims and no reclassifications between the two categories in this scope
(Assumption A1 was used only to pick a concrete BVA value for a PASS case, not as any confirmed
defect's oracle).

**Stage 6 human gate: approved 2026-07-07** (user: "Approve." — blanket approval of all 8
presented drafts, no report held back). All 8 promoted verbatim to
`out/reports/FR-17-coupon-crud/bug-reports/report.md` and filed as GitHub issues
[#17](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/17)–[#24](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/24)
(same day, `gh` already authenticated, Issues already enabled).
