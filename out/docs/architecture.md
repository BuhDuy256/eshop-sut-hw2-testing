# architecture.md — Authoritative Architecture

> **Status:** Authoritative source of truth for the architecture of this project.
> **Scope:** Stable architectural decisions only. This document contains no implementation
> tasks and no project progress. For the implementation sequence, see `implementation_plan.md`;
> for orientation and file map, see the project `CLAUDE.md`.
> **Reading rule:** where a detail has not yet been confirmed by running the first pilot
> feature, it is marked **_Pending empirical validation_**. Such details are the current
> intent, not a final commitment.

---

## 1. System Overview

### 1.1 What this project is

An **AI-assisted software testing workflow**: a repeatable method in which an AI agent
performs the mechanical and analytical work of testing a System Under Test (SUT), while a
human owns judgment and accountability. The workflow applies classical black-/grey-box
testing techniques (Equivalence Partitioning, Boundary Value Analysis, and Decision Tables
where rules combine) to discover where the SUT's behavior diverges from its specification.

Key terms used throughout:
- **SUT** — the System Under Test. It is never modified by this workflow.
- **Oracle** — the source that decides what *correct* behavior is (the specification).
- **Model** — the description of what the SUT *does* / what must be *tested*.
- **Gate** — a decision point with a checkable condition that routes the workflow.
- **Contract** — the stable conceptual interface (an artifact) passed between capabilities.

### 1.2 Project goals

1. Apply testing techniques rigorously and produce reviewable evidence of divergence (bugs).
2. Do so through a **disciplined, step-guided** use of AI — not a single opaque prompt.
3. Capture the method as **reusable capabilities** so it can be applied to further features.

### 1.3 AI-first philosophy

AI-first means the AI is guided through *every step* of a testing technique as a disciplined
assistant, not asked to "find bugs" as a black box. The AI generates, executes, and
interprets; the value comes from the structure imposed on that work, not from autonomy.

### 1.4 Human-in-the-Loop philosophy

The human's role is **review and decision**, not mechanical execution. Human attention is a
scarce resource and is spent only where judgment is irreducible:
- deciding whether a model is complete,
- deciding whether an observed divergence is a real defect,
- approving what gets reported.

Human-in-the-Loop lives at **decision gates**, never at request-sending or data transcription.

---

## 2. Core Principles

### 2.1 MODEL ≠ ORACLE

The description of what the code *does* (the Model) and the definition of what is *correct*
(the Oracle) are separate at all times. Expected results are derived only from the
specification (or from an accepted assumption) — **never** from source code or from observed
output. Reading code is legitimate for building the Model (finding *where* to test); it is
never a source of correctness. This principle is enforced structurally (see §4.4 and §7.1).

### 2.2 Design-by-Contract

Each phase is treated like a function with a **precondition** (required inputs), a body
(AI activities and internal gates), a **postcondition** (exit criteria), and outputs. A
phase may not be entered until its preconditions hold, and may not be exited until its exit
criteria hold. Gates are assertions on this contract.

### 2.3 Decision-driven workflow

The workflow is a **decision system, not a linear pipeline**. Each phase is defined by the
*condition that allows moving to the next phase*, not by "what the AI does." A phase's exit
is a routing point evaluated against a checkable predicate. A predicate that cannot be
checked is not a gate (see §5).

### 2.4 Capability-based Skills

Reusable skills are named and scoped by **capability** (a reusable way of reasoning), never
by phase or by anything specific to one SUT or assignment. A skill must be runnable, in
principle, against a different repository or a different course task without edits (see §6).

### 2.5 Example-first development

Reusable abstractions are **extracted from a working example**, not designed up front. The
method is proven by hand on one feature before it is frozen into a skill. Templates and
tooling are instantiated from a real run, not pre-built speculatively.

### 2.6 Deliverable-first implementation

Effort is spent producing real, reviewable output before it is spent on generalization.
Where reusable architecture and concrete output conflict, the concrete output comes first;
generalization follows only after the method has been validated on one feature.

