# FR-08 — Bug Report

> Scope note: this report holds the Step-3 vertical-smoke bug (`BUG-08-001`) plus the
> Continuation FR-08 Full pass below (`BUG-08-002`), added 2026-07-04. Both were originally
> promoted with local evidence only — GitHub issue filing was blocked (first by `gh` not being
> installed at Step 0, then by the repository having Issues disabled entirely). **Update
> 2026-07-04 (later the same day):** Issues have been enabled on the repository and `gh` is
> authenticated; both approved reports below have now been filed verbatim as GitHub issues
> (#1, #2), with no change to any technical content — only the `GitHub Issue` field per bug
> was updated.
>
> **Correction, 2026-07-04 (same day):** this report originally also included `BUG-08-003`
> (apply-coupon auth/usage-cap bypass), `BUG-08-004` (percent discount formula), and
> `BUG-08-005` (C3 boundary `>` vs `>=`) — all three about FR-09 (customer-facing coupon
> application), which is **not** one of the 4 assigned features
> (`docs/hw2-reqs/features-that-need-testing.md`). The assigned coupon-related feature, FR-17,
> is a different feature (admin Coupon CRUD). These 3 bug reports have been removed from this
> deliverable. GitHub issues #3–#5 (already filed for them) are left open and unedited — they
> document real defects, just outside this student's graded FR-08 scope. See the AI Audit for
> the corrective entry.

## BUG-08-001 — Checkout persists client-forged `total_amount` instead of the server-recomputed cart total

| Field | Value |
|---|---|
| **Severity** | Critical — `total_amount` is the SUT's sole financial record for an order: it is what the admin revenue dashboard aggregates for `status = 'delivered'` orders (`README.md` line 183) and the only recorded amount owed for the order. Evidence proves this field is 100% attacker-controlled with zero server-side validation, for any authenticated user, on any order — a complete failure of the one rule (`README.md` FR-08 line 107) that exists specifically to prevent it, with no compensating control elsewhere in the checkout flow. Note: this SUT has no separate payment-gateway charge step to observe: severity is assessed against the order's financial-record integrity (and its downstream use in revenue reporting), not against an independently verified real-money charge event. |
| **Priority** | P1 |
| **Ref** | `TC-08-001` (`out/reports/FR-08-checkout/domain-testing/report.md`) |
| **GitHub Issue** | [#1](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/1) — filed 2026-07-04 after Issues were enabled on the repository. |

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
| **GitHub Issue** | [#2](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/2) — filed 2026-07-04 after Issues were enabled on the repository. |

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

## Summary

**Step-3 smoke:** 1 case executed, 1 confirmed defect (`BUG-08-001`).

**Continuation FR-08 Full:** 3 cases executed (auth-state ×2, cart-clearing ×1) — 2 passed,
1 failed, confirmed as `BUG-08-002`. No failure was rejected as a test/setup artifact.

**By severity:** Critical — 1 (`BUG-08-001`). Medium — 1 (`BUG-08-002`).

**Evidence basis:** both confirmed defects (`BUG-08-001`, `BUG-08-002`) are `spec`-grounded —
every expected result traces directly to a README FR-08 citation. No assumption-grounded
claims in this scope.

**GitHub filing:** both bugs are filed as GitHub issues (#1, #2), as of 2026-07-04, the same
day Issues were enabled on the repository — see `work/FR-08-checkout/bug-report-drafts.md`
for the resolution note. Filed verbatim from the already-approved content; no technical field
was changed.
