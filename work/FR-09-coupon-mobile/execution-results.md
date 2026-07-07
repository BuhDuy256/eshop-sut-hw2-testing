# execution-results.md — FR-09-Mobile, code-derived inference (no live execution)

> Per `docs/implementation-plan/continuation-handoff-FR09-mobile.md` §2 (non-negotiable): none
> of the 13 results below come from opening the mobile app. Each `Actual` is a code-derived
> inference — it names the exact `frontend-mobile/App.js` line(s) read and the exact
> already-confirmed backend defect (by GitHub issue #) it combines with. No `expected` field is
> recorded here (references the frozen case in the sibling `out/reports/FR-09-coupon-mobile/*`
> report instead), matching the structural guard in architecture.md §4.4. Verdict is computed by
> comparing the inferred actual to the already-frozen expected — never the reverse.

## ER-09-EP-001 — ref `TC-09-EP-001`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`backend/server.js:373-377` (returns `404` with `"Mã giảm giá không tồn tại hoặc đã bị vô hiệu
hóa"` for a `code` with no matching active row) combined with `frontend-mobile/App.js:376-378`
(the `catch` block sets this exact message as `couponError`) and the render at lines 722-724
(shows it under the coupon box). No confirmed backend defect involved — this is baseline,
correct behavior.

**Verdict:** PASS.

## ER-09-EP-002 — ref `TC-09-EP-002`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`backend/server.js:381-384` (rejects with `"Mã giảm giá đã hết hạn"` when `expiry < now`, and
`EXPIRED`'s seeded `expired_at` is `2020-01-01`) combined with the same `App.js:376-378`/`722-724`
catch-and-render path as `ER-09-EP-001`. No confirmed backend defect involved — baseline.

**Verdict:** PASS.

## ER-09-EP-003 — ref `TC-09-EP-003`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`frontend-mobile/App.js:358-372` (`handleApplyCoupon` constructs the `apply-coupon` fetch with
only a `Content-Type` header — never `Authorization` — for any mobile user regardless of login
state, asserting identity solely via `user_id: user?.id || null` from local state) combined with
the confirmed backend behavior in **issue #3** (`backend/server.js:363` carries no
`authenticateToken` middleware at all and trusts `user_id` from the body). Because the mobile
client's own code never attempts to send a token on this call, the request the app itself
constructs already reaches the exact unauthenticated path issue #3 describes — the coupon would
be granted despite presenting no valid JWT, for any logged-in mobile user, not only a crafted
attack.

**Verdict:** FAIL — reconfirms issue #3, from the mobile client's own code path (comment on
existing issue, not a duplicate).

## ER-09-EP-004 — ref `TC-09-EP-004`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`backend/server.js:398-401` (`discount_amount = Math.floor(total_amount * (1 -
coupon.discount_value))`; for `SAVE10`, `discount_value = 10`, so `discount_amount = 1,000,000 ×
(1 − 10) = -9,000,000`, and `final_amount = 1,000,000 − (−9,000,000) = 10,000,000`) combined
with `frontend-mobile/App.js:728-732` (renders `couponResult.discount_amount`/`final_amount`
directly through `formatMoney`, no sign-check or sanity clamp). The coupon box would show
**"Tiết kiệm: -9.000.000 ₫"** and **"Thành tiền: 10.000.000 ₫"**, under the success message
(line 727), for a 1,000,000₫ cart — this is **issue #4**'s already-confirmed mechanism, now
traced through to its mobile rendering.

**Verdict:** FAIL — reconfirms issue #4, from a specific mobile render (comment on existing
issue, not a duplicate).

## ER-09-EP-005 — ref `TC-09-EP-005`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`backend/server.js:402-403` (`fixed`-type branch: `discount_amount = coupon.discount_value`,
matching the spec exactly, unaffected by issue #4) combined with the same
`App.js:728-732` render as `ER-09-EP-004`. For `BIGBUY` (600,000₫ cart): `discount_amount =
50,000`, `final_amount = 550,000`, both correctly displayed. No confirmed backend defect
involved — baseline.

**Verdict:** PASS.

## ER-09-EP-006 — ref `TC-09-EP-006`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`frontend-mobile/App.js:385` (`const finalAmount = couponResult ? couponResult.final_amount :
cartTotal;`) and lines 392-396 (`POST /api/checkout` with `total_amount: finalAmount`) combined
with **issue #1**'s already-confirmed mechanism (`backend/server.js:297-309` inserts whatever
`total_amount` it receives into `orders` with zero recomputation from the cart) and **issue
#4**'s mechanism (already inferred in `ER-09-EP-004`: `couponResult.final_amount = 10,000,000`
for this input, not the correct `900,000`). Chaining these: after applying `SAVE10` to a
1,000,000₫ cart, tapping "Xác Nhận Thanh Toán" would send `total_amount: 10,000,000` to
checkout, which would persist `10,000,000` as the order's stored total — ten times the real
cart value and over eleven times the spec-correct `final_amount` of `900,000` — not the
`900,000` the frozen case expects.

**Verdict:** FAIL — a new finding this session, combining issues #1 and #4 through a mobile-only
call path neither original bug report examined (candidate for a fresh bug report, per the
Testing Model's explicit flagging and the student's blanket approval).

## ER-09-BVA-001 — ref `TC-09-BVA-001`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`backend/server.js:379` (`total_amount > coupon.min_order_amount`; `299,999 > 300,000` is
false) combined with the reject-branch message render (`App.js:376-378`/`722-724`). Rejected
under both the spec's and the code's reading — no divergence at this point.

**Verdict:** PASS.

## ER-09-BVA-002 — ref `TC-09-BVA-002`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`backend/server.js:379` (`300,000 > 300,000` is `false` in JavaScript's strict comparison, so
the `else` branch at lines 434-438 runs, returning `400` with `"Đơn hàng chưa đủ giá trị tối
thiểu 300.000 ₫ để áp dụng mã này"`) combined with `App.js:376-378`/`722-724` (renders this exact
message as `couponError`). The mobile coupon box would show this rejection for a cart total the
spec says should qualify — this is **issue #5**'s already-confirmed mechanism, now traced
through to its mobile rendering.

