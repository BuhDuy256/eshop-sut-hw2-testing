# AI Critique

The clearest mistake happened during FR-08 Full: the AI modeled FR-09 (customer-facing coupon
application — the C1–C5 conditions and discount formula) as if it belonged to FR-08, reasoning
that "coupons are applied during checkout" made it functionally adjacent. It designed a 7-row
Decision Table and found 3 real bugs against code that was never actually assigned. I only
caught it because the resulting scope felt larger than what I remembered assigning, and asked
about it directly. The AI had `docs/hw2-reqs/features-that-need-testing.md` — the authoritative
4-line scope list — available from the start of that session and simply never consulted it
before accepting the prior session's framing at face value. It substituted a plausible-sounding
functional adjacency for an actual scope check, which is exactly the kind of error a fixed
checklist step would have caught, but nothing forced that step to happen before modeling began.

The same shape of risk reappeared with FR-17: it is the *correct* coupon feature, but sits one
edit away from the same C1–C5 logic, so I had it re-verify scope explicitly at the start of that
session rather than trust continuity from the FR-08 correction.

What I learned: an AI agent's context window does not substitute for an authoritative document
it hasn't been told to check. "Read the spec" and "read the assigned-scope list" are different
instructions, and skipping the second one is invisible until the output is already large and
convincing. The fix that worked wasn't asking the AI to be more careful in general — it was
requiring a scope-citation step before any modeling begins, checkable and gated, not a hoped-for
habit.
