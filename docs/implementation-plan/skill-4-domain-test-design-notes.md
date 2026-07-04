# Methodology notes — `domain-test-design` (Step 5.1, revised after human review)

> Base: `docs/skill-creation-master-plan/skill-creation-master-plan.md` Part 5, Skill 4.
> Refined from what actually worked in Step 3 (FR-08 smoke) and Step 4 (FR-04 full pilot),
> then generalized further after a human review pass on the generated skill (this revision).
> This is an **existing spec** input for `generate-skill` (Step 2B path) — kept in sync with
> `.claude/skills/domain-test-design/SKILL.md` so the file could be reproduced from these
> notes alone.
>
> Per architecture.md §6.1, `build-test-model` is currently merged into the front of this
> skill (not split out) — these notes cover both model construction and EP/BVA design as one
> flow, since that is what Step 4 actually did as one continuous pass.
>
> Stage numbers below (1–6) match the generated skill's section numbers exactly (renamed from
> an earlier lettered draft — "Phase A/B/C..." — to avoid colliding with this project's own
> outer-workflow phase numbers, Phase 0–3, which a skill must never reference per
> architecture.md §5.4).

## Task type

Domain Test Design (Testing Model construction + Equivalence Partitioning + Boundary Value
Analysis + Decision Table when needed), producing frozen, oracle-sourced test cases.

## Methodology

Spec-and-code-derived variable modeling → assumption defensibility check → equivalence
partitioning → boundary value analysis → (decision table only if conditions combine) →
freeze with traceability, gated by human approval.

## Stage 1 — Model each variable

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
- **Judgment — create an Assumption wherever the model is not yet defensible**, not only when
  there is no spec rule at all: do the authoritative inputs gathered so far (spec, code,
  outside reference) add up to an oracle that could be defended if challenged, for the
  specific test case this variable is heading toward? A spec rule can exist and still fall
  short (e.g. it states a behavior but never names which part of the system must enforce it).
  Log every such gap, however partial, as an Assumption with `{source, confidence,
  status: proposed}`.

## Stage 2 — Assumption defensibility check (before any assumption becomes an oracle)

**This is the most important lesson from the pilots; it prevents an oracle from being
quietly invented.**

- **Judgment — for every Assumption that would serve as a Test Case's oracle:**
  → Can this assumption be pointed at an actual line in the spec, or a documented
    architectural rule? Not "it seems reasonable" — an actual citation.
  → If it names a specific responsible layer or component (e.g. "the backend must enforce
    X"), is that layer named *anywhere* in the spec/architecture, the way a comparable rule
    elsewhere in the same spec might name one? Contrast with a rule that never names any
    layer at all.
  → **Prefer the least-committing oracle.** Even where a layer-specific claim could be
    defended, does a path-agnostic, outcome-based version of the same claim already follow
    from the spec just as well? If so, use that instead — state only what the spec's wording
    actually supports, not more. Only assign responsibility to a specific layer when the spec
    itself does.
  → If no citation exists: **can the oracle be reframed as an outcome, stated
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

## Stage 3 — Equivalence Partitioning

- Partition each variable into valid/invalid classes. Split a class further only when
  behavior genuinely differs inside it.
- **Judgment — stop condition:** would splitting this class further actually change the
  observable behavior or the expected outcome, or would the resulting classes still expect
  the same thing? If a split would not change either one, stop there — a split that produces
  two classes with the same expectation is over-partitioning, not more coverage.
- **Judgment:** for an invalid class, is the expected outcome actually determinable from the
  oracle (spec or an accepted assumption / reframed outcome from Stage 2), or does testing it
  require guessing an error contract the spec never specifies? If the latter, state the
  expectation at the level the spec actually supports (e.g. "the invalid value must not end
  up persisted" rather than inventing a specific error message/status code).
- One case per invalid class (isolate the failure); valid classes may combine into fewer
  cases that jointly cover them.
- Explicitly design one negative case for every forbidden field and one for every immutable
  field found in Stage 1.

## Stage 4 — Boundary Value Analysis

Not only numeric ranges — a boundary can also be lexical (a string's length or allowed
characters), an enum (a fixed set of allowed values), optional/presence (whether a field may
be absent, empty, or must be populated), or structural (the size or count of a collection).

- **Judgment:** what kind of boundary is this, and does that change what "just inside" and
  "just outside" mean? For a numeric/length range, is the spec's boundary inclusive or
  exclusive (`>` vs `>=`)? Check the exact wording rather than assuming a convention.
- Plain action — generate the values for the identified kind: numeric/length range
  (below-min, min, max, above-max); enum (first member, last member, one value adjacent to
  but outside the set); optional/presence (absent, present-but-empty, present-with-value);
  structural (smallest allowed size, largest allowed size, one step beyond each). Add values
  for any second, orthogonal condition the spec also states.
- **Judgment — multi-path recognition:** does the feature have more than one reachable entry
  point that could independently satisfy or violate the same oracle (e.g. a
  client-side-enforced path and a directly-callable path)? If yes, design the same boundary
  values as separate cases per path — this is what turns a "the two layers might disagree"
  observation into falsifiable, separately verifiable cases, instead of one case that hides
  which path was actually exercised.

## Stage 5 — Decision Table gate

- Plain action: check whether two or more conditions must hold jointly to change the
  outcome (per architecture's gate-legitimacy rule — a table is only worth drawing if it
  changes the downstream action for at least two combinations).
- If no combining conditions exist: skip the table and record why in one line. Do not build a
  table "for completeness" when every condition is independent.

## Stage 6 — Freeze and traceability

- Plain action, and a hard rule of the method (not left to whoever runs it): **no case may
  move to `frozen` until a human has reviewed and approved the model entry it was built from**
  (including every assumption/reframing it rests on). If no such approval is recorded, stop
  and get it first — do not freeze on the model's completeness alone.
- Plain action: for every case, record `expected_source` as `spec` (with citation) or
  `assumption: <id>` (only if `accepted`) — never `impl`/`actual`.
- Plain action: link every case back to the Testing Model variable it came from.
- Plain action: mark `status: frozen` and commit before any execution happens.

## Output disposition

The output must show the final disposition of **every** assumption that was ever raised, even
ones that turned out not to be needed: `accepted` (used as a case's oracle), `rejected` (no
defensible citation and no reframing was possible), or `reframed — no longer needed` (a
path-agnostic, spec-based expectation replaced it). This keeps traceability complete — a
reader can see what happened to every assumption considered, not only the ones that survived.

## Authoritative inputs

| Input | Authoritative for | NOT authoritative for |
|---|---|---|
| The specification | Business rules, validation rules, what is valid/invalid, who owns what data | Where in the code a rule is enforced, or whether it is enforced at all |
| The source code | Where a variable is read/written, what boundaries the current implementation actually checks, whether two enforcement locations agree | What the *correct* behavior should be (never the oracle) |
| An assumption | A defensible stand-in for a spec gap, once explicitly accepted | Anything that could instead be reframed as a direct, path-agnostic reading of the spec (see Stage 2) |
