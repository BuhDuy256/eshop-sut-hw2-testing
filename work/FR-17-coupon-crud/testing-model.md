# testing-model.md — FR-17 Coupon Management CRUD (Admin)

## Phase 0 — Feature Discovery (file map)

> Precondition: feature identifier `FR-17` + repo access. Exit criterion: feature fully
> mapped, no touched file omitted (architecture.md Phase 0).

| Layer | File | What it does for FR-17 |
|---|---|---|
| Backend route (read) | `backend/server.js` L355–360 — `GET /api/coupons` | Lists all coupons (`SELECT * FROM coupons`). Has `authenticateToken` (L356) — requires *some* valid JWT, no role check. This is FR-17's own "Xem" (View) path. |
| Backend route (write) | `backend/server.js` L457–481 — `POST /api/admin/coupons` | Destructures `code, type, discount_value, min_order_amount, expired_at, max_uses_per_user` from `req.body` with **zero validation**, inserts verbatim. `max_uses_per_user || 1` (L474) — falsy values (`0`, `null`, `undefined`, omitted) silently coerced to `1`. Has `authenticateToken` (L457), **no role check**. This is FR-17's "Thêm" (Add) path. |
| Backend route (write) | `backend/server.js` L483–488 — `DELETE /api/admin/coupons/:id` | Deletes by id, unconditionally (no check for existing `coupon_usage` rows referencing it). Has `authenticateToken` (L483), **no role check**. This is FR-17's "Xóa" (Delete) path. |
| No edit route | — | No `PUT /api/admin/coupons/:id` (or any coupon update route) exists anywhere in `server.js`. Consistent with README FR-17 listing only Thêm/Xem/Xóa (no Sửa). Confirmed current, not modeled as a gap. |
| Auth middleware (shared, exists) | `backend/server.js` L100–110 — `authenticateToken` | Returns 401 if no token, 403 if token present but invalid/expired via `jwt.verify`. **Never inspects `req.user.role`** — role-based authorization is not implemented as a concept anywhere in this middleware or in any of the 3 coupon routes. |
| DB schema | `backend/database.js` L29–38 — `coupons` table | `id, code TEXT UNIQUE, type TEXT DEFAULT 'percent', discount_value INTEGER, min_order_amount INTEGER DEFAULT 0, expired_at DATETIME, is_active INTEGER DEFAULT 1, max_uses_per_user INTEGER DEFAULT 1`. Only `code` carries a real DB-level constraint (`UNIQUE`); no `CHECK` on `type` enum, `discount_value` positivity, `min_order_amount >= 0`, `max_uses_per_user >= 1`; no `NOT NULL` on `expired_at`. |
| DB seed | `backend/database.js` L106–111 — coupon seed | 4 seeded coupons: `SAVE10` (percent 10%, min 300k, exp 2099, max 1), `BIGBUY` (fixed 50k, min 500k, exp 2099, max 1), `VIP100` (fixed 100k, min 300k, exp 2099, max 2), `EXPIRED` (percent 20%, min 100k, exp **2020-01-01**, max 1). |
| Admin frontend | `frontend-admin/src/App.jsx` L16, L24–32, L41–58, L612–775 | `couponForm` state; `fetchData()` (L51) calls `GET /coupons` (axios default header carries the admin's own JWT via `axios.defaults.headers.common["Authorization"]`, L36 — so the *admin UI itself* always sends a token; the no-role-check finding is only reachable via a direct API call with a non-admin or missing token, not through this UI). Create form (L615–715): `code` has `required` + forces uppercase on input (L644, client-only transform); `type` is a fixed 2-option `<select>` (structurally can't submit a third value through this UI); `discount_value` has `required`, `type="number"`, no `min`; `min_order_amount` has **no `required`**, `type="number"`, no `min` (defaults to `0` in state); `expired_at` has `required`, `type="date"`; `max_uses_per_user` has **no `required`**, `type="number"`, `min="1"` (client-side only; defaults to `1` in state). Delete button (L753–768) calls `DELETE /admin/coupons/:id` directly, no confirmation dialog. |
| Spec — feature text | `README.md` L213–216 — FR-17 | "Admin có thể Thêm / Xem / Xóa mã giảm giá." + the 6 field constraints (quoted in full below). Note: unlike FR-15's phrasing ("Admin có thể Thêm/Sửa/Xóa"), FR-17 explicitly bundles **Xem** into the admin-only capability sentence itself — not only implied by the cross-cutting FR-12 rule. |
| Spec — access control | `README.md` L172–179 — FR-12 "Kiểm soát truy cập" | Names `/api/coupons` explicitly (alongside `/api/products`, `/api/categories`) as one of the "API có tính ảnh hưởng dữ liệu" requiring (1) valid JWT and (2) `role='admin'`. |
| Spec — security requirements | `README.md` L274–284 — §9, `SEC-02`/`SEC-03` | `SEC-02`: security-sensitive APIs require a valid JWT. `SEC-03`: Admin APIs must check `role='admin'`, not just token presence. |
| API spec (shape only) | `api_specification.md` §6.4, L201–214 | `POST /api/admin/coupons` example body (all 6 fields), `DELETE /api/admin/coupons/:id`. Shape only per `oracle-precedence.md` — not evidence of what the server should trust or enforce. |

