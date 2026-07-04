# bug-report-drafts.md — FR-08 Checkout (Step 3 smoke)

## BUG-08-001

| Field | Value |
|---|---|
| **ID** | `BUG-08-001` |
| **Title** | Checkout persists client-forged `total_amount` instead of the server-recomputed cart total |
| **Ref** | `TC-08-001` (test case) / `ER-08-001` (execution result) |
| **Severity** | Critical — `total_amount` is the SUT's sole financial record for an order: it is what the admin revenue dashboard aggregates for `status = 'delivered'` orders (`README.md` line 183) and the only recorded amount owed for the order. Evidence proves this field is 100% attacker-controlled with zero server-side validation, for any authenticated user, on any order — a complete failure of the one rule (`README.md` FR-08 line 107) that exists specifically to prevent it, with no compensating control elsewhere in the checkout flow. Note: this SUT has no separate payment-gateway charge step to observe: severity is assessed against the order's financial-record integrity (and its downstream use in revenue reporting), not against an independently verified real-money charge event. |
| **Priority** | P1 |
| **Expected** | Per `README.md` FR-08 line 107 (oracle, see `docs/implementation-plan/oracle-precedence.md`): the backend must recompute `total_amount` server-side from the cart (`X = Σ price × quantity`) and persist that value, ignoring whatever `total_amount` the client sends. For this case: `X = 30,000,000` VND (1× iPhone 15 Pro Max). |
| **Actual** | The created order (`orderId: 1`) persists `total_amount = 1` — the exact forged value sent by the client — with no server-side recomputation. Confirmed via `GET /api/orders/my-orders` and `GET /api/orders/1`. |
| **Repro steps** | 1. Login as any user (`POST /api/login`). 2. Add any product to the cart via `POST /api/cart` (e.g. `{"id":1,"name":"iPhone 15 Pro Max","price":30000000,"quantity":1}`). 3. `POST /api/checkout` with a forged `total_amount` far below the real cart value, e.g. `{"total_amount":1,"shipping_address":"..."}`. 4. `GET /api/orders/my-orders` — observe the persisted `total_amount` equals the forged client value, not the real cart total. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` lines 297–309, `POST /api/checkout`: destructures `total_amount` directly from `req.body` and inserts it into the `orders` table with zero recomputation from `userCarts[userId]`. |
| **Evidence** | `out/reports/FR-08-checkout/bug-reports/evidence/BUG-08-001-request-response.txt` |
| **Status** | `approved` — promoted to `out/reports/FR-08-checkout/bug-reports/report.md`. |

## Human gate: `approve → file`

- [x] Approve this draft for promotion to `out/reports/FR-08-checkout/bug-reports/report.md`.

  **Note:** `gh` CLI is not installed in this environment (see `docs/implementation-plan/blockers.md`,
  0.2). Per the plan's own fallback ("GitHub posting blocked by unresolved Step 0 → proceed
  with local approved draft; do not block"), this promotes to the deliverable report with
  local evidence only — no GitHub issue filed in this session.

  **Approved 2026-07-04.**

---

# Continuation FR-08 Full — Bug Report Drafts (2026-07-04)

> `gh` CLI is now installed and authenticated as `BuhDuy256` in this environment (unlike at
> Step 0/Step 3 — see `docs/implementation-plan/blockers.md` 0.2, not retroactively edited).
> Pending approval below, these can be filed as real GitHub issues, not just local drafts.

## BUG-08-002

| Field | Value |
|---|---|
| **ID** | `BUG-08-002` |
| **Title** | Cart is not cleared after a successful checkout |
| **Ref** | `TC-08-EP-004` (test case) / `ER-08-EP-004` (execution result) |
| **Severity** | Medium — a stated post-condition of a core business flow (README FR-08 line 108) is violated on every successful checkout; the customer's cart silently retains items they already paid for, risking accidental duplicate purchase or user confusion on the next visit. Proven mechanism: the cart array is byte-identical before and after a successful checkout. Not classified higher — no data corruption or security boundary is crossed; the order itself is still created correctly. |
| **Priority** | Medium-High — visible on every single checkout, not an edge case. |
| **Expected** | Per `README.md` FR-08 line 108 ("Sau thanh toán thành công, giỏ hàng được xóa"): after a successful checkout, the cart must be cleared for that user. `expected_source`: `spec`. |
| **Actual** | `GET /api/cart` immediately after a `200 "Checkout successful"` response still returns the same, unchanged, non-empty cart contents. |
| **Repro steps** | 1. Login. 2. `POST /api/cart` to add an item. 3. `GET /api/cart` — confirm non-empty. 4. `POST /api/checkout` with a valid body — confirm success response. 5. `GET /api/cart` again — observe it is unchanged, not empty. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` `POST /api/checkout` (lines 297–309) never references `userCarts` — no code path anywhere in the file clears or resets it after an order is created. |
| **Evidence** | Raw request/response capture (API-level, no browser involved): `out/reports/FR-08-checkout/bug-reports/evidence/BUG-08-002-request-response.txt`. |
| **Status** | draft — pending human approval. |

