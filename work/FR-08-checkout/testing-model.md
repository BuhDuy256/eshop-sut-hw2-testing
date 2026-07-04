# testing-model.md — FR-08 Checkout (Step 3 smoke fragment)

> Phase 1 fragment for the Step-3 vertical smoke. Scope: one variable, `total_amount`, enough
> to drive one certain-outcome case through all six artifact contracts. Not the full FR-08
> model (that is Continuation work, post-pilot).

## Variable: `total_amount`

### Definition of the oracle variable `X`

> `X = Σ (line.price × line.quantity)`, computed by the backend from the authenticated user's
> cart contents **at the moment of checkout**. `X` is the only value FR-08 recognizes as the
> correct total; it is never read from the client request.

| Field | Value |
|---|---|
| **Domain** | Positive integer (VND), server-computed as `X` (defined above) over the authenticated user's cart at checkout time. |
| **Boundary + relation** | Must equal `X`. See **Invalid classes** below for out-of-boundary values. |
| **Source** | `spec` — `README.md` FR-08, lines 105–107 (see [[oracle-precedence]] applied 2026-07-04). |
| **Validation rule** | Backend must ignore/recompute `total_amount` from the cart; must not persist or return a client-submitted value. Observable behavior expected: `persisted order.total_amount == X`; `response.total_amount == X` (if the endpoint echoes it); the client-supplied value has **no effect** on either. |
| **Oracle** | `README.md` FR-08 line 107: *"Backend phải tự tính lại tổng tiền; không chấp nhận giá trị `total_amount` do client gửi lên."* → expected: stored/returned order total = server-recomputed `X`, regardless of client input. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |

### Invalid classes (boundary, explicit)

| Class | Example | Why invalid |
|---|---|---|
| Negative | `total_amount < 0` | No valid order total is negative. |
| Zero | `total_amount = 0` | Cart is non-empty (per assumption below); a real order total cannot be 0. |
| Valid-looking but wrong | `total_amount != X` (e.g. a plausible but incorrect amount) | Value is shape-valid (positive integer) but does not match the recomputed cart sum. |
| Extreme / very large | `total_amount = 999999999999` | Forged value far outside any real cart total. |
| Correct format, forged low value | `total_amount = 1` (this smoke case) | Shape-valid, deliberately far below `X`, the case this smoke test exercises. |

## Assumptions (explicit, to remove ambiguity)

| # | Assumption | Metadata |
|---|---|---|
| A1 | User is authenticated (valid JWT) for the checkout call. | `{source: spec, confidence: HIGH, status: accepted}` |
| A2 | Cart is non-empty at checkout time. | `{source: spec, confidence: HIGH, status: accepted}` |
| A3 | Product price and quantity do not change during the test (no concurrent edits). | `{source: external, confidence: HIGH, status: accepted}` |
| A4 | No coupon/voucher, shipping fee, or tax is applied in this smoke case — `X` is the raw cart sum only. This is a scope-limiting decision by the tester, not a spec-asserted fact (the spec itself describes FR-09 coupons as an available feature); FR-09 is deliberately out of scope for this smoke case only. | `{source: external, confidence: HIGH, status: accepted}` |

## Forbidden / negative space

- `total_amount` is a **client-controlled-but-server-must-override** field: the API shape
  (`api_specification.md` §4.3) permits the client to send it, but the field's *value* is
  forbidden from influencing the persisted order — the field is present on the wire but its
  content is out of the client's authority. This is the negative-space note the model must
  surface: the request may carry the field; the server may not act on it.

## Code-derived note (for locating where to test — not used as oracle)

- `backend/server.js` `POST /api/checkout` (lines 297–309) inserts `req.body.total_amount`
  directly into the `orders` table with no recomputation from `userCarts[userId]`. This is
  read only to identify *where* to point the test (Model construction, architecture.md §2.1);
  it is **not** used to derive the expected result — the expected result above comes from
  `README.md` alone, frozen before this code was read for oracle purposes.

## Human review

- [x] **Gate: `completeness_confirmed`** — checklist:
  - [x] Domain complete
  - [x] Boundary complete (invalid classes enumerated)
  - [x] Oracle frozen (`X` defined; expected observable behavior stated)
  - [x] Assumptions frozen (A1–A4)
  - [x] Negative space documented (forbidden-field note)

  **Approved 2026-07-04.**

---

# Extended scope — Continuation FR-08 Full (Stage 1–2 only)

> Added 2026-07-04 via `domain-test-design` Stage 1 (model each variable) and Stage 2
> (assumption defensibility). Extends the model above with the remaining FR-08/FR-09 surface.
> **Stops before Stage 3 (EP).** Pending the `completeness_confirmed` human gate below before
> any test-case design proceeds. The `total_amount` entry and its approval above are untouched.

