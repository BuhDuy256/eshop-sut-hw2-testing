# FR-08 — Boundary Value Analysis Report

> **Correction, 2026-07-04:** this report previously held 7 BVA cases (`TC-08-BVA-001..007`)
> for FR-09's coupon conditions — `min_order_amount` threshold, `max_uses_per_user`, and the
> C2 expiry instant. FR-09 is not one of the 4 assigned features
> (`docs/hw2-reqs/features-that-need-testing.md`: FR-04, FR-08, FR-15, FR-17) — the assigned
> coupon-related feature is FR-17 (admin Coupon CRUD), a different feature from FR-09
> (customer-facing coupon application). All 7 cases have been removed; see the AI Audit for
> the corrective entry and `out/reports/FR-08-checkout/domain-testing/report.md` for the
> corresponding EP/Decision-Table removal.
>
> **Open gap, not yet resolved:** removing the FR-09 cases leaves this report with no BVA
> cases at all. FR-08's own model (`work/FR-08-checkout/testing-model.md`) lists boundary-
> shaped invalid classes for `total_amount` (`< 0`, `= 0`, very large — see the `total_amount`
> variable's "Invalid classes" table) that were never turned into BVA cases. Whether to design
> BVA cases for these now is a follow-up decision, not yet made.
