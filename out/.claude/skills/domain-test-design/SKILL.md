---
name: domain_test_design
description: >
  Builds a Testing Model from a feature's specification and source code, then designs
  Equivalence Partitioning and Boundary Value Analysis test cases from that model, adding a
  Decision Table only when two or more conditions must hold together to change the result.
  Takes a specification, the feature's source code, and (if one already exists) a partial
  Testing Model as input. Produces a completed Testing Model (domains, boundaries, sources,
  validation rules, oracles, metadata), a list of Assumptions each with an explicit
  accept/reject decision, and a set of frozen test cases whose expected results are always
  traced to the spec or an accepted assumption, never to the code or an observed result.
---

# Domain Test Design

Turns a specification and its source code into frozen, oracle-sourced test cases; the stage
order matters because an assumption must be checked for a cleaner, citation-free reframing
(Stage 2) before it is ever allowed to become the expected result of a test case (Stage 3
onward), and because no case may reach `frozen` (Stage 6) without a human approving the model
it was built from.

---

## Skill Metadata

**Task Type:** Domain Test Design
**Methodology:** Variable modeling → assumption defensibility check → equivalence
partitioning → boundary value analysis → decision table (only if needed) → freeze with
traceability.

---

## Authoritative Inputs

Only treat each input as authoritative for what it actually contains.

| Input | Authoritative for | NOT authoritative for |
|---|---|---|
| The specification | Business rules, validation rules, what is valid/invalid, who owns what data | Where in the code a rule is enforced, or whether it is enforced at all |
| The source code | Where a variable is read/written, what boundaries the current implementation actually checks, whether two enforcement locations agree with each other | What the correct behavior should be — code is never the oracle |
| An assumption | A defensible stand-in for a spec gap, once explicitly accepted | Anything that could instead be reframed as a direct, path-agnostic reading of the spec (see Stage 2) |

---

## Stage 1: Model each variable

**Objective:** Turn every input/output variable the feature touches into a complete model
entry.

- **Step 1.1 — Model the variable:**
  - **Input:** The specification and the source code for this variable.
  - **Reasoning:**
    → What is the domain, the boundary and its relation, the validation rule, and the oracle
      for this variable?
    → Where does each of those come from — the spec, the code, or an outside reference? Tag
      it with that source.
    → Ignore: do not let a value read from the code become the oracle. Code shows where to
      look; the spec (or an accepted assumption) says what is correct.
  - **Output:** One model entry: domain, boundary + relation, source, validation rule, oracle,
    metadata `{source, confidence, status}`.

