# testing-model.md — FR-09 Discount Coupons, Mobile-Framed via Code-Derived Inference

> Continuation item 5. Corrected 4th assigned feature (Pool D — Mobile), replacing FR-17. Built
> via `domain-test-design` Stage 1-2, reusing the prior-art model already built for this exact
> backend feature (`git show 4ab06d2~1:work/FR-08-checkout/testing-model.md`, "Extended scope"
> section, approved 2026-07-04) as the base. The new work in this pass is **not** re-deriving
> C1-C5/the formula from spec+code — it is reframing each variable's *evidence method* as
> code-derived inference (reading `frontend-mobile/App.js`'s rendering code to predict what the
> mobile screen would show), per `docs/implementation-plan/continuation-handoff-FR09-mobile.md`
> §2 (the one non-negotiable rule: no live mobile execution took place in this pass).

## Method note (not an Assumption — an evidentiary boundary, sanctioned by the handoff)

Every variable below adds a **Mobile inference path** field: the exact `App.js` line(s) that
would carry a value from the API response to the screen, and the exact already-confirmed
backend defect (by GitHub issue #) it would need to combine with to produce an observable,
*inferred* divergence. Where the mobile UI's own code makes a sub-case unreachable or where
producing it would require tampering with the request outside the app's own button-tap flow
(not "reading the UI's rendering code"), that is recorded as a **Limitation**, not forced into
a fabricated case — per handoff §6 point 1 and §8's explicit instruction to flag rather than
guess. The load-bearing code fact underpinning all of this (handoff §6 point 4, confirmed by
re-reading `App.js` this session): the coupon-box render (lines 725-735) passes
`couponResult.message` / `.discount_amount` / `.final_amount` straight from the API response
through `formatMoney` with no client-side recomputation, validation, or sanity check of any
kind — so whatever the backend returns is what the screen would show, unfiltered. This is a
direct reading of the render function, not a hypothesis; it needs no Assumption of its own.

## File map

| File | What it's used for | Lines cited (re-confirmed this session, unchanged from the handoff) |
|---|---|---|
| `README.md` | Oracle — FR-09's 5 conditions + discount formula | 110–136 |
| `backend/server.js` | Where each condition/formula is enforced (model-construction only, never the oracle) | `POST /api/apply-coupon` 363–441 (no `authenticateToken`); `POST /api/checkout` 297–309; `POST /api/coupon-usage` 444–454 |
| `backend/database.js` | `coupons`/`coupon_usage` schema + seed data | 29–46 (schema), 106–111 (seed: `SAVE10`, `BIGBUY`, `VIP100`, `EXPIRED`) |
| `frontend-mobile/App.js` | The mobile rendering code this pass reads to derive inferences | `openCheckout` 344–356; `handleApplyCoupon` 358–380; `handleConfirmCheckout` 382–422; coupon-box render 694–736 |

## Already-confirmed backend defects reused as given (not re-derived this session)

| # | Mechanism |
|---|---|
| **#3** | `POST /api/apply-coupon` has no `authenticateToken` middleware at all; identity (`user_id`) is trusted verbatim from the request body; the usage cap (C5) is skipped entirely if `user_id` is omitted. |
| **#4** | Percent-type formula: `Math.floor(total_amount * (1 - coupon.discount_value))` instead of spec's `total × discount_value / 100`. With `discount_value` seeded as a whole-number percent (e.g. `10`), this evaluates to `total_amount × (1 − 10) = total_amount × −9` — a large **negative** `discount_amount`, hence a `final_amount` far **larger** than the total. |
| **#5** | C3 threshold check is `total_amount > coupon.min_order_amount` (strict), rejecting the exact boundary the spec states as inclusive (`>=`). |
| **#1** (`BUG-08-001`, different bug family) | `POST /api/checkout` persists whatever `total_amount` the client sends, verbatim, with zero server-side recomputation from the cart. |

---

## Variable: C1 — Mã tồn tại (exists + active)

| Field | Value |
|---|---|
| **Domain** | String; valid class = codes present in `coupons` with `is_active = 1`. Seeded: `SAVE10`, `BIGBUY`, `VIP100`, `EXPIRED` (all `is_active = 1`). |
| **Boundary + relation** | Enum-membership boundary. |
| **Source** | `spec` — README FR-09 row C1. |
| **Validation rule** | A nonexistent or inactive code must not receive a discount. |
| **Oracle** | README FR-09 C1 → expected: rejected, no discount, error surfaced. |
| **Mobile inference path** | `handleApplyCoupon` (358–380) sends the code as typed; on a `404`, the `catch` block (376–378) sets `couponError` to `data.error`, rendered at line 722–724 (`{!!couponError && <Text style={styles.errorSmall}>{couponError}</Text>}`) — the exact backend message ("Mã giảm giá không tồn tại hoặc đã bị vô hiệu hóa") would appear under the coupon box. No confirmed defect to combine with here — this predicts **correct** behavior (baseline coverage, not a bug case). |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |

## Variable: C2 — Còn hạn sử dụng (not expired)

| Field | Value |
|---|---|
| **Domain** | Date comparison: `coupon.expired_at` vs. "now." |
| **Boundary + relation** | Spec: strict `now < expired_at`. Second, code-revealed boundary (`server.js:381-384`): rejects when `expiry < now`, i.e. accepts when `expiry >= now` — diverges from spec only at the exact instant `now == expired_at`. Recorded side by side, per Step 1.2; not resolved here. |
| **Source** | `spec` — README FR-09 row C2. Code-revealed — `server.js:381-384`, `{source: impl}`. |
| **Validation rule** | A coupon whose `expired_at` has passed must be rejected. |
| **Oracle** | README FR-09 C2 → expected: seeded `EXPIRED` (`2020-01-01`) rejected; `SAVE10`/`BIGBUY`/`VIP100` (`2099-12-31`) satisfy C2. |
| **Mobile inference path** | Same render path as C1 (`couponError` ← `data.error`, line 722–724). **No confirmed backend defect exists for C2** (the prior-art pass never executed the exact-instant divergence — it substituted a practical yesterday/tomorrow pair and never found a bug there; see prior-art BVA report). This variable predicts **correct** behavior on both sides of the practical boundary — coverage, not a bug case. The exact-instant divergence itself is **not inferable** through the mobile UI at all (no time-precision seed data, and no confirmed defect to anchor an inference to) — left as an explicit open question, not guessed. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |

## Variable: C3 — Đủ ngưỡng đơn hàng (order threshold)

| Field | Value |
|---|---|
| **Domain** | Numeric: `total_amount` (cart total submitted from mobile) vs. `coupon.min_order_amount`. |
| **Boundary + relation** | Spec: inclusive `total_amount >= min_order_amount`. Code (`server.js:379`): exclusive `total_amount > min_order_amount` — **confirmed bug #5**, exactly at `total_amount == min_order_amount`. |
| **Source** | `spec` — README FR-09 row C3, `{source: spec}`. Code — `server.js:379`, `{source: impl}`. |
| **Validation rule** | At `total_amount == min_order_amount`, spec says satisfied; code rejects. |
| **Oracle** | README FR-09 C3 → expected: accepted at exactly `min_order_amount`. |
| **Mobile inference path** | **Combines with issue #5.** `handleApplyCoupon` sends `total_amount: cartTotal` (line 369) — a mobile user whose cart totals exactly `SAVE10`'s `min_order_amount` (300,000₫) and applies the code would hit `server.js:379`'s `else` branch (line 434-438), returning `400` with `"Đơn hàng chưa đủ giá trị tối thiểu 300.000 ₫ để áp dụng mã này"`. `handleApplyCoupon`'s `catch` (376-378) sets this as `couponError`, rendered verbatim at line 722-724. **Inference:** the mobile coupon box would show this rejection message for a cart total that the spec says should qualify — a direct, traceable manifestation of issue #5 on the mobile screen. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |

## Variable: C4 — Đã đăng nhập (valid JWT)

| Field | Value |
|---|---|
| **Domain** | Auth state reaching `POST /api/apply-coupon` from the mobile client. |
| **Boundary + relation** | Presence/enum boundary: `{no Authorization header at all (mobile's actual behavior), header present}`. |
| **Source** | `spec` — README FR-09 row C4. Code-revealed (Step 1.2, structural absence): `server.js:363` carries no `authenticateToken` middleware — **confirmed bug #3**. |
| **Validation rule** | A coupon must not apply without a valid JWT. |
| **Oracle** | README FR-09 C4 → expected: rejected without a valid JWT. |
| **Mobile inference path** | **Combines with issue #3 — and reinforces it from the client's own design, not just the server's gap.** `handleApplyCoupon` (358–372) sends **no `Authorization` header at all** on this call, for *any* mobile user, logged in or not — only `Content-Type`. Identity is asserted purely via `user_id: user?.id || null` (line 370), read from the app's own local state, never proven to the server. **Inference:** even a genuinely, honestly logged-in mobile user's coupon-apply request carries zero proof of identity — the mobile client's own code guarantees C4 is never actually checked through this screen, for anyone. This is a code-derived reinforcement of #3's finding, from a second, independent code path (the client), not merely a restatement of the server-side gap already filed. |
| **Limitation (not a forced case)** | The inverse sub-case — a request that reaches the coupon box with **no user at all** — is not reachable through the mobile UI's own screens: `openCheckout` (344-349) redirects to the login screen unless `user` is truthy, before the coupon box ever renders. This is a limitation of the mobile client's own design, not a finding to force. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |

## Variable: C5 — Chưa dùng hết lượt (uses-per-user)

| Field | Value |
|---|---|
| **Domain** | Numeric: prior `coupon_usage` rows for `(coupon_id, user_id)` vs. `coupon.max_uses_per_user`. |
| **Boundary + relation** | Spec: strict `usage_count < max_uses_per_user`. Code (`server.js:391`) matches exactly — no spec/code divergence, still boundary-worthy at `max_uses_per_user - 1` vs. `max_uses_per_user`. |
| **Source** | `spec` — README FR-09 row C5. |
| **Validation rule** | Once `usage_count == max_uses_per_user`, the coupon must be rejected. |
| **Oracle** | README FR-09 C5 → expected: rejected once the cap is reached. |
| **Mobile inference path** | For a genuinely exhausted, honestly-identified user, the mobile flow (`handleApplyCoupon` → real `user_id` → `handleConfirmCheckout` → `POST /api/coupon-usage` on success, line 401-410) matches the backend's own usage-recording mechanism exactly — **predicts correct rejection**, not a bug case (no confirmed defect attaches to the *honest* path). |
| **Limitation (not a forced case)** | Issue #3's *other* half — bypassing C5 by **omitting** `user_id` entirely — is **not reachable through the mobile app's own normal flow**: `handleApplyCoupon` (line 370) always sends `user_id: user?.id || null`; it is never entirely absent from the JSON body. Reaching that bypass would require tampering with the network request outside the app's own button-tap flow (e.g. a proxy) — beyond this pass's "read the UI's rendering code" evidence boundary (handoff §2/§8). Flagged as an open question for human review: leave out, or note as an inference that requires stepping outside pure UI-code-reading (in which case it would need its own explicit caveat, distinct from every other case in this pass). |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |

## Variable: Discount calculation formula

| Field | Value |
|---|---|
| **Domain** | `discount_amount`/`final_amount`, derived from `total_amount`, `coupon.type ∈ {percent, fixed}`, `coupon.discount_value`. |
| **Boundary + relation** | Formula-level, not edge-level; both `type` members exercised directly. |
| **Source** | `spec` — README FR-09, "Công thức tính giảm giá." |
| **Validation rule** | For a coupon passing C1-C5, `discount_amount`/`final_amount` must equal the spec's formula for that `type`. |
| **Oracle** | README FR-09 formula → **percent:** `discount_amount = total × discount_value / 100`, `final_amount = total − discount_amount`. **fixed:** `discount_amount = discount_value`, `final_amount = total − discount_amount`. |
| **Mobile inference path** | **Combines with issue #4 — this is the flagship, most direct mobile-visible case in this whole pass.** `server.js:398-401/417-421` computes, for `percent`: `discount_amount = Math.floor(total_amount * (1 - coupon.discount_value))`; with `SAVE10`'s `discount_value = 10`, this is `total_amount × −9` — a large negative number. `handleApplyCoupon` stores this response verbatim in `couponResult` (line 375); the render (728-732) shows `Text>✅ {couponResult.message}` (still the success message, since the backend returned `success: true`), then `Tiết kiệm: {formatMoney(couponResult.discount_amount)}` → **literally "Tiết kiệm: -9.000.000 ₫"** (for a 1,000,000₫ cart) with no sign-check or sanity clamp anywhere in the render path, then `Thành tiền: {formatMoney(couponResult.final_amount)}` → **"Thành tiền: 10.000.000 ₫"**, ten times the real cart total. **Inference:** the mobile coupon box would display a negative "savings" figure and an inflated "amount due" figure, under a green checkmark success message, for any percent-type coupon. `fixed`-type (`BIGBUY`) is unaffected — predicts correct display, coverage baseline. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |

---

## New variable (proposed — flagged for human review, not simply a restatement of #3/#4/#5)

### Compound chain: mobile checkout persists the broken percent-formula result as the order's stored total

| Field | Value |
|---|---|
| **Domain** | The `total_amount` value mobile's `handleConfirmCheckout` sends to `POST /api/checkout`, and what gets persisted. |
| **Why this is a genuinely new finding, not a duplicate** | It requires chaining **two independently-confirmed backend defects (#1 and #4) through a mobile-only call path** that neither prior bug report examined: #4 was only ever confirmed at the `apply-coupon` response level (never carried into a subsequent checkout call); #1 was only ever confirmed with a client that *directly* forges `total_amount` (never via a coupon-computed value flowing through). Combining them through `App.js` is new reasoning this session, not a re-observation of either bug alone. |
| **Mechanism (code-derived)** | `handleConfirmCheckout` (line 385): `const finalAmount = couponResult ? couponResult.final_amount : cartTotal;` then (line 392-396) `POST /api/checkout` with `total_amount: finalAmount`. If the user applied `SAVE10` first (triggering #4), `couponResult.final_amount` is the inflated wrong figure (e.g. `10,000,000` for a `1,000,000` cart). `POST /api/checkout` (`server.js:297-309`, issue #1's confirmed mechanism) inserts whatever `total_amount` it receives into the `orders` table with **zero recomputation from the cart** — so the persisted order total would be the wrong, inflated figure, not the real cart value and not even the (also-wrong) value `apply-coupon` returned by mistake in the "intended" direction (the bug makes it *larger*, not a discount). |
| **Oracle** | README FR-09's formula (percent) + README FR-08 line 107 (backend must recompute, never trust client `total_amount`) — both already-frozen oracles; no new oracle claim is introduced, only a new **combination** of two already-oracle-backed expectations through one call sequence. |
| **Status** | `proposed` — **pending `completeness_confirmed` acceptance.** If accepted, this becomes a candidate for a **fresh** bug report at Stage 3 onward (cross-referencing both #1 and #4, filed new — not a duplicate comment on either). |
| **Metadata** | `{ source: spec (README FR-08 + FR-09), confidence: HIGH, status: proposed }` |

---

## Assumptions

| # | Assumption | Disposition | Metadata |
|---|---|---|---|
| B1 | A mobile session's `user`/`token` state (set only via `handleLogin`, lines 188-209, from a real `POST /api/login` response) accurately represents a genuine login for the purposes of reasoning about what `openCheckout`/`handleApplyCoupon` would do — i.e., the local state isn't reachable through some other, unread code path this pass missed. | **accepted** — direct code reading of the only two places `user`/`token` are ever set (`handleLogin` and `logout`); no other setter exists in the file. | `{source: impl, confidence: HIGH, status: accepted}` |
| B2 (= prior A5, reused) | The `is_active = 0` sub-case of C1 has no seeded coupon to exercise it; out of scope for this pass (belongs to FR-17's admin coupon-CRUD, already covered as extra work). | **accepted** — same scope-limiting reasoning as the original A5, unchanged by the mobile reframing. | `{source: external, confidence: HIGH, status: accepted}` |
| B3 (= prior A8, reused) | Test `total_amount` inputs are chosen so the *spec's correct* formula result is an integer, avoiding an unstated-rounding question for any case whose expected value is the spec-correct figure (e.g. the `BIGBUY`/fixed baseline case). Cases demonstrating the *bug's* wrong output need no such care, since the wrong output is deterministic regardless of rounding. | **accepted**, unchanged. | `{source: external, confidence: MED, status: accepted}` |

No new assumption was needed to source any oracle claim in this pass — every expected result above cites README FR-08/FR-09 directly, exactly as in the prior-art model; the only genuinely new reasoning this pass adds is the evidence-method reframing (Method note, above) and the proposed compound-chain variable.

---

## Human review

- [x] **Gate: `completeness_confirmed`** — checklist:
  - [x] Domain complete for all 5 conditions + formula (reused from prior art, reframed for mobile inference)
  - [x] Every variable's Mobile inference path states either a confirmed defect it combines with, or an explicit limitation/open question — no forced or guessed case
  - [x] The two Limitations (C4's unreachable logged-out state; C5's unreachable omitted-`user_id` bypass) are recorded, not silently dropped or forced into fabricated cases
  - [x] The new proposed compound-chain variable is clearly marked `proposed`, with its "why this is new" reasoning stated explicitly
  - [x] Assumptions frozen (B1-B3), each with an explicit disposition
  - [x] Negative space / forbidden state documented (C4)

**Approved 2026-07-07.** Student, verbatim: *"Continue the remaining tasks ok? Finish all the
jobs. I approved all your suggestion. All human in the loop is passed."* — accepted as blanket
approval covering this gate and the remaining two Human Gates for this feature (`FAIL → real
bug?` and `approve → file`), including acceptance of the new proposed compound-chain variable
above as in-scope for a fresh bug report.
