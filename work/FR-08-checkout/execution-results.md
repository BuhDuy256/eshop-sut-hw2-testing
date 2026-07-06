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

---

# Continuation FR-08 Full — Execution Results (2026-07-04)

> DB reseeded (`docker exec eshop-backend node database.js`) immediately before this batch
> began. Tokens captured: `test@eshop.com` = user id 2, `admin@eshop.com` = id 1.
>
> **Correction, 2026-07-04 (same day):** this section originally also included FR-09
> coupon-related results (`ER-08-EP-005..011`, `ER-08-BVA-001..007`, `ER-08-DT-002`). FR-09 is
> not one of the 4 assigned features — removed, see `testing-model.md`'s correction note and
> the AI Audit for detail. Only `ER-08-EP-002..004` (auth-state, cart-clearing) remain below.

## ER-08-EP-002 — ref `TC-08-EP-002`

**Actual:** `POST /api/checkout` with no `Authorization` header → `401 {"error":"Unauthorized"}`. Follow-up `GET /api/orders/my-orders` (authenticated) → `[]`, no order created.
**Verdict:** PASS.

## ER-08-EP-003 — ref `TC-08-EP-003`

**Actual:** `POST /api/checkout` with `Authorization: Bearer invalid.token.value` → `403 {"error":"Forbidden"}`. No new order created (confirmed via the same `my-orders` check as ER-08-EP-002).
**Verdict:** PASS.

## ER-08-EP-004 — ref `TC-08-EP-004`

**Actual:** Cart seeded with 1 item (`iPhone 15 Pro Max`) — `GET /api/cart` before checkout showed 2 entries (1 pre-existing residue from `userCarts` being an in-memory object not reset by DB reseed, plus the 1 just added; noted, does not affect the verdict — see below). `POST /api/checkout` → `200 {"message":"Checkout successful","orderId":1}`. `GET /api/cart` immediately after → **still returned the same 2 entries, unchanged** (not empty).
**Verdict:** **FAIL** — the cart was not cleared after a successful checkout, regardless of its pre-checkout contents; a successful checkout leaving the cart non-empty directly contradicts the frozen expected in `TC-08-EP-004` (`README.md` FR-08 line 108).

## Human gate: `FAIL → real bug?` (Continuation batch)

- [x] `ER-08-EP-004` (cart not cleared) — real defect. Cart-clear behavior was checked with a
  freshly-added, known item; the array was byte-identical before and after checkout across two
  separate `GET /api/cart` calls in the same run — not a stale-read artifact.

  **Confirmed real bug — 2026-07-04.**
