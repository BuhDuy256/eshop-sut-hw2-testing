# Continuation Handoff — for a new Claude Code session

> Written 2026-07-04, at the end of the session that produced the Core Complete baseline.
> No Continuation work was performed in that session. This file is the handoff artifact only.

---

## 1. Current project status

**Steps 0–6 of the AI testing workflow are Core Complete.** The frozen pilot — Step 0
(blockers), Step 1 (execution viability), Step 2 (oracle precedence), Step 3 (FR-08 smoke),
Step 4 (FR-04 full pilot), Step 5 (`domain-test-design` skill extracted), Step 6
(`bug-reporting` skill extracted) — is done, human-reviewed, and confirmed consistent across
the plan document, the artifacts, and git history.

**Continuation has not started.** The next work is FR-08 Full, described in §6 below.

## 2. Authoritative baseline

- **Git commit `43defbc`** is the last commit that changed Steps 0–6 *artifact content*
  (testing models, test cases, execution results, bug reports, the two `SKILL.md` files, AI
  Audit rows).
- **Git commit `b48b1b2`** (HEAD as of this handoff) added only a documentation/policy note to
  `implementation_plan.md` recording the baseline and the no-retroactive-edit rule — it did
  not change any Steps 0–6 artifact.
- Treat **the repository itself — `implementation_plan.md` plus `git log`/`git show`** — as
  the authoritative source of current status. Do not rely on any prior chat's memory or
  summary; if this handoff and the repository ever disagree, the repository wins.
- One pre-existing, harmless leftover: `backend/database.sqlite` shows as modified in the
  working tree (residue from earlier manual test runs). Reseed it
  (`docker exec eshop-backend node database.js`, per
  `docs/implementation-plan/execution-notes.md`) before running new FR-08 executions; this is
  not a blocker and not part of the baseline.

## 3. Files a new session must read before doing anything, in priority order

1. `CLAUDE.md` — project orientation: the 4 assigned features (FR-04, FR-08, FR-15, FR-17),
   deliverable file paths, how to run the SUT.
2. `docs/architecture/architecture.md` — the frozen architecture (read for context; do **not**
   redesign it).
3. `docs/implementation-plan/implementation_plan.md` — **read the Status table and the
   "Continuation" section first**; this is where the baseline commit and the no-retroactive-
   edit policy are recorded as project fact, not just as this handoff's claim.
4. `docs/implementation-plan/oracle-precedence.md` — the frozen rule for spec-doc conflicts
   and the evidence standard (screenshot vs. raw text).
5. `docs/implementation-plan/blockers.md` — current state of the GitHub repo / `gh` CLI
   (as of the baseline, `gh` was not installed; bug filing falls back to local approved draft
   + evidence only).
6. `docs/implementation-plan/execution-notes.md` — the working Model-C execution command form
   (login, authed request, reseed).
7. `.claude/skills/domain-test-design/SKILL.md` and `.claude/skills/bug-reporting/SKILL.md` —
   the two frozen skills to use (see §4).
8. Worked examples, for calibration only — **do not edit these**:
   - `work/FR-08-checkout/*` and `out/reports/FR-08-checkout/*` (the Step-3 smoke case —
     `TC-08-001`, `BUG-08-001` — is the seed to build FR-08 Full from, not to redo)
   - `work/FR-04-personal-profile/*` and `out/reports/FR-04-personal-profile/*` (the Step-4
     full-pilot example, showing what a complete model/EP/BVA/execution/bug-report pass looks
     like end to end)
9. `README.md` — the SUT specification, especially FR-08 (checkout, lines ~102–108) and FR-09
   (the 5 combined coupon conditions, lines ~110–134). This is the behavioral oracle.
10. `api_specification.md` §4.3/§5.1 — interface shape only for checkout/coupon endpoints, not
    a behavioral oracle (see oracle-precedence.md for why).
