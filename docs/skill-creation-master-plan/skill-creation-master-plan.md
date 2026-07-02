# MASTER-PLAN.md — HW02 AI Testing Agent

> **Purpose:** Both a plan (for the human) and a resume point (for Claude). When the human
> says "build the next one," Claude reads **Next Action**, does it, then updates **Status**
> and **Next Action**. No context switch needed.

---

## Part 1 — Project Snapshot

- **Course:** Software Testing — HW02 Domain Testing & BVA
- **SUT:** EShop (Vietnamese e-commerce, has intentional bugs)
- **Features to test:** FR-04 (Profile), FR-08 (Checkout), FR-15 (Product CRUD),
  FR-17 (Coupon CRUD). *(FR-09 Discount coupons — pending scope confirmation.)*
- **Goal:** Build a **reusable** Claude skill system that runs the 4-phase testing
  workflow, then use it to produce the HW02 deliverables.

**Core constraints (apply everywhere):**
1. MODEL != ORACLE — never derive Expected Results from implementation code.
2. External Reference — used only when conflict is confirmed.
3. Human review is mandatory at every phase.
4. No knowledge-base update without human approval.
5. All AI usage recorded in AI Audit Report.
6. All skills use the same format (from `generate-skilfl`): simple words, Reasoning blocks
   on judgment steps, one line for plain-action steps.

---

## Part 2 — Architecture Principle (read before building anything)

The three mechanisms have **separate jobs**. Do not mix them up.

| Mechanism | Job | Named after |
|-----------|-----|-------------|
| **Skill** | HOW — a reusable method for one capability | the **capability** (not the phase) |
| **Subagent** | WHERE — runs a heavy task in its own fresh context, returns a short summary | the **specialist role** |
| **Command** | GLUE — mixes skills/agents into one workflow for a project | the **project task** |

**Key rules:**
- `skills/` holds **atomic, reusable** capabilities. A skill must work on any repo/spec,
  not just HW02. So skills are named by capability (`spec-recovery`), never by phase
  (`phase-1`).
- `agents/` holds **subagents**. Use a subagent when a step reads or produces **a lot of
  data** (source code, test logs) — so that data stays in the subagent's own context and
  does not bloat the main session. Also use it when **fresh eyes beat session memory**.
- `commands/` holds the **orchestrator**. This is the only place tied to HW02. It calls
  skills and spawns subagents in order.

**Main vs subagent — decision test:**
```
Use a subagent when:
  -> the step reads/produces a lot of data (whole source files, logs)
  -> you don't want that data in the main context
  -> fresh, unbiased analysis is better than remembering the chat

Run in main when:
  -> input and output are already small
  -> the step needs to stay connected to earlier steps
```

---

## Part 3 — The 4-Phase Workflow, mapped to mechanisms

```
Phase 0: Feature Discovery
  -> runs in MAIN (light: just lists files, routes, deps)
  -> skill: feature-discovery

Phase 1: SRE (recover requirements + compare with spec)
  -> runs in SUBAGENT (reads a lot of source code -> own context, fresh eyes)
  -> agent: sre-analyst  ->  loads skills: spec-recovery + conformance-analysis

Phase 2: Domain Test Design (EP + BVA)
  -> runs in MAIN (input is already small: recovered requirements)
  -> skill: domain-test-design

Phase 3: Test Execution & Bug Reporting
  -> runs in SUBAGENT (runs tests, reads lots of output -> own context)
  -> agent: test-executor  ->  loads skill: bug-reporting
  -> (API execution inside the agent; UI tests manual or Playwright)

Phase 4: Human-Approved Learning (controlled, not self-learning)
  -> updates /knowledge/*.md, only with human approval
```

Reference diagram: `ai-testing-workflow.html`

---

## Part 4 — Build Inventory

Status: [DONE] · [WIP] · [ ]

### skills/ (reusable capabilities)

| # | Path | Capability | Status |
|---|------|-----------|--------|
| 0 | `.claude/skills/generate-skill/SKILL.md` | Generate other skills | [DONE] |
| 1 | `.claude/skills/feature-discovery/SKILL.md` | Map a feature in any repo | [ ] |
| 2 | `.claude/skills/spec-recovery/SKILL.md` | Recover requirements from code | [ ] |
| 3 | `.claude/skills/conformance-analysis/SKILL.md` | Compare impl vs spec -> conflicts | [ ] |
| 4 | `.claude/skills/domain-test-design/SKILL.md` | EP + BVA test design from a spec | [ ] |
| 5 | `.claude/skills/bug-reporting/SKILL.md` | Write bug reports from test results | [ ] |

### agents/ (subagents, own context)

