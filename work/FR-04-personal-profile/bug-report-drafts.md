# bug-report-drafts.md — FR-04 Personal Profile (Step 4 pilot)

## BUG-04-001 — Empty `name` accepted and persisted (assumption-grounded)

| Field | Value |
|---|---|
| **ID** | `BUG-04-001` |
| **Title** | Profile update accepts and persists an empty `name` with no validation |
| **Ref** | `TC-04-EP-002` / `ER-04-EP-002` |
| **Severity** | Medium — no security/financial impact; a user could end up with a blank display name across the UI (order history, header, etc.), a data-quality issue rather than a spec-breaking one. |
| **Priority** | P3 |
| **`expected_source`** | **`assumption: A2`** (`work/FR-04-personal-profile/assumptions.md`) — **not** a direct spec citation. `README.md` states `name` is mandatory **at registration** (FR-01 line 32: "Người dùng phải cung cấp: Họ Tên, Email, Mật khẩu"); FR-04 (line 64) lists `name` as an updatable field but does not explicitly restate that an update may not blank it out. This defect is reported **as an assumption-grounded finding**, distinct in kind from BUG-04-002/003/004, which cite `README.md` FR-04 directly. If this classification is not acceptable for grading purposes, the alternative is to not report it as a confirmed defect and instead log it purely as a coverage gap in the domain-testing report. |
| **Expected** | Per accepted assumption A2: an empty `name` should not end up persisted. |
| **Actual** | `PUT /api/users/me` with `name: ""` returns 200; `GET /api/users/me` returns `name: ""`. |
| **Repro steps** | 1. Login. 2. `PUT /api/users/me` with `{"name":"","phone":"0912345678","shipping_address":"123 Le Loi"}`. 3. `GET /api/users/me` — observe `name` is now `""`. |
| **Root cause (code-derived, not the oracle)** | `backend/server.js` `PUT /api/users/me` performs no check on `name` before the `UPDATE` query. |
| **Evidence** | `out/reports/FR-04-personal-profile/bug-reports/evidence/BUG-04-001-request-response.txt` |
| **Status** | `approved` — promoted to `out/reports/FR-04-personal-profile/bug-reports/report.md`. |

## BUG-04-002 — Backend performs no phone-format validation

| Field | Value |
|---|---|
| **ID** | `BUG-04-002` |
| **Title** | `PUT /api/users/me` persists any `phone` value with no format validation |
| **Ref** | `TC-04-EP-004`, `TC-04-BVA-006/009/010` / `ER-04-EP-004`, `ER-04-BVA-006/009/010` |
| **Severity** | High — the spec's stated validity rule for `phone` (`README.md` FR-04 line 65) is completely unenforced anywhere reachable by a direct API call; any string, of any length or format, is stored. |
| **Priority** | P2 |
| **`expected_source`** | `spec` — `README.md` FR-04 line 65, applied path-agnostically (no claim about which layer "should" enforce it — see `work/FR-04-personal-profile/assumptions.md` A4 rejection/reframing). |
| **Expected** | A `phone` value violating "bắt đầu bằng số 0, từ 10–11 chữ số" must never end up persisted, regardless of entry path. |
| **Actual** | All of `091234567` (9 digits), `091234567890` (12 digits), and `1912345678` (wrong leading digit) were persisted verbatim via direct `PUT /api/users/me` calls. |
| **Repro steps** | 1. Login. 2. `PUT /api/users/me` with `phone: "1912345678"` (or any other spec-invalid value) and valid `name`/`shipping_address`. 3. `GET /api/users/me` — observe the invalid value persisted unchanged. |
| **Root cause (code-derived, not the oracle)** | `backend/server.js` `PUT /api/users/me` destructures `phone` from `req.body` and writes it to the `UPDATE` query with no format check. |
| **Evidence** | `out/reports/FR-04-personal-profile/bug-reports/evidence/BUG-04-002-request-response.txt` |
| **Status** | `approved` — promoted to `out/reports/FR-04-personal-profile/bug-reports/report.md`. |

