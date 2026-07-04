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
