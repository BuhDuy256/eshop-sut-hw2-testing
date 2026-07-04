# Continuation Handoff — for a new Claude Code session

> Written 2026-07-04, at the end of the session that completed FR-08 Full (Continuation item
> 1). This file supersedes the previous handoff (written after the Core Complete baseline,
> before Continuation started) — that one is preserved in git history if needed, but this one
> is the current, authoritative handoff.

---

## 1. Current project status

**Steps 0–6 are Core Complete** (frozen at commit `43defbc`, see `implementation_plan.md`
Status table). **Continuation item 1, FR-08 Full, is also now done** (this session, 2026-07-04):
the FR-08/FR-09 Testing Model was extended (auth-state, cart-clearing, FR-09's 5 coupon
conditions C1–C5, discount formula), EP + BVA + a 7-row Decision Table were designed and
frozen, all 17 cases were executed against the live SUT, and 4 new confirmed bugs were found
and approved (`BUG-08-002..005`, alongside the pre-existing `BUG-08-001` — 5 total for FR-08).

**The next Continuation item is FR-15 (Product Management CRUD)**, described in §6 below.
After FR-15: FR-17 (Coupon Management CRUD), then the global deliverables (`out/README.md`,
`ai-critique.md`, finalize `[AI-02]/[AI-03]/[AI-05]`, commit log, skill demo video) — see
`implementation_plan.md`'s "Continuation" section, items 2–3.

## 2. Authoritative baseline

- **Git commit `43defbc`** — last commit changing Steps 0–6 artifact content (frozen, see the
  original handoff/git history for detail).
- **Commits `982b659` through `0b6f58e`** (this session) — FR-08 Full: extended Testing Model
  (`982b659`), frozen EP/BVA/Decision Table (`1feea56`), execution results (`47f0d86`), bug
  report drafts (`46ab960`), promoted bug reports (`63e92cd`), Stage 7 summary (`0b6f58e`), and
  the `implementation_plan.md` status update (`3d45427`, HEAD as of this handoff).
- Treat **the repository itself — `implementation_plan.md` plus `git log`/`git show`** — as
  authoritative for current status, not this handoff or any prior chat's memory, if they ever
  disagree.
- `backend/database.sqlite` may show as modified in the working tree between sessions — this
  is expected residue from manual test runs (the DB is reseeded before each execution batch,
  per `docs/implementation-plan/execution-notes.md`); not a blocker.
- **Update, same day:** the GitHub-Issues-disabled blocker noted above is **now resolved**.
  Issues have been enabled on the repository, and all 5 FR-08 bug reports (`BUG-08-001..005`),
  originally promoted local-evidence-only, have been filed verbatim as GitHub issues #1–#5 (no
  technical content changed — only each report's `GitHub Issue` field). This resolution is
  recorded as an addendum in `docs/implementation-plan/blockers.md` (not a rewrite of its
  Step-0 content) and in `work/FR-08-checkout/bug-report-drafts.md`. **For FR-15/FR-17: GitHub
  issue filing should now work normally** — attempt it as part of each `approve → file` gate,
  the same fallback-if-blocked discipline still applies if some new blocker appears.

## 3. Files a new session must read before doing anything, in priority order

1. `CLAUDE.md` — project orientation: the 4 assigned features (FR-04, FR-08, FR-15, FR-17),
   deliverable file paths, how to run the SUT.
2. `docs/architecture/architecture.md` — the frozen architecture (read for context; do **not**
   redesign it).
3. `docs/implementation-plan/implementation_plan.md` — read the Status table and the
   "Continuation" section (item 2, FR-15, is next; item 1, FR-08 Full, is marked done with a
   summary). Treat this file plus `git log`/`git show` as authoritative for current status.
