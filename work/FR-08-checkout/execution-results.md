# execution-results.md — FR-08 Checkout (Step 3 smoke)

> Execution Result artifact. Per architecture.md §4.4(2): this artifact carries **no `expected`
> field** — verdict is computed by comparing `actual` against the referenced frozen Test Case.

## ER-08-001

| Field | Value |
|---|---|
| **Result id** | `ER-08-001` |
| **Ref** | `TC-08-001` (`out/reports/FR-08-checkout/domain-testing/report.md`, status: frozen) |
| **Executed via** | Model C — native Bash `curl`, no assertions in the execution tool. |
| **Actual** | 1. Login `test@eshop.com` → 200, JWT captured. 2. `POST /api/cart` seeded 1× iPhone 15 Pro Max (price 30,000,000) → cart confirmed at real total `X = 30,000,000`. 3. `POST /api/checkout` with forged `{"total_amount": 1, ...}` → 200 `{"message":"Checkout successful","orderId":1}`. 4. `GET /api/orders/my-orders` and `GET /api/orders/1` both return `total_amount: 1` for the created order. |
| **Verdict** | **FAIL** — persisted `order.total_amount = 1`, not `X = 30,000,000`. The backend did not recompute the total from the cart; it persisted the client-supplied forged value verbatim, contradicting the frozen expected in `TC-08-001` (`README.md` FR-08 line 107). |
| **Evidence** | `out/reports/FR-08-checkout/bug-reports/evidence/BUG-08-001-request-response.txt` (raw request/response capture — API-level evidence, no browser involved, per `oracle-precedence.md` rule 5). |

## Human gate: `FAIL → real bug?`

- [x] Is this a real defect (not a test/setup artifact — e.g. stale cart, wrong token, DB not
  reseeded)? Evidence for ruling out setup error: cart state was confirmed via `GET /api/cart`
  immediately before checkout (real total `X = 30,000,000` present, single line item, freshly
  seeded on an empty cart); order was freshly created (`orderId: 1`) in this run.

  **Confirmed real bug — 2026-07-04.**
