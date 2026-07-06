# Continuation Handoff — FR-17 (Coupon Management CRUD, Admin)

> Written 2026-07-04. Self-contained handoff for a new Claude Code session to pick up FR-17.
> Do not rely on any other handoff file for context — everything needed is here or in the
> files this document points to.

---

## 1. Current project status

**Steps 0–6 are Core Complete** (frozen at commit `43defbc`). **FR-08 Full is done**
(`total_amount`, auth-state, cart-clearing — 2 confirmed bugs, both filed as GitHub issues
#1/#2). **FR-15 may or may not be done yet** — check `implementation_plan.md`'s Status/
Continuation section and `work/FR-15-product-crud/` before starting; if FR-15 hasn't been done,
consider doing it first (it's listed before FR-17 in the Continuation plan), but this handoff
is self-contained for FR-17 regardless of that order.

**Critical lesson, read this before touching anything:** an earlier FR-08 pass accidentally
modeled **FR-09** (README line 110, "Mã Giảm Giá" — customer-facing coupon *application* logic:
the 5 conditions C1–C5, discount formula, applying a code at checkout) as if it were part of
FR-08, reasoning it was "functionally adjacent" (coupons apply during checkout). **FR-09 is a
completely different feature from FR-17** and is still not one of the 4 assigned features. It
was caught and removed from FR-08's scope (git history shows both the mistake and the fix).

**FR-17 is NOT FR-09.** FR-17 (README line 213, "Quản lý Mã Giảm Giá — Coupon CRUD") is the
**admin** side: creating, viewing, and deleting coupon *codes themselves* (the `coupons` table
rows) — not applying a coupon during checkout. Do not pull in any of FR-09's C1–C5
apply-coupon logic, discount formula, or `POST /api/apply-coupon` endpoint when working on
FR-17 — that endpoint and its behavior belong to FR-09, still out of scope. FR-17 only concerns
`POST /api/admin/coupons`, `DELETE /api/admin/coupons/:id`, and viewing the coupon list.

## 2. Authoritative scope — check this first

`docs/hw2-reqs/features-that-need-testing.md` (4 lines):

```
FR-04 Personal profile management
FR-08 Checkout
FR-15 Product management (CRUD)
FR-17 Coupon management (CRUD)
```

FR-17 = **README.md lines 213–216** ("FR-17: Quản lý Mã Giảm Giá — Coupon CRUD"). Do not
conflate with FR-09 (line 110, coupon *application*) or FR-16 (CSV import for *products*, line
200 — a different resource entirely).

## 3. What FR-17 actually specifies (the oracle)

README.md lines 213–216, in full:

> - Admin có thể Thêm / Xem / Xóa mã giảm giá.
> - Các trường bắt buộc: `code` (duy nhất), `type` (percent/fixed), `discount_value` (dương),
>   `expired_at`, `min_order_amount` (>= 0), `max_uses_per_user` (>= 1).

Note carefully: **Add / View / Delete only — no "Sửa" (Edit)** listed for coupons, unlike FR-15
which explicitly includes Edit. Don't assume an edit operation is in scope just because
`PUT`-shaped CRUD is a common pattern — check whether an edit endpoint even exists in the code
(see §4) and whether the spec actually asks for one (it doesn't, as quoted above).

Six required fields, each with its own constraint:
- `code` — required, **unique**.
- `type` — required, one of `percent` / `fixed`.
- `discount_value` — required, must be **positive**.
- `expired_at` — required (a date).
- `min_order_amount` — required, must be `>= 0`.
- `max_uses_per_user` — required, must be `>= 1`.

This is 6 independent field-level constraints — at a glance, shaped like FR-15 (multiple
independent rules, not obviously combining), closer to FR-04's shape than FR-08/09's. Do not
assume this does or doesn't need a Decision Table — apply `domain-test-design`'s own Stage 5
check once the model is built, and skip with a one-line reason if nothing combines.

## 4. Code-derived findings already surfaced (verify these still hold; code shows *where* to
test, never the oracle — per architecture.md §2.1, MODEL ≠ ORACLE)

From `backend/server.js` (read yourself to confirm current state — these line numbers may
shift if FR-15 work touches nearby lines first):

1. **`GET /api/coupons`** (around line 356) — has `authenticateToken` middleware (requires
   *some* valid login) but **no role check** — any authenticated user, not just admin, can
   list all coupons. Likely the "Xem" (View) endpoint for FR-17.
2. **`POST /api/admin/coupons`** (around line 457) — has `authenticateToken` but **no role
   check either** — README says "**Admin** có thể Thêm/Xem/Xóa," implying admin-only, but the
   code only requires *a* valid JWT, not specifically an admin role. This is a code-revealed
   forbidden-state candidate (Step 1.3) — any logged-in non-admin user can create coupons.
   Destructures `code, type, discount_value, min_order_amount, expired_at, max_uses_per_user`
   from `req.body` with **zero validation** on any of them — no uniqueness pre-check (relies
   entirely on the DB's own `UNIQUE` constraint on `code`, see §4.4 below), no `type` enum
   check, no positivity check on `discount_value`, no `>= 0`/`>= 1` checks on
   `min_order_amount`/`max_uses_per_user`. Note: `max_uses_per_user || 1` — if the client omits
   or sends a falsy `max_uses_per_user` (`0`, `null`, `undefined`), the code silently
   substitutes `1` rather than rejecting the request — worth its own boundary case (does `0`
   get silently coerced to `1`, contradicting the spec's `>= 1` requirement being violated by a
   literal `0` input, or does the substitution happen to produce a spec-compliant result by
   accident?).
3. **`DELETE /api/admin/coupons/:id`** (around line 483) — has `authenticateToken`, no role
   check either. No check for whether the coupon has ever been used (no `coupon_usage`
   dependency handling) — deleting a coupon that has usage history is allowed unconditionally.
   Whether this matters for FR-17 specifically (vs. being an FR-09/usage-tracking concern) is
   worth thinking through during modeling — the deletion itself is squarely FR-17's own
   endpoint.
4. **`backend/database.js`** `coupons` table (read yourself, ~line 29–38): `code TEXT UNIQUE`
   (a **real DB-level constraint** — unlike FR-15's `products` table, which had none at all;
   this means `code` uniqueness actually is enforced somewhere, worth confirming behaviorally
   what happens on a duplicate insert — a clean rejection, or a DB error leaking as a 500).
   `type TEXT DEFAULT 'percent'` (no enum `CHECK`). `discount_value INTEGER` (no positivity
   `CHECK`). `min_order_amount INTEGER DEFAULT 0` (no `CHECK`, default satisfies `>=0` but a
   negative value could still be inserted). `expired_at DATETIME` (no `NOT NULL`).
   `max_uses_per_user INTEGER DEFAULT 1` (no `CHECK` for `>=1`).
5. **No PUT/edit endpoint exists** for `/api/admin/coupons/:id` in `server.js` — consistent
   with the spec listing only Add/View/Delete (§3). Confirm this is still true; if a PUT
   endpoint has been added since, that would itself be worth flagging (code doing more than the
   spec describes), not modeling as if the spec required it.

## 5. Files to read, in priority order

1. `CLAUDE.md` — project orientation.
2. `docs/hw2-reqs/features-that-need-testing.md` — the 4-line assigned scope (§2 above).
3. `docs/architecture/architecture.md` — frozen architecture, read for context, don't redesign.
4. `docs/implementation-plan/implementation_plan.md` — Status table + Continuation section.
5. This file.
6. `docs/implementation-plan/oracle-precedence.md` — spec-conflict resolution rule + evidence
   standard.
7. `docs/implementation-plan/blockers.md` — frozen Step-0 content + dated addendum (`gh` works,
   Issues enabled — filing should work normally).
8. `docs/implementation-plan/execution-notes.md` — Model-C execution command form.
9. `.claude/skills/domain-test-design/SKILL.md` and `.claude/skills/bug-reporting/SKILL.md` —
   invoke via the `Skill` tool, don't hand-copy their logic.
10. `work/FR-04-personal-profile/testing-model.md` and `out/reports/FR-04-personal-profile/*`
    — calibration only, do not edit. Multiple independent field-level rules, no Decision Table.
11. `work/FR-08-checkout/testing-model.md` and `out/reports/FR-08-checkout/*` — calibration
    only, do not edit. Read the correction notes at the top of each file — this is exactly the
    kind of adjacent-feature confusion (FR-09 vs. FR-08) to avoid repeating (FR-09 vs. FR-17,
    this time).
12. If it exists by the time you start: `work/FR-15-product-crud/testing-model.md` and its
    `out/reports/FR-15-product-crud/*` — likely the closest-shaped worked example (multiple
    independent field constraints, admin CRUD, no auth-role enforcement in code either).
13. `README.md` lines 213–216 (FR-17) — the oracle. Not FR-09, not FR-16.
14. `api_specification.md` §6.4 (around lines 201–214) — shape only for
    `POST /api/admin/coupons` and `DELETE /api/admin/coupons/:id`.
15. `backend/server.js` — `GET /api/coupons`, `POST /api/admin/coupons`,
    `DELETE /api/admin/coupons/:id` (search for these route strings; line numbers may have
    shifted).
16. `backend/database.js` — `coupons` table schema and seed data (4 seeded coupons: `SAVE10`,
    `BIGBUY`, `VIP100`, `EXPIRED`).
17. `out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md` — append new
    rows for every new artifact; read a couple of existing rows for format.

## 6. Immutable rules

- Steps 0–6 frozen at `43defbc`. FR-08 Full's (and, if done, FR-15's) artifacts are also
  frozen. Do not edit any of these unless a genuine defect is found — never for polish.
- Do not edit `domain-test-design/SKILL.md` or `bug-reporting/SKILL.md` unless a real framework
  bug surfaces on FR-17 — not a preference. Notes-first-then-regenerate if a fix is needed.
- **Check scope before modeling anything.** Cross-reference `features-that-need-testing.md`
  and README's exact FR-17 section (lines 213–216) before treating any variable, endpoint, or
  behavior as in-scope. In particular: never reach for `/api/apply-coupon` or the C1–C5
  condition logic — that's FR-09, still not assigned, already removed once from FR-08's scope.
- MODEL ≠ ORACLE, freeze-before-execute, the three Human Gates (`completeness_confirmed`,
  `FAIL → real bug?`, `approve → file`) — actually ask the user for each, don't self-approve —
  one AI Audit row per AI-generated artifact.
- Record framework limitations in `docs/implementation-plan/learning-notes.md` instead of
  fixing immediately; keep moving with the skills as-is unless a limitation blocks completion.

## 7. Expected outputs of FR-17

Same three-phase rhythm as FR-08 Full / FR-15, pausing at all three Human Gates:

- `work/FR-17-coupon-crud/testing-model.md` (new) — file map, then one model entry per
  variable (`code` uniqueness, `type` enum, `discount_value` positivity, `expired_at`
  presence, `min_order_amount >= 0`, `max_uses_per_user >= 1`, actor/role for CUD), each with
  domain/boundary+source/validation/oracle/metadata. Include the `max_uses_per_user || 1`
  silent-coercion finding (§4.2) as its own noted behavior. Gate: `completeness_confirmed`.
- `out/reports/FR-17-coupon-crud/domain-testing/report.md` — EP cases; Decision Table only if
  Stage 5 finds combining conditions among FR-17's own 6 fields + actor/role.
- `out/reports/FR-17-coupon-crud/boundary-value-analysis/report.md` — BVA for
  `discount_value`'s positivity boundary, `min_order_amount`'s `>= 0` boundary,
  `max_uses_per_user`'s `>= 1` boundary (and its `0`/omitted coercion behavior specifically).
- `work/FR-17-coupon-crud/execution-results.md` — Model C, no `expected` field, reseed between
  runs if state matters (the DB reseed script recreates the 4 seed coupons each time).
- `out/reports/FR-17-coupon-crud/bug-reports/report.md` — confirmed defects, human-gated per
  report, filed as GitHub issues.
- New rows in `[AI-02]` continuing from wherever FR-15's artifacts left off.
- Git commits per phase/artifact, human gates honored.
- **This is also the point to finally, deliberately answer the open question from the FR-08
  correction: does FR-17 need a Decision Table?** Apply Stage 5 honestly on FR-17's own 6
  fields + actor/role — don't import the expectation from FR-09's now-removed table, and don't
  assume "no" just because FR-04/FR-15 didn't need one either.

---

# Prompt for a New Claude Session

```
You are joining a project mid-stream. You have no memory of any prior session — do not assume
context beyond what you read below. Do not use any memory system; treat the repository as the
only source of truth.

Read, in this exact order, before doing or proposing anything:
1. CLAUDE.md
2. docs/hw2-reqs/features-that-need-testing.md - the EXACT 4 assigned features (FR-04, FR-08,
   FR-15, FR-17). A prior session once wrongly folded FR-09 (a different, unassigned feature -
   customer-facing coupon application) into FR-08's scope. FR-17 is the ADMIN coupon-CRUD
   feature (Add/View/Delete coupon codes) - a completely different feature from FR-09. Never
   pull in /api/apply-coupon or the 5-condition (C1-C5) logic when working on FR-17.
3. docs/architecture/architecture.md
4. docs/implementation-plan/implementation_plan.md - Status table + Continuation section
5. docs/implementation-plan/continuation-handoff-FR17.md - this file, written for you
6. docs/implementation-plan/oracle-precedence.md
7. docs/implementation-plan/blockers.md
8. docs/implementation-plan/execution-notes.md
9. .claude/skills/domain-test-design/SKILL.md
10. .claude/skills/bug-reporting/SKILL.md
11. work/FR-04-personal-profile/* and out/reports/FR-04-personal-profile/* (calibration only,
    do not edit)
12. work/FR-08-checkout/* and out/reports/FR-08-checkout/* (calibration only, do not edit -
    read the correction notes at the top of each file - this is exactly the FR-09-vs-FR-17
    confusion to avoid repeating)
13. work/FR-15-product-crud/* and out/reports/FR-15-product-crud/* if they exist yet
    (calibration only, do not edit)
14. README.md lines 213-216 (FR-17) only - not FR-09 (line 110), not FR-16 (line 200)
15. api_specification.md section 6.4 (admin coupon endpoints)
16. backend/server.js - GET /api/coupons, POST /api/admin/coupons,
    DELETE /api/admin/coupons/:id (search for these route strings) - and backend/database.js's
    coupons table schema
17. out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md (existing
    rows, for format)

Ground rules, non-negotiable:
- Steps 0-6 are Core Complete (frozen at 43defbc); FR-08 Full's (and FR-15's, if done)
  artifacts are also frozen. Do not edit any of these unless you find an actual defect.
- Do not redesign, rewrite, or "improve" the architecture, the workflow, or either skill.
- Before modeling any variable/endpoint/finding, confirm it belongs to FR-17 specifically
  (README lines 213-216) - this feature has been the site of one scope mistake already
  (FR-09 folded into FR-08); do not repeat it by pulling FR-09's apply-coupon logic into FR-17.
- Build a complete Testing Model, EP test cases, and a Boundary Value Analysis for FR-17 from
  scratch. FR-17 has 6 independent field constraints (code uniqueness, type enum,
  discount_value positivity, expired_at presence, min_order_amount >= 0, max_uses_per_user >= 1)
  plus an actor/role forbidden-state candidate (no role check on any admin coupon endpoint).
  Check whether these combine into anything needing a Decision Table (apply Stage 5's own
  check, don't assume either way based on FR-04/FR-15's outcome), then execute and report bugs.
- Follow existing discipline: MODEL != ORACLE, freeze test cases and commit before executing,
  honor the three Human Gates by actually asking rather than self-approving, log one AI Audit
  entry per AI-generated artifact. GitHub issue filing should work normally.

Start by reading the files above, then tell me what you found and propose the first concrete
step. Do not start executing test cases before I confirm the plan.
```
