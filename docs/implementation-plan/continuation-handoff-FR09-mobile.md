# Continuation Handoff — FR-09 (Discount Coupons, Customer-Facing), Tested via Mobile

> Written 2026-07-07. Self-contained handoff for a new Claude Code session to pick up the
> corrected 4th assigned feature. Do not rely on any other handoff file for context — everything
> needed is here or in the files this document points to.

---

## 1. Why this handoff exists — the scope correction

The assignment's 4 assigned features were originally recorded as FR-04, FR-08, FR-15, **FR-17**
(admin Coupon CRUD). That was wrong. The official Pool-assignment spreadsheet (student ID
23127179, confirmed directly with the instructor) shows this student's actual row:

| Pool | Feature |
|---|---|
| Pool A | FR-04 Personal profile management |
| Pool B | FR-08 Checkout |
| Pool C | FR-15 Product management (CRUD) |
| **Pool D** | **FR-17 Coupon management (CRUD)**, tagged **"Mobile"** |

The assignment's own SUT/Pool structure (§4 of the HW02 spec) defines **Pool D as "Mobile
App"** — a platform requirement, not a feature list. The confirmed mechanism (from the
instructor): Pool D always reuses one FR already defined in Pool A/B/C, but requires it to be
tested through the **mobile client** specifically. Other students' rows show the same pattern
(e.g. one student's Pool D = FR-16, borrowed from Pool C; another's = FR-02, borrowed from Pool
A).

**The blocker:** FR-17 (admin Thêm/Xem/Xóa mã giảm giá) has **zero mobile UI** in this SUT.
`frontend-mobile/App.js` was greped for `coupon|admin` — the only coupon-related code is the
**customer-facing apply-coupon flow** (`handleApplyCoupon`, the coupon box in the checkout
screen) — that is **FR-09** (Discount coupons, Pool B), not FR-17. There is no way to genuinely
test FR-17 "via Mobile" because the feature does not exist on that client.

**Resolution, agreed with the instructor:** swap Pool D from FR-17 → **FR-09**. Still
coupon-themed (so the swap is easy to justify), and confirmed to have real, working mobile UI.

**FR-17's already-completed work is not deleted or invalidated** — Testing Model, 31 frozen
test cases (15 EP + 16 BVA), 8 confirmed defects, all filed as GitHub issues #17–#24. It remains
in the repo as a real, evidenced testing pass — just **no longer the graded Pool-D
requirement**. Do not touch it except for a genuine defect (same baseline-protection rule as
every other frozen feature).

Full detail: `docs/implementation-plan/blockers.md`'s correction addendum (search for
"Correction — 2026-07-07").

---

## 2. Authoritative scope for this handoff

**Only FR-09 (Discount coupons), tested via the Mobile app.** Do not touch FR-04/FR-08/FR-15/
FR-17's already-frozen artifacts. Do not pull in FR-17's admin CRUD scope (Thêm/Xem/Xóa mã
giảm giá) — that is a different feature, already done, not part of this handoff.

`docs/hw2-reqs/features-that-need-testing.md` has been updated to reflect the correction — read
it, it has the same correction note as this file's §1.

---

## 3. What FR-09 specifies (the oracle)

`README.md` lines 110–136, in full:

> **FR-09: Mã Giảm Giá (Coupon)**
>
> Tại bước Checkout, người dùng có thể nhập mã giảm giá. Hệ thống áp dụng giảm giá dựa trên
> **5 điều kiện** sau, tất cả phải thỏa mãn:
>
> | # | Điều kiện | Mô tả |
> |---|---|---|
> | C1 | Mã tồn tại | Mã phải có trong CSDL và đang hoạt động (`is_active = 1`) |
> | C2 | Còn hạn sử dụng | Ngày hiện tại phải trước `expired_at` |
> | C3 | Đủ ngưỡng đơn hàng | Tổng đơn hàng **>= (lớn hơn hoặc bằng)** `min_order_amount` |
> | C4 | Đã đăng nhập | Người dùng phải có JWT Token hợp lệ |
> | C5 | Chưa dùng hết lượt | Số lần đã dùng mã này của user < `max_uses_per_user` |
>
> **Công thức tính giảm giá:**
> - Loại `percent`: `discount_amount = total × discount_value / 100`
> - Loại `fixed`: `discount_amount = discount_value`
> - `final_amount = total - discount_amount`
>
> Seed coupons: `SAVE10` (percent 10%, min 300k, exp 2099-12-31, max 1/user), `BIGBUY` (fixed
> 50k, min 500k, exp 2099-12-31, max 1/user), `VIP100` (fixed 100k, min 300k, exp 2099-12-31,
> max 2/user), `EXPIRED` (percent 20%, min 100k, **exp 2020-01-01**, max 1/user).

