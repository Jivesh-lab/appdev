# ClassPulse Backend

Node.js Express server with SQLite database for ClassPulse authentication and session management.

## Setup Instructions

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Start the Server
```bash
npm start
```

The server will start on `http://localhost:8000`

### 3. API Endpoints

#### Signup (Register New Teacher)
```
POST /api/auth/signup
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "role": "teacher"
}

Response (201):
{
  "success": true,
  "message": "Account created successfully. Please login with your credentials.",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "teacher"
  }
}
```

#### Login
```
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123",
  "role": "teacher"
}

Response (200):
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "teacher"
  }
}
```

#### Get User Details
```
GET /api/users/:id

Response (200):
{
  "success": true,
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "teacher",
    "created_at": "2024-03-28 10:30:00"
  }
}
```

#### Health Check
```
GET /api/health

Response (200):
{
  "success": true,
  "message": "ClassPulse API is running"
}
```

## Database

- **Type**: SQLite
- **File**: `classpulse.db`
- **Tables**: 
  - `users` - Teacher accounts (id, name, email, hashed_password, role, created_at)
  - `sessions` - Class sessions (id, class_code, class_name, teacher_id, session_code, join_link, start_time, is_active)

## Features

- ✅ User registration with email validation
- ✅ Password hashing with bcryptjs
- ✅ User authentication with email/password
- ✅ SQLite persistent database
- ✅ CORS enabled for Flutter web
- ✅ Error handling and validation
- ✅ Database schema auto-creation

## Development Notes

- Passwords are hashed using bcryptjs (salt rounds: 10)
- Email is unique constraint (no duplicate registrations)
- All responses include success flag and message
- Server runs on port 8000 (configurable via PORT env variable)
