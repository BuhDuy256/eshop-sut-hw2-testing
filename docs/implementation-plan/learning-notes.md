# learning-notes.md — Cross-cutting Learning Artifacts

> The Learning Artifact type defined in `architecture.md` §3.1/§8 ("a record of assumptions
> made, effective prompts, and lessons — kept only insofar as it feeds reviewable output").
> No automated learning engine; every entry here is human-reviewed at the moment it is logged.
> This is the first real instance of this artifact, produced from Step 3 — per the plan's own
> rule ("no pre-built templates... real instances become the templates").

## LN-001 — Assumption metadata `source` enum may be missing a category

- **Observed:** Step 3 (FR-08 smoke), self-review of the Testing Model fragment.
- **What happened:** two Assumptions were logged for `total_amount` — A3 ("product price and
  quantity do not change during the test") and A4 (originally: "no coupon/voucher/shipping/tax
  applied in this smoke case"). Both were forced into the frozen enum
  `source ∈ {spec, impl, external}` (`architecture.md` §4.2), tagged `external`, for lack of a
  better fit.
- **Why this is a gap:** neither assumption is actually sourced from an external reference.
  A4 turned out to be a **tester scope-limiting decision** (fixed during self-review: was
  mistagged `spec`, which risked implying `README.md` states "no coupon applies" — it does
  not; FR-09 coupons are a real, spec-described feature deliberately excluded from this
  smoke case). A3 is closer to a **test-execution control assumption** (an assumption about
  the *test environment*, not about the SUT's specified behavior, its implementation, or any
  external document) — `external` is the least-wrong existing tag, but not an accurate one.
- **Candidate improvement (not adopted — architecture is frozen):** a fourth `source` value,
  e.g. `test-scope` or `test-control`, distinct from `external`, to represent assumptions that
  bound the *test's* conditions rather than describe a fact about the SUT. Whether this is
  worth adding depends on how often this category recurs across FR-04/15/17 — if it shows up
  repeatedly, it is real evidence for extending the enum in a future architecture revision or
  the next iteration of this framework; a single occurrence does not justify reopening a
  frozen contract.
- **Disposition:** logged only. `A3`/`A4` remain tagged `external` in
  `work/FR-08-checkout/testing-model.md` (within the current frozen enum). No architecture
  change made. Revisit if the same pattern recurs in Step 4 (FR-04) or later.
