# execution-results.md — FR-17 Coupon Management CRUD

> Model C execution: agent-fired `curl` requests against the live SUT (manual `node server.js`
> start — Docker Desktop unreachable this session, same fallback FR-15 used), raw
> request/response captured, no assertions built into the execution tool. Each row references
> its frozen Test Case; **no `expected` field appears here** (structural guard, architecture.md
> §4.4.2) — comparison against the frozen expected happens in the bug-reporting stage.
> DB reseeded to a clean baseline (`node database.js`) immediately before this run. Full raw
> request/response capture:
> `out/reports/FR-17-coupon-crud/bug-reports/evidence/fr17-raw-execution-log.txt`.

## Equivalence Partitioning — Execution Results

| Result ID | Ref | Actual | Verdict | Evidence |
|---|---|---|---|---|
| ER-17-EP-001 | TC-17-EP-001 | `POST` returned `200 {"message":"Coupon created","id":5}`; follow-up `GET` (admin) showed id 5 with all 6 fields matching the submitted input exactly. | PASS | log lines 2–12 |
| ER-17-EP-002 | TC-17-EP-002 | First `POST` (`DUPTEST1`) → `200`, id 6 created. Second `POST` with the same `code:"DUPTEST1"` → `500 {"error":"SQLITE_CONSTRAINT: UNIQUE constraint failed: coupons.code"}`; follow-up `GET` confirmed only one `DUPTEST1` row (id 6) exists. | PASS | log lines 14–29 |
| ER-17-EP-003 | TC-17-EP-003 | `POST` with `code` omitted → `200 {"message":"Coupon created","id":7}`; follow-up `GET` showed id 7 persisted with `"code":null`. | FAIL | log lines 31–41 |
| ER-17-EP-004 | TC-17-EP-004 | `POST` with `type:"discount"` → `200`, id 8 created; follow-up `GET` showed id 8 persisted with `"type":"discount"` verbatim. | FAIL | log lines 43–53 |
| ER-17-EP-005 | TC-17-EP-005 | `POST` with `type` omitted → `200`, id 9 created; follow-up `GET` showed id 9 persisted with `"type":null` (**not** `"percent"`, confirming the column-default-suppression hypothesis). | FAIL | log lines 55–65 |
| ER-17-EP-006 | TC-17-EP-006 | `POST` with `discount_value:-1000` → `200`, id 10 created; follow-up `GET` showed id 10 persisted with `"discount_value":-1000`. | FAIL | log lines 67–77 |
| ER-17-EP-007 | TC-17-EP-007 | `POST` with `expired_at` omitted → `200`, id 11 created; follow-up `GET` showed id 11 persisted with `"expired_at":null`. | FAIL | log lines 79–89 |
| ER-17-EP-008 | TC-17-EP-008 | `POST` with `min_order_amount:-500` → `200`, id 12 created; follow-up `GET` showed id 12 persisted with `"min_order_amount":-500`. | FAIL | log lines 91–101 |
| ER-17-EP-009 | TC-17-EP-009 | `POST` with `min_order_amount` omitted → `200`, id 13 created; follow-up `GET` showed id 13 persisted with `"min_order_amount":null` (**not** `0`, confirming the column-default-suppression hypothesis). | FAIL | log lines 103–113 |
| ER-17-EP-010 | TC-17-EP-010 | `POST` with `max_uses_per_user:-5` → `200`, id 14 created; follow-up `GET` showed id 14 persisted with `"max_uses_per_user":-5`. | FAIL | log lines 115–125 |
| ER-17-EP-011 | TC-17-EP-011 | `GET /api/coupons` with no `Authorization` header → `401 {"error":"Unauthorized"}`. | PASS | log lines 127–132 |
| ER-17-EP-012 | TC-17-EP-012 | `GET /api/coupons` with a valid `test@eshop.com` (`role:user`) JWT → `200`, full coupon list returned (14 rows at that point). | FAIL | log lines 134–139 |
| ER-17-EP-013 | TC-17-EP-013 | `POST /api/admin/coupons` with no `Authorization` header, body `code:"UNAUTHCR8"` → `401 {"error":"Unauthorized"}`; follow-up admin `GET` confirmed no `UNAUTHCR8` row exists. | PASS | log lines 141–151 |
| ER-17-EP-014 | TC-17-EP-014 | `POST /api/admin/coupons` with a valid `test@eshop.com` (`role:user`) JWT, body `code:"USERROLECR8"` → `200 {"message":"Coupon created","id":15}`; follow-up admin `GET` confirmed the coupon exists. | FAIL | log lines 153–163 |
| ER-17-EP-015 | TC-17-EP-015 | Throwaway coupon `DELTHROW1` created (id 16) as admin. `DELETE /api/admin/coupons/16` with no `Authorization` header → `401 {"error":"Unauthorized"}`; follow-up admin `GET` confirmed id 16 still exists. | PASS | log lines 165–187 |

