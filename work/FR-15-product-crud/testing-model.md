# testing-model.md — FR-15 Product Management CRUD

## Phase 0 — Feature Discovery (file map)

> Precondition: feature identifier `FR-15` + repo access. Exit criterion: feature fully
> mapped, no touched file omitted (architecture.md Phase 0).

| Layer | File | What it does for FR-15 |
|---|---|---|
| Backend route (read) | `backend/server.js` L141–157 — `GET /api/products` | Lists all products; supports `?search=` (raw string-interpolated SQL — a SQL-injection shape). No auth. **Search/listing is not FR-15's own spec text** (closer to FR-02/03, unassigned) — noted, not modeled here. |
| Backend route (read) | `backend/server.js` L159–165 — `GET /api/products/:id` | Returns one product row. No auth. `if (row.id % 2 === 0) row.price = row.price.toString();` — `price` is a string for even ids, a number for odd ids. This is FR-15's own "Xem" (View) path. |
| Backend route (write) | `backend/server.js` L167–177 — `POST /api/products` | Inserts `name, price, description, imageUrl, category_id` verbatim from `req.body`. **No middleware at all.** |
| Backend route (write) | `backend/server.js` L179–189 — `PUT /api/products/:id` | Updates the same 5 fields, scoped by `WHERE id = ?` (single-row SQL scope). **No middleware at all.** |
| Backend route (write) | `backend/server.js` L191–196 — `DELETE /api/products/:id` | Deletes by id. **No middleware at all.** |
| Auth middleware (exists, unused here) | `backend/server.js` L100–110 — `authenticateToken` | Used elsewhere (e.g. `GET /api/users/me`); **not attached to any of the 3 write routes above.** No route in `server.js` checks `req.user.role` anywhere — role-based authorization is not implemented as a concept in this backend. |
| DB schema | `backend/database.js` L64–71 — `products` table | `id, name TEXT, price INTEGER, description TEXT, imageUrl TEXT, category_id INTEGER`. No `NOT NULL`, no `CHECK`, no `FOREIGN KEY` to `categories`. |
| DB schema + seed | `backend/database.js` L23–26, L83–88 — `categories` table | 3 seeded rows: `1=Điện thoại, 2=Laptop, 3=Phụ kiện`. |
| DB seed | `backend/database.js` L97–103 — product seed | 5 seeded products, ids 1–5 (ids 2, 4 hit the price-as-string anomaly above). |
| Admin frontend | `frontend-admin/src/App.jsx` L95–160, L480–545 — product form + handlers | `name` input has `required` (client-side only), no `maxLength`. `price` input is `type="number"`, no `min`, **no `required`** either. `category_id` is a `<select>` populated only from live `GET /api/categories` rows (structurally can't submit a non-existent id through this UI, but a direct API call bypasses it). `handleProductSubmit` edit branch (L108–115): does a real `PUT`, then sets `products` state to `products.map(p => ({...p, name: productForm.name}))` — applies the edited name to every product in local UI state, without calling `fetchData()` afterward (unlike the create branch, L118, which does refetch). |
| Spec — access control | `README.md` L172–179 — FR-12 "Kiểm soát truy cập" | Directly names `POST/PUT/DELETE /api/products` (by literal path) as requiring (1) a valid JWT and (2) `role='admin'` in the token. Cited here only because it names FR-15's own endpoints, not because FR-12 itself is being tested (same pattern as FR-04's use of SEC-06). |
| Spec — security requirements | `README.md` L274–284 — §9, `SEC-02` / `SEC-03` | `SEC-02`: security-sensitive APIs require a valid JWT. `SEC-03`: Admin APIs must check `role='admin'`, not just token presence. Corroborates FR-12 for the same 3 endpoints. |

**Gate: file map complete?** — Yes for the three constrained fields (`name`, `price`,
`category_id`), the actor/role forbidden state on the 3 write endpoints, and the
edit-isolation postcondition. `GET` routes (list/detail) are read-only "Xem" and are not an
access-control target — FR-12 line 177 names only the 3 write routes, not the 2 read routes.
No further backend/admin-frontend file touches FR-15's CUD path.

---

## Phase 1 — Testing Model (variables)

### Variable: `name`

