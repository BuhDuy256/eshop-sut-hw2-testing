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
> began. Tokens captured: `test@eshop.com` = user id 2, `admin@eshop.com` = id 1. Coupon ids at
> seed time: `SAVE10=1`, `BIGBUY=2`, `VIP100=3`, `EXPIRED=4`.

## ER-08-EP-002 — ref `TC-08-EP-002`

**Actual:** `POST /api/checkout` with no `Authorization` header → `401 {"error":"Unauthorized"}`. Follow-up `GET /api/orders/my-orders` (authenticated) → `[]`, no order created.
**Verdict:** PASS.

## ER-08-EP-003 — ref `TC-08-EP-003`

**Actual:** `POST /api/checkout` with `Authorization: Bearer invalid.token.value` → `403 {"error":"Forbidden"}`. No new order created (confirmed via the same `my-orders` check as ER-08-EP-002).
**Verdict:** PASS.

## ER-08-EP-004 — ref `TC-08-EP-004`

**Actual:** Cart seeded with 1 item (`iPhone 15 Pro Max`) — `GET /api/cart` before checkout showed 2 entries (1 pre-existing residue from `userCarts` being an in-memory object not reset by DB reseed, plus the 1 just added; noted, does not affect the verdict — see below). `POST /api/checkout` → `200 {"message":"Checkout successful","orderId":1}`. `GET /api/cart` immediately after → **still returned the same 2 entries, unchanged** (not empty).
**Verdict:** **FAIL** — the cart was not cleared after a successful checkout, regardless of its pre-checkout contents; a successful checkout leaving the cart non-empty directly contradicts the frozen expected in `TC-08-EP-004` (`README.md` FR-08 line 108).

## ER-08-EP-005 — ref `TC-08-EP-005`

**Actual:** `POST /api/apply-coupon` `{"code":"NOPE_NOT_REAL","total_amount":500000,"user_id":2}` → `404 {"error":"Mã giảm giá không tồn tại hoặc đã bị vô hiệu hóa"}`.
**Verdict:** PASS.

## ER-08-EP-006 — ref `TC-08-EP-006`

**Actual:** `POST /api/apply-coupon` `{"code":"EXPIRED","total_amount":200000,"user_id":2}` → `400 {"error":"Mã giảm giá đã hết hạn"}`.
**Verdict:** PASS.

## ER-08-EP-007 — ref `TC-08-EP-007`

**Actual:** `POST /api/apply-coupon` `{"code":"SAVE10","total_amount":100000,"user_id":2}` → `400 {"error":"Đơn hàng chưa đủ giá trị tối thiểu 300,000 ₫ để áp dụng mã này"}`.
**Verdict:** PASS.

## ER-08-EP-008 — ref `TC-08-EP-008`

