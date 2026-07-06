# bug-report-drafts.md — FR-08 Checkout (Step 3 smoke)

## BUG-08-001

| Field | Value |
|---|---|
| **ID** | `BUG-08-001` |
| **Title** | Checkout persists client-forged `total_amount` instead of the server-recomputed cart total |
| **Ref** | `TC-08-001` (test case) / `ER-08-001` (execution result) |
| **Severity** | Critical — `total_amount` is the SUT's sole financial record for an order: it is what the admin revenue dashboard aggregates for `status = 'delivered'` orders (`README.md` line 183) and the only recorded amount owed for the order. Evidence proves this field is 100% attacker-controlled with zero server-side validation, for any authenticated user, on any order — a complete failure of the one rule (`README.md` FR-08 line 107) that exists specifically to prevent it, with no compensating control elsewhere in the checkout flow. Note: this SUT has no separate payment-gateway charge step to observe: severity is assessed against the order's financial-record integrity (and its downstream use in revenue reporting), not against an independently verified real-money charge event. |
| **Priority** | P1 |
| **Expected** | Per `README.md` FR-08 line 107 (oracle, see `docs/implementation-plan/oracle-precedence.md`): the backend must recompute `total_amount` server-side from the cart (`X = Σ price × quantity`) and persist that value, ignoring whatever `total_amount` the client sends. For this case: `X = 30,000,000` VND (1× iPhone 15 Pro Max). |
| **Actual** | The created order (`orderId: 1`) persists `total_amount = 1` — the exact forged value sent by the client — with no server-side recomputation. Confirmed via `GET /api/orders/my-orders` and `GET /api/orders/1`. |
| **Repro steps** | 1. Login as any user (`POST /api/login`). 2. Add any product to the cart via `POST /api/cart` (e.g. `{"id":1,"name":"iPhone 15 Pro Max","price":30000000,"quantity":1}`). 3. `POST /api/checkout` with a forged `total_amount` far below the real cart value, e.g. `{"total_amount":1,"shipping_address":"..."}`. 4. `GET /api/orders/my-orders` — observe the persisted `total_amount` equals the forged client value, not the real cart total. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` lines 297–309, `POST /api/checkout`: destructures `total_amount` directly from `req.body` and inserts it into the `orders` table with zero recomputation from `userCarts[userId]`. |
| **Evidence** | `out/reports/FR-08-checkout/bug-reports/evidence/BUG-08-001-request-response.txt` |
| **Status** | `approved` — promoted to `out/reports/FR-08-checkout/bug-reports/report.md`. |

## Human gate: `approve → file`

- [x] Approve this draft for promotion to `out/reports/FR-08-checkout/bug-reports/report.md`.

  **Note:** `gh` CLI is not installed in this environment (see `docs/implementation-plan/blockers.md`,
  0.2). Per the plan's own fallback ("GitHub posting blocked by unresolved Step 0 → proceed
  with local approved draft; do not block"), this promotes to the deliverable report with
  local evidence only — no GitHub issue filed in this session.

  **Approved 2026-07-04.**

  **Update 2026-07-04 (later the same day):** the environment blocker is resolved — Issues
  are now enabled on the repository and `gh` is authenticated. Filed verbatim from this
  already-approved content, no technical field changed: [issue #1](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/1).

---

# Continuation FR-08 Full — Bug Report Drafts (2026-07-04)

> `gh` CLI is now installed and authenticated as `BuhDuy256` in this environment (unlike at
> Step 0/Step 3 — see `docs/implementation-plan/blockers.md` 0.2, not retroactively edited).
> Pending approval below, these can be filed as real GitHub issues, not just local drafts.

## BUG-08-002

| Field | Value |
|---|---|
| **ID** | `BUG-08-002` |
| **Title** | Cart is not cleared after a successful checkout |
| **Ref** | `TC-08-EP-004` (test case) / `ER-08-EP-004` (execution result) |
| **Severity** | Medium — a stated post-condition of a core business flow (README FR-08 line 108) is violated on every successful checkout; the customer's cart silently retains items they already paid for, risking accidental duplicate purchase or user confusion on the next visit. Proven mechanism: the cart array is byte-identical before and after a successful checkout. Not classified higher — no data corruption or security boundary is crossed; the order itself is still created correctly. |
| **Priority** | Medium-High — visible on every single checkout, not an edge case. |
| **Expected** | Per `README.md` FR-08 line 108 ("Sau thanh toán thành công, giỏ hàng được xóa"): after a successful checkout, the cart must be cleared for that user. `expected_source`: `spec`. |
| **Actual** | `GET /api/cart` immediately after a `200 "Checkout successful"` response still returns the same, unchanged, non-empty cart contents. |
| **Repro steps** | 1. Login. 2. `POST /api/cart` to add an item. 3. `GET /api/cart` — confirm non-empty. 4. `POST /api/checkout` with a valid body — confirm success response. 5. `GET /api/cart` again — observe it is unchanged, not empty. |
| **Root cause (code-derived, for repro clarity only — not the oracle)** | `backend/server.js` `POST /api/checkout` (lines 297–309) never references `userCarts` — no code path anywhere in the file clears or resets it after an order is created. |
| **Evidence** | Raw request/response capture (API-level, no browser involved): `out/reports/FR-08-checkout/bug-reports/evidence/BUG-08-002-request-response.txt`. |
| **Status** | draft — pending human approval. |

## Human gate: `approve → file` (Continuation batch)

- [x] Approve `BUG-08-002` (cart not cleared) for promotion + GitHub issue.

  **Approved 2026-07-04 — requested to file as real GitHub issue (`gh` now installed
  and authenticated as `BuhDuy256`, unlike at Step 0).**

  **GitHub filing attempt:** `gh issue create --repo BuhDuy256/eshop-sut-hw2-testing ...` for
  `BUG-08-002` returned: *"the 'BuhDuy256/eshop-sut-hw2-testing' repository has disabled
  issues."* This is a harder, different blocker than Step 0's "`gh` not installed" (which has
  since resolved) — the repo itself does not accept issues at all, regardless of `gh`'s state.
  Per the plan's fallback ("GitHub posting blocked → proceed with local approved draft; do not
  block"), promoted to `out/reports/FR-08-checkout/bug-reports/report.md` with local evidence
  only. Enabling Issues on the repository (Settings → General → Features) would resolve this
  for future filing, if desired.

  **Update 2026-07-04 (later the same day, Continuation task — resolving the environment
  blocker, not re-opening Core Complete or this batch's technical content):** Issues have been
  enabled on the repository. Re-verified `gh auth status` (still authenticated as `BuhDuy256`)
  and `gh repo view --json hasIssuesEnabled` (`true`). Filed verbatim —
  `BUG-08-002` → [#2](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues/2) — no title,
  severity, priority, expected, actual, repro, or evidence content changed from what was
  already approved above; only the `GitHub Issue` field in
  `out/reports/FR-08-checkout/bug-reports/report.md` was updated to reference the issue.

## Correction, 2026-07-04 (same day) — `BUG-08-003/004/005` removed (FR-09 out of scope)

This file originally also contained `BUG-08-003` (apply-coupon auth/usage-cap bypass),
`BUG-08-004` (percent discount formula), and `BUG-08-005` (C3 boundary `>` vs `>=`) — all three
were about FR-09 (customer-facing coupon application), which is **not** one of the 4 assigned
features (`docs/hw2-reqs/features-that-need-testing.md`: FR-04, FR-08, FR-15, FR-17). The
assigned coupon-related feature, FR-17, is a different feature (admin Coupon CRUD). These 3
drafts have been removed from this file and from the promoted
`out/reports/FR-08-checkout/bug-reports/report.md`.

**GitHub issues #3, #4, #5 (already filed for these 3 bugs before the scope error was caught)
are left open and unedited on GitHub** — they document real, reproducible defects in the code,
just outside this student's graded FR-08 scope. They are not referenced from the FR-08
deliverable report going forward. See the AI Audit for the corrective entry.
