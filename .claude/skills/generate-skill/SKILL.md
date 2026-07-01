---
name: generate_skill
description: >
  Generates a new SKILL.md file from either a plain description of what the skill should
  do, or an existing spec that describes its steps and logic. Steps that need judgment
  include a Reasoning block written as open questions. Steps that are plain actions stay
  as one line. All output uses short, common words.
---

# Generate Skill

Takes a description or a spec and turns it into a complete SKILL.md file.
Phase order matters: identify the input type first, then build structure, then fill the
template, then check the result before output.

---

## Skill Metadata

**Task Type:** Skill File Generation
**Methodology:** Template-driven scaffolding with embedded reasoning
Identify input type → build or format structure → mark judgment steps → fill template →
validate → output.

---

## Global Writing Rule — Simple Words

This rule applies to this file and to every SKILL.md this skill generates.

- Use short, common words. Say "use" not "utilize." Say "show" not "demonstrate."
- One idea per sentence where possible.
- Only use a technical term when there is no simpler word for it (e.g. "API," "token").
- If a hard word is needed, explain it in plain words right after.

---

## Authoritative Inputs

Only treat each input as authoritative for what it actually contains.

| Input | Authoritative for | NOT authoritative for |
|---|---|---|
| Plain description | What the skill should do and what it should produce | How to split phases, step order, edge cases |
| Existing spec | Phase structure, step content, decision rules | Task type label, methodology name, input boundaries |

Phase structure (when input is a plain description) comes from Claude's judgment.
Formatting (when input is an existing spec) keeps the original logic — do not reorder,
merge, or simplify steps unless asked.

---

## Reasoning Block Rules

Read this before Step 2A or 2B.

**When to add a Reasoning block:**

```
A step needs judgment if:
  → the correct output depends on context
     (two different inputs would produce different answers)
  → there is more than one reasonable interpretation
  → it involves classifying, comparing, or inferring something

A step is a plain action if:
  → the output is the same no matter what the input is
  → it is mechanical: read, list, copy, call, write
  → someone with no domain knowledge could do it correctly
```

- Judgment step → **must** have a Reasoning block written as open questions.
- Plain action step → **no** Reasoning block. Keep it to one line.

**How to write a Reasoning block:**

Write it as questions, not rules. A question makes the model check the real context each
time. A fixed rule gets followed blindly even when the context does not fit.

```
❌ Too rigid (rule, not reasoning):
   If operator is ">": mark as strict boundary.
   If operator is ">=": mark as inclusive boundary.

✅ Right level (open question):
   → Does this boundary match what the spec says?
     Is it > or >=, and does that match the spec's intent?
```

- Keep each question short and in plain words.
- Add an "Ignore:" line when there is a common mistake or distraction to avoid.
- Never add a Reasoning block to a plain action step.

---

## Step 1 — Identify Input Type

```
Input is a plain description only      → go to Step 2A
Input is an existing spec only         → go to Step 2B
Input is both (description + part spec)
  → treat spec as authoritative for steps that exist
  → derive missing steps from description
  → go to Step 3
```

---

## Step 2A — Build Structure from Description

**Objective:** Turn a plain description into a phase and step structure.

- **Step 2A.1 — Name the task type:**
  - **Input:** The plain description.
  - **Reasoning:**
    → What kind of work is this skill doing?
    → Would the label make sense to someone who has not read the description?
    → Is the label specific enough to tell it apart from other skills?
  - **Output:** One task type label. Example: "Code Review," "Format Conversion."

- **Step 2A.2 — Name the methodology:**
  - **Input:** The plain description and the task type label.
  - **Reasoning:**
    → What is the main thinking pattern this skill uses to get from input to output?
    → Does a standard name exist for it, or does it need a short descriptive phrase?
  - **Output:** One methodology name or short phrase.

- **Step 2A.3 — Split into phases:**
  - **Input:** The plain description, task type, and methodology.
  - **Reasoning:**
    → What are the natural stages this task moves through?
    → Does each stage have one clear goal, or is it doing two unrelated things?
      If two things, split it.
    → Does the order matter? If yes, is the current order the right one?
  - **Output:** A list of phases, each with a one-sentence objective.

- **Step 2A.4 — List steps inside each phase:**
  - **Input:** Each phase and its objective.
  - **Reasoning:**
    → What concrete actions does this phase need?
    → For each step: does it need judgment, or is it a plain action?
      (Use the test from Reasoning Block Rules.)
    → Are there decision points? If yes, make them explicit in the step.
  - **Output:** Steps inside each phase, flagged as judgment or plain action.