## Boundary Value Analysis — Execution Results

| Result ID | Ref | Actual | Verdict | Evidence |
|---|---|---|---|---|
| ER-17-BVA-001 | TC-17-BVA-001 | `POST` with `discount_value:-1` → `200`, id 17; persisted as `-1`. | FAIL | log lines 189–194 |
| ER-17-BVA-002 | TC-17-BVA-002 | `POST` with `discount_value:0` → `200`, id 18; persisted as `0`. | FAIL | log lines 196–201 |
| ER-17-BVA-003 | TC-17-BVA-003 | `POST` with `discount_value:1` → `200`, id 19; persisted as `1`. | PASS | log lines 203–208 |
| ER-17-BVA-004 | TC-17-BVA-004 | `POST` with `min_order_amount:-1` → `200`, id 20; persisted as `-1`. | FAIL | log lines 210–215 |
| ER-17-BVA-005 | TC-17-BVA-005 | `POST` with `min_order_amount:0` → `200`, id 21; persisted as `0`. | PASS | log lines 217–222 |
| ER-17-BVA-006 | TC-17-BVA-006 | `POST` with `min_order_amount:1` → `200`, id 22; persisted as `1`. | PASS | log lines 224–229 |
| ER-17-BVA-007 | TC-17-BVA-007 | `POST` with `max_uses_per_user:0` → `200`, id 23; persisted as `1` (the `\|\| 1` fallback fired — spec-valid outcome, not persisted as the invalid `0` given). | PASS | log lines 231–236 |
| ER-17-BVA-008 | TC-17-BVA-008 | `POST` with `max_uses_per_user:null` → `200`, id 24; persisted as `1` (fallback fired). | PASS | log lines 238–243 |
| ER-17-BVA-009 | TC-17-BVA-009 | `POST` with `max_uses_per_user` omitted → `200`, id 25; persisted as `1` (fallback fired). | PASS | log lines 245–250 |
| ER-17-BVA-010 | TC-17-BVA-010 | `POST` with `max_uses_per_user:-1` → `200`, id 26; persisted **as `-1`** (fallback did **not** fire — confirms the predicted falsy/truthy asymmetry). | FAIL | log lines 252–257 |
| ER-17-BVA-011 | TC-17-BVA-011 | `POST` with `max_uses_per_user:1` → `200`, id 27; persisted as `1`. | PASS | log lines 259–264 |
| ER-17-BVA-012 | TC-17-BVA-012 | `POST` with `max_uses_per_user:2` → `200`, id 28; persisted as `2`. | PASS | log lines 266–271 |
| ER-17-BVA-013 | TC-17-BVA-013 | `POST` with `type:"percent"` → `200`, id 29; persisted as `"percent"`. | PASS | log lines 273–278 |
| ER-17-BVA-014 | TC-17-BVA-014 | `POST` with `type:"fixed"` → `200`, id 30; persisted as `"fixed"`. | PASS | log lines 280–285 |
| ER-17-BVA-015 | TC-17-BVA-015 | `POST` with `type:"Percent"` (case variant) → `200`, id 31; persisted as `"Percent"` verbatim (not a member of `{"percent","fixed"}`). | FAIL | log lines 287–292 |
| ER-17-BVA-016 | TC-17-BVA-016 | `POST` with `expired_at:""` → `200`, id 32; persisted as `""`. | FAIL | log lines 294–299 |

## Summary

**Executed:** 31 frozen cases (15 EP + 16 BVA). **PASS:** 15. **FAIL:** 16.

**Notable pattern:** every field-validation FAIL is the same shape — no field-level check exists
at all in `POST /api/admin/coupons`, so any value (or omission) the client sends is persisted
verbatim, **except** `code`'s uniqueness (enforced by the DB's own `UNIQUE` constraint,
`ER-17-EP-002` PASS) and `max_uses_per_user`'s *falsy* invalid values (accidentally protected by
the `\|\| 1` fallback, `ER-17-BVA-007/008/009` PASS) — `max_uses_per_user`'s *truthy* invalid
value (`-1`) has no such protection (`ER-17-BVA-010` FAIL), confirming the asymmetry predicted
in the model.

**Observation (not a failure, attached to `ER-17-EP-002` PASS):** the duplicate-`code` rejection
mechanism is a raw `500` with the SQLite driver's own error string (`"SQLITE_CONSTRAINT: UNIQUE
constraint failed: coupons.code"`), not a clean `400` validation response. The frozen oracle
only required "not persisted as a duplicate," which held — this is a code-quality observation,
not a defect against `TC-17-EP-002`'s own expected result, and is not carried into the bug
reports below (mirroring FR-15's A2 disposition: observed, not asserted as a failure).