## BUG-08-003

| Field | Value |
|---|---|
| **ID** | `BUG-08-003` |
| **Title** | `POST /api/apply-coupon` enforces no authentication — identity and usage-cap can both be bypassed |
| **Ref** | `TC-08-EP-008` / `ER-08-EP-008` (spoofed identity, no token) and `TC-08-DT-002` / `ER-08-DT-002` (confirmed-exhausted usage bypassed by omitting `user_id`, also no token) |
| **Severity** | Critical — README FR-09 row C4 states a coupon requires a valid JWT, and row C5 states a per-user usage cap; evidence directly proves neither is enforced by any code path on this endpoint (no `authenticateToken` middleware at all), and that the one client-supplied field (`user_id`) the code uses as an identity proxy can simply be omitted to bypass the usage cap too — for **any** unauthenticated caller, on **any** coupon. Not extended beyond what was proven: this pass did not test whether `apply-coupon`'s output is later trusted uncritically by an authenticated `checkout` call — that chain is untested, so the claim here is scoped to `apply-coupon`'s own missing authentication and defeated usage cap, not to a proven end-to-end financial loss. |
| **Priority** | P1 |
| **Expected** | Per `README.md` FR-09 rows C4 and C5 (reframed outcome-level per the Testing Model's Assumption A7 — no assumption needed, since this is a direct spec reading): a coupon must not be applied for a request that presents no valid JWT, and a user's usage-per-coupon cap must hold regardless of what identity, if any, the request claims. `expected_source`: `spec`. |
| **Actual** | (1) A request with no `Authorization` header and `user_id: 1` (the admin account, not the requester) received a successful discount. (2) A coupon confirmed exhausted for a real, authenticated user moments earlier was successfully re-applied by simply omitting `user_id` and the token entirely. |
| **Repro steps** | See both scenarios in the evidence file. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` `POST /api/apply-coupon` (line 363) carries no `authenticateToken` middleware; it reads `user_id` directly from the untrusted request body (lines 364, 386) and only runs the usage-cap check (C5) inside an `if (user_id)` branch — omitting the field skips that check entirely. |
| **Evidence** | Raw request/response capture: `out/reports/FR-08-checkout/bug-reports/evidence/BUG-08-003-request-response.txt`. |
| **Status** | draft — pending human approval. |

## BUG-08-004

| Field | Value |
|---|---|
| **ID** | `BUG-08-004` |
| **Title** | Percent-type coupon discount formula returns a large negative discount instead of the spec's formula |
| **Ref** | `TC-08-EP-010` / `ER-08-EP-010` |
| **Severity** | Critical — the discount/final-amount calculation is a core computed value for every percent-type coupon (not a rare edge case — `SAVE10` is the system's flagship percent coupon), and evidence proves it returns a result inverted and inflated far beyond the original total, not merely imprecise. Not extended beyond what was proven: whether this incorrect `final_amount` is ever actually charged to a customer was not tested in this pass (no payment step exists in this SUT to observe) — the proven claim is scoped to the value `apply-coupon` itself returns. |
| **Priority** | P1 |
| **Expected** | Per `README.md` FR-09 "Công thức tính giảm giá," percent type: `discount_amount = total × discount_value / 100`. For `total_amount = 1,000,000`, `discount_value = 10`: `discount_amount = 100,000`, `final_amount = 900,000`. `expected_source`: `spec`. |
| **Actual** | `discount_amount = -9,000,000`, `final_amount = 10,000,000`. |
| **Repro steps** | 1. Login as a user who has not yet used `SAVE10`. 2. `POST /api/apply-coupon` `{"code":"SAVE10","total_amount":1000000,"user_id":<id>}`. 3. Observe `discount_amount`/`final_amount` in the response. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` lines 398-401/417-421 compute, for `type === "percent"`: `discount_amount = Math.floor(total_amount * (1 - coupon.discount_value))`. Seed data stores `discount_value` as a whole-number percent (`10`, not `0.10`), so this evaluates to `total_amount × (1 − 10) = total_amount × −9`, structurally different from the spec's `total × discount_value / 100`. The `fixed`-type branch (`discount_amount = coupon.discount_value`) matches the spec exactly and is unaffected (confirmed passing in `TC-08-EP-011`). |
| **Evidence** | Raw request/response capture: `out/reports/FR-08-checkout/bug-reports/evidence/BUG-08-004-request-response.txt`. |
| **Status** | draft — pending human approval. |

## BUG-08-005

| Field | Value |
|---|---|
| **ID** | `BUG-08-005` |
| **Title** | Coupon order-threshold check rejects orders at exactly `min_order_amount` (uses `>` instead of the spec's `>=`) |
| **Ref** | `TC-08-BVA-001/002/003` / `ER-08-BVA-001/002/003` |
| **Severity** | Medium — a defined, named business rule (README FR-09 row C3, explicitly stated as inclusive) is violated at exactly one point: an order whose total exactly equals a coupon's minimum threshold is wrongly denied the discount it is entitled to. Proven narrowly and precisely: the value just below and just above the threshold both behave correctly under either reading; only the boundary point itself diverges. Not classified higher — this affects eligibility for a discount, not data integrity or a security boundary. |
| **Priority** | Medium |
| **Expected** | Per `README.md` FR-09 row C3 ("Đủ ngưỡng đơn hàng — Tổng đơn hàng >= (lớn hơn hoặc bằng) min_order_amount"): a coupon is usable when `total_amount >= min_order_amount`, including equality. For `SAVE10` (`min_order_amount = 300,000`), a request with `total_amount = 300,000` must be accepted. `expected_source`: `spec`. |
| **Actual** | `total_amount = 300,000` is rejected with the same "insufficient total" error as a value below the threshold. |
| **Repro steps** | 1. Login. 2. `POST /api/apply-coupon` `{"code":"SAVE10","total_amount":300000,"user_id":<id>}` (a coupon not yet exhausted for this user). 3. Observe the rejection. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js:379`: `if (total_amount > coupon.min_order_amount)` — strictly exclusive, rather than the spec's inclusive `>=`. |
| **Evidence** | Raw request/response capture: `out/reports/FR-08-checkout/bug-reports/evidence/BUG-08-005-request-response.txt`. |
| **Status** | draft — pending human approval. |

## Human gate: `approve → file` (Continuation batch)

- [x] Approve `BUG-08-002` (cart not cleared) for promotion + GitHub issue.
- [x] Approve `BUG-08-003` (apply-coupon auth/usage-cap bypass) for promotion + GitHub issue.
- [x] Approve `BUG-08-004` (percent formula) for promotion + GitHub issue.
- [x] Approve `BUG-08-005` (C3 boundary `>` vs `>=`) for promotion + GitHub issue.

  **Approved 2026-07-04 — all 4, requested to file as real GitHub issues (`gh` now installed
  and authenticated as `BuhDuy256`, unlike at Step 0).**

  **GitHub filing attempt:** `gh issue create --repo BuhDuy256/eshop-sut-hw2-testing ...` for
  `BUG-08-002` returned: *"the 'BuhDuy256/eshop-sut-hw2-testing' repository has disabled
  issues."* This is a harder, different blocker than Step 0's "`gh` not installed" (which has
  since resolved) — the repo itself does not accept issues at all, regardless of `gh`'s state.
  Not retried for the other 3 drafts (same repo, same blocker). Per the plan's fallback
  ("GitHub posting blocked → proceed with local approved draft; do not block"), all 4 promoted
  to `out/reports/FR-08-checkout/bug-reports/report.md` with local evidence only. Enabling
  Issues on the repository (Settings → General → Features) would resolve this for future
  filing, if desired.