---

## 3. System Architecture

### 3.1 The four phases

The workflow has four phases plus a cross-cutting learning record. Each phase is stated as a
Design-by-Contract unit (precondition → activities/gates → exit criterion → output).

**Phase 0 — Feature Discovery**
- *Precondition:* a feature identifier and access to the repository.
- *Activities:* locate every file/route/handler the feature touches; classify by layer.
- *Exit criterion:* the feature is fully mapped (no touched file omitted).
- *Output:* a feature map.

**Phase 1 — Requirement Augmentation (Model Construction)**
- *Precondition:* the feature map, the specification, source-code access.
- *Activities:* build the **Testing Model** = specification **combined with** implementation
  detail. For each variable: domain, boundaries (each tagged with provenance —
  spec / impl / external), validation rule, and oracle. Surface forbidden/immutable fields
  (negative space). Record gaps as Assumptions.
- *Exit criterion:* every variable carries domain + boundary(+source) + validation +
  oracle-or-accepted-assumption; completeness confirmed by a human.
- *Output:* Testing Model + Assumptions.
- *Note:* boundaries are the **union of spec-derived and code-derived** sources. Code-only
  boundaries miss "the code forgot to handle X" defects; spec-only boundaries miss
  branch-specific edges. Both are required.

**Phase 2 — Domain Test Design**
- *Precondition:* a Testing Model.
- *Activities:* Equivalence Partitioning and Boundary Value Analysis for every variable;
  a Decision Table **only where conditions combine**. Expected results drawn from the oracle
  only, and **frozen**.
- *Exit criterion:* every test case has inputs, steps, and an expected result citing a spec
  location or an accepted assumption; expected values are frozen; model↔case traceability
  exists.
- *Output:* Test Cases (+ coverage note + traceability).

**Phase 3 — Test Execution & Bug Reporting**
- *Precondition:* frozen Test Cases and a reachable SUT.
- *Activities:* execute each frozen case against the SUT (see §7.3), collect the actual
  behavior, compare to the frozen expected, confirm defects, and draft reports with evidence.
- *Exit criterion:* each executed case has a recorded actual and verdict; each confirmed
  defect has reproduction steps, evidence, and severity; a human has approved what is reported.
- *Output:* Execution Results + Bug Report Drafts + test summary.

**Learning Artifacts (cross-cutting, human-reviewed)**
- A record of assumptions made, effective prompts, and lessons — kept only insofar as it
  feeds reviewable output. There is **no automated learning engine**: no pattern mining, no
  self-updating rules or skills. All entries are human-reviewed. (See §8.)

### 3.2 Command vs Skill vs Execution vs SUT

Four kinds of thing, with strictly separate jobs:

| Element | Job | Knows about |
|---|---|---|
| **SUT** | The system being tested. Never modified. | Nothing about the workflow. |
| **Skill** | A reusable **reasoning** capability (HOW to think). | Only its own inputs/outputs and exit criteria. |
| **Command** | **Orchestration** glue. Sequences phases; holds all project-specific coupling. | Everything project-specific. |
| **Execution infrastructure** | The **means of firing requests and capturing responses**. Dumb: execute + collect only, no assertions. | Only how to reach the SUT. |

### 3.3 Responsibility boundaries

- A **Skill** contains no I/O, no orchestration, and no SUT- or assignment-specific nouns.
  It owns its own **exit criteria**. It never references "Phase 2" or any sequencing — doing
  so would couple it to this workflow and break reuse.
- The **Command** owns cross-phase **handoff gates**, the feature list, all file paths, the
  injection of project facts (e.g., the oracle-precedence rule), the wiring of execution, and
  the enforcement of audit and commit discipline. It is the only element allowed to be
  specific to this project.
- **Execution infrastructure** performs no judgment. Comparison of expected vs actual is a
  reasoning/human step, never encoded in the execution tool.
- No **subagents** are part of the architecture. (See §8.)

---

## 4. Artifact Contracts

