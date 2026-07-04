# Methodology notes — `domain-test-design` (Step 5.1)

> Base: `docs/skill-creation-master-plan/skill-creation-master-plan.md` Part 5, Skill 4.
> Refined from what actually worked in Step 3 (FR-08 smoke) and Step 4 (FR-04 full pilot).
> This is an **existing spec** input for `generate-skill` (Step 2B path) — it describes steps
> and logic; `generate-skill` maps it into the standard SKILL.md structure, adding Reasoning
> blocks for judgment steps.
>
> Per architecture.md §6.1, `build-test-model` is currently merged into the front of this
> skill (not split out) — these notes cover both model construction and EP/BVA design as one
> flow, since that is what Step 4 actually did as one continuous pass.

## Task type

Domain Test Design (Testing Model construction + Equivalence Partitioning + Boundary Value
Analysis + Decision Table when needed), producing frozen, oracle-sourced test cases.

## Methodology

Spec-and-code-derived variable modeling → equivalence partitioning → boundary value analysis
→ (decision table only if conditions combine) → freeze with traceability.

## Phase A — Model each variable

For each input/output variable relevant to the feature:
- List Domain, Boundary + relation, Source (`spec`/`impl`/`external`), Validation rule,
  Oracle, Metadata `{source, confidence, status}`.
- **Judgment:** is a stated boundary complete on its own, or does the implementation reveal a
  second, possibly conflicting boundary (e.g. a client-side check that differs from what the
  spec defines as valid)? Both must be recorded — reading code to find a boundary is
  legitimate; using the code's behavior as the *expected* value is not (Model ≠ Oracle).
- **Judgment:** does the variable have a forbidden state (something the actor must never be
  able to set, e.g. an elevated permission) or an immutable state (something that must never
  change through this path)? If yes, record it explicitly — it becomes its own negative test
  case later, not a footnote.
- Plain action: log every gap (no spec rule, no code constraint) as an Assumption with
  `{source, confidence, status: proposed}`.

## Phase B — Assumption defensibility check (before any assumption becomes an oracle)

**This is the most important lesson from this pilot; it prevents an oracle from being
quietly invented.**

- **Judgment — for every Assumption that would serve as a Test Case's oracle:**
  → Can this assumption be pointed at an actual line in the spec, or a documented
    architectural rule? Not "it seems reasonable" — an actual citation.
  → If it names a specific responsible layer or component (e.g. "the backend must enforce
    X"), is that layer named *anywhere* in the spec/architecture, the way a comparable rule
    elsewhere in the same spec might name one? Contrast with a rule that never names any
    layer at all.
  → If no such citation exists: **can the oracle be reframed as an outcome, stated
    path-agnostically, using only what the spec already defines** (e.g. "a value the spec
    calls invalid must never end up in the persisted/observable end state, regardless of
    which part of the system was supposed to catch it") **instead of asserting which layer
    is responsible?** A reframed, outcome-based oracle usually needs no assumption at all,
    because it only restates a definition the spec already gives.
  → Only if no defensible reframing exists should the assumption stand as-is, and only after
    an explicit accept/reject decision at the completeness gate — never silently kept.
  - Ignore: the temptation to keep the original, layer-specific wording just because it is
    already written down. A citation-free convenience claim does not become defensible by
    being reused.

## Phase C — Equivalence Partitioning

- Partition each variable into valid/invalid classes. Split a class further only when
  behavior genuinely differs inside it.
- **Judgment:** for an invalid class, is the expected outcome actually determinable from the
  oracle (spec or an accepted assumption / reframed outcome from Phase B), or does testing it
  require guessing an error contract the spec never specifies? If the latter, state the
  expectation at the level the spec actually supports (e.g. "the invalid value must not end
  up persisted" rather than inventing a specific error message/status code).
- One case per invalid class (isolate the failure); valid classes may combine into fewer
  cases that jointly cover them.
- Explicitly design one negative case for every forbidden field and one for every immutable
  field found in Phase A.

## Phase D — Boundary Value Analysis

- For each variable with a spec-stated ordered/numeric boundary, generate the boundary points
  (below-min, min, max, above-max at minimum; add points for any second, orthogonal boundary
  condition the spec states, e.g. a required leading value distinct from length).
- **Judgment:** is the spec's boundary inclusive or exclusive (`>` vs `>=`)? Check the exact
  wording rather than assuming a convention.
- **Judgment — multi-path recognition:** does the feature have more than one reachable entry
  point that could independently satisfy or violate the same oracle (e.g. a
  client-side-enforced path and a directly-callable path)? If yes, design the same boundary
  values as separate cases per path — this is what turns a "the two layers might disagree"
  observation into falsifiable, separately verifiable cases, instead of one case that hides
  which path was actually exercised.

## Phase E — Decision Table gate

- Plain action: check whether two or more conditions must hold jointly to change the
  outcome (per architecture's gate-legitimacy rule — a table is only worth drawing if it
  changes the downstream action for at least two combinations).
- If no combining conditions exist: skip the table and record why in one line. Do not build a
  table "for completeness" when every condition is independent.

## Phase F — Freeze and traceability

- Plain action: for every case, record `expected_source` as `spec` (with citation) or
  `assumption: <id>` (only if `accepted`) — never `impl`/`actual`.
- Plain action: link every case back to the Testing Model variable it came from.
- Plain action: mark `status: frozen` and commit before any execution happens.

## Authoritative inputs

| Input | Authoritative for | NOT authoritative for |
|---|---|---|
| The specification | Business rules, validation rules, what is valid/invalid, who owns what data | Where in the code a rule is enforced, or whether it is enforced at all |
| The source code | Where a variable is read/written, what boundaries the current implementation actually checks, whether two enforcement points agree | What the *correct* behavior should be (never the oracle) |
| An assumption | A defensible stand-in for a spec gap, once explicitly accepted | Anything that could instead be reframed as a direct, path-agnostic reading of the spec (see Phase B) |