Backend endpoints: `POST /api/apply-coupon` (applies a coupon, returns `discount_amount`/
`final_amount`), `POST /api/coupon-usage` (records a usage after a successful checkout),
`POST /api/checkout` (the surrounding checkout flow this feature is embedded in).

---

## 4. Prior art — reusable, but must be rebuilt for mobile execution

A **previous session already built a full Testing Model, EP+BVA, a Decision Table, and found 3
real bugs for this exact feature** — while it was (wrongly) attached to "FR-08 Full." That
content was correctly removed from FR-08's deliverables on 2026-07-06 (FR-09 was not an
assigned feature at the time), but the modeling itself is directly reusable now that FR-09 is
genuinely in scope. It is preserved in git history, not in the working tree:

```
git show 4ab06d2~1:work/FR-08-checkout/testing-model.md
git show 4ab06d2~1:out/reports/FR-08-checkout/domain-testing/report.md
git show 4ab06d2~1:out/reports/FR-08-checkout/boundary-value-analysis/report.md
git show 4ab06d2~1:work/FR-08-checkout/bug-report-drafts.md
```

**What's in there (read it before starting Stage 1 — don't re-derive from scratch):**
- Full Testing Model for C1–C5 + the discount formula, each with spec + code-derived boundaries
  (`backend/server.js` lines ~363–441 at that time; re-confirm line numbers haven't shifted).
- **3 already-confirmed, already-filed defects** (GitHub issues #3, #4, #5 — still open,
  real bugs, just were out of scope until now):
  - **#3** — `POST /api/apply-coupon` enforces no authentication; identity (`user_id`) and the
    usage-cap (C5) can both be bypassed by omitting/spoofing `user_id` in the body (no JWT
    check exists on this endpoint at all).
  - **#4** — the `percent`-type discount formula (`server.js`, `Math.floor(total_amount * (1 -
    coupon.discount_value))`) diverges from the spec's `total × discount_value / 100` — with
    seed data storing `discount_value` as a whole-number percent (e.g. `10`, not `0.10`), the
    code's formula produces a large **negative** discount instead of the correct one.
  - **#5** — the C3 order-threshold check (`server.js`, `if (total_amount > coupon.min_order_amount)`)
    uses strict `>`, rejecting the exact boundary the spec's `>=` says must be accepted.
- A 7-row Decision Table (non-exhaustive, justified — the code's own nested condition-checking
  order makes most of the full 32 combinations either unreachable or indistinguishable).

**Why you can't just re-freeze those old cases as-is:** they were designed for direct `curl`
calls to `POST /api/apply-coupon` (Model C, API-level). This handoff's whole point is Mobile-UI
execution — tapping through the actual app and screenshotting results, not raw HTTP calls. Some
of the old cases translate directly (e.g. entering a bogus code in the coupon box); others need
rethinking because the mobile app's own UI imposes constraints the API-level cases didn't have
(see §5). Treat the old model's **variables, boundaries, and oracles** as validated and
reusable; treat the old **EP/BVA/Decision-Table cases and their preconditions/steps** as a
reference to redesign from, not to copy verbatim.

---

## 5. Mobile-UI-specific constraints found during discovery (confirm these still hold)

Read `frontend-mobile/App.js` yourself — these are current as of 2026-07-07:

1. **`openCheckout()` (line ~344) blocks access unless `user` is truthy** — the checkout screen
   (where the coupon box lives) cannot be reached without being logged in through the app's own
   UI. This means **C4 ("must have a valid JWT") is not reachable as a pure UI negative test**
   the way it was via direct API calls — you cannot navigate to the coupon box while logged out.
   Decide during Phase 1 modeling how to handle this: model it as an assumption-grounded
   observation (code-derived, not directly testable via pure UI), or find another in-app path
   that reaches `apply-coupon` unauthenticated. Do not force a test case that isn't actually
   executable through the UI just because the old API-level model had one.
2. **`handleApplyCoupon()` (line ~358) never sends an `Authorization` header at all** — only
   `Content-Type: application/json`; identity is asserted via `user_id: user?.id || null` in
   the body, taken from the app's own local `user` state. This means: even when genuinely
   logged in through the app, the mobile client's own coupon-apply call carries no proof of
   identity — worth noting as a code-derived finding (relates to issue #3), but confirming it
   from pure UI interaction (without a network inspector) is limited to observing behavior, not
   the header itself.
3. **`handleConfirmCheckout()` (line ~382) does send `Authorization: Bearer ${token}` when a
   token exists** — the checkout call itself (distinct from apply-coupon) is authenticated
   normally.
4. The coupon box UI (~line 694) shows `couponResult.message`, `discount_amount` (as "Tiết
   kiệm"), and `final_amount` (as "Thành tiền") on success, or `couponError` on failure — these
   are the on-screen signals to screenshot as evidence.
5. **C5 (usage cap) is genuinely testable via UI**: apply a coupon, complete a checkout (which
   triggers `POST /api/coupon-usage`), then start a new order and try the same coupon again as
   the same logged-in user — the second attempt should be rejected once the cap is reached.

---

## 6. Mobile execution environment (Model C, but on a different client)

Per `docker-compose.yml`, `frontend-mobile` is a real Expo/React Native app (ports `8081`,
`19000`, `19001`), configured for testing via a **physical device over LAN** (see the
`HOST_LAN_IP`/`REACT_NATIVE_PACKAGER_HOSTNAME`/`EXPO_PUBLIC_API_URL` env vars in
`docker-compose.yml`) or an Android/iOS emulator.

**Use one of:**
- **Expo Go on a physical phone** (same Wi-Fi/LAN as the machine running the backend) — scan
  the QR code from `expo start`. This is what the project is actually configured for.
- **An Android Studio emulator** (or iOS simulator on macOS) — genuinely runs the mobile OS,
  counts as real mobile-platform testing.

**Do not use `npm run web` / `expo start --web`** for evidence screenshots — that renders via
`react-native-web` in a desktop browser, which would not convincingly demonstrate the feature
was tested on Mobile (this was flagged explicitly by the student during scope discussion).

Evidence standard for this feature (per `docs/implementation-plan/oracle-precedence.md` §5,
UI-level bug → browser/device screenshot): every case's evidence should be a **screenshot of
the phone/emulator screen** showing the relevant on-screen state (coupon box success/error
message, order history, etc.) — not a raw request/response text capture like FR-04/08/15/17's
API-level bugs used.

---

## 7. Files to read, in priority order

1. `CLAUDE.md` — project orientation (note: its feature table still says FR-17; treat
   `docs/hw2-reqs/features-that-need-testing.md` as authoritative over it for the assigned set,
   per this handoff's correction — CLAUDE.md itself doesn't need editing for this).
2. `docs/hw2-reqs/features-that-need-testing.md` — corrected 4-feature scope (§2 above).
3. `docs/architecture/architecture.md` — frozen architecture, read for context, don't redesign.
4. `out/docs/implementation_plan.md` — Status table + Continuation section (items 3 note on
   FR-17's correction, item 5 is this handoff's task).
5. This file.
6. `docs/implementation-plan/blockers.md` — read the correction addendum in full (mechanism,
   evidence, resolution).
7. `docs/implementation-plan/oracle-precedence.md` — spec-conflict rule + evidence standard
   (§5 for UI-level screenshots).
8. `.claude/skills/domain-test-design/SKILL.md` and `.claude/skills/bug-reporting/SKILL.md` —
   invoke via the `Skill` tool, don't hand-copy their logic.
9. **Prior-art commit** — `git show 4ab06d2~1:work/FR-08-checkout/testing-model.md` and the
   sibling report paths (§4 above). Read in full before Stage 1.
10. `work/FR-15-product-crud/*` and `work/FR-17-coupon-crud/*` (+ their `out/reports/*`) —
    calibration only, do not edit. Closest-shaped worked examples for method/format, though
    both are API-level, not mobile-UI — adapt the evidence style per §6, not the request style.
11. `README.md` lines 110–136 (FR-09) — the oracle. Not FR-17 (line 213).
12. `api_specification.md` — check for a `/api/apply-coupon`/`/api/coupon-usage` section (shape
    only, per oracle-precedence.md).
13. `backend/server.js` — `POST /api/apply-coupon`, `POST /api/coupon-usage`, `POST
    /api/checkout` (search for these route strings; line numbers may have shifted since
    2026-07-06).
14. `backend/database.js` — `coupons` and `coupon_usage` table schemas, seed data.
15. `frontend-mobile/App.js` in full — especially `handleApplyCoupon`, `handleConfirmCheckout`,
    `openCheckout`, the coupon-box render section (~line 694), and the order-history/cancel
    section (unrelated to FR-09 but useful for orienting in the same file).
16. `out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md` — append new
    rows starting at **Artifact #23** (the last logged artifact is #22).

---

## 8. Immutable rules

- Steps 0–6 frozen at `43defbc`. FR-08 Full, FR-15, and FR-17's artifacts are all frozen — do
  not edit any of them except for a genuine defect, never for polish. FR-17 stays as extra work,
  not deleted, not backdated into this feature's scope.
- Do not edit `domain-test-design/SKILL.md` or `bug-reporting/SKILL.md` unless a real framework
  bug surfaces — not a preference. Notes-first-then-regenerate if a fix is needed.
- MODEL ≠ ORACLE, freeze-before-execute, the three Human Gates (`completeness_confirmed`,
  `FAIL → real bug?`, `approve → file`) — actually ask the user for each, don't self-approve —
  one AI Audit row per AI-generated artifact.
- The prior-art commit (§4) is a **reference for modeling**, not a source of pre-frozen test
  cases — Stage 3–6 (EP/BVA/freeze) must be redone for mobile-UI executability; don't just copy
  the old cases' `status: frozen` forward without re-checking each one is actually reachable and
  screenshot-able through the app's UI (§5's constraints apply).
- GitHub issue filing: `gh` is authenticated, Issues enabled — works normally. Issues #3/#4/#5
  already exist for 3 of the likely findings here — if this pass reconfirms the same defects via
  mobile UI, **don't file duplicates**; instead, comment on the existing issue with the new
  UI-based evidence (mirroring the "add a screenshot as a comment, don't rewrite the analysis"
  pattern used for the Bruno-repro screenshots on FR-15/FR-17's issues), and only file a new
  issue for a genuinely new/different finding.

---

## 9. Expected outputs

Same three-phase rhythm as every prior feature, pausing at all three Human Gates:

- `work/FR-09-coupon-mobile/testing-model.md` (new) — file map (including the mobile-UI
  constraints from §5), then one model entry per condition (C1–C5) + the discount formula,
  each with domain/boundary+source/validation/oracle/metadata, informed by but not copy-pasted
  from the prior-art commit. Gate: `completeness_confirmed`.
- `out/reports/FR-09-coupon-mobile/domain-testing/report.md` — EP cases, redesigned for
  mobile-UI steps (open app → login → add to cart → checkout → type code → tap Áp dụng →
  screenshot). Decision Table only if Stage 5 still finds it justified for the UI-reachable
  subset of C1–C5 (re-check; don't assume the old 7-row table survives unchanged since C4 may
  no longer be independently reachable — see §5.1).
- `out/reports/FR-09-coupon-mobile/boundary-value-analysis/report.md` — BVA for C3's threshold
  boundary, C5's usage-cap boundary, C2's expiry boundary (practical near-instant substitution,
  same reasoning the prior art already worked out).
- `work/FR-09-coupon-mobile/execution-results.md` — Model C, but "execution" here means driving
  the actual mobile app (Expo Go/emulator) and recording actual + verdict; screenshots go in
  `out/reports/FR-09-coupon-mobile/bug-reports/evidence/` (image files, not raw text logs, per
  §6's evidence standard).
- `out/reports/FR-09-coupon-mobile/bug-reports/report.md` — confirmed defects, human-gated,
  cross-referencing issues #3/#4/#5 if reconfirmed (comment, don't duplicate) or filed fresh if
  new.
- New rows in `[AI-02]` continuing from Artifact #23.
- Git commits per phase/artifact, human gates honored.
- Once done: revisit `out/README.md`'s self-assessment table (swap the FR-17 row for FR-09) and
  test summary (add FR-09's counts to the totals), per `out/docs/implementation_plan.md`
  Continuation item 4's follow-up note.

---

# Prompt for a New Claude Session

```
You are joining a project mid-stream. You have no memory of any prior session — do not assume
context beyond what you read below. Do not use any memory system; treat the repository as the
only source of truth.

Read, in this exact order, before doing or proposing anything:
1. CLAUDE.md
2. docs/hw2-reqs/features-that-need-testing.md - the CORRECTED 4 assigned features (FR-04,
   FR-08, FR-15, FR-09-via-Mobile). The 4th feature was originally recorded as FR-17 (admin
   Coupon CRUD) - that was wrong, corrected 2026-07-07 after discovering FR-17 has zero mobile
   UI. Do not pull FR-17's admin CRUD scope into this work - that's a different, already-done
   feature.
3. docs/architecture/architecture.md
4. out/docs/implementation_plan.md - Status table + Continuation section (item 5 is this task)
5. docs/implementation-plan/continuation-handoff-FR09-mobile.md - this file, written for you
6. docs/implementation-plan/blockers.md - read the full "Correction — 2026-07-07" addendum
7. docs/implementation-plan/oracle-precedence.md
8. .claude/skills/domain-test-design/SKILL.md
9. .claude/skills/bug-reporting/SKILL.md
10. Prior-art commit (reference only, not pre-frozen cases):
    git show 4ab06d2~1:work/FR-08-checkout/testing-model.md
    git show 4ab06d2~1:out/reports/FR-08-checkout/domain-testing/report.md
    git show 4ab06d2~1:out/reports/FR-08-checkout/boundary-value-analysis/report.md
11. work/FR-15-product-crud/* and work/FR-17-coupon-crud/* (calibration only, do not edit -
    both are API-level; adapt the evidence style for mobile screenshots, not raw text)
12. README.md lines 110-136 (FR-09) - the oracle. Not FR-17 (line 213).
13. backend/server.js - POST /api/apply-coupon, POST /api/coupon-usage, POST /api/checkout
14. backend/database.js - coupons and coupon_usage table schemas, seed data
15. frontend-mobile/App.js in full, especially handleApplyCoupon, handleConfirmCheckout,
    openCheckout, and the coupon-box render section
16. out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md (existing
    rows through Artifact #22, for format - your first new row is Artifact #23)

Ground rules, non-negotiable:
- Steps 0-6 are Core Complete; FR-08 Full, FR-15, and FR-17's artifacts are all frozen. FR-17
  stays as extra/bonus work, not deleted, not backported into this feature.
- Do not redesign, rewrite, or "improve" the architecture, the workflow, or either skill.
- This feature must be tested via the Mobile app's own UI (Expo Go on a physical device, or an
  Android/iOS emulator) - not expo start --web, and not raw curl/API calls like the prior
  features used. Evidence is phone/emulator screenshots, not raw request/response text.
- Read the mobile-UI-specific constraints already discovered (handoff §5) before modeling C4 -
  the checkout screen blocks unauthenticated access, so some of the old API-level test cases
  may not be directly reachable through the UI; redesign, don't force-copy.
- Reuse the prior-art commit's Testing Model reasoning (C1-C5, discount formula, the 3 already-
  confirmed bugs on issues #3/#4/#5) as a modeling reference, but redesign Stage 3-6 (EP/BVA/
  Decision Table/freeze) for genuine mobile-UI executability.
- Follow existing discipline: MODEL != ORACLE, freeze test cases and commit before executing,
  honor the three Human Gates by actually asking rather than self-approving, log one AI Audit
  entry per AI-generated artifact starting at Artifact #23. If a finding reconfirms an existing
  issue (#3/#4/#5), comment with new evidence rather than filing a duplicate.

Start by reading the files above, then tell me what you found and propose the first concrete
step. Do not start executing test cases before I confirm the plan.
```
