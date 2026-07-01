# FR-17 — Domain Testing Report

This file should contain the domain testing analysis for FR-17 Coupon Management CRUD, including:
- Identification of all input variables and their domains (code, type, discount_value, min_order_amount, expired_at, max_uses_per_user)
- Equivalence classes for each input (valid and invalid partitions), for Create and Delete operations
- Test cases derived from each equivalence class, with test steps, expected results, actual results, and pass/fail status
- Coverage of uniqueness constraint on coupon code and enum constraint on type