Artifacts are the stable conceptual interfaces between capabilities. They are defined by
their meaning and required content, not by a serialization format. Consistent identity
references between artifacts form the traceability chain (§7.5).

### 4.1 The six artifacts

| Artifact | Purpose | Produced by | Consumed by | Kind |
|---|---|---|---|---|
| **Testing Model** | The Model — every input/output variable with domain, provenance-tagged boundaries, validation, oracle; plus forbidden fields | Phase 1 (model construction) | Domain Test Design | Internal |
| **Assumptions** | Decisions made where the spec is silent/ambiguous, so tests are defensible | Phase 1 | Domain Test Design, Bug Reporting | Internal |
| **Test Cases** | Designed cases binding a partition/boundary to concrete input + a frozen, oracle-sourced expected | Domain Test Design | Execution, Bug Reporting | Deliverable |
| **Execution Results** | The observed actual + verdict for one frozen case (references the case; carries no expected of its own) | Execution (Command) | Bug Reporting, test summary | Internal |
| **Bug Report Draft** | A confirmed defect with evidence, pending human approval to file | Bug Reporting | Command (files/records it) | Deliverable |
| **AI Audit Entry** | One record per AI-generated artifact: verbatim prompt + output + verdict + human fix | Every capability, at artifact creation | Audit/critique/disclosure | Deliverable |

### 4.2 Metadata

Testing Model items and Assumptions carry `{ source, confidence, status }`:
- `source ∈ { spec, impl, external }`
- `confidence ∈ { HIGH, MED, LOW }`
- `status ∈ { proposed, accepted, rejected }` (a single lifecycle field; "proposed" implies
  not-yet-reviewed).

### 4.3 Lifecycle

- **Testing Model / Assumptions:** proposed → (human review) → accepted / rejected. Only an
  **accepted** assumption may serve as an oracle source for a Test Case.
- **Test Cases:** draft → **frozen** (expected becomes immutable at Phase-2 exit).
- **Execution Results:** created at execution; verdict confirmed by human for failures.
- **Bug Report Draft:** draft → approved → filed.
- **AI Audit Entry:** appended at the moment its artifact is created; its verdict and human
  fix are themselves the human-review record.

### 4.4 Structural guards (how the invariant is made unbreakable)

Three shape decisions make MODEL ≠ ORACLE structurally enforced rather than merely intended:

1. **`Test Case.expected_source ∈ { spec, assumption }`** — the enum has no `impl`/`actual`
   value, so expected cannot be sourced from code or output.
2. **`Execution Result` has no `expected` field** — the verdict is computed against the
   referenced frozen Test Case; there is nowhere to backfill an expected value after seeing
   the actual.
3. **An assumption may be cited as an oracle only when `accepted`** — no test may rest on an
   unreviewed guess.

---

## 5. Decision Gates

### 5.1 Gate shape

Every gate has the form **Evidence → Predicate → Decision → Action**. A gate's predicate
must be **checkable**; a condition that cannot be evaluated is not a gate. Evidence is a
pointer to already-existing material (a spec location, a code location, a captured response,
a screenshot), not a new artifact to manufacture; its weight scales with the gate type.

### 5.2 Gate types

- **AUTO** — the predicate is mechanically decidable; no human time is spent
  (e.g., "does every expected result cite a spec location?").
- **HUMAN** — the judgment is irreducible; a human always decides
  (e.g., "is this divergence a real defect, or a test/setup error?").
- **HYBRID** — the AI proposes a decision with a confidence value, and **routing depends on a
  threshold**: at or above the threshold the decision auto-accepts; below it, the decision
  escalates to a human. Without a threshold that changes routing, a gate is HUMAN, not HYBRID.

This AUTO / HUMAN split is the same principle as judgment-vs-plain-action in skill authoring,
raised to the workflow level: judgment points are explicit questions; mechanical points are
one-liners.

### 5.3 Gate legitimacy

