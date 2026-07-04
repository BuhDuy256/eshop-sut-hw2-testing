# FR-08 — Boundary Value Analysis Report

> Continuation FR-08 Full, added 2026-07-04 via `domain-test-design` Stage 4. Model reference:
> `work/FR-08-checkout/testing-model.md`, "Extended scope" section (approved 2026-07-04).
> Covers the three genuinely boundary-shaped FR-09 conditions: C3 (order threshold), C5
> (uses-per-user), and C2 (expiry). C1 and C4 are presence/enum-shaped, not numeric-range
> boundaries, and are already fully exercised by the EP cases in `domain-testing/report.md`
> (`TC-08-EP-005`, `TC-08-EP-008`) — no separate BVA case is added for them, per the
> over-partitioning guard (a further split would not change the expected outcome).

## Boundary set 1 — C3, order threshold (`min_order_amount`), coupon `SAVE10` (300,000₫)

| Field | Value |
|---|---|
| **Boundary kind** | Numeric range, inclusive at the minimum. README FR-09 row C3: *">= (lớn hơn hoặc bằng) min_order_amount"*. Code-revealed second reading (`server.js:379`): exclusive `>`. See the model's C3 entry for both readings recorded side by side. |
| **Values generated (Step 4.2)** | `min_order_amount − 1 = 299,999` (just below); `min_order_amount = 300,000` (exact boundary — the spec/code divergence point); `min_order_amount + 1 = 300,001` (just above). |

### TC-08-BVA-001 — `total_amount = 299,999` (just below threshold)

| Field | Value |
|---|---|
| **Preconditions** | None. |
| **Input** | `POST /api/apply-coupon` `{"code": "SAVE10", "total_amount": 299999, "user_id": <test@eshop.com's id>}`, authenticated. |
| **Expected result** | Rejected — below threshold under both the spec's and the code's reading (no divergence at this point). |
| **`expected_source`** | `spec` — README FR-09 row C3. |
| **Status** | frozen. |

### TC-08-BVA-002 — `total_amount = 300,000` (exact boundary — the flagship divergence case)

| Field | Value |
|---|---|
| **Preconditions** | None. |
| **Input** | `POST /api/apply-coupon` `{"code": "SAVE10", "total_amount": 300000, "user_id": <id>}`, authenticated. |
| **Expected result** | **Per README FR-09's stated `>=`: accepted** — C3 is satisfied at exactly `min_order_amount`, and (assuming C1/C2/C4/C5 also hold) the discount is applied. This is the spec-sourced expected result; the code's `>` reading would instead reject this exact input — that is the divergence this case exists to surface, decided by execution + the human `FAIL → real bug?` gate, not asserted here as already-confirmed. |
| **`expected_source`** | `spec` — README FR-09 row C3 (`>=`, inclusive). |
| **Status** | frozen. |

### TC-08-BVA-003 — `total_amount = 300,001` (just above threshold)

| Field | Value |
|---|---|
| **Preconditions** | None. |
| **Input** | `POST /api/apply-coupon` `{"code": "SAVE10", "total_amount": 300001, "user_id": <id>}`, authenticated. |
| **Expected result** | Accepted — above threshold under both readings (no divergence at this point). |
| **`expected_source`** | `spec` — README FR-09 row C3. |
| **Status** | frozen. |

## Boundary set 2 — C5, uses-per-user (`max_uses_per_user`), coupon `VIP100` (max = 2)

| Field | Value |
|---|---|
| **Boundary kind** | Numeric range, upper bound. README FR-09 row C5: *"Số lần đã dùng... < max_uses_per_user"* (strict less-than). Code (`server.js:391`) matches this exactly — no spec/code divergence here, unlike C3; still boundary-worthy. `VIP100` (max = 2) is used instead of `SAVE10` (max = 1) so both "just below" and "at" the boundary are distinct, non-zero usage counts. |
| **Values generated (Step 4.2)** | `max − 1 = 1` prior use (just below — one more use still allowed); `max = 2` prior uses (exact boundary — exhausted). |

### TC-08-BVA-004 — `usage_count = 1` (max − 1, one more use allowed)

