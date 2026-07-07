# FR-09 (Mobile) — Domain Testing Report

> Continuation item 5, corrected 4th assigned feature (Pool D — Mobile), replacing FR-17.
> Model reference: `work/FR-09-coupon-mobile/testing-model.md` (approved 2026-07-07).
>
> **Evaluation-method note (applies to every case below, not repeated per row):** every case in
> this report will be evaluated by **code-derived inference** from `frontend-mobile/App.js`,
> combined with an already-confirmed backend defect where one applies — **never by live mobile
> execution** (`docs/implementation-plan/continuation-handoff-FR09-mobile.md` §2). The inferred
> `actual` for each case lives in `work/FR-09-coupon-mobile/execution-results.md`, written only
> **after** this report is frozen and committed. `Expected` below states only the spec-correct
> behavior, exactly as MODEL≠ORACLE requires — it never mentions the bug mechanism itself; that
> belongs to the execution result and the bug report, not to the frozen expectation.

## Test Cases

### TC-09-EP-001 — Apply a nonexistent coupon code (C1 fails)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, C1 (exists + active). |
| **Model reference** | C1 variable, `work/FR-09-coupon-mobile/testing-model.md`. |
| **Preconditions** | Mobile user logged in (`user`/`token` set via `handleLogin`); on the Checkout screen's coupon box. |
| **Input** | Coupon code `NOPE_NOT_REAL` typed into the mobile coupon box and submitted via the "Áp dụng" button. |
| **Steps (as the mobile UI would perform them)** | 1. Type `NOPE_NOT_REAL` into the coupon field. 2. Tap "Áp dụng" (`handleApplyCoupon`). |
| **Expected result** | No discount is applied; the coupon box shows a rejection, not a success state. |
| **`expected_source`** | `spec` — README FR-09 row C1. |
| **Status** | frozen. |

### TC-09-EP-002 — Apply an expired coupon, threshold otherwise met (C2 fails)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, C2 (not expired). |
| **Model reference** | C2 variable. |
| **Preconditions** | Mobile user logged in; cart total ≥ `EXPIRED`'s `min_order_amount` (100,000₫), so the request reaches the C2 check. |
| **Input** | Coupon code `EXPIRED`, cart total 200,000₫. |
| **Steps** | 1. Cart total is 200,000₫. 2. Type `EXPIRED`, tap "Áp dụng". |
| **Expected result** | Rejected — the coupon's `expired_at` (2020-01-01) has passed. |
| **`expected_source`** | `spec` — README FR-09 row C2. |
| **Status** | frozen. |

### TC-09-EP-003 — A genuinely logged-in mobile user's coupon-apply request carries no proof of identity (C4)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class, C4 (logged in / valid JWT), mobile-specific instantiation. |
| **Model reference** | C4 variable. |
| **Preconditions** | Mobile user has genuinely logged in through the app's own login screen (real JWT held in `token` state). |
| **Input** | Any valid, unexhausted coupon code (e.g. `VIP100`), cart total meeting its threshold. |
| **Steps** | 1. Log in normally. 2. Add items reaching `VIP100`'s threshold. 3. Type `VIP100`, tap "Áp dụng". |
| **Expected result** | Per README FR-09 C4, a coupon must not be applied for a request that presents no valid JWT — the applying request must be rejected unless the client actually proves its identity. |
| **`expected_source`** | `spec` — README FR-09 row C4. |
| **Status** | frozen. |

### TC-09-EP-004 — Percent-type coupon discount (`SAVE10`, 10%)

| Field | Value |
|---|---|
| **Technique** | EP — invalid class (formula), discount-formula variable, `type = "percent"`. |
| **Model reference** | Discount-formula variable. |
| **Preconditions** | Mobile user logged in, has not used `SAVE10` before; cart total = 1,000,000₫ (chosen so the spec-correct result is an integer, per Assumption B3). |
| **Input** | Coupon code `SAVE10`, cart total 1,000,000₫. |
| **Steps** | 1. Cart total is 1,000,000₫. 2. Type `SAVE10`, tap "Áp dụng". |
| **Expected result** | `discount_amount = 1,000,000 × 10 / 100 = 100,000`; `final_amount = 900,000`, displayed in the coupon box. |
| **`expected_source`** | `spec` — README FR-09, "Công thức tính giảm giá," percent formula. |
| **Status** | frozen. |

### TC-09-EP-005 — Fixed-type coupon discount (`BIGBUY`, 50,000₫) — all conditions pass