A gate is worth drawing only if it **changes the downstream action** — concretely, only if at
least two features would take different branches through it. A gate with one outcome is a
comment (always-true) or a dead node (always-false), not a gate.

### 5.4 Gate ownership and exit criteria

- **Exit-criteria gates** describe a capability's *own* output being complete. They live in
  the Skill (`SKILL.md`).
- **Handoff / loop gates** describe *sequencing* between phases. They live in the Command.
- A Skill that references a phase boundary has been re-coupled and is no longer reusable.

Exit criteria are the terminal gate of a phase — the postcondition of its Design-by-Contract
unit. The Command reads a skill's exit criteria to decide handoff.

### 5.5 Pending validation

Which gates actually fire, the real instances of HYBRID gates, and any threshold values are
**_Pending empirical validation_**. The current intent: the decision-table gate is a real
gate (some features need it, others do not); the state-machine gate is a dead node for the
current feature set; HYBRID is expected to have at most one home (admitting Phase-1 model
items by confidence). None of these are confirmed until the first pilot runs.

---

## 6. Skill Architecture

### 6.1 Capability decomposition

The reusable capabilities (input-agnostic, reasoning-only):

| Capability | Reasoning it owns | Status |
|---|---|---|
| **build-test-model** | Construct a Testing Model from spec + code (provenance-tagged), with assumptions and forbidden fields | May begin merged into the front of `domain-test-design`; split only when a real case proves the seam — **_Pending empirical validation_** |
| **domain-test-design** | EP + BVA (+ Decision Table when conditions combine) from a Testing Model, with frozen oracle-sourced expected | Core |
| **bug-reporting** | Turn executed results + evidence into confirmed, classified, evidenced defect write-ups | Core |
| **generate-skill** | Produce other skills in the standard format | Meta (owner of the skill authoring format) |
| **feature-discovery** | Map a feature in an arbitrary repository | Deferred to a future skill (see §8) |

### 6.2 Skill boundaries

- A skill takes abstract inputs (a "spec," a "feature identifier," a "testing model,"
  "executed results") — never named project files, endpoints, or feature IDs.
- A skill owns its exit criteria; it does not know the phase order it participates in.
- Skills follow the authoring format defined by `generate-skill`: judgment steps carry a
  Reasoning block written as open questions; plain actions are one line; simple words;
  an Authoritative-Inputs table; and (per the frozen skill structure) typed **Gates** and
  **Exit Criteria**.

### 6.3 The coupling smell-test

Before a `SKILL.md` is accepted, it is scanned for project-specific nouns (feature IDs, the
SUT name, source filenames, host/URLs, deliverable paths, spec filenames, phase numbers,
grading terms, the assignment name). **Any hit is a coupling leak** and must move to a skill
input or to the Command. This is a mechanical, decidable check and belongs in each skill's
own acceptance checklist.

### 6.4 Command responsibilities

The Command is the only project-specific element. It: sequences the four phases; owns the
cross-phase handoff gates; supplies every project fact the skills consume (feature list,
paths, oracle-precedence rule, execution wiring); and enforces audit-entry and commit
discipline at phase boundaries. A different assignment reuses the same skills behind a
different Command.

---

## 7. Architectural Invariants

These hold in every phase and are not subject to local trade-offs.

### 7.1 MODEL ≠ ORACLE
Expected results come only from the spec or an accepted assumption. Enforced by the three
structural guards in §4.4.

### 7.2 Oracle precedence
When specification sources conflict, the **behavioral specification is authoritative** and a
**interface/shape specification is not** authoritative for behavior. An external reference is
consulted **only** after a conflict is confirmed, and any such use is recorded in the audit.
(The concrete mapping of which project file plays which role is a project fact injected by the
Command, not part of this architecture.)

### 7.3 Execution model (Model C)
The agent executes cases against the SUT using its native execution tool, and collects raw
responses. The execution tool performs **execute + collect only** — no assertions. The
comparison of expected vs actual is a reasoning step reviewed by a human at a decision gate.
Building a bespoke test-runner or assertion framework is outside the architecture.
*(This model assumes an agent runtime with a native execution tool; in an environment without
one, the equivalent is a human-assisted send with the AI analysing the response. The choice is
recorded so it is defensible.)*