## BUG-04-003 — Frontend phone regex contradicts the spec's validity rule

| Field | Value |
|---|---|
| **ID** | `BUG-04-003` |
| **Title** | Profile form's phone validation rejects every spec-valid number and accepts some spec-invalid ones |
| **Ref** | `TC-04-BVA-001..005` / `ER-04-BVA-001..005` |
| **Severity** | High — a legitimate user cannot save a correctly formatted phone number through the UI at all (every `0`-leading, 10–11-digit number is rejected by the form). |
| **Priority** | P2 |
| **`expected_source`** | `spec` — `README.md` FR-04 line 65. |
| **Expected** | Values matching `^0[0-9]{9,10}$` (spec-valid) should be accepted by the form; values not matching it should be rejected. |
| **Actual** | Frontend regex `^[1-9][0-9]{8,9}$` (`Profile.jsx` line 43) rejects `0912345678` and `09123456789` (both spec-valid) and accepts `1912345678` (spec-invalid). |
| **Repro steps** | 1. Open the Profile page in the browser. 2. Enter `0912345678` in the phone field and submit. 3. Observe the client-side alert "Số điện thoại không hợp lệ..." blocking a valid number. (Also reproducible headlessly: `node -e "console.log(/^[1-9][0-9]{8,9}$/.test('0912345678'))"` → `false`.) |
| **Root cause (code-derived, not the oracle)** | `frontend-web/src/pages/Profile.jsx` line 43 uses a regex pattern unrelated to the spec's rule (wrong leading-digit class, wrong length window). |
| **Evidence** | `out/reports/FR-04-personal-profile/bug-reports/evidence/BUG-04-003-request-response.txt` |
| **Status** | `approved` — promoted to `out/reports/FR-04-personal-profile/bug-reports/report.md`. |

## BUG-04-004 — Role injection via profile update (CRITICAL)

| Field | Value |
|---|---|
| **ID** | `BUG-04-004` |
| **Title** | A `user`-role account can self-promote to `admin` via `PUT /api/users/me` |
| **Ref** | `TC-04-EP-005` / `ER-04-EP-005` |
| **Severity** | Critical — full privilege escalation: any authenticated user can grant themselves admin access to the entire system (admin-only APIs per `README.md` §6 all gate on `role`). |
| **Priority** | P0 |
| **`expected_source`** | `spec` — `README.md` line 67 ("không thể tự thay đổi thuộc tính `role`") + SEC-06 (line 283, "API cập nhật hồ sơ không được cho phép thay đổi trường `role` từ client"). |
| **Expected** | A `role` field in the `PUT /api/users/me` request body must have no effect on the stored `role`. |
| **Actual** | Sending `{"role":"admin", ...}` as a `user`-role account changes the stored `role` to `admin`, confirmed via `GET /api/users/me`. |
| **Repro steps** | 1. Login as a `user`-role account. 2. `PUT /api/users/me` with `{"name":"...","phone":"0912345678","shipping_address":"...","role":"admin"}`. 3. `GET /api/users/me` — observe `role: "admin"`. |
| **Root cause (code-derived, not the oracle)** | `backend/server.js` `PUT /api/users/me`: `if (role) { query += ", role = ?"; params.push(role); }` — conditionally appends an unrestricted `role` update whenever the client includes a truthy `role` field. |
| **Evidence** | `out/reports/FR-04-personal-profile/bug-reports/evidence/BUG-04-004-request-response.txt` |
| **Status** | `approved` — promoted to `out/reports/FR-04-personal-profile/bug-reports/report.md`. |

## Human gate: `approve → file`

- [x] Approve BUG-04-001 (assumption-grounded, Medium) for promotion.
- [x] Approve BUG-04-002 (High) for promotion.
- [x] Approve BUG-04-003 (High) for promotion.
- [x] Approve BUG-04-004 (Critical) for promotion.

  **Note:** `gh` CLI unavailable — local approved draft + evidence only, same fallback as Step 3.

  **Approved 2026-07-04.**
