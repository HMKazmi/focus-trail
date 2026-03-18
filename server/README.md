# FocusTrail Server

Production-style Express REST API for the FocusTrail Productivity Tracker.

**Stack:** Node.js · Express · TypeScript · MongoDB (Mongoose) · JWT Auth · Zod validation · Swagger/OpenAPI 3

---

## Quick Start

### 1. Prerequisites

- Node.js ≥ 18
- MongoDB running locally **or** a connection string (e.g. MongoDB Atlas)

### 2. Install dependencies

```bash
cd server
npm install
```

### 3. Configure environment

```bash
cp .env.example .env
```

Edit `.env`:

```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/focustrail
JWT_SECRET=replace_with_a_long_random_secret_32_chars_min
JWT_EXPIRES_IN=7d
CORS_ORIGINS=http://localhost:3000,chrome-extension://your-extension-id
```

### 4. Run in development

```bash
npm run dev
```

### 5. Build for production

```bash
npm run build    # compiles TypeScript → dist/
npm start        # runs dist/server.js
```

---

## API Documentation (Swagger)

Once the server is running, open:

```
http://localhost:3000/docs
```

Click **Authorize** → enter your JWT token (`Bearer <token>`) to test protected routes.

---

## Available Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start with ts-node-dev (hot reload) |
| `npm run build` | Compile TypeScript |
| `npm start` | Run compiled output |
| `npm test` | Run integration tests (Vitest + Supertest + mongo-memory-server) |
| `npm run lint` | ESLint |
| `npm run lint:fix` | ESLint auto-fix |
| `npm run format` | Prettier format |

---

## Project Structure

```
src/
├── app.ts                  # Express app wiring (middleware, routes)
├── server.ts               # Entry point (DB connect + listen)
├── config/
│   ├── env.ts              # Validated env config
│   └── db.ts               # MongoDB connection
├── modules/
│   ├── auth/
│   │   ├── auth.routes.ts
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   └── auth.schemas.ts  # Zod schemas
│   └── tasks/
│       ├── tasks.routes.ts
│       ├── tasks.controller.ts
│       ├── tasks.service.ts
│       └── tasks.schemas.ts
├── models/
│   ├── User.ts
│   └── Task.ts
├── middlewares/
│   ├── auth.ts             # JWT authentication
│   ├── validate.ts         # Zod request validation
│   └── error.ts            # Centralized error handler
├── utils/
│   ├── ApiError.ts         # Typed API error class
│   ├── jwt.ts              # sign/verify helpers
│   └── password.ts         # bcrypt helpers
├── docs/
│   └── openapi.ts          # OpenAPI 3 spec
└── tests/
    ├── setup.ts            # Vitest global setup (mongo-memory-server)
    ├── auth.test.ts
    └── tasks.test.ts
```

---

## Endpoints

### Auth

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/auth/register` | — | Register new user |
| POST | `/api/auth/login` | — | Login, receive JWT |
| GET | `/api/auth/me` | ✓ | Get current user |

### Tasks

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/tasks` | ✓ | List tasks (filter/search/sort) |
| POST | `/api/tasks` | ✓ | Create task |
| GET | `/api/tasks/:id` | ✓ | Get task by ID |
| PUT | `/api/tasks/:id` | ✓ | Full update |
| PATCH | `/api/tasks/:id` | ✓ | Partial update |
| DELETE | `/api/tasks/:id` | ✓ | Delete task |

### Query params for `GET /api/tasks`

| Param | Type | Example | Description |
|-------|------|---------|-------------|
| `status` | string | `todo` | Filter by status (`todo`, `in_progress`, `done`) |
| `search` | string | `report` | Search title & description |
| `sort` | string | `createdAt` | Sort field (default: `updatedAt`, always desc) |

---

## Sample curl commands

### Register

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","password":"password123","name":"Alice"}'
```

### Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","password":"password123"}'
```

> Copy the `accessToken` from the response.

### Create a task

```bash
curl -X POST http://localhost:3000/api/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"title":"Finish report","description":"Q3 summary","dueDate":"2026-04-01T00:00:00Z"}'
```

### List tasks (with filters)

```bash
# All tasks
curl http://localhost:3000/api/tasks \
  -H "Authorization: Bearer <token>"

# Filter by status + search
curl "http://localhost:3000/api/tasks?status=todo&search=report" \
  -H "Authorization: Bearer <token>"
```

### Update task status

```bash
curl -X PATCH http://localhost:3000/api/tasks/<task-id> \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"status":"done"}'
```

### Delete a task

```bash
curl -X DELETE http://localhost:3000/api/tasks/<task-id> \
  -H "Authorization: Bearer <token>"
```

---

## Error Response Format

All errors follow a consistent shape:

```json
{
  "success": false,
  "error": {
    "message": "Invalid credentials",
    "statusCode": 401
  }
}
```

## Success Response Format

```json
{
  "success": true,
  "data": { ... }
}
```
