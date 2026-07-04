# blockers.md — Step 0 External Blocker Resolutions

## 0.1 — Rubric scope mapping

**Question:** Does the assigned set (FR-04, FR-08, FR-15, FR-17 — a second Pool-C feature) map
onto rubric row 4 (*Mobile*, 15 pts), or must one feature be swapped?

**Answer:** Confirmed by the student — the assigned set maps onto rubric row 4 as-is. No
feature swap required.

**Status:** resolved.

## 0.2 — GitHub repo + Issues board

**Question:** Confirm the group GitHub repo + Issues board URL; run `gh auth status`.

**Repo URL:** `https://github.com/BuhDuy256/eshop-sut-hw2-testing` (read from `git remote -v`,
`origin`).

**`gh auth status`:** **pending** — the `gh` CLI is not installed in this environment
(`gh: command not found`). Bug filing to GitHub Issues (Steps 3.4 / 4.4) will fall back to
"approved draft + local evidence only" until `gh` is installed and authenticated, per the
plan's own fallback: *"GitHub posting blocked by unresolved Step 0 → proceed with local
approved draft (documented); do not block."*

**Status:** repo URL resolved; `gh auth` explicitly noted pending (not a hard blocker per plan).

---

## Addendum — 2026-07-04 (later the same day), environment blocker resolved

> Recorded here, not by rewriting the Step-0 answer above, per the no-retroactive-edit policy —
> this is a status update on an external environment fact, not a redo of Step 0's analysis.

`gh` CLI is now installed and authenticated (`gh auth status` → logged in as `BuhDuy256`).
During Continuation FR-08 Full, a *further* blocker was found: the GitHub repository itself
had Issues disabled (`gh issue create` → "the repository has disabled issues"), independent of
`gh`'s own availability. **That blocker is now also resolved** — Issues have been enabled on
the repository (confirmed via `gh repo view --json hasIssuesEnabled` → `true`). All 5 FR-08
bug reports (`BUG-08-001..005`), previously promoted with local-evidence-only per the
documented fallback, have been filed verbatim as GitHub issues #1–#5 (see
`work/FR-08-checkout/bug-report-drafts.md` and `out/reports/FR-08-checkout/bug-reports/report.md`
for the per-bug issue links). No technical content in any bug report was changed by this — only
each report's `GitHub Issue` field was updated.