4. `docs/implementation-plan/continuation-handoff.md` — this file. Follow it.
5. `docs/implementation-plan/oracle-precedence.md` — the frozen rule for spec-doc conflicts
   and the evidence standard (screenshot vs. raw text vs. self-contained request/response
   capture — all three forms were actually used across FR-08's bug reports).
6. `docs/implementation-plan/blockers.md` — frozen at its Step-0 content, plus a dated
   addendum recording that `gh` now works and that Issues (initially disabled) are now enabled
   on the repository — GitHub issue filing should work normally going forward.
7. `docs/implementation-plan/execution-notes.md` — the working Model-C execution command form
   (login, authed request, reseed).
8. `.claude/skills/domain-test-design/SKILL.md` and `.claude/skills/bug-reporting/SKILL.md` —
   the two frozen skills to use (see §4).
9. Worked examples, for calibration only — **do not edit these**:
   - `work/FR-04-personal-profile/*` and `out/reports/FR-04-personal-profile/*` — the Step-4
     full-pilot example: a feature with **no** combining conditions (Decision Table explicitly
     skipped with a one-line reason). FR-15 looks the same shape (three independent field
     rules, no conditions that must hold together) — this is the closer analogue for FR-15
     than FR-08.
   - `work/FR-08-checkout/*` and `out/reports/FR-08-checkout/*` — the Step-3 smoke *plus* this
     session's full Continuation pass: shows the complete model-extend → EP/BVA/Decision-Table
     → execute → bug-report cycle end to end, including a self-caught execution-order confound
     (`TC-08-BVA-003`, documented rather than silently fixed) and a bug-grouping example
     (`BUG-08-003` merges two failing cases under one root cause). Useful for the *bug-reporting*
     half even though FR-15 likely won't need FR-08's Decision Table half.
10. `README.md` FR-15 (lines 191–198) — the behavioral oracle. **Do not conflate with FR-16**
    (CSV import, lines 200–211, immediately below it in the README) — FR-16 is a *different*
    feature and is **not** one of this student's 4 assigned features (FR-04, FR-08, FR-15,
    FR-17, per `CLAUDE.md`). Read FR-15 only.
11. `api_specification.md` §3 (`GET /api/products`, `GET /api/products/:id`, `POST/PUT/DELETE
    /api/products` — lines 78–98) — interface shape only for the product CRUD endpoints, not a
    behavioral oracle (see `oracle-precedence.md` for why).
12. `backend/server.js` — the product route handlers (`GET /api/products` line 141, `GET
    /api/products/:id` line 159, `POST /api/products` line 167, `PUT /api/products/:id` line
    179, `DELETE /api/products/:id` line 191) — read to locate where to test, per
    architecture.md §2.1; never as the oracle.
