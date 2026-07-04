# Step 6.3 — Validation run: `bug-reporting` skill applied to FR-04's execution results

> Not a deliverable. Walks the generated skill's Stages 1–7 against FR-04's actual 16
> execution results (`work/FR-04-personal-profile/execution-results.md`) to check it
> reproduces `out/reports/FR-04-personal-profile/bug-reports/report.md` equivalently. The
> deliverable files are untouched.

## Stage 1 — Confirm each failure

10 FAILs (`ER-04-EP-002/004/005`, `ER-04-BVA-001/002/003/005/006/009/010`). Each confirmed
real (not setup error) using exactly the evidence the skill asks for: DB freshly reseeded
before the EP run and again before the BVA API-path run; only the field under test varied per
case; UI-path used the literal, unmodified regex. **Matches** the hand-run
`FAIL → real bug?` gate recorded in `execution-results.md`.

## Stage 2 — Group by root cause

- `ER-04-EP-002` → 1 defect (empty `name` accepted).
- `ER-04-EP-004`, `ER-04-BVA-006/009/010` → 1 defect (backend has no phone-format validation
  at all — same missing check, four different input values).
- `ER-04-BVA-001/002/003/005` → 1 defect (frontend regex contradicts the spec's phone rule —
  same wrong pattern, exercised at five boundary values; the two that "coincidentally" reject
  correctly are cited as evidence of the same defect, not treated as passes).
- `ER-04-EP-005` → 1 defect (role injection).

**= 4 distinct defects from 10 failures.** Matches `BUG-04-001..004` exactly — same grouping,
same count.

## Stage 3 — Severity from proven evidence

- Role injection: proven mechanism is a full stored-role change via a documented, spec-cited
  security rule (SEC-06) → Critical, no overclaim needed.
- Backend phone validation: proven mechanism is "any value persists, no format check
  anywhere reachable via direct API" → High; matches without needing correction (this bug's
  wording never overclaimed a downstream consequence, unlike FR-08's `total_amount` bug did
  on the first draft).
- Frontend regex: proven mechanism is "regex rejects spec-valid input, accepts spec-invalid
  input" → High; matches, no overclaim.
- Empty name: proven mechanism is a data-quality gap with no stated security/financial angle
  → Medium; matches.

**Matches** `BUG-04-004` (Critical) / `BUG-04-002`, `BUG-04-003` (High) / `BUG-04-001`
(Medium) exactly.

## Stage 4 — Spec vs assumption source

- `BUG-04-002`, `BUG-04-003`, `BUG-04-004`: expected result cites `README.md` FR-04 directly
  (lines 65, 65, 67 + SEC-06) → labeled `spec`.
- `BUG-04-001`: expected result rests on accepted Assumption A2, with an explicit
  classification note distinguishing it from the other three — labeled `assumption: A2`.

**Matches exactly** — this is the same distinction the human review round required for
`BUG-04-001` in the hand-run pass.

## Stage 5 — Write the report

- `actual` fields state what was executed (e.g. "ran the exact regex... returned false" for
  `BUG-04-003`, matching the wording fixed in the Step 4 self-review round).
- Root-cause notes are present and labeled "(code-derived, not the oracle)" for all four bugs.
- Evidence: raw request/response text for the three API-driven bugs, plus the executed regex
  output for the frontend one — matches the deliverable's evidence files exactly (no
  screenshots, since no browser tool exists in this environment; documented rather than
  silently substituted).

**Matches.**

## Stage 6 — Human gate

All four were reviewed individually before promotion; `BUG-04-001` was specifically held back
once for reclassification (assumption-grounded wording) before the batch was approved.
**Matches exactly** — this is the literal event the skill's "approval is per report, not one
blanket approval" rule was written to generalize from.

## Stage 7 — Summarize

Skill would report: 16 executed / 6 passed / 10 failed / 4 confirmed defects / severity
breakdown {Critical: 1, High: 2, Medium: 1}.

**Partial gap found:** `execution-results.md`'s existing summary states the 16/6/10/4 counts,
but no single line anywhere in the FR-04 deliverables states the severity breakdown
{Critical: 1, High: 2, Medium: 1} as its own explicit count — it is only recoverable by
reading all four bug entries in `bug-reports/report.md`. This is a minor, non-blocking gap:
the skill's Stage 7 output is slightly more complete than what the hand-run pass produced.
Not fixed here (would require editing the FR-04 deliverable, which this validation step must
not touch) — worth adding the explicit severity-count line the next time a bug-reporting pass
is run through this skill.

## Verdict

**Equivalent**, with one minor, already-identified gap (missing explicit severity-count
summary line) that the skill actually improves on rather than misses. Confirms the extraction
captured the method actually used, including both self-review corrections (severity
overclaim discipline, executed-vs-inferred phrasing, assumption-vs-spec labeling).
