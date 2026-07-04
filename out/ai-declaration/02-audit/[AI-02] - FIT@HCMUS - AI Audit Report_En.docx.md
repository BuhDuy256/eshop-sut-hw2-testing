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
| **Artifact #4 — Testing Model + Assumptions (FR-04: `name`/`phone`/`shipping_address` + forbidden `role` + immutable `email`)** | | | | |
| Tool: Claude Code (claude-sonnet-5)<br>Time: 2026-07-04, Step 4.1–4.2<br>Prompt (from `implementation_plan.md` Step 4.2): *"variables name, phone, shipping_address; forbidden/immutable fields email and role. For each: domain, boundaries + relation + source, validation, oracle, metadata, confidence. Log gaps as Assumptions."* | Draft model with `phone`'s oracle framed as **A4: "backend must reject a spec-invalid phone"** — an assumption with no cited spec/architecture evidence for assigning enforcement to a specific layer; also drafted A1–A3 (name length, name empty, address empty). | INVALID (for A4 only; A1–A3 and the rest of the model were VALID) | ISTQB FL §1.4 (test basis independence) / general defect-reporting discipline: an oracle claim must be traceable to an authoritative source, not inferred convenience. A4 named a specific implementation layer ("backend must enforce") with no `README.md` or `architecture.md` citation assigning that responsibility — unlike FR-08 line 107, which explicitly does. Citing an unsupported inference as spec would not survive challenge. | Student (via chat, verbatim): *"README quy định định dạng số điện thoại, nhưng chưa xác định rõ trách nhiệm enforce... Nếu không có bằng chứng, chuyển A4 thành một giả định cần xác nhận hoặc đổi mục tiêu test: kiểm chứng sự không nhất quán giữa spec, frontend và backend, thay vì dùng backend enforcement làm expected result."* AI searched `README.md`/SEC-01–07/`architecture.md`, found no enforcement-layer evidence, marked A4 `status: rejected`, and reframed the `phone` oracle to a path-agnostic, directly spec-sourced outcome requiring no assumption (see `testing-model.md` `phone` variable). User then approved (`completeness_confirmed` gate, 2026-07-04). |
| **Artifact #5 — Frozen Test Cases (FR-04: 6 EP + 10 BVA)** | | | | |
| Tool: Claude Code (claude-sonnet-5)<br>Time: 2026-07-04, Step 4.3<br>Prompt (from `implementation_plan.md` Step 4.3): *"EP cases → domain-testing report; BVA cases (phone-length boundary set) → boundary-value-analysis report. Expected from spec/accepted-assumption only, expected_source cited; traceability model↔case. Decision-table gate: skip if no combining conditions."* | 6 EP cases (`TC-04-EP-001..006`: valid update, empty name, empty address, invalid phone via API, role injection, email immutability) + 10 BVA cases (`TC-04-BVA-001..010`: 5 phone boundary values × UI-path/API-path), each with `expected_source` citing `spec` or `assumption: A2/A3`; decision table explicitly skipped with reasoning (no combining conditions in FR-04, unlike FR-09). | VALID | ISTQB FL §4.2/§4.3 — partition and boundary coverage for `phone`'s spec-stated length/leading-digit rule is complete (min−1, min, max, max+1, plus the leading-digit boundary), and the dual UI-path/API-path design directly operationalizes the Phase-1 finding (frontend/backend disagree) into falsifiable cases rather than leaving it as a code-reading impression. | None needed — accepted as drafted and committed before execution (`git log`: `Step 4.3 frozen test cases` precedes `Step 4.4 execution`), proving freeze-before-execute. |
| **Artifact #6 — Execution Results (FR-04, 16 cases)** | | | | |
| Tool: Claude Code (claude-sonnet-5)<br>Time: 2026-07-04, Step 4.4<br>Prompt (from `implementation_plan.md` Step 4.4): *"execute each frozen case via native Bash; record ref case ids, actual, verdict, evidence; no expected. Reseed DB between re-runs if state matters."* | 16 results (`ER-04-EP-001..006`, `ER-04-BVA-001..010`) recorded with `actual`/`verdict` only (no `expected` field); DB reseeded before the EP run and again before the BVA API-path run; UI-path executed via literal `node -e` evaluation of the frontend regex (no browser tool available in this environment, documented as the Model-C equivalent). | VALID | ISTQB FL §2.3 (test execution) — results are objective observations (raw request/response, regex output) with verdicts computed by comparison to the already-frozen Test Cases, never backfilled; environment resets between passes rule out state leakage as a false-positive source. | None needed — the `FAIL → real bug?` gate (2026-07-04) confirmed 3 of the 4 defect groups directly against spec-cited evidence; see Artifact #7 for the one reclassification. |
| **Artifact #7 — Bug Report Drafts (FR-04: `BUG-04-001..004`)** | | | | |
| Tool: Claude Code (claude-sonnet-5)<br>Time: 2026-07-04, Step 4.4<br>Prompt (from `implementation_plan.md` Step 4.4, using the FAIL verdicts in `execution-results.md`): *"Bug Report Draft(s): id, title, ref, expected-vs-actual, repro, evidence ref, severity, priority, status: draft."* | 4 drafts: `BUG-04-001` (empty name, drafted with `expected_source` implicitly treated as spec-equivalent), `BUG-04-002` (backend no phone validation, High), `BUG-04-003` (frontend regex contradicts spec, High), `BUG-04-004` (role injection, Critical). | INCOMPLETE (for `BUG-04-001` only; 002–004 were VALID) | ISTQB FL §5.3 (Defect Report) requires the expected result's basis to be stated precisely; `BUG-04-001`'s expected rested on accepted assumption A2, not an explicit FR-04 statement (`README.md` only states `name` is mandatory *at registration*, FR-01 line 32) — conflating an assumption-sourced expectation with a spec-cited one (as done for 002–004) overstates its evidentiary basis. | Student (via chat, verbatim): *"Riêng BUG-04-001... expectation 'name không được rỗng' hiện dựa trên accepted assumption A2 chứ không phải một rule được README phát biểu rõ... hãy phân loại rõ."* AI re-checked `README.md` for any FR-04-specific "name must not be empty" statement (found none), relabeled `BUG-04-001`'s `expected_source` as `assumption: A2` explicitly, added a "Classification note" distinguishing it from the three spec-cited bugs, and lowered confidence framing accordingly. User then approved all 4 (`approve → file` gate, 2026-07-04); promoted to `out/reports/FR-04-personal-profile/bug-reports/report.md`; no GitHub issues filed (`gh` unavailable). |
| **Artifact #8 — `domain-test-design` SKILL.md (generated, then generalized after human review)** | | | | |
| Tool: Claude Code (claude-sonnet-5)<br>Time: 2026-07-04, Step 5.1–5.4<br>Prompt (Step 5.1–5.2, from `implementation_plan.md`): *"Write methodology notes from what actually worked in 4.2–4.3... run generate-skill... validate... run the coupling smell-test."* Then, after the draft was shown for review, a second verbatim prompt (via chat): *"1. Mở rộng tiêu chí tạo Assumption... 2. Bổ sung heuristic... Prefer the least-committing oracle... 3. Thêm tiêu chí dừng chia Equivalence Partition... 4. Mở rộng Boundary Value Analysis... (lexical, enum, optional/presence, structural)... 5. Thêm Human Gate trước khi Freeze... 6. Output bổ sung kết quả cuối của từng Assumption."* | First draft: 6 stages (model → assumption-check → EP → BVA → decision-table → freeze), smell-test 0 hits, validated equivalent to FR-04's hand-written EP/BVA tables (`work/FR-04-personal-profile/skill-validation-output.md`). | INCOMPLETE (first draft) | ISTQB FL §1.3 (test design techniques should generalize beyond one system under test): the first draft's Assumption-creation rule ("no spec rule and no code constraint") did not capture FR-04's actual A4 lesson (a spec rule existed but was insufficient to defend a layer-specific oracle); its BVA stage only covered numeric ranges, missing lexical/enum/presence/structural boundary kinds that ISTQB FL §4.3 treats as equally valid boundary types; and it lacked an explicit rule tying `frozen` status to prior human approval, leaving a Design-by-Contract precondition (architecture.md §2.2) implicit rather than stated. | Student provided all 6 points verbatim (above). AI applied each: broadened Step 1.4 to "authoritative inputs insufficient for a defensible oracle" (not only "no spec rule"); added an explicit "prefer the least-committing oracle" heuristic to Stage 2; added an open-question stop-condition to Stage 3 ("would a further split change the outcome?"); rewrote Stage 4 to cover numeric/enum/optional-presence/structural boundary kinds; added Step 6.1 requiring recorded human approval before any `frozen` status; and required the Output Format to show every assumption's final disposition (`accepted`/`rejected`/`reframed — no longer needed`), not only the surviving ones. Also self-corrected a leftover inconsistency (intro text still said "Phase B/C" after an earlier rename to "Stage"), and synced `docs/implementation-plan/skill-4-domain-test-design-notes.md` to match, since the plan's own stop condition ("never hand-patch the generated file") is best honored by keeping notes and skill in lockstep even when the fix is applied directly. Smell-test re-run after all edits: 0 hits. User feedback (verbatim, chat): *"từ các skill sau nên ưu tiên cập nhật methodology notes trước rồi regenerate/update skill từ notes để tránh lệch nguồn sự thật."* Applied starting with Artifact #9 below (notes written first, skill generated from notes, no hand-patching). |
| **Artifact #9 — `bug-reporting` SKILL.md** | | | | |
| Tool: Claude Code (claude-sonnet-5)<br>Time: 2026-07-04, Step 6.1–6.4<br>Prompt (Step 6.1, from `implementation_plan.md`): *"Write notes from 4.4 (base: master-plan Part 5, Skill 5)... run generate-skill → save .claude/skills/bug-reporting/SKILL.md... Validate against FR-04's bug reports... run the coupling smell-test (0 hits)."* Notes were written first (`docs/implementation-plan/skill-5-bug-reporting-notes.md`), incorporating the Step 3/4 self-review lessons directly (severity must not overclaim beyond proven evidence; group failures by root cause, not 1:1; label `actual` as executed, not inferred; separate spec-cited from assumption-grounded expected results; per-report human approval, not blanket). Skill generated from those notes via `generate-skill`, no hand-patching this round. | 7 stages (confirm → group by root cause → classify severity from proven evidence → separate spec/assumption source → write → human gate → summarize). Smell-test: one false-positive hit on "points" ("evidence points either way") — reworded to "supports either conclusion", 0 hits after. | VALID | ISTQB FL §5.3 (Defect Report) and §1.4 (independent, evidence-bound judgment) — the skill's Stage 3 heuristic ("prefer the least-overclaiming severity justification") and Stage 4 (spec-vs-assumption labeling) directly generalize the two corrections the human review required on FR-08's and FR-04's bug reports in this same session, rather than re-deriving them from scratch each time. | Validated against FR-04's actual 16 execution results (`work/FR-04-personal-profile/bug-reporting-skill-validation-output.md`): reproduces the same 4-defect grouping, same severities, same spec-vs-assumption labeling, same per-report human-gate pattern as `out/reports/FR-04-personal-profile/bug-reports/report.md`. One minor gap found (the skill's Stage 7 would report an explicit severity-count summary line that the hand-run deliverable never stated as its own line) — noted as a future-work improvement, not fixed retroactively since it would require editing an already-approved deliverable. |

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
