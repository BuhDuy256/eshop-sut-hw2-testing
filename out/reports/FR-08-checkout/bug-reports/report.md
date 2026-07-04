# FR-08 — Bug Report

> Scope note: this report holds the Step-3 vertical-smoke bug (`BUG-08-001`) plus the
> Continuation FR-08 Full pass below (`BUG-08-002..005`), added 2026-07-04. None filed as
> GitHub issues — attempting to file `BUG-08-002` via `gh issue create` returned "the
> 'BuhDuy256/eshop-sut-hw2-testing' repository has disabled issues," a harder blocker than
> Step 0's "`gh` not installed" (which has since resolved — `gh` is now installed and
> authenticated). All 4 promote with local evidence only, per the plan's documented fallback.

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

---

## BUG-08-002 — Cart is not cleared after a successful checkout

| Field | Value |
|---|---|
| **Severity** | Medium — a stated post-condition of a core business flow (README FR-08 line 108) is violated on every successful checkout; the customer's cart silently retains items they already paid for, risking accidental duplicate purchase or confusion. Proven mechanism: the cart array is byte-identical before and after a successful checkout. Not classified higher — no data corruption or security boundary is crossed. |
| **Priority** | Medium-High — visible on every checkout, not an edge case. |
| **Ref** | `TC-08-EP-004` / `ER-08-EP-004` (`out/reports/FR-08-checkout/domain-testing/report.md`, `work/FR-08-checkout/execution-results.md`) |
| **GitHub Issue** | Not filed — the repository has Issues disabled (confirmed via `gh issue create`, 2026-07-04). Approved draft + local evidence only. |

**Expected** (per `README.md` FR-08 line 108, oracle): after a successful checkout, the cart
must be cleared for that user.

**Actual:** `GET /api/cart` immediately after a `200 "Checkout successful"` response still
returns the same, unchanged, non-empty cart contents.

**Steps to reproduce:**
1. Login. 2. `POST /api/cart` to add an item. 3. `GET /api/cart` — confirm non-empty.
4. `POST /api/checkout` with a valid body — confirm success response. 5. `GET /api/cart` again
— observe it is unchanged, not empty.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
`POST /api/checkout` (lines 297–309) never references `userCarts` — no code path anywhere in
the file clears or resets it after an order is created.

**Evidence:** [`evidence/BUG-08-002-request-response.txt`](evidence/BUG-08-002-request-response.txt)
(raw request/response capture — API-level bug, no browser involved).

---

## BUG-08-003 — `POST /api/apply-coupon` enforces no authentication — identity and usage-cap can both be bypassed

| Field | Value |
|---|---|
| **Severity** | Critical — README FR-09 row C4 states a coupon requires a valid JWT, and row C5 states a per-user usage cap; evidence directly proves neither is enforced by any code path on this endpoint, and that the one client-supplied field (`user_id`) the code uses as an identity proxy can simply be omitted to bypass the usage cap too — for any unauthenticated caller, on any coupon. Not extended beyond what was proven: whether `apply-coupon`'s output is later trusted uncritically by an authenticated `checkout` call was not tested — the claim is scoped to `apply-coupon`'s own missing authentication and defeated usage cap. |
| **Priority** | P1 |
| **Ref** | `TC-08-EP-008` / `ER-08-EP-008` and `TC-08-DT-002` / `ER-08-DT-002` |
| **GitHub Issue** | Not filed — repository has Issues disabled. Approved draft + local evidence only. |

**Expected** (per `README.md` FR-09 rows C4 and C5, reframed outcome-level per Testing Model
Assumption A7): a coupon must not be applied for a request that presents no valid JWT, and a
user's usage-per-coupon cap must hold regardless of what identity, if any, the request claims.

**Actual:** (1) A request with no `Authorization` header and `user_id: 1` (the admin account,
not the requester) received a successful discount. (2) A coupon confirmed exhausted for a real,
authenticated user moments earlier was successfully re-applied by simply omitting `user_id`
and the token entirely.

**Steps to reproduce:** see the two scenarios in the evidence file.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
`POST /api/apply-coupon` (line 363) carries no `authenticateToken` middleware; it reads
`user_id` directly from the untrusted request body (lines 364, 386) and only runs the
usage-cap check (C5) inside an `if (user_id)` branch — omitting the field skips that check
entirely.

**Evidence:** [`evidence/BUG-08-003-request-response.txt`](evidence/BUG-08-003-request-response.txt)
(raw request/response capture — API-level bug, no browser involved).

---

## BUG-08-004 — Percent-type coupon discount formula returns a large negative discount

