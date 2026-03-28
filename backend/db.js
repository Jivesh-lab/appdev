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
  // ─── Existing Tables ──────────────────────────────────────────────────────

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
    if (err) console.error('Error creating users table:', err);
    else console.log('Users table ready');
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
      status TEXT DEFAULT 'active',
      ended_at DATETIME,
      alert_threshold INTEGER DEFAULT 40,
      student_count INTEGER DEFAULT 0,
      FOREIGN KEY(teacher_id) REFERENCES users(id)
    )
  `, (err) => {
    if (err) console.error('Error creating sessions table:', err);
    else console.log('Sessions table ready');
  });

  // Create students_joined table
  db.run(`
    CREATE TABLE IF NOT EXISTS students_joined (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_code TEXT NOT NULL,
      student_name TEXT,
      student_email TEXT,
      student_token TEXT,
      joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(session_code) REFERENCES sessions(session_code)
    )
  `, (err) => {
    if (err) console.error('Error creating students_joined table:', err);
    else console.log('Students joined table ready');
  });

  // ─── New Tables ───────────────────────────────────────────────────────────

  // Questions submitted by students (anonymous)
  db.run(`
    CREATE TABLE IF NOT EXISTS questions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_code TEXT NOT NULL,
      student_token TEXT,
      text TEXT NOT NULL,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
      is_answered INTEGER DEFAULT 0,
      FOREIGN KEY(session_code) REFERENCES sessions(session_code)
    )
  `, (err) => {
    if (err) console.error('Error creating questions table:', err);
    else console.log('Questions table ready');
  });

  // Feedback log — one row per student per session (upserted on signal change)
  db.run(`
    CREATE TABLE IF NOT EXISTS feedback_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_code TEXT NOT NULL,
      student_token TEXT NOT NULL,
      signal_type TEXT NOT NULL CHECK(signal_type IN ('got_it','sort_of','lost')),
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(session_code, student_token),
      FOREIGN KEY(session_code) REFERENCES sessions(session_code)
    )
  `, (err) => {
    if (err) console.error('Error creating feedback_log table:', err);
    else console.log('Feedback log table ready');
  });

  // Session summary — written when teacher ends a session
  db.run(`
    CREATE TABLE IF NOT EXISTS session_summary (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_code TEXT UNIQUE NOT NULL,
      started_at DATETIME,
      ended_at DATETIME,
      total_students INTEGER DEFAULT 0,
      lost_count INTEGER DEFAULT 0,
      sort_of_count INTEGER DEFAULT 0,
      got_it_count INTEGER DEFAULT 0,
      question_count INTEGER DEFAULT 0,
      FOREIGN KEY(session_code) REFERENCES sessions(session_code)
    )
  `, (err) => {
    if (err) console.error('Error creating session_summary table:', err);
    else console.log('Session summary table ready');
  });
});

module.exports = db;