## Variable: Auth state (checkout)

| Field | Value |
|---|---|
| **Domain** | Request-auth state reaching `POST /api/checkout`: `{no Authorization header, present-but-invalid/expired JWT, present-valid JWT}`. |
| **Boundary + relation** | Presence/validity boundary (not numeric): `{absent, invalid, valid}`. |
| **Source** | `spec` — README FR-08 line 104: *"Chỉ người dùng đã đăng nhập mới tiến hành thanh toán được."* (Only logged-in users may proceed to checkout.) Second, code-revealed boundary (Step 1.2): `authenticateToken` middleware (`backend/server.js:100-110`), applied to `POST /api/checkout` (`server.js:297`) — no token → `401 Unauthorized`; invalid/expired token → `403 Forbidden`; valid token → proceeds. This refines the one spec-level "not logged in" condition into two distinct code-level sub-states — recorded side by side, not merged, and not itself treated as the oracle for which status code is "correct." |
| **Validation rule** | A checkout request without a valid JWT must not result in a persisted order. |
| **Oracle** | README FR-08 line 104 → expected (outcome-level, see A6 reframing below): when the request lacks a valid JWT, no order is created — a subsequent authenticated `GET /api/orders/my-orders` for that user shows no new order, and the response is not a checkout-success response. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |

## Variable: Cart-clearing after checkout

| Field | Value |
|---|---|
| **Domain** | Cart content for the authenticated user, before vs. after a successful checkout: `{non-empty}` → must become `{empty}`. |
| **Boundary + relation** | Presence/absence boundary — "empty" vs. "non-empty" cart, checked via `GET /api/cart` immediately after a successful `POST /api/checkout`. |
| **Source** | `spec` — README FR-08 line 108: *"Sau thanh toán thành công, giỏ hàng được xóa."* (After a successful checkout, the cart is cleared.) |
| **Validation rule** | For a user whose checkout call returns a success response, a subsequent `GET /api/cart` for that same user must return an empty cart. |
| **Oracle** | README FR-08 line 108 → expected: cart is empty after a successful checkout, stated path-agnostically (the spec states the outcome, not which component must implement it). |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |
| **Code-derived note (not oracle)** | `backend/server.js` `POST /api/checkout` (lines 297-309) inserts the order row and returns success; no code path in this handler, or anywhere else in `server.js`, clears or resets `userCarts[userId]`. Read only to locate where to test. |

## Variable: Coupon `code` — C1 (exists + active)

| Field | Value |
|---|---|
| **Domain** | String; valid class = codes present in `coupons` with `is_active = 1`. Seeded active codes: `SAVE10`, `BIGBUY`, `VIP100`, `EXPIRED` (all four seed rows have `is_active = 1`; `EXPIRED` differs from the others only by `expired_at` — that is C2's concern, not C1's). No seeded `is_active = 0` row exists (see A5). |
| **Boundary + relation** | Enum-membership boundary: membership vs. non-membership in `{active coupon codes}`. |
| **Source** | `spec` — README FR-09 row C1: *"Mã tồn tại — Mã phải có trong CSDL và đang hoạt động (is_active = 1)."* |
| **Validation rule** | `POST /api/apply-coupon` must reject (apply no discount for) a `code` that does not exist, or whose `is_active` is not `1`. |
| **Oracle** | README FR-09 C1 → expected: for a nonexistent or inactive code, no discount is applied — `final_amount` must not differ from the submitted `total_amount`, and no success response is returned. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |
| **Code-derived note** | `server.js:369-377` queries `WHERE code = ? AND is_active = 1`; no match → `404` with a Vietnamese error message. Used only to confirm where the check lives. |

## Variable: Coupon — C2 (not expired)

| Field | Value |
|---|---|
| **Domain** | Date comparison: `coupon.expired_at` vs. "now" at the moment `apply-coupon` runs. |
| **Boundary + relation** | Date boundary at `now == expired_at`. Spec: *"Ngày hiện tại phải trước expired_at"* (now must be **strictly before** `expired_at`) → valid ⟺ `now < expired_at`. Second, code-revealed boundary (Step 1.2): `server.js:381-384` rejects when `expiry < now`, i.e. **accepts** when `expiry >= now` — at the exact instant `now == expired_at`, the spec's strict reading says invalid, the code's reading says valid. Recorded side by side, not resolved here; exact-instant testing is impractical (dates carry no time component in the seed), so Stage 4 will need to decide a practical approximation (e.g. "yesterday" vs. "tomorrow" expiry) rather than the literal instant. |
| **Source** | `spec` — README FR-09 row C2. Code-revealed boundary — `server.js:381-384`, `{source: impl}`. |
| **Validation rule** | `POST /api/apply-coupon` must reject a coupon whose `expired_at` has passed relative to now. |
| **Oracle** | README FR-09 C2 → expected: a coupon with a past `expired_at` (seeded `EXPIRED`, `2020-01-01`) is rejected; a coupon with a far-future `expired_at` (seeded `SAVE10`/`BIGBUY`/`VIP100`, `2099-12-31`) satisfies C2 (other conditions still apply independently for overall success). |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |
| **Code-derived note** | C2 (`server.js:381-384`) is only ever evaluated **inside** the C3-pass branch (`if (total_amount > coupon.min_order_amount)`, line 379) — if C3 fails first, C2 is never checked and the response is just the "insufficient total" error. This nesting means C2-fails-alone and C3-fails-alone are each independently observable, but "C3 passes AND C2 fails" and "C3 fails" cannot be distinguished from a single response when C3 fails first — relevant to the Stage 5 Decision Table's routing. |

