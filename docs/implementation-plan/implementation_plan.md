# implementation_plan.md — HW02 AI Testing Workflow

> **Purpose:** Executable plan for the frozen implementation strategy. Also a resume point.
> When resuming, read **Status → Next Action**, do that step, then update Status.
> **Architecture, contracts, and invariants are frozen.** This file turns them into tasks.
> It does not re-open any design decision.

---

## How to use this file

- Do steps in order. Do not start a step until the previous step's **Exit Criteria** all pass.
- Every step ends with a **Git commit** (satisfies HW policy §12: one commit per step).
- A step's **Stop Conditions** override the plan — if one triggers, halt and get a human decision.
- `FR-04` is the first full pilot. `FR-08` is used only as the pipeline smoke (Step 3).

---

## Global rules (apply in every step)

1. **MODEL ≠ ORACLE.** Expected results come only from the spec (or an accepted assumption), never from code or observed output. Enforced structurally by the contracts:
   - `Test Case.expected_source ∈ {spec, assumption}` — never `impl`/`actual`.
   - `Execution Result` has **no** `expected` field — it references the frozen Test Case.
   - A Test Case may cite an Assumption as oracle only if that assumption is `accepted`.
2. **Oracle precedence.** `README.md` = behavioral oracle (wins). `api_specification.md` = interface shape only. External reference only on a confirmed conflict (recorded in the AI Audit).
3. **Freeze before execute.** Frozen Test Cases are committed to Git **before** any Execution Result is produced. The Git commit order is the proof; never edit an expected value after seeing an actual.
4. **Execution = Model C.** The agent executes against the SUT with its native Bash tool (`curl`/`node`). No test-runner, no assertions-in-code. Comparison and verdict live in the workflow + human gate. `.http` records are captured **after** execution as documentation, not built up front.
5. **Audit as you go.** Append one AI Audit Entry per AI-generated artifact at the moment it is created — never reconstruct at the end.
6. **Human gates (mandatory).** `completeness_confirmed` (model), `FAIL → real bug?` (execution), `approve → file` (bug report).
7. **Metadata** `{source, confidence, status}` on every Testing Model item and Assumption.
8. **No pre-built templates.** The Step 3 smoke produces the first real instance of each artifact; those instances become the templates.
9. **Skill decoupling.** Before saving any `SKILL.md`, run the coupling smell-test grep (see Step 5). Any hit on an HW02 noun = a leak to fix.

---

## Folder structure (create minimal only, at each step's prep — no templates)

```
docs/implementation-plan/
  implementation_plan.md      # this file
  blockers.md                 # Step 0 answers
  execution-notes.md          # Step 1 working execution command form
  oracle-precedence.md        # Step 2 rule
  learning-notes.md           # cross-cutting Learning Artifact log (architecture.md §3.1/§8), first entry from Step 3 self-review
  skill-4-domain-test-design-notes.md  # Step 5.1 methodology notes, input to generate-skill
  skill-5-bug-reporting-notes.md       # Step 6.1 methodology notes, input to generate-skill

work/                         # internal working artifacts (optional-to-submit, §14 "supporting")
  FR-08-checkout/             # created at Step 3 prep
    testing-model.md
    execution-results.md
    bug-report-drafts.md
    requests.http             # captured AFTER execution
  FR-04-personal-profile/     # created at Step 4 prep
    testing-model.md
    assumptions.md
    execution-results.md
    bug-report-drafts.md
    requests.http

out/reports/FR-XX-.../        # DELIVERABLES (already scaffolded as stubs)
  domain-testing/report.md            # EP test cases (frozen) — canonical Test Case store
  boundary-value-analysis/report.md   # BVA test cases (frozen)
  bug-reports/report.md               # approved bugs
  bug-reports/evidence/*.png          # screenshots (self-contained, relative paths)

out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md
.claude/skills/domain-test-design/SKILL.md   # created at Step 5
.claude/skills/bug-reporting/SKILL.md        # created at Step 6
```

> The frozen **Test Cases are stored in the deliverable report files**, not duplicated in `work/`. This avoids the two-sources-of-truth drift.

---

## Step 0 — Resolve external blockers (parallel, out-of-band)

**Goal:** get the two answers only a human can provide.

**Tasks**
- 0.1 Ask the TA: does the assigned set (FR-04, FR-08, FR-15, **FR-17 — a second Pool-C feature**) map onto rubric row 4 (*Mobile*, 15 pts), or must one feature be swapped? Record in `docs/implementation-plan/blockers.md`.
- 0.2 Confirm the group GitHub repo + Issues board URL; run `gh auth status`. Record result.

