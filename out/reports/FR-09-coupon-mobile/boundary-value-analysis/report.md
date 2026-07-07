# FR-09 (Mobile) — Boundary Value Analysis Report

> Continuation item 5. Model reference: `work/FR-09-coupon-mobile/testing-model.md` (approved
> 2026-07-07). Covers the two genuinely boundary-shaped FR-09 conditions reachable via the
> mobile client: C3 (order threshold) and C5 (uses-per-user), plus a practical-substitution pair
> for C2 (expiry). C1 and C4 are presence/enum-shaped, already exercised by the EP cases in the
> sibling `domain-testing/report.md` (`TC-09-EP-001`, `TC-09-EP-003`) — no separate BVA case, per
> the over-partitioning guard.
>
> **Evaluation-method note (applies to every case below):** evaluated by code-derived inference
> from `frontend-mobile/App.js`, combined with an already-confirmed backend defect where one
> applies — never by live mobile execution. `Expected` states only the spec-correct behavior;
> the inferred `actual` lives in `work/FR-09-coupon-mobile/execution-results.md`.

## Boundary set 1 — C3, order threshold (`min_order_amount`), coupon `SAVE10` (300,000₫)

| Field | Value |
|---|---|
| **Boundary kind** | Numeric range, inclusive at the minimum. README FR-09 row C3: `>=`. Code-revealed second reading (`server.js:379`): exclusive `>` — **confirmed bug #5**. |
| **Values generated** | `299,999` (just below); `300,000` (exact boundary — the divergence point); `300,001` (just above). |

### TC-09-BVA-001 — Cart total = 299,999 (just below threshold)

| Field | Value |
|---|---|
| **Preconditions** | Mobile user logged in, has not used `SAVE10`. |
| **Input** | Coupon code `SAVE10`, cart total 299,999₫. |
| **Expected result** | Rejected — below threshold under both the spec's and the code's reading (no divergence at this point). |
| **`expected_source`** | `spec` — README FR-09 row C3. |
| **Status** | frozen. |

### TC-09-BVA-002 — Cart total = 300,000 (exact boundary)

| Field | Value |
|---|---|
| **Preconditions** | Mobile user logged in, has not used `SAVE10`. |
| **Input** | Coupon code `SAVE10`, cart total 300,000₫. |
| **Expected result** | Per README FR-09's stated `>=`: accepted — C3 is satisfied at exactly `min_order_amount`, and the discount is applied. |
| **`expected_source`** | `spec` — README FR-09 row C3 (`>=`, inclusive). |
| **Status** | frozen. |

### TC-09-BVA-003 — Cart total = 300,001 (just above threshold)

| Field | Value |
|---|---|
| **Preconditions** | Mobile user logged in, has not used `SAVE10`. |
| **Input** | Coupon code `SAVE10`, cart total 300,001₫. |
| **Expected result** | Accepted — above threshold under both readings (no divergence at this point). |
| **`expected_source`** | `spec` — README FR-09 row C3. |
| **Status** | frozen. |

## Boundary set 2 — C5, uses-per-user (`max_uses_per_user`), coupon `VIP100` (max = 2)

| Field | Value |
|---|---|
| **Boundary kind** | Numeric range, upper bound. README FR-09 row C5: strict `<`. Code (`server.js:391`) matches this exactly for the *honest* mobile flow — no spec/code divergence here (unlike C3), still boundary-worthy. |

### TC-09-BVA-004 — `usage_count = 1` (max − 1, one more use allowed)

| Field | Value |
|---|---|
| **Preconditions** | Mobile user logged in, has recorded exactly 1 prior usage of `VIP100` through the app's own checkout-confirm flow (`handleConfirmCheckout` → `POST /api/coupon-usage`, App.js:401-410). |
| **Input** | Coupon code `VIP100`, cart total 400,000₫ (clears the 300,000₫ threshold). |
| **Expected result** | Accepted — `usage_count (1) < max_uses_per_user (2)`; discount applied (`fixed`, `discount_amount = 100,000`, `final_amount = 300,000`). |
| **`expected_source`** | `spec` — README FR-09 row C5 + formula section. |
| **Status** | frozen. |

### TC-09-BVA-005 — `usage_count = 2` (max, exact boundary — exhausted)

| Field | Value |
|---|---|
| **Preconditions** | Continuing from `TC-09-BVA-004`: the same mobile user records a second usage of `VIP100` via the same app flow. |
| **Input** | Same as `TC-09-BVA-004`, after a second successful checkout confirmation recording usage. |
| **Expected result** | Rejected — `usage_count (2)` has reached `max_uses_per_user (2)`. |
| **`expected_source`** | `spec` — README FR-09 row C5. |
| **Status** | frozen. |

## Boundary set 3 — C2, expiry, practical near-instant approximation

| Field | Value |
|---|---|
| **Boundary kind** | Date boundary. README FR-09 row C2: strictly before. Code-revealed second reading (`server.js:381-384`): accepts when `expiry >= now`, diverging from spec only at the exact instant `now == expired_at`. |
| **Practicality note** | Same substitution as the prior-art FR-08-Full pass: the seeded `expired_at` values carry no time component, so this BVA uses a practical yesterday-vs-tomorrow pair rather than the exact instant. The exact-instant divergence is a genuine open question in this pass too — with no seeded coupon and no confirmed backend defect to anchor an inference to (the prior-art pass never executed that exact point either), it is **not inferable** here and is left unaddressed rather than guessed. |

### TC-09-BVA-006 — `expired_at` = yesterday (just past)

| Field | Value |
|---|---|
| **Preconditions** | A test coupon with `expired_at` set to yesterday relative to the (hypothetical) execution date exists and is active — same setup pattern as the prior-art `TESTEXP_PAST` coupon. |
| **Input** | The past-dated test coupon's code, cart total clearing its threshold. |
| **Expected result** | Rejected — `expired_at` has passed. |
| **`expected_source`** | `spec` — README FR-09 row C2. |
| **Status** | frozen. |

### TC-09-BVA-007 — `expired_at` = tomorrow (just future)

| Field | Value |
|---|---|
| **Preconditions** | A test coupon with `expired_at` set to tomorrow exists and is active — same setup pattern as the prior-art `TESTEXP_FUTURE` coupon. |
| **Input** | The future-dated test coupon's code, cart total clearing its threshold. |
| **Expected result** | Accepted — `expired_at` has not passed; discount applied per its formula. |
| **`expected_source`** | `spec` — README FR-09 row C2 + formula section. |
| **Status** | frozen. |

## Traceability

Every case above references its model entry in `work/FR-09-coupon-mobile/testing-model.md`;
`TC-09-BVA-002` targets the confirmed spec-vs-code divergence (issue #5) — its expected result
comes only from the spec's reading, never from the code's, exactly as the sibling EP report's
`TC-09-EP-004`/`006` do for the discount-formula and compound-chain findings.