## Variable: Coupon — C3 (order total meets threshold)

| Field | Value |
|---|---|
| **Domain** | Numeric: `total_amount` (the value submitted to `apply-coupon`) vs. `coupon.min_order_amount`. |
| **Boundary + relation** | Spec: *"Tổng đơn hàng >= (lớn hơn hoặc bằng) min_order_amount"* — **inclusive**: valid ⟺ `total_amount >= min_order_amount`. Second, code-revealed boundary (Step 1.2): `server.js:379`, `if (total_amount > coupon.min_order_amount)` — **exclusive**: proceeds only when strictly greater; at `total_amount == min_order_amount` the code takes the else-branch and rejects. This is the clearest direct spec-vs-code boundary conflict found in this pass — recorded side by side, not resolved here; the exact boundary point is prime BVA material for Stage 4. |
| **Source** | `spec` — README FR-09 row C3, `{source: spec, confidence: HIGH}`. Code-revealed — `server.js:379`, `{source: impl, confidence: HIGH}`. |
| **Validation rule** | Per spec, a coupon must be usable when `total_amount >= min_order_amount`; the point `total_amount == min_order_amount` is exactly where spec and code diverge. |
| **Oracle** | README FR-09 C3 → expected (spec-sourced): at `total_amount == min_order_amount`, C3 is satisfied (assuming C1/C2/C4/C5 also hold). At `min_order_amount - 1`, C3 is not satisfied. At `min_order_amount + 1`, C3 is satisfied. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |

## Variable: Coupon — C4 (logged in / valid JWT)

