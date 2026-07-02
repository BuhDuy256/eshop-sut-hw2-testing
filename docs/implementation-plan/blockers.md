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
