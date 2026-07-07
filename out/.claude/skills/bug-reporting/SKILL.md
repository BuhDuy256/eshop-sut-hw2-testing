---
name: bug_reporting
description: >
  Confirms which executed test failures are real defects, groups the ones that share a root
  cause without merging unrelated ones, classifies severity and priority using only what the
  evidence actually proved, and writes an evidenced bug report for each — clearly separating
  an expected result the spec states directly from one that only rests on an accepted
  assumption. Takes executed test results (an actual outcome and a verdict, each referencing
  a frozen test case) and the source code as input. Produces confirmed defect reports gated
  on human approval before promotion, plus a summary of totals by outcome, by severity, and
  by how many rest on a direct citation versus an accepted assumption.
---

# Bug Reporting

Turns confirmed test failures into evidenced, defensible bug reports; the stage order matters
because a failure must be confirmed and grouped by root cause before its severity is judged,
and its expected result's source (spec or assumption) must be settled before the report is
written — and no report may be promoted before a human approves it.

---

## Skill Metadata

**Task Type:** Bug Reporting
**Methodology:** Confirm each failure → group by root cause → classify severity/priority from
proven evidence only → separate spec-stated from assumption-grounded expectations → write the
report → human gate → summarize.

---

## Authoritative Inputs

Only treat each input as authoritative for what it actually contains.

| Input | Authoritative for | NOT authoritative for |
|---|---|---|
| Executed test results (actual + verdict, referencing a frozen test case) | What was observed when a specific frozen case ran | Whether the observed behavior is correct — that already lives in the test case's own expected result |
| The frozen test case being referenced | The expected result and its source (spec citation or accepted assumption) | Anything not already decided when the case was frozen — a bug report may not invent a new expectation at write time |
| The source code | Why a defect happens (root cause), once one is already confirmed | Whether something is a defect in the first place, or how severe it is — those are decided from the expected-vs-actual comparison and executed evidence, never from reading code alone |

---

## Stage 1: Confirm each failure is a real defect

**Objective:** Rule out test/setup error before treating a FAIL as a defect.

- **Step 1.1 — Confirm or reject the failure:**
  - **Input:** The executed result (actual + verdict) and how the environment was set up for
    this run.
  - **Reasoning:**
    → Is this a genuine defect, or could it be a test/setup artifact — stale state left from
      an earlier run, wrong credentials, a variable that was not actually isolated?
    → What concrete evidence supports either conclusion — was the environment freshly reset
      before this run, did only the field under test change while everything else stayed at
      a known-valid value, does the same result reproduce on a second attempt?
  - **Output:** A confirm/reject decision, with its evidence, for this failure.

- **Step 1.2 — Gate the next stage.** A failure with no recorded confirm/reject decision may
  not move on to Stage 2.

---

## Stage 2: Group failures by shared root cause

**Objective:** Turn a list of confirmed failures into a smaller list of distinct defects,
without merging failures that only look alike.

- **Step 2.1 — Decide which failures belong together:**
  - **Input:** All failures confirmed in Stage 1.
  - **Reasoning:**
    → Do two or more of these trace back to the same underlying defect — for example, the
      same missing check, exercised through different input values?
    → If these failures were merged into one report, would that make reproduction less
      clear, or would fixing the merged report actually require two or more independent
      fixes? If either is true, they are not one defect — keep them as separate reports even
      if they look related on the surface.
    → Ignore: grouping failures that only look similar on the surface but trace to different
      causes. That would hide a second, distinct defect inside one report.
  - **Output:** Groups of failures, one group per distinct defect.

---

## Stage 3: Classify severity and priority from only what was proven

**Objective:** Keep the severity claim exactly as strong as the evidence, no stronger.

