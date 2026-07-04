# testing-model.md — FR-04 Personal Profile Management

## Phase 0 — Feature Discovery (file map)

> Precondition: feature identifier `FR-04` + repo access. Exit criterion: feature fully
> mapped, no touched file omitted (architecture.md Phase 0).

| Layer | File | What it does for FR-04 |
|---|---|---|
| Backend route (read) | `backend/server.js` L112–116 — `GET /api/users/me` | Returns the full `users` row (including `password`, `role`) for the authenticated user. No field filtering. |
| Backend route (write) | `backend/server.js` L118–135 — `PUT /api/users/me` | Updates `name`, `shipping_address`, `phone` unconditionally from `req.body`. **Also updates `role` if `role` is present and truthy in `req.body`** (L124–127) — no server-side allowlist/blocklist on fields. No phone-format validation server-side. `email` is never part of the update query (cannot be changed via this endpoint, matches spec). |
| Auth middleware | `backend/server.js` L100–110 — `authenticateToken` | JWT verification; populates `req.user.id` used by both routes above. No role/ownership check beyond "is this a valid token" — `req.user.id` is taken from the token, so a user can only ever target their own row (no `:id` param on this endpoint), which is consistent with spec ("chỉ có thể cập nhật hồ sơ của chính mình"). |
| Frontend page | `frontend-web/src/pages/Profile.jsx` | Form for `name`/`phone`/`shipping_address`; `email` rendered `disabled` (UI-only immutability, not enforced server-side — server already excludes it from the update query so this is consistent). Client-side phone regex **`/^[1-9][0-9]{8,9}$/`** (L43) — starts with digit `1-9`, total length 9–10. Also renders order history (out of FR-04 scope, shared page). |
| Auth context | `frontend-web/src/context/AuthContext.jsx` | Fetches `GET /api/users/me` on token change and populates the `user` object consumed by `Profile.jsx`. Note: after a successful `PUT`, `Profile.jsx` does not refresh `AuthContext`'s `user` (no re-fetch, no state update) — the header/other pages may show stale profile data until next reload/login. Logged as an observation, not yet a scoped test target. |

### Discrepancy flagged for the model (code-derived, location only — not oracle)

- **Spec (`README.md` FR-04, line 65):** phone must **start with `0`**, be **10–11 digits**.
- **Frontend impl (`Profile.jsx` L43):** regex requires starting with **`1`–`9`** (not `0`!)
  and total length **9–10** digits.
- **Backend impl:** no phone format validation at all — accepts any string.
- These three sources disagree with each other. Per `docs/implementation-plan/oracle-precedence.md`,
  `README.md` is the oracle; the frontend regex is an implementation detail that may itself be
  a bug (rejecting valid `0xxxxxxxxx` numbers) or may reveal a boundary the backend fails to
  enforce at all (since the backend has zero validation, a request bypassing the browser form —
  e.g. direct API call — can persist any string as `phone`, including no digits at all).

### Forbidden field observed directly in code (feeds the Testing Model's forbidden-field note)

- `role` — spec (`README.md` L67, SEC-06 L283) explicitly forbids client-side role change via
  the profile API. Code confirms the endpoint **will** update `role` if the client includes it
  in the `PUT /api/users/me` body. This is a concrete, code-confirmed forbidden-field target
  for Phase 2 (negative test case), not yet an executed/confirmed defect — execution happens
  in Phase 3.

**Gate: file map complete?** — Yes for the two variables and the one forbidden field this
pilot targets (`name`, `phone`, `shipping_address`, forbidden: `role`, immutable: `email`).
No further backend/frontend file touches FR-04's update path.

---

## Phase 1 — Testing Model (variables)

### Variable: `name`

| Field | Value |
|---|---|
| **Domain** | Non-empty string (per [[A2]]), unbounded length (per [[A1]]). |
| **Boundary + relation** | No spec-stated length boundary. Empty string (`""`) is the one
  concrete boundary this pilot tests (invalid, per A2). |
| **Source** | `spec` (mandatory field, FR-01/FR-04) for "must be non-empty" (via A2); no
  source for a length boundary (gap, see A1). |
| **Validation rule** | Must not be empty. No length ceiling enforced anywhere in the SUT. |
| **Oracle** | `README.md` FR-04 line 64 (name is a manageable profile field) + [[A2]] (accepted
  2026-07-04). |
| **Metadata** | `{ source: spec, confidence: MED, status: accepted }` |

### Variable: `phone`

| Field | Value |
|---|---|
| **Domain** | String representing a VN phone number. |
| **Boundary + relation (spec)** | Must start with `0`; length 10–11 digits. BVA boundaries: 9
  digits (invalid, too short), 10 digits (valid, min), 11 digits (valid, max), 12 digits
  (invalid, too long); first digit `0` (valid) vs `!= 0` (invalid). `source: spec` — `README.md`
  FR-04 line 65. |