- **Step 2A.5 — Identify authoritative inputs:**
  - **Input:** All inputs the skill will receive, as found in the description.
  - **Reasoning:**
    → What does each input actually contain?
    → What should NOT be inferred from it?
      (What would be a wrong assumption to make about it?)
  - **Output:** Rows for the Authoritative Inputs table.

  Declare before moving to Step 3:
  > "Derived structure: [Task Type] / [Methodology] / [N phases]. Proceeding."

---

## Step 2B — Format an Existing Spec

**Objective:** Map an existing spec into the standard skill structure without changing
its logic.

- **Step 2B.1 — Extract task type and methodology:**
  - **Input:** The existing spec.
  - **Reasoning:**
    → What is the spec trying to do? What label fits that work?
    → What thinking pattern does it use to go from input to output?
    → Ignore: any labels or names the spec already uses — derive fresh ones from the
      intent, then check if they match.
  - **Output:** Task type label and methodology name.

- **Step 2B.2 — Map steps into phase structure:**
  - **Input:** All steps in the existing spec.
  - **Reasoning:**
    → Do the steps group into natural phases, or are they flat?
    → Does each group have one clear goal?
    → Does the order in the spec make sense, or does a step depend on something
      that comes after it?
    → Ignore: formatting details in the spec — focus on logic and order.
  - **Output:** Phases with steps, in the same order as the spec.

- **Step 2B.3 — Run the judgment test on each step:**
  - **Input:** Each step from Step 2B.2.
  - **Reasoning:**
    → Does this step need judgment or is it a plain action?
      (Use the test from Reasoning Block Rules.)
    → If the spec shows judgment happening but does not spell it out, turn it into
      an explicit Reasoning block.
    → If the spec already has reasoning, keep it — just rewrite it as open questions
      if it is currently written as fixed rules.
  - **Output:** Each step flagged: judgment (needs Reasoning block) or plain action
    (one line only).

- **Step 2B.4 — Identify authoritative inputs:**
  - **Input:** All inputs mentioned in the spec.
  - **Reasoning:**
    → What does each input actually contain?
    → What should NOT be inferred from it?
  - **Output:** Rows for the Authoritative Inputs table.

  Declare before moving to Step 3:
  > "Formatting existing spec: [N phases detected]. Proceeding."

---

## Step 3 — Fill the Template

Produce the complete SKILL.md using this template:

````markdown
---
name: [skill_name_in_snake_case]
description: >
  [One paragraph. What the skill does, what it takes as input, what it produces
  as output. No trigger conditions — those belong in CLAUDE.md. Use simple words.]
---

# [Skill Title in Title Case]

[One sentence: what this skill does and why the phase order matters.]

---

## Skill Metadata

**Task Type:** [Category of work]
**Methodology:** [Name of reasoning approach]
[One sentence: the flow using → notation.]

---

## Authoritative Inputs

Only treat each input as authoritative for what it actually contains.

| Input | Authoritative for | NOT authoritative for |
|---|---|---|
| [input 1] | [what it contains] | [what must not be inferred from it] |
| [input 2] | [what it contains] | [what must not be inferred from it] |

[Any note about which judgments use Claude's knowledge vs. input content.]

---

## Phase 1: [Phase Name]

**Objective:** [One sentence.]

- **Step 1.1 — [Step Name]:**
  - **Input:** [what to look at]
  - **Reasoning:**
    → [Question 1 in plain words]
    → [Question 2 in plain words]
    → Ignore: [what not to infer or act on]
  - **Output:** [what this step produces]

- **Step 1.2 — [Plain action step — one line, no Reasoning block.]**

---

## Phase 2: [Phase Name]

**Objective:** [One sentence.]

- **Step 2.1 — [Step Name]:**
  - **Input:** [...]
  - **Reasoning** *(if needed)*:
    → [...]
  - **Output:** [...]

---

## Output Format *(include only if the skill produces a fixed output format)*

[Describe or show the fixed output format here.]
````

---

## Step 4 — Check Before Output

Before showing the file, run through this list. Fix anything that fails.

- [ ] `description` has no trigger conditions ("use this when...", "always trigger if...")
- [ ] `description` and body use simple, plain words (see Global Writing Rule)
- [ ] `Skill Metadata` has both Task Type and Methodology
- [ ] `Authoritative Inputs` table has at least one "NOT authoritative for" entry
- [ ] Each phase has one clear objective
- [ ] Every judgment step has a Reasoning block written as open questions
- [ ] Every plain action step has no Reasoning block (one line only)
- [ ] No Reasoning block is written as a fixed rule or if/else logic
- [ ] No phase does two unrelated things (single responsibility)
- [ ] Output format is declared if the skill produces structured output

---

## Output

Show the generated file inside a fenced markdown code block, then say:

> "Save as `.claude/skills/[skill_name].md`."

Do not create the file on disk unless asked.