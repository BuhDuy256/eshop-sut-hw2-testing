# assumptions.md — FR-04 Personal Profile Management

> Assumptions artifact (architecture.md §4.1). Only an **accepted** assumption may serve as an
> oracle source for a Test Case (§4.3). All entries below are `status: proposed` pending
> human review at the `completeness_confirmed` gate.

## Review status (2026-07-04)

- A1, A2, A3: **accepted** as drafted.
- A4: **rejected** as originally drafted — see revised entry below. No spec or architecture
  evidence assigns phone-format enforcement to a specific layer (checked: `README.md` FR-04,
  the SEC-01–SEC-07 security requirements list, and `architecture.md`'s oracle-precedence
  principle — none name an enforcement layer for this rule; contrast with FR-08 line 107,
  which *does* explicitly say "backend phải tự tính lại"). Asserting "backend must reject" as
  an oracle would not be defensible. Reframed below.

## A1 — `name` maximum length

- **Gap:** `README.md` FR-01/FR-04 require `name` but state no minimum/maximum length. No
  frontend `maxLength`, no backend check, no DB constraint (SQLite `TEXT`, unbounded).
- **Assumption:** treat `name` as unbounded for this pilot — no BVA on an upper length
  boundary is derivable without an authoritative limit. An extremely long string (e.g. 10,000
  chars) is tested only as a robustness/EP probe (does the request succeed or error?), not as
  a pass/fail boundary against a spec-stated limit.
- **Metadata:** `{ source: external, confidence: LOW, status: accepted }` — `external` because
  there is no spec or impl basis at all; this is a testing-scope decision made in the absence
  of any authoritative limit (same category flagged in `docs/implementation-plan/learning-notes.md` LN-001).

## A2 — `name` empty-string handling

- **Gap:** frontend marks the `name` input `required` (client-side only); backend performs no
  check and will persist an empty string if the endpoint is called directly.
- **Assumption:** an empty `name` is an **invalid** equivalence class for FR-04 (a profile
  cannot have a blank name) — this follows from `name` being one of the three fields FR-04
  explicitly lists as user-manageable profile data, and from `name` being mandatory at
  registration (FR-01) with no stated exception allowing it to become blank later.
- **Metadata:** `{ source: spec, confidence: MED, status: accepted }`.

## A3 — `shipping_address` empty-string handling

- **Gap:** `README.md` does not state whether `shipping_address` may be empty; the frontend
  `textarea` has no `required` attribute.
- **Assumption:** empty `shipping_address` is a **valid** equivalence class (a user may not
  have set a default address yet) — consistent with the DB allowing `NULL`/empty and no spec
  statement to the contrary.
- **Metadata:** `{ source: impl, confidence: MED, status: accepted }`.

## A4 — Server-side enforcement of the phone format rule (REJECTED, reframed)

- **Original gap:** `README.md` FR-04 states the phone validity rule ("bắt đầu bằng số 0,
  10–11 chữ số") but does not say *where* it must be enforced.
- **Original assumption (rejected 2026-07-04):** ~~the backend must reject a spec-invalid
  phone value when called directly.~~ Rejected because no spec or architecture text assigns
  enforcement responsibility to a specific layer. Unlike FR-08 (`README.md` line 107, which
  explicitly says "Backend phải tự tính lại..."), FR-04 names no layer. Asserting "backend
  must reject" as the expected result would source the oracle from an unsupported inference,
  not from the spec itself — not defensible if challenged.
- **Reframing (adopted, no assumption needed):** drop the layer-specific claim. The spec does
  define what a *valid* phone value is (line 65); that definition is used directly as the
  oracle for an **end-to-end, path-agnostic** outcome: *a phone value that violates the spec's
  format must never end up persisted in the `users` table, regardless of which entry path
  (browser form vs. direct API call) was used to submit it.* This requires no assumption about
  which layer is responsible — only that the system, taken as a whole, must not end up in a
  state that contradicts the spec's definition of "valid." Test cases against this reframed
  target are two independent, spec-sourced checks (not a single backend-must-reject claim):
  1. **UI-path check:** does the frontend accept a spec-*valid* value (e.g. `0912345678`) and
     reject a spec-*invalid* one, per line 65? (Exposes the frontend/spec mismatch directly —
     `source: spec` for the definition, `source: impl` for the observed regex, no assumption.)
  2. **API-path check:** does a direct `PUT /api/users/me` call with a spec-invalid phone
     value end up persisted? This is reported as an **observation** of whether the SUT enforces
     its own stated validity rule end-to-end — not framed as "backend must do X," but as "does
     any part of the system uphold what `README.md` line 65 defines as valid?"
- **Metadata:** `{ source: spec, confidence: HIGH, status: rejected }` (original claim);
  reframed target is captured directly in the `phone` variable's Oracle field in
  `testing-model.md` — no separate assumption record needed for it.