| **Boundary + relation (impl, frontend)** | Frontend regex `^[1-9][0-9]{8,9}$` — starts with
  `1`–`9` (never `0`), length 9–10 digits total. **Directly contradicts the spec boundary
  above** (e.g. a spec-valid `0912345678` is rejected client-side; a spec-invalid
  `912345678` — no leading `0`, 9 digits — is accepted client-side). `source: impl` —
  `frontend-web/src/pages/Profile.jsx` line 43. |
| **Boundary + relation (impl, backend)** | No validation at all — any string is persisted.
  `source: impl` — `backend/server.js` `PUT /api/users/me`. |
| **Validation rule** | A value matching `^0[0-9]{9,10}$` is spec-valid; anything else is
  spec-invalid (`README.md` line 65). No layer is named as responsible for enforcing this —
  see [[A4]] (original "backend must enforce" assumption **rejected**, reframed below). |
| **Oracle (reframed, path-agnostic — no assumption needed)** | `README.md` FR-04 line 65
  defines validity directly; that definition is used as the oracle for an end-to-end outcome
  that names no specific layer: *a spec-invalid phone value must never end up persisted in the
  `users` table, regardless of entry path.* Two independent, spec-sourced checks follow from
  this, neither requiring [[A4]]: (1) **UI-path** — does the frontend accept a spec-valid value
  and reject a spec-invalid one? (2) **API-path** — does a direct API call with a spec-invalid
  value get persisted? Both are reported against the same spec citation; the API-path result is
  an *observation of whether the SUT upholds its own stated rule end-to-end*, not a claim about
  which layer "should" have blocked it. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` (the spec validity
  definition, line 65 — always was directly spec-sourced, independent of A4); `{ source: impl,
  confidence: HIGH, status: accepted }` (the frontend regex and backend no-validation facts,
  logged as observations, not oracles). |

### Variable: `shipping_address`

| Field | Value |
|---|---|
| **Domain** | Free-form string. |
| **Boundary + relation** | No spec-stated boundary. Empty string is the one concrete boundary
  tested (valid, per [[A3]]). |
| **Source** | `impl` (no `required` attribute; DB allows empty/`NULL`) for "empty is valid",
  via A3. |
| **Validation rule** | None stated by spec; no format/length constraint anywhere in the SUT. |
| **Oracle** | [[A3]] (accepted 2026-07-04). |
| **Metadata** | `{ source: impl, confidence: MED, status: accepted }` |

### Forbidden field: `role`

| Field | Value |
|---|---|
| **Rule** | A user must not be able to change their own `role` via the profile-update API. |
| **Source** | `spec` — `README.md` line 67 ("không thể tự thay đổi thuộc tính `role`") and
  SEC-06 (line 283, security requirement list). |
| **Code-derived note (location only, not oracle)** | `backend/server.js` L118–135 **will**
  update `role` if the client includes a truthy `role` field in the `PUT /api/users/me` body —
  confirmed by reading the code to locate the test target, per architecture.md §2.1. |
| **Oracle** | `README.md` line 67 / SEC-06: a `role` field in the request body must have no
  effect on the stored `role`, regardless of what value is sent. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` — no ambiguity; both the
  behavioral rule and the security requirement independently state the same constraint. |

### Immutable field: `email`

| Field | Value |
|---|---|
| **Rule** | `email` cannot be changed through this feature. |
| **Source** | `spec` — `README.md` line 66 ("Email không được phép thay đổi qua giao diện."). |
| **Code-derived note (location only, not oracle)** | `backend/server.js`'s update query never
  includes `email`, so even a client-supplied `email` in the request body has no effect —
  consistent with the spec regardless of the code. |
| **Oracle** | `README.md` line 66: an `email` field in the request body must have no effect on
  the stored `email`. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |

## Human review

- [x] **Gate: `completeness_confirmed`** — checklist:
  - [x] Domain complete for `name`, `phone`, `shipping_address`
  - [x] Boundary complete (spec-derived **and** impl-derived boundaries both present for `phone`)
  - [x] Oracle frozen or backed by an accepted assumption
  - [x] Assumptions logged and reviewed (`work/FR-04-personal-profile/assumptions.md`):
    A1 accepted, A2 accepted, A3 accepted, **A4 rejected as originally drafted and reframed**
    (no defensible spec/architecture evidence for "backend must enforce" — replaced with a
    path-agnostic, directly spec-sourced oracle requiring no assumption; see `phone` variable
    above and `assumptions.md`).
  - [x] Forbidden field present (`role`, SEC-06)
  - [x] Immutable field present (`email`)

  **Approved 2026-07-04**, contingent on the A4 reframing above.
