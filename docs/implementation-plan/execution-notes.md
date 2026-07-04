# execution-notes.md — Step 1 Working Execution Command Form

> Reference only, not a harness. Model C: the agent fires requests with its native Bash tool
> (`curl`) and reads raw responses; no assertions are built into these commands.

## Environment

- `docker-compose up --build -d` from repo root starts all 4 containers:
  - `eshop-backend` → `:3000` (healthy per Docker healthcheck)
  - `eshop-frontend-web` → `:5173`
  - `eshop-frontend-admin` → `:5174`
  - `eshop-frontend-mobile` → `:8081`, `:19000-19001`
- Backend has no route at `GET /` (returns 404) — this is expected, not a failure signal.
  Liveness is confirmed via the Docker healthcheck (`Up ... (healthy)`) and via a real API call.

## Login (capture JWT)

```bash
curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@eshop.com","password":"Admin123!"}'

curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@eshop.com","password":"Test1234!"}'
```

Response shape: `{"message","token","user":{...}}`. Extract `token` for `Authorization: Bearer <token>`.

**Observation (not part of Step 1 scope, logged for later):** the login response body includes
the plaintext `password` field inside `user`. Worth flagging as a candidate defect under
whichever assigned feature owns auth/profile exposure — not evaluated here since it is outside
FR-04/08/15/17 scope of this step.

## Authed request (extract token, then call)

```bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@eshop.com","password":"Test1234!"}' \
  | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).token))")

curl -s http://localhost:3000/api/users/me -H "Authorization: Bearer $TOKEN"
curl -s http://localhost:3000/api/products
```

(`node -e` used to parse JSON and extract `token` since `jq` is not confirmed installed in this
environment; swap for `jq -r .token` if available.)

## Reseed (confirm idempotent baseline)

```bash
docker exec eshop-backend node database.js
```

Output: `Database initialized and seeded (Phase 2).` / `Connected to database`.

Confirmed idempotent: re-running the login + `GET /api/users/me` + `GET /api/products` sequence
after reseed returned byte-identical bodies to the pre-reseed run (same user id/fields, same
5-product seed list in the same order).

## Exit criteria evidence

- Two JWTs captured (admin role id 1, user role id 2).
- One real 200 body captured for `GET /api/users/me` and `GET /api/products`.
- Reseed via `docker exec eshop-backend node database.js` confirmed idempotent by diffing
  pre-/post-reseed response bodies (identical).