**File paths:** `docs/implementation-plan/blockers.md`
**Exit criteria:** both answers recorded; `gh auth status` is OK or explicitly noted pending.
**Assumption validated:** the feature set maps to the rubric; a real Issues target exists.
**Risks impossible after this:** silent grade-cap; Step 3 GitHub-posting blocking with no fallback.
**Commit:** yes — `Step 0: record external blocker resolutions`.
**Stop condition:** if the scope answer requires changing the feature set (e.g., swap FR-17 for a mobile feature) → **halt and re-plan**; this changes the whole feature list (missing authoritative input).

---

## Step 1 — Validate execution viability (Model C)

**Goal:** prove the agent can run the SUT, authenticate, execute a request, and reseed — all via native Bash — before any test is designed.

**Tasks**
- 1.1 `docker-compose up --build`; confirm backend `:3000`, admin `:5174`, web `:5173`.
- 1.2 Agent executes `POST /api/login` for `admin@eshop.com / Admin123!` and `test@eshop.com / Test1234!` → capture both JWTs.
- 1.3 Agent executes one authed request: `GET /api/users/me` (user token) and `GET /api/products`. Capture a real 200 body.
- 1.4 Run `node backend/database.js` to reseed; re-run 1.3 to confirm a known baseline is restored (idempotent reset).
- 1.5 Record the exact working execution command form (curl or node one-liner) in `docs/implementation-plan/execution-notes.md`. This is a **reference, not a harness**.

**File paths:** `docs/implementation-plan/execution-notes.md`
**Exit criteria:** two tokens in hand; one real 200 response captured; reseed confirmed idempotent.
**Assumption validated:** the entire execution model (agent-executes-via-Bash, auth, clean state).
**Risks impossible after this:** R6 (PowerShell curl in path), R7 (token/role), R4 (no clean state), "SUT won't run."
**Commit:** yes — `Step 1: validate Model-C execution viability`.
**Stop condition:** SUT will not start → halt and fix environment before any further step.

---

## Step 2 — Freeze the oracle-precedence rule

**Goal:** write the deterministic rule that resolves spec-doc conflicts, so the FR-08 bug cannot be reasoned away.

**Tasks**
- 2.1 Write `docs/implementation-plan/oracle-precedence.md`: `README.md` = behavioral oracle (wins); `api_specification.md` = shape only; external reference only on confirmed conflict; evidence standard (API bug → screenshot of request+response; UI bug → browser screenshot; MD report is self-contained, GitHub is a mirror).
- 2.2 Apply the rule on paper to the FR-08 `total_amount` contradiction; confirm it yields "backend must recompute; trusting client `total_amount` = bug."

**File paths:** `docs/implementation-plan/oracle-precedence.md`
**Exit criteria:** rule written; FR-08 contradiction resolves deterministically.
**Assumption validated:** doc-vs-doc conflicts have a defined winner.
**Risks impossible after this:** R3 (oracle contamination via the wrong doc; missing the flagship FR-08 bug).
**Commit:** yes — `Step 2: freeze oracle precedence rule`.
**Stop condition:** a README-vs-API-spec conflict the rule cannot resolve → log as an Assumption + human review; do not guess.

---

## Step 3 — Vertical smoke: FR-08 forged `total_amount`, one case, all six contracts, by hand

**Goal:** drive one certain-outcome case end-to-end to prove the pipeline composes, the contracts link, and the structural guards hold. Feature-agnostic pipeline validation.

**Prep**
- 3.0 Create minimal folders only (no templates): `work/FR-08-checkout/`, `out/reports/FR-08-checkout/bug-reports/evidence/`.

