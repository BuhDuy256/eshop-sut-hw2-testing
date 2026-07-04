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

*(to be completed next: domain, boundary + relation + source, validation, oracle, metadata for
`name`, `phone`, `shipping_address`; forbidden/immutable fields `role`, `email`)*
