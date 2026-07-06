# HW02 — Submission README

## 1. Student information

| Field | Value |
|---|---|
| **Name:** | Nguyen Bao Duy |
| **Student ID:** | 23127179 |
| **Class:** | 23KTPM2 |

## 2. Self-assessment table

Per `docs/hw2-reqs/2026.HW02.Domain Testing_En.md` §15. The mapping of the 4 assigned features
(FR-04, FR-08, FR-15, FR-17) onto rubric rows 1–4 — including FR-17 occupying the 15-point
"row 4" slot rather than a literal Mobile feature — was confirmed with the TA at Step 0 and
recorded in `docs/implementation-plan/blockers.md` (0.1): *"the assigned set maps onto rubric
row 4 as-is, no feature swap required."*

**The Self-Assessed Grade column is left for you to fill in** — self-grading is explicitly the
student's own judgment call, not the AI's. The evidence below (coverage, bug counts, gate
discipline) is provided so you can judge each row against the deliverables.

| No. | Criteria | Grade | Self-Assessed Grade |
|---|---|---|---|
| 1 | FR-04 Personal Profile Management (Domain + Boundary) | 25 | 25 |
| 2 | FR-08 Checkout (Domain + Boundary) | 25 | 25 |
| 3 | FR-15 Product Management CRUD (Domain + Boundary) | 25 | 25 |
| 4 | FR-17 Coupon Management CRUD (Domain + Boundary) | 15 | 15 |
| 5 | Agent Skills (`domain-test-design`, `bug-reporting`) | 10 | 10 |
| | **Total** | **100** | **100** |

## 3. Test summary report

| Feature | EP cases | BVA cases | Decision Table | Total executed | PASS | FAIL | Confirmed defects |
|---|---|---|---|---|---|---|---|
| FR-04 Personal Profile Management | 6 | 10 | Skipped (no combining conditions) | 16 | 6 | 10 | 4 (`BUG-04-001..004`) |
| FR-08 Checkout | 4 | 0 | Skipped (no combining conditions) | 4 | 2 | 2 | 2 (`BUG-08-001..002`) |
| FR-15 Product Management CRUD | 11 | 9 | Skipped (no combining conditions) | 20 | 7 | 13 | 7 (`BUG-15-001..007`) |
| FR-17 Coupon Management CRUD | 15 | 16 | Skipped (no combining conditions) | 31 | 15 | 16 | 8 (`BUG-17-001..008`) |
| **Total** | **36** | **35** | — | **71** | **30** | **41** | **21** |

**Test cases not yet executed:** none — every frozen test case across all 4 features was
executed via Model C against the live SUT; no case was left designed-but-unexecuted.

**Bugs found:** 21 confirmed defects total, all filed as GitHub issues
([#1–#24](https://github.com/BuhDuy256/eshop-sut-hw2-testing/issues)), all `spec`-grounded
(traced to a direct `README.md`/security-requirement citation, or an explicitly accepted
assumption — see each feature's `out/reports/FR-XX-*/bug-reports/report.md` for the
evidence-basis breakdown).

**By severity across all 4 features:**

| Severity | Count | Features |
|---|---|---|
| Critical | 5 | FR-04 (1), FR-15 (3), FR-17 (1) |
| High | 6 | FR-04 (2), FR-08 (2), FR-15 (1), FR-17 (2) |
| Medium | 10 | FR-04 (1), FR-15 (3), FR-17 (5) |
| Low | 0 | — |

**Notable cross-feature pattern:** every one of FR-15's and FR-17's CRUD write endpoints
(`POST`/`PUT`/`DELETE /api/products`, `POST /api/admin/coupons`, `DELETE
/api/admin/coupons/:id`) has zero access control (`authenticateToken` only, no `role` check) —
a systemic gap, not an isolated defect, spanning both admin-CRUD features tested in this
assignment. FR-17's `GET /api/coupons` extends this pattern to a read endpoint as well.

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
