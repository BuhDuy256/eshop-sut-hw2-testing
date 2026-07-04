# Faculty of Information Technology (FIT) – Ho Chi Minh City University of Science (HCMUS)

## CS423 / CSC13003 – Software Testing (AI-augmented · 2026)

### AI POLICY · TEMPLATES — 2026 v1.0

# AI Audit Report — 5-section Template per Artifact

*Mandatory appendix for every AI-assisted homework (HW#01–HW#06, and Seminar).*

*Adapted from Med Kharbach, PhD (2026) — AI Use Policy Templates for Higher Education. CC BY-NC-SA 4.0. This adaptation is prepared for FIT@HCMUS – CS423 / CSC15003 Software Testing course.*

---

## 1. Student Information

| Field | Value |
|---|---|
| **Student name (printed):** | |
| **Student ID:** | |
| **Class / Cohort:** | |
| **Assignment ID (e.g., HW#00, HW#02):** | |
| **Assignment date:** | |
| **AI tool(s) used:** | |
| **AI tool(s) used:** | [ ] Yes  [ ] No |

---

## 2. Instructions (read before filling)

- Add one row per AI-generated artifact (test case, script, checklist, OpenAPI spec, JMeter plan, etc.).
- Paste the verbatim prompt — DO NOT paraphrase.
- Paste the verbatim AI output (or include a labelled screenshot in the report).
- Tag the verdict: VALID / INVALID / INCOMPLETE.
- Reasoning must cite a course slide, ISTQB section, or technical RFC.
- Show the corrected artifact with the change highlighted.
- Sample rows are in italic — replace them before submission.

---

## 3. Audit Table — one row per artifact

| (1) Prompt + Tool | (2) AI Output | (3) Verdict | (4) Reasoning (ISTQB) | (5) Student Fix |
|---|---|---|---|---|
| **Sample *(italic)* — replace before submission:** | | | | |
| Tool: AI Tool (e.g., ChatGPT, Claude, Gemini)<br>Time: 14:32 25/02/2026<br>Prompt: "Generate test cases for parsePhoneNumberVN function…" | TC01: parsePhoneNumberVN("0912345678")<br>Expected: {prefix:84, number:912345678, valid:true}<br>… | INCOMPLETE | AI ignored RFC 3966 international format. ISTQB FL §4.3 Boundary Value Analysis requires testing format edges. | Added TC: parsePhoneNumberVN("+84-91-234-5678")<br>Expected: {prefix:84, number:912345678, valid:true} |
| **Artifact #1 — Testing Model fragment `total_amount` (FR-08)** | | | | |
| Tool: Claude Code (claude-sonnet-5)<br>Time: 2026-07-04, Step 3.1<br>Prompt (from `implementation_plan.md` Step 3.1, executed under the frozen `implementation-mode.md` workflow): *"Testing Model fragment → work/FR-08-checkout/testing-model.md: variable total_amount — domain, boundary + relation, source: spec (README FR-08), validation, oracle (backend recomputes; client value rejected), metadata {source: spec, confidence: HIGH, status: proposed}, forbidden-field note (client-controlled total). Human-review: approve."* | Draft with: Domain (positive integer, server-computed), Boundary (must equal recomputed sum X, "any other value... out of boundary" — no explicit invalid-class enumeration), Source (README FR-08 105–107), Validation rule (backend must ignore/recompute), Oracle (README line 107 quoted), Metadata `{source: spec, confidence: HIGH, status: proposed}`, forbidden-field note on client-controlled total. | INCOMPLETE | ISTQB FL §4.3 (Boundary Value Analysis) requires boundaries to be enumerated as explicit equivalence classes, not left as an unbound "any other value"; §4.2 (Equivalence Partitioning) requires the partition and its representative values to be unambiguous before a case can be derived from it. The oracle variable `X` was referenced but never formally defined, and no explicit assumptions were recorded to bound the scenario (login state, cart non-empty, no concurrent price change, no coupon/tax component) — leaving the model open to multiple readings. | Student (via chat, verbatim): *"1. Hãy ghi rõ biến oracle X được định nghĩa là gì... 2. Thêm explicit assumptions... (đăng nhập, cart không rỗng, giá/số lượng không đổi, không voucher/shipping/tax trừ khi ghi rõ)... 3. Boundary nên ghi rõ invalid classes (<0, =0, !=X, rất lớn, hợp lệ nhưng khác X)... 4. Validation rule bổ sung observable behavior (persisted/response total_amount = X, client value no effect)... 5. Human Gate bổ sung checklist (Domain/Boundary/Oracle/Assumptions/Negative space)."* AI applied all 5 points; user then approved (`completeness_confirmed` gate, 2026-07-04) and the fragment moved to `status: accepted`. |
| **Artifact #2 — Frozen Test Case `TC-08-001`** | | | | |
| Tool: Claude Code (claude-sonnet-5)<br>Time: 2026-07-04, Step 3.2<br>Prompt (from `implementation_plan.md` Step 3.2): *"Test Case (frozen) → first case in out/reports/FR-08-checkout/domain-testing/report.md: TC-08-001, technique EP/negative, preconditions (user token, cart seeded to real total X), input (POST /api/checkout with total_amount = 1), steps, expected (order persists server-recomputed X; client 1 rejected/ignored) + expected_source: README FR-08, status: frozen. Commit this before executing."* | `TC-08-001`: EP negative class (`total_amount != X`), preconditions (JWT + cart seeded to 1× iPhone 15 Pro Max, `X = 30,000,000`), input (`POST /api/checkout {"total_amount":1,...}`), 4-step procedure, expected (persisted/echoed total = `X`, client value has no effect), `expected_source: README FR-08 line 107`, `status: frozen`. | VALID | ISTQB FL §4.2 Equivalence Partitioning — the case targets the single highest-risk negative class (forged value far below the real total) with a concrete, reproducible precondition and a spec-sourced expected result, satisfying the MODEL≠ORACLE constraint (expected derived only from `README.md`, never from the code read while locating the endpoint). | None needed — accepted as drafted and committed before execution (`git log`: commit `Step 3.2 frozen test case` precedes `Step 3.3 execution result`), proving freeze-before-execute. |
| **Artifact #3 — Bug Report Draft `BUG-08-001`** | | | | |
| Tool: Claude Code (claude-sonnet-5)<br>Time: 2026-07-04, Step 3.4<br>Prompt (from `implementation_plan.md` Step 3.4, using the FAIL verdict recorded in `ER-08-001`): *"Bug Report Draft (if FAIL) → work/FR-08-checkout/bug-report-drafts.md: id, title, ref: TC-08-001, expected-vs-actual, repro, evidence ref, severity, priority, status: draft."* | `BUG-08-001`: title, Critical/P1, ref `TC-08-001`/`ER-08-001`, expected (`X = 30,000,000`) vs actual (`total_amount = 1` persisted), 4-step repro, code-derived root-cause note (`server.js` 297–309, labelled as non-oracle), evidence file reference, `status: draft`. | VALID | ISTQB FL §5.3 (Defect Report) required fields — unique ID, summary, severity/priority, precise reproduction steps, expected vs. actual result, and evidence — are all present and each expected value is traceable to the spec citation already frozen in `TC-08-001`. | None needed — approved as drafted (`approve → file` gate, 2026-07-04) and promoted verbatim to `out/reports/FR-08-checkout/bug-reports/report.md`; no GitHub issue filed this session (`gh` CLI unavailable, per `blockers.md` 0.2), local evidence only. |
| **Artifact #4** | | | | |
| **Artifact #5** | | | | |
| **Artifact #6** | | | | |
| **Artifact #7** | | | | |
| **Artifact #8** | | | | |
| **Artifact #9** | | | | |
| **Artifact #10** | | | | |

---

## 4. Summary of AI Accuracy

Aggregate the verdicts from Section 3 and complete the table below.

| Metric | Count | Percentage |
|---|---|---|
| **Total AI-generated artifacts audited** | | |
| **VALID (correct, accepted as-is)** | | % |
| **INVALID (wrong; rejected)** | | % |
| **INCOMPLETE (acceptable after edits)** | | % |

---

## 5. Conclusion — When should AI be used (or not)?

Write 80–150 words describing patterns you observed. Where did AI shine? Where did AI fail? What is your recommendation for using AI in this kind of work in the future?

*(Write your conclusion here.)*

---

## 6. Mandatory Disclosure (paste verbatim)

> "[Test cases / script / dataset / report] was initially generated by [AI tool name]; I reviewed and modified [section X], added [edge cases Y, Z]; [section W] was written entirely by me. The detailed AI Audit Report is attached as Appendix A. I confirm I did not use AI to generate any artifact listed in the prohibited category."

### Signature

| Field | Value |
|---|---|
| **Student name (printed):** | |
| **Student ID:** | |
| **Class / Cohort:** | |
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