| # | Path | Role | Loads skills | Status |
|---|------|------|--------------|--------|
| 6 | `.claude/agents/sre-analyst.md` | Read code, recover + compare, return summary | 2, 3 | [ ] |
| 7 | `.claude/agents/test-executor.md` | Run tests, collect evidence, report bugs | 5 | [ ] |

### commands/ (orchestrator, HW02-specific)

| # | Path | Job | Status |
|---|------|-----|--------|
| 8 | `.claude/commands/test-feature.md` | Run Phase 0->1->2->3 for one FR, pause for review between phases | [ ] |

### config + data

| # | Path | Job | Status |
|---|------|-----|--------|
| 9 | `CLAUDE.md` | Workflow entry, constraints, KB refs, triggers | [ ] |
| 10 | `/knowledge/*.md` (5 files) | Knowledge base scaffolds | [ ] |

Each skill below has **methodology notes inline** — enough to feed `generate-skill`
directly. To build one: read its notes -> run `generate-skill` on them -> save to its path.

---

## Part 5 — Skill Methodology Notes

### Skill 1 — feature-discovery

**Task type:** Feature Discovery · **Methodology:** Layer-guided static mapping
**Input:** feature id + repository. **Output:** dependency graph, file list, entry points,
layer map. **Runs in:** main.

**Phases (notes):**
- **Locate.** Find every file that touches this feature. *Judgment:* which routes /
  handlers / components belong to it vs. unrelated code sharing the same file?
- **Map layers.** Classify each touched piece into the 7 layers: Data/Schema, Business
  Logic, Authorization, State Machine, Interface Contract (API), Frontend Validation,
  Calculation/Formula. *Judgment:* which layers does this feature actually hit? (skip the
  rest).
- **Build dependency graph.** Trace call order: route -> middleware -> handler -> DB ->
  shared utils. *Judgment:* what runs before the handler (auth, parsing)? what shared
  logic is reused?
- **Output.** dependency graph + file list + entry points + layer map.

---

### Skill 2 — spec-recovery

**Task type:** Specification Recovery · **Methodology:** Reverse engineering (code ->
requirements)
**Input:** dependency graph + source code. **Output:** recovered requirements, input
domains, business rules, validation rules, state rules — each tagged `[IMPL]`.
**Runs in:** subagent (sre-analyst).

**Phases (notes):**
- **Read behavior.** For each file, extract "when X then Y" statements. *Judgment:* is
  this line validation, authorization, calculation, or state? *Ignore:* logging, try/catch,
  formatting.
- **Recover.** Turn behavior into recovered requirements + input domains + business rules
  + validation rules + state rules. Tag `[IMPL]`.
- **Confidence.** Score each item HIGH/MED/LOW (HIGH = clear 1:1, MED = needs inference,
  LOW = ambiguous / unverified branch).

**Reasoning focus:** this recovers what the code *does*. It never says what the code
*should* do — that is the spec's job (next skill).

---

### Skill 3 — conformance-analysis

**Task type:** Conformance Analysis · **Methodology:** Spec-vs-impl comparison
**Input:** recovered requirements (`[IMPL]`) + spec. **Output:** conflict report + bug
candidates. **Runs in:** subagent (sre-analyst, right after spec-recovery).

**Phases (notes):**
- **Compare.** For each recovered item, compare to spec. Classify: MATCH / DIVERGE /
  MISSING / EXTRA. *Judgment:* does code match what spec says?
- **Classify conflicts.** For each DIVERGE/MISSING/EXTRA: Likely Impl Bug / Likely Spec
  Bug / Both Wrong / Need Human Review. *Judgment:* which side is wrong? External Reference
  lookup ONLY here, only if the conflict is confirmed.
- **Output bug candidates.** Each candidate: spec says X, impl does Y, risk level,
  confidence.

**Reasoning focus:** MODEL != ORACLE. Recovered = MODEL. Spec = ORACLE. Bug candidate = the
gap. Bug candidates are used only to *aim* tests later, never as the expected result.

---

### Skill 4 — domain-test-design

**Task type:** Domain Test Design · **Methodology:** EP + BVA + decision/state tables
**Input:** spec + recovered requirements + input domains + bug candidates. **Output:** EP
table, BVA table, decision table, state table, test cases, coverage report, traceability
matrix, assumptions log. **Runs in:** main.

**Phases (notes):**
- **Variables & gaps.** List input/output variables. Detect gaps (field with no spec
  rule) and surface them before proceeding. *Judgment:* is a rule missing, or just not
  applicable?
- **Equivalence classes.** Partition each variable into valid/invalid ECs. Split a class
  when behavior differs inside it. Label source `Spec` or `[inferred from code]`.
  *Judgment:* does behavior change for a sub-range? if yes, split.
- **Select test cases.** Valid ECs -> combine to maximize coverage. Invalid ECs -> one per
  test (isolate the failure). **Expected result from spec, not code.**