11. `backend/server.js` — read the checkout/coupon route handlers to locate what to test
    (legitimate per architecture.md §2.1: code shows *where*, never *what's correct*).
12. `out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md` — append
    new rows here for every new AI-generated artifact; read the existing rows first for format.

## 4. The two skills to use

- **`domain-test-design`** (`.claude/skills/domain-test-design/SKILL.md`) — builds the Testing
  Model and designs EP/BVA/Decision Table test cases.
- **`bug-reporting`** (`.claude/skills/bug-reporting/SKILL.md`) — confirms failures, groups by
  root cause, classifies severity/priority, writes evidenced bug reports.

Invoke them as skills (via the `Skill` tool), the same way they were validated in Step 5/6 —
feed them the real FR-08 spec/code/model as input. Do not read their internal logic as a guide
to copy by hand instead of invoking them; the whole point of Continuation is to use them as
built.

## 5. Immutable rules for this and all future Continuation sessions

- **The core is frozen.** Steps 0–6 are Core Complete at commit `43defbc`.
- **Do not edit Steps 0–6 artifacts** (`work/FR-08-checkout/*` and `work/FR-04-personal-profile/*`
  content from the pilot, `out/reports/FR-08-checkout/domain-testing/report.md`'s `TC-08-001`,
  `out/reports/FR-04-personal-profile/*`, the AI Audit rows already logged for Steps 0–6)
  **unless a genuine defect in them is found** — never for further polish, restyling, or
  generalization.
- **Do not edit `domain-test-design/SKILL.md` or `bug-reporting/SKILL.md`** unless the skill
  demonstrably fails or produces an indefensible result while actually being used on FR-08 —
  a real framework bug, not a preference. If found, the fix still goes through the
  notes-first-then-regenerate flow (`docs/implementation-plan/skill-4-...-notes.md` /
  `skill-5-...-notes.md`), never a direct hand-patch.
- **Every new improvement belongs to Continuation, not the baseline.** If FR-08 Full surfaces
  a limitation in the framework or a skill, **record it** (as a Learning Artifact entry in
  `docs/implementation-plan/learning-notes.md`, following the `LN-001` pattern already there)
  **instead of fixing it immediately.** Keep moving through FR-08 Full using the skills as they
  are. Only come back to fix the framework if the limitation actually blocks completing FR-08
  Full — and even then, confirm with the user first.
- Framework governance still applies: MODEL ≠ ORACLE (expected results come only from
  `README.md` or an accepted assumption, never from code or observed output), freeze-before-
  execute (commit the frozen test case before any execution), the three Human Gates
  (`completeness_confirmed`, `FAIL → real bug?`, `approve → file`), and one AI Audit row per
  AI-generated artifact, appended at creation time.

## 6. First Continuation goal: FR-08 Full

Per `implementation_plan.md`'s Continuation §1: **FR-08 Full**, through the two frozen skills,
reusing the Step-3 smoke case (`TC-08-001` / `BUG-08-001`) as the seed rather than redoing it.
FR-08 is deliberately the first Continuation target because it stresses the **Decision Table**
path — the only path in this project's 4 assigned features with genuinely combining
conditions (FR-09's 5 coupon conditions: code exists + active, not expired, order total meets
threshold, user logged in, uses-per-user not exceeded) — which neither the FR-08 smoke nor the
FR-04 pilot exercised.

**Use the skills as a user of the framework, not as its designer.** If `domain-test-design` or
`bug-reporting` produces something awkward, incomplete, or surprising while working through
FR-08 Full, the default response is: note it as a Continuation-improvement candidate and keep
going with the skill as it is — not stop and redesign the skill mid-task.

### Inputs to read, in priority order (subset of §3, FR-08-specific)

1. `README.md` FR-08 (checkout) and FR-09 (coupons) — the oracle.
2. `api_specification.md` §4.3 (checkout) and §5.1 (apply-coupon) — shape only.
3. `backend/server.js` — checkout, coupon, and cart route handlers — to locate what to test.
4. `work/FR-08-checkout/testing-model.md` — the existing (partial) model from the Step-3
   smoke, to extend, not replace.
5. `out/reports/FR-08-checkout/domain-testing/report.md` — the existing `TC-08-001`, to keep
   and build around.
6. `docs/implementation-plan/oracle-precedence.md` — reapply the same precedence rule to any
   new README-vs-api_specification conflict found in the coupon logic.

### Expected outputs of FR-08 Full

- `work/FR-08-checkout/testing-model.md` — extended to cover every FR-08/FR-09 variable: auth
  state, cart state, `total_amount` (already modeled), coupon `code`, and the 5 coupon
  conditions (C1–C5), each with domain/boundary/source/validation/oracle/metadata, run through
  the `domain-test-design` skill's Stage 1–2 (including the assumption-defensibility check —
  watch for any FR-09 rule that looks like it needs a layer-specific assumption; prefer the
  least-committing, reframed oracle per Stage 2, the same lesson learned from FR-04's A4).
- `out/reports/FR-08-checkout/domain-testing/report.md` — full EP test cases for all FR-08/
  FR-09 variables (not just `total_amount`), with `TC-08-001` retained and referenced, not
  duplicated.
- `out/reports/FR-08-checkout/boundary-value-analysis/report.md` — currently an empty stub;
  fill with BVA for `min_order_amount` (per-coupon thresholds), `max_uses_per_user`, and any
  discount-rounding boundary FR-09 implies.
- A **Decision Table** for the 5 combined coupon conditions — the first real one in this
  project — built via `domain-test-design`'s Stage 5, with cases for combinations that
  actually route to different outcomes (not an exhaustive 2⁵ truth table unless the skill's
  own gate-legitimacy check says otherwise).
- `work/FR-08-checkout/execution-results.md` — extended with new `ER-08-*` entries for the new
  cases, executed via Model C (native Bash), no `expected` field.
- `out/reports/FR-08-checkout/bug-reports/report.md` — extended with any new confirmed defects
  from `bug-reporting`'s Stage 1–7 (grouped by root cause, severity from proven evidence only,
  spec-vs-assumption labeled, human-gated per report), `BUG-08-001` retained.
