# FR-17 — Domain Testing Report

## Testing Model reference

- Variables: `code`, `type`, `discount_value`, `expired_at`, `min_order_amount`,
  `max_uses_per_user`; forbidden state: actor/role for View/Create/Delete — see
  `work/FR-17-coupon-crud/testing-model.md` (accepted 2026-07-07).
- Assumptions: `work/FR-17-coupon-crud/assumptions.md` — A1 accepted (`discount_value` BVA
  granularity); A2 rejected (`expired_at` must-be-future claim, contradicted by the seeded
  `EXPIRED` coupon); A3 rejected (`code` case-sensitivity of uniqueness — logged only as an
  observation in the Gap Analysis below, not a test case).
- **No edit-isolation postcondition** (unlike FR-15): no `PUT`/edit route exists for coupons —
  consistent with FR-17's spec listing only Thêm/Xem/Xóa, not modeled as a gap.
- Decision Table: **skipped**. Checked for real (Stage 5.1): all six field variables are each
  validated (or, in the SUT's current state, not validated at all) completely independently —
  no code path in `GET /api/coupons`, `POST /api/admin/coupons`, or `DELETE
  /api/admin/coupons/:id` branches on a *combination* of these conditions. The only
  combination-shaped operator anywhere on this surface is `max_uses_per_user || 1`
  (server.js L474) — a single-variable JS falsy-fallback that depends on nothing but
  `max_uses_per_user`'s own value; `code`, `type`, `discount_value`, `expired_at`, and
  `min_order_amount` have no bearing on whether it fires. The actor/role forbidden state also
  acts independently — there is no role check anywhere, so it never interacts with field
  validity. A request with an invalid `code` **and** an invalid `type` **and** a non-admin actor
  is simply persisted/rejected exactly as if only one were invalid, since none is actually
  checked. Per architecture.md §2.3/§5.3, a table is only drawn where it would change downstream
  action; here it would not (same shape as FR-04/FR-08(original)/FR-15).

## Equivalence Partitioning — Test Cases

### TC-17-EP-001 — Happy path: valid create as admin

| Field | Value |
|---|---|
| **Technique** | EP — valid class, all six field variables + valid actor state, combined. |
| **Model reference** | `code`, `type`, `discount_value`, `expired_at`, `min_order_amount`, `max_uses_per_user`, actor/role. |
| **Preconditions** | Admin (`admin@eshop.com`) authenticated (JWT, `role=admin`). |
| **Input** | `POST /api/admin/coupons` `{"code":"EPTEST001","type":"percent","discount_value":15,"min_order_amount":200000,"expired_at":"2099-06-30","max_uses_per_user":2}`. |
| **Steps** | 1. Login as admin. 2. `POST /api/admin/coupons` with the input above. 3. `GET /api/coupons` (as admin) to confirm the new coupon appears with matching fields. |
| **Expected result** | Creation succeeds; the coupon list contains a coupon matching all submitted fields exactly. |
| **`expected_source`** | `spec` — `README.md` FR-17 lines 215–216 (admin can add a coupon meeting the six constraints). |
| **Status** | frozen |

### TC-17-EP-002 — `code` duplicate (invalid class, uniqueness)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `code` (uniqueness), isolated from other axes (admin actor, other fields valid). |
| **Model reference** | `code` variable. |
| **Preconditions** | Admin authenticated. A throwaway coupon `DUPTEST1` is first created via admin `POST` (avoids risking a seeded coupon row if the duplicate is, contrary to spec, accepted). |
| **Input** | `POST /api/admin/coupons` with `code:"DUPTEST1"` again (identical to the throwaway just created), other fields valid. |
| **Steps** | 1. Login as admin. 2. `POST` a throwaway coupon `code:"DUPTEST1"`. 3. `POST` again with the exact same `code:"DUPTEST1"`. 4. `GET /api/coupons` (as admin) to check whether two rows now share that code. |
| **Expected result** | The second create is rejected; no second coupon with `code:"DUPTEST1"` is persisted. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 216 ("duy nhất"). |
| **Status** | frozen |

### TC-17-EP-003 — `code` omitted entirely (invalid class, required-ness)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `code` (required-ness, distinct from the uniqueness invalid class in TC-17-EP-002). |
| **Model reference** | `code` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/admin/coupons` with `code` key omitted, other fields valid. |
| **Steps** | 1. Login as admin. 2. `POST` with no `code` key. 3. `GET /api/coupons` (as admin) to check for any coupon created with a null/blank code around this time. |
| **Expected result** | The create is rejected, or if created, `code` must not be persisted as `null`/absent — a required field must carry a genuine value. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 216 (required). |
| **Status** | frozen |

### TC-17-EP-004 — `type` invalid (not a member of `{percent, fixed}`)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `type` (general representative; exact enum boundary is in the BVA report). |
| **Model reference** | `type` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/admin/coupons` `{"code":"EPTEST004","type":"discount","discount_value":10,"min_order_amount":0,"expired_at":"2099-06-30","max_uses_per_user":1}`. |
| **Steps** | 1. Login as admin. 2. `POST` with `type:"discount"`. 3. `GET /api/coupons` (as admin) for the created row. |
| **Expected result** | The create is rejected, or if created, `type` must not be persisted as `"discount"` (a non-enum-member value). |
| **`expected_source`** | `spec` — `README.md` FR-17 line 216. |
| **Status** | frozen |

### TC-17-EP-005 — `type` omitted entirely

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `type` (required-ness, distinct literal input from TC-17-EP-004). |
| **Model reference** | `type` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/admin/coupons` with `type` key omitted, other fields valid. |
| **Steps** | 1. Login as admin. 2. `POST` with no `type` key. 3. `GET /api/coupons` (as admin) for the created row — specifically check whether `type` reads `"percent"` (the schema's `DEFAULT`, if it fired) or `null` (if the column-default-suppression finding holds). |
| **Expected result** | The create is rejected, or if created, `type` must not be persisted as `null`/absent — must be a genuine `"percent"`/`"fixed"` value. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 216 (required). |
| **Status** | frozen |

### TC-17-EP-006 — `discount_value` invalid (negative)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `discount_value` (general representative; exact boundary is in the BVA report). |
| **Model reference** | `discount_value` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/admin/coupons` `{"code":"EPTEST006","type":"fixed","discount_value":-1000,"min_order_amount":0,"expired_at":"2099-06-30","max_uses_per_user":1}`. |
| **Steps** | 1. Login as admin. 2. `POST` with `discount_value:-1000`. 3. `GET /api/coupons` (as admin) for the created row. |
| **Expected result** | The create is rejected, or if created, `discount_value` must not be persisted as `-1000`. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 216. |
| **Status** | frozen |

### TC-17-EP-007 — `expired_at` omitted entirely

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `expired_at` (required-ness). |
| **Model reference** | `expired_at` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/admin/coupons` with `expired_at` key omitted, other fields valid. |
| **Steps** | 1. Login as admin. 2. `POST` with no `expired_at` key. 3. `GET /api/coupons` (as admin) for the created row. |
| **Expected result** | The create is rejected, or if created, `expired_at` must not be persisted as `null`/absent. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 216 (required). |
| **Status** | frozen |

### TC-17-EP-008 — `min_order_amount` invalid (negative)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `min_order_amount` (general representative; exact boundary is in the BVA report). |
| **Model reference** | `min_order_amount` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/admin/coupons` `{"code":"EPTEST008","type":"percent","discount_value":10,"min_order_amount":-500,"expired_at":"2099-06-30","max_uses_per_user":1}`. |
| **Steps** | 1. Login as admin. 2. `POST` with `min_order_amount:-500`. 3. `GET /api/coupons` (as admin) for the created row. |
| **Expected result** | The create is rejected, or if created, `min_order_amount` must not be persisted as `-500`. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 216. |
| **Status** | frozen |

### TC-17-EP-009 — `min_order_amount` omitted entirely

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `min_order_amount` (required-ness, distinct from the numeric boundary in the BVA report). |
| **Model reference** | `min_order_amount` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/admin/coupons` with `min_order_amount` key omitted, other fields valid. |
| **Steps** | 1. Login as admin. 2. `POST` with no `min_order_amount` key. 3. `GET /api/coupons` (as admin) for the created row — check whether it reads `0` (the schema's `DEFAULT`, if it fired) or `null` (if the column-default-suppression finding holds). |
| **Expected result** | The create is rejected, or if created, `min_order_amount` must not be persisted as `null`/absent — a required field must carry a genuine value, regardless of what the schema default might otherwise suggest. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 216 (required). |
| **Status** | frozen |

### TC-17-EP-010 — `max_uses_per_user` invalid, truthy-negative (general representative)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `max_uses_per_user` (general representative of the truthy-invalid branch of the falsy/truthy asymmetry; the full boundary set including `0`/`null`/omitted is in the BVA report). |
| **Model reference** | `max_uses_per_user` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/admin/coupons` `{"code":"EPTEST010","type":"percent","discount_value":10,"min_order_amount":0,"expired_at":"2099-06-30","max_uses_per_user":-5}`. |
| **Steps** | 1. Login as admin. 2. `POST` with `max_uses_per_user:-5`. 3. `GET /api/coupons` (as admin) for the created row. |
| **Expected result** | The create is rejected, or if created, `max_uses_per_user` must not be persisted as `-5` (a value `< 1`). |
| **`expected_source`** | `spec` — `README.md` FR-17 line 216. |
| **Status** | frozen |

### TC-17-EP-011 — `GET /api/coupons` with no Authorization header

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, actor/role forbidden state (View), sub-state: header entirely absent. |
| **Model reference** | Actor/role forbidden state (View). |
| **Preconditions** | None (no token sent at all). |
| **Input** | `GET /api/coupons` with **no** `Authorization` header. |
| **Steps** | 1. Send the request above with no token. |
| **Expected result** | Request is rejected (not a `200` with the coupon list); no coupon data is disclosed to an unauthenticated caller. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 215 + §9 `SEC-02`. |
| **Status** | frozen |

### TC-17-EP-012 — `GET /api/coupons` with valid JWT, `role='user'`

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, actor/role forbidden state (View), sub-state: authenticated but wrong role (the highest-signal sub-state, isolating the missing *role* check specifically — this is the dimension FR-17 adds beyond FR-15's forbidden state, since FR-15 excluded View entirely). |
| **Model reference** | Actor/role forbidden state (View). |
| **Preconditions** | `test@eshop.com` (role `user`) authenticated. |
| **Input** | `GET /api/coupons` with `Authorization: Bearer <user JWT>`. |
| **Steps** | 1. Login as `test@eshop.com`. 2. `GET /api/coupons` with the user's token. |
| **Expected result** | Request is rejected; a non-admin authenticated user must not be able to view the coupon list. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 215 + §9 `SEC-03`. |
| **Status** | frozen |

### TC-17-EP-013 — `POST /api/admin/coupons` with no Authorization header

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, actor/role forbidden state (Create), sub-state: header absent. |
| **Model reference** | Actor/role forbidden state (Create). |
| **Preconditions** | None. |
| **Input** | `POST /api/admin/coupons` with **no** `Authorization` header, body `{"code":"UNAUTHCR8","type":"percent","discount_value":10,"min_order_amount":0,"expired_at":"2099-06-30","max_uses_per_user":1}`. |
| **Steps** | 1. Send the request above with no token. 2. Separately, login as admin and `GET /api/coupons` to confirm no coupon `code:"UNAUTHCR8"` exists. |
| **Expected result** | Request is rejected; no coupon matching the submitted code is created. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 215 + FR-12 lines 176–179 + §9 `SEC-02`. |
| **Status** | frozen |

### TC-17-EP-014 — `POST /api/admin/coupons` with valid JWT, `role='user'`

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, actor/role forbidden state (Create), sub-state: wrong role. |
| **Model reference** | Actor/role forbidden state (Create). |
| **Preconditions** | `test@eshop.com` (role `user`) authenticated. |
| **Input** | `POST /api/admin/coupons` with `Authorization: Bearer <user JWT>`, body `{"code":"USERROLECR8","type":"percent","discount_value":10,"min_order_amount":0,"expired_at":"2099-06-30","max_uses_per_user":1}`. |
| **Steps** | 1. Login as `test@eshop.com`. 2. `POST /api/admin/coupons` with the user's token. 3. Login as admin, `GET /api/coupons`, confirm no coupon `code:"USERROLECR8"` exists. |
| **Expected result** | Request is rejected; no coupon matching the submitted code is created. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 215 + FR-12 lines 176–179 + §9 `SEC-03`. |
| **Status** | frozen |

### TC-17-EP-015 — `DELETE /api/admin/coupons/:id` with no Authorization header

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, actor/role forbidden state (Delete), sub-state: header absent. |
| **Model reference** | Actor/role forbidden state (Delete). |
| **Preconditions** | A throwaway coupon is first created via authenticated admin `POST` (same reasoning as TC-17-EP-002 — deleting a real seeded coupon on a confirmed bug would corrupt the baseline other cases rely on), recording its id/code. |
| **Input** | `DELETE /api/admin/coupons/<throwaway id>` with **no** `Authorization` header. |
| **Steps** | 1. Create the throwaway coupon as admin; record its id. 2. Send the `DELETE` above with no token. 3. Login as admin, `GET /api/coupons`, confirm the throwaway coupon still exists. |
| **Expected result** | Request is rejected; the throwaway coupon still exists afterward. |
| **`expected_source`** | `spec` — `README.md` FR-17 line 215 + FR-12 lines 176–179 + §9 `SEC-02`. |
| **Status** | frozen |

## Coverage rationale

Covers the valid class for all six constrained fields jointly (EP-001), one representative
invalid class per field beyond the exact boundary values (deferred to the BVA report):
`code` uniqueness (EP-002) and required-ness (EP-003), `type` invalid-member (EP-004) and
required-ness (EP-005), `discount_value` negative (EP-006), `expired_at` required-ness
(EP-007), `min_order_amount` negative (EP-008) and required-ness (EP-009), `max_uses_per_user`
truthy-invalid (EP-010, the branch of the falsy/truthy asymmetry the code's own fallback does
**not** protect against — the full asymmetry set is in the BVA report). The actor/role
forbidden state is covered across all three operations for its strongest sub-state (no header:
EP-011/013/015) plus the single most diagnostic wrong-role sub-state, run on both **View**
(EP-012 — the new dimension FR-17 adds beyond FR-15's scope) and **Create** (EP-014, mirroring
FR-15's own choice of where to run this sub-state once).

**Scope decision, actor/role sub-states across operations:** `role='user'` is not repeated for
`DELETE` — all three coupon routes carry the identical shape (`authenticateToken` only, no role
check anywhere), so a third repetition of the same sub-state on the third route adds no new
information, the same reasoning FR-15 used for its own three write routes. `role='user'` **is**
tested on both View and Create (not just once, unlike FR-15) because View is a genuinely new
forbidden-state dimension for this feature, not an extension of an already-tested shape.

**Note on `code`'s second-enforcement-path finding:** TC-17-EP-002 itself is where the
DB-`UNIQUE`-only enforcement mechanism (server.js L476–478's raw `500` on constraint violation)
gets observed directly — no separate case is needed for it.

## AI Gap Analysis

Cases/classes not designed in this pass, and why. **None of the items below were executed
against the SUT — they are untested hypotheses, not confirmed defects.**

1. **Type-confusion (wrong JSON type, not just wrong value).** All invalid inputs in this pass
   are valid JSON of the expected type carrying an invalid *value* (e.g. `discount_value:-1000`,
   not `discount_value:"abc"`). **Why missed:** same feature-complexity triage FR-04/FR-15
   recorded for their own type-confusion gaps — prioritized the field-validity and
   forbidden-state risks Phase 0/1 discovery already surfaced over an open-ended type-fuzzing
   pass.
2. **`code` case-sensitivity of uniqueness.** Raised as Assumption A3 in `assumptions.md` and
   explicitly **rejected** at Stage 2 — no citation, no defensible reframing from "duy nhất" to
   a case-folding rule. Retained here only as an observation: whether `save10` and `SAVE10` are
   treated as distinct codes by the live DB (SQLite's `UNIQUE` is case-sensitive by default,
   `database.js` line 31) is a genuine open question worth a human's attention, but produces no
   frozen test case under MODEL ≠ ORACLE.
3. **`coupon_usage` referential integrity on `DELETE`.** The continuation handoff flagged this
   explicitly: does deleting a coupon that has usage history leave a dangling `coupon_id`
   reference, and does that matter? **Why excluded:** constructing that precondition (a coupon
   with actual usage history) requires exercising `POST /api/coupon-usage` and the
   `/api/apply-coupon` flow — both FR-09 machinery, not FR-17's own surface. Testing "delete
   with no usage history" is fully covered by this report's own cases; "delete with usage
   history" would require reaching into unassigned functionality just to set up the scenario,
   so it is excluded rather than tested via a workaround.
4. **Stored-XSS in `code` (`SEC-04`).** `code` is rendered in the admin table (`App.jsx` line
   731) via JSX text interpolation, which React escapes by default (no `dangerouslySetInnerHTML`
   used) — unlike FR-15's `name`/`description`, this display path has no obvious injection
   vector to begin with. **Why missed:** low prior probability given the rendering mechanism,
   and — same as FR-04/FR-15 — a cross-cutting security rule better tested once across all
   user-input fields than piecemeal per feature.
5. **Concurrent duplicate-`code` race (two simultaneous `POST`s with the same code).** Not
   tested — feature-complexity triage; the DB's `UNIQUE` constraint is expected to serialize
   this correctly regardless, and no spec text calls out concurrent-request behavior for FR-17.
