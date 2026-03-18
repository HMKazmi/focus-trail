# FocusTrail Backend API

> Node.js REST API backend with TypeScript, Express, and MongoDB

![Node.js](https://img.shields.io/badge/Node.js-20+-339933?logo=node.js)
![TypeScript](https://img.shields.io/badge/TypeScript-5.9-3178C6?logo=typescript)
![Express](https://img.shields.io/badge/Express-5.2-000000?logo=express)
![MongoDB](https://img.shields.io/badge/MongoDB-6.0+-47A248?logo=mongodb)

## 🚀 Overview

The FocusTrail backend is a robust REST API built with Node.js, TypeScript, and Express. It provides comprehensive task management endpoints with authentication, analytics, and real-time data synchronization capabilities.

## ✨ Features

### Core API Features
- **RESTful Architecture**: Clean, predictable API design
- **JWT Authentication**: Secure token-based auth
- **MongoDB Integration**: Efficient data storage with Mongoose
- **TypeScript**: Type-safe codebase
- **Input Validation**: Zod schema validation
- **Error Handling**: Comprehensive error management
- **Request Logging**: Detailed logging for debugging
- **API Documentation**: Interactive Swagger/OpenAPI docs

### Task Management
- CRUD operations for tasks
- Search and filtering
- Priority and status management
- Due date tracking
- Soft delete (trash bin)
- Bulk operations

### Analytics & Insights
- Dashboard statistics
- Completion trends
- Priority distribution
- Overdue task tracking
- Productivity metrics
- Time-series analytics

## 🏗️ Architecture

```
server/
├── src/
│   ├── config/              # Configuration files
│   │   ├── db.ts           # MongoDB connection
│   │   └── env.ts          # Environment variables
│   │
│   ├── middlewares/         # Express middlewares
│   │   ├── auth.ts         # JWT authentication
│   │   ├── validate.ts     # Schema validation
│   │   └── error.ts        # Error handling
│   │
│   ├── models/              # Mongoose models
│   │   ├── User.ts         # User model
│   │   └── Task.ts         # Task model
│   │
│   ├── modules/             # Feature modules
│   │   ├── auth/           # Authentication
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.routes.ts
│   │   │   └── auth.schemas.ts
│   │   │
│   │   └── tasks/          # Task management
│   │       ├── tasks.controller.ts
│   │       ├── tasks.service.ts
│   │       ├── tasks.routes.ts
│   │       └── tasks.schemas.ts
│   │
│   ├── utils/              # Utilities
│   │   ├── ApiError.ts    # Custom error class
│   │   ├── jwt.ts         # JWT utilities
│   │   ├── password.ts    # Password hashing
│   │   └── logger.ts      # Winston logger
│   │
│   ├── docs/              # API documentation
│   │   └── openapi.ts    # OpenAPI specification
│   │
│   ├── app.ts            # Express app setup
│   └── server.ts         # Server entry point
│
└── tests/                # Test files
    ├── auth.test.ts
    └── tasks.test.ts
```

## 🛠️ Tech Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Runtime | Node.js | 20+ |
| Language | TypeScript | 5.9.3 |
| Framework | Express | 5.2.1 |
| Database | MongoDB | 6.0+ |
| ODM | Mongoose | 9.3.0 |
| Validation | Zod | 3.23.8 |
| Authentication | jsonwebtoken | 9.0.2 |
| Password | bcryptjs | 2.4.3 |
| Testing | Vitest | 2.1.8 |
| Logging | Winston | 3.17.0 |
| Documentation | Swagger UI | 5.18.2 |

## 🚀 Getting Started

### Prerequisites

- Node.js 20 or higher
- MongoDB 6.0 or higher
- npm or yarn package manager

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/FocusTrail.git
   cd FocusTrail/server
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   
   Create `.env` file:
   ```env
   PORT=4000
   MONGODB_URI=mongodb://localhost:27017/focustrail
   JWT_SECRET=your-secret-key-here
   JWT_EXPIRES_IN=7d
   CORS_ORIGINS=http://localhost:3000
   NODE_ENV=development
   ```

4. **Start MongoDB**
   ```bash
   # macOS/Linux
   mongod --dbpath /path/to/data

   # Windows
   mongod --dbpath C:\data\db

   # Or use MongoDB Atlas (cloud)
   ```

5. **Run the server**
   ```bash
   # Development with hot reload
   npm run dev

   # Production
   npm run build
   npm start
   ```

The server will start at `http://localhost:4000`

## 📚 API Documentation

### Interactive Documentation

Access the Swagger UI at: `http://localhost:4000/docs`

### Main Endpoints

#### Authentication

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}
```

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

```http
GET /api/auth/me
Authorization: Bearer <token>
```

#### Tasks

```http
GET /api/tasks
Authorization: Bearer <token>
Query Parameters:
  - status: todo|in_progress|done
  - priority: low|medium|high
  - search: string
  - sort: createdAt|updatedAt|dueDate
```

```http
POST /api/tasks
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Complete project",
  "description": "Finish the FocusTrail app",
  "priority": "high",
  "status": "in_progress",
  "dueDate": "2026-03-25T10:00:00Z"
}
```

```http
PATCH /api/tasks/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "done"
}
```

```http
DELETE /api/tasks/:id
Authorization: Bearer <token>
```

#### Analytics

```http
GET /api/tasks/stats
Authorization: Bearer <token>
```

```http
GET /api/tasks/analytics/completion?period=week
Authorization: Bearer <token>
```

### Response Format

**Success Response:**
```json
{
  "success": true,
  "data": {
    // Response data
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "error": {
    "message": "Error description",
    "statusCode": 400
  }
}
```

## 🗄️ Database Schema

### User Model
```typescript
{
  email: string (unique, required)
  password: string (hashed, required)
  name: string (optional)
  createdAt: Date
  updatedAt: Date
}
```

### Task Model
```typescript
{
  userId: ObjectId (ref: User, required)
  title: string (required)
  description: string (optional)
  status: 'todo' | 'in_progress' | 'done'
  priority: 'low' | 'medium' | 'high'
  dueDate: Date (optional)
  reminderAt: Date (optional)
  deletedAt: Date (optional, for trash)
  createdAt: Date
  updatedAt: Date
}
```

## 🧪 Testing

### Run Tests
```bash
# Run all tests
npm test

# Watch mode
npm run test:watch

# Coverage report
npm run test:coverage
```

### Test Structure
```
tests/
├── auth.test.ts        # Authentication tests
├── tasks.test.ts       # Task CRUD tests
└── analytics.test.ts   # Analytics tests
```

### Example Test
```typescript
describe('POST /api/tasks', () => {
  it('should create a new task', async () => {
    const response = await request(app)
      .post('/api/tasks')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Test Task',
        priority: 'high'
      });
    
    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
  });
});
```

## 🔐 Security

### Authentication Flow
1. User registers or logs in
2. Server generates JWT token
3. Client stores token
4. Client sends token in Authorization header
5. Server validates token on protected routes

### Password Security
- Passwords hashed with bcryptjs (12 rounds)
- Never stored in plain text
- Validated on login

### JWT Configuration
```typescript
{
  expiresIn: '7d',
  algorithm: 'HS256'
}
```

### CORS Configuration
```typescript
cors({
  origin: (origin, callback) => {
    // Allow configured origins
    if (config.corsOrigins.includes(origin)) {
      callback(null, true);
    }
    // Allow Chrome extensions
    if (origin?.startsWith('chrome-extension://')) {
      callback(null, true);
    }
  },
  credentials: true
})
```

## 📊 Logging

The server uses Winston for comprehensive logging:

```typescript
// Log levels
logger.info('Server started on port 4000');
logger.success('User logged in successfully');
logger.warn('Invalid login attempt');
logger.error('Database connection failed', { error });
logger.debug('Processing request', { data });
```

### Log Format
```
2026-03-18T10:30:15.123Z [INFO] [Auth] Login attempt for: user@example.com
2026-03-18T10:30:15.456Z [SUCCESS] [Auth] Login successful: user@example.com
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Server port | 4000 |
| MONGODB_URI | MongoDB connection string | mongodb://localhost:27017/focustrail |
| JWT_SECRET | Secret for JWT signing | (required) |
| JWT_EXPIRES_IN | Token expiration | 7d |
| CORS_ORIGINS | Allowed origins (comma-separated) | http://localhost:3000 |
| NODE_ENV | Environment | development |