### 7.4 Frozen expected before execution
A case's expected result is frozen at Phase-2 exit and committed **before** any Execution
Result is produced. The commit order is the durable proof; an expected value is never edited
after an actual is observed.

### 7.5 Traceability
Artifacts reference each other by identity, forming the chain
`Testing Model variable → Test Case → Execution Result → Bug Report Draft`, with
`AI Audit Entry → the artifact it produced`. Any requirement↔case↔defect traceability view is
a projection of these references, not a separately maintained document.

### 7.6 Audit
Every AI-generated artifact has a corresponding AI Audit Entry, appended at the moment the
artifact is created (never reconstructed afterward). The entry carries the verbatim prompt,
verbatim output, a verdict, and the human's correction.

---

## 8. Deferred Decisions

Intentionally postponed. These are **not** part of the current architecture and must not be
built until their trigger is met. Several are gated on validation by the first pilot feature.

- **feature-discovery as a reusable skill.** Deferred until a second repository exists to test
  its generality; building it from a single repository would overfit. Until then, discovery is
  a Command-orchestrated step, not a skill.
- **Learning engine.** Pattern mining, automated rule refinement, self-updating skills, and any
  approval-looped knowledge base are deferred. Only human-reviewed learning *artifacts* are in
  scope now.
- **Subagents.** Cut on the grounds that the current SUT is small enough to analyse in the main
  context. Reconsidered only for a genuinely large SUT.
- **Splitting `build-test-model` from `domain-test-design`.** The two may begin merged; the
  split happens only when a concrete case demonstrates the seam is needed —
  **_Pending empirical validation_**.
- **Exact gate predicates, HYBRID instances, and threshold values.** The intended gates are
  described in §5; whether each fires as designed, and any thresholds, are
  **_Pending empirical validation_** by the first pilot feature.
- **Sufficiency of the artifact contract fields.** The required/optional fields in §4 reflect
  current intent; whether they are complete in practice is **_Pending empirical validation_**.

The reconciliation of any item marked *Pending empirical validation* happens after the first
pilot feature has been run end-to-end; this document is then corrected to match observed
reality.

---

## 9. Documentation Ownership

One owner per kind of information; every other document references the owner rather than
restating it. An allowed exception: a document may hold a *labeled derived view* of owned
content, provided it states that the owner wins on any conflict.

| Information | Owner | Referencers (do not restate) |
|---|---|---|
| Workflow shape, phase definitions, decision gates | **architecture.md** | workflow diagram, `implementation_plan.md`, `CLAUDE.md` |
| Design-by-Contract structure | **architecture.md** | `generate-skill` |
| Invariants (MODEL≠ORACLE, oracle precedence, frozen-expected, execution model, audit, traceability) | **architecture.md** | `implementation_plan.md` (as a labeled operational checklist) |
| Artifact contracts + structural guards | **architecture.md** | `implementation_plan.md`, `generate-skill` |
| Skill decomposition and boundaries | **architecture.md** | `CLAUDE.md` |
| Implementation sequence, status, folder layout | **implementation_plan.md** | `CLAUDE.md` |
| Skill authoring format (gates, exit criteria, smell-test) | **generate-skill/SKILL.md** | **architecture.md** |
| Project orientation (features, deliverables, run instructions) and the source-of-truth index | **CLAUDE.md** | — |
| Visual depiction of the workflow | the workflow diagram | (a view of architecture.md; owns nothing normative) |

Specifications of the SUT (behavioral and interface) are **inputs / oracle**, owned by the SUT,
and are never edited by this workflow.

---

*This document consolidates previously frozen decisions only. It introduces no new
architecture. Items marked **_Pending empirical validation_** are current intent to be
confirmed or corrected after the first pilot feature runs end-to-end.*