**Gate: file map complete?** — Yes. All 3 coupon routes (`GET /api/coupons`, `POST /api/admin/coupons`,
`DELETE /api/admin/coupons/:id`), the DB schema, the seed data, the admin-frontend form/table,
and every spec citation FR-17 depends on (FR-17 itself, FR-12, SEC-02/SEC-03) are accounted for.
Confirmed no PUT/edit route exists. No FR-09 (`/api/apply-coupon`, `coupon_usage`, C1–C5) file
is included — out of scope, per the continuation handoff's explicit warning.

---

## Phase 1 — Testing Model (variables)

### Variable: `code`

| Field | Value |
|---|---|
| **Domain** | String, coupon code. |
| **Boundary + relation (spec)** | Required; must be **unique** among coupons. `source: spec` — `README.md` FR-17 line 216 ("code (duy nhất)"). |
| **Boundary + relation (impl, backend)** | `coupons.code` is `TEXT UNIQUE` (database.js L31) — a real DB-level constraint, the only one of the six fields with any enforcement at all. The `POST` handler does **no pre-check** of its own; a duplicate insert's rejection (if any) depends entirely on the DB throwing a constraint-violation error. `source: impl`. |
| **Boundary + relation (impl, admin frontend)** | `required`; forces `.toUpperCase()` on every keystroke (`App.jsx` L644) — a **client-only cosmetic transform**, not a validation rule; a direct API call can submit lowercase or mixed-case codes untouched. `source: impl`. |
| **Validation rule** | Must be non-empty; a `POST` whose `code` exactly matches an already-existing coupon's `code` must not result in a second coupon persisted with that same code. |
| **Oracle** | `README.md` FR-17 line 216 → a duplicate `code` (exact string match against an existing coupon) must not end up persisted as a second row. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |
| **Second-enforcement-path note (code-derived, not oracle)** | Since the `POST` handler has no pre-check, the *mechanism* of rejecting a duplicate is whatever the DB driver does with a `UNIQUE` constraint violation: `db.run(..., function(err){ if (err) return res.status(500).json({error: err.message}) ...})` (server.js L476–478) — a constraint violation surfaces as a raw `500` with the driver's own error string, not a clean `400`. The spec doesn't prescribe an error-response shape, so this isn't asserted as a violation of the oracle itself (which only requires the duplicate not be persisted) — but it's flagged as a quality/robustness finding worth observing directly. |
| **Observation, not modeled (see Assumption A3)** | Case-sensitivity of "duy nhất" (does `save10` collide with `SAVE10`?) — spec is silent; not asserted as an oracle claim. |

### Variable: `type`