- New rows in `[AI-02]` for every new AI-generated artifact.
- Git commits following the same discipline as Steps 3–4: freeze before execute, one commit
  per artifact/phase, human gates honored (not silently auto-approved).
- Any framework limitation surfaced along the way, logged in `learning-notes.md` rather than
  fixed in place (per §5).

---

# Prompt for a New Claude Session

```
You are joining a project mid-stream. You have no memory of any prior session on this
project — do not assume any context beyond what you read from the files below. Do not use
any memory system; treat the repository as the only source of truth.

Read, in this exact order, before doing or proposing anything:
1. CLAUDE.md
2. docs/architecture/architecture.md
3. docs/implementation-plan/implementation_plan.md — pay special attention to the "Status"
   table and the "Continuation" section, which record a baseline git commit and a
   no-retroactive-edit policy for Steps 0-6. Treat this file plus `git log`/`git show` as
   authoritative for current project state.
4. docs/implementation-plan/continuation-handoff.md — the handoff written for you specifically.
   Follow it.
5. docs/implementation-plan/oracle-precedence.md
6. docs/implementation-plan/blockers.md
7. docs/implementation-plan/execution-notes.md
8. .claude/skills/domain-test-design/SKILL.md
9. .claude/skills/bug-reporting/SKILL.md
10. work/FR-08-checkout/* and out/reports/FR-08-checkout/* (existing Step-3 smoke case —
    build on it, do not redo it)
11. work/FR-04-personal-profile/* and out/reports/FR-04-personal-profile/* (worked example of
    a full pass — for calibration only, do not edit)
12. README.md, focusing on FR-08 (checkout) and FR-09 (coupons)
13. api_specification.md, sections for checkout and apply-coupon
14. backend/server.js, the checkout/coupon/cart route handlers
15. out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md (existing
    rows, for format)

Ground rules, non-negotiable:
- Steps 0-6 of this project's testing workflow are already Core Complete, frozen at a git
  commit recorded in implementation_plan.md. Do not edit any Steps 0-6 artifact (testing
  models, test cases, execution results, bug reports, the two SKILL.md files, existing AI
  Audit rows) unless you find an actual defect in them — never for polish or generalization.
- Do not redesign, rewrite, or "improve" the architecture, the workflow, or either skill. You
  are a user of this framework now, not its designer. If a skill produces something awkward
  or incomplete while you use it on real work, write it down as a Continuation-improvement
  candidate (following the existing learning-notes.md pattern) and keep going with the skill
  as it is, rather than stopping to fix it.
- Your task is to start FR-08 Full: apply the domain-test-design skill and the bug-reporting
  skill (invoke them as skills, using their actual logic, not by copying their steps by hand)
  to build out a complete Testing Model, EP test cases, a Boundary Value Analysis, and — this
  is the point of choosing FR-08 first — a real Decision Table for FR-09's 5 combined coupon
  conditions, then execute and report bugs, exactly as described in
  docs/implementation-plan/continuation-handoff.md section 6.
- Follow the project's existing discipline: MODEL != ORACLE (expected results only from
  README.md or an accepted assumption, never from code or observed output), freeze test cases
  and commit before executing them, honor the three Human Gates (completeness_confirmed,
  FAIL -> real bug?, approve -> file) by actually asking me rather than self-approving, and
  log one AI Audit entry per AI-generated artifact.

Start by reading the files above, then tell me what you found (current status, what FR-08
Full needs) and propose the first concrete step. Do not start executing test cases before I
confirm the plan.
```
