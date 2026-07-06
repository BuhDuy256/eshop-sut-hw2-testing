# Continuation Handoff — for a new Claude Code session

> Written 2026-07-04, after FR-08 Full was completed and then corrected for a scope error
> (FR-09 was wrongly included — see §1). This file supersedes all previous handoffs (preserved
> in git history if needed) — this one is the current, authoritative handoff.

---

## 1. Current project status

**Steps 0–6 are Core Complete** (frozen at commit `43defbc`, see `implementation_plan.md`
Status table). **Continuation item 1, FR-08 Full, is done** (2026-07-04): the FR-08 Testing
Model was extended (auth-state, cart-clearing), 3 EP cases were designed, frozen, and executed
against the live SUT, and 1 new confirmed bug was found and approved (`BUG-08-002`, alongside
the pre-existing `BUG-08-001` — 2 total for FR-08, both filed as GitHub issues #1/#2).

**Important correction, same day:** FR-08 Full originally also included FR-09 (customer-facing
coupon application — 5 conditions C1–C5, a discount formula, a 7-row Decision Table, and 3
bugs). The student caught this: **FR-09 is not one of the 4 assigned features.** Check
`docs/hw2-reqs/features-that-need-testing.md` — the actual list is:

```
FR-04 Personal profile management
FR-08 Checkout
FR-15 Product management (CRUD)
FR-17 Coupon management (CRUD)
```

FR-17 (README line 213, "Quản lý Mã Giảm Giá — Coupon CRUD") is the assigned coupon-related
feature — it is the **admin** side (Add/View/Delete coupon codes), a *different* feature from
FR-09 (README line 110, "Mã Giảm Giá" — the **customer-facing** apply-coupon-at-checkout
logic). A prior session folded FR-09 into "FR-08 Full" reasoning that coupons are applied "at
the Checkout step" and that FR-09 was the only place among the 4 features complex enough to
need a Decision Table — this was a scope-creep judgment call that was never checked against
the actual assigned-features list. All FR-09 content has been removed from FR-08's
deliverables (see the AI Audit's corrective entry for exactly what was removed). **No Decision
Table exists anywhere in this project's deliverables right now** — FR-08's remaining variables
(`total_amount`, auth-state, cart-clearing) have no combining conditions, so Stage 5 was
skipped, the same way FR-04 skipped it.

**Lesson for every future feature, including FR-15 and FR-17:** check
`docs/hw2-reqs/features-that-need-testing.md` for the *exact* assigned scope before modeling
anything that isn't directly and unambiguously that feature. Do not fold in an adjacent README
feature number just because it's functionally related or conveniently exercises a technique
the assignment wants demonstrated (e.g. a Decision Table) — that is exactly the mistake that
was just corrected.

**The next Continuation item is FR-15 (Product Management CRUD)**, described in §6 below.
After FR-15: FR-17 (Coupon Management CRUD — the *actual* assigned coupon feature; this is
where a Decision Table should be re-evaluated, not assumed), then the global deliverables
(`out/README.md`, `ai-critique.md`, finalize `[AI-02]/[AI-03]/[AI-05]`, commit log, skill demo
video) — see `implementation_plan.md`'s "Continuation" section, items 2–3.

## 2. Authoritative baseline

- **Git commit `43defbc`** — last commit changing Steps 0–6 artifact content (frozen).
- This session's FR-08 Full work and its correction are in the git log between `982b659` and
  the correction commit(s) that follow it — `git log --oneline` shows both the original FR-09
  work and the correction; nothing was rewritten or force-pushed, the history is honest about
  the mistake and the fix.
- Treat **the repository itself — `implementation_plan.md` plus `git log`/`git show`** — as
  authoritative for current status, not this handoff or any prior chat's memory.
- `backend/database.sqlite` may show as modified in the working tree between sessions —
  expected residue from manual test runs (DB is reseeded before each execution batch, per
  `docs/implementation-plan/execution-notes.md`); not a blocker.
- `gh` CLI is installed and authenticated (`gh auth status` → `BuhDuy256`), and GitHub Issues
  are enabled on the repository — both confirmed working (issues #1–#5 filed; #3–#5 are the
  now-out-of-scope FR-09 bugs, left open on GitHub as real findings, just not referenced from
  any deliverable report going forward). GitHub issue filing should work normally for FR-15/FR-17.

## 3. Files a new session must read before doing anything, in priority order

1. `CLAUDE.md` — project orientation: the 4 assigned features (FR-04, FR-08, FR-15, FR-17),
   deliverable file paths, how to run the SUT.
2. `docs/hw2-reqs/features-that-need-testing.md` — **the exact assigned scope, 4 lines.** Read
   this before reading anything else feature-specific. It is the single source of truth for
   "is this in scope," and the FR-09 mistake happened because it wasn't consulted early enough.
3. `docs/architecture/architecture.md` — the frozen architecture (read for context; do **not**
   redesign it).
4. `docs/implementation-plan/implementation_plan.md` — read the Status table and the
   "Continuation" section (item 2, FR-15, is next; item 1, FR-08 Full, is done, with its
   correction noted inline). Treat this file plus `git log`/`git show` as authoritative for
   current status.
5. `docs/implementation-plan/continuation-handoff.md` — this file. Follow it.
6. `docs/implementation-plan/oracle-precedence.md` — the frozen rule for spec-doc conflicts
   and the evidence standard.
7. `docs/implementation-plan/blockers.md` — frozen at Step-0 content, plus a dated addendum:
   `gh` now works and Issues are enabled on the repository.
8. `docs/implementation-plan/execution-notes.md` — the working Model-C execution command form
   (login, authed request, reseed).
9. `.claude/skills/domain-test-design/SKILL.md` and `.claude/skills/bug-reporting/SKILL.md` —
   the two frozen skills to use (see §4).
10. Worked examples, for calibration only — **do not edit these**:
    - `work/FR-04-personal-profile/*` and `out/reports/FR-04-personal-profile/*` — a feature
      with **no** combining conditions (Decision Table explicitly skipped, one-line reason).
      Closest shape to both FR-15 and (likely) FR-17.
    - `work/FR-08-checkout/*` and `out/reports/FR-08-checkout/*` — the corrected, in-scope
      version: `total_amount` (Step-3 smoke) + auth-state + cart-clearing. Also useful for
      seeing how a scope correction is documented (correction notes at the top of each file,
      nothing silently deleted) if the same situation ever needs to be handled again.
11. `README.md` FR-15 (lines 191–198) — the behavioral oracle for FR-15. Do not conflate with
    the adjacent FR-16 (CSV import, lines 200–211) — FR-16 is not one of the 4 assigned
    features either.
12. `api_specification.md` §3 (lines 78–98) — shape only for the product CRUD endpoints.
13. `backend/server.js` — the 5 product route handlers (`GET /api/products` line 141, `GET
    /api/products/:id` line 159, `POST /api/products` line 167, `PUT /api/products/:id` line
    179, `DELETE /api/products/:id` line 191) — read to locate where to test, never as oracle.
14. `out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md` — append new
    rows for every new AI-generated artifact; read the FR-08 correction entry (search for
    "scope error") to see how a correction is logged (append, don't rewrite history), and a
    couple of the earlier FR-08/FR-04 rows for the normal format.

## 4. The two skills to use

- **`domain-test-design`** (`.claude/skills/domain-test-design/SKILL.md`) — builds the Testing
  Model and designs EP/BVA/Decision Table test cases. Used unmodified across FR-08 Full — no
  framework changes were needed. The skill itself was never the problem in the FR-09 mistake —
  the problem was feeding it an out-of-scope feature as input, a Command-level/orchestration
  error, not a skill defect.
- **`bug-reporting`** (`.claude/skills/bug-reporting/SKILL.md`) — confirms failures, groups by
  root cause, classifies severity/priority, writes evidenced bug reports. Also used unmodified.

Invoke them as skills (via the `Skill` tool), feeding them the real FR-15 spec/code/model as
input. **Before invoking, double-check every variable/finding you're about to feed in actually
belongs to the named feature** (README FR-number match, not just functional adjacency) — this
is the one new discipline this correction adds.

## 5. Immutable rules for this and all future Continuation sessions

- **The core is frozen.** Steps 0–6 are Core Complete at commit `43defbc`. FR-08 Full's
  corrected artifacts (`total_amount`, auth-state, cart-clearing; `TC-08-001`/`TC-08-EP-002..004`;
  `BUG-08-001..002`) are now also frozen — do not edit unless a genuine defect is found.
- **Do not edit `domain-test-design/SKILL.md` or `bug-reporting/SKILL.md`** unless the skill
  demonstrably fails on FR-15 — a real framework bug, not a preference. If a fix is genuinely
  needed, go through the notes-first-then-regenerate flow, never a direct hand-patch.
- **Check scope before modeling anything.** Read `docs/hw2-reqs/features-that-need-testing.md`
  and cross-reference the exact README FR-number before treating any variable, endpoint, or
  behavior as part of the current feature. Functional adjacency ("this happens during the same
  user flow") is not the same as being the assigned feature.
- **Every new improvement belongs to Continuation, not the baseline.** Record framework
  limitations in `docs/implementation-plan/learning-notes.md` instead of fixing immediately;
  keep moving with the skills as they are unless a limitation actually blocks completion.
- **`blockers.md` stays frozen at its Step-0 content**, with dated addenda only (never a
  rewrite). Same pattern for any new environment blocker found during FR-15/FR-17.
- Framework governance still applies: MODEL ≠ ORACLE, freeze-before-execute, the three Human
  Gates (`completeness_confirmed`, `FAIL → real bug?`, `approve → file`) — actually ask the
  user for each, don't self-approve — and one AI Audit row per AI-generated artifact. If a
  scope mistake is found (like this one), the audit entry documents it as a correction, not by
  silently rewriting or deleting the earlier rows.
- **Do not assume a Decision Table is needed or not needed for FR-15 or FR-17 based on this
  document's expectations.** Apply Stage 5's own check independently for each feature, using
  only that feature's own actual variables.

## 6. Next Continuation goal: FR-15 (Product Management CRUD)

Per `implementation_plan.md`'s Continuation §2: **FR-15**, through the two frozen skills, as a
fresh feature (no existing partial model — `work/FR-15-product-crud/` does not exist yet).

**Use the skills as a user of the framework, not as its designer.** If a skill produces
something awkward while working through FR-15, note it in `learning-notes.md` and keep going
with the skill as-is.

### What FR-15 actually specifies (README lines 191–198, oracle)

- Admin can Add / View / Edit / Delete products.
- **Input constraints:** product name — required, max 255 characters. Price — required, must
  be a **positive** number (`> 0`). Category — required, must be chosen from the existing list.
- Editing one product must change **only** that product — other products must remain unchanged.

Do not assume this needs, or doesn't need, a Decision Table — apply Stage 5's own check on
FR-15's actual variables once the model is built, and skip with a one-line reason if none combine.

### Findings already surfaced from reading `backend/server.js` (lines 141–196) and
`backend/database.js`, before this handoff was written — verify these still hold, then use
them to build the Testing Model (code shows *where* to test, never the oracle):

1. **`POST/PUT/DELETE /api/products` have zero `authenticateToken` middleware** — any actor,
   including fully unauthenticated ones, can create/edit/delete products. README FR-15 says
   "**Admin** có thể Thêm/Xem/Sửa/Xóa," implying CUD should be admin-restricted. This is the
   highest-signal forbidden-state candidate for this feature — model it as its own
   actor/role variable (Step 1.3), the same shape as FR-08/09's auth-bypass finding, but this
   time squarely inside FR-15's own scope (it's about *this* feature's own CRUD endpoints, not
   an adjacent feature).
2. **`GET /api/products/:id`** (line 159): `if (row.id % 2 === 0) row.price = row.price.toString();`
   — `price` is returned as a string for even-id products, a number otherwise. Code-revealed
   anomaly, not spec-mentioned — needs its own Stage 1.4/Stage 2 check for what a defensible
   oracle claim even is here (the spec says nothing about response type).
3. **`products` table schema** has no `NOT NULL`, no `CHECK`, no foreign key to `categories` —
   confirms no DB-level enforcement of any of the 3 input constraints.
4. **`GET /api/products?search=...`** builds SQL via raw string interpolation
   (`WHERE name LIKE '%${searchQuery}%'`) — a SQL-injection-shaped concern, but **search/listing
   is not described anywhere in FR-15's own spec text (lines 191–198)** — it's closer to
   FR-02/03 (product browsing), which are not assigned features either. Flag it as an
   observation in the Testing Model if useful context, but do not build FR-15 test cases for
   it unless the user explicitly decides to expand scope — this is exactly the kind of
   adjacency that caused the FR-09 mistake; don't repeat it.

### Inputs to read, in priority order (subset of §3, FR-15-specific)

1. `README.md` FR-15 (lines 191–198) — the oracle. Not FR-16.
2. `api_specification.md` §3 (lines 78–98) — shape only.
3. `backend/server.js` — the 5 product route handlers (lines 141, 159, 167, 179, 191).
4. `backend/database.js` — `products`/`categories` schema and seed data.
5. `work/FR-04-personal-profile/testing-model.md` — calibration (no Decision Table, similar
   independent-field-rule shape).

### Expected outputs of FR-15

Following the same three-phase rhythm as FR-08 Full (pausing at all three Human Gates,
actually asking, not self-approving):

- `work/FR-15-product-crud/testing-model.md` (new) — file map, then one model entry per
  variable (`name`, `price`, `category_id`, actor/role for CUD, edit-isolation postcondition),
  each with domain/boundary+source/validation/oracle/metadata. Gate: `completeness_confirmed`.
- `out/reports/FR-15-product-crud/domain-testing/report.md` — EP cases; a Decision Table only
  if Stage 5 actually finds combining conditions for FR-15's own variables specifically.
- `out/reports/FR-15-product-crud/boundary-value-analysis/report.md` — BVA for `name`'s
  255-char boundary and `price`'s `> 0` boundary.
- `work/FR-15-product-crud/execution-results.md` — Model C, no `expected` field, reseed
  between runs if state matters.
- `out/reports/FR-15-product-crud/bug-reports/report.md` — confirmed defects, human-gated per
  report, filed as GitHub issues (should work normally now).
- New rows in `[AI-02]` (starting at Artifact #15) for every new AI-generated artifact.
- Git commits per phase, human gates honored.
- **Before freezing anything: re-confirm every variable in the model traces to FR-15's own
  README text (lines 191–198), not an adjacent feature.**

---

# Prompt for a New Claude Session

```
You are joining a project mid-stream. You have no memory of any prior session on this
project — do not assume any context beyond what you read from the files below. Do not use
any memory system; treat the repository as the only source of truth.

Read, in this exact order, before doing or proposing anything:
1. CLAUDE.md
2. docs/hw2-reqs/features-that-need-testing.md — the EXACT 4 assigned features (FR-04, FR-08,
   FR-15, FR-17). A prior session got this wrong once already (folded FR-09 into FR-08's scope,
   later corrected) — check every variable/finding you model against this list before treating
   it as in-scope, not just against functional adjacency in the README.
3. docs/architecture/architecture.md
4. docs/implementation-plan/implementation_plan.md — the "Status" table and "Continuation"
   section (item 1, FR-08 Full, is done and corrected; item 2, FR-15, is next).
5. docs/implementation-plan/continuation-handoff.md — this file, written for you specifically.
6. docs/implementation-plan/oracle-precedence.md
7. docs/implementation-plan/blockers.md (frozen at Step-0 content, plus a dated addendum: gh
   now works and Issues are enabled)
8. .claude/skills/domain-test-design/SKILL.md
9. .claude/skills/bug-reporting/SKILL.md
10. work/FR-04-personal-profile/* and out/reports/FR-04-personal-profile/* (calibration: no
    Decision Table, independent field-level rules — likely FR-15's shape too)
11. work/FR-08-checkout/* and out/reports/FR-08-checkout/* (the corrected, in-scope version —
    total_amount + auth-state + cart-clearing only; note the correction notes at the top of
    each file for how a scope error is documented without hiding it)
12. README.md FR-15 only (lines 191-198) — not FR-16, not FR-09
13. api_specification.md section 3 (product endpoints)
14. backend/server.js, the 5 product route handlers, and backend/database.js's
    products/categories schema
15. out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md (existing
    rows, including the FR-09 correction entry, for format)

Ground rules, non-negotiable:
- Steps 0-6 are Core Complete (frozen at 43defbc); FR-08 Full's corrected artifacts are also
  now frozen. Do not edit any of these unless you find an actual defect in them.
- Do not redesign, rewrite, or "improve" the architecture, the workflow, or either skill.
- Before modeling any variable, endpoint, or finding, confirm it actually belongs to FR-15
  per docs/hw2-reqs/features-that-need-testing.md and README.md's FR-15 section specifically —
  do not fold in an adjacent feature (e.g. FR-02/03's product listing/search) just because it
  shares a route file or a functional flow, the same mistake already made once with FR-09.
- Your task is to build a complete Testing Model, EP test cases, and a Boundary Value Analysis
  for FR-15 (Product Management CRUD) from scratch. Check whether FR-15's own variables (name,
  price, category, actor/role for CUD) actually combine into anything needing a Decision Table
  (apply the skill's own Stage 5 check) — do not assume either way — then execute and report
  bugs, exactly as described in docs/implementation-plan/continuation-handoff.md section 6.
- Follow the project's existing discipline: MODEL != ORACLE, freeze test cases and commit
  before executing them, honor the three Human Gates by actually asking rather than
  self-approving, and log one AI Audit entry per AI-generated artifact. GitHub issue filing
  should work normally (Issues enabled, gh authenticated).

Start by reading the files above, then tell me what you found (current status, what FR-15
needs) and propose the first concrete step. Do not start executing test cases before I
confirm the plan.
```
