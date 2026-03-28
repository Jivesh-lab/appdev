const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Create/open SQLite database
const db = new sqlite3.Database(path.join(__dirname, 'classpulse.db'), (err) => {
  if (err) {
    console.error('Error opening database:', err);
  } else {
    console.log('Connected to SQLite database');
  }
});

// Initialize database schema
db.serialize(() => {
  // Create users table
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `, (err) => {
    if (err) {
      console.error('Error creating users table:', err);
    } else {
      console.log('Users table ready');
    }
  });

  // Create sessions table
  db.run(`
    CREATE TABLE IF NOT EXISTS sessions (
      id TEXT PRIMARY KEY,
      class_code TEXT NOT NULL,
      class_name TEXT NOT NULL,
      teacher_id INTEGER NOT NULL,
      session_code TEXT UNIQUE NOT NULL,
      join_link TEXT NOT NULL,
      start_time DATETIME DEFAULT CURRENT_TIMESTAMP,
      is_active BOOLEAN DEFAULT 1,
      FOREIGN KEY(teacher_id) REFERENCES users(id)
    )
  `, (err) => {
    if (err) {
      console.error('Error creating sessions table:', err);
    } else {
      console.log('Sessions table ready');
    }
  });

  // Create students_joined table
  db.run(`
    CREATE TABLE IF NOT EXISTS students_joined (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_code TEXT NOT NULL,
      student_name TEXT,
      student_email TEXT,
      joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(session_code) REFERENCES sessions(session_code)
    )
  `, (err) => {
    if (err) {
      console.error('Error creating students_joined table:', err);
    } else {
      console.log('Students joined table ready');
    }
  });
});

module.exports = db;
