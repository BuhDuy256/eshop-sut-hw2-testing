# bug-report-drafts.md — FR-15 Product Management CRUD

> Drafted via `bug-reporting` Stages 1–5 from `work/FR-15-product-crud/execution-results.md`.
> Stage 1 (confirm real vs. test/setup artifact) and Stage 2 (grouping) were applied in chat
> and confirmed by the human ("There are real defects.", 2026-07-06) before drafting. All 7
> groups are `spec`-grounded (Stage 4) — none rest on an assumption as the behavioral oracle
> (Assumption A1 was used only to pick the concrete BVA value `1`, not as the oracle itself).
> Evidence: shared raw capture
> `out/reports/FR-15-product-crud/bug-reports/evidence/fr15-raw-execution-log.txt`
> (API-level, no browser involved except `BUG-15-007`), referenced per bug by its `===` marker.

## BUG-15-001

| Field | Value |
|---|---|
| **ID** | `BUG-15-001` |
| **Title** | `name` has zero server-side validation — empty, absent, and over-255-character values all persist |
| **Ref** | `TC-15-EP-002`/`ER-15-EP-002`, `TC-15-EP-003`/`ER-15-EP-003`, `TC-15-BVA-003`/`ER-15-BVA-003` |
| **Severity** | Medium — a data-integrity defect in the product catalog (blank, `null`, or 256+ character names persist and are returned by `GET /api/products`), degrading customer-facing display data. No security boundary or financial value is affected; not classified higher. |
| **Priority** | Medium — reachable only by an actor bypassing the admin form's client-side `required` (a direct API call), not by normal UI use. |
| **Expected** | Per `README.md` FR-15 line 195 (`name`: bắt buộc, tối đa 255 ký tự): a `name` that is empty, absent, or exceeds 255 characters must not end up persisted as given. `expected_source`: `spec`. |
| **Actual** | Three distinct invalid inputs were each accepted and persisted verbatim: `name:""` → persisted as `""` (id 7); `name` key omitted → persisted as `null` (id 8); a 256-character string → persisted at full length 256 (id 19). All confirmed via a follow-up `GET`. |
| **Repro steps** | 1. Login as admin. 2. `POST /api/products` with `name:""` (or omit `name`, or send a 256-char string), valid `price`/`category_id`. 3. `GET /api/products/:id` for the returned id — observe the invalid `name` persisted unchanged. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` `POST`/`PUT /api/products` (lines 167–189) bind `name` straight into the SQL statement with no check; `products.name` (database.js line 66) has no `NOT NULL`/`CHECK` constraint. |
| **Evidence** | `fr15-raw-execution-log.txt`, sections `TC-15-EP-002`, `TC-15-EP-003`, `TC-15-BVA-003` (raw request/response, API-level). |
| **Status** | `approved` — promoted to `out/reports/FR-15-product-crud/bug-reports/report.md`, filed as [#10](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/10). |

## BUG-15-002

| Field | Value |
|---|---|
| **ID** | `BUG-15-002` |
| **Title** | `price` has zero server-side validation — negative and zero values both persist |
| **Ref** | `TC-15-EP-004`/`ER-15-EP-004`, `TC-15-BVA-004`/`ER-15-BVA-004`, `TC-15-BVA-005`/`ER-15-BVA-005` |
| **Severity** | High — `price` is core transactional catalog data; a negative or zero value corrupts the one field that customer-facing product display, cart totals, and the admin revenue dashboard (`README.md` FR-13, line 183) would all read from. Proven mechanism is limited to **persistence**: this pass did not execute a cart/checkout flow against one of these corrupted products, so no end-to-end financial-loss chain is claimed as demonstrated — only that invalid pricing data enters and stays in the system with no server-side gate at all. |
| **Priority** | High. |
| **Expected** | Per `README.md` FR-15 line 196 (`price`: bắt buộc, phải là số dương `> 0`): a `price ≤ 0` must not end up persisted. `expected_source`: `spec`. |
| **Actual** | `price:-500000` → persisted as `-500000` (id 9). `price:-1` → persisted as `"-1"` (id 20, id-parity string coercion, value still -1). `price:0` → persisted as `0` (id 21). All confirmed via a follow-up `GET`. |
| **Repro steps** | 1. Login as admin. 2. `POST /api/products` with `price:-1` (or `0`, or any negative number), valid `name`/`category_id`. 3. `GET /api/products/:id` — observe the invalid `price` persisted unchanged. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` `POST`/`PUT /api/products` bind `price` straight into the SQL statement with no check; `products.price` (database.js line 67) is `INTEGER` with no `CHECK (price > 0)`. |
| **Evidence** | `fr15-raw-execution-log.txt`, sections `TC-15-EP-004`, `TC-15-BVA-004`, `TC-15-BVA-005`. |
| **Status** | `approved` — promoted to `out/reports/FR-15-product-crud/bug-reports/report.md`, filed as [#11](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/11). |

## BUG-15-003

| Field | Value |
|---|---|
| **ID** | `BUG-15-003` |
| **Title** | `category_id` is never checked against existing categories — a nonexistent id persists |
| **Ref** | `TC-15-EP-005`/`ER-15-EP-005`, `TC-15-BVA-009`/`ER-15-BVA-009` |
| **Severity** | Medium — a dangling-reference data-integrity defect (a product can reference a category that does not exist), likely to affect category-filtered browsing; that downstream surface was not itself executed in this pass, so no broken-browsing behavior is claimed as proven, only the dangling reference itself. |
| **Priority** | Medium. |
| **Expected** | Per `README.md` FR-15 line 197 (`category_id`: bắt buộc, phải chọn từ danh sách có sẵn): a `category_id` not matching an existing category must not end up persisted. `expected_source`: `spec`. |
| **Actual** | `category_id:999` → persisted as `999` (id 10). `category_id:4` (one past the seeded set `{1,2,3}`) → persisted as `4` (id 25). Both confirmed via a follow-up `GET`; no category with either id exists (`GET /api/categories` returns only ids 1–3). |
| **Repro steps** | 1. Login as admin. 2. `POST /api/products` with `category_id:999` (or `4`), valid `name`/`price`. 3. `GET /api/products/:id` — observe the nonexistent `category_id` persisted unchanged. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` `POST`/`PUT /api/products` bind `category_id` straight into the SQL statement with no existence check; no `FOREIGN KEY` from `products.category_id` to `categories.id` (database.js lines 64–71). |
| **Evidence** | `fr15-raw-execution-log.txt`, sections `TC-15-EP-005`, `TC-15-BVA-009`. |
| **Status** | `approved` — promoted to `out/reports/FR-15-product-crud/bug-reports/report.md`, filed as [#12](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/12). |

## BUG-15-004

| Field | Value |
|---|---|
| **ID** | `BUG-15-004` |
| **Title** | `POST /api/products` has no access control — any actor, authenticated or not, admin or not, can create products |
| **Ref** | `TC-15-EP-006`/`ER-15-EP-006`, `TC-15-EP-007`/`ER-15-EP-007` |
| **Severity** | Critical — a security boundary explicitly required by `README.md` FR-12 (lines 176–179) and `SEC-02`/`SEC-03` is completely absent for this endpoint: evidence proves both a fully unauthenticated request and a request authenticated as a non-admin (`role:user`) succeed identically to an admin request, with no compensating control anywhere in the route. |
| **Priority** | P1. |
| **Expected** | Per `README.md` FR-12 lines 176–179 + `SEC-02`/`SEC-03`: `POST /api/products` must require (1) a valid JWT and (2) `role='admin'` in that token; a request failing either must be rejected with no product created. `expected_source`: `spec`. |
| **Actual** | A `POST /api/products` request with **no** `Authorization` header succeeded (`200`, product id 11 created). A separate request with a valid `test@eshop.com` JWT (`role:user`) also succeeded (`200`, product id 12 created). Both confirmed present via a follow-up `GET /api/products`. |
| **Repro steps** | 1. `POST /api/products` with a valid body and **no** `Authorization` header — observe `200` and a new product id. 2. Separately, login as a non-admin user and repeat with that user's JWT — observe the same. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` line 167, `POST /api/products` — no middleware at all (not even `authenticateToken`, which exists and is used elsewhere in the same file, e.g. line 112). |
| **Evidence** | `fr15-raw-execution-log.txt`, sections `TC-15-EP-006`, `TC-15-EP-007`. |
| **Status** | `approved` — promoted to `out/reports/FR-15-product-crud/bug-reports/report.md`, filed as [#13](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/13). |

## BUG-15-005

| Field | Value |
|---|---|
| **ID** | `BUG-15-005` |
| **Title** | `PUT /api/products/:id` has no access control — any unauthenticated actor can overwrite any product |
| **Ref** | `TC-15-EP-008`/`ER-15-EP-008` |
| **Severity** | Critical — same security-boundary violation as `BUG-15-004`, on the Update route specifically; proven to allow an unauthenticated actor to silently overwrite an existing product's `name`/`price`/all fields (demonstrated: renamed to `"HACKED"`, price set to `1`). Kept as a separate report from `BUG-15-004` because the fix is a separate code change (middleware added to a different route), even though the defect class is the same. |
| **Priority** | P1. |
| **Expected** | Per `README.md` FR-12 lines 176–179 + `SEC-02`/`SEC-03`: `PUT /api/products/:id` must require a valid JWT with `role='admin'`; otherwise reject with no update applied. `expected_source`: `spec`. |
| **Actual** | `PUT /api/products/13` with **no** `Authorization` header, body `{"name":"HACKED","price":1,...}` → `200 {"message":"Product updated"}`. `GET /api/products/13` confirmed the product's `name`/`price` were overwritten to `"HACKED"`/`1`. |
| **Repro steps** | 1. Create a product as admin (or use any existing id). 2. `PUT /api/products/:id` with **no** `Authorization` header and an arbitrary body. 3. `GET /api/products/:id` — observe the product was overwritten. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` line 179, `PUT /api/products/:id` — no middleware at all. |
| **Evidence** | `fr15-raw-execution-log.txt`, section `TC-15-EP-008`. |
| **Status** | `approved` — promoted to `out/reports/FR-15-product-crud/bug-reports/report.md`, filed as [#14](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/14). |

## BUG-15-006

| Field | Value |
|---|---|
| **ID** | `BUG-15-006` |
| **Title** | `DELETE /api/products/:id` has no access control — any unauthenticated actor can delete any product |
| **Ref** | `TC-15-EP-009`/`ER-15-EP-009` |
| **Severity** | Critical — same security-boundary violation as `BUG-15-004`/`005`, on the Delete route; proven to allow an unauthenticated actor to permanently remove an existing product. Kept separate for the same independent-fix reasoning as `BUG-15-005`. |
| **Priority** | P1. |
| **Expected** | Per `README.md` FR-12 lines 176–179 + `SEC-02`/`SEC-03`: `DELETE /api/products/:id` must require a valid JWT with `role='admin'`; otherwise reject with no deletion applied. `expected_source`: `spec`. |
| **Actual** | `DELETE /api/products/14` with **no** `Authorization` header → `200 {"message":"Product deleted"}`. `GET /api/products/14` afterward returned `{}` — the product no longer exists. |
| **Repro steps** | 1. Create a product as admin (or use any existing id). 2. `DELETE /api/products/:id` with **no** `Authorization` header. 3. `GET /api/products/:id` — observe the product is gone. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` line 191, `DELETE /api/products/:id` — no middleware at all. |
| **Evidence** | `fr15-raw-execution-log.txt`, section `TC-15-EP-009`. |
| **Status** | `approved` — promoted to `out/reports/FR-15-product-crud/bug-reports/report.md`, filed as [#15](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/15). |

## BUG-15-007

| Field | Value |
|---|---|
| **ID** | `BUG-15-007` |
| **Title** | Admin panel's edit form overwrites every visible product's displayed name, not just the edited one |
| **Ref** | `TC-15-EP-011`/`ER-15-EP-011` |
| **Severity** | Medium — a UI-only correctness defect (the backend's own stored data is correctly isolated, per `ER-15-EP-010` PASS): after editing one product's name in the admin panel, every other product row in the same session's local list is redrawn with the edited product's new name, until the next full refetch/reload. This could mislead an admin into believing multiple products were renamed and acting on that incorrect belief, but self-corrects on any refresh and never reaches the backend. |
| **Priority** | Medium. |
| **Expected** | Per `README.md` FR-15 line 198 ("Khi Sửa một sản phẩm, chỉ sản phẩm đó bị thay đổi — các sản phẩm khác giữ nguyên"): editing one product must leave every other product's displayed data unchanged. `expected_source`: `spec`. |
| **Actual** | Executed the literal `handleProductSubmit` state-update expression (`frontend-admin/src/App.jsx` lines 110–113) via `node -e` against a two-product fixture. `products.map(p => ({...p, name: productForm.name}))` overwrote **both** products' `name` to the edited product's new name — including the untouched sibling (id 16) — in the array passed to `setProducts()`. |
| **Repro steps** | 1. Log into the admin panel with at least 2 products visible. 2. Edit one product's name and submit. 3. Without reloading, observe every other product row now displays the same (edited) name. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `frontend-admin/src/App.jsx` lines 108–115: the edit branch of `handleProductSubmit` issues a correct, properly-scoped `PUT` (server-side isolation holds, see `ER-15-EP-010`), then locally computes `products.map(p => ({...p, name: productForm.name}))` and calls `setProducts(...)` with it — applying the edited product's new name to every product in local state — and does not call `fetchData()` afterward in this branch (unlike the create branch, line 118, which does refetch). |
| **Evidence** | `fr15-raw-execution-log.txt` does not cover this case (no HTTP request involved); evidence is the `node -e` execution transcript shown in `work/FR-15-product-crud/execution-results.md`, `ER-15-EP-011` row — a **code-execution capture**, not a browser screenshot, since no browser-automation tool was available in this environment. |
| **Status** | `approved` — promoted to `out/reports/FR-15-product-crud/bug-reports/report.md`, filed as [#16](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/16). |

## Human gate: `approve → file`

- [x] Approve `BUG-15-001` (name validation missing) → filed [#10](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/10)
- [x] Approve `BUG-15-002` (price validation missing) → filed [#11](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/11)
- [x] Approve `BUG-15-003` (category_id validation missing) → filed [#12](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/12)
- [x] Approve `BUG-15-004` (POST no access control) → filed [#13](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/13)
- [x] Approve `BUG-15-005` (PUT no access control) → filed [#14](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/14)
- [x] Approve `BUG-15-006` (DELETE no access control) → filed [#15](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/15)
- [x] Approve `BUG-15-007` (admin-UI edit-isolation) → filed [#16](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/16)

**Approved 2026-07-06** (all 7, blanket per-report review — user replied "Approve." to the full
set presented; no report was held back). Promoted verbatim to
`out/reports/FR-15-product-crud/bug-reports/report.md`; no technical field (title, severity,
priority, expected, actual, repro, root cause, evidence) was changed between draft and
promoted/filed versions — only each draft's `Status` line below and this gate section were
updated.