- **Step 1.2 — Check for a second, code-revealed boundary:**
  - **Input:** The model entry from Step 1.1, plus the source code.
  - **Reasoning:**
    → Does the code enforce a boundary that differs from the one the spec states (for
      example, a check on the client side that does not match the spec's rule)?
    → If yes, record both boundaries side by side, each tagged with its own source — do not
      merge them into one, and do not treat the code's boundary as correct just because it
      exists.
  - **Output:** The model entry updated with any second boundary found, clearly tagged.

- **Step 1.3 — Check for a forbidden or immutable state:**
  - **Input:** The model entry, the spec, and the source code.
  - **Reasoning:**
    → Can this variable be pushed into a state the actor must never be able to reach (for
      example, gaining a permission they should not have)?
    → Is there a value that must never change through this path, even if the request tries to
      change it?
    → If either is true, record it explicitly — it becomes its own test case later, not a
      note buried in the model.
  - **Output:** A forbidden-state and/or immutable-state entry, if any exist.

- **Step 1.4 — Create an Assumption wherever the model is not yet defensible:**
  - **Input:** The model entry built so far in Steps 1.1–1.3.
  - **Reasoning:**
    → Do the authoritative inputs gathered so far — spec, code, outside reference — add up to
      an oracle that could be defended if challenged, for the specific test case this variable
      is heading toward?
    → This is not only "there is no spec rule at all." A spec rule can exist and still fall
      short — for example, it states a behavior but never says which part of the system must
      enforce it, or it defines a class of values but leaves a needed detail unstated.
    → Ignore: treating "a spec rule exists somewhere nearby" as automatically enough. Ask
      whether it is enough for the exact oracle claim being planned, not for the variable in
      general.
  - **Output:** One Assumption entry `{source, confidence, status: proposed}` for every gap
    found this way, however partial the gap is.

---

## Stage 2: Check every assumption before it can become an oracle

**Objective:** Stop an assumption from becoming a test case's expected result unless it is
truly needed — this is the step that keeps an oracle honest.

- **Step 2.1 — Test the assumption for a citation, then try to reframe it:**
  - **Input:** Every Assumption from Step 1.4 that a test case would need as its oracle.
  - **Reasoning:**
    → Can this assumption be pointed at an actual line in the spec, or a documented
      architectural rule — not "it seems reasonable," an actual citation?
    → If it names a specific responsible part of the system (for example, "the server must
      block this"), is that part actually named anywhere in the spec, the way a comparable
      rule elsewhere in the same spec might name one?
    → **Prefer the least-committing oracle.** Even where a layer-specific claim could be
      defended, does a path-agnostic, outcome-based version of the same claim already follow
      from the spec just as well? If so, use that instead — state only what the spec's
      wording actually supports, not more. Only assign responsibility to a specific layer
      when the spec itself does.
    → If no citation exists: can the same expectation be restated as an outcome, using only
      what the spec already defines, without naming which part of the system is responsible
      (for example, "a value the spec calls invalid must never end up in the final, visible
      state, no matter which part of the system was supposed to catch it")? A reframed,
      outcome-based expectation usually needs no assumption at all, because it only repeats a
      definition the spec already gives.
    → Only keep the assumption as-is if no such reframing is possible, and only after it is
      explicitly accepted or rejected — never carried forward silently.
    - Ignore: do not keep the original wording just because it is already written down. A
      claim with no citation does not become defensible by being reused.
  - **Output:** Each assumption marked `accepted`, `rejected`, or replaced by a reframed,
    citation-based expectation that needs no assumption at all.

---

## Stage 3: Equivalence Partitioning

**Objective:** Split each variable into valid and invalid classes and pick cases that cover
them.

- **Step 3.1 — Partition into classes:**
  - **Input:** The model entry (Stage 1) and any reframed expectation (Stage 2).
  - **Reasoning:**
    → What are the valid and invalid classes for this variable?
    → Does behavior actually differ inside a class? If yes, split it further; if the
      behavior is the same throughout, do not split it just to add more classes.
    → Would splitting this class further actually change the observable behavior or the
      expected outcome, or would the resulting classes still expect the same thing? If a
      split would not change either one, stop there — a split that produces two classes with
      the same expectation is not a real partition, it is over-partitioning.
  - **Output:** A list of valid and invalid classes, each one representing a genuinely
    different observable outcome.

- **Step 3.2 — Decide what an invalid class can actually claim:**
  - **Input:** Each invalid class from Step 3.1.
  - **Reasoning:**
    → Is the expected outcome for this class determinable from the oracle (the spec, an
      accepted assumption, or a Stage 2 reframing)?
    → Or would testing it require guessing an error contract the spec never specifies (an
      exact message, code, or format)? If so, state the expectation at the level the spec
      actually supports — for example, that an invalid value must not end up persisted —
      instead of inventing detail the spec does not give.
  - **Output:** A stated, spec-level expectation for each invalid class.

- **Step 3.3 — Select cases.** One case per invalid class, to isolate each failure. Combine
  valid classes into as few cases as will still cover all of them.

- **Step 3.4 — Add the forbidden/immutable cases.** For every forbidden state and every
  immutable state found in Step 1.3, add one negative test case targeting it.

---

## Stage 4: Boundary Value Analysis

**Objective:** Turn every boundary a variable has into concrete boundary-value test cases —
not only numeric ranges. A boundary can also be lexical (a string's length or allowed
characters), an enum (a fixed set of allowed values), optional/presence (whether a field may
be absent, empty, or must be populated), or structural (the size or count of a collection).
Each kind has its own way of expressing "just inside" and "just outside."

- **Step 4.1 — Identify the boundary's kind and exact wording:**
  - **Input:** The spec's statement of the boundary.
  - **Reasoning:**
    → What kind of boundary is this — a numeric/length range, a fixed set of allowed values,
      the presence or absence of something, or the size of a collection? The right boundary
      values depend on which kind it is.
    → For a numeric/length range: is it inclusive or exclusive — does the spec say "greater
      than" or "greater than or equal to" (and the same question at the other end)?
    → Does this match what a natural reading of the spec intends, or is the wording
      ambiguous enough to need its own assumption?
  - **Output:** A confirmed boundary definition: its kind, plus the inclusive/exclusive
    reading if it is a range.

- **Step 4.2 — Generate the boundary values for that kind:**
  - Numeric/length range: the value just below the minimum, the minimum, the maximum, and
    the value just above the maximum.
  - Enum: the first and last defined member, and one value adjacent to the set but not a
    member of it.
  - Optional/presence: the field entirely absent, present but empty, and present with a
    value.
  - Structural: the smallest and largest allowed size or count, and one step beyond each end.
  - In every case, also add values for any second, orthogonal condition the spec states (for
    example, a required starting value that is separate from length).

- **Step 4.3 — Check for more than one enforcement path:**
  - **Input:** The boundary values from Step 4.2, plus the source-code map from Stage 1.
  - **Reasoning:**
    → Does this feature have more than one reachable path that could each independently
      satisfy or violate the same boundary rule (for example, one path enforced before
      submission and a second path that bypasses it)?
    → If yes, does testing only one path hide whether the two paths actually agree with each
      other?
  - **Output:** If more than one path exists, the same boundary values turned into separate
    cases per path, so each path's actual behavior is separately checked.

---

## Stage 5: Decide whether a Decision Table is needed

**Objective:** Only build a Decision Table when it would change what gets tested.

- **Step 5.1 — Check whether conditions combine:**
  - **Input:** All variables and rules gathered for this feature so far.
  - **Reasoning:**
    → Do two or more conditions have to hold at the same time to change the outcome?
    → Would a Decision Table actually route at least two different combinations to different
      outcomes? If every condition acts independently of the others, a table adds no new
      information.
  - **Output:** Either a Decision Table (built only for the combining conditions), or a
    one-line note explaining why it was skipped.

---

## Stage 6: Freeze and trace

**Objective:** Lock every test case to its source and its model entry before any execution
happens.

- **Step 6.1 — Confirm human approval before anything is frozen.** A test case may not move
  to `frozen` until a human has reviewed and approved the model entry (and every assumption or
  reframing it rests on) it was built from. This is a rule of the method, not a detail left to
  whoever runs it: if no such approval is recorded, stop here and get it before continuing —
  do not freeze on the strength of the model's completeness alone.

- **Step 6.2 — Record the expected-result source.** For every case, write `expected_source`
  as the spec (with its exact citation) or `assumption: <id>` — only for an assumption marked
  `accepted` in Stage 2. Never record the code or an observed result as the source.

- **Step 6.3 — Link each case to its model entry.** Every test case references the exact
  variable entry (Stage 1) it was derived from.

- **Step 6.4 — Freeze.** Mark each case `status: frozen`. No case's expected result may be
  edited after this point, and no case may be executed before this point.

---

## Output Format

For each variable: one Testing Model entry (`domain`, `boundary + relation + source`,
`validation rule`, `oracle`, `metadata {source, confidence, status}`), plus any
forbidden/immutable-state entries found for it.

For each spec gap: one Assumption entry (`{source, confidence, status}`). The output must
show the **final disposition of every assumption that was ever raised**, even the ones that
turned out not to be needed — `accepted` (used as a case's oracle), `rejected` (no defensible
citation and no reframing was possible, so the claim was dropped), or `reframed — no longer
needed` (a path-agnostic, spec-based expectation replaced it). This is what keeps traceability
complete: a reader can see not just which assumptions survived, but what happened to every one
that was considered.

For the feature as a whole: an Equivalence Partitioning table (one row per case: technique,
preconditions, input, steps, expected result, `expected_source`, `status`), a Boundary Value
Analysis table in the same row shape (one set of rows per enforcement path, when more than
one path exists), a Decision Table only where Stage 5 found combining conditions (with a
one-line note when it was skipped), and a traceability link from every case back to its model
entry.
