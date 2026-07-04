# Methodology notes — `bug-reporting` (Step 6.1)

> Base: `docs/skill-creation-master-plan/skill-creation-master-plan.md` Part 5, Skill 5.
> Refined from what actually worked in Step 3 (FR-08 smoke) and Step 4 (FR-04 full pilot),
> including the self-review corrections made on both. This is an **existing spec** input for
> `generate-skill` (Step 2B path). Stage numbers avoid the word "Phase" + a number, so they
> cannot collide with this project's own outer-workflow phase numbers (see
> `docs/implementation-plan/skill-4-domain-test-design-notes.md`'s note on the same point).
>
> Per the user's standing preference for this project: when this file is revised again after
> a human review round, update it first, then regenerate the skill from it — do not hand-patch
> the generated `SKILL.md` and sync this file afterward.

## Task type

Bug Reporting (confirm real defects from executed test results, classify them, write
evidenced reports, gate their promotion on human approval).

## Methodology

Confirm each failure is real → group failures by shared root cause → classify severity/
priority strictly from what was proven → write an evidenced report, distinguishing what the
spec states from what only an assumption supports → human approval before promotion →
summarize.

## Stage 1 — Confirm each failure is a real defect

- **Judgment:** for each executed case with a FAIL verdict, is this a genuine defect, or could
  it be a test/setup artifact (stale state from a previous run, wrong credentials, a variable
  that was not actually isolated)? Point to concrete evidence either way — for example, that
  the environment was freshly reset before this run, that only the field under test changed
  while everything else stayed at a known-valid value, or that the same result reproduces on
  a second attempt.
- Plain action: record the confirm/reject decision and its evidence for every FAIL before
  moving on. A FAIL with no recorded confirmation may not proceed to Stage 2.

## Stage 2 — Group failures by shared root cause

- **Judgment:** do two or more confirmed failures trace back to the same underlying defect
  (for example, the same missing validation check, exercised through different input values)?
  If so, they belong in one bug report, not one each — a report should describe one thing
  wrong with the system, evidenced by however many cases demonstrate it, not a case-by-case
  transcript.
  - Ignore: grouping failures that merely look similar on the surface but trace to different
    causes (that would hide a second, distinct defect inside one report).

## Stage 3 — Classify severity and priority from only what was proven

- **Judgment — prefer the least-overclaiming severity justification:**
  → What mechanism did the executed evidence actually demonstrate — not what it might imply
    if some other, untested part of the system behaved a certain way?
  → Does the severity wording assume a downstream consequence that was never executed or
    observed (for example, describing a data-integrity bug as if it were a live financial
    transaction, when no such transaction was exercised)? If so, restate the severity in terms
    of the mechanism actually proven (for example: this is the system's only record of a
    value, and it is fully attacker-controlled), and note explicitly what was not tested.
  → How bad is the proven impact on its own terms — data loss or corruption, a security
    boundary crossed, a business rule violated, or a cosmetic mismatch? Rank accordingly.
  - Ignore: reusing a dramatic-sounding severity phrase just because it reads more urgently;
    match the words to the evidence, not to the desired impression.

## Stage 4 — Separate what the spec states from what only an assumption supports

- **Judgment:** does this bug's expected result come from an explicit statement in the spec,
  or does it rest on an accepted Assumption (a gap the spec never directly closed)? These are
  not interchangeable, and a reader must be able to tell which one they are looking at.
  - If assumption-grounded: say so plainly in the report (which assumption, and why it was
    accepted), rather than presenting it with the same confidence as a direct citation.
  - If the underlying assumption was itself reframed into a path-agnostic, spec-based
    expectation (see the `domain-test-design` skill, Stage 2), cite that reframed expectation
    directly — it is spec-grounded, not assumption-grounded, once reframed.

## Stage 5 — Write the report

Plain action, fixed fields per bug: ID, title, severity, priority, ref (the test case and
execution result it comes from), expected (with its source per Stage 4), actual, steps to
reproduce, evidence.

- Plain action: state `actual` as what was actually executed and observed (for example, "ran
  the exact validation logic against this value and it returned X" or "sent this request and
  the stored value became Y") — never phrase it in a way that could be mistaken for a
  conclusion drawn only from reading the source.
- Plain action: if the code was read to explain *why* the defect happens, label that
  explanation clearly as a root-cause note derived from the code, not as the oracle — the
  expected result still comes only from Stage 4, never from this note.
- Plain action: attach evidence in whatever form actually matches how the case was executed
  (a screenshot for a UI-driven case, a raw captured request/response for an API-driven one);
  state plainly which form was used and why, if it is not a screenshot.

## Stage 6 — Human gate before promotion

- Plain action, and a hard rule of the method: a bug report may not be promoted to a
  deliverable or filed anywhere until a human has approved it. Approval is per report, not a
  single blanket approval over an unreviewed batch — a reviewer must be able to hold one
  report back (for reclassification, a missing citation, or any other concern) while approving
  the rest.

## Stage 7 — Summarize

Plain action: report totals — how many cases were executed, how many passed, how many failed,
how many failures were confirmed as defects, and a count of confirmed defects by severity.

## Authoritative inputs

| Input | Authoritative for | NOT authoritative for |
|---|---|---|
| Executed test results (actual + verdict, referencing a frozen test case) | What was observed when a specific frozen case ran | Whether the observed behavior is correct — that already lives in the test case's own expected result |
| The frozen test case being referenced | The expected result and its source (spec citation or accepted assumption) | Anything not already decided when the case was frozen — a bug report may not invent a new expectation at write-time |
| The source code | Why a defect happens (root cause), once one is already confirmed | Whether something is a defect in the first place — that is decided from the expected-vs-actual comparison, never from reading code alone |
