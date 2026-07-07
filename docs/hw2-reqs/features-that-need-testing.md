FR-04 Personal profile management
FR-08 Checkout
FR-15 Product management (CRUD)
FR-09 Discount coupons (Pool D — must be tested via the Mobile app)

---

Correction, 2026-07-07: the 4th assigned feature was originally recorded as FR-17 (Coupon
management CRUD), based on the Step-0 rubric-mapping answer in blockers.md §0.1. That answer
turned out to be wrong: the official Pool-assignment spreadsheet (confirmed directly with the
instructor) shows this student's row as Pool A=FR-04, Pool B=FR-08, Pool C=FR-15, **Pool
D=FR-17, tagged "Mobile"** — and Pool D's own defined content (per the assignment's SUT/pool
list, §4) is "Mobile App," meaning whichever feature lands in that slot must be tested via the
mobile client specifically, not the admin web panel/API.

FR-17 (admin Coupon CRUD) has **zero mobile UI** in this SUT (`frontend-mobile` only
implements the customer-facing apply-coupon flow, which is FR-09, not FR-17) — confirmed by
code inspection, no admin screens exist on mobile at all. Since FR-17 cannot genuinely be
tested via Mobile, the student and instructor agreed to swap the Pool D feature from FR-17 to
**FR-09 (Discount coupons)** — still coupon-themed, and confirmed to have real, working mobile
UI (`frontend-mobile/App.js`, `handleApplyCoupon`, the coupon box in the checkout screen).

FR-17's already-completed work (Testing Model, 31 frozen test cases, 8 confirmed bugs, GitHub
issues #17–#24) is **not deleted** — it remains a valid, real testing pass, kept as extra work
outside the graded Pool-D requirement. See `docs/implementation-plan/blockers.md` addendum and
`docs/implementation-plan/continuation-handoff-FR09-mobile.md` for full detail.