- **BVA.** For ordered ECs, generate the 9 points (Min UI, LB-1, LB, LB+1, Nominal, UB-1,
  UB, UB+1, Max UI). *Judgment:* is the boundary > or >= per spec?
- **Decision / state tables.** For rule-heavy features (coupon conditions, order states)
  build a decision table or state transition table.
- **Output + traceability.** test cases + coverage report + traceability (Req <-> TC) +
  assumptions log.

---

### Skill 5 — bug-reporting

**Task type:** Bug Reporting · **Methodology:** Evidence-based defect writing
**Input:** executed test results + evidence (logs, screenshots, DB state). **Output:**
confirmed bug list, Markdown bug reports, GitHub issue drafts, test summary. **Runs in:**
subagent (test-executor).

**Phases (notes):**
- **Confirm.** For each FAIL, confirm it reproduces. *Judgment:* real bug or test error /
  false positive?
- **Classify.** Severity + priority + root cause (if known). *Judgment:* how bad is the
  impact? (data loss / security > cosmetic).
- **Write.** Markdown bug report + GitHub issue draft (with screenshot placeholders),
  fixed format.
- **Summarize.** total / passed / failed / blocked / not-run + bug count by severity.

---

## Part 6 — Agent Notes

### Agent 6 — sre-analyst
- **Why a subagent:** reads the whole source of a feature -> keep that in its own context,
  keep main light. Fresh eyes, no bias from the planning chat.
- **Loads:** `spec-recovery` then `conformance-analysis`.
- **Input from main:** feature id + dependency graph (from Phase 0).
- **Returns to main:** short summary — recovered requirements + bug candidates + confidence.
- **Tools:** read-only (Read, Grep, Bash) — it analyzes, it does not edit.

### Agent 7 — test-executor
- **Why a subagent:** runs API tests and reads lots of responses/logs -> own context.
- **Loads:** `bug-reporting`.
- **Input from main:** test cases (from Phase 2) + running SUT address.
- **Returns to main:** short summary — pass/fail counts + confirmed bugs + report paths.
- **Note:** API execution inside the agent; UI tests manual or via Playwright.

---

## Part 7 — Command Notes

### Command 8 — /test-feature
- `/test-feature FR-04` runs one full feature:
  ```
  Phase 0  feature-discovery        (main)          -> human review
  Phase 1  spawn sre-analyst        (subagent)      -> human review
  Phase 2  domain-test-design       (main)          -> human review
  Phase 3  spawn test-executor      (subagent)      -> human review
  ```
- Pauses for human review between phases (constraint 3).
- This is the only HW02-specific piece. A different assignment reuses the same skills with
  a different command.

---

## Part 8 — Knowledge Base (item 10)

Scaffolds under `/knowledge/`:
- `assumptions.md` — proposed / accepted / rejected / pending
- `bug-patterns.md` — confirmed bugs, false positives, patterns, root causes
- `prompt-library.md` — effective prompts, anti-patterns, templates
- `test-patterns.md` — reusable boundary / validation / workflow patterns
- `lessons-learned.md` — what worked, what didn't, recommendations

**Rule:** no update without human approval.

---

## Part 9 — Decisions Log (do not re-litigate)

- **skills = capability-named, reusable.** Never named by phase. Must work on any repo.
- **commands = the only HW02-specific glue.** Reuse skills across assignments.
- **subagents for heavy-context phases (SRE, execution).** Keeps main context small;
  fresh eyes beat session memory.
- **SRE split into two skills** (spec-recovery + conformance-analysis) — Option B — so
  "recover requirements from code" is reusable on its own.
- **MODEL != ORACLE.** Recovered requirements decide what to test; spec decides what is
  correct; bug candidates only aim the tests.
- **Controlled learning, not self-learning.** KB is Markdown, updated only with approval.
- **Every skill same format** (via generate-skill). Judgment steps -> Reasoning blocks as
  open questions. Plain actions -> one line. Simple words.
- **HW deliverables != phase outputs.** Phase outputs are working artifacts; deliverables
  are the formatted files the grader reads.

---

## Part 10 — Build Order

```
1. feature-discovery       <- START HERE
2. spec-recovery
3. conformance-analysis
4. domain-test-design
5. bug-reporting
6. sre-analyst (agent)
7. test-executor (agent)
8. test-feature (command)
9. CLAUDE.md (updated)
10. /knowledge/*.md scaffolds
--- then run /test-feature FR-04 as the pilot ---
```

---

## > NEXT ACTION

**Build:** `.claude/skills/feature-discovery/SKILL.md`
**How:** read Skill 1 notes (Part 5) -> run `generate-skill` -> save to path.
**After done:** mark Skill 1 [DONE] in Part 4, set Next Action to Skill 2 (`spec-recovery`).
