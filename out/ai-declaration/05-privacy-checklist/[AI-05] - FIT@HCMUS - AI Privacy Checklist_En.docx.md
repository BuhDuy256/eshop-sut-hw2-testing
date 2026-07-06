# Faculty of Information Technology (FIT) – Ho Chi Minh City University of Science (HCMUS)

## CS423 / CSC13003 – Software Testing (AI-augmented · 2026)

### AI POLICY · TEMPLATES — 2026 v1.0

# Privacy & Responsible AI Use Checklist

*Run through this checklist before submitting any AI-assisted work.*

*Adapted from Med Kharbach, PhD (2026) — AI Use Policy Templates for Higher Education. CC BY-NC-SA 4.0. This adaptation is prepared for FIT@HCMUS – CS423 / CSC13003 Software Testing course.*

> **Note on the checkboxes below:** each is left for you to tick yourself — these are your own
> first-person certifications, not something the AI should assert on your behalf. A factual
> note is added after each item where objective evidence exists in the repo, so you can verify
> quickly before ticking.

---

## 1. Before I use AI

- [ ] I confirmed the AI Use Category assigned to this assignment. — _the specific category
  number (1–5) isn't recorded anywhere in this repo; confirm against the course's AI Usage
  Guideline document before ticking._
- [ ] I have declared which AI tool(s) I will use in my prompt log. — Claude Code
  (`claude-sonnet-5`) is declared in `[AI-03]` §2.1 and every prompt is logged verbatim in
  `[AI-02]` (22 artifacts).
- [ ] I have read the AI Use Agreement for this course.
- [ ] I understand which artifacts MUST NOT be AI-generated. — per `docs/architecture/
  architecture.md` §2.1 (MODEL ≠ ORACLE), expected test results are never sourced from AI
  reading code or observing output; only the spec or an explicitly accepted assumption may
  serve as an oracle.

---

## 2. While I am using AI

- [ ] I did not enter personal data of classmates, customers, or patients. — the SUT's seed
  data (`backend/database.js`) uses only fictional test accounts (`admin@eshop.com`,
  `test@eshop.com`); no real personal data was used in any session.
- [ ] I did not paste copyrighted reading materials wholesale into the AI.
- [ ] I did not paste proprietary employer or open-source license-restricted code. — all code
  read/modified belongs to this course's own SUT repository.
- [ ] I logged each prompt + AI response into prompt_log.md with timestamp. — logged instead
  into `[AI-02]`'s AI Audit Report (verbatim prompt + output + verdict + reasoning + fix, one
  row per artifact), per this project's own audit convention.

---

## 3. Before I submit my work

- [ ] All AI-generated artifacts are tagged in the AI Audit Report. — 22 artifacts logged in
  `[AI-02]`, spanning all 4 features plus the 2 extracted skills.
- [ ] All citations from AI have been verified (sources actually exist). — verify the
  `README.md`/`api_specification.md` line numbers cited throughout the domain-testing/BVA
  reports still match current file state before submitting (they may drift if the SUT files
  are edited after this pass).
- [ ] All AI-generated code has been executed and tested. — all 71 frozen test cases (across
  FR-04/08/15/17) were executed against the live SUT via Model C (`curl`), not merely read;
  raw request/response evidence is in each feature's `bug-reports/evidence/`.
- [ ] My 200–300-word AI Critique is included in the report. — drafted in `out/ai-critique.md`
  (270 words); review and personalize before submitting.
- [ ] The Mandatory Disclosure paragraph is at the end of my report. — _confirm this course's
  specific wording requirement; not otherwise present as a separate paragraph in the current
  deliverables._
- [ ] I attached the AI Use Disclosure Form. — drafted at `[AI-03]`; personal fields (name,
  student ID, category, signature) still need your input.
- [ ] I am ready for a 5–7-min random oral defense the week after submission.

---

## 4. Final Statement

*Final responsibility for the accuracy, originality, and integrity of this submission rests with me. Any undisclosed AI use is treated as academic misconduct.*

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
