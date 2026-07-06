# assumptions.md — FR-15 Product Management CRUD

> Assumptions artifact (architecture.md §4.1). Only an **accepted** assumption may serve as an
> oracle source for a Test Case (§4.3). Both entries below have already been carried through
> Stage 2 (assumption defensibility) — see disposition per entry.

## Review status (2026-07-04, model-construction pass)

- A1: **accepted** as drafted (BVA-granularity scoping decision, not a behavioral claim).
- A2: **rejected** — no citation exists and no reframing is defensible; the underlying anomaly
  is retained as an observation for the domain-testing report's gap-analysis section, not as a
  test-case oracle.

## A1 — `price` BVA granularity (smallest positive unit)

- **Gap:** `README.md` FR-15 line 196 requires `price` to be "số dương (> 0)" but does not
  state whether fractional VND is meaningful or accepted. `products.price` is declared
  `INTEGER` (`database.js` line 67), and all 5 seeded prices are whole numbers with no
  decimals (e.g. `30000000`).
- **Assumption:** for Boundary Value Analysis, treat the smallest valid positive step above
  zero as an integer (boundary set `{-1, 0, 1}`, not `{-0.01, 0, 0.01}`) — VND has no smaller
  circulating subunit, matching both the column's declared type and the whole-number seed
  data. This is a scoping decision for *which concrete number represents "just above the
  minimum,"* not a claim about whether the SUT does or should reject fractional prices — that
  question has no spec answer either way and is not asserted as a pass/fail boundary.
- **Stage 2 check:** could this be reframed instead of assumed? No — the ">0" wording alone
  does not fix a granularity; the answer isn't derivable path-agnostically from the spec text,
  only from the schema/seed-data evidence cited above.
- **Metadata:** `{ source: impl, confidence: MED, status: accepted }`.

## A2 — Response-type consistency for `price` on `GET /api/products/:id` (REJECTED)

- **Gap:** `backend/server.js` line 162 returns `price` as a **string** for even-numbered
  product ids and as a **number** for odd-numbered ids (`if (row.id % 2 === 0) row.price =
  row.price.toString();`). `README.md`'s only statement about `price` is the Add/Edit input
  constraint (line 196, "phải là số dương"); it says nothing about the View-path response's
  data type. `api_specification.md` §3.2 shows no response body example for this endpoint, so
  it is silent too (and per `oracle-precedence.md`, would only be shape-authoritative even if
  it did show one).
- **Assumption tested for citation (Stage 2.1):** can "price must be a positive number" (the
  Add/Edit input-validity clause, line 196) be reframed path-agnostically to also govern the
  View-path response type? No defensible reframing found — that clause defines input validity
  for Add/Edit, not response serialization for View. Extending it to response type would assert
  more than the spec's wording supports, which Stage 2 explicitly disallows ("state only what
  the spec's wording actually supports, not more").
- **Disposition:** **rejected** — no citation exists and no reframing is defensible. Not usable
  as a test-case oracle under MODEL ≠ ORACLE.
- **Metadata:** `{ source: spec, confidence: HIGH, status: rejected }`.
- **Retained as an observation (not a modeled EP/BVA target):** the id-parity-dependent type
  switch is a genuine code anomaly worth flagging in the domain-testing report's gap-analysis
  section — exactly the caution the handoff raised — but it produces no frozen test case.