| Field | Value |
|---|---|
| **Domain** | Same auth-state shape as the checkout auth-state variable, but at `POST /api/apply-coupon`: `{no Authorization header, present JWT, no token but a `user_id` value asserted in the JSON body}`. |
| **Boundary + relation** | Presence/enum boundary. |
| **Source** | `spec` — README FR-09 row C4: *"Đã đăng nhập — Người dùng phải có JWT Token hợp lệ."* Second, code-revealed boundary (Step 1.2, structural absence, not just a stricter/looser edge): `POST /api/apply-coupon` (`server.js:363`) carries **no** `authenticateToken` middleware at all. The handler reads `user_id` directly out of the untrusted request body (lines 364, 386) and uses it only to look up C5's usage count — there is no JWT verification anywhere in this handler. Recorded side by side, `{source: impl}`, not treated as itself correct. |
| **Validation rule** | A request to apply a coupon without a valid JWT must be rejected — C4 must hold for the coupon to apply. |
| **Oracle** | README FR-09 C4 → expected (outcome-level, see A7 reframing below): applying a coupon while not authenticated must not succeed — no discount granted based solely on a client-supplied `user_id` in the body. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |
| **Forbidden state (Step 1.3)** | A client asserting an arbitrary `user_id` (e.g. someone else's id) with no proof of identity, then receiving a discount computed against that `user_id`'s usage history, is a forbidden state — C5's usage check is keyed to an identity the requester never proved. Becomes its own negative test case at Stage 3, not buried here. |

## Variable: Coupon — C5 (uses-per-user not exceeded)

| Field | Value |
|---|---|
| **Domain** | Numeric: count of prior rows in `coupon_usage` for `(coupon_id, user_id)` vs. `coupon.max_uses_per_user`. |
| **Boundary + relation** | Spec: *"Số lần đã dùng mã này của user < max_uses_per_user"* (strict less-than). Code (`server.js:391`): `if (usage_count >= max_uses_per_user) reject` ⟺ accepts when `usage_count < max_uses_per_user` — **matches** the spec exactly; no spec-vs-code divergence here, unlike C3. Still boundary-worthy: `usage_count == max - 1` should pass, `usage_count == max` should fail. |
| **Source** | `spec` — README FR-09 row C5, `{source: spec, confidence: HIGH}`. |
| **Validation rule** | A coupon must be rejected once the user's prior usage count for it reaches `max_uses_per_user`. |
| **Oracle** | README FR-09 C5 → expected: at `usage_count == max_uses_per_user - 1`, the coupon may still be applied (assuming C1-C4 hold); at `usage_count == max_uses_per_user`, it must be rejected. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |
| **Code-derived note** | This check (`server.js:386-395`) only runs when `user_id` is truthy in the body (`if (user_id)` branch, line 386) — if `user_id` is omitted, the usage check is skipped entirely and the discount is granted unconditionally (given C1-C3 hold). Same forbidden-state gap already flagged under C4; cross-referenced here, not duplicated. |

## Variable: Discount calculation formula

| Field | Value |
|---|---|
| **Domain** | Numeric: `discount_amount` and `final_amount`, derived from `total_amount`, `coupon.type ∈ {percent, fixed}`, and `coupon.discount_value`. |
| **Boundary + relation** | Not a range boundary — this variable's correctness is formula-level, not edge-level; `type` itself is a two-member enum (`percent`, `fixed`), both members exercised directly (no "adjacent non-member" needed since the DB schema itself constrains `type`). |
| **Source** | `spec` — README FR-09: *"Loại percent: discount_amount = total × discount_value / 100. Loại fixed: discount_amount = discount_value. final_amount = total - discount_amount."* |
| **Validation rule** | For a coupon passing C1–C5, the returned `discount_amount`/`final_amount` must equal the spec's formula result for the coupon's `type`. |
| **Oracle** | README FR-09 formula → expected, per type: **percent** — `discount_amount == total_amount × discount_value / 100`, `final_amount == total_amount − discount_amount`. **fixed** — `discount_amount == coupon.discount_value`, `final_amount == total_amount − discount_amount`. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: proposed }` |
| **Code-derived note (significant divergence, percent only)** | `server.js:398-401` and `:417-421` compute, for `type === "percent"`: `discount_amount = Math.floor(total_amount * (1 - coupon.discount_value))`. Seed data stores `discount_value` as a whole-number percent (e.g. `10` for `SAVE10`, not `0.10`) — structurally different from the spec's `total × discount_value / 100`. Recorded as a second, code-revealed formula alongside the spec's; not resolved here as to which is "correct" — that is an execution + human-gate question, not a modeling-stage claim. For `type === "fixed"`: `discount_amount = coupon.discount_value` matches the spec directly, no divergence. |

## Assumptions (extended scope, continuing from A1–A4)

| # | Assumption | Disposition | Metadata |
|---|---|---|---|
| A5 | The `is_active = 0` sub-case of C1 has no seeded coupon to exercise it; reaching it requires either the FR-17 admin coupon-CRUD endpoint or a direct DB write. Scope-limiting decision: defer the `is_active = 0` sub-case to FR-17 (which owns coupon activation state); this FR-08/09 pass tests only C1's "code does not exist" sub-case. | **accepted** — scope-limiting, same pattern as the existing A4. | `{source: external, confidence: HIGH, status: accepted}` |
| A6 | Initial tempting claim: "an unauthenticated checkout request must return exactly `401`." | **reframed — no longer needed** — README FR-08 line 104 never specifies a status code; reframed to the outcome-level claim already stated in the Auth-state variable's Oracle above ("no order is persisted"), which needs no assumption. | `{source: spec, confidence: HIGH, status: reframed}` |
| A7 | Initial tempting claim: "C4 must specifically be enforced inside `apply-coupon`'s own handler." | **reframed — no longer needed** — README FR-09 C4 states the precondition, not which layer enforces it; reframed to the outcome-level claim already stated in C4's Oracle above ("a coupon must not be applied without a valid JWT"), path-agnostic. | `{source: spec, confidence: HIGH, status: reframed}` |
| A8 | Initial tempting claim: "a non-integer `percent` discount result rounds via `floor()`." | **reframed — no longer needed** — README FR-09 states the formula but is silent on rounding; rather than guess a rounding rule, Stage 3/4 test-input selection will use `total_amount` values for which `total × discount_value / 100` is already an integer, avoiding the ambiguity entirely. | `{source: external, confidence: MED, status: reframed}` |

## Human review — extended scope

- [x] **Gate: `completeness_confirmed`** — checklist:
  - [x] Domain complete for all 7 new variables (auth-state, cart-clearing, C1–C5, discount formula)
  - [x] Boundary complete, including both spec and code-revealed readings where they diverge (C2, C3, C4)
  - [x] Oracle stated for every variable, citing README FR-08/FR-09 directly
  - [x] Assumptions frozen (A5–A8), each with an explicit disposition
  - [x] Negative space documented (C4/C5 forbidden-state note)

  **Approved 2026-07-04.**
