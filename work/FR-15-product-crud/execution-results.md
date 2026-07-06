# execution-results.md — FR-15 Product Management CRUD

> Model C execution: native Bash (`curl`/`node`) against the SUT running locally (backend
> started manually — `node database.js` then `node server.js` — Docker Desktop was not
> running in this session; manual path is the documented fallback in `CLAUDE.md`). DB was
> reseeded to the known baseline (5 products, ids 1–5) immediately before this run, and again
> immediately after, to restore a clean baseline. Raw request/response capture:
> `out/reports/FR-15-product-crud/bug-reports/evidence/fr15-raw-execution-log.txt`.
> No `expected` field is recorded here per the structural guard (architecture.md §4.4) — each
> row only references its frozen case (`out/reports/FR-15-product-crud/domain-testing/report.md`
> or `.../boundary-value-analysis/report.md`) and records what was actually observed.

## Equivalence Partitioning — Execution Results

| Result ID | Ref | Actual | Verdict |
|---|---|---|---|
| ER-15-EP-001 | TC-15-EP-001 | `POST /api/products` with valid `name`/`price`/`category_id` as admin → `200 {"message":"Product created","id":6}`. `GET /api/products/6` returned all three fields matching the input exactly. | PASS |
| ER-15-EP-002 | TC-15-EP-002 | `POST /api/products` with `name:""` as admin → `200 {"message":"Product created","id":7}`. `GET /api/products` list shows id 7 persisted with `name:""`. | FAIL |
| ER-15-EP-003 | TC-15-EP-003 | `POST /api/products` with `name` key omitted, as admin → `200 {"message":"Product created","id":8}`. `GET /api/products` list shows id 8 persisted with `name:null`. | FAIL |
| ER-15-EP-004 | TC-15-EP-004 | `POST /api/products` with `price:-500000` as admin → `200 {"message":"Product created","id":9}`. `GET /api/products` list shows id 9 persisted with `price:-500000`. | FAIL |
| ER-15-EP-005 | TC-15-EP-005 | `POST /api/products` with `category_id:999` as admin → `200 {"message":"Product created","id":10}`. `GET /api/products` list shows id 10 persisted with `category_id:999` (no such category exists — seeded set is `{1,2,3}`). | FAIL |
| ER-15-EP-006 | TC-15-EP-006 | `POST /api/products` with **no** `Authorization` header, valid body → `200 {"message":"Product created","id":11}`. `GET /api/products` confirms a product named `"Unauth Create Test"` exists (id 11). | FAIL |
| ER-15-EP-007 | TC-15-EP-007 | `POST /api/products` with a valid `test@eshop.com` (`role:user`) JWT, valid body → `200 {"message":"Product created","id":12}`. `GET /api/products` confirms a product named `"User Role Create Test"` exists (id 12). | FAIL |
| ER-15-EP-008 | TC-15-EP-008 | Created throwaway product id 13 (`name:"Throwaway PUT Target", price:111111, category_id:1`) as admin. `PUT /api/products/13` with **no** `Authorization` header, body `{"name":"HACKED","price":1,...}` → `200 {"message":"Product updated"}`. `GET /api/products/13` returned `{"id":13,"name":"HACKED","price":1,...}` — the unauthenticated update was applied. | FAIL |
| ER-15-EP-009 | TC-15-EP-009 | Created throwaway product id 14 (`name:"Throwaway DELETE Target"`) as admin. `DELETE /api/products/14` with **no** `Authorization` header → `200 {"message":"Product deleted"}`. `GET /api/products/14` returned `{}` (empty — product no longer exists). | FAIL |
| ER-15-EP-010 | TC-15-EP-010 | Created throwaway products id 15 (`P_target`) and id 16 (`P_sibling`, `name:"Throwaway Sibling", price:444444, category_id:1`) as admin. `PUT /api/products/15` as admin changed its `name`/`price`/`category_id`. `GET /api/products/16` immediately after returned `{"id":16,"name":"Throwaway Sibling","price":"444444","category_id":1}` — byte-identical to its pre-edit values (price returned as the id-parity string-coercion already logged as an observation in `assumptions.md` A2, not a value change). | PASS |
| ER-15-EP-011 | TC-15-EP-011 | No browser-automation tool available in this environment; executed the literal `handleProductSubmit` state-update expression (`frontend-admin/src/App.jsx` lines 110–113) via `node -e` against a two-product fixture (`id:15` target, `id:16` sibling), mirroring the technique FR-04 used to execute its frontend regex directly. Input fixture: `products = [{id:15,name:"Edited Name",...},{id:16,name:"Throwaway Sibling",...}]`, `productForm.name = "Edited Name (second edit)"`. Output: `products.map(p => ({...p, name: productForm.name}))` produced `[{id:15,name:"Edited Name (second edit)",...},{id:16,name:"Edited Name (second edit)",...}]` — the sibling's `name` (id 16) was overwritten to the edited product's new name in the array that `setProducts()` applies to local UI state. | FAIL |

## Boundary Value Analysis — Execution Results

| Result ID | Ref | Actual | Verdict |
|---|---|---|---|
| ER-15-BVA-001 | TC-15-BVA-001 | `name` = 1-char string, admin → created (id 17). `GET /api/products/17` shows `name` length 1, `price:500000`, `category_id:2` — all as submitted. | PASS |
| ER-15-BVA-002 | TC-15-BVA-002 | `name` = 255-char string, admin → created (id 18). `GET /api/products/18` shows `name` length 255. | PASS |
| ER-15-BVA-003 | TC-15-BVA-003 | `name` = 256-char string, admin → created (id 19). `GET /api/products/19` shows `name` length **256** persisted verbatim (one over the stated 255 maximum). | FAIL |
| ER-15-BVA-004 | TC-15-BVA-004 | `price:-1`, admin → created (id 20). `GET /api/products/20` shows `price:"-1"` persisted (id-parity string coercion, value still -1). | FAIL |
| ER-15-BVA-005 | TC-15-BVA-005 | `price:0`, admin → created (id 21). `GET /api/products/21` shows `price:0` persisted. | FAIL |
| ER-15-BVA-006 | TC-15-BVA-006 | `price:1`, admin → created (id 22). `GET /api/products/22` shows `price:"1"` persisted (id-parity string coercion, value 1). | PASS |
| ER-15-BVA-007 | TC-15-BVA-007 | `category_id:1`, admin → created (id 23). `GET /api/products/23` shows `category_id:1`. | PASS |
| ER-15-BVA-008 | TC-15-BVA-008 | `category_id:3`, admin → created (id 24). `GET /api/products/24` shows `category_id:3`. | PASS |
| ER-15-BVA-009 | TC-15-BVA-009 | `category_id:4`, admin → created (id 25). `GET /api/products/25` shows `category_id:4` persisted (no category with id 4 exists). | FAIL |

## Totals

- Executed: 20 (11 EP + 9 BVA).
- PASS: 7 (`ER-15-EP-001`, `ER-15-EP-010`, `ER-15-BVA-001/002/006/007/008`).
- FAIL: 13 (`ER-15-EP-002/003/004/005/006/007/008/009/011`, `ER-15-BVA-003/004/005/009`).

## Environment note

Docker Desktop's daemon was not reachable in this session (`npipe` connection error). Ran the
documented manual fallback instead (`CLAUDE.md`): `cd backend && npm install && node
database.js && node server.js`. Confirmed a byte-identical baseline product list before and
after this run via `GET /api/products` diffed against the known 5-product seed.