**Tasks (commit per artifact)**
- 3.1 **Testing Model fragment** → `work/FR-08-checkout/testing-model.md`: variable `total_amount` — domain, boundary + relation, `source: spec (README FR-08)`, validation, oracle (backend recomputes; client value rejected), metadata `{source: spec, confidence: HIGH, status: proposed}`, forbidden-field note (client-controlled total). Human-review: approve.
- 3.2 **Test Case (frozen)** → first case in `out/reports/FR-08-checkout/domain-testing/report.md`: `TC-08-001`, technique EP/negative, preconditions (user token, cart seeded to real total X), input (`POST /api/checkout` with `total_amount = 1`), steps, **expected** (order persists server-recomputed X; client `1` rejected/ignored) + `expected_source: README FR-08`, `status: frozen`. **Commit this before executing** (freeze-before-execute proof).
- 3.3 **Execution Result** → `work/FR-08-checkout/execution-results.md`: run 3.2 via Model C; record `result id`, `ref: TC-08-001`, actual (checkout response + a follow-up `GET` of the stored order/total), `verdict`, evidence pointer. **No `expected` field.** Screenshot → `out/reports/FR-08-checkout/bug-reports/evidence/BUG-08-001.png`.
- 3.4 **Bug Report Draft** (if FAIL) → `work/FR-08-checkout/bug-report-drafts.md`: id, title, `ref: TC-08-001`, expected-vs-actual, repro, evidence ref, severity, priority, `status: draft`. Human gate → approve → promote to `out/reports/FR-08-checkout/bug-reports/report.md`. If Step 0 resolved repo + `gh`: file the GitHub issue; else stop at approved draft + local evidence.
- 3.5 **AI Audit Entry** → append rows to `out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md` for each AI-generated artifact (model fragment, test case, bug draft): tool, timestamp, verbatim prompt, verbatim output, verdict, reasoning, student fix.
- 3.6 Capture the executed request into `work/FR-08-checkout/requests.http` (post-hoc documentation).

**Exit criteria (all must pass)**
- [x] Each artifact exists and links to the next by id.
- [x] `execution-results.md` contains no `expected` field.
- [x] `git log` shows the frozen Test Case commit **before** the Execution Result commit
  (`024a656` before `3009936`).
- [x] Evidence saved under the deliverable evidence folder — **caveat:** not a `.png`
  screenshot as originally worded; a raw request/response `.txt` capture was substituted
  because this case is API-only (curl, no browser), per `oracle-precedence.md` rule 5's
  documented alternative for API-level evidence.
