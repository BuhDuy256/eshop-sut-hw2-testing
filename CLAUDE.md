# CLAUDE.md — HW02 Domain Testing on EShop

## Project Context

- **Course:** Software Testing — HW02 Domain Testing & Boundary Value Analysis
- **SUT:** EShop (Vietnamese e-commerce with intentional bugs)
- **Your 4 Features:** FR-04, FR-08, FR-15, FR-17

---

## Input Documents (Read These First)

### Homework Requirements
| File | Purpose |
|------|---------|
| `docs/hw2-reqs/2026.HW02.Domain Testing_En.md` | Full HW02 assignment spec |
| `docs/hw2-reqs/features-that-need-testing.md` | Your 4 assigned features |
| `docs/general-hw-policies/___2026.Homework.Policies.md` | Submission rules and policies |

### System Under Test
| File | Purpose |
|------|---------|
| `README.md` | Feature specifications (FR-01 to FR-20) in Vietnamese |
| `api_specification.md` | Backend API details and validation rules |
| `setup_guide.md` | How to run the system manually |
| `DOCKER_README.md` | How to run via Docker |

### AI Declaration Templates (fill these in as you work)
| File | Purpose |
|------|---------|
| `out/ai-declaration/02-audit/[AI-02]...md` | AI Audit Report — log every AI interaction here |
| `out/ai-declaration/03-disclosure-form/[AI-03]...md` | AI Disclosure Form — declare tools used |
| `out/ai-declaration/05-privacy-checklist/[AI-05]...md` | Pre-submission checklist — run before submitting |

---

## Output Documents (Write These During Homework)

### Root outputs
| File | Purpose |
|------|---------|
| `out/README.md` | Self-assessment table + test summary report |
| `out/ai-critique.md` | AI Critique (200–300 words) |
| `out/git_commit_log.txt` | Git commit log — populate with `git log --oneline` |

### FR-04: Personal Profile Management
| File | Purpose |
|------|---------|
| `out/reports/FR-04-personal-profile/domain-testing/report.md` | Domain analysis and test cases |
| `out/reports/FR-04-personal-profile/boundary-value-analysis/report.md` | BVA test cases |
| `out/reports/FR-04-personal-profile/bug-reports/report.md` | Bugs found with GitHub issue links |

### FR-08: Checkout
| File | Purpose |
|------|---------|
| `out/reports/FR-08-checkout/domain-testing/report.md` | Domain analysis and test cases |
| `out/reports/FR-08-checkout/boundary-value-analysis/report.md` | BVA test cases |
| `out/reports/FR-08-checkout/bug-reports/report.md` | Bugs found with GitHub issue links |

### FR-15: Product Management CRUD
| File | Purpose |
|------|---------|
| `out/reports/FR-15-product-crud/domain-testing/report.md` | Domain analysis and test cases |
| `out/reports/FR-15-product-crud/boundary-value-analysis/report.md` | BVA test cases |
| `out/reports/FR-15-product-crud/bug-reports/report.md` | Bugs found with GitHub issue links |

### FR-17: Coupon Management CRUD
| File | Purpose |
|------|---------|
| `out/reports/FR-17-coupon-crud/domain-testing/report.md` | Domain analysis and test cases |
| `out/reports/FR-17-coupon-crud/boundary-value-analysis/report.md` | BVA test cases |
| `out/reports/FR-17-coupon-crud/bug-reports/report.md` | Bugs found with GitHub issue links |

---

## Running the System

```bash
# Docker (recommended)
docker-compose up --build

# Manual
cd backend && npm install && node database.js && node server.js
cd frontend-web && npm install && npm run dev        # http://localhost:5173
cd frontend-admin && npm install && npm run dev      # http://localhost:5174
```

**Test Accounts:**
- Admin: `admin@eshop.com` / `Admin123!`
- User: `test@eshop.com` / `Test1234!`
