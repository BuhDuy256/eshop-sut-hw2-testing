# FR-08 — Domain Testing Report

> Scope note: this report holds the Step-3 vertical-smoke case (`TC-08-001`, `total_amount`)
> plus the Continuation FR-08 Full pass below (auth state, cart-clearing), added 2026-07-04 via
> `domain-test-design` Stage 3 (EP). BVA is in the sibling `boundary-value-analysis/report.md`.
> `TC-08-001` is unchanged.
>
> **Correction, 2026-07-04 (same day):** this report originally also included FR-09's 5 coupon
> conditions (`TC-08-EP-005..011`) and a 7-row Decision Table (`TC-08-DT-002`). FR-09 is not
> one of the 4 assigned features (`docs/hw2-reqs/features-that-need-testing.md`) — the
> assigned coupon-related feature is FR-17 (admin Coupon CRUD), a different feature from FR-09
> (customer-facing coupon application). That content has been removed from this report; see
> the AI Audit for the corrective entry. No Decision Table is included here as a result — none
> of the remaining FR-08 variables (`total_amount`, auth-state, cart-clearing) have combining
> conditions, so Stage 5 is skipped with this one-line reason, the same way FR-04 skipped it.

## Testing Model reference

- Variable under test: `total_amount` — see `work/FR-08-checkout/testing-model.md` (accepted
  2026-07-04).
- Oracle precedence applied: `docs/implementation-plan/oracle-precedence.md`.

## Test Cases

### TC-08-001 — Forged `total_amount` must not override server-recomputed total

| Field | Value |
|---|---|
| **Technique** | Equivalence Partitioning — negative class (`total_amount != X`, specifically a forged low value). |
| **Model reference** | `total_amount` variable, `work/FR-08-checkout/testing-model.md`. |
| **Preconditions** | (1) User `test@eshop.com` is authenticated (valid JWT). (2) Cart is seeded to a known, real total: 1× "iPhone 15 Pro Max" (`product_id: 1`, `price: 30000000`), so the server-recomputed total `X = 30000000` VND. (Assumptions A1–A2 from the testing model.) |
| **Input** | `POST /api/checkout` with body `{"total_amount": 1, "shipping_address": "123 Le Loi, TP.HCM"}` — a shape-valid but forged value, `1 << X`. |
| **Steps** | 1. Login as `test@eshop.com`, capture JWT. 2. `POST /api/cart` with the product above to seed the cart to real total `X = 30000000`. 3. `POST /api/checkout` with `total_amount: 1` (forged). 4. `GET /api/orders/:id` (or `GET /api/orders/my-orders`) for the resulting order to read the persisted total. |
| **Expected result** | The persisted order's `total_amount` equals the server-recomputed `X = 30000000`; the client-supplied `1` has no effect on the stored value. If the checkout response echoes `total_amount`, it also equals `X`, not `1`. |
| **`expected_source`** | `spec` — `README.md` FR-08, line 107 (via `docs/implementation-plan/oracle-precedence.md`). |
| **Status** | **frozen** (committed before execution — see `git log`, commit `Step 3.2 frozen test case` precedes `Step 3.3 execution result`). |

---

## Continuation — FR-08 Full: Equivalence Partitioning Test Cases

> Model reference: `work/FR-08-checkout/testing-model.md`, "Extended scope" section
> (approved 2026-07-04). All expected results cite README FR-08/FR-09 directly, or the Stage-2
> reframings (A6, A7) recorded there — no case rests on A8 (that assumption was reframed away
> by choosing inputs where the percent formula's result is already an integer, see TC-08-EP-010).

### TC-08-EP-002 — Checkout with no Authorization header

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, auth-state variable (sub-path: header entirely absent). |
| **Model reference** | Auth state (checkout) variable. |
| **Preconditions** | None (the `authenticateToken` middleware runs before any cart/order logic, per Step 1.2's code-revealed note — cart state is irrelevant to this path). |
| **Input** | `POST /api/checkout` with **no** `Authorization` header, body `{"total_amount": 100000, "shipping_address": "123 Le Loi, TP.HCM"}`. |
| **Steps** | 1. Send the request above with no token. 2. Separately, log in as `test@eshop.com` and `GET /api/orders/my-orders` to confirm no new order exists. |
| **Expected result** | The request is rejected before any order is created; the response is not a checkout-success response, and no new order appears for `test@eshop.com`. |
| **`expected_source`** | `spec` — README FR-08 line 104, reframed per Assumption A6 (outcome-level: no order persisted; no specific status code asserted, since README states none). |
| **Status** | frozen. |

### TC-08-EP-003 — Checkout with invalid/expired JWT

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, auth-state variable (sub-path: token present but invalid). |
| **Model reference** | Auth state (checkout) variable. |
| **Preconditions** | None. |
| **Input** | `POST /api/checkout` with `Authorization: Bearer invalid.token.value`, same body as TC-08-EP-002. |
| **Steps** | Same as TC-08-EP-002, substituting the malformed token. |
| **Expected result** | Same as TC-08-EP-002 — no order persisted. |
| **`expected_source`** | `spec` — README FR-08 line 104, reframed per A6. |
| **Status** | frozen. |

### TC-08-EP-004 — Cart is cleared after a successful checkout

| Field | Value |
|---|---|
| **Technique** | EP — valid-class postcondition check (cart-clearing variable). |
| **Model reference** | Cart-clearing variable. |
| **Preconditions** | User `test@eshop.com` authenticated; cart empty at start (reseed if needed). |
| **Input** | 1 item added via `POST /api/cart`, then `POST /api/checkout` with a valid `total_amount`/`shipping_address`. |
| **Steps** | 1. Login. 2. `POST /api/cart` to add one product. 3. `GET /api/cart` — confirm non-empty. 4. `POST /api/checkout` with a valid body; confirm a success response. 5. `GET /api/cart` again. |
| **Expected result** | Step 5's cart is empty for this user. |
| **`expected_source`** | `spec` — README FR-08 line 108. |
| **Status** | frozen. |

---

## Coverage rationale

`TC-08-001` covers the single highest-risk negative equivalence class for `total_amount`
(client-forged value far below the real cart total). The Continuation pass above adds auth
state and cart-clearing for checkout (`TC-08-EP-002..004`). The other `total_amount` invalid
classes from the Step-3 model (`< 0`, `= 0`, very large) remain out of scope for this pass —
they concern `POST /api/checkout`'s own total specifically, not the auth/cart surface this
Continuation pass targets, and are not blocking; see the sibling BVA report for a follow-up
decision on whether to add boundary cases for `total_amount` itself.

No Decision Table: none of FR-08's variables (`total_amount`, auth-state, cart-clearing) have
conditions that must hold together to change an outcome — each is checked independently. Per
Stage 5's own check, this is a legitimate skip (the same shape as FR-04, which also skipped a
Decision Table for the same reason), not a gap.

## AI Gap Analysis

The Step-3 smoke intentionally covered only `total_amount`; this Continuation pass adds the
remaining FR-08-only surface. No gaps identified in this pass — auth-state and cart-clearing
are both directly spec-cited (README FR-08 lines 104 and 108) with no ambiguity requiring an
assumption.
