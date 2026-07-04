# FR-08 — Domain Testing Report

> Scope note: this report holds the Step-3 vertical-smoke case (`TC-08-001`, `total_amount`)
> plus the Continuation FR-08 Full pass below (auth state, cart-clearing, FR-09's 5 coupon
> conditions C1–C5, and the discount formula), added 2026-07-04 via `domain-test-design`
> Stage 3 (EP) and Stage 5 (Decision Table). BVA is in the sibling
> `boundary-value-analysis/report.md`. `TC-08-001` is unchanged.

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

### TC-08-EP-005 — Apply a nonexistent coupon code (C1 fails)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, C1 (exists + active). |
| **Model reference** | Coupon C1 variable. |
| **Preconditions** | None — `apply-coupon` takes `total_amount` directly in its own body, independent of cart state. |
| **Input** | `POST /api/apply-coupon` `{"code": "NOPE_NOT_REAL", "total_amount": 500000, "user_id": <test@eshop.com's id>}`. |
| **Steps** | 1. Login as `test@eshop.com`, capture JWT and user id. 2. Send the request above with `Authorization: Bearer <token>`. |
| **Expected result** | No discount is applied; `final_amount` is not returned as different from `total_amount`; no success payload. |
| **`expected_source`** | `spec` — README FR-09 row C1. |
| **Status** | frozen. |

### TC-08-EP-006 — Apply an expired coupon, threshold otherwise met (C2 fails, C1 & C3 pass)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, C2 (not expired). |
| **Model reference** | Coupon C2 variable. |
| **Preconditions** | None. |
| **Input** | `POST /api/apply-coupon` `{"code": "EXPIRED", "total_amount": 200000, "user_id": <id>}` — 200,000 clears `EXPIRED`'s `min_order_amount` (100,000), so the request reaches the C2 check (per the Step 1.2 nesting note). |
| **Steps** | Authenticated as `test@eshop.com`, send the request above. |
| **Expected result** | Rejected — no discount applied, because the coupon's `expired_at` (2020-01-01) has passed. |
| **`expected_source`** | `spec` — README FR-09 row C2. |
| **Status** | frozen. |

### TC-08-EP-007 — Apply a coupon below the order threshold (C3 fails, C1 passes)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, C3 (order total meets threshold). |
| **Model reference** | Coupon C3 variable. |
| **Preconditions** | None. |
| **Input** | `POST /api/apply-coupon` `{"code": "SAVE10", "total_amount": 100000, "user_id": <id>}` — `SAVE10`'s `min_order_amount` is 300,000; 100,000 is well below it. |
| **Steps** | Authenticated as `test@eshop.com`, send the request above. |
| **Expected result** | Rejected — no discount applied. |
| **`expected_source`** | `spec` — README FR-09 row C3. |
| **Status** | frozen. |

