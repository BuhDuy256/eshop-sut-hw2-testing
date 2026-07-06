# assumptions.md — FR-17 Coupon Management CRUD

> Assumptions artifact (architecture.md §4.1). Only an **accepted** assumption may serve as an
> oracle source for a Test Case (§4.3). All three entries below have already been carried
> through Stage 2 (assumption defensibility) — see disposition per entry.

## Review status (model-construction pass)

- A1: **accepted** as drafted (BVA-granularity scoping decision, not a behavioral claim).
- A2: **rejected** — no citation, and the system's own `EXPIRED` seed coupon contradicts the
  claim as a baseline fact; retained as an explicit exclusion note in the testing model, not a
  test-case oracle.
- A3: **rejected** — no citation exists for case-folding behavior on `code` uniqueness; the
  underlying question is retained as an observation, not a test-case oracle.

## A1 — `discount_value` BVA granularity (smallest positive unit)

- **Gap:** `README.md` FR-17 line 216 requires `discount_value` to be "dương" (positive) but
  does not state whether fractional values are meaningful. `coupons.discount_value` is declared
  `INTEGER` (`database.js` line 33), and all 4 seeded values (`10`, `50000`, `100000`, `20`) are
  whole numbers.
- **Assumption:** for Boundary Value Analysis, treat the smallest valid positive step above
  zero as the integer `1` (boundary set `{-1, 0, 1}`, not a fractional step) — matching both the
  column's declared type and the whole-number seed data. This is a scoping decision for *which
  concrete number represents "just above the minimum,"* not a claim about whether the SUT does
  or should reject fractional values — that question has no spec answer either way and is not
  asserted as a pass/fail boundary. Same class of decision as FR-15's accepted `A1` for `price`.
- **Stage 2 check:** could this be reframed instead of assumed? No — the "dương" wording alone
  does not fix a granularity; the answer isn't derivable path-agnostically from the spec text,
  only from the schema/seed-data evidence cited above.
- **Metadata:** `{ source: impl, confidence: MED, status: accepted }`.

## A2 — `expired_at` must be a future date at creation time (REJECTED)

- **Gap:** `README.md` FR-17 line 216 lists `expired_at` as a bare required field, with no
  parenthetical constraint (unlike the other five fields, each of which has one: uniqueness,
  enum, positivity, `>=0`, `>=1`). A plausible business reading might assume a newly created
  coupon's expiry must be in the future — otherwise why create it at all?
- **Assumption tested for citation (Stage 2.1):** can "required" be reframed to also mean "must
  not already be in the past"? No defensible reframing found. Stronger: the system's own seed
  data directly contradicts the claim — `backend/database.js` line 110 seeds the `EXPIRED`
  coupon with `expired_at: '2020-01-01'`, a date far in the past, as part of the SUT's own
  accepted baseline state (used deliberately to test the *customer-facing* expiry check in
  FR-09, out of scope here). If "must be future at creation" were a real rule, the seed data
  itself would already violate it. Extending "required" to "required and future" would assert
  more than the spec's wording supports, which Stage 2 explicitly disallows.
- **Disposition:** **rejected** — no citation exists, and the seed data is affirmative evidence
  against it. Not usable as a test-case oracle under MODEL ≠ ORACLE.
- **Metadata:** `{ source: spec, confidence: HIGH, status: rejected }`.
- **Retained as an explicit exclusion**, not a modeled EP/BVA target — recorded directly in the
  testing model's `expired_at` entry so a reader doesn't mistake the omission for an oversight.

## A3 — Case-sensitivity of `code` uniqueness (REJECTED)

- **Gap:** `README.md` FR-17 line 216 requires `code` to be "duy nhất" (unique) but does not
  state whether uniqueness is case-sensitive. SQLite's `UNIQUE` constraint (the only enforcement
  mechanism here — see the testing model's `code` entry) is case-sensitive by default (no
  `COLLATE NOCASE` declared on the column, `database.js` line 31). The admin frontend forces
  `.toUpperCase()` on input (`App.jsx` line 644), but that is a client-only cosmetic transform —
  a direct API call could submit `save10` alongside an existing `SAVE10` coupon.
- **Assumption tested for citation (Stage 2.1):** can "duy nhất" be reframed to mean
  "case-insensitively unique"? No defensible reframing found — the spec's wording is silent on
  case-folding, and nothing elsewhere in `README.md` establishes a case-insensitive-comparison
  convention for any other field to draw an analogy from.
- **Disposition:** **rejected** — no citation exists and no reframing is defensible. Not usable
  as a test-case oracle under MODEL ≠ ORACLE.
- **Metadata:** `{ source: spec, confidence: MED, status: rejected }`.
- **Retained as an observation (not a modeled EP/BVA target):** whether `save10` and `SAVE10`
  are treated as distinct codes by the live DB is a genuine open question worth a human's
  attention, but produces no frozen test case here.
