# FR-08 — Domain Testing Report

> Scope note: this report currently holds the Step-3 vertical-smoke case (`TC-08-001`) that
> validates the pipeline end-to-end on the `total_amount` variable. The full FR-08 domain
> model (auth state, cart state, all 5 coupon conditions per FR-09) is Continuation work,
> post-pilot (see `implementation_plan.md`).

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

## Coverage rationale

`TC-08-001` covers the single highest-risk negative equivalence class for `total_amount`
(client-forged value far below the real cart total) identified as the flagship risk in the
oracle-precedence analysis. It does not yet cover the other invalid classes enumerated in the
testing model (`< 0`, `= 0`, very large, valid-looking-but-wrong) — those are deferred to the
full FR-08 pass (Continuation, post-pilot), where BVA/EP coverage will be completed together
with the FR-09 coupon decision table.

## AI Gap Analysis

Not yet applicable — this report currently covers only the Step-3 smoke case, not a full
domain pass. A gap analysis will be recorded when the full FR-08 domain model is built.