### TC-08-EP-008 — Apply a coupon with a spoofed identity and no valid JWT (C4 fails / forbidden state)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, C4 (logged in) **and** the forbidden-state case from the Testing Model's Step 1.3. |
| **Model reference** | Coupon C4 variable; forbidden-state note. |
| **Preconditions** | None — deliberately no login. |
| **Input** | `POST /api/apply-coupon` with **no** `Authorization` header, body `{"code": "VIP100", "total_amount": 400000, "user_id": 1}` (`user_id: 1` asserts the admin account's id, which the requester never authenticated as). |
| **Steps** | Send the request above with no token at all. |
| **Expected result** | Rejected — a coupon must not be applied for a request that presents no valid JWT, regardless of any `user_id` claimed in the body. |
| **`expected_source`** | `spec` — README FR-09 row C4, reframed per Assumption A7 (outcome-level: no discount without a valid JWT; no specific enforcement layer asserted). |
| **Status** | frozen. |

### TC-08-EP-009 — Apply a coupon already exhausted for this user (C5 fails)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, C5 (uses-per-user not exceeded). |
| **Model reference** | Coupon C5 variable. |
| **Preconditions** | `test@eshop.com` has already recorded one prior usage of `SAVE10` (`max_uses_per_user = 1`) via `POST /api/coupon-usage`. **Execution-order note:** this case must run *after* the usage is recorded and *after* TC-08-EP-010 (percent-formula case, which also uses `SAVE10` for this same user and must observe a fresh, unused coupon) — run TC-08-EP-010 first, then record usage, then this case. |
| **Input** | `POST /api/apply-coupon` `{"code": "SAVE10", "total_amount": 500000, "user_id": <test@eshop.com's id>}`, authenticated with a valid JWT matching `user_id` (isolates C5 — C4 is genuinely satisfied here). |
| **Steps** | 1. Login as `test@eshop.com`. 2. Record one usage: `POST /api/coupon-usage` `{"coupon_id": <SAVE10's id>}`. 3. Send the `apply-coupon` request above. |
| **Expected result** | Rejected — the user has already used this coupon `max_uses_per_user` (1) times. |
| **`expected_source`** | `spec` — README FR-09 row C5. |
| **Status** | frozen. |

### TC-08-EP-010 — Percent discount formula (`SAVE10`, 10%)

| Field | Value |
|---|---|
| **Technique** | EP — valid class, discount-formula variable, `type = "percent"`. |
| **Model reference** | Discount-formula variable. |
| **Preconditions** | `test@eshop.com` has **not** yet used `SAVE10` (run before TC-08-EP-009, which exhausts it). `total_amount = 1,000,000` is chosen so `total × discount_value / 100` is already an integer, per Assumption A8's reframing (avoids the unstated-rounding question entirely). |
| **Input** | `POST /api/apply-coupon` `{"code": "SAVE10", "total_amount": 1000000, "user_id": <id>}`, authenticated. |
| **Steps** | Authenticated as `test@eshop.com`, send the request above (first use of `SAVE10` for this user). |
| **Expected result** | `discount_amount = 1,000,000 × 10 / 100 = 100,000`; `final_amount = 900,000`. |
| **`expected_source`** | `spec` — README FR-09, "Công thức tính giảm giá," percent formula. |
| **Status** | frozen. |

### TC-08-EP-011 — Fixed discount formula (`BIGBUY`, 50,000₫) — also the coupon-flow happy path

| Field | Value |
|---|---|
| **Technique** | EP — valid class, discount-formula variable, `type = "fixed"`; also the all-conditions-pass representative for C1–C5. |
| **Model reference** | Discount-formula variable; C1–C5 (all pass). |
| **Preconditions** | `test@eshop.com` has not yet used `BIGBUY` (`max_uses_per_user = 1`). |
| **Input** | `POST /api/apply-coupon` `{"code": "BIGBUY", "total_amount": 600000, "user_id": <id>}`, authenticated — `BIGBUY` exists+active (C1), unexpired (C2), 600,000 ≥ 500,000 threshold (C3), valid JWT (C4), zero prior usage (C5). |
| **Steps** | Authenticated as `test@eshop.com`, send the request above. |
| **Expected result** | `discount_amount = 50,000` (the coupon's fixed `discount_value`); `final_amount = 550,000`. |
| **`expected_source`** | `spec` — README FR-09, "Công thức tính giảm giá," fixed formula; all of C1–C5 satisfied per README FR-09's condition table. |
| **Status** | frozen. |

---

## Continuation — FR-08 Full: Decision Table (FR-09's 5 combined coupon conditions)

**Stage 5 check:** README FR-09 states all 5 conditions (C1–C5) must hold simultaneously for a
coupon to apply ("tất cả phải thỏa mãn") — two or more conditions combine, and different
combinations route to different, distinguishable outcomes (a different rejection reason, or
success). A Decision Table is legitimate here. Per the model's Step-1.2 code-revealed note, the
code evaluates conditions in a specific nested order (C1 → C3 → C2 → C5-if-`user_id`-present) —
**not** as 5 independent checks — so the table below is **not exhaustive (not the full 2⁵ = 32
rows)**; it covers the combinations that are actually distinguishable through the API and that
each test a genuinely different routing, per the model's forbidden-state findings under C4/C5.

| Row | C1 (exists+active) | C2 (not expired) | C3 (≥ threshold) | C4 (valid JWT) | C5 (uses < max) | Expected outcome (`expected_source`) | Case |
|---|---|---|---|---|---|---|---|
| 1 | T | T | T | T | T | Success — discount applied per the formula. (README FR-09 condition table + formula) | `TC-08-EP-011` |
| 2 | **F** | – | – | – | – | Rejected — code does not exist / inactive. (README FR-09 C1) | `TC-08-EP-005` |
| 3 | T | – | **F** | – | – | Rejected — total below threshold. Per the C2-nesting note, C2 is never reached when C3 fails first. (README FR-09 C3) | `TC-08-EP-007` |
| 4 | T | **F** | T | – | – | Rejected — coupon expired. (README FR-09 C2) | `TC-08-EP-006` |
| 5 | T | T | T | **F** | (n/a — no real identity to check usage against) | Rejected per spec — a coupon must not apply without a valid JWT, regardless of an asserted `user_id`. (README FR-09 C4, reframed per A7) | `TC-08-EP-008` |
| 6 | T | T | T | T (real JWT, `user_id` matches) | **F** | Rejected — usage cap reached for this user. (README FR-09 C5) | `TC-08-EP-009` |
| 7 | T | T | T | **F** (no token) | **F** (usage already at cap, `user_id` omitted from body) | Rejected per spec on **both** C4 and C5 grounds — no valid JWT, and this identity's usage cap is already reached; omitting `user_id` must not grant an unconditional discount. (README FR-09 C4 + C5 combined) | `TC-08-DT-002` (new, below) |

### TC-08-DT-002 — Coupon apply with `user_id` entirely omitted, no token, prior usage already at cap

| Field | Value |
|---|---|
| **Technique** | Decision Table — Row 7 (C4 **and** C5 both fail; `user_id` omission removes the only signal the code uses for either). |
| **Model reference** | Coupon C4 and C5 variables; forbidden-state note (C4). |
| **Preconditions** | `test@eshop.com` has already recorded one prior usage of `SAVE10` (reuse the setup from TC-08-EP-009 — run this case after that setup). |
| **Input** | `POST /api/apply-coupon` with **no** `Authorization` header, body `{"code": "SAVE10", "total_amount": 500000}` — note `user_id` is **omitted from the JSON body entirely**, not merely null. |
| **Steps** | Send the request above with no token and no `user_id` key. |
| **Expected result** | Rejected — no discount applied. The request presents no valid JWT (C4) and the coupon has already been used by this identity up to its cap (C5); the response must not grant a discount by omitting the one field the implementation happens to key its usage check on. |
| **`expected_source`** | `spec` — README FR-09 rows C4 and C5 combined, reframed per A7 (outcome-level, no enforcement-layer commitment). |
| **Status** | frozen. |

---

## Coverage rationale

`TC-08-001` covers the single highest-risk negative equivalence class for `total_amount`
(client-forged value far below the real cart total). The Continuation pass above adds: auth
state and cart-clearing for checkout (`TC-08-EP-002..004`); all 5 FR-09 conditions individually
(`TC-08-EP-005..009`); both discount-formula types (`TC-08-EP-010..011`); and a non-exhaustive,
justified Decision Table for the 5 conditions combined (7 rows, 1 new case). Deferred, by
explicit Assumption: the `is_active = 0` sub-case of C1 (A5 — no seed data reaches it; belongs
to FR-17's coupon-CRUD scope). BVA for `min_order_amount`, `max_uses_per_user`, and the C2
expiry instant is in the sibling `boundary-value-analysis/report.md`. The other `total_amount`
invalid classes from the Step-3 model (`< 0`, `= 0`, very large) remain out of scope for this
pass — they concern `POST /api/checkout`'s own total, not the coupon/auth/cart surface this
Continuation pass targets, and are not blocking; they can be picked up in a later pass if
prioritized.

## AI Gap Analysis

The Step-3 smoke intentionally covered only `total_amount`; this Continuation pass is the
first full domain pass for FR-08/FR-09. One judgment call worth flagging: the Decision Table
(Stage 5) was scoped to 7 rows instead of the full 32 because the code's own condition-nesting
(C2 inside C3's pass-branch; C5 inside an `if (user_id)` branch) makes most of the remaining 25
combinations either unreachable through the API or indistinguishable in their observed outcome
from a row already listed — building all 32 would have produced duplicate rows expecting the
same outcome for a different reason, which the model's own over-partitioning guard (Stage 3.1)
argues against extending to decision tables. If a reviewer disagrees with that scoping, the
missing combinations are cheap to add since the underlying variables are already modeled.
