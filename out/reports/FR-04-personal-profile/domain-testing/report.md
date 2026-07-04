# FR-04 — Domain Testing Report

## Testing Model reference

- Variables: `name`, `phone`, `shipping_address`; forbidden: `role`; immutable: `email` — see
  `work/FR-04-personal-profile/testing-model.md` (accepted 2026-07-04).
- Assumptions: `work/FR-04-personal-profile/assumptions.md` — A1/A2/A3 accepted; A4 rejected
  and reframed (no assumption needed for `phone`'s oracle — see below and BVA report).
- Decision Table: **skipped**. FR-04 has no combining conditions — each field (`name`, `phone`,
  `shipping_address`, `role`, `email`) is validated/checked independently; no rule requires two
  or more conditions to hold jointly (contrast with FR-09's 5 combined coupon conditions). Per
  architecture.md §2.3/§5.3, a table is only drawn where it changes downstream action; here it
  would not.

## Equivalence Partitioning — Test Cases

### TC-04-EP-001 — Valid profile update (happy path, all three fields)

| Field | Value |
|---|---|
| **Technique** | EP — valid class, all three variables simultaneously. |
| **Preconditions** | User `test@eshop.com` authenticated (JWT). |
| **Input** | `PUT /api/users/me` `{"name":"Nguyen Van A","phone":"0912345678","shipping_address":"123 Le Loi, TP.HCM"}`. |
| **Steps** | 1. Login. 2. `PUT /api/users/me` with the input above. 3. `GET /api/users/me` to read back. |
| **Expected** | 200 response; `GET /api/users/me` returns `name="Nguyen Van A"`, `phone="0912345678"`, `shipping_address="123 Le Loi, TP.HCM"`. |
| **`expected_source`** | `spec` — `README.md` FR-04 line 64 (these three fields are user-updatable). |
| **Status** | frozen |

### TC-04-EP-002 — `name` empty string (invalid class)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `name`. |
| **Preconditions** | User authenticated. |
| **Input** | `PUT /api/users/me` `{"name":"","phone":"0912345678","shipping_address":"123 Le Loi"}`. |
| **Steps** | 1. Login. 2. `PUT /api/users/me` with `name: ""`. 3. `GET /api/users/me`. |
| **Expected** | The update is rejected, or if accepted, `name` does not end up persisted as an empty string (per accepted assumption [[A2]]). Because the SUT provides no documented error-response contract for this case, the frozen expectation is stated as the **outcome**: `GET /api/users/me` must not return `name=""`. |
| **`expected_source`** | `assumption: A2` (accepted 2026-07-04, `work/FR-04-personal-profile/assumptions.md`). |
| **Status** | frozen |

### TC-04-EP-003 — `shipping_address` empty string (valid class)

| Field | Value |
|---|---|
| **Technique** | EP — valid class for `shipping_address` (per accepted [[A3]]). |
| **Preconditions** | User authenticated. |
| **Input** | `PUT /api/users/me` `{"name":"Nguyen Van A","phone":"0912345678","shipping_address":""}`. |
| **Steps** | 1. Login. 2. `PUT /api/users/me` with `shipping_address: ""`. 3. `GET /api/users/me`. |
| **Expected** | 200 response; `GET /api/users/me` returns `shipping_address=""` (empty is accepted, not coerced to `null` or rejected). |
| **`expected_source`** | `assumption: A3` (accepted 2026-07-04). |
| **Status** | frozen |

### TC-04-EP-004 — `phone` spec-invalid value persists via direct API call (API-path)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class for `phone` (wrong leading digit), API-path per the reframed oracle (no assumption; see `testing-model.md` `phone` variable and BVA report for the full boundary treatment). |
| **Preconditions** | User authenticated. |
| **Input** | `PUT /api/users/me` `{"name":"Nguyen Van A","phone":"1912345678","shipping_address":"123 Le Loi"}` — `1912345678` does not start with `0`: spec-invalid per line 65. |
| **Steps** | 1. Login. 2. `PUT /api/users/me` with the spec-invalid phone. 3. `GET /api/users/me`. |
| **Expected** | `phone` is **not** persisted as `1912345678` — the SUT must not end up storing a value that its own spec (line 65) defines as invalid, regardless of which layer would have been expected to catch it. |
| **`expected_source`** | `spec` — `README.md` FR-04 line 65 (validity definition applied path-agnostically). |
| **Status** | frozen |

### TC-04-EP-005 — Role injection is rejected (forbidden field)

| Field | Value |
|---|---|
| **Technique** | EP — negative test on forbidden field `role`. |
| **Preconditions** | User `test@eshop.com` (role `user`) authenticated. |
| **Input** | `PUT /api/users/me` `{"name":"Nguyen Van A","phone":"0912345678","shipping_address":"123 Le Loi","role":"admin"}`. |
| **Steps** | 1. Login as a `user`-role account. 2. `PUT /api/users/me` including `role: "admin"`. 3. `GET /api/users/me` (and/or re-login) to check the stored `role`. |
| **Expected** | Stored `role` remains `user`; the `role` field in the request has no effect. |
| **`expected_source`** | `spec` — `README.md` line 67 + SEC-06 (line 283). |
| **Status** | frozen |

### TC-04-EP-006 — Email immutability (immutable field)

| Field | Value |
|---|---|
| **Technique** | EP — negative test on immutable field `email`. |
| **Preconditions** | User authenticated. |
| **Input** | `PUT /api/users/me` `{"name":"Nguyen Van A","phone":"0912345678","shipping_address":"123 Le Loi","email":"changed@eshop.com"}`. |
| **Steps** | 1. Login. 2. `PUT /api/users/me` including a different `email`. 3. `GET /api/users/me`. |
| **Expected** | Stored `email` remains `test@eshop.com`; the `email` field in the request has no effect. |
| **`expected_source`** | `spec` — `README.md` line 66. |
| **Status** | frozen |

## Coverage rationale

Covers the valid class for all three manageable fields jointly (TC-001), the one concrete
invalid/valid boundary identified for `name`/`shipping_address` via accepted assumptions
(TC-002/003), one representative `phone` invalid class via the API path (TC-004, expanded with
the full boundary set in the BVA report), and both negative-space targets identified in Phase 0/1
(forbidden `role`, immutable `email` — TC-005/006). Not covered here: exhaustive `phone` length/
leading-digit boundaries (deferred to the BVA report, same variable) and the UI-path check for
`phone` (also in the BVA report, since it is inherently a boundary-focused comparison between
spec, frontend regex, and backend behavior).

## AI Gap Analysis

To be completed after Phase 3 execution — recorded here once actual results are in, per plan
Step 4.6 (record any case/bug the AI missed and why).
