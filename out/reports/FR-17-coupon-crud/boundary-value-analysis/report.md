# FR-17 — Boundary Value Analysis Report

This file should contain the boundary value analysis for FR-17 Coupon Management CRUD, including:
- Boundary points for discount_value (must be > 0): 0, 0.01, -0.01
- Boundary points for min_order_amount (must be >= 0): -0.01, 0, positive
- Boundary points for max_uses_per_user (must be >= 1): 0, 1, 2
- Test cases for each boundary point with test data, expected results, actual results, and pass/fail status