| Field | Value |
|---|---|
| **Domain** | Enum, two members: `percent`, `fixed`. |
| **Boundary + relation (spec)** | Required; must be exactly `"percent"` or `"fixed"`. `source: spec` — `README.md` FR-17 line 216 ("type (percent/fixed)"). |
| **Boundary + relation (impl, backend)** | `coupons.type` is `TEXT DEFAULT 'percent'` (database.js L32), no `CHECK` enum constraint. The `INSERT` always names all 6 columns explicitly (server.js L467), including `type` — so even when the client omits `type` from the request body, the bound parameter is `undefined`, which the `sqlite3` driver binds as SQL `NULL`. **The column's own `DEFAULT 'percent'` can never actually fire through this endpoint**, because SQLite only applies a column default when the column is omitted from the `INSERT`'s column list — not when an explicit `NULL` is supplied. `source: impl`. |
| **Boundary + relation (impl, admin frontend)** | Fixed 2-option `<select>` (`percent`/`fixed`) — structurally cannot submit a third value through this UI; a direct API call can send any string, case variant, or omit the key. `source: impl`. |
| **Validation rule** | Must be exactly `"percent"` or `"fixed"` (case-sensitive, per the two literal values the spec and code both use). |
| **Oracle** | `README.md` FR-17 line 216 → a `type` value other than `"percent"`/`"fixed"` (including a missing or empty value) must not end up persisted as given. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |

### Variable: `discount_value`

