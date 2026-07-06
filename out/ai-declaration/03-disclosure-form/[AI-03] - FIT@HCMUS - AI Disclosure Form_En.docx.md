# Faculty of Information Technology (FIT) – Ho Chi Minh City University of Science (HCMUS)

## CS423 / CSC13003 – Software Testing (AI-augmented · 2026)

### AI POLICY · TEMPLATES — 2026 v1.0

# AI Use Disclosure Form

*Attach to assignments where AI was used in any permitted capacity.*

*Adapted from Med Kharbach, PhD (2026) — AI Use Policy Templates for Higher Education. CC BY-NC-SA 4.0. This adaptation is prepared for FIT@HCMUS – CS423 / CSC15003 Software Testing course.*

---

## 1. Course & Student Info

| Field | Value |
|---|---|
| **Course:** | CS423 / CSC13003 – Software Testing |
| **Assignment ID:** | HW02 |
| **Assignment Title:** | AI Domain Testing & Boundary Value Analysis |
| **AI Use Category (1–5):** | Category ____ _(fill in per the course's AI Usage Guideline — not included in this repo, so left for you to select)_ |
| **Date:** | 2026-07-07 |
| **Student name:** | Nguyen Bao Duy |
| **Student ID:** | 23127179 |

---

## 2. Disclosure Questions

### 1. AI tool(s) used:

Claude Code (model: `claude-sonnet-5`), Anthropic — used as an agentic CLI throughout, not a
single-prompt chat tool.

---

### 2. Stage(s) of the assignment where AI was used:

*Tick all that apply:*

- [ ] brainstorming
- [ ] outlining
- [x] drafting
- [ ] feedback
- [ ] revision
- [x] coding
- [x] data analysis
- [ ] visual design
- [x] other (specify): test design (EP/BVA/Decision-Table analysis), live SUT execution via `curl`, defect classification, GitHub issue filing

AI was used for every phase of the testing workflow itself (model construction, test design,
execution, bug reporting) under a structured process — see `docs/architecture/architecture.md`
and the two extracted skills, `.claude/skills/domain-test-design/SKILL.md` and
`.claude/skills/bug-reporting/SKILL.md` — with three mandatory human-in-the-loop gates
(`completeness_confirmed`, `FAIL → real bug?`, `approve → file`) that the AI could not
self-approve past.

---

### 3. Main prompts or tasks given to the AI:

The full verbatim prompt/output/verdict log is in `out/ai-declaration/02-audit/[AI-02] -
FIT@HCMUS - AI Audit Report_En.docx.md` (22 logged artifacts across FR-04, FR-08, FR-15, FR-17,
plus the two skill-extraction artifacts). The three most structurally important prompts:

1. The initial instruction to build an "AI-assisted software testing workflow" — a
   Design-by-Contract architecture with a MODEL ≠ ORACLE invariant, frozen-before-execute
   discipline, and named human gates — before any test case was designed for any feature (see
   `docs/architecture/architecture.md`).
2. Per-feature: "Build the Testing Model (Stage 1–2)... [spec text, code excerpts, DB schema]...
   Output the full Stage 1–2 Testing Model content" — invoking `domain-test-design` with the
   feature's spec/code as input, never asking the AI to "find bugs" as a black box.
3. The bug-reporting invocation per feature: "Turn the N confirmed FAIL results into grouped,
   classified, evidenced bug drafts... then stop at the Stage 6 human gate — present the drafts
   for approval, do not promote or file anything yet."

---

### 4. Specific parts of the work AI contributed to:

AI generated: all Testing Model entries (domains, boundaries, oracles, metadata) for all 4
features; all EP/BVA test cases and their `expected_source` citations; all Decision-Table
skip/build decisions; the two `SKILL.md` files; all `curl`-based Model C executions and raw
evidence capture; all bug report drafts (severity/priority/root-cause/evidence); all GitHub
issue filings; this AI Critique and the AI Audit Report itself.

Student contributed: every Human Gate decision (model completeness, FAIL→real-bug confirmation,
bug-report approval) was made by the student, not the AI — the AI proposed, the student decided.
The student also caught and corrected one scope error (see AI Critique, `out/ai-critique.md`):
an earlier session had folded FR-09 (unassigned) into FR-08's model; the student noticed the
scope had grown larger than expected and asked about it directly, which the AI could not have
caught on its own since it never re-checked the authoritative scope list mid-session.

---

### 5. How I reviewed, revised, or verified the AI output:

Every Testing Model was checked for MODEL ≠ ORACLE compliance before being approved (expected
results traced only to spec citations or explicitly accepted assumptions, never to code or
observed behavior) — see the completeness_confirmed gate checklist in each feature's
`work/FR-XX-*/testing-model.md`. Every test case was frozen and git-committed *before* any
execution result existed (verifiable via `git log` — see `out/git_commit_log.txt`). Every
confirmed defect was checked against the live SUT via a real HTTP request/response, not
inferred from source code alone — raw captures are in each feature's
`out/reports/FR-XX-*/bug-reports/evidence/`. Both extracted skills were smell-tested for
project-specific coupling (grep for feature IDs, filenames, phase numbers — zero hits required)
before being accepted.

---

### 6. Citation (if required by course style guide):

Anthropic. (2026). *Claude* (claude-sonnet-5) [Large language model]. https://claude.ai

---

## 3. Statement of Honesty

*By signing below, I confirm that the disclosure above is accurate and complete. I understand that undisclosed or false disclosure of AI use is treated as academic misconduct and may result in a 0 grade for the assignment and disciplinary referral.*

### Signature

| Field | Value |
|---|---|
| **Student name (printed):** | Nguyen Bao Duy |
| **Student ID:** | 23127179 |
| **Class / Cohort:** | _(fill in)_ |
| **Course:** | CS423 / CSC13003 – Software Testing |
| **Instructor:** | |
| **Date:** | |
| **Signature:** | |

---

## References

- Kharbach, M. (2026). *AI Use Policy Templates for Higher Education.* CC BY-NC-SA 4.0.
- ISTQB Foundation Level Syllabus (latest version).
- Hardman, P. (2025). *A Post-AI Learning Taxonomy.*
- Fuster Rabella, M. (2025). OECD Education Working Paper No. 338.
- Perkins, M., Roe, J., & Furze, L. (2025). *AI Assessment Scale.*
- Anthropic (2025). *Building reliable AI test agents* — engineering blog.
- DeepEval & Promptfoo documentation — testing frameworks for LLM systems.