- **Step 3.1 — Judge severity and priority:**
  - **Input:** A grouped defect and everything that was actually executed to demonstrate it.
  - **Reasoning:**
    → What mechanism did the executed evidence actually demonstrate — not what it might imply
      if some other, untested part of the system behaved a certain way?
    → Does the wording assume a downstream consequence that was never executed or observed
      (for example, describing a data-integrity bug as if it were a live financial
      transaction, when no such transaction was exercised)? If so, restate the severity in
      terms of the mechanism actually proven, and say plainly what was not tested.
    → How bad is the proven impact on its own terms — data loss or corruption, a security
      boundary crossed, a business rule violated, or a cosmetic mismatch?
    → Ignore: reusing a dramatic-sounding phrase just because it reads more urgently — match
      the words to the evidence, not to the desired impression.
    → Ignore: raising the severity or the confidence of the claim because the source code
      suggests the problem is worse than what was executed. Code may explain why the defect
      happens; it may never push the severity or the confidence beyond what was actually run
      and observed.
  - **Output:** A severity and priority, worded to match only what was proven.

---

## Stage 4: Separate what the spec states from what only an assumption supports

**Objective:** Make sure a reader can tell a direct citation apart from an assumption-backed
claim.

- **Step 4.1 — Trace the expected result to its source:**
  - **Input:** The expected result the failing case was compared against.
  - **Reasoning:**
    → Does this expected result come from an explicit statement in the spec, or does it rest
      on an accepted Assumption — a gap the spec never directly closed?
    → If assumption-grounded, does the report say so plainly — naming which assumption and
      why it was accepted — rather than presenting it with the same confidence as a direct
      citation?
    → If the assumption behind it was itself reframed into a path-agnostic, spec-based
      expectation, is that reframed expectation cited directly instead? Once reframed, it is
      spec-grounded, not assumption-grounded.
  - **Output:** The expected result's source, labeled plainly as `spec` or `assumption`.

---

## Stage 5: Write the report

**Objective:** Produce one evidenced report per grouped defect.

- **Step 5.1 — Fill the fixed fields.** ID, title, severity, priority, ref (the test case and
  execution result it comes from), expected (with its source from Stage 4), actual, steps to
  reproduce, evidence.

- **Step 5.2 — State `actual` as what was executed.** Phrase it as what was actually run and
  observed (for example, "ran the exact check against this value and it returned X" or "sent
  this request and the stored value became Y") — never in a way that could be mistaken for a
  conclusion drawn only from reading the source.

- **Step 5.3 — Label any code-derived explanation as root cause, not oracle.** If the code
  was read to explain why the defect happens, mark that explanation clearly as a root-cause
  note — the expected result still comes only from Stage 4, never from this note.

- **Step 5.4 — Attach matching evidence, and name its type.** Use whatever form actually
  matches how the case was executed — a screenshot, a raw captured request/response, a log
  excerpt, a direct database observation, or another form the execution actually produced —
  and always state which type it is, in every report, not only when it happens to be
  something other than a screenshot. This is what lets a reader trace the claim back to how
  it was actually checked.

---

## Stage 6: Human gate before promotion

**Objective:** Stop any report from being promoted or filed without explicit approval.

- **Step 6.1 — Gate on approval.** A bug report may not be promoted to a deliverable or filed
  anywhere until a human has approved it. Approval is per report, not one blanket approval
  over an unreviewed batch — a reviewer must be able to hold one report back (for
  reclassification, a missing citation, or any other concern) while approving the rest.

---

## Stage 7: Summarize

**Objective:** Report the run's outcome as numbers, not just as a list of reports.

- **Step 7.1 — Report totals.** How many cases were executed, how many passed, how many
  failed, how many failures were confirmed as defects, and a count of confirmed defects by
  severity.

- **Step 7.2 — Report the evidence basis.** How many confirmed defects ended up `spec`-
  grounded versus `assumption`-grounded (Stage 4), and how many were reclassified from one to
  the other during review. This shows how much of the run's confidence rests on a direct
  citation versus an accepted judgment call.

---

## Output Format

For each grouped defect: one bug report with the fixed fields from Stage 5 (ID, title,
severity, priority, ref, expected + source, actual, steps to reproduce, evidence + its named
type), plus its Stage 6 approval status.

For the run as a whole: a summary with the totals from Step 7.1 (executed / passed / failed /
confirmed-defects counts, and a count of confirmed defects by severity) and the evidence-basis
breakdown from Step 7.2 (`spec`-grounded vs. `assumption`-grounded confirmed defects, and any
reclassifications between the two).