13. `out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md` — append new
    rows here for every new AI-generated artifact; Artifacts #1–14 (plus one update) are
    already logged — read a couple of the FR-08 ones (e.g. #11, #12) for the current format
    before adding #15 onward.

## 4. The two skills to use

- **`domain-test-design`** (`.claude/skills/domain-test-design/SKILL.md`) — builds the Testing
  Model and designs EP/BVA/Decision Table test cases. Used unmodified across FR-08 Full this
  session — no framework changes were needed.
- **`bug-reporting`** (`.claude/skills/bug-reporting/SKILL.md`) — confirms failures, groups by
  root cause, classifies severity/priority, writes evidenced bug reports. Also used unmodified.

Invoke them as skills (via the `Skill` tool), feeding them the real FR-15 spec/code/model as
input — the same way they were used for FR-08 Full this session. Do not read their internal
logic as a guide to copy by hand instead of invoking them.

## 5. Immutable rules for this and all future Continuation sessions

- **The core is frozen.** Steps 0–6 are Core Complete at commit `43defbc`. **FR-08 Full's
  artifacts from this session are now also frozen** (the extended `testing-model.md`,
  `TC-08-EP-002..011`/`TC-08-BVA-001..007`/`TC-08-DT-002`, `ER-08-*`, `BUG-08-002..005`) — do
  not edit any of these unless a genuine defect in them is found, never for polish or
  generalization.
- **Do not edit `domain-test-design/SKILL.md` or `bug-reporting/SKILL.md`** unless the skill
  demonstrably fails or produces an indefensible result while actually being used on FR-15 — a
  real framework bug, not a preference. Both skills ran FR-08 Full without needing any change;
  the bar for touching them stays high. If a fix is genuinely needed, it goes through the
  notes-first-then-regenerate flow (`docs/implementation-plan/skill-4-...-notes.md` /
  `skill-5-...-notes.md`), never a direct hand-patch.
- **Every new improvement belongs to Continuation, not the baseline.** If FR-15 surfaces a
  limitation in the framework or a skill, **record it** (as a Learning Artifact entry in
  `docs/implementation-plan/learning-notes.md`, following the `LN-001` pattern) **instead of
  fixing it immediately.** Keep moving through FR-15 using the skills as they are. Only come
  back to fix the framework if the limitation actually blocks completing FR-15 — and even then,
  confirm with the user first.
- **`blockers.md` stays frozen at its Step-0 content**, with one addendum (dated, appended, not
  a rewrite) recording the GitHub-Issues-disabled-then-resolved episode. Follow the same
  pattern for FR-15 if a new environment blocker appears: record it as a dated addendum or in
  the feature's own bug-report-drafts file, never by rewriting existing frozen content.
  GitHub issue filing itself should now work normally for FR-15/FR-17 (Issues enabled, `gh`
  authenticated) — attempt it at the `approve → file` gate as a matter of course.
- Framework governance still applies: MODEL ≠ ORACLE (expected results only from `README.md`
  or an accepted assumption, never from code or observed output), freeze-before-execute
  (commit the frozen test case before any execution), the three Human Gates
  (`completeness_confirmed`, `FAIL → real bug?`, `approve → file`) — actually ask the user for
  each, don't self-approve — and one AI Audit row per AI-generated artifact, appended at
  creation time. This session followed exactly this rhythm for FR-08 Full (extend model → stop
  for `completeness_confirmed` → design + freeze + commit → execute → stop for `FAIL → real
  bug?`/draft bugs → stop for `approve → file` → promote/attempt-filing → commit) — repeat the
  same rhythm for FR-15, pausing at each of the three gates rather than proceeding through all
  of them in one uninterrupted pass.

## 6. Next Continuation goal: FR-15 (Product Management CRUD)

Per `implementation_plan.md`'s Continuation §2: **FR-15**, through the two frozen skills, as a
fresh feature (no existing smoke case or partial model to extend — unlike FR-08, there is no
`work/FR-15-product-crud/testing-model.md` yet; Phase 0/1 start from scratch here, closer to
how FR-04 began).

**Use the skills as a user of the framework, not as its designer.** If `domain-test-design` or
`bug-reporting` produces something awkward, incomplete, or surprising while working through
FR-15, the default response is: note it as a Continuation-improvement candidate in
`learning-notes.md` and keep going with the skill as it is — not stop and redesign the skill
mid-task.

### What FR-15 actually specifies (README lines 191–198, oracle)

- Admin can Add / View / Edit / Delete products.
- **Input constraints:** product name — required, max 255 characters. Price — required, must
  be a **positive** number (`> 0`). Category — required, must be chosen from the existing list.
- Editing one product must change **only** that product — other products must remain unchanged
  (an isolation/side-effect constraint, likely its own test case rather than a boundary or
  equivalence class).

At a glance this does **not** look like it has FR-08/09's combining-conditions shape (each of
the three constraints — name, price, category — reads as independently enforced, similar to
FR-04's `name`/`phone`/`shipping_address`) — but this is an observation, not a conclusion;
apply Stage 5's own check (`domain-test-design`) rather than skipping the Decision Table step
outright. If it turns out no conditions combine, skip it with a one-line reason, the same way
FR-04 did.

### Inputs to read, in priority order (subset of §3, FR-15-specific)

1. `README.md` FR-15 (lines 191–198) — the oracle. Do not read FR-16 as part of this feature.
2. `api_specification.md` §3 (lines 78–98) — shape only for `GET /products`, `GET
   /products/:id`, `POST/PUT/DELETE /products`.
3. `backend/server.js` — the 5 product route handlers (lines 141, 159, 167, 179, 191) — to
   locate what to test and to check for any code-revealed second boundary (e.g., does the code
   actually enforce "name max 255 chars" or "price > 0," or does it accept anything and let the
   DB/frontend silently truncate or reject? Does `category_id` get validated against the real
   category list, or just stored as whatever integer is sent?).
4. `backend/database.js` — the `products`/`categories` table schema and seed data, for
   boundary values (name length limits at the schema level, the actual seeded category id
   range) and to check whether `price` has any DB-level constraint (e.g. `CHECK` or just
   `REAL`/`INTEGER` with no positivity enforcement).
5. `work/FR-04-personal-profile/testing-model.md` and `out/reports/FR-04-personal-profile/*` —
   calibration for a feature shaped like FR-15 (independent field-level rules, no Decision
   Table) — not FR-08's.

### Expected outputs of FR-15

Following the same three-phase rhythm as FR-08 Full (with the three Human Gates actually
paused on, not self-approved):

- `work/FR-15-product-crud/testing-model.md` (new — first Phase-0/1 pass for this feature,
  no partial model exists yet) — file map (which routes/files FR-15 touches), then one model
  entry per variable (`name`, `price`, `category_id`) with domain/boundary+source/validation/
  oracle/metadata, plus the edit-isolation constraint recorded as its own forbidden/postcondition
  note (Step 1.3-shaped, even though it isn't exactly "forbidden state" — it's "other products
  must not change," the same kind of explicit-not-buried-in-the-model note FR-08's
  cart-clearing variable used). Human gate: `completeness_confirmed`, actually asked.
- `out/reports/FR-15-product-crud/domain-testing/report.md` — EP cases for all 3 variables +
  the edit-isolation case; a Decision Table only if Stage 5 actually finds combining conditions
  (with a one-line skip-reason otherwise, per the FR-04 precedent).
- `out/reports/FR-15-product-crud/boundary-value-analysis/report.md` — BVA for `name`'s 255-char
  boundary and `price`'s `> 0` boundary (both are exactly the numeric/lexical boundary shapes
  `domain-test-design`'s Stage 4 already knows how to handle — no new boundary *kind* expected
  here, unlike FR-08/09's date and enum boundaries).
- `work/FR-15-product-crud/execution-results.md` — executed via Model C, no `expected` field,
  same discipline as FR-08 (reseed between runs if state matters; watch for the same kind of
  execution-order confound FR-08's `TC-08-BVA-003` hit, where one case's setup accidentally
  changes state a later case depends on).
- `out/reports/FR-15-product-crud/bug-reports/report.md` — any confirmed defects, human-gated
  per report (`approve → file`), filed as GitHub issues (Issues are enabled and `gh` is
  authenticated as of this handoff — this should now work normally; fall back to
  local-evidence-only, documented, only if some new blocker appears).
- New rows in `[AI-02]` (starting at Artifact #15) for every new AI-generated artifact.
- Git commits following the same per-phase discipline as FR-08 Full: freeze before execute,
  one commit per artifact/phase, human gates honored (paused on, not silently auto-approved).
- Any framework limitation surfaced along the way, logged in `learning-notes.md` rather than
  fixed in place (per §5) — FR-08 Full surfaced none; FR-15 may or may not.

---

# Prompt for a New Claude Session

```
You are joining a project mid-stream. You have no memory of any prior session on this
project — do not assume any context beyond what you read from the files below. Do not use
any memory system; treat the repository as the only source of truth.

Read, in this exact order, before doing or proposing anything:
1. CLAUDE.md
2. docs/architecture/architecture.md
3. docs/implementation-plan/implementation_plan.md — the "Status" table and the
   "Continuation" section (item 1, FR-08 Full, is done; item 2, FR-15, is next). Treat this
   file plus `git log`/`git show` as authoritative for current project state.
4. docs/implementation-plan/continuation-handoff.md — the handoff written for you
   specifically. Follow it.
5. docs/implementation-plan/oracle-precedence.md
6. docs/implementation-plan/blockers.md (frozen at Step-0 content, plus a dated addendum:
   gh now works and Issues are now enabled on the repository)
7. docs/implementation-plan/execution-notes.md
8. .claude/skills/domain-test-design/SKILL.md
9. .claude/skills/bug-reporting/SKILL.md
10. work/FR-04-personal-profile/* and out/reports/FR-04-personal-profile/* (calibration: a
    feature with no combining conditions, closer to FR-15's shape)
11. work/FR-08-checkout/* and out/reports/FR-08-checkout/* (calibration: the full
    model-extend -> EP/BVA/Decision-Table -> execute -> bug-report cycle, done this session)
12. README.md FR-15 only (lines 191-198) — do not conflate with the adjacent FR-16 (CSV
    import), which is not one of this student's 4 assigned features
13. api_specification.md section 3 (product endpoints)
14. backend/server.js, the 5 product route handlers, and backend/database.js's
    products/categories schema
15. out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md (existing
    rows, for format — Artifacts #1-14 already logged)

Ground rules, non-negotiable:
- Steps 0-6 are Core Complete (frozen at 43defbc); FR-08 Full's artifacts from the prior
  session are also now frozen. Do not edit any of these unless you find an actual defect in
  them — never for polish or generalization.
- Do not redesign, rewrite, or "improve" the architecture, the workflow, or either skill. You
  are a user of this framework now, not its designer. Both skills ran FR-08 Full without any
  change needed; if a skill produces something awkward on FR-15, write it down in
  learning-notes.md and keep going with the skill as it is.
- Your task is to build a complete Testing Model, EP test cases, and a Boundary Value Analysis
  for FR-15 (Product Management CRUD) — starting from scratch, unlike FR-08 which had a
  partial model to extend. Check whether FR-15's three field-level rules (name, price,
  category) actually combine into anything needing a Decision Table (apply the skill's own
  Stage 5 check rather than assuming either way), then execute and report bugs, exactly as
  described in docs/implementation-plan/continuation-handoff.md section 6.
- Follow the project's existing discipline: MODEL != ORACLE, freeze test cases and commit
  before executing them, honor the three Human Gates (completeness_confirmed, FAIL -> real
  bug?, approve -> file) by actually asking me rather than self-approving, and log one AI
  Audit entry per AI-generated artifact. GitHub issue filing should now work normally (Issues
  are enabled, gh is authenticated) — attempt it at the approve -> file gate; if some new
  blocker appears, fall back to local-evidence-only and note it in FR-15's own
  bug-report-drafts file rather than editing blockers.md's existing content.

Start by reading the files above, then tell me what you found (current status, what FR-15
needs) and propose the first concrete step. Do not start executing test cases before I
confirm the plan.
```