- [x] ≥1 AI Audit row appended (3 rows, Artifacts #1–3).
- [x] A commit exists per artifact (Step 3.1–3.6, verified via `git log`).

**Assumption validated:** the pipeline composes; the six contracts link; the three structural guards hold in practice; evidence + audit + commit-granularity all work.
**Risks impossible after this:** R1 (audit reconstruction), R2 (expected backfill — structurally blocked), R8/R9 (evidence medium), R11 (commit granularity), "contracts don't compose."
**Commit points:** per artifact — `Step 3.1 model` · `Step 3.2 frozen test case` · `Step 3.3 execution result` · `Step 3.4 bug report` · `Step 3.5 audit`.
**Stop conditions:** artifact chain cannot be linked → the pipeline/contract is broken; halt and fix before Step 4. GitHub posting blocked by unresolved Step 0 → proceed with local approved draft (documented); do not block.

---

## Step 4 — FR-04 full pilot, by hand, through the contracts (no skills)

**Goal:** produce the three real FR-04 deliverables through the frozen workflow. **This is the FR-04 end-to-end success milestone.**

**Prep**
- 4.0 Create `work/FR-04-personal-profile/` and confirm `out/reports/FR-04-personal-profile/{domain-testing,boundary-value-analysis,bug-reports/evidence}/` exist.

**Tasks (human gate between phases; commit per phase)**
- 4.1 **Phase 0 — Discovery (light, main):** map FR-04 to `PUT /api/users/me` + `GET /api/users/me` in `backend/server.js` and `frontend-web/src/pages/Profile.jsx`. Record the file map in the header of `work/FR-04-personal-profile/testing-model.md`. Gate: file map complete?
- 4.2 **Phase 1 — Build Test Model:** variables `name`, `phone`, `shipping_address`; **forbidden/immutable fields** `email` (not changeable) and `role` (SEC-06). For each: domain, boundaries + relation + `source` (phone: starts `0`, 10–11 digits → boundaries around 9/10/11/12, `source: spec`, plus any impl-derived boundary tagged `source: impl`), validation, oracle, metadata, confidence. Log gaps (e.g. `name` max length — spec silent) as Assumptions in `work/FR-04-personal-profile/assumptions.md`. Gate: `completeness_confirmed` (HUMAN — forbidden fields present).
- 4.3 **Phase 2 — Domain Test Design (by hand):** EP cases → `out/reports/FR-04-personal-profile/domain-testing/report.md`; BVA cases (phone-length 9-point set, etc.) → `.../boundary-value-analysis/report.md`. Expected from spec/accepted-assumption only, `expected_source` cited; traceability model↔case. Decision-table gate: FR-04 has no combining conditions → skip and note why. **Freeze + commit test cases before execution.**
- 4.4 **Phase 3 — Execution (Model C) + Bug Reporting:** execute each frozen case via native Bash; record in `work/FR-04-personal-profile/execution-results.md` (ref case ids, actual, verdict, evidence; no `expected`); screenshots → `.../bug-reports/evidence/`. Reseed DB between re-runs if state matters. Human gate `FAIL → real bug?`; approved drafts → `out/reports/FR-04-personal-profile/bug-reports/report.md`; file GitHub issues if repo resolved.
- 4.5 Append AI Audit rows for every AI-generated artifact.
- 4.6 **AI Gap Analysis (§6.3):** record any case/bug the AI missed and *why* (prompt quality / tool limit / feature complexity) in the domain-testing report.

**File paths:** the three `out/reports/FR-04-personal-profile/*` files; `work/FR-04-personal-profile/*`; `[AI-02]` audit file.
**Exit criteria**
- [x] All three FR-04 report files populated.
- [x] Every expected cites `spec` or an `accepted` assumption (no `impl`/`actual` as source) —
  including the A4 case, where the original layer-specific claim was rejected and reframed
  rather than left as an unsupported assumption.
- [x] `git log` shows frozen cases committed before execution results (`ef84047` before
  `31d0df0`).
- [x] Forbidden-field cases present (`role` injection — `TC-04-EP-005`; `email` immutability —
  `TC-04-EP-006`).
- [x] Audit rows exist for all AI-generated artifacts (Artifacts #4–7, plus #8–10 for the two
  extracted skills).
- [x] Per-phase commits present (4.1, 4.2, 4.3, 4.4×2, 4.5, 4.6 — verified via `git log`).

**Assumption validated:** the method produces valid deliverables on the target feature; freeze-before-execute is enforceable and observable; the completeness gate catches negative space.
**Risks impossible after this:** R5 (model-completeness gate unexercised), FR-04 design risk, "freeze-before-execute is only a slogan."
**Commit points:** per phase — `Step 4.1 FR-04 discovery` · `Step 4.2 FR-04 model+assumptions` · `Step 4.3 FR-04 frozen test cases` · `Step 4.4 FR-04 execution+bugs`.
**Stop conditions:** a business rule is ambiguous with no spec and no safe assumption → halt for human decision. Suspected DB pollution (false bug) → reseed and re-run before reporting.

---

## Step 5 — Extract `domain-test-design` skill from FR-04

**Goal:** freeze the proven Phase-2 method into a reusable, decoupled skill.

**Tasks**
- 5.1 Write methodology notes from what actually worked in 4.2–4.3 (base: master-plan Part 5, Skill 4).
- 5.2 Run `generate-skill` on the notes → save `.claude/skills/domain-test-design/SKILL.md`.
- 5.3 Validate: run the skill on FR-04's testing model; confirm it reproduces EP/BVA tables **equivalent** to the hand-written report. Do **not** overwrite the deliverable.
- 5.4 Coupling smell-test — grep the skill for: `FR-0`, `EShop`, `server.js`, `localhost`, `out/reports`, `README.md`, `api_specification`, `Phase 1|2|3`, `points`, `HW02`. Zero hits required.

**File paths:** `.claude/skills/domain-test-design/SKILL.md`
**Exit criteria:** reproduces FR-04 tables equivalently; smell-test = 0 hits; format matches `generate-skill` (Reasoning blocks on judgment steps, one line for plain actions, simple words).
**Assumption validated:** the capability abstraction is correct and repo-agnostic.
**Risks impossible after this:** R10 (wrong abstraction) for test design.
**Commit:** yes — `Step 5: extract domain-test-design skill`.
**Stop condition:** skill cannot reproduce FR-04 without embedding HW02 specifics → fix the notes and regenerate; never hand-patch the generated file.

---

## Step 6 — Extract `bug-reporting` skill from FR-04

**Goal:** same as Step 5, for the Phase-3 reasoning half.

**Tasks**
- 6.1 Write notes from 4.4 (base: master-plan Part 5, Skill 5).
- 6.2 Run `generate-skill` → save `.claude/skills/bug-reporting/SKILL.md`.
- 6.3 Validate against FR-04's bug reports (equivalent output).
- 6.4 Run the coupling smell-test (0 hits).

**File paths:** `.claude/skills/bug-reporting/SKILL.md`
**Exit criteria:** reproduces FR-04 bug reports equivalently; smell-test = 0 hits; correct format.
**Assumption validated:** the second reusable seam.
**Risks impossible after this:** R10 for bug reporting.
**Commit:** yes — `Step 6: extract bug-reporting skill`.
**Stop condition:** same as Step 5.

---

## Continuation (post-pilot — not part of the frozen 0–6 core)

> **Baseline: `43defbc` — Steps 0–6 tagged Core Complete (2026-07-04).** From this commit
> forward: do not retroactively edit Steps 0–6 artifacts (testing models, test cases,
> execution results, bug reports, the two `SKILL.md` files, the audit rows already logged)
> unless a genuine defect in them is found — not for further polish or generalization. Any
> new improvement discovered during Continuation belongs to Continuation's own artifacts, not
> backported into the baseline. Continuation work applies the two frozen skills as a user of
> the framework, not as a continued tuning exercise on the framework itself.

After Step 6 the pipeline, contracts, and both skills are validated. Then, reusing the skills:
1. ~~FR-08 full (through skills; reuse the Step-3 smoke case).~~
   **Done, 2026-07-04.** Extended the model (auth-state, cart-clearing) via `domain-test-design`
   Stage 1-2, human-approved; designed 3 EP cases (Stage 3), frozen and committed before
   execution; executed via Model C against the live SUT; confirmed 1 new defect via
   `bug-reporting` (`BUG-08-002` cart not cleared), approved and promoted alongside
   `BUG-08-001` (2 total for FR-08). Both filed as GitHub issues #1-#2 (Issues enabled +
   `gh` authenticated, same day). **No Decision Table** — none of FR-08's variables have
   combining conditions (Stage 5 skipped, same shape as FR-04). See `work/FR-08-checkout/*`
   and the AI Audit (`[AI-02]`, Artifacts #11-14 + correction entry) for full detail.
   **Correction, same day:** this work originally also included FR-09 (customer-facing coupon
   application, 5 conditions + a 7-row Decision Table + 3 bugs) — the student caught that FR-09
   is not one of the 4 assigned features (`docs/hw2-reqs/features-that-need-testing.md`: FR-04,
   FR-08, FR-15, FR-17; the assigned coupon feature is FR-17, a different admin-CRUD feature).
   That content was removed from FR-08's deliverables; GitHub issues #3-#5 (already filed for
   the 3 removed bugs) are left open on GitHub as real findings, just outside graded scope.