**Actual:** `POST /api/apply-coupon` with **no** `Authorization` header, `{"code":"VIP100","total_amount":400000,"user_id":1}` (spoofing the admin account's id) → `200 {"success":true,"coupon_id":3,"discount_amount":100000,"final_amount":300000,"message":"Áp dụng thành công! Giảm 100,000 ₫"}`.
**Verdict:** **FAIL** — the request presented no JWT at all and still received a successful discount computed against a spoofed `user_id`, contradicting the frozen expected in `TC-08-EP-008` (`README.md` FR-09 row C4, via the A7 reframing).

## ER-08-EP-009 — ref `TC-08-EP-009`

**Actual:** `POST /api/coupon-usage` `{"coupon_id":1}` (authenticated as `test@eshop.com`) → usage recorded. `POST /api/apply-coupon` `{"code":"SAVE10","total_amount":500000,"user_id":2}` (authenticated) → `400 {"error":"Bạn đã sử dụng mã này 1 lần (đã đạt giới hạn)"}`.
**Verdict:** PASS.

## ER-08-EP-010 — ref `TC-08-EP-010`

**Actual:** `POST /api/apply-coupon` `{"code":"SAVE10","total_amount":1000000,"user_id":2}` (authenticated, first use) → `200 {"success":true,"coupon_id":1,"discount_amount":-9000000,"final_amount":10000000,"message":"Áp dụng thành công! Giảm 10%"}`.
**Verdict:** **FAIL** — expected (per `TC-08-EP-010`, README FR-09 percent formula) `discount_amount = 100,000`, `final_amount = 900,000`. Actual `discount_amount = -9,000,000`, `final_amount = 10,000,000` — the returned "final amount" is over 10× the original total, not a 10% reduction.

## ER-08-EP-011 — ref `TC-08-EP-011`

**Actual:** `POST /api/apply-coupon` `{"code":"BIGBUY","total_amount":600000,"user_id":2}` (authenticated, first use) → `200 {"success":true,"coupon_id":2,"discount_amount":50000,"final_amount":550000,"message":"Áp dụng thành công! Giảm 50,000 ₫"}`.
**Verdict:** PASS — matches the frozen expected exactly (fixed-type formula).

## ER-08-BVA-001 — ref `TC-08-BVA-001`

**Actual:** `POST /api/apply-coupon` `{"code":"SAVE10","total_amount":299999,"user_id":2}` → `400`, "insufficient total" error.
**Verdict:** PASS.

## ER-08-BVA-002 — ref `TC-08-BVA-002`

**Actual:** `POST /api/apply-coupon` `{"code":"SAVE10","total_amount":300000,"user_id":2}` (exact boundary) → `400 {"error":"Đơn hàng chưa đủ giá trị tối thiểu 300,000 ₫ để áp dụng mã này"}`.
**Verdict:** **FAIL** — the frozen expected in `TC-08-BVA-002` (README FR-09 row C3, `>=`, inclusive) calls for this to be **accepted** at exactly `min_order_amount`. The actual response rejects it, matching the code's `>` (exclusive) reading instead of the spec's `>=`.

## ER-08-BVA-003 — ref `TC-08-BVA-003`

**Note on execution order:** the first attempt at `total_amount=300001` (run immediately after `ER-08-EP-009`/`ER-08-EP-010`, which had already recorded a `SAVE10` usage for `test@eshop.com`) returned `400 {"error":"Bạn đã sử dụng mã này 1 lần (đã đạt giới hạn)"}` — a **confounded** result: it reflects C5 (usage cap already reached), not C3, because this case's design did not account for `SAVE10`'s `max_uses_per_user=1` already being exhausted by the earlier percent-formula case in the same execution pass. The DB was reseeded (clearing `coupon_usage`) and the case was re-run before recording a verdict, per "reseed between runs if state matters" (`implementation_plan.md` Step 4.4).

**Actual (re-run, clean state):** `POST /api/apply-coupon` `{"code":"SAVE10","total_amount":300001,"user_id":2}` → `200 {"success":true,"coupon_id":1,"discount_amount":-2700009,"final_amount":3000010,"message":"Áp dụng thành công! Giảm 10%"}`.
**Verdict:** PASS **for the boundary claim under test** (C3 is satisfied just above the threshold — a `success:true` response, matching both the spec's and the code's reading, which agree above the boundary). The `discount_amount`/`final_amount` values themselves are wrong, but that is the already-separately-confirmed formula defect (`ER-08-EP-010`), not a new finding for this case — `TC-08-BVA-003`'s own expected result concerned only whether C3 passes, not the formula's output.

## ER-08-BVA-004 — ref `TC-08-BVA-004`

**Actual:** `POST /api/coupon-usage` `{"coupon_id":3}` (1st `VIP100` usage) → recorded. `POST /api/apply-coupon` `{"code":"VIP100","total_amount":400000,"user_id":2}` → `200 {"success":true,"coupon_id":3,"discount_amount":100000,"final_amount":300000,...}`.
**Verdict:** PASS.

## ER-08-BVA-005 — ref `TC-08-BVA-005`

**Actual:** `POST /api/coupon-usage` `{"coupon_id":3}` (2nd `VIP100` usage) → recorded. `POST /api/apply-coupon` `{"code":"VIP100","total_amount":400000,"user_id":2}` → `400 {"error":"Bạn đã sử dụng mã này 2 lần (đã đạt giới hạn)"}`.
**Verdict:** PASS.

## ER-08-BVA-006 — ref `TC-08-BVA-006`

**Setup:** `POST /api/admin/coupons` (admin-authenticated) created `TESTEXP_PAST` (`fixed`, 10,000₫, `min_order_amount:0`, `expired_at:"2026-07-03"`, `max_uses_per_user:1`) — confirmed `is_active:1` (schema default; the admin-create endpoint does not accept an `is_active` field at all).
**Actual:** `POST /api/apply-coupon` `{"code":"TESTEXP_PAST","total_amount":50000,"user_id":2}` → `400 {"error":"Mã giảm giá đã hết hạn"}`.
**Verdict:** PASS.

## ER-08-BVA-007 — ref `TC-08-BVA-007`

**Setup:** `POST /api/admin/coupons` created `TESTEXP_FUTURE` (same shape, `expired_at:"2026-07-05"`).
**Actual:** `POST /api/apply-coupon` `{"code":"TESTEXP_FUTURE","total_amount":50000,"user_id":2}` → `200 {"success":true,"coupon_id":6,"discount_amount":10000,"final_amount":40000,...}`.
**Verdict:** PASS.

## ER-08-DT-002 — ref `TC-08-DT-002`

**Actual:** `POST /api/coupon-usage` `{"coupon_id":1}` (authenticated, exhausting `SAVE10` for `test@eshop.com` again post-reseed) → recorded. Sanity check — authenticated re-attempt with `user_id:2` → correctly rejected (`"Bạn đã sử dụng mã này 1 lần..."`), confirming the exhaustion took effect. Then: `POST /api/apply-coupon` with **no** `Authorization` header and **`user_id` key omitted entirely** from the body, `{"code":"SAVE10","total_amount":500000}` → `200 {"success":true,"coupon_id":1,"discount_amount":-4500000,"final_amount":5000000,"message":"Áp dụng thành công! Giảm 10%"}`.
**Verdict:** **FAIL** — the same coupon/user combination that was confirmed exhausted (and required no auth to check) returned a full success response the moment `user_id` was simply omitted from the request body, with no token presented either. Both C4 and C5 are bypassed simultaneously, contradicting the frozen expected in `TC-08-DT-002`.

## Human gate: `FAIL → real bug?` (Continuation batch)

- [x] `ER-08-EP-004` (cart not cleared) — real defect. Cart-clear behavior was checked with a
  freshly-added, known item; the array was byte-identical before and after checkout across two
  separate `GET /api/cart` calls in the same run — not a stale-read artifact.
- [x] `ER-08-EP-008` + `ER-08-DT-002` (apply-coupon auth/usage-cap bypass) — real defect,
  reproduced twice under two different concrete scenarios (spoofed `user_id`; omitted `user_id`
  with prior usage confirmed-exhausted moments earlier via an authenticated check) — not a
  fluke or a race condition.
- [x] `ER-08-EP-010` (percent discount formula) — real defect. Matches the code-derived note
  already recorded in the Testing Model (`Math.floor(total*(1-discount_value))`) exactly;
  reproduced with a fresh, first-time coupon use, no stale state involved.
- [x] `ER-08-BVA-002` (C3 boundary, `>` vs `>=`) — real defect. Reproduced at the exact
  documented boundary value with a freshly-seeded, never-used coupon for this user; `ER-08-BVA-001`
  and `ER-08-BVA-003` (one below, one above) both behave as expected, isolating the failure to
  precisely the boundary point.

  **All four confirmed real bugs — 2026-07-04.**
