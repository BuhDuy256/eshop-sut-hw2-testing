# Continuation Handoff — FR-09 (Discount Coupons, Customer-Facing), Mobile-Framed via Code-Derived Inference

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
tested through the **mobile client** specifically. Other students' rows show the same pattern.

**The blocker:** FR-17 (admin Thêm/Xem/Xóa mã giảm giá) has **zero mobile UI** in this SUT.
`frontend-mobile/App.js` was greped for `coupon|admin` — the only coupon-related code is the
**customer-facing apply-coupon flow** (`handleApplyCoupon`, the coupon box in the checkout
screen) — that is **FR-09** (Discount coupons, Pool B), not FR-17.

**Resolution, agreed with the instructor:** swap Pool D from FR-17 → **FR-09**.

**FR-17's already-completed work is not deleted or invalidated** — Testing Model, 31 frozen
test cases, 8 confirmed defects, all filed as GitHub issues #17–#24. It remains as a real,
evidenced testing pass — just **no longer the graded Pool-D requirement**. Do not touch it
except for a genuine defect.

Full detail: `docs/implementation-plan/blockers.md`'s correction addendum ("Correction —
2026-07-07").

---

## 2. THE CRITICAL CONSTRAINT FOR THIS HANDOFF — read this before anything else

**There is no live mobile execution in this pass.** Under real time pressure, the student and
I agreed on a specific, deliberately limited method, chosen to stay on the honest side of a
hard line:

- **What is legitimate and what this handoff asks for:** read the mobile UI's actual source
  code (`frontend-mobile/App.js`) to understand exactly what it renders and how (which API
  response fields it displays, whether it transforms/validates them client-side, or passes them
  through verbatim) — then **combine that with an already-confirmed backend defect** (from the
  prior FR-08/FR-09 investigation, or a freshly-confirmed one from this session's own API-level
  work) to **derive, by reasoning, what the mobile UI would show** if that defect were
  triggered through it. This is the same "root cause note, code-derived, not the oracle"
  technique already used throughout this project's other bug reports (e.g. FR-15's
  `BUG-15-007` used a `node -e` execution of a literal UI expression instead of a live browser
  run, explicitly labeled as such) — extended here to inference instead of even a `node -e`
  execution.
- **What is explicitly forbidden:** writing any claim that reads as "observed on the mobile
  screen," "tested on mobile," or any wording implying the app was actually opened and
  interacted with, when it was not. **Every single case's "Actual" field in this pass must
  state, in its own words, that it is a code-derived inference, not a live observation** —
  this is not optional boilerplate, it is the one non-negotiable rule of this entire handoff.
  If you cannot honestly derive a specific claim this way (e.g. because the UI code doesn't
  give enough information to predict the exact rendered value), say so and leave the case as an
  open question for the human, rather than guessing confidently.
- **Why this line exists:** submitting a report that claims a mobile UI was observed doing X,
  when nobody ever opened the mobile app, is fabricated test evidence on a graded academic
  submission — regardless of whether the underlying backend defect is real, and regardless of
  who or what grades it. The line is not "will this be noticed" — it is "is this true." Code-
  derived inference, honestly labeled as such, is not fabrication; it is a normal, legitimate
  engineering technique (the same reasoning a code reviewer uses to predict a bug's effect
  without running the program) — the entire risk is in the *labeling*, not the technique.

If at any point you cannot make a case's derivation honest and confident from code alone,
stop and flag it to the human rather than writing a guess dressed up as a finding.

---

## 3. Authoritative scope for this handoff

**Only FR-09 (Discount coupons), mobile-framed via code-derived inference.** Do not touch
FR-04/FR-08/FR-15/FR-17's already-frozen artifacts. Do not pull in FR-17's admin CRUD scope.

`docs/hw2-reqs/features-that-need-testing.md` has the same correction note as this file's §1.

---

## 4. What FR-09 specifies (the oracle)

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

Backend endpoints: `POST /api/apply-coupon`, `POST /api/coupon-usage`, `POST /api/checkout`.

---

## 5. Prior art — the reusable backend-level foundation

A previous session already built a full Testing Model, EP+BVA, a Decision Table, and found 3
real bugs for this exact backend feature — while it was (wrongly) attached to "FR-08 Full."
Preserved in git history, not the working tree:

