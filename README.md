# Task Manager

A full-stack task management platform with user authentication, task CRUD,
filtering and search. It ships as a single Docker Compose stack (MySQL +
Spring Boot API + React SPA served by nginx) and can also be run locally
with Maven and Vite.

## Screenshots

| | |
|---|---|
| ![Login page](docs/images/loginPage.png) | ![Register page](docs/images/registerPage.png) |
| ![Dashboard](docs/images/dashboardside.png) | ![Task creation](docs/images/creationPage.png) |
| ![Task deletion](docs/images/deletePage.png) | |

## Features

- **Authentication** — email/password registration and login, stateless JWT
  (HS256) issued by the API, passwords hashed with BCrypt.
- **Task management** — create, read, update and delete your own tasks with
  title, description and status (`TODO`, `IN_PROGRESS`, `DONE`).
- **Filtering & search** — filter by status and search by title/description,
  with server-side pagination.
- **Ownership isolation** — every task query is scoped to the authenticated
  user; users cannot read, update or delete another user's tasks.
- **Show/hide password** — eye / eye-slash toggle on every password field.
- **API documentation** — live Swagger UI served by the backend.
- **Uniform error handling** — all errors are returned as a consistent JSON
  `ApiError` body.

## Tech stack & architecture

The project is a monorepo with three layers:

- **Backend** — Spring Boot 3.4 (Java 21, Maven). REST API under `/api`,
  Spring Security + JWT for stateless auth, Spring Data JPA with Flyway
  migrations (`ddl-auto: validate`), springdoc-openapi for Swagger,
  Spring Actuator for health checks. MySQL for persistence, H2 for tests.
- **Frontend** — React 18 + TypeScript + Vite, Tailwind CSS 4, React Router,
  TanStack Query, React Hook Form + Zod for validation, Axios HTTP client.
  Tests with Vitest + Testing Library.
- **Infrastructure** — `docker-compose.yml` orchestrates MySQL 8, the
  backend and the frontend (built as static files served by nginx, which
  proxies `/api` to the backend).

### Repository layout

```
├─ backend/    Spring Boot REST API (Maven, Java 21)
│  └─ src/main/resources/db/migration/   Flyway migrations (SQL)
├─ frontend/   React SPA (Vite + TypeScript + Tailwind)
├─ docs/images/      Screenshots
├─ docker-compose.yml   Full-stack deployment (MySQL + API + SPA)
└─ .env.example        Environment variables template
```

## Prerequisites

- **Docker** with **Docker Compose** (easiest path), **or**
- **Java 21** and **Maven 3.9+** to run the backend locally,
- **Node.js 20+** and **npm** to run the frontend locally,
- **MySQL 8** if running the backend without Docker.

## Quick start (Docker Compose)

The whole stack runs with a single command:

```bash
cp .env.example .env        # then edit JWT_SECRET and DB passwords
docker compose up --build
```

Once up:

| Service  | URL                          |
| -------- | ---------------------------- |
| Frontend | http://localhost:3000        |
| API      | http://localhost:8080/api    |
| Swagger  | http://localhost:8080/swagger-ui.html |
| Health   | http://localhost:8080/actuator/health |

## Local development

Start the backend and frontend independently for fast iteration.

### 1. Backend

Flyway applies the schema automatically; create a MySQL database first
(any name matching `DB_NAME`, default `taskmanager`).

```bash
cd backend

# Option A: point the backend at a MySQL container
docker compose up -d mysql

# export the required environment (adjust values as needed)
export DB_HOST=localhost DB_PORT=3306 DB_NAME=taskmanager
export DB_USERNAME=taskuser DB_PASSWORD=task_password
export JWT_SECRET="$(openssl rand -base64 48)"

mvn spring-boot:run   # starts on http://localhost:8080 (profile "local")
```

Run the backend tests:

```bash
cd backend
mvn test
```

### 2. Frontend

```bash
cd frontend
npm install
cp .env.example .env    # VITE_API_URL defaults to http://localhost:8080
npm run dev             # starts on http://localhost:5173
```

Run the frontend tests:

```bash
cd frontend
npm test                # watch mode: npm run test:watch
```

### 3. Login and explore

Register an account from the register page, then log in to reach the
dashboard and start creating tasks.

## Configuration

Environment variables are read from the root `.env` by Docker Compose and
by the backend container. The frontend uses its **own** file,
`frontend/.env` (see `frontend/.env.example`).

| Variable                | Default           | Description                                        |
| ----------------------- | ----------------- | -------------------------------------------------- |
| `MYSQL_ROOT_PASSWORD`   | —                 | MySQL root password (container only)               |
| `DB_NAME`               | `taskmanager`     | Database name                                      |
| `DB_USERNAME` / `DB_PASSWORD` | `taskuser` / `task_password` | DB credentials                         |
| `JWT_SECRET`            | **required**      | ≥ 32 bytes (256 bits); generate with `openssl rand -base64 48` |
| `JWT_EXPIRATION`        | `86400000`        | Token lifetime in ms (24 h)                        |
| `CORS_ALLOWED_ORIGINS`  | `http://localhost:5173` | Comma-separated allowed browser origins      |
| `BACKEND_PORT` / `FRONTEND_PORT` | `8080` / `3000` | Published host ports                 |
| `VITE_API_URL`          | `/api`            | API base URL used by the SPA (frontend `.env`)     |

## API overview

Base URL: `/api` (all task endpoints require `Authorization: Bearer <jwt>`).

| Method | Path            | Description                                  |
| ------ | --------------- | -------------------------------------------- |
| POST   | `/api/auth/register` | Register and receive a JWT               |
| POST   | `/api/auth/login`    | Log in and receive a JWT                 |
| GET    | `/api/tasks`    | List my tasks (`status`, `search`, `page`, `size`) |
| POST   | `/api/tasks`    | Create a task                              |
| PUT    | `/api/tasks/{id}` | Update one of my tasks                   |
| DELETE | `/api/tasks/{id}` | Delete one of my tasks                   |

Errors are returned as:

```json
{ "timestamp": "…", "status": 404, "error": "Not Found", "message": "…", "path": "…" }
```

## Useful commands

```bash
mvn test         # backend unit + integration tests (H2)
mvn package      # build the backend jar
npm test         # frontend tests (Vitest)
npm run build    # type-check + production build (frontend)
```