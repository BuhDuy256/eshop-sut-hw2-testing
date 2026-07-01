# EShop Docker Setup

This Docker Compose configuration runs all EShop modules (Backend, Frontend Web, Frontend Admin, and Frontend Mobile) in containerized environments.

## Prerequisites

- **Docker** (v20.10+)
- **Docker Compose** (v1.29+)

## Quick Start

### 1. Build and Run All Services

```bash
docker-compose up --build
```

This command will:
- Build Docker images for all services
- Start all containers
- Display logs from all services

**Note:** First run may take a few minutes as dependencies are installed.

### 2. Access the Applications

Once all services are running, access them via:

| Service          | URL                      | Credentials              |
| ---------------- | ------------------------ | ------------------------ |
| **Backend API**  | http://localhost:3000    | N/A                      |
| **Frontend Web** | http://localhost:5173    | test@eshop.com / Test1234! |
| **Frontend Admin** | http://localhost:5174  | admin@eshop.com / Admin123! |
| **Frontend Mobile** | See below              | (Expo - QR code/Emulator) |

### 3. For Mobile (Expo)

Option A: **Android Emulator / iOS Simulator**
```bash
# In the Expo container terminal, press:
a   # for Android Emulator
i   # for iOS Simulator
```

Option B: **Physical Device with Expo Go**
1. Install **Expo Go** app on your phone (iOS App Store / Google Play)
2. Open terminal where docker-compose is running
3. Look for the QR code from frontend-mobile service
4. Scan with Expo Go app

---

## Commands

### Start Services in Background
```bash
docker-compose up -d
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend-web
docker-compose logs -f frontend-admin
docker-compose logs -f frontend-mobile
```

### Stop Services
```bash
docker-compose down
```

### Stop and Remove Volumes (Clean Slate)
```bash
docker-compose down -v
```

### Rebuild Specific Service
```bash
docker-compose up -d --build backend
docker-compose up -d --build frontend-web
```

---

## Database

The SQLite database is automatically initialized when the backend container starts:
- Database file: `backend/database.sqlite`
- Created by: `node database.js` (runs on first container startup)

To reset the database:
```bash
docker-compose down -v
docker-compose up -d
```

---

## Development Features

All services have **hot-reload enabled**:
- **Backend**: Changes to files auto-restart (via volumes)
- **Frontend Web/Admin**: Vite hot module reload (HMR)
- **Frontend Mobile**: Expo fast refresh

The `docker-compose.yml` uses volume mounts to sync source code:
```yaml
volumes:
  - ./backend:/app              # Mount source code
  - /app/node_modules          # Keep node_modules in container
```

Edit files locally and see changes immediately in running containers.

---

## Troubleshooting

### Port Already in Use
```bash
# Check which process is using the port
netstat -ano | findstr :3000   # Windows
lsof -i :3000                  # Mac/Linux

# Change ports in docker-compose.yml if needed:
# "3000:3000" → "3001:3000"
```

### Container Won't Start
```bash
# Check logs
docker-compose logs backend

# Rebuild from scratch
docker-compose down -v
docker-compose up --build
```

### Mobile App Can't Connect to Backend
- Mobile container and backend container are on the same Docker network
- From mobile app, use `http://backend:3000` (container hostname)
- From host machine, use `http://localhost:3000`

### Database Locked Error
```bash
# Kill and restart backend
docker-compose restart backend
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│          Docker Network (eshop-network)                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Backend    │  │Frontend-Web  │  │Frontend-Admin│  │
│  │  :3000       │  │  :5173       │  │  :5174       │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                                                │
│  ┌──────────────┐                                       │
│  │Frontend-Mobile│                                      │
│  │   :8081      │                                       │
│  └──────────────┘                                       │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Notes

- Services are configured with health checks (backend waits for frontend services)
- Frontend services depend on backend being healthy before starting
- Default database file is `backend/database.sqlite` (created automatically)
- Change `NODE_ENV=development` in `docker-compose.yml` if needed for production