2. FR-15, then FR-17 (through skills). **Not started.**
3. Globals: `out/README.md` self-assessment + test summary; `out/ai-critique.md` (from logged corrections); finalize `[AI-02]/[AI-03]/[AI-05]`; `git log --oneline > out/git_commit_log.txt`; record one end-to-end skill demo video (§7). **Not started.**

---

## Global stop conditions (override the plan)

- A required authoritative input is missing and cannot be inferred → stop and ask.
- Business logic or user-facing behavior is ambiguous → stop and get a human decision.
- A step would introduce a new module/architecture layer beyond the folders defined here → confirm first.
- A mid-task fork changes the methodology for remaining steps → stop and reconcile.
- Suspected oracle-doc conflict beyond the precedence rule → log as Assumption + human review.

---

## Status

| Step | State |
|---|---|
| 0 Blockers | [x] |
| 1 Execution viability | [x] |
| 2 Oracle precedence | [x] |
| 3 FR-08 smoke | [x] |
| 4 FR-04 pilot | [x] |
| 5 domain-test-design skill | [x] |
| 6 bug-reporting skill | [x] |

## > NEXT ACTION

**Steps 0–6 tagged Core Complete at `43defbc` (2026-07-04).** Confirmed by human review:
baseline is consistent across plan/artifacts/git history, all exit criteria carry evidence,
both skills are extracted/validated/smell-tested through two review rounds, and all three
Human Gates + structural guards are demonstrated by real execution — not just asserted.

**Paused here by explicit request** — Continuation has not started yet in this session. When
resumed, the first Continuation task is: **FR-08 full**, driven through the two frozen skills
(`domain-test-design`, `bug-reporting`) as a user of the framework, not as further tuning of
it (stresses the decision-table path via FR-09's 5 combined coupon conditions). See the
"Continuation" section above for the baseline-protection rule that applies from here on.
