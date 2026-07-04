# Step 5.3 — Validation run: `domain-test-design` skill applied to FR-04's Testing Model

> Not a deliverable. Produced by manually walking the generated skill's Stages 3–6 against
> FR-04's already-approved Testing Model, to check the skill reproduces the hand-written
> report in `out/reports/FR-04-personal-profile/{domain-testing,boundary-value-analysis}/report.md`
> equivalently. The deliverable files are untouched.

## Stage 3 output — Equivalence Partitioning (skill-derived)

1. Joint valid case: `name` valid + `phone` spec-valid + `shipping_address` non-empty →
   expect all three persisted as sent.
2. `name` = empty string (invalid class) → expect: not persisted as empty.
3. `shipping_address` = empty string (valid class, per accepted assumption) → expect:
   persisted as empty.
4. `phone` = spec-invalid value via the non-UI path (invalid class) → expect: not persisted
   (path-agnostic oracle).
5. Forbidden field (`role`)-injection case → expect: no effect on stored value.
6. Immutable field (`email`)-injection case → expect: no effect on stored value.

**= 6 cases.** Matches `out/reports/FR-04-personal-profile/domain-testing/report.md`
(`TC-04-EP-001`…`006`) one-to-one in substance (same variable coverage, same classes, same
forbidden/immutable treatment). Only difference: the skill has no project-specific IDs,
concrete field/endpoint names, or literal spec line numbers — it produces the same case
*shape*, not the same labels (expected, since the skill takes those as input, not as
built-in knowledge).

## Stage 4 output — Boundary Value Analysis (skill-derived, `phone`)

- Boundary read as inclusive both ends (`10–11 digits` means length ∈ [10,11]).
- Boundary values: below-min (9), min (10), max (11), above-max (12); plus the orthogonal
  leading-digit condition (valid `0` vs invalid non-`0`, held at a valid length) → 5 distinct
  values.
- Multi-path check: yes — a client-side-enforced path and a directly-callable path that could
  disagree → same 5 values become separate cases per path → **5 × 2 = 10 cases.**

Matches `out/reports/FR-04-personal-profile/boundary-value-analysis/report.md`
(`TC-04-BVA-001`…`010`) exactly in count and structure (same 5-value boundary set, same
UI-path/API-path split).

## Stage 5 output — Decision Table gate

No two conditions combine to jointly change an outcome (each field validated/checked
independently) → table skipped, one-line reason recorded. Matches the hand-written report's
decision.

## Stage 6 output — Freeze and traceability

Each case's `expected_source` traces to a spec citation or an accepted assumption (never
code/observed); each case links back to its Testing Model variable; all marked `frozen`
before any execution. Matches the hand-written report's discipline (verified by `git log`
commit order in Step 4.3/4.4).

## Verdict

**Equivalent.** Case count (6 EP + 10 BVA = 16), partition/boundary coverage, forbidden/
immutable handling, decision-table reasoning, and freeze/traceability discipline all match
the hand-written FR-04 report. The skill reproduces the proven method without needing any
FR-04-specific knowledge baked into it — the specifics came entirely from the Testing Model
given as input.
