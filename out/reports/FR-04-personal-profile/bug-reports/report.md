# FR-04 — Bug Report

> **Update 2026-07-04 (Continuation environment-integration task):** all 4 bugs below were
> originally approved and promoted with local evidence only — `gh` CLI was unavailable at the
> time (see `docs/implementation-plan/blockers.md`, 0.2). That blocker has since resolved
> (`gh` is now installed/authenticated, and GitHub Issues are enabled on the repository — see
> the FR-08 report and `blockers.md`'s addendum). All 4 have now been filed verbatim as GitHub
> issues #6–#9, with no change to any technical content — only the `GitHub Issue` field per
> bug was added/updated.

## BUG-04-004 — Role injection via profile update (CRITICAL)

| Field | Value |
|---|---|
| **Severity** | Critical |
| **Priority** | P0 |
| **Ref** | `TC-04-EP-005` (`out/reports/FR-04-personal-profile/domain-testing/report.md`) |
| **GitHub Issue** | [#6](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/6) — filed 2026-07-04 after Issues were enabled on the repository. |

**Expected** (per `README.md` line 67 + SEC-06, line 283): a `role` field in the
`PUT /api/users/me` request body must have no effect on the stored `role`.

**Actual:** sending `{"role":"admin", ...}` as a `user`-role account changes the stored `role`
to `admin`, confirmed via `GET /api/users/me`.

**Steps to reproduce:**
1. Login as a `user`-role account.
2. `PUT /api/users/me` with `{"name":"...","phone":"0912345678","shipping_address":"...","role":"admin"}`.
3. `GET /api/users/me` — observe `role: "admin"`.

**Root cause (code-derived, not the oracle):** `backend/server.js` `PUT /api/users/me`:
`if (role) { query += ", role = ?"; params.push(role); }` — conditionally appends an
unrestricted `role` update whenever the client includes a truthy `role` field.

**Evidence:** [`evidence/BUG-04-004-request-response.txt`](evidence/BUG-04-004-request-response.txt)

---

## BUG-04-002 — Backend performs no phone-format validation

| Field | Value |
|---|---|
| **Severity** | High |
| **Priority** | P2 |
| **Ref** | `TC-04-EP-004`, `TC-04-BVA-006/009/010` |
| **GitHub Issue** | [#7](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/7) — filed 2026-07-04 after Issues were enabled on the repository. |

**Expected** (per `README.md` FR-04 line 65, applied path-agnostically — see
`work/FR-04-personal-profile/assumptions.md` A4): a `phone` value violating "bắt đầu bằng số
0, từ 10–11 chữ số" must never end up persisted, regardless of entry path.

**Actual:** `091234567` (9 digits), `091234567890` (12 digits), and `1912345678` (wrong
leading digit) were all persisted verbatim via direct `PUT /api/users/me` calls.

**Steps to reproduce:**
1. Login.
2. `PUT /api/users/me` with `phone: "1912345678"` (or any other spec-invalid value) and valid
   `name`/`shipping_address`.
3. `GET /api/users/me` — observe the invalid value persisted unchanged.

**Root cause (code-derived, not the oracle):** `backend/server.js` `PUT /api/users/me`
destructures `phone` from `req.body` and writes it to the `UPDATE` query with no format check.

**Evidence:** [`evidence/BUG-04-002-request-response.txt`](evidence/BUG-04-002-request-response.txt)

---

## BUG-04-003 — Frontend phone regex contradicts the spec's validity rule

| Field | Value |
|---|---|
| **Severity** | High |
| **Priority** | P2 |
| **Ref** | `TC-04-BVA-001..005` |
| **GitHub Issue** | [#8](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/8) — filed 2026-07-04 after Issues were enabled on the repository. |

**Expected** (per `README.md` FR-04 line 65): values matching `^0[0-9]{9,10}$` (spec-valid)
should be accepted by the form; values not matching it should be rejected.

**Actual:** executed (not read-only): running the literal frontend regex —
`node -e "console.log(/^[1-9][0-9]{8,9}$/.test('<value>'))"`, the exact code from
`Profile.jsx` line 43 — against each boundary value returned `false` for `0912345678` and
`09123456789` (both spec-valid — regex rejects them) and `true` for `1912345678`
(spec-invalid — regex accepts it). See `ER-04-BVA-002/003/005` in
`work/FR-04-personal-profile/execution-results.md` for the full executed set.

**Steps to reproduce:**
1. Open the Profile page in the browser.
2. Enter `0912345678` in the phone field and submit.
3. Observe the client-side alert "Số điện thoại không hợp lệ..." blocking a valid number.
   (Also reproducible headlessly: `node -e "console.log(/^[1-9][0-9]{8,9}$/.test('0912345678'))"`
   → `false`.)

**Root cause (code-derived, not the oracle):** `frontend-web/src/pages/Profile.jsx` line 43
uses a regex pattern unrelated to the spec's rule (wrong leading-digit class, wrong length
window).

**Evidence:** [`evidence/BUG-04-003-request-response.txt`](evidence/BUG-04-003-request-response.txt)

---

## BUG-04-001 — Empty `name` accepted and persisted (assumption-grounded)

| Field | Value |
|---|---|
| **Severity** | Medium |
| **Priority** | P3 |
| **Ref** | `TC-04-EP-002` |
| **GitHub Issue** | [#9](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/9) — filed 2026-07-04 after Issues were enabled on the repository. |
| **Classification note** | **This defect is reported against an accepted assumption
  (`work/FR-04-personal-profile/assumptions.md` A2), not a direct `README.md` FR-04
  citation.** `README.md` states `name` is mandatory **at registration** (FR-01 line 32); FR-04
  (line 64) lists `name` as updatable but does not explicitly restate that an update may not
  blank it out. Distinct in kind from BUG-04-002/003/004 above, which cite `README.md` FR-04
  directly. |

**Expected** (per accepted assumption A2): an empty `name` should not end up persisted.

**Actual:** `PUT /api/users/me` with `name: ""` returns 200; `GET /api/users/me` returns
`name: ""`.

**Steps to reproduce:**
1. Login.
2. `PUT /api/users/me` with `{"name":"","phone":"0912345678","shipping_address":"123 Le Loi"}`.
3. `GET /api/users/me` — observe `name` is now `""`.

**Root cause (code-derived, not the oracle):** `backend/server.js` `PUT /api/users/me`
performs no check on `name` before the `UPDATE` query.

**Evidence:** [`evidence/BUG-04-001-request-response.txt`](evidence/BUG-04-001-request-response.txt)
