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

## Correction — 2026-07-07, Step-0 answer 0.1 was wrong (student-caught, instructor-confirmed)

> Recorded here, not by rewriting the original 0.1 answer above, per the no-retroactive-edit
> policy — this is a correction to a resolved Step-0 answer, discovered much later (after
> FR-17's full testing pass — Testing Model, 31 test cases, 8 confirmed bugs, GitHub issues
> #17–#24 — was already complete).

**What was wrong:** 0.1's answer ("the assigned set maps onto rubric row 4 as-is, no feature
swap required") assumed the HW02 rubric's generic "Feature D (Mobile, Domain + Boundary), 15
pts" row was satisfied by treating FR-17 as just the fourth 15-point slot — without checking
whether "Mobile" in that row is a literal platform requirement. It is: the assignment's own
System-Under-Test section (§4) organizes features into **Pool A/B/C/D**, where **Pool D is
explicitly "Mobile App"** — a platform, not a feature list — and the official Pool-assignment
spreadsheet (student ID 23127179, confirmed directly with the instructor) shows this student's
own row: Pool A=FR-04, Pool B=FR-08, Pool C=FR-15, **Pool D=FR-17, tagged "Mobile."** The
mechanism (confirmed directly by the instructor): Pool D always reuses one FR already defined
in Pool A/B/C, but requires it to be tested through the **mobile client**, not web/API — other
students' rows show the same pattern (e.g. Pool D=FR-16, Pool D=FR-02, Pool D=FR-06, each
borrowed from another pool).

**The blocking discovery:** FR-17 (admin Coupon CRUD) has **no mobile UI whatsoever** in this
SUT. `frontend-mobile/App.js` was grepped for `coupon|admin` — the only coupon-related code
found is the customer-facing apply-coupon flow (`handleApplyCoupon`, the coupon box in the
checkout screen), which is **FR-09** (Discount coupons, Pool B), not FR-17. There is no way to
genuinely test FR-17 "via Mobile" because the feature does not exist on that client at all.

**Resolution (agreed with the instructor):** swap this student's Pool D feature from **FR-17
→ FR-09** (Discount coupons) — thematically still coupon-related, and confirmed to have real,
working mobile UI. FR-17's already-completed work is **not deleted or invalidated** — it is a
real, evidenced testing pass (8 confirmed defects, all filed as GitHub issues) — but it is no
longer this assignment's graded Pool-D requirement; it stands as extra work. FR-09 is now the
4th required feature, to be tested through the mobile app's own UI (Expo Go on a physical
device, or an Android/iOS emulator — **not** `expo start --web`, which renders via
`react-native-web` in a desktop browser and would not genuinely demonstrate mobile testing).

**Full handoff for the FR-09-via-Mobile work:**
`docs/implementation-plan/continuation-handoff-FR09-mobile.md`.

**Status:** resolved — scope corrected, documented, ready for a fresh session to pick up.

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