| Field | Value |
|---|---|
| **Technique** | EP — valid class, discount-formula variable (`type = "fixed"`); also the all-conditions-pass representative for C1–C5. |
| **Model reference** | Discount-formula variable; C1–C5 (all pass). |
| **Preconditions** | Mobile user logged in, has not used `BIGBUY` before; cart total ≥ 500,000₫. |
| **Input** | Coupon code `BIGBUY`, cart total 600,000₫. |
| **Steps** | 1. Cart total is 600,000₫. 2. Type `BIGBUY`, tap "Áp dụng". |
| **Expected result** | `discount_amount = 50,000` (the coupon's fixed value); `final_amount = 550,000`, displayed in the coupon box. |
| **`expected_source`** | `spec` — README FR-09, "Công thức tính giảm giá," fixed formula; C1–C5 per README FR-09's condition table. |
| **Status** | frozen. |

### TC-09-EP-006 — Confirming checkout after a percent-coupon apply persists the correct order total

| Field | Value |
|---|---|
| **Technique** | EP — postcondition check on the compound (proposed) variable: mobile checkout after a coupon apply. |
| **Model reference** | New proposed compound-chain variable, `work/FR-09-coupon-mobile/testing-model.md` (approved, in scope per the student's blanket approval). |
| **Preconditions** | Mobile user logged in; applies `SAVE10` (percent) to a 1,000,000₫ cart, then taps "Xác Nhận Thanh Toán" to confirm checkout. |
| **Input** | Same as `TC-09-EP-004`, followed by a checkout confirmation. |
| **Steps** | 1. Apply `SAVE10` to a 1,000,000₫ cart (as in `TC-09-EP-004`). 2. Tap "Xác Nhận Thanh Toán" (`handleConfirmCheckout`). 3. (Reference only) check the persisted order's stored total. |
| **Expected result** | Per README FR-09's formula (`final_amount = 900,000` for this input) and README FR-08 line 107 (backend must recompute/persist the correct total, never a value it merely received unchecked): the order persisted by a successful checkout must have a stored total of `900,000` — the correct, spec-computed final amount, not any other figure. |
| **`expected_source`** | `spec` — README FR-09 formula + README FR-08 line 107. |
| **Status** | frozen. |

---

## Decision Table (Stage 5) — skipped for this mobile-framed pass, with reason

README FR-09 still states all 5 conditions must combine ("tất cả phải thỏa mãn"), same as the
prior-art FR-08-Full pass, which did build a 7-row Decision Table at the API level (filed under
issues #3–#5). For **this** mobile-framed, code-derived-inference pass specifically, no
additional Decision Table is built: every combined-condition scenario the mobile client's own
code could actually produce reduces to one of the individual per-condition cases already listed
above (each isolates one condition while holding the others at a passing value, exactly as the
EP/BVA cases do) — and the one combination that would add new information (C4+C5 both failing
at once, via an omitted `user_id`) is not producible through the mobile app's own normal flow at
all (see the Forbidden-state note below), so a table row for it would not be inferable, only
guessed. This is a pass-specific skip, not a re-litigation of the prior-art table's own scope
decision — a future live-execution pass on the mobile client (outside this handoff's
constraint) would be the place to actually test the combined case.

## Forbidden state (Step 1.3) — not designed as a case: open question

Per the Testing Model's Limitations, the combined C4+C5 bypass (an unauthenticated request that
also omits `user_id` entirely, exploiting both gaps in issue #3 at once) is **not reachable
through the mobile app's own normal button-tap flow** — `handleApplyCoupon` (App.js:370) always
sends `user_id: user?.id || null`, never an entirely absent field. Producing that exact request
would require tampering with the network call outside the app's own rendering/dispatch code,
which is outside this pass's "read the UI's rendering code" evidence boundary. **No case is
designed for it in this pass** — flagged here as an open question rather than guessed. The
generic (non-mobile-specific) version of this exact bypass is already covered and confirmed at
the API level by the prior FR-08-Full pass (`TC-08-DT-002`, filed as part of issue #3).

## Coverage rationale

`TC-09-EP-001..003` cover C1, C2, and C4 individually (one negative case each, C1/C2 predicting
correct baseline behavior, C4 predicting a spec violation the mobile client's own design
guarantees). `TC-09-EP-004/005` cover both discount-formula types (percent, fixed), with `005`
doubling as the all-conditions-pass valid-class representative. `TC-09-EP-006` extends the
Testing Model's newly proposed compound-chain variable into a concrete case. C3 and C5 are
boundary-shaped and are covered in the sibling `boundary-value-analysis/report.md` instead, per
the same over-partitioning guard used throughout this project (a further EP-level split of a
boundary condition would not change the expected outcome beyond what BVA already covers more
precisely).

## AI Gap Analysis

One judgment call worth flagging: `TC-09-EP-003`'s expected result is stated at the
outcome level ("must not be applied without a valid JWT") without asserting a specific status
code or error message, mirroring the same reframing (`A7`/`B`-series) already used in the prior
FR-08-Full pass — README FR-09 states the precondition, not the enforcement layer or the wire
format of a rejection. No new assumption was needed to support this; it is a direct reading of
what the spec's own wording commits to, same as the reused model.