| Field | Value |
|---|---|
| **Severity** | Critical — the discount/final-amount calculation is a core computed value for every percent-type coupon (not a rare edge case — `SAVE10` is the system's flagship percent coupon), and evidence proves it returns a result inverted and inflated far beyond the original total. Not extended beyond what was proven: whether this incorrect `final_amount` is ever actually charged to a customer was not tested (no payment step exists in this SUT to observe). |
| **Priority** | P1 |
| **Ref** | `TC-08-EP-010` / `ER-08-EP-010` |
| **GitHub Issue** | Not filed — repository has Issues disabled. Approved draft + local evidence only. |

**Expected** (per `README.md` FR-09 "Công thức tính giảm giá," percent type):
`discount_amount = total × discount_value / 100`. For `total_amount = 1,000,000`,
`discount_value = 10`: `discount_amount = 100,000`, `final_amount = 900,000`.

**Actual:** `discount_amount = -9,000,000`, `final_amount = 10,000,000`.

**Steps to reproduce:** 1. Login as a user who has not yet used `SAVE10`. 2. `POST
/api/apply-coupon` `{"code":"SAVE10","total_amount":1000000,"user_id":<id>}`. 3. Observe
`discount_amount`/`final_amount` in the response.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js`
lines 398-401/417-421 compute, for `type === "percent"`:
`discount_amount = Math.floor(total_amount * (1 - coupon.discount_value))`. Seed data stores
`discount_value` as a whole-number percent (`10`, not `0.10`), so this evaluates to
`total_amount × (1 − 10) = total_amount × −9`. The `fixed`-type branch matches the spec exactly
and is unaffected (confirmed passing in `TC-08-EP-011`).

**Evidence:** [`evidence/BUG-08-004-request-response.txt`](evidence/BUG-08-004-request-response.txt)
(raw request/response capture — API-level bug, no browser involved).

---

## BUG-08-005 — Coupon order-threshold check rejects the exact boundary (`>` instead of the spec's `>=`)

| Field | Value |
|---|---|
| **Severity** | Medium — a defined, named business rule (README FR-09 row C3, explicitly stated as inclusive) is violated at exactly one point: an order whose total exactly equals a coupon's minimum threshold is wrongly denied the discount it is entitled to. Proven narrowly: the value just below and just above both behave correctly under either reading; only the boundary point itself diverges. |
| **Priority** | Medium |
| **Ref** | `TC-08-BVA-001/002/003` / `ER-08-BVA-001/002/003` |
| **GitHub Issue** | Not filed — repository has Issues disabled. Approved draft + local evidence only. |

**Expected** (per `README.md` FR-09 row C3, "Tổng đơn hàng >= (lớn hơn hoặc bằng)
min_order_amount"): a coupon is usable when `total_amount >= min_order_amount`, including
equality. For `SAVE10` (`min_order_amount = 300,000`), `total_amount = 300,000` must be
accepted.

**Actual:** `total_amount = 300,000` is rejected with the same "insufficient total" error as a
value below the threshold.

**Steps to reproduce:** 1. Login. 2. `POST /api/apply-coupon`
`{"code":"SAVE10","total_amount":300000,"user_id":<id>}` (a coupon not yet exhausted for this
user). 3. Observe the rejection.

**Root cause (code-derived, for repro clarity only — not the oracle):** `backend/server.js:379`:
`if (total_amount > coupon.min_order_amount)` — strictly exclusive, rather than the spec's
inclusive `>=`.

**Evidence:** [`evidence/BUG-08-005-request-response.txt`](evidence/BUG-08-005-request-response.txt)
(raw request/response capture — API-level bug, no browser involved).

---

## Summary

**Step-3 smoke:** 1 case executed, 1 confirmed defect (`BUG-08-001`).

**Continuation FR-08 Full:** 17 cases executed (10 EP, 6 BVA counted at their final clean
result + 1 confounded-then-reseeded re-run, 1 Decision Table case) — 13 passed, 5 failed,
grouped into 4 confirmed defects (`BUG-08-002` groups 2 failing cases under one root cause;
`BUG-08-004`/`BUG-08-005` are each 1 failing case). No failure was rejected as a test/setup
artifact.

**By severity (Continuation batch):** Critical — 2 (`BUG-08-003`, `BUG-08-004`). Medium — 2
(`BUG-08-002`, `BUG-08-005`).

**Evidence basis:** all 5 confirmed defects (`BUG-08-001..005`) are `spec`-grounded —
every expected result traces directly to a README FR-08/FR-09 citation. None rest on an
unresolved assumption; the two candidate assumptions that touched this batch (A6, A7) were
each reframed at the modeling stage into a direct, path-agnostic spec reading before any test
case was written, so no bug report needed to lean on an assumption's credibility. Zero
reclassifications between spec-grounded and assumption-grounded during this review.

**GitHub filing:** none of the 5 bugs are filed as GitHub issues — the repository has Issues
disabled (confirmed 2026-07-04, see `work/FR-08-checkout/bug-report-drafts.md`). All 5 are
promoted here with local evidence only, per the plan's documented fallback.
