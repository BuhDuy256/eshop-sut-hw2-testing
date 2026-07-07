# HW02 — Submission README

## 1. Student information

| Field | Value |
|---|---|
| **Name:** | Nguyen Bao Duy |
| **Student ID:** | 23127179 |
| **Class:** | 23KTPM2 |
| **GitHub Repo:** | [BuhDuy256/eshop-sut-hw2-testing](https://github.com/BuhDuy256/eshop-sut-hw2-testing) |

## 2. Self-assessment table

Per `docs/hw2-reqs/2026.HW02.Domain Testing_En.md` §15. The mapping of the 4 assigned features originally included (FR-04, FR-08, FR-15, FR-17) with FR-17 mapped to rubric row 4. This was confirmed with the TA at Step 0 and recorded in `docs/implementation-plan/blockers.md` (0.1). However, since the requirement states each pool must be represented and row 4 is a Mobile feature (Pool D), **FR-09 (Discount Coupons - Mobile)** was subsequently selected to occupy the Pool D (row 4) slot. **FR-17 Coupon Management CRUD** is still kept in this submission as extra/bonus work.


| No. | Criteria | Grade | Self-Assessed Grade |
|---|---|---|---|
| 1 | FR-04 Personal Profile Management (Domain + Boundary) | 25 | 25 |
| 2 | FR-08 Checkout (Domain + Boundary) | 25 | 25 |
| 3 | FR-15 Product Management CRUD (Domain + Boundary) | 25 | 25 |
| 4 | FR-09 Discount Coupons, tested via Mobile (Domain + Boundary) | 15 | 15 |
| 5 | Agent Skills (`domain-test-design`, `bug-reporting`) | 10 | 10 |
| | **Total** | **100** | **100** |

**FR-17 Coupon Management CRUD** (15 EP + 16 BVA, 8 confirmed defects, issues #17–#24) remains
completed, evidenced work — kept as extra/bonus, outside the 5 graded rows above.

## 3. Test summary report

| Feature | EP cases | BVA cases | Decision Table | Total executed | PASS | FAIL | Confirmed defects |
|---|---|---|---|---|---|---|---|
| FR-04 Personal Profile Management | 6 | 10 | Skipped (no combining conditions) | 16 | 6 | 10 | 4 (`BUG-04-001..004`) |
| FR-08 Checkout | 4 | 0 | Skipped (no combining conditions) | 4 | 2 | 2 | 2 (`BUG-08-001..002`) |
| FR-15 Product Management CRUD | 11 | 9 | Skipped (no combining conditions) | 20 | 7 | 13 | 7 (`BUG-15-001..007`) |
| FR-09 Discount Coupons (Mobile) | 6 | 7 | Skipped (reason recorded in report) | 13 | 9 | 4 | 4 (`BUG-09-001` + 3 reconfirmed) |
| *FR-17 Coupon Mgmt CRUD (bonus, not graded)* | 15 | 16 | Skipped (no combining conditions) | 31 | 15 | 16 | 8 (`BUG-17-001..008`) |
| **Total (graded, rows 1-4)** | **27** | **26** | — | **53** | **24** | **29** | **17** |
| **Total incl. FR-17 bonus** | **42** | **42** | — | **84** | **39** | **45** | **25** |

**Test cases not yet executed:** none — every frozen test case across all 4 features was executed via Model C against the live SUT; no case was left designed-but-unexecuted.

**Bugs found:** 25 confirmed defects total (17 across the 4 graded features + 8 FR-17 bonus),
filed as GitHub issues [#1–#27](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues) minus
#4 and #5 (found deleted during the FR-09 pass, re-filed as #26/#27 — see
`out/reports/FR-09-coupon-mobile/bug-reports/report.md` for the discovery). All confirmed
defects are `spec`-grounded (traced to a direct `README.md`/security-requirement citation, or an
explicitly accepted assumption — see each feature's `bug-reports/report.md` for the
evidence-basis breakdown). Of FR-09's 4: 1 is newly found this pass (`BUG-09-001`, a mobile-only
compound chain); 3 reconfirm defects originally found during the FR-08-Full pass, now correctly
attributed to FR-09 (their real feature) with fresh mobile-specific evidence, after being
stripped from FR-08's scope in an earlier correction.

**By severity (graded features, rows 1-4):**

| Severity | Count | Features |
|---|---|---|
| Critical | 8 | FR-04 (1), FR-15 (3), FR-09 (3) |
| High | 6 | FR-04 (2), FR-08 (2), FR-15 (1) |
| Medium | 11 | FR-04 (1), FR-15 (3), FR-09 (1) |
| Low | 0 | — |

(Including FR-17's bonus 8: Critical 9, High 8, Medium 16, Low 0 — Total 25.)

**Notable cross-feature pattern:** every one of FR-15's and FR-17's CRUD write endpoints
(`POST`/`PUT`/`DELETE /api/products`, `POST /api/admin/coupons`, `DELETE
/api/admin/coupons/:id`) has zero access control (`authenticateToken` only, no `role` check) —
a systemic gap, not an isolated defect. FR-09's `POST /api/apply-coupon` extends the same
missing-auth pattern to a customer-facing endpoint, and this pass's mobile-code reading shows
the official mobile client's own code reinforces it — the app never even attempts to send a
token on that call, for any user.

## 4. Demo videos

- End-to-end skill demonstration: https://www.youtube.com/watch?v=W6TxiZhdteY

## 5. Deliverable index

*Paths below are relative to this `out/` folder, which is zipped as the submission root.*

- Domain Testing + Boundary Value Analysis reports: `reports/FR-{04,08,15,17}-*/{domain-testing,boundary-value-analysis}/report.md`
- Bug reports (with GitHub Issue links): `reports/FR-{04,08,15,17}-*/bug-reports/report.md`
- AI Audit Report: `ai-declaration/02-audit/[AI-02] - FIT@HCMUS - AI Audit Report_En.docx.md` (22 artifacts logged)
- AI Disclosure Form: `ai-declaration/03-disclosure-form/[AI-03] - FIT@HCMUS - AI Disclosure Form_En.docx.md`
- AI Privacy Checklist: `ai-declaration/05-privacy-checklist/[AI-05] - FIT@HCMUS - AI Privacy Checklist_En.docx.md`
- AI Critique: `ai-critique.md`
- Git commit log: `git_commit_log.txt` (64 commits)
- Reusable skills: `.claude/skills/domain-test-design/SKILL.md`, `.claude/skills/bug-reporting/SKILL.md`
- Architecture / process documentation: `docs/architecture.md`, `docs/implementation_plan.md`