| Field | Value |
|---|---|
| **Preconditions** | `test@eshop.com` has recorded exactly 1 prior usage of `VIP100` (`POST /api/coupon-usage` once). |
| **Input** | `POST /api/apply-coupon` `{"code": "VIP100", "total_amount": 400000, "user_id": <id>}`, authenticated (400,000 clears `VIP100`'s 300,000 threshold). |
| **Steps** | 1. Login. 2. `POST /api/coupon-usage` `{"coupon_id": <VIP100's id>}` once. 3. Send the `apply-coupon` request above. |
| **Expected result** | Accepted — `usage_count (1) < max_uses_per_user (2)`; discount applied (`fixed`, `discount_amount = 100,000`, `final_amount = 300,000`). |
| **`expected_source`** | `spec` — README FR-09 row C5 + formula section. |
| **Status** | frozen. |

### TC-08-BVA-005 — `usage_count = 2` (max, exact boundary — exhausted)

| Field | Value |
|---|---|
| **Preconditions** | Continue from TC-08-BVA-004: `test@eshop.com` now records a second usage of `VIP100`, reaching `usage_count = 2`. |
| **Input** | Same as TC-08-BVA-004, after one more `POST /api/coupon-usage` call. |
| **Steps** | 1. `POST /api/coupon-usage` `{"coupon_id": <VIP100's id>}` a second time (now `usage_count = 2`). 2. Send the same `apply-coupon` request again. |
| **Expected result** | Rejected — `usage_count (2)` has reached `max_uses_per_user (2)`. |
| **`expected_source`** | `spec` — README FR-09 row C5. |
| **Status** | frozen. |

## Boundary set 3 — C2, expiry, practical near-instant approximation

| Field | Value |
|---|---|
| **Boundary kind** | Date boundary. README FR-09 row C2: *"Ngày hiện tại phải trước expired_at"* — strictly before. Code-revealed second reading (`server.js:381-384`): accepts when `expiry >= now` (inclusive at the exact instant), diverging from the spec's strict reading exactly at `now == expired_at`. |
| **Practicality note** | The seeded `expired_at` values carry no time component, and hitting the literal instant `now == expired_at` deterministically is impractical at real-clock precision. This BVA substitutes a practical near-boundary pair — `expired_at` = yesterday vs. tomorrow (relative to execution time) — rather than the exact instant. This is a test-execution practicality choice, not a new oracle assumption: the oracle for each of the two practical points is still a direct, unambiguous spec reading (clearly-past date → invalid; clearly-future date → valid); only the exact-instant case (already out of scope for this pair) is where the spec/code divergence actually lives, and it is called out above, not silently dropped. |
| **Setup (both cases)** | Two coupons created via `POST /api/admin/coupons` (admin-authenticated) purely as test data, not as a test of FR-17's CRUD itself: `TESTEXP_PAST` (`type: "fixed"`, `discount_value: 10000`, `min_order_amount: 0`, `expired_at`: yesterday's date, `max_uses_per_user: 1`) and `TESTEXP_FUTURE` (same shape, `expired_at`: tomorrow's date). The admin-create endpoint does not accept an `is_active` field and the schema defaults it to `1` (`database.js:36`), so both are active — isolating C2 alone. |

### TC-08-BVA-006 — `expired_at` = yesterday (just past)

| Field | Value |
|---|---|
| **Preconditions** | `TESTEXP_PAST` created per the setup above. |
| **Input** | `POST /api/apply-coupon` `{"code": "TESTEXP_PAST", "total_amount": 50000, "user_id": <id>}`, authenticated. |
| **Expected result** | Rejected — `expired_at` has passed. |
| **`expected_source`** | `spec` — README FR-09 row C2. |
| **Status** | frozen. |

### TC-08-BVA-007 — `expired_at` = tomorrow (just future)

| Field | Value |
|---|---|
| **Preconditions** | `TESTEXP_FUTURE` created per the setup above. |
| **Input** | `POST /api/apply-coupon` `{"code": "TESTEXP_FUTURE", "total_amount": 50000, "user_id": <id>}`, authenticated. |
| **Expected result** | Accepted — `expired_at` has not passed; discount applied (`fixed`, `discount_amount = 10,000`, `final_amount = 40,000`). |
| **`expected_source`** | `spec` — README FR-09 row C2 + formula section. |
| **Status** | frozen. |

## Traceability

Every case above references its model entry in `work/FR-08-checkout/testing-model.md`
("Extended scope" section) and, where it targets a spec-vs-code divergence (`TC-08-BVA-002`),
the divergence is stated as two readings — the expected result comes only from the spec's
reading, never from the code's.