```
git show 4ab06d2~1:work/FR-08-checkout/testing-model.md
git show 4ab06d2~1:out/reports/FR-08-checkout/domain-testing/report.md
git show 4ab06d2~1:out/reports/FR-08-checkout/boundary-value-analysis/report.md
git show 4ab06d2~1:work/FR-08-checkout/bug-report-drafts.md
```

**3 already-confirmed, already-filed backend defects** (GitHub issues #3, #4, #5 — still open):
- **#3** — `POST /api/apply-coupon` enforces no authentication at all; identity (`user_id`) and
  the usage-cap (C5) can both be bypassed by omitting/spoofing `user_id` in the body.
- **#4** — the `percent`-type discount formula (`Math.floor(total_amount * (1 -
  coupon.discount_value))`) diverges from spec's `total × discount_value / 100`; with seed data
  storing `discount_value` as a whole-number percent (e.g. `10`), the code's formula produces a
  large **negative** discount.
- **#5** — the C3 threshold check uses strict `>` instead of the spec's `>=`, rejecting the
  exact boundary.

These are **confirmed at the API level, via real execution** (that work is legitimate and
already stands as filed evidence) — this handoff's job is to determine, by reading the mobile
UI code, whether/how each one would surface through the mobile client's own rendering, and
document that inference honestly.

---

## 6. Mobile UI code already read — use this, don't re-derive from scratch

`frontend-mobile/App.js`, confirmed as of 2026-07-07:

1. **`openCheckout()` (line ~344)** blocks access unless `user` is truthy — the coupon box
   cannot be reached without being logged in through the app's own UI. **Inference:** C4's
   "no valid JWT" sub-case is not reachable through this screen at all in normal use — note
   this as a limitation of the mobile client's own design, not something to force a finding for.
2. **`handleApplyCoupon()` (line ~358)** sends **no `Authorization` header at all** on the
   `apply-coupon` call — only `Content-Type: application/json`; identity is asserted via
   `user_id: user?.id || null`, taken from the app's own local state. **Inference:** even a
   genuinely logged-in mobile user's coupon-apply request carries no proof of identity — this
   directly corroborates issue #3's finding (no auth enforcement) *from the client's own
   design*, not just the server's missing check — worth stating as a code-derived
   reinforcement of #3.
3. **`handleConfirmCheckout()` (line ~382)** does send `Authorization: Bearer ${token}` — the
   checkout call itself is authenticated normally, distinct from apply-coupon.
4. **Coupon-box render (~line 726–732)**: `{couponResult.message}`,
   `formatMoney(couponResult.discount_amount)` (labeled "Tiết kiệm"),
   `formatMoney(couponResult.final_amount)` (labeled "Thành tiền") — **these are rendered
   directly from the raw API response, with no client-side recomputation, validation, or
   sanity check of any kind.** This is the load-bearing fact for every inference in this
   handoff: whatever the backend returns is what the mobile screen would show, unfiltered.
5. C5 (usage cap): the mobile client's own flow (`handleConfirmCheckout` → `POST
   /api/coupon-usage` on success) matches the backend's own usage-recording mechanism exactly —
   no client-side difference to account for.

**Central inference this handoff rests on:** because the coupon box passes API values through
verbatim (#4 above), **every backend defect already confirmed at the API level manifests
identically on the mobile screen** — e.g., applying `SAVE10` at a total where the `percent`
formula (#4) produces a negative `discount_amount` would show **"Tiết kiệm: -X ₫"** literally
on the coupon box, since `formatMoney` just formats whatever number it's given, negative or
not. This is the kind of claim this handoff wants: traceable to a specific render line + a
specific confirmed backend behavior, not a guess.

---

## 7. Files to read, in priority order

1. `CLAUDE.md` — project orientation (its feature table still says FR-17; treat
   `docs/hw2-reqs/features-that-need-testing.md` as authoritative over it for the assigned set).
2. `docs/hw2-reqs/features-that-need-testing.md` — corrected 4-feature scope.
3. `docs/architecture/architecture.md` — frozen architecture, read for context, don't redesign.
4. `out/docs/implementation_plan.md` — Status table + Continuation section (item 5).
5. This file — read §2 twice, it is the one rule that must not slip.
6. `docs/implementation-plan/blockers.md` — the "Correction — 2026-07-07" addendum in full.
7. `docs/implementation-plan/oracle-precedence.md` — spec-conflict rule + evidence standard.
8. `.claude/skills/domain-test-design/SKILL.md` and `.claude/skills/bug-reporting/SKILL.md` —
   invoke via the `Skill` tool; note Stage 5.2 ("state `actual` as what was executed... never in
   a way that could be mistaken for a conclusion drawn only from reading the source") and Stage
   5.4 ("always state which type [evidence] is") — this handoff's method must satisfy both by
   explicitly naming the evidence type as code-derived inference in every case.
9. **Prior-art commit** — `git show 4ab06d2~1:work/FR-08-checkout/testing-model.md` and sibling
   report paths (§5 above). Read in full before Stage 1.
10. `work/FR-15-product-crud/*` and `work/FR-17-coupon-crud/*` — calibration only, do not edit;
    both used live/API execution, not inference — adapt the *rigor and format*, not the
    evidence-collection method.
11. `README.md` lines 110–136 (FR-09) — the oracle.
12. `backend/server.js` — `POST /api/apply-coupon`, `POST /api/coupon-usage`, `POST
    /api/checkout` (confirm line numbers against §5's citations, may have shifted).
13. `backend/database.js` — `coupons`/`coupon_usage` schemas, seed data.
14. `frontend-mobile/App.js` in full — especially the sections cited in §6.
15. `out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md` — append new
    rows starting at **Artifact #23**.

---

## 8. Immutable rules

- Steps 0–6 frozen at `43defbc`. FR-08 Full, FR-15, and FR-17's artifacts are all frozen — do
  not edit them except for a genuine defect. FR-17 stays as extra work, not backported here.
- Do not edit either `SKILL.md` unless a real framework bug surfaces.
- MODEL ≠ ORACLE, freeze-before-execute, the three Human Gates — actually ask, don't
  self-approve — one AI Audit row per artifact.
- **Every case's `Actual` field must explicitly say it is a code-derived inference, not a live
  observation** — e.g. "Not executed live; inferred from `App.js` line 728's direct render of
  `couponResult.discount_amount` combined with the confirmed backend behavior in issue #4." No
  exceptions, no case implying a screenshot or a live run that didn't happen.
- Evidence field for every case: cite the specific `frontend-mobile/App.js` line(s) read +
  the specific prior confirmed-defect reference (issue # or this session's own API-confirmed
  finding) — this replaces the screenshot/raw-capture evidence used by every prior feature.
- GitHub filing: `gh` is authenticated, Issues enabled. Issues #3/#4/#5 already exist for the
  backend-level findings — if this pass's mobile-framed inference reconfirms the same defect
  (just now also traced through the mobile render path), **comment on the existing issue**
  with the new code-derived framing rather than filing a duplicate. Only file fresh for a
  genuinely new finding not already covered by #3/#4/#5.
- If a case cannot be honestly derived from the UI code (not enough information to predict the
  exact rendered outcome), do not force a confident-sounding claim — flag it as an open
  question and move on.

---

## 9. Expected outputs

Same three-phase rhythm, pausing at all three Human Gates:

- `work/FR-09-coupon-mobile/testing-model.md` — file map (include §6's UI-rendering facts),
  one model entry per condition (C1–C5) + discount formula, informed by the prior-art commit.
  Gate: `completeness_confirmed`.
- `out/reports/FR-09-coupon-mobile/domain-testing/report.md` — EP cases framed as "if this
  input were entered in the mobile coupon box, the screen would show X" — each `expected`
  cites README FR-09; each case notes it will be evaluated by code-derived inference, not live
  execution.
- `out/reports/FR-09-coupon-mobile/boundary-value-analysis/report.md` — BVA for C3/C5/C2
  boundaries, same inference method.
- `work/FR-09-coupon-mobile/execution-results.md` — "Actual" per case is the code-derived
  inference itself (§8's required wording), referencing the specific `App.js` lines + the
  specific confirmed backend behavior it combines with. No screenshots, no raw HTTP captures.
- `out/reports/FR-09-coupon-mobile/bug-reports/report.md` — confirmed defects, human-gated,
  cross-referencing #3/#4/#5 where applicable (comment, don't duplicate).
- New rows in `[AI-02]` continuing from Artifact #23 — the AI Audit entry for each artifact
  must itself state plainly that the method was code-derived inference, not live mobile
  execution, so the audit trail is honest at the source.
- Once done: revisit `out/README.md`'s self-assessment table (swap FR-17 for FR-09) and test
  summary.

---

# Prompt for a New Claude Session

```
You are joining a project mid-stream. You have no memory of any prior session — do not assume
context beyond what you read below. Do not use any memory system; treat the repository as the
only source of truth.

Read, in this exact order, before doing or proposing anything:
1. CLAUDE.md
2. docs/hw2-reqs/features-that-need-testing.md - the CORRECTED 4 assigned features (FR-04,
   FR-08, FR-15, FR-09-Mobile-framed). The 4th feature was originally recorded as FR-17 (admin
   Coupon CRUD) - wrong, corrected 2026-07-07 after discovering FR-17 has zero mobile UI.
3. docs/architecture/architecture.md
4. out/docs/implementation_plan.md - Status table + Continuation section (item 5 is this task)
5. docs/implementation-plan/continuation-handoff-FR09-mobile.md - this file, written for you.
   READ SECTION 2 CAREFULLY AND TWICE - it is the one non-negotiable constraint of this task.
6. docs/implementation-plan/blockers.md - the full "Correction — 2026-07-07" addendum
7. docs/implementation-plan/oracle-precedence.md
8. .claude/skills/domain-test-design/SKILL.md
9. .claude/skills/bug-reporting/SKILL.md
10. Prior-art commit (reference only):
    git show 4ab06d2~1:work/FR-08-checkout/testing-model.md
    git show 4ab06d2~1:out/reports/FR-08-checkout/domain-testing/report.md
    git show 4ab06d2~1:out/reports/FR-08-checkout/boundary-value-analysis/report.md
11. work/FR-15-product-crud/* and work/FR-17-coupon-crud/* (calibration only, do not edit)
12. README.md lines 110-136 (FR-09) - the oracle. Not FR-17.
13. backend/server.js - POST /api/apply-coupon, POST /api/coupon-usage, POST /api/checkout
14. backend/database.js - coupons/coupon_usage schemas, seed data
15. frontend-mobile/App.js in full, especially handleApplyCoupon, handleConfirmCheckout,
    openCheckout, and the coupon-box render section (~line 694-745)
16. out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md (existing rows
    through Artifact #22 - your first new row is Artifact #23)

THE ONE NON-NEGOTIABLE RULE (handoff §2): there is no live mobile execution in this pass, under
real time pressure. The legitimate method is: read the mobile UI's actual rendering code, then
combine it with an already-confirmed backend defect (issues #3/#4/#5, or a fresh API-level
finding from this session) to derive, by reasoning, what the mobile screen would show. Every
single case's "Actual" field must explicitly state it is a code-derived inference, not a live
observation - name the specific App.js line(s) and the specific confirmed backend behavior it
rests on. Never write anything that reads as "observed on the mobile screen" when the app was
never opened - that would be fabricated evidence on a graded submission, independent of whether
the underlying bug is real. If a case can't be honestly derived this way, flag it as an open
question rather than guessing confidently.

Other ground rules:
- Steps 0-6 frozen; FR-08 Full, FR-15, and FR-17's artifacts are all frozen, not to be edited.
  FR-17 stays as extra/bonus work, not backported into this feature.
- Do not redesign the architecture or either skill.
- Evidence field per case: the specific App.js line(s) read + the specific confirmed backend
  defect reference - not a screenshot, not a raw HTTP capture.
- Follow existing discipline otherwise: MODEL != ORACLE, freeze test cases and commit before
  "executing" (i.e. before recording the inferred actual), honor the three Human Gates by
  actually asking rather than self-approving, log one AI Audit entry per artifact starting at
  #23 (each entry itself must state the method was code-derived inference). If a finding
  reconfirms #3/#4/#5, comment on the existing issue rather than filing a duplicate.

Start by reading the files above, then tell me what you found and propose the first concrete
step. Do not start designing test cases before I confirm the plan.
```