**Verdict:** FAIL — reconfirms issue #5, from a specific mobile render (comment on existing
issue, not a duplicate).

## ER-09-BVA-003 — ref `TC-09-BVA-003`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`backend/server.js:379` (`300,001 > 300,000` is `true`) combined with the success-render path
(`App.js:725-735`). Accepted under both readings — no divergence at this point.

**Verdict:** PASS.

## ER-09-BVA-004 — ref `TC-09-BVA-004`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`backend/server.js:391` (`usage_count (1) >= max_uses_per_user (2)` is `false`, so the
usage-cap branch does not reject) combined with the fixed-formula render already established in
`ER-09-EP-005`'s reasoning (`VIP100` is `fixed`, `discount_value = 100,000`). No confirmed
backend defect involved — baseline, matches spec.

**Verdict:** PASS.

## ER-09-BVA-005 — ref `TC-09-BVA-005`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`backend/server.js:391` (`usage_count (2) >= max_uses_per_user (2)` is `true`, rejects with
`"Bạn đã sử dụng mã này 2 lần (đã đạt giới hạn)"`) combined with the reject-render path. No
confirmed backend defect involved — baseline, matches spec.

**Verdict:** PASS.

## ER-09-BVA-006 — ref `TC-09-BVA-006`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`backend/server.js:381-384` (a coupon dated yesterday satisfies `expiry < now`, rejects) combined
with the reject-render path. No confirmed backend defect involved — baseline, matches spec.

**Verdict:** PASS.

## ER-09-BVA-007 — ref `TC-09-BVA-007`

**Actual (code-derived inference, not a live observation):** Not executed live; inferred from
`backend/server.js:381-384` (a coupon dated tomorrow satisfies `expiry >= now`, does not reject
on C2) combined with the success-render path. No confirmed backend defect involved — baseline,
matches spec.

**Verdict:** PASS.

---

## Summary

- **Executed (inferred):** 13 cases (6 EP, 7 BVA).
- **PASS:** 9 (`ER-09-EP-001/002/005`, `ER-09-BVA-001/003/004/005/006/007`).
- **FAIL:** 4 (`ER-09-EP-003/004/006`, `ER-09-BVA-002`).
- **Of the 4 FAILs:** 3 reconfirm already-filed issues from the mobile client's own code path
  (`ER-09-EP-003` → #3, `ER-09-EP-004` → #4, `ER-09-BVA-002` → #5); 1 is a new finding this
  session (`ER-09-EP-006`, combining #1 and #4 through `handleConfirmCheckout`).
- **Evidence basis:** 100% code-derived inference (`App.js` line(s) + a named confirmed backend
  defect or a direct code reading), 0% live execution, per the handoff's non-negotiable
  constraint. No case's actual is worded in a way that could be mistaken for a live observation.
