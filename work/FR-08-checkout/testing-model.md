# testing-model.md — FR-08 Checkout (Step 3 smoke fragment)

> Phase 1 fragment for the Step-3 vertical smoke. Scope: one variable, `total_amount`, enough
> to drive one certain-outcome case through all six artifact contracts. Not the full FR-08
> model (that is Continuation work, post-pilot).

## Variable: `total_amount`

### Definition of the oracle variable `X`

> `X = Σ (line.price × line.quantity)`, computed by the backend from the authenticated user's
> cart contents **at the moment of checkout**. `X` is the only value FR-08 recognizes as the
> correct total; it is never read from the client request.

| Field | Value |
|---|---|
| **Domain** | Positive integer (VND), server-computed as `X` (defined above) over the authenticated user's cart at checkout time. |
| **Boundary + relation** | Must equal `X`. See **Invalid classes** below for out-of-boundary values. |
| **Source** | `spec` — `README.md` FR-08, lines 105–107 (see [[oracle-precedence]] applied 2026-07-04). |
| **Validation rule** | Backend must ignore/recompute `total_amount` from the cart; must not persist or return a client-submitted value. Observable behavior expected: `persisted order.total_amount == X`; `response.total_amount == X` (if the endpoint echoes it); the client-supplied value has **no effect** on either. |
| **Oracle** | `README.md` FR-08 line 107: *"Backend phải tự tính lại tổng tiền; không chấp nhận giá trị `total_amount` do client gửi lên."* → expected: stored/returned order total = server-recomputed `X`, regardless of client input. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |

### Invalid classes (boundary, explicit)

| Class | Example | Why invalid |
|---|---|---|
| Negative | `total_amount < 0` | No valid order total is negative. |
| Zero | `total_amount = 0` | Cart is non-empty (per assumption below); a real order total cannot be 0. |
| Valid-looking but wrong | `total_amount != X` (e.g. a plausible but incorrect amount) | Value is shape-valid (positive integer) but does not match the recomputed cart sum. |
| Extreme / very large | `total_amount = 999999999999` | Forged value far outside any real cart total. |
| Correct format, forged low value | `total_amount = 1` (this smoke case) | Shape-valid, deliberately far below `X`, the case this smoke test exercises. |

## Assumptions (explicit, to remove ambiguity)

| # | Assumption | Metadata |
|---|---|---|
| A1 | User is authenticated (valid JWT) for the checkout call. | `{source: spec, confidence: HIGH, status: accepted}` |
| A2 | Cart is non-empty at checkout time. | `{source: spec, confidence: HIGH, status: accepted}` |
| A3 | Product price and quantity do not change during the test (no concurrent edits). | `{source: external, confidence: HIGH, status: accepted}` |
| A4 | No coupon/voucher, shipping fee, or tax is applied in this smoke case — `X` is the raw cart sum only. This is a scope-limiting decision by the tester, not a spec-asserted fact (the spec itself describes FR-09 coupons as an available feature); FR-09 is deliberately out of scope for this smoke case only. | `{source: external, confidence: HIGH, status: accepted}` |

## Forbidden / negative space

- `total_amount` is a **client-controlled-but-server-must-override** field: the API shape
  (`api_specification.md` §4.3) permits the client to send it, but the field's *value* is
  forbidden from influencing the persisted order — the field is present on the wire but its
  content is out of the client's authority. This is the negative-space note the model must
  surface: the request may carry the field; the server may not act on it.

## Code-derived note (for locating where to test — not used as oracle)

- `backend/server.js` `POST /api/checkout` (lines 297–309) inserts `req.body.total_amount`
  directly into the `orders` table with no recomputation from `userCarts[userId]`. This is
  read only to identify *where* to point the test (Model construction, architecture.md §2.1);
  it is **not** used to derive the expected result — the expected result above comes from
  `README.md` alone, frozen before this code was read for oracle purposes.

## Human review

- [x] **Gate: `completeness_confirmed`** — checklist:
  - [x] Domain complete
  - [x] Boundary complete (invalid classes enumerated)
  - [x] Oracle frozen (`X` defined; expected observable behavior stated)
  - [x] Assumptions frozen (A1–A4)
  - [x] Negative space documented (forbidden-field note)

  **Approved 2026-07-04.**

---

# Extended scope — Continuation FR-08 Full

