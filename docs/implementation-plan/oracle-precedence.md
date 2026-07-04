# oracle-precedence.md — Step 2 Oracle Precedence Rule

> Freezes how conflicts between the two SUT specification documents are resolved, so that no
> such conflict can be reasoned away when it produces an inconvenient (failing) test result.
> This is a project fact (architecture.md §7.2 leaves the concrete mapping to the Command).

## 2.1 The rule

1. **`README.md` is the behavioral oracle — it wins.** It describes what the system must *do*
   (business rules, validation, side effects, user-facing behavior). Any expected result that
   concerns *behavior* is sourced from `README.md`.
2. **`api_specification.md` is interface/shape only — it is not authoritative for behavior.**
   It documents request/response *shape* (endpoint, field names, example payloads). Its
   examples show what a client *may send on the wire*; they are not a claim about what the
   server *should accept or trust*. A field appearing in an example body is not evidence that
   the server is supposed to honor that field's value.
3. **Conflict resolution order:** when the two documents disagree about behavior, `README.md`
   wins outright — no averaging, no "both are partially right." `api_specification.md` is
   never consulted to override a `README.md` behavioral statement.
4. **External reference — only after a confirmed conflict.** If neither document resolves a
   question (both silent, or genuinely ambiguous even after applying rule 3), an external
   reference (e.g. standard REST/e-commerce convention) may be consulted **only after** the
   conflict has been confirmed as unresolvable internally. Any such use is recorded as an
   Assumption with `source: external` and logged in the AI Audit.
5. **Evidence standard** (for Phase 3 execution/bug reporting):
   - API-level bug → screenshot (or saved raw text) of the request **and** response.
   - UI-level bug → browser screenshot.
   - The Markdown bug report is self-contained (evidence embedded/linked via relative path);
     a GitHub issue, if filed, is a mirror of the Markdown report — not the source of truth.

## 2.2 Applying the rule on paper — FR-08 `total_amount` contradiction

**The conflict:**

- `README.md` line 105–107 (FR-08, behavioral): *"Tổng tiền thanh toán được tính tự động từ
  giỏ hàng và không cho phép người dùng chỉnh sửa trực tiếp."* / *"Backend phải tự tính lại
  tổng tiền; không chấp nhận giá trị `total_amount` do client gửi lên."* — the backend must
  recompute the total server-side from the cart; a client-supplied `total_amount` must not be
  trusted.
- `api_specification.md` §4.3 (`POST /api/checkout`, interface shape): the documented request
  body is `{"total_amount": 200000, "shipping_address": "..."}` — `total_amount` appears as a
  field the client sends.

**Applying rule 3:** `api_specification.md` §4.3 only documents that a client *may send* a
`total_amount` field in the request body — it makes no claim that the server *trusts or uses*
that value for the stored order total. `README.md` is the behavioral oracle and it explicitly
states the backend must recompute and must not accept the client's value. There is no genuine
conflict once shape is separated from behavior: the client is permitted to send the field
(shape, api_specification.md), but the server is required to ignore it and recompute
(behavior, README.md).

**Resolution (deterministic):**
> The backend **must** recompute `total_amount` server-side from the cart contents at checkout
> time and persist/return the recomputed value, regardless of what `total_amount` value the
> client sends in the request body. **Expected oracle for any checkout test case:** the stored
> and returned order total equals the server-computed sum of cart line items (price × quantity),
> never the client-submitted `total_amount`.
>
> **Therefore:** if the SUT persists or returns the client-submitted `total_amount` value
> (e.g., a forged low value like `1`) instead of the server-recomputed value, that is a
> confirmed defect against `README.md` FR-08 — not a spec ambiguity, and not excusable by
> pointing at the `api_specification.md` example body.

This matches the plan's stated expected outcome: *"backend must recompute; trusting client
`total_amount` = bug."*

## Metadata

- `{ source: README FR-08 (behavioral oracle), confidence: HIGH, status: accepted }`
- `api_specification.md` §4.3 role: `{ source: api_specification (shape only), confidence: HIGH, status: accepted }` — not used as behavioral evidence, only to confirm the field name/shape the client sends.