| Field | Value |
|---|---|
| **Domain** | String. |
| **Boundary + relation (spec)** | Required (non-empty); max **255** characters, inclusive (255 valid, 256 invalid). `source: spec` — `README.md` FR-15 line 195 ("Tên sản phẩm: bắt buộc, tối đa 255 ký tự."). |
| **Boundary + relation (impl, backend)** | None enforced. `POST`/`PUT` bind `name` straight into a parameterized `INSERT`/`UPDATE`; DB column is `TEXT` with no `NOT NULL`/`CHECK` (database.js L64–71). An empty string, a missing field, or an arbitrarily long string are all accepted and persisted as-is. `source: impl`. |
| **Boundary + relation (impl, admin frontend)** | `<input>` has `required` (blocks empty submission **through this UI form only**); no `maxLength` — the 255-char ceiling is not enforced anywhere client-side either. `source: impl` — `frontend-admin/src/App.jsx` line 498. |
| **Validation rule** | Must be non-empty and ≤255 characters (`README.md` line 195). |
| **Oracle** | `README.md` FR-15 line 195 → a `name` value that is empty or exceeds 255 characters must not end up persisted as a product's name. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |

### Variable: `price`

| Field | Value |
|---|---|
| **Domain** | Number (VND), positive. |
| **Boundary + relation (spec)** | Required; must be **> 0** (exclusive lower bound). `source: spec` — `README.md` FR-15 line 196 ("Giá: bắt buộc, phải là số dương (> 0)."). |
| **Boundary + relation (impl, backend)** | None enforced. No `NOT NULL`, no `CHECK > 0`; column declared `INTEGER` (database.js L67). `POST`/`PUT` persist whatever value arrives — negative, zero, missing (binds `NULL`), or a non-numeric string SQLite may coerce. `source: impl`. |
| **Boundary + relation (impl, admin frontend)** | `<input type="number">`, no `min`, and **no `required`** attribute (unlike `name`) — this form can submit an empty, zero, or negative price. `source: impl` — `App.jsx` lines 500–508. |
| **Validation rule** | Must be a positive number (`> 0`). |
| **Oracle** | `README.md` FR-15 line 196 → a `price` value `≤ 0` (or absent/non-numeric) must not end up persisted as a product's price. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |
| **Open question (see [[assumptions#A1]])** | The DB column's declared type is `INTEGER` (`source: impl`) — raises a BVA-granularity question (what counts as "just above 0"?), resolved as Assumption A1, not folded into this entry's oracle. |

### Variable: `category_id`

| Field | Value |
|---|---|
| **Domain** | Integer referencing `categories.id`. |
| **Boundary + relation (spec)** | Required; must be selected from the available category list — an enum-type boundary over whatever `categories.id` values currently exist (seeded: `1, 2, 3`). `source: spec` — `README.md` FR-15 line 197 ("Danh mục: bắt buộc, phải chọn từ danh sách có sẵn."). |
| **Boundary + relation (impl, backend)** | None enforced. No `FOREIGN KEY` from `products.category_id` to `categories.id` (database.js L64–71), no existence check in `POST`/`PUT`. Any integer, non-integer, or missing value is persisted verbatim. `source: impl`. |
| **Boundary + relation (impl, admin frontend)** | `<select>` populated only from live `GET /api/categories` rows — this UI form structurally cannot submit a category id outside the current list, but a direct API call bypasses it entirely. `source: impl` — `App.jsx` lines 528–543. |
| **Validation rule** | Must be present and must equal the `id` of an existing category row. |
| **Oracle** | `README.md` FR-15 line 197 → a `category_id` that is absent or does not match an existing category must not end up persisted as a product's category. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |
| **Explicit exclusion** | Category **deletion** cascading into products that reference it (an FR-14 Category-CRUD operation's side effect) is out of scope for FR-15 — noted, not modeled, per the same feature-boundary discipline as the FR-09 correction on FR-08. |

### Forbidden state: Actor/role for Create/Update/Delete

| Field | Value |
|---|---|
| **Rule** | Only an actor holding a valid JWT with `role = 'admin'` may create, update, or delete a product; every other actor state must be rejected. |
| **Source** | `README.md` FR-15 line 193 ("Admin có thể Thêm/Sửa/Xóa sản phẩm") states *who* may act. `README.md` FR-12 lines 176–179 ("Kiểm soát truy cập") **directly names** `POST/PUT/DELETE /api/products` as one of the data-affecting Admin APIs requiring (1) a valid JWT and (2) `role='admin'` in the token — not merely token existence. Corroborated by §9 `SEC-02` (line 279) and `SEC-03` (line 280). FR-12/SEC-02/SEC-03 are cited only because they name FR-15's own endpoints by literal path — the same pattern FR-04 used for `SEC-06` — not because FR-12 is itself being tested as a feature. |
| **Domain (actor state reaching these 3 endpoints)** | `{ no Authorization header, present-but-invalid/expired JWT, valid JWT with role='user', valid JWT with role='admin' }` — kept as 4 distinct classes because the spec (FR-12 + SEC-02/SEC-03) assigns each a different required outcome, even though the code (below) does not distinguish them. |
| **Code-derived note (location only, not oracle)** | `backend/server.js` lines 167, 179, 191 — none of the 3 routes carry any middleware (not even `authenticateToken`, which exists and is used elsewhere, e.g. `GET /api/users/me` L112). No route anywhere in `server.js` checks `req.user.role`. All 4 actor states above reach the same unguarded handler. |
| **Validation rule** | The first three actor states must be rejected (no persisted change); only the fourth (valid admin JWT) may proceed. |
| **Oracle** | `README.md` FR-12 lines 176–179 + `SEC-02`/`SEC-03` → a create/update/delete request without a valid JWT, or with a valid JWT whose role is not `admin`, must not result in a persisted product change. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` — direct citation, no assumption needed. |
| **Note on `GET` routes** | FR-12 line 177 names only the 3 write routes, not the 2 read routes. "View" (part of FR-15's "Thêm/Xem/Sửa/Xóa") is therefore **not** modeled as an access-control target — the read routes being open to any actor is consistent with the spec, not a gap. |

### Variable: Edit-isolation postcondition

| Field | Value |
|---|---|
| **Domain** | The full `products` collection, before vs. after a `PUT /api/products/:id` call for one target id. |
| **Boundary + relation** | Presence/absence-of-change boundary — every product other than the target id must be unchanged before vs. after the edit. |
| **Source** | `spec` — `README.md` FR-15 line 198 ("Khi Sửa một sản phẩm, chỉ sản phẩm đó bị thay đổi — các sản phẩm khác giữ nguyên."). |
| **Validation rule** | After `PUT /api/products/:id`, a subsequent read of every other product must return the same values it had before the edit. |
| **Oracle** | `README.md` FR-15 line 198 → only the targeted product's row changes; all sibling products remain unchanged — checked both by a direct re-read of the backend data and by what the admin UI displays. |
| **Code-derived note, second enforcement path (not oracle)** | (1) **Backend** — the `PUT` handler (server.js L179–189) scopes its `UPDATE` with `WHERE id = ?` bound to the single target id; by construction this path only ever touches one row. (2) **Admin frontend** — `handleProductSubmit`'s edit branch (`App.jsx` L108–115) issues the real `PUT`, then computes `products.map(p => ({...p, name: productForm.name}))` and calls `setProducts(...)` with it — applying the *edited* product's new `name` to **every** product currently held in the admin panel's local state, without calling `fetchData()` afterward in this branch (the create branch, L118, does refetch). The two paths disagree: the backend's stored data is correctly isolated; the admin UI's displayed list is not, until the next full refetch. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |

---

## Assumptions

See `assumptions.md` for the full entries and Stage-2 disposition. Summary: **A1 accepted**
(price BVA granularity), **A2 rejected** (price-as-string response-type claim — no citation,
no defensible reframing; logged as an observation, not a modeled oracle).

## Human review

- [ ] **Gate: `completeness_confirmed`** — checklist:
  - [ ] Domain complete for `name`, `price`, `category_id`
  - [ ] Boundary complete (spec-derived **and** impl-derived boundaries present for all three)
  - [ ] Oracle frozen or backed by an accepted assumption for every entry
  - [ ] Assumptions logged and reviewed (A1 accepted, A2 rejected)
  - [ ] Forbidden state present (actor/role for CUD, citing FR-12 + SEC-02/SEC-03)
  - [ ] Edit-isolation postcondition present, both enforcement paths recorded
  - [ ] Scope check: no FR-16, no product search/listing, no FR-14 category-deletion cascade
    folded in

  **Pending human approval.**