| Field | Value |
|---|---|
| **Domain** | Number, must be positive. (Its unit — percentage points vs. VND amount — depends on `type`, but that dependency belongs to FR-09's discount-formula logic, out of scope here; FR-17 only concerns storage of a positive value.) |
| **Boundary + relation (spec)** | Required; must be **> 0** (exclusive lower bound). `source: spec` — `README.md` FR-17 line 216 ("discount_value (dương)"). |
| **Boundary + relation (impl, backend)** | `coupons.discount_value` is `INTEGER`, no `CHECK > 0` (database.js L33). `POST` persists whatever value arrives — negative, zero, or missing — verbatim. `source: impl`. |
| **Boundary + relation (impl, admin frontend)** | `required`, `type="number"`, no `min` attribute — UI requires *some* value but does not block negative/zero. `source: impl` — `App.jsx` L659–675. |
| **Validation rule** | Must be a positive number (`> 0`). |
| **Oracle** | `README.md` FR-17 line 216 → a `discount_value ≤ 0` (or absent/non-numeric) must not end up persisted. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |
| **Explicit exclusion** | No upper bound (e.g., `≤ 100` for `type: percent`) is modeled — FR-17's own spec text states only "dương" (positive), no type-dependent ceiling; inventing one would import FR-09's discount-formula concerns into FR-17's CRUD scope, the same discipline as the FR-09 correction on FR-08. |
| **Open question (see [[assumptions#A1]])** | BVA granularity ("just above zero") is not fixed by the spec's wording alone — resolved as Assumption A1. |

### Variable: `expired_at`

| Field | Value |
|---|---|
| **Domain** | Date. |
| **Boundary + relation (spec)** | Required (listed as a bare required field, no further qualifier in the same parenthetical style as the other five). `source: spec` — `README.md` FR-17 line 216 ("expired_at"). |
| **Boundary + relation (impl, backend)** | `coupons.expired_at` is `DATETIME`, **no `NOT NULL`** (database.js L35). `POST` does not validate presence, format, or temporal direction — persists whatever arrives, including a past date. `source: impl`. |
| **Boundary + relation (impl, admin frontend)** | `required`, `type="date"` — the HTML5 date picker constrains typed input to a calendar date, but a direct API call can send any string or omit the key. `source: impl`. |
| **Validation rule** | Must be present (non-null, non-empty). |
| **Oracle** | `README.md` FR-17 line 216 → an omitted or empty `expired_at` must not end up persisted (a coupon must not be created with no expiration date at all). |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |
| **Explicit exclusion (see [[assumptions#A2]])** | "Must be a future date at creation time" is **not** modeled as an oracle claim — rejected at Stage 2 (Assumption A2): no citation, and the seeded `EXPIRED` coupon (`expired_at: '2020-01-01'`) is itself the system's own accepted baseline state proving a past-dated coupon is not treated as invalid to *have* — only the field's *presence* is spec-required. |

### Variable: `min_order_amount`

| Field | Value |
|---|---|
| **Domain** | Number (VND), non-negative. |
| **Boundary + relation (spec)** | Required; must be **>= 0** (inclusive lower bound). `source: spec` — `README.md` FR-17 line 216 ("min_order_amount (>= 0)"). |
| **Boundary + relation (impl, backend)** | `coupons.min_order_amount` is `INTEGER DEFAULT 0` (database.js L34), no `CHECK >= 0`. Same column-default-suppression finding as `type` above: the `INSERT` always names `min_order_amount` explicitly, so an omitted request field binds `NULL`, not the schema's `DEFAULT 0` — meaning omission does **not** safely fall back to `0` as the schema alone might suggest. Negative values persist as given. `source: impl`. |
| **Boundary + relation (impl, admin frontend)** | Not `required`, `type="number"`, no `min` attribute; defaults to `0` in local form state (so an admin who never touches the field submits a valid `0`, not a gap). A direct API call can send negative numbers or omit the key. `source: impl`. |
| **Validation rule** | Must be a number `>= 0`. |
| **Oracle** | `README.md` FR-17 line 216 → a `min_order_amount < 0` must not end up persisted. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |

### Variable: `max_uses_per_user`

| Field | Value |
|---|---|
| **Domain** | Integer, must be `>= 1`. |
| **Boundary + relation (spec)** | Required; must be **>= 1** (inclusive lower bound). `source: spec` — `README.md` FR-17 line 216 ("max_uses_per_user (>= 1)"). |
| **Boundary + relation (impl, backend) — second boundary, differs from spec** | `server.js` L474: `max_uses_per_user || 1` — a JS falsy-coercion fallback, **not** a `>= 1` check. Any *falsy* input (`0`, `null`, `undefined`/omitted key, `""`, `NaN`) is silently replaced with the literal `1` before insertion — which happens to land inside the spec-valid range **by accident of the fallback value chosen**, not because the code is enforcing "`>= 1`". Critically, this fallback does **not** protect against a *truthy* invalid value: `-1` is truthy in JavaScript, so `-1 || 1` evaluates to `-1` — a negative value bypasses the fallback entirely and persists verbatim, still violating `>= 1`. `source: impl`, tagged separately from the spec's own boundary per Step 1.2. |
| **Boundary + relation (impl, admin frontend)** | Not `required`, `type="number"`, `min="1"` (client-side only); defaults to `1` in local form state. `source: impl`. |
| **Validation rule** | Must be an integer `>= 1`. |
| **Oracle** | `README.md` FR-17 line 216 → a `max_uses_per_user < 1` that is **not** coerced away by the code's own falsy-fallback must not end up persisted as given; conversely, the spec does not forbid the code's accidental coercion of a falsy input to `1`, since `1` is itself spec-valid. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` |
| **Flagged for its own dedicated BVA set** | The asymmetry between falsy inputs (`0`, omitted, `null`) — silently coerced to spec-valid `1` — and truthy-invalid input (`-1`) — not coerced, persisted as a spec violation — is exactly the behavior the continuation handoff called out; it needs boundary cases that distinguish these, not one generic "invalid" case. |

### Forbidden state: Actor/role for View/Create/Delete

| Field | Value |
|---|---|
| **Rule** | Only an actor holding a valid JWT with `role = 'admin'` may view, create, or delete coupons; every other actor state must be rejected. |
| **Source** | `README.md` FR-17 line 215 ("Admin có thể Thêm / Xem / Xóa mã giảm giá") states *who* may act — and, unlike FR-15's phrasing ("Admin có thể Thêm/Sửa/Xóa sản phẩm", which left View unmentioned as an admin-gated action), FR-17's own sentence explicitly bundles **Xem (View)** into the same admin-only capability list as Thêm/Xóa. This is a direct citation from FR-17's own clause, not an extension of FR-12. Corroborated for the two write operations by `README.md` FR-12 lines 176–179 (naming `/api/coupons` explicitly among the data-affecting Admin APIs) and §9 `SEC-02`/`SEC-03`. Further corroborated structurally: the code's own comment at `server.js` L355 reads "GET all coupons (**public - for admin display**)" — i.e., even the implementation's own intent for this route is admin display, not a customer-facing listing (the customer-facing coupon flow, FR-09, looks up one coupon by `code`, never lists all coupons) — consistent with, not contradicting, FR-17's own text. |
| **Domain (actor state reaching these 3 endpoints)** | `{ no Authorization header, present-but-invalid/expired JWT, valid JWT with role='user', valid JWT with role='admin' }` — 4 distinct classes, same reasoning as FR-15. |
| **Code-derived note (location only, not oracle)** | `backend/server.js` lines 356, 457, 483 — all three coupon routes carry only `authenticateToken` (401 if no token, 403 if invalid/expired via `jwt.verify`); none inspects `req.user.role`. All 4 actor states reach the same unguarded handler for all 3 operations. |
| **Validation rule** | The first three actor states must be rejected (no coupon list disclosed / no coupon persisted / no coupon removed); only the fourth (valid admin JWT) may proceed. |
| **Oracle** | `README.md` FR-17 line 215 (View/Create/Delete are Admin-only capabilities) + FR-12 lines 176–179 + `SEC-02`/`SEC-03` (Create/Delete specifically, as data-affecting writes) → a View/Create/Delete request without a valid JWT, or with a valid JWT whose role is not `admin`, must not succeed as if performed by an admin. |
| **Metadata** | `{ source: spec, confidence: HIGH, status: accepted }` — direct citation, no assumption needed. |

## Second-enforcement-path / cross-field note

`type`, `min_order_amount` share the same code-derived finding: because the `INSERT` statement (`server.js` L467) always names all 6 columns explicitly, an **omitted** request field is bound as SQL `NULL`, never triggering that column's own schema `DEFAULT` (`'percent'` / `0` respectively). A reader might assume omission safely falls back to the schema default — it does not, through this endpoint. This is a where-to-test finding (code-derived), not an oracle change: each field's own required-ness (from the spec) still means omission must not end up as a successfully created, spec-compliant coupon.

## Assumptions

See `assumptions.md` for full entries and Stage-2 disposition. Summary: **A1 accepted**
(`discount_value` BVA granularity), **A2 rejected** (`expired_at` must-be-future-date claim —
no citation, contradicted by the system's own `EXPIRED` seed baseline), **A3 rejected**
(`code` case-sensitivity of uniqueness — no citation, retained as an observation only).

## Human review

- [x] **Gate: `completeness_confirmed`** — checklist:
  - [x] Domain complete for `code`, `type`, `discount_value`, `expired_at`, `min_order_amount`, `max_uses_per_user`
  - [x] Boundary complete (spec-derived **and** impl-derived boundaries present for all six)
  - [x] Oracle frozen or backed by an accepted assumption for every entry
  - [x] Assumptions logged and reviewed (A1 accepted, A2 rejected, A3 rejected)
  - [x] Forbidden state present (actor/role for View/Create/Delete, citing FR-17 line 215 directly + FR-12/SEC-02/SEC-03 for the write operations)
  - [x] `max_uses_per_user`'s falsy-coercion asymmetry (0/omitted/null vs. negative) recorded as its own noted behavior, not folded into a single generic "invalid" case
  - [x] Scope check: no FR-09 (`/api/apply-coupon`, `coupon_usage`, C1–C5, discount formula) folded in

  **Approved 2026-07-07** (user: "Approve.").
