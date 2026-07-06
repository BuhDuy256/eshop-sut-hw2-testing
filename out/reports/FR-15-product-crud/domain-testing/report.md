# FR-15 — Domain Testing Report

## Testing Model reference

- Variables: `name`, `price`, `category_id`; forbidden state: actor/role for
  Create/Update/Delete; postcondition: edit-isolation — see
  `work/FR-15-product-crud/testing-model.md` (accepted 2026-07-06).
- Assumptions: `work/FR-15-product-crud/assumptions.md` — A1 accepted (price BVA granularity);
  A2 rejected (price-as-string response-type claim, no citation/reframing — logged only as an
  observation in the Gap Analysis below, not a test case).
- Decision Table: **skipped**. Checked for real (Stage 5.1): `name`, `price`, `category_id`,
  and the actor/role forbidden state are each validated (or, in the SUT's current state, not
  validated at all) completely independently — no code path anywhere in `POST/PUT/DELETE
  /api/products` branches differently depending on a *combination* of these conditions. A
  request with an invalid `name` **and** an invalid `price` **and** a non-admin actor is simply
  persisted with all three invalid values verbatim, exactly as if only one were invalid — no
  rule requires two or more conditions to hold jointly. Per architecture.md §2.3/§5.3, a table
  is only drawn where it would change downstream action; here it would not (same shape as
  FR-04/FR-08).

## Equivalence Partitioning — Test Cases

### TC-15-EP-001 — Happy path: valid create as admin

| Field | Value |
|---|---|
| **Technique** | EP — valid class, all three field variables + valid actor state, combined. |
| **Model reference** | `name`, `price`, `category_id`, actor/role. |
| **Preconditions** | Admin (`admin@eshop.com`) authenticated (JWT, `role=admin`). |
| **Input** | `POST /api/products` `{"name":"BVA Test Product 001","price":500000,"description":"test","imageUrl":"https://placehold.co/300","category_id":2}`. |
| **Steps** | 1. Login as admin. 2. `POST /api/products` with the input above. 3. `GET /api/products/:id` for the returned id to read back. |
| **Expected result** | 200/creation response; `GET` returns `name`, `price`, `category_id` matching the input exactly. |
| **`expected_source`** | `spec` — `README.md` FR-15 lines 193/195–197 (admin can add a product meeting the three constraints). |
| **Status** | frozen |

### TC-15-EP-002 — `name` empty string (invalid class)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `name`, isolated from the actor axis (admin used, so any failure is attributable only to the field rule). |
| **Model reference** | `name` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/products` `{"name":"","price":500000,"description":"test","imageUrl":"https://placehold.co/300","category_id":2}`. |
| **Steps** | 1. Login as admin. 2. `POST /api/products` with `name:""`. 3. `GET /api/products` (list) to check whether a product with an empty name now exists. |
| **Expected result** | The create is rejected, or — because the SUT has no documented error-response contract for this case — if a product is nonetheless created, it must not be persisted with `name=""`. Frozen expectation stated as the outcome, per `README.md` line 195. |
| **`expected_source`** | `spec` — `README.md` FR-15 line 195. |
| **Status** | frozen |

### TC-15-EP-003 — `name` omitted entirely (invalid class, distinct from empty string)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `name`, distinct literal input from TC-15-EP-002 (field absent vs. field present-but-empty). |
| **Model reference** | `name` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/products` `{"price":500000,"description":"test","imageUrl":"https://placehold.co/300","category_id":2}` — `name` key absent. |
| **Steps** | 1. Login as admin. 2. `POST /api/products` with no `name` key. 3. `GET /api/products` (list) to check the created row. |
| **Expected result** | The create is rejected, or if created, `name` must not be persisted as `null`/absent — same outcome-level standard as TC-15-EP-002. |
| **`expected_source`** | `spec` — `README.md` FR-15 line 195 (required). |
| **Status** | frozen |

