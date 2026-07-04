# FR-08 — Bug Report

> Scope note: this report currently holds the Step-3 vertical-smoke bug (`BUG-08-001`). The
> full FR-08 bug pass is Continuation work, post-pilot (see `implementation_plan.md`).

## BUG-08-001 — Checkout persists client-forged `total_amount` instead of the server-recomputed cart total

| Field | Value |
|---|---|
| **Severity** | Critical — `total_amount` is the SUT's sole financial record for an order: it is what the admin revenue dashboard aggregates for `status = 'delivered'` orders (`README.md` line 183) and the only recorded amount owed for the order. Evidence proves this field is 100% attacker-controlled with zero server-side validation, for any authenticated user, on any order — a complete failure of the one rule (`README.md` FR-08 line 107) that exists specifically to prevent it, with no compensating control elsewhere in the checkout flow. Note: this SUT has no separate payment-gateway charge step to observe: severity is assessed against the order's financial-record integrity (and its downstream use in revenue reporting), not against an independently verified real-money charge event. |
| **Priority** | P1 |
| **Ref** | `TC-08-001` (`out/reports/FR-08-checkout/domain-testing/report.md`) |
| **GitHub Issue** | Not filed — `gh` CLI unavailable in this environment (see `docs/implementation-plan/blockers.md`, 0.2). Approved draft + local evidence only, per the plan's documented fallback. |

**Expected** (per `README.md` FR-08 line 107, oracle — see `docs/implementation-plan/oracle-precedence.md`):
the backend must recompute `total_amount` server-side from the cart
(`X = Σ price × quantity`) and persist that value, ignoring whatever `total_amount` the client
sends. For this case: `X = 30,000,000` VND (1× iPhone 15 Pro Max).

**Actual:** the created order (`orderId: 1`) persists `total_amount = 1` — the exact forged
value sent by the client — with no server-side recomputation. Confirmed via
`GET /api/orders/my-orders` and `GET /api/orders/1`.

**Steps to reproduce:**
1. Login as any user (`POST /api/login`).
2. Add any product to the cart via `POST /api/cart` (e.g.
   `{"id":1,"name":"iPhone 15 Pro Max","price":30000000,"quantity":1}`).
3. `POST /api/checkout` with a forged `total_amount` far below the real cart value, e.g.
   `{"total_amount":1,"shipping_address":"..."}`.
4. `GET /api/orders/my-orders` — observe the persisted `total_amount` equals the forged client
   value, not the real cart total.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
lines 297–309, `POST /api/checkout`, destructures `total_amount` directly from `req.body` and
inserts it into the `orders` table with zero recomputation from `userCarts[userId]`.

**Evidence:** [`evidence/BUG-08-001-request-response.txt`](evidence/BUG-08-001-request-response.txt)
(raw request/response capture — API-level bug, no browser involved).