### MongoDB Connection Options
```typescript
{
  useNewUrlParser: true,
  useUnifiedTopology: true,
  serverSelectionTimeoutMS: 5000
}
```

## 🚢 Deployment

### Production Build
```bash
npm run build
npm start
```

### Docker Deployment
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist ./dist
EXPOSE 4000
CMD ["node", "dist/server.js"]
```

### Environment Setup
```bash
# Production environment
NODE_ENV=production
PORT=4000
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/focustrail
JWT_SECRET=secure-random-string
CORS_ORIGINS=https://focustrail.com,https://www.focustrail.com
```

## 📈 Performance

### Optimization Techniques
- Database indexing on frequently queried fields
- Connection pooling
- Response caching (where applicable)
- Pagination for large datasets
- Lazy loading of relations

### Monitoring
- Request/response logging
- Error tracking
- Performance metrics
- Database query optimization

## 🐛 Debugging

### Enable Debug Logs
```bash
LOG_LEVEL=debug npm run dev
```

### Common Issues

**Issue**: Cannot connect to MongoDB
```
Solution: Check MONGODB_URI in .env
         Ensure MongoDB is running
         Check network/firewall settings
```

**Issue**: JWT authentication fails
```
Solution: Verify JWT_SECRET is set
         Check token expiration
         Ensure Authorization header format: Bearer <token>
```

## 🔄 API Versioning

Currently using v1 (implicit). Future versions:
```
/api/v2/tasks
```

## 📦 Scripts

```json
{
  "dev": "ts-node-dev src/server.ts",
  "build": "tsc",
  "start": "node dist/server.js",
  "test": "vitest",
  "test:watch": "vitest --watch",
  "test:coverage": "vitest --coverage",
  "lint": "eslint src/**/*.ts",
  "lint:fix": "eslint src/**/*.ts --fix"
}
```

## 🤝 Contributing

1. Follow TypeScript best practices
2. Write tests for new features
3. Update API documentation
4. Run linter before committing
5. Ensure all tests pass

## 📄 License

This project is part of FocusTrail and is licensed under the MIT License.

---

For issues and questions, please refer to the main repository README.