> Added 2026-07-04 via `domain-test-design` Stage 1 (model each variable) and Stage 2
> (assumption defensibility). Extends the model above with the remaining **FR-08-only**
> surface: auth-state for checkout and cart-clearing. The `total_amount` entry and its
> approval above are untouched.
>
> **Correction, 2026-07-04 (same day):** this section originally also modeled FR-09's 5 coupon
> conditions (C1–C5) and the discount-calculation formula, reasoning that coupon application
> happens "at the Checkout step" per README's own FR-09 text. The student flagged this: FR-09
> ("Mã Giảm Giá," README line 110 — customer-facing coupon application) is **not** one of the
> 4 assigned features (`docs/hw2-reqs/features-that-need-testing.md`: FR-04, FR-08, FR-15,
> FR-17 only). The 4th assigned coupon-related feature, FR-17 (README line 213), is a
> *different* feature — admin coupon CRUD (Add/View/Delete coupon codes), not customer-facing
> application logic. All FR-09 model content, EP/BVA cases, the Decision Table, execution
> results, and 3 of the 5 bug reports built from it have been removed from this feature's
> scope — see the AI Audit for the corrective entry logged at the time of this correction.
> None of it was deleted from the repository's history (git log still shows it); it is simply
> no longer part of FR-08's active model or deliverables.

## Variable: Auth state (checkout)

| Field | Value |
|---|---|
| **Domain** | Request-auth state reaching `POST /api/checkout`: `{no Authorization header, present-but-invalid/expired JWT, present-valid JWT}`. |
| **Boundary + relation** | Presence/validity boundary (not numeric): `{absent, invalid, valid}`. |
| **Source** | `spec` — README FR-08 line 104: *"Chỉ người dùng đã đăng nhập mới tiến hành thanh toán được."* (Only logged-in users may proceed to checkout.) Second, code-revealed boundary (Step 1.2): `authenticateToken` middleware (`backend/server.js:100-110`), applied to `POST /api/checkout` (`server.js:297`) — no token → `401 Unauthorized`; invalid/expired token → `403 Forbidden`; valid token → proceeds. This refines the one spec-level "not logged in" condition into two distinct code-level sub-states — recorded side by side, not merged, and not itself treated as the oracle for which status code is "correct." |
| **Validation rule** | A checkout request without a valid JWT must not result in a persisted order. |
| **Oracle** | README FR-08 line 104 → expected (outcome-level, see A6 reframing below): when the request lacks a valid JWT, no order is created — a subsequent authenticated `GET /api/orders/my-orders` for that user shows no new order, and the response is not a checkout-success response. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |

## Variable: Cart-clearing after checkout

| Field | Value |
|---|---|
| **Domain** | Cart content for the authenticated user, before vs. after a successful checkout: `{non-empty}` → must become `{empty}`. |
| **Boundary + relation** | Presence/absence boundary — "empty" vs. "non-empty" cart, checked via `GET /api/cart` immediately after a successful `POST /api/checkout`. |
| **Source** | `spec` — README FR-08 line 108: *"Sau thanh toán thành công, giỏ hàng được xóa."* (After a successful checkout, the cart is cleared.) |
| **Validation rule** | For a user whose checkout call returns a success response, a subsequent `GET /api/cart` for that same user must return an empty cart. |
| **Oracle** | README FR-08 line 108 → expected: cart is empty after a successful checkout, stated path-agnostically (the spec states the outcome, not which component must implement it). |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |
| **Code-derived note (not oracle)** | `backend/server.js` `POST /api/checkout` (lines 297-309) inserts the order row and returns success; no code path in this handler, or anywhere else in `server.js`, clears or resets `userCarts[userId]`. Read only to locate where to test. |

## Human review — extended scope

- [x] **Gate: `completeness_confirmed`** — checklist:
  - [x] Domain complete for both new variables (auth-state, cart-clearing)
  - [x] Boundary complete
  - [x] Oracle stated for every variable, citing README FR-08 directly
  - [x] No new assumptions needed beyond A1–A4 (both variables reframe cleanly to
    outcome-level spec readings, no layer-specific or status-code commitment required)
  - [x] Negative space documented (auth-state's rejection requirement)

  **Approved 2026-07-04. Re-scoped 2026-07-04 (same day) to remove FR-09 content — see the
  correction note at the top of this section.**