### TC-15-EP-004 — `price` invalid (negative)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `price` (general representative, not a boundary value — exact boundary is in the BVA report). |
| **Model reference** | `price` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/products` `{"name":"BVA Test Product 004","price":-500000,"description":"test","imageUrl":"https://placehold.co/300","category_id":2}`. |
| **Steps** | 1. Login as admin. 2. `POST /api/products` with `price:-500000`. 3. `GET /api/products/:id` for the returned id. |
| **Expected result** | The create is rejected, or if created, `price` must not be persisted as `-500000` (a negative value). |
| **`expected_source`** | `spec` — `README.md` FR-15 line 196. |
| **Status** | frozen |

### TC-15-EP-005 — `category_id` invalid (nonexistent)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `category_id` (general representative; exact enum boundary is in the BVA report). |
| **Model reference** | `category_id` variable. |
| **Preconditions** | Admin authenticated. |
| **Input** | `POST /api/products` `{"name":"BVA Test Product 005","price":500000,"description":"test","imageUrl":"https://placehold.co/300","category_id":999}`. |
| **Steps** | 1. Login as admin. 2. `POST /api/products` with `category_id:999` (no such category exists). 3. `GET /api/products/:id` for the returned id. |
| **Expected result** | The create is rejected, or if created, `category_id` must not be persisted as `999` (a nonexistent category). |
| **`expected_source`** | `spec` — `README.md` FR-15 line 197. |
| **Status** | frozen |

### TC-15-EP-006 — `POST /api/products` with no Authorization header

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, actor/role forbidden state (sub-state: header entirely absent). Field values held valid so any rejection is attributable only to the actor state. |
| **Model reference** | Actor/role forbidden state. |
| **Preconditions** | None (no token sent at all). |
| **Input** | `POST /api/products` with **no** `Authorization` header, body `{"name":"Unauth Create Test","price":100000,"description":"test","imageUrl":"https://placehold.co/300","category_id":1}`. |
| **Steps** | 1. Send the request above with no token. 2. `GET /api/products` (list) to confirm no product named `"Unauth Create Test"` exists. |
| **Expected result** | Request is rejected (not a creation-success response); no product matching the submitted name is created. |
| **`expected_source`** | `spec` — `README.md` FR-12 lines 176–179 + §9 `SEC-02`. |
| **Status** | frozen |

### TC-15-EP-007 — `POST /api/products` with valid JWT, `role='user'`

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, actor/role forbidden state (sub-state: authenticated but wrong role — the highest-signal sub-state, since it isolates the missing *role check* specifically, not just a missing token check). |
| **Model reference** | Actor/role forbidden state. |
| **Preconditions** | `test@eshop.com` (role `user`) authenticated. |
| **Input** | `POST /api/products` with `Authorization: Bearer <user JWT>`, body `{"name":"User Role Create Test","price":100000,"description":"test","imageUrl":"https://placehold.co/300","category_id":1}`. |
| **Steps** | 1. Login as `test@eshop.com`. 2. `POST /api/products` with the user's token. 3. `GET /api/products` (list) to confirm no product named `"User Role Create Test"` exists. |
| **Expected result** | Request is rejected; no product matching the submitted name is created. |
| **`expected_source`** | `spec` — `README.md` FR-12 lines 176–179 + §9 `SEC-03`. |
| **Status** | frozen |

### TC-15-EP-008 — `PUT /api/products/:id` with no Authorization header

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, actor/role forbidden state, Update operation. |
| **Model reference** | Actor/role forbidden state. |
| **Preconditions** | A throwaway product is first created via an **authenticated admin** `POST` (to avoid risking a confirmed bug corrupting a seeded product), capturing its id and original field values. |
| **Input** | `PUT /api/products/<throwaway id>` with **no** `Authorization` header, body `{"name":"HACKED","price":1,"description":"test","imageUrl":"https://placehold.co/300","category_id":1}`. |
| **Steps** | 1. Create the throwaway product as admin; record its original `name`/`price`/`category_id`. 2. Send the `PUT` above with no token. 3. `GET /api/products/<throwaway id>` to compare against the recorded original values. |
| **Expected result** | Request is rejected; the throwaway product's fields are unchanged from their recorded original values. |
| **`expected_source`** | `spec` — `README.md` FR-12 lines 176–179 + §9 `SEC-02`. |
| **Status** | frozen |

### TC-15-EP-009 — `DELETE /api/products/:id` with no Authorization header

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, actor/role forbidden state, Delete operation. |
| **Model reference** | Actor/role forbidden state. |
| **Preconditions** | A throwaway product is first created via an **authenticated admin** `POST` (same reasoning as TC-15-EP-008 — deleting a real seeded product on a confirmed bug would corrupt the baseline other cases rely on). |
| **Input** | `DELETE /api/products/<throwaway id>` with **no** `Authorization` header. |
| **Steps** | 1. Create the throwaway product as admin. 2. Send the `DELETE` above with no token. 3. `GET /api/products/<throwaway id>` to confirm the product still exists. |
| **Expected result** | Request is rejected; the throwaway product still exists afterward. |
| **`expected_source`** | `spec` — `README.md` FR-12 lines 176–179 + §9 `SEC-02`. |
| **Status** | frozen |

### TC-15-EP-010 — Edit-isolation, backend data path

| Field | Value |
|---|---|
| **Technique** | EP — valid-class postcondition check, backend enforcement path. |
| **Model reference** | Edit-isolation postcondition. |
| **Preconditions** | Two throwaway products created via authenticated admin `POST`: `P_target` and `P_sibling`, each with recorded original `name`/`price`/`category_id`. |
| **Input** | `PUT /api/products/<P_target id>` as admin, body changing `name`/`price` to new values. |
| **Steps** | 1. Create `P_target` and `P_sibling`, recording both's original values. 2. `PUT /api/products/<P_target id>` with new `name`/`price`. 3. `GET /api/products/<P_sibling id>` and compare to its recorded original values. |
| **Expected result** | `P_sibling`'s `name`/`price`/`category_id` are byte-identical to their recorded original values; only `P_target` changed. |
| **`expected_source`** | `spec` — `README.md` FR-15 line 198. |
| **Status** | frozen |

### TC-15-EP-011 — Edit-isolation, admin-UI path (second enforcement path)

| Field | Value |
|---|---|
| **Technique** | EP — valid-class postcondition check, admin-frontend enforcement path (Stage 4.3: a second, independent path for the same postcondition, since Phase 0 discovery found the admin UI's local-state handling disagrees with the backend). |
| **Model reference** | Edit-isolation postcondition, admin-frontend code note in `testing-model.md`. |
| **Preconditions** | Admin logged into `frontend-admin` (`http://localhost:5174`) in a real browser; at least 2 products visible in the product list/table. |
| **Input** | Use the "Sửa sản phẩm" (edit) form on one visible product, changing only its `name`, then submit. |
| **Steps** | 1. Log into the admin panel as admin. 2. Note the currently-displayed `name` of a second, different product (the "sibling") in the table. 3. Click edit on the first product, change its `name`, submit. 4. Without reloading the page, observe the sibling product's displayed `name` in the table. |
| **Expected result** | The sibling product's displayed `name` in the table remains its original value — unchanged by editing the other product. |
| **`expected_source`** | `spec` — `README.md` FR-15 line 198 (the postcondition is a user-observable requirement, not only a backend-storage one). |
| **Status** | frozen |
| **Execution note** | This case requires actual browser interaction (Model C's evidence standard for UI-level bugs: a browser screenshot), not `curl` — unlike all other cases in this report. |

## Coverage rationale

Covers the valid class for all three constrained fields jointly (EP-001), one representative
invalid class per field (EP-002/003 for `name`'s two distinct empty/absent literal states,
EP-004 for `price`, EP-005 for `category_id` — exact boundary values deferred to the BVA
report), the actor/role forbidden state across all three write operations for its strongest
sub-state (no header: EP-006/008/009) plus the single most diagnostic wrong-role sub-state
(EP-007, run once on `POST` only), and both enforcement paths of the edit-isolation
postcondition (EP-010 backend, EP-011 admin UI).

**Scope decision, actor/role sub-states across operations:** `role='user'` and
`invalid/expired JWT` are not repeated for `PUT`/`DELETE` — Phase 0 discovery confirmed all
three write routes carry *zero* middleware, an architecturally identical shape, so repeating
either sub-state on the other two routes would add no new information. This differs from
FR-08's checkout route, which genuinely branches on absent-vs-invalid token (401 vs. 403) and
so justified testing both there; FR-15's product routes have no token-parsing at all, so no
comparable branch exists to justify it here.

**Scope decision, dual-path testing:** unlike FR-04's `phone` (frontend regex actively
contradicts the spec's boundary, justifying separate UI-path and API-path cases), FR-15's admin
frontend does not enforce a *different* rule for `name`/`price`/`category_id` — it enforces the
same rule less completely (or not at all: `price` has no client-side check whatsoever). A
single API-path case per field therefore suffices for those three variables; the two-path
treatment is reserved for the edit-isolation postcondition, which has a genuine,
currently-disagreeing second enforcement point (see EP-011).

## AI Gap Analysis

Cases/classes not designed in this pass, and why. **None of the items below were executed
against the SUT — they are untested hypotheses, not confirmed defects.**

1. **`description`/`imageUrl` fields.** FR-15's own spec text (README lines 193–198) states no
   constraint on `description` or `imageUrl` at all — no required-ness, no format, no length.
   No case targets them. **Why:** nothing to test against; a field with zero spec-stated rule
   has no derivable oracle, and inventing one would violate MODEL ≠ ORACLE.
2. **Type-confusion (wrong JSON type, not just wrong value).** All `price`/`category_id` inputs
   in this pass are valid JSON numbers with an invalid *value*; none send a non-numeric type
   (e.g. `price: "abc"`, `category_id: null`, `name: 12345`). **Why missed:** same
   feature-complexity triage FR-04 recorded for its own type-confusion gap — prioritized the
   field-validity and forbidden-state risks Phase 0/1 discovery already surfaced over an
   open-ended type-fuzzing pass.
3. **`price`-as-string response-type anomaly (`GET /api/products/:id`, even ids).** Raised as
   Assumption A2 in `assumptions.md` and explicitly **rejected** at Stage 2 — no citation, no
   defensible reframing from the Add/Edit input-validity clause to a View-path response-type
   claim. Retained here only as an observation: `backend/server.js` line 162 returns `price` as
   a string for even-numbered product ids and a number for odd-numbered ones. This is a genuine
   code anomaly worth a human's attention, but produces no frozen test case under MODEL ≠
   ORACLE.
4. **Stored-XSS in `name`/`description`.** `README.md` SEC-04 requires safe escaping of
   user-input on display; both fields are rendered in the admin table and the public product
   listing. No case sends an HTML/script payload. **Why missed:** deliberately out of scope for
   this pass, same reasoning FR-04 recorded for its own SEC-04 gap — a cross-cutting security
   rule better tested once across all user-input fields than piecemeal per feature.
