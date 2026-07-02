# implementation-mode.md — Session Bootstrap (Implementation Phase)

> **Use:** paste this, or reference it, at the start of any NEW Claude Code session during
> implementation. It synchronizes a fresh session with the current project state in under a minute.
>
> **Priority order — always, in this order:**
> **1) Correctness · 2) Homework deliverables · 3) First-pass success · 4) Minimal rework.**
> Generalization happens only after empirical validation.

---

You are entering **IMPLEMENTATION MODE**. The design phase is over. The architecture and the
implementation strategy are already frozen. Do the following, in order, before anything else.

## 1 · Read the authoritative documents first (in this order)

Read these exactly as referenced — do **not** rename, rewrite, or inline any reference:

1. @CLAUDE.md
2. @docs/architecture/architecture.md
3. @docs/implementation-plan/implementation_plan.md

If any of these point to further files, follow those references. Read before acting.

- `architecture.md` is the **authoritative architecture** (the frozen *what* and *why*).
- `implementation_plan.md` is the **primary execution document** (the frozen sequence + Status).

## 2 · Restore the implementation mindset

State back, in 2–3 lines, that you understand these are **FROZEN**:

- Architecture (`architecture.md`) — frozen
- Workflow / the 4 phases — frozen
- Artifact contracts + the 3 structural guards — frozen
- Implementation sequence (Steps 0–6) — frozen

Do **not** reopen design discussions. Do **not** propose architectural changes unless I explicitly ask.

## 3 · Resume execution

- In `implementation_plan.md`, find **Status**, then find **> NEXT ACTION**.
- Execute **only** the current Next Action.
- **Never skip steps.** **Never run multiple steps in one session** unless I explicitly request it.
- A step may not begin until the previous step's **Exit Criteria** all pass.

## 4 · Implementation rules

Follow `implementation_plan.md` exactly. Honor, without exception:

- every **Stop Condition**
- every **Human Gate**
- every **Exit Criteria**
- every **Artifact Contract** (including the 3 structural guards)

If any action would violate the frozen architecture — for example: deriving an expected result
from code or observed output, editing a frozen expected, putting project-specific nouns inside a
skill, adding a phase, extracting a skill before FR-04, or building a test-runner / assertions —
then:

> **STOP. Explain why it conflicts with the frozen architecture. Ask for confirmation.
> Do NOT silently redesign.**

## 5 · After completing the step

1. Update `implementation_plan.md`: **Status** and **> NEXT ACTION**.
2. Update any affected documentation — respect Documentation Ownership (`architecture.md` §9):
   reference the owner document, do not restate owned content.
3. Commit (one commit per step, as the plan requires).
4. Summarize in the chat:
   - files changed
   - assumptions made (each logged with `{ source, confidence, status }`)
   - risks found
   - blockers
   - recommended next step
5. **Then stop.** Wait for me before continuing.

## 6 · Behavioral rules

**Do NOT:** redesign architecture · optimize prematurely · generalize · create new abstractions ·
extract reusable skills early (only after FR-04) · introduce new phases · build test-runners or
assertion frameworks.

**Prefer:** example-first · deliverable-first · evidence-driven decisions · minimal changes ·
one validated step at a time.

## 7 · Bootstrap checklist

```
□ Read @CLAUDE.md, @docs/architecture/architecture.md,
  @docs/implementation-plan/implementation_plan.md   (in order)
□ Acknowledged frozen: architecture · workflow · contracts · sequence
□ Located Status → Next Action
□ Executed ONE step only
□ Respected Stop Conditions · Human Gates · Exit Criteria · Artifact Contracts
□ Updated Status + Next Action (+ affected docs) · committed
□ Summarized: files · assumptions · risks · blockers · next
□ Stopped
```
