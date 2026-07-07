# FR-09 (Mobile) — Bug Reports

> Continuation item 5. All entries derive from `work/FR-09-coupon-mobile/execution-results.md`
> (4 FAILs out of 13 code-derived-inference cases). Per
> `docs/implementation-plan/continuation-handoff-FR09-mobile.md` §8: 3 of the 4 FAILs reconfirm
> already-filed defects (issues #3, #4, #5) from a new, mobile-specific code path — these are
> **reconfirmation notes**, posted as GitHub comments on the existing issues, not new bug
> reports. The 4th FAIL is a genuinely new finding (a mobile-only compound chain, not covered by
> any of #1/#3/#4/#5 individually) and is filed as a fresh bug report + GitHub issue.

## Stage 1 — Confirm each failure is a real defect

All 4 FAILs are code-derived inferences, not live executions, so the usual "test/setup
artifact" check (stale state, wrong credentials) does not apply — there is no environment to
have polluted. The relevant confirmation question instead is: **is the inference correctly
derived from the code, with no logical gap?** For all 4: the source lines cited in
`execution-results.md` were re-read directly for this confirmation step, the arithmetic/control
flow was re-traced by hand (e.g. `1,000,000 × (1 − 10) = -9,000,000`, confirmed), and each
inference rests on a value that reaches its destination unconditionally (no branch, error
handler, or intervening validation in the code that could break the chain). All 4 confirmed as
real.

## Stage 2 — Grouping

- `ER-09-EP-003` → root cause: issue #3 (no auth on `apply-coupon`). Same root cause, new
  evidence path (the client's own code, not just the server's gap). **Reconfirmation, not a
  new group.**
- `ER-09-EP-004` → root cause: issue #4 (percent formula). Same root cause, traced to its exact
  mobile render. **Reconfirmation, not a new group.**
- `ER-09-BVA-002` → root cause: issue #5 (C3 boundary `>` vs `>=`). Same root cause, traced to
  its exact mobile render. **Reconfirmation, not a new group.**
- `ER-09-EP-006` → root cause: **neither #1 nor #4 alone** — it is the specific, unconditional
  code path chaining them (`handleConfirmCheckout`'s `total_amount: couponResult.final_amount`
  into `POST /api/checkout`'s unchecked insert). Fixing #4 (the formula) or #1 (checkout
  recomputation) independently would each separately close this path, but as of today, with
  neither fixed, this chain is its own distinct, newly-traced defect. **New group.**

---

## Reconfirmation — issue #3 (`POST /api/apply-coupon` has no authentication)

**Ref:** `TC-09-EP-003` / `ER-09-EP-003`.

**New evidence (code-derived inference, not a live observation):** `frontend-mobile/App.js:358-372`
(`handleApplyCoupon`) never sends an `Authorization` header on this call, for any mobile user,
regardless of login state — identity is asserted purely via `user_id: user?.id || null` from
local app state. This means the mobile client's **own, honest, non-malicious** code already
constructs exactly the unauthenticated request issue #3 describes — the vulnerability is not
only reachable by a crafted attack; the official mobile client reaches it on every normal
coupon-apply tap.

**Action:** comment on GitHub issue #3 with this mobile-specific reinforcement; not filed as a
duplicate.

## Reconfirmation — issue #4 (percent-formula produces a negative discount)

**Ref:** `TC-09-EP-004` / `ER-09-EP-004`.

**New evidence (code-derived inference, not a live observation):** `frontend-mobile/App.js:728-732`
renders `couponResult.discount_amount`/`final_amount` directly through `formatMoney`, with no
sign-check anywhere in the render path. Applying `SAVE10` to a 1,000,000₫ cart would show
**"Tiết kiệm: -9.000.000 ₫"** and **"Thành tiền: 10.000.000 ₫"** on the coupon box, under a
green "✅" success message — the bug is not only a wrong number in an API response; it is a
literal negative-savings figure that would render on the customer-facing mobile screen.

**Action:** comment on GitHub issue #4 with this specific mobile render trace; not filed as a
duplicate.

## Reconfirmation — issue #5 (C3 threshold uses `>` instead of `>=`)

**Ref:** `TC-09-BVA-002` / `ER-09-BVA-002`.

**New evidence (code-derived inference, not a live observation):** `frontend-mobile/App.js:376-378`/`722-724`
renders the backend's rejection message (`"Đơn hàng chưa đủ giá trị tối thiểu 300.000 ₫..."`)
verbatim. A mobile user whose cart totals exactly `SAVE10`'s `min_order_amount` (300,000₫) would
see this rejection on their own screen, denying a discount the spec entitles them to.

**Action:** comment on GitHub issue #5 with this specific mobile render trace; not filed as a
duplicate.

---

## BUG-09-001 — Confirming mobile checkout after a broken percent-coupon apply persists a wildly inflated order total

| Field | Value |
|---|---|
| **ID** | `BUG-09-001` |
| **Title** | Mobile checkout persists `apply-coupon`'s broken percent-formula result as the order's stored total, with no recomputation |
| **Ref** | `TC-09-EP-006` (test case) / `ER-09-EP-006` (execution result) |
| **Severity** | Critical — `total_amount` is the SUT's sole financial record for an order (same reasoning as the already-confirmed `BUG-08-001`/issue #1: it is what the admin revenue dashboard aggregates, README line 183, and the only recorded amount owed). This chain persists a value **11× larger than the spec-correct total** (`10,000,000` vs. the correct `900,000`) and **10× the real cart value** (`1,000,000`), for any mobile user who applies a percent-type coupon and confirms checkout — not a rare edge case, since `SAVE10` is the system's flagship, most prominently seeded percent coupon. Both component mechanisms (#1: checkout trusts client `total_amount` verbatim; #4: percent formula inverts the discount) are **independently already confirmed via live execution** in the prior FR-08-Full pass — this report's own contribution is tracing the specific, unconditional mobile code path (`App.js:385`, `392-396`) that chains them, which neither original report examined. **Caveat, stated plainly:** this exact combined runtime sequence was not independently live-executed in this pass (per the handoff's constraint) — the claim rests on: (a) two individually-confirmed live-executed defects, and (b) a direct, unconditional code reading with no intervening branch/validation that could break the chain (re-verified in Stage 1 above), not on a fresh live run of the full sequence. |
| **Priority** | P1 |
| **Expected** | Per README FR-09's formula (for this input, `final_amount = 900,000`) and README FR-08 line 107 (backend must recompute/persist the correct total, never trust an unchecked client-supplied value): the order persisted by a successful mobile checkout, after applying `SAVE10` to a 1,000,000₫ cart, must have a stored `total_amount` of `900,000`. `expected_source`: `spec`. |
| **Actual** | Code-derived inference, not a live observation: `App.js:385` sets `finalAmount = couponResult.final_amount`, which — per issue #4's confirmed mechanism — would be `10,000,000` for this input (see `ER-09-EP-004`); `App.js:392-396` sends this value as `total_amount` in the `POST /api/checkout` body; `backend/server.js:297-309` (issue #1's confirmed mechanism) inserts this value into the `orders` table with zero recomputation. Inferred persisted `total_amount`: `10,000,000`, not `900,000`. |
| **Repro steps (code-derived, not live)** | 1. (Would-be) log in on the mobile app. 2. Add items to the cart totaling 1,000,000₫. 3. Open checkout, type `SAVE10`, tap "Áp dụng" — per `ER-09-EP-004`, the coupon box would show a negative "Tiết kiệm" and an inflated "Thành tiền." 4. Tap "Xác Nhận Thanh Toán" — per this chain, the order persisted would carry `total_amount: 10,000,000`. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | Two already-documented root causes (`server.js:398-401` for #4, `server.js:297-309` for #1), joined by `App.js:385`/`392-396`'s unconditional pass-through of `couponResult.final_amount` into the checkout call, with no client-side sanity check of any kind between the two. |
| **Evidence** | Code-derived inference — cites `frontend-mobile/App.js:385, 392-396` + GitHub issues #1 and #4 (this session's own combination, not a screenshot or raw capture, per the handoff's evidence-field replacement, §8). |
| **Status** | `approved` — promoted below, under the student's standing blanket approval ("Continue the remaining tasks ok? Finish all the jobs. I approved all your suggestion. All human in the loop is passed."). |

## Human gate: `approve → file`

- [x] Approve `BUG-09-001` for promotion + GitHub issue, cross-referencing #1 and #4.
- [x] Approve posting reconfirmation comments on issues #3, #4, #5.

  **Approved 2026-07-07** under the student's standing blanket approval (quoted above), which
  the student stated explicitly covers all remaining Human Gates for this feature.

## Summary

- **Executed (inferred):** 13 cases.
- **PASS:** 9. **FAIL:** 4.
- **Confirmed defects this pass:** 4 (3 reconfirmations of #3/#4/#5 via a new mobile evidence
  path; 1 new — `BUG-09-001`).
- **By severity (new defect only):** 1 Critical (`BUG-09-001`).
- **Evidence basis:** 4/4 confirmed defects are code-derived inference (0 assumption-grounded —
  every expected result cited README FR-08/FR-09 directly, no case rested on an unaccepted
  assumption). 0 reclassifications between spec-grounded and assumption-grounded during review.
