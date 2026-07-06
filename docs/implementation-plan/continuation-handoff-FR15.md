# Continuation Handoff — FR-15 (Product Management CRUD)

> Written 2026-07-04. Self-contained handoff for a new Claude Code session to pick up FR-15.
> Do not rely on any other handoff file for context — everything needed is here or in the
> files this document points to.

---

## 1. Current project status

**Steps 0–6 are Core Complete** (frozen at commit `43defbc`). **FR-08 Full is done**
(`total_amount`, auth-state, cart-clearing — `TC-08-001`, `TC-08-EP-002..004`; 2 confirmed bugs,
`BUG-08-001`/`BUG-08-002`, both filed as GitHub issues #1/#2).

**Important lesson from FR-08, apply it here:** an earlier pass on FR-08 accidentally folded in
FR-09 (a different, unassigned README feature — customer-facing coupon application) reasoning
it was "functionally adjacent" (coupons apply during checkout). This was caught and corrected
(git history shows both the mistake and the fix). **The fix for FR-15: before treating any
variable, endpoint, or behavior as in-scope, confirm it is actually described in FR-15's own
README section (lines 191–198) — not just reachable from the same route file or a related
user flow.**

**FR-15 is the next Continuation item and has not been started.** No `work/FR-15-product-crud/`
directory exists yet.

## 2. Authoritative scope — check this first

`docs/hw2-reqs/features-that-need-testing.md` (4 lines, read it, it is short):

```
FR-04 Personal profile management
FR-08 Checkout
FR-15 Product management (CRUD)
FR-17 Coupon management (CRUD)
```

FR-15 = **README.md lines 191–198** ("FR-15: Quản lý Sản phẩm — Product CRUD"). Do not conflate
with FR-16 (CSV import, lines 200–211, immediately below it) — different feature, not assigned.
Do not conflate with product **listing/search** (`GET /api/products?search=...`) either — that
functionality is closer to FR-02/03 (product browsing), which are also not assigned features;
mention it as an observation if relevant, don't build FR-15 test cases for it.

## 3. What FR-15 actually specifies (the oracle)

README.md lines 191–198, in full:

> - Admin có thể Thêm / Xem / Sửa / Xóa sản phẩm.
> - **Ràng buộc đầu vào:**
>   - Tên sản phẩm: bắt buộc, tối đa 255 ký tự.
>   - Giá: bắt buộc, phải là số **dương** (> 0).
>   - Danh mục: bắt buộc, phải chọn từ danh sách có sẵn.
> - Khi Sửa một sản phẩm, chỉ sản phẩm đó bị thay đổi — các sản phẩm khác giữ nguyên.

So: Admin can Add/View/Edit/Delete products. Three input constraints (`name` required ≤255
chars; `price` required and `> 0`; `category_id` required and must be an existing category).
Plus an edit-isolation postcondition: editing one product must not change any other product.

Do not assume this does or doesn't need a Decision Table — apply `domain-test-design`'s own
Stage 5 check once the model is built, and skip with a one-line reason if nothing combines
(this is what FR-04 did; FR-15 looks the same shape at a glance, but verify, don't assume).

## 4. Code-derived findings already surfaced (verify these still hold; code shows *where* to
test, never the oracle — per architecture.md §2.1, MODEL ≠ ORACLE)

From `backend/server.js` (read lines 141–196 yourself to confirm current state):

1. **`GET /api/products`** (line 141) — no auth; supports `?search=` via a raw
   string-interpolated SQL query (`WHERE name LIKE '%${searchQuery}%'`) — a SQL-injection shape,
   but search/listing isn't in FR-15's own spec text. Note only, don't build FR-15 cases for it.
2. **`GET /api/products/:id`** (line 159) — no auth; `if (row.id % 2 === 0) row.price =
   row.price.toString();` — returns `price` as a **string** for even-id products, a number for
   odd-id ones. Code-revealed anomaly; the spec is silent on response type, so building an
   oracle claim here needs its own Stage 1.4/Stage 2 defensibility check — don't just assume
   "numbers should always be numbers" is spec-backed without checking whether that's a
   reframe-able direct reading or needs an accepted assumption.
3. **`POST /api/products`** (line 167), **`PUT /api/products/:id`** (line 179), **`DELETE
   /api/products/:id`** (line 191) — **none have `authenticateToken` middleware at all.** Any
   actor, including a fully unauthenticated one, can create/edit/delete products. README says
   "**Admin** có thể Thêm/Xem/Sửa/Xóa" — implying CUD should be admin-restricted. This is the
   single highest-signal forbidden-state candidate for FR-15 (Step 1.3) — squarely FR-15's own
   endpoints, not an adjacent feature, so it's safe to model directly (unlike the FR-09 mistake).
4. **`backend/database.js`** `products` table (read it yourself, ~line 64–71): no `NOT NULL`,
   no `CHECK` constraints, no foreign key from `category_id` to `categories`. Confirms zero
   DB-level enforcement of any of the 3 spec constraints. `categories` table seeded with 3 rows
   (1=Điện thoại, 2=Laptop, 3=Phụ kiện). 5 seed products, ids 1–5 (so ids 2, 4 hit the
   price-as-string anomaly above).

## 5. Files to read, in priority order

1. `CLAUDE.md` — project orientation.
2. `docs/hw2-reqs/features-that-need-testing.md` — the 4-line assigned scope (§2 above).
3. `docs/architecture/architecture.md` — frozen architecture, read for context, don't redesign.
4. `docs/implementation-plan/implementation_plan.md` — Status table + Continuation section.
5. This file.
6. `docs/implementation-plan/oracle-precedence.md` — spec-conflict resolution rule + evidence
   standard.
7. `docs/implementation-plan/blockers.md` — frozen Step-0 content + a dated addendum (`gh` now
   works, GitHub Issues enabled on the repo — filing should work normally).
8. `docs/implementation-plan/execution-notes.md` — Model-C execution command form.
9. `.claude/skills/domain-test-design/SKILL.md` and `.claude/skills/bug-reporting/SKILL.md` —
   the two frozen skills. Invoke them via the `Skill` tool; don't hand-copy their logic.
10. `work/FR-04-personal-profile/testing-model.md` and `out/reports/FR-04-personal-profile/*`
    — calibration only, do not edit. Closest-shaped worked example (no Decision Table,
    independent field-level rules).
11. `work/FR-08-checkout/testing-model.md` and its `out/reports/FR-08-checkout/*` — calibration
    only, do not edit. Note the correction notes at the top of each file — shows how a scope
    error gets documented (appended, not hidden) if that's ever relevant again.
12. `README.md` lines 191–198 (FR-15) — the oracle. Not FR-16.
13. `api_specification.md` §3 (lines 78–98) — shape only for product endpoints.
14. `backend/server.js` lines 141–196 — the 5 product route handlers.
15. `backend/database.js` — `products`/`categories` schema and seed data.
16. `out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md` — append new
    rows starting at Artifact #15; read a couple of existing rows for format.

## 6. Immutable rules

- Steps 0–6 frozen at `43defbc`. FR-08 Full's corrected artifacts are also frozen. Do not edit
  either unless a genuine defect is found — never for polish or generalization.
- Do not edit `domain-test-design/SKILL.md` or `bug-reporting/SKILL.md` unless a real framework
  bug surfaces on FR-15 — not a preference. Notes-first-then-regenerate if a fix is needed,
  never hand-patch.
- **Check scope before modeling anything** — cross-reference `features-that-need-testing.md`
  and README's exact FR-15 section before treating any variable as in-scope. This is the one
  new discipline the FR-09 mistake adds.
- MODEL ≠ ORACLE, freeze-before-execute, the three Human Gates (`completeness_confirmed`,
  `FAIL → real bug?`, `approve → file`) — actually ask the user for each, don't self-approve —
  one AI Audit row per AI-generated artifact.
- Record framework limitations in `docs/implementation-plan/learning-notes.md` instead of
  fixing immediately; keep moving with the skills as-is unless a limitation blocks completion.

## 7. Expected outputs of FR-15

Same three-phase rhythm as FR-08 Full, pausing at all three Human Gates:

- `work/FR-15-product-crud/testing-model.md` (new) — file map, then one model entry per
  variable (`name`, `price`, `category_id`, actor/role for CUD, edit-isolation postcondition),
  each with domain/boundary+source/validation/oracle/metadata. Gate: `completeness_confirmed`.
- `out/reports/FR-15-product-crud/domain-testing/report.md` — EP cases; Decision Table only if
  Stage 5 finds combining conditions for FR-15's own variables.
- `out/reports/FR-15-product-crud/boundary-value-analysis/report.md` — BVA for `name`'s
  255-char boundary and `price`'s `> 0` boundary.
- `work/FR-15-product-crud/execution-results.md` — Model C, no `expected` field, reseed
  between runs if state matters.
- `out/reports/FR-15-product-crud/bug-reports/report.md` — confirmed defects, human-gated per
  report, filed as GitHub issues.
- New rows in `[AI-02]` starting at Artifact #15.
- Git commits per phase/artifact, human gates honored.

---

# Prompt for a New Claude Session

```
You are joining a project mid-stream. You have no memory of any prior session — do not assume
context beyond what you read below. Do not use any memory system; treat the repository as the
only source of truth.

Read, in this exact order, before doing or proposing anything:
1. CLAUDE.md
2. docs/hw2-reqs/features-that-need-testing.md — the EXACT 4 assigned features (FR-04, FR-08,
   FR-15, FR-17). A prior session once wrongly folded an unassigned feature (FR-09) into FR-08's
   scope reasoning "functional adjacency" - it was caught and corrected. Check every
   variable/finding you model against this list and against README's own FR-15 section before
   treating it as in-scope.
3. docs/architecture/architecture.md
4. docs/implementation-plan/implementation_plan.md - Status table + Continuation section
5. docs/implementation-plan/continuation-handoff-FR15.md - this file, written for you
6. docs/implementation-plan/oracle-precedence.md
7. docs/implementation-plan/blockers.md
8. docs/implementation-plan/execution-notes.md
9. .claude/skills/domain-test-design/SKILL.md
10. .claude/skills/bug-reporting/SKILL.md
11. work/FR-04-personal-profile/* and out/reports/FR-04-personal-profile/* (calibration only,
    do not edit - no Decision Table, independent field-level rules)
12. work/FR-08-checkout/* and out/reports/FR-08-checkout/* (calibration only, do not edit -
    note the correction notes at the top of each file)
13. README.md lines 191-198 (FR-15) only - not FR-16, not product search/listing
14. api_specification.md section 3 (product endpoints)
15. backend/server.js lines 141-196 (product route handlers) and backend/database.js's
    products/categories schema
16. out/ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md (existing
    rows, for format)

Ground rules, non-negotiable:
- Steps 0-6 are Core Complete (frozen at 43defbc); FR-08 Full's artifacts are also frozen.
  Do not edit either unless you find an actual defect - never for polish or generalization.
- Do not redesign, rewrite, or "improve" the architecture, the workflow, or either skill.
- Before modeling any variable/endpoint/finding, confirm it belongs to FR-15 specifically
  (README lines 191-198) - do not fold in an adjacent feature (e.g. product search/listing)
  just because it shares a route file, the same mistake already made once with FR-09.
- Build a complete Testing Model, EP test cases, and a Boundary Value Analysis for FR-15 from
  scratch. Check whether FR-15's own variables (name, price, category, actor/role for CUD)
  combine into anything needing a Decision Table (apply Stage 5's own check, don't assume
  either way), then execute and report bugs.
- Follow existing discipline: MODEL != ORACLE, freeze test cases and commit before executing,
  honor the three Human Gates by actually asking rather than self-approving, log one AI Audit
  entry per AI-generated artifact. GitHub issue filing should work normally (Issues enabled,
  gh authenticated).

Start by reading the files above, then tell me what you found and propose the first concrete
step. Do not start executing test cases before I confirm the plan.
```
