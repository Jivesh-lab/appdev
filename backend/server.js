require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { body, validationResult } = require('express-validator');
const db = require('./db');
const { writeSignal, readSignals, firebaseEnabled } = require('./firebase');

// ─── Helper: Generate unique 4-char alphanumeric session code ─────────────────
function generateSessionCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I to avoid confusion
  let code = '';
  for (let i = 0; i < 4; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

const app = express();
const PORT = process.env.PORT || 8000;
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_change_me';

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── verifyToken Middleware ───────────────────────────────────────────────────
function verifyToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer <token>

  if (!token) {
    return res.status(401).json({ success: false, message: 'Access denied. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded; // { userId, role, email }
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
  }
}

// ─── Routes ───────────────────────────────────────────────────────────────────

/**
 * GET /api/health
 * Public health check
 */
app.get('/api/health', (req, res) => {
  res.status(200).json({ success: true, message: 'ClassPulse API is running' });
});

/**
 * POST /api/auth/signup
 * Register a new teacher account
 */
app.post('/api/auth/signup',
  [
    body('name').notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('role').notEmpty().withMessage('Role is required'),
  ],
  async (req, res) => {
    // Validate inputs
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, message: errors.array()[0].msg });
    }

    try {
      const { name, email, password, role } = req.body;

      // Hash password
      const hashedPassword = await bcrypt.hash(password, 10);

      // Insert user
      db.run(
        'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
        [name, email, hashedPassword, role],
        function (err) {
          if (err) {
            if (err.message.includes('UNIQUE constraint failed')) {
              return res.status(400).json({ success: false, message: 'Email already registered' });
            }
            console.error('Signup DB error:', err);
            return res.status(500).json({ success: false, message: 'Error creating account' });
          }

          res.status(201).json({
            success: true,
            message: 'Account created successfully. Please login.',
            user: { id: this.lastID, name, email, role }
          });
        }
      );
    } catch (error) {
      console.error('Signup error:', error);
      res.status(500).json({ success: false, message: 'Server error during signup' });
    }
  }
);

/**
 * POST /api/auth/login
 * Authenticate teacher — returns signed JWT
 */
app.post('/api/auth/login',
  [
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, message: errors.array()[0].msg });
    }

    try {
      const { email, password } = req.body;

      db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
        if (err) {
          console.error('Login DB error:', err);
          return res.status(500).json({ success: false, message: 'Server error' });
        }

        if (!user) {
          return res.status(401).json({ success: false, message: 'Invalid email or password' });
        }

        // Verify password
        const passwordMatch = await bcrypt.compare(password, user.password);
        if (!passwordMatch) {
          return res.status(401).json({ success: false, message: 'Invalid email or password' });
        }

        // Sign JWT
        const token = jwt.sign(
          { userId: user.id, role: user.role, email: user.email },
          JWT_SECRET,
          { expiresIn: '24h' }
        );

        res.status(200).json({
          success: true,
          message: 'Login successful',
          token,
          user: { id: user.id, name: user.name, email: user.email, role: user.role }
        });
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ success: false, message: 'Server error during login' });
    }
  }
);

/**
 * GET /api/users/:id
 * Get user details by ID — PROTECTED
 */
app.get('/api/users/:id', verifyToken, (req, res) => {
  const { id } = req.params;

  db.get(
    'SELECT id, name, email, role, created_at FROM users WHERE id = ?',
    [id],
    (err, user) => {
      if (err) {
        console.error('Get user DB error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
      }
      if (!user) {
        return res.status(404).json({ success: false, message: 'User not found' });
      }
      res.status(200).json({ success: true, user });
    }
  );
});

/**
 * POST /api/sessions/create
 * Create a new session — PROTECTED (teacher only)
 * Generates a unique 4-char alphanumeric code with retry on collision
 */
app.post('/api/sessions/create', verifyToken, (req, res) => {
  try {
    const { classCode, className } = req.body;
    const teacherId = req.user.userId;

    if (!className) {
      return res.status(400).json({ success: false, message: 'Class name is required' });
    }

    // Retry up to 5 times to get a unique code
    const tryInsert = (attempt) => {
      if (attempt > 5) {
        return res.status(500).json({ success: false, message: 'Could not generate unique session code. Try again.' });
      }

      const code = generateSessionCode();
      const sessionId = `session_${code}_${Date.now()}`;
      const link = `classpulse://join/${code}`;

      db.run(
        'INSERT INTO sessions (id, class_code, class_name, teacher_id, session_code, join_link, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [sessionId, classCode || 'DEFAULT', className, teacherId, code, link, 'active'],
        function (err) {
          if (err) {
            if (err.message.includes('UNIQUE constraint failed')) {
              return tryInsert(attempt + 1); // retry with new code
            }
            console.error('Create session DB error:', err);
            return res.status(500).json({ success: false, message: 'Error creating session' });
          }

          res.status(201).json({
            success: true,
            message: 'Session created successfully',
            session: { id: sessionId, code, sessionCode: code, joinLink: link, studentCount: 0 }
          });
        }
      );
    };

    tryInsert(1);
  } catch (error) {
    console.error('Create session error:', error);
    res.status(500).json({ success: false, message: 'Server error during session creation' });
  }
});

/**
 * GET /api/sessions/:code
 * Get session info — PUBLIC (students use this)
 */
app.get('/api/sessions/:code', (req, res) => {
  const { code } = req.params;

  db.get(
    `SELECT s.id, s.session_code, s.class_name, s.join_link, s.is_active, s.status,
            s.student_count, u.name as teacher_name
     FROM sessions s
     LEFT JOIN users u ON s.teacher_id = u.id
     WHERE s.session_code = ?`,
    [code],
    (err, session) => {
      if (err) {
        console.error('Get session DB error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
      }
      if (!session) {
        return res.status(404).json({ success: false, message: 'Session not found' });
      }
      if (session.status === 'ended') {
        return res.status(410).json({ success: false, message: 'This session has ended' });
      }

      res.status(200).json({
        success: true,
        session: {
          id: session.id,
          sessionCode: session.session_code,
          className: session.class_name,
          joinLink: session.join_link,
          isActive: session.is_active,
          status: session.status,
          teacherName: session.teacher_name,
          studentCount: session.student_count || 0
        }
      });
    }
  );
});

/**
 * POST /api/sessions/:code/join
 * Student joins a session — PUBLIC (no auth)
 * Returns an anonymous_student_token (UUID) for this student's session
 */
app.post('/api/sessions/:code/join', (req, res) => {
  const { code } = req.params;
  const { studentName, studentEmail } = req.body;

  db.get(
    'SELECT id, session_code, status FROM sessions WHERE session_code = ?',
    [code],
    (err, session) => {
      if (err) {
        console.error('Join session DB error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
      }
      if (!session) {
        return res.status(404).json({ success: false, message: 'Session not found' });
      }
      if (session.status === 'ended') {
        return res.status(410).json({ success: false, message: 'This session has ended' });
      }

      const studentToken = crypto.randomUUID();

      // Add student record with token
      db.run(
        'INSERT INTO students_joined (session_code, student_name, student_email, student_token) VALUES (?, ?, ?, ?)',
        [code, studentName || 'Anonymous Student', studentEmail || null, studentToken],
        function (insertErr) {
          if (insertErr) {
            console.error('Insert student DB error:', insertErr);
            return res.status(500).json({ success: false, message: 'Error joining session' });
          }

          // Update student_count on sessions table
          db.run(
            'UPDATE sessions SET student_count = (SELECT COUNT(*) FROM students_joined WHERE session_code = ?) WHERE session_code = ?',
            [code, code],
            (updateErr) => {
              if (updateErr) console.error('Update student count error:', updateErr);
            }
          );

          // Get updated count
          db.get(
            'SELECT COUNT(*) as count FROM students_joined WHERE session_code = ?',
            [code],
            (countErr, countResult) => {
              if (countErr) {
                return res.status(500).json({ success: false, message: 'Error getting student count' });
              }
              res.status(200).json({
                success: true,
                message: 'Successfully joined session',
                sessionId: session.id,
                code,
                anonymous_student_token: studentToken,
                studentCount: countResult.count
              });
            }
          );
        }
      );
    }
  );
});

/**
 * POST /api/sessions/:code/end
 * End a session — PROTECTED (teacher who created it only)
 * Writes final aggregates to session_summary table
 */
app.post('/api/sessions/:code/end', verifyToken, (req, res) => {
  const { code } = req.params;
  const teacherId = req.user.userId;

  db.get(
    'SELECT * FROM sessions WHERE session_code = ?',
    [code],
    (err, session) => {
      if (err) {
        console.error('End session DB error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
      }
      if (!session) {
        return res.status(404).json({ success: false, message: 'Session not found' });
      }
      if (session.teacher_id !== teacherId) {
        return res.status(403).json({ success: false, message: 'Only the session creator can end it' });
      }
      if (session.status === 'ended') {
        return res.status(400).json({ success: false, message: 'Session already ended' });
      }

      const endedAt = new Date().toISOString();

      // Mark session as ended
      db.run(
        'UPDATE sessions SET status = ?, is_active = 0, ended_at = ? WHERE session_code = ?',
        ['ended', endedAt, code],
        (updateErr) => {
          if (updateErr) {
            console.error('End session update error:', updateErr);
            return res.status(500).json({ success: false, message: 'Error ending session' });
          }

          // Aggregate feedback counts from feedback_log
          db.get(
            `SELECT
               COUNT(*) as total,
               SUM(CASE WHEN signal_type = 'got_it' THEN 1 ELSE 0 END) as got_it_count,
               SUM(CASE WHEN signal_type = 'sort_of' THEN 1 ELSE 0 END) as sort_of_count,
               SUM(CASE WHEN signal_type = 'lost' THEN 1 ELSE 0 END) as lost_count
             FROM feedback_log WHERE session_code = ?`,
            [code],
            (aggErr, agg) => {
              if (aggErr) {
                console.error('Aggregation error:', aggErr);
              }

              const totalStudents = session.student_count || 0;
              const gotIt = (agg && agg.got_it_count) || 0;
              const sortOf = (agg && agg.sort_of_count) || 0;
              const lost = (agg && agg.lost_count) || 0;

              // Count questions
              db.get(
                'SELECT COUNT(*) as qcount FROM questions WHERE session_code = ?',
                [code],
                (qErr, qResult) => {
                  const questionCount = (qResult && qResult.qcount) || 0;

                  // Write summary row
                  db.run(
                    `INSERT OR REPLACE INTO session_summary
                       (session_code, started_at, ended_at, total_students, got_it_count, sort_of_count, lost_count, question_count)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                    [code, session.start_time, endedAt, totalStudents, gotIt, sortOf, lost, questionCount],
                    (summaryErr) => {
                      if (summaryErr) {
                        console.error('Summary write error:', summaryErr);
                      }

                      const startTime = new Date(session.start_time).getTime();
                      const endTime = new Date(endedAt).getTime();
                      const durationMinutes = Math.round((endTime - startTime) / 60000);

                      res.status(200).json({
                        success: true,
                        message: 'Session ended',
                        summary: {
                          sessionCode: code,
                          className: session.class_name,
                          startedAt: session.start_time,
                          endedAt,
                          durationMinutes,
                          totalStudents,
                          gotItCount: gotIt,
                          sortOfCount: sortOf,
                          lostCount: lost,
                          questionCount
                        }
                      });
                    }
                  );
                }
              );
            }
          );
        }
      );
    }
  );
});

/**
 * GET /api/sessions/:code/summary
 * Retrieve session summary — PROTECTED (teacher only)
 */
app.get('/api/sessions/:code/summary', verifyToken, (req, res) => {
  const { code } = req.params;

  db.get(
    'SELECT * FROM session_summary WHERE session_code = ?',
    [code],
    (err, summary) => {
      if (err) {
        console.error('Get summary DB error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
      }
      if (!summary) {
        return res.status(404).json({ success: false, message: 'Summary not found. Session may still be active.' });
      }

      const startTime = new Date(summary.started_at).getTime();
      const endTime = new Date(summary.ended_at).getTime();
      const durationMinutes = Math.round((endTime - startTime) / 60000);

      // Also get question list
      db.all(
        'SELECT id, text, timestamp, is_answered FROM questions WHERE session_code = ? ORDER BY timestamp ASC',
        [code],
        (qErr, questions) => {
          res.status(200).json({
            success: true,
            summary: {
              sessionCode: code,
              startedAt: summary.started_at,
              endedAt: summary.ended_at,
              durationMinutes,
              totalStudents: summary.total_students,
              gotItCount: summary.got_it_count,
              sortOfCount: summary.sort_of_count,
              lostCount: summary.lost_count,
              questionCount: summary.question_count,
              questions: questions || []
            }
          });
        }
      );
    }
  );
});

// ─── Phase 3: Feedback Signal APIs ───────────────────────────────────────────

/**
 * POST /api/sessions/:code/feedback
 * Student submits or changes their signal — PUBLIC (uses anonymous_student_token)
 * Upserts into feedback_log (one row per student per session)
 * Also writes to Firestore: sessions/{code}/signals/{student_token}
 */
app.post('/api/sessions/:code/feedback', async (req, res) => {
  const { code } = req.params;
  const { signal, student_token } = req.body;

  // Validate
  if (!signal || !['got_it', 'sort_of', 'lost'].includes(signal)) {
    return res.status(400).json({ success: false, message: 'signal must be got_it, sort_of, or lost' });
  }
  if (!student_token) {
    return res.status(400).json({ success: false, message: 'student_token is required' });
  }

  // Verify session is active
  db.get('SELECT status FROM sessions WHERE session_code = ?', [code], async (err, session) => {
    if (err) return res.status(500).json({ success: false, message: 'Server error' });
    if (!session) return res.status(404).json({ success: false, message: 'Session not found' });
    if (session.status === 'ended') return res.status(410).json({ success: false, message: 'Session has ended' });

    // Upsert: INSERT OR REPLACE updates the signal if student_token already exists
    db.run(
      `INSERT INTO feedback_log (session_code, student_token, signal_type, timestamp)
       VALUES (?, ?, ?, CURRENT_TIMESTAMP)
       ON CONFLICT(session_code, student_token)
       DO UPDATE SET signal_type = excluded.signal_type, timestamp = excluded.timestamp`,
      [code, student_token, signal],
      async (dbErr) => {
        if (dbErr) {
          console.error('Feedback upsert error:', dbErr);
          return res.status(500).json({ success: false, message: 'Error saving feedback' });
        }

        // Write to Firestore (non-blocking, fire-and-forget)
        await writeSignal(code, student_token, signal);

        res.status(200).json({ received: true, signal, student_token });
      }
    );
  });
});

/**
 * GET /api/sessions/:code/feedback/aggregate
 * Teacher gets live aggregate counts — PROTECTED
 * Reads from SQLite feedback_log (source of truth)
 * Checks lost_percentage against session's alert_threshold
 */
app.get('/api/sessions/:code/feedback/aggregate', verifyToken, (req, res) => {
  const { code } = req.params;

  // Get alert threshold for this session
  db.get('SELECT alert_threshold FROM sessions WHERE session_code = ?', [code], (tErr, sess) => {
    if (tErr) return res.status(500).json({ success: false, message: 'Server error' });
    if (!sess) return res.status(404).json({ success: false, message: 'Session not found' });

    const threshold = (sess.alert_threshold != null ? sess.alert_threshold : 40);

    // Aggregate from feedback_log
    db.get(
      `SELECT
         COUNT(*) as total,
         SUM(CASE WHEN signal_type = 'got_it'  THEN 1 ELSE 0 END) as got_it,
         SUM(CASE WHEN signal_type = 'sort_of' THEN 1 ELSE 0 END) as sort_of,
         SUM(CASE WHEN signal_type = 'lost'    THEN 1 ELSE 0 END) as lost
       FROM feedback_log WHERE session_code = ?`,
      [code],
      (err, row) => {
        if (err) {
          console.error('Aggregate query error:', err);
          return res.status(500).json({ success: false, message: 'Server error' });
        }

        const total     = row.total    || 0;
        const gotIt     = row.got_it   || 0;
        const sortOf    = row.sort_of  || 0;
        const lost      = row.lost     || 0;
        const lostPct   = total > 0 ? Math.round((lost / total) * 100) : 0;
        const alert     = lostPct >= threshold;

        res.status(200).json({
          success: true,
          got_it: gotIt,
          sort_of: sortOf,
          lost,
          total,
          lost_percentage: lostPct,
          alert,
          threshold,
          firebase_realtime: firebaseEnabled
        });
      }
    );
  });
});

/**
 * PATCH /api/sessions/:code/threshold
 * Teacher updates the lost-signal alert threshold — PROTECTED
 */
app.patch('/api/sessions/:code/threshold', verifyToken, (req, res) => {
  const { code } = req.params;
  const { threshold } = req.body;
  const teacherId = req.user.userId;

  if (threshold === undefined || typeof threshold !== 'number' || threshold < 0 || threshold > 100) {
    return res.status(400).json({ success: false, message: 'threshold must be a number between 0 and 100' });
  }

  db.get('SELECT teacher_id FROM sessions WHERE session_code = ?', [code], (err, session) => {
    if (err) return res.status(500).json({ success: false, message: 'Server error' });
    if (!session) return res.status(404).json({ success: false, message: 'Session not found' });
    if (session.teacher_id !== teacherId) {
      return res.status(403).json({ success: false, message: 'Not authorized to modify this session' });
    }

    db.run(
      'UPDATE sessions SET alert_threshold = ? WHERE session_code = ?',
      [threshold, code],
      (updateErr) => {
        if (updateErr) {
          console.error('Threshold update error:', updateErr);
          return res.status(500).json({ success: false, message: 'Error updating threshold' });
        }
        res.status(200).json({ updated: true, threshold });
      }
    );
  });
});

// ─── Phase 4: Questions API ───────────────────────────────────────────────────

/**
 * POST /api/sessions/:code/questions
 * Student submits an anonymous question — PUBLIC (uses student_token)
 */
app.post('/api/sessions/:code/questions', (req, res) => {
  const { code } = req.params;
  const { text, student_token } = req.body;

  if (!text || text.trim().length === 0) {
    return res.status(400).json({ success: false, message: 'Question text is required' });
  }
  if (!student_token) {
    return res.status(400).json({ success: false, message: 'student_token is required' });
  }

  // Verify session is active
  db.get('SELECT status FROM sessions WHERE session_code = ?', [code], (err, session) => {
    if (err) return res.status(500).json({ success: false, message: 'Server error' });
    if (!session) return res.status(404).json({ success: false, message: 'Session not found' });
    if (session.status === 'ended') {
      return res.status(410).json({ success: false, message: 'Session has ended' });
    }

    db.run(
      'INSERT INTO questions (session_code, student_token, text) VALUES (?, ?, ?)',
      [code, student_token, text.trim()],
      function (insertErr) {
        if (insertErr) {
          console.error('Insert question DB error:', insertErr);
          return res.status(500).json({ success: false, message: 'Error saving question' });
        }

        res.status(201).json({
          success: true,
          question: {
            id: this.lastID,
            sessionCode: code,
            text: text.trim(),
            isAnswered: false,
            timestamp: new Date().toISOString()
          }
        });
      }
    );
  });
});

/**
 * GET /api/sessions/:code/questions
 * Teacher retrieves all questions for a session — PROTECTED
 */
app.get('/api/sessions/:code/questions', verifyToken, (req, res) => {
  const { code } = req.params;

  db.all(
    'SELECT id, text, timestamp, is_answered FROM questions WHERE session_code = ? ORDER BY timestamp ASC',
    [code],
    (err, rows) => {
      if (err) {
        console.error('Get questions DB error:', err);
        return res.status(500).json({ success: false, message: 'Server error' });
      }

      res.status(200).json({
        success: true,
        questions: (rows || []).map(q => ({
          id: q.id,
          text: q.text,
          timestamp: q.timestamp,
          isAnswered: q.is_answered === 1
        }))
      });
    }
  );
});

/**
 * PATCH /api/sessions/:code/questions/:id/answer
 * Teacher marks a question as answered — PROTECTED
 */
app.patch('/api/sessions/:code/questions/:id/answer', verifyToken, (req, res) => {
  const { code, id } = req.params;
  const teacherId = req.user.userId;

  // Verify this teacher owns the session
  db.get('SELECT teacher_id FROM sessions WHERE session_code = ?', [code], (err, session) => {
    if (err) return res.status(500).json({ success: false, message: 'Server error' });
    if (!session) return res.status(404).json({ success: false, message: 'Session not found' });
    if (session.teacher_id !== teacherId) {
      return res.status(403).json({ success: false, message: 'Not authorized for this session' });
    }

    db.run(
      'UPDATE questions SET is_answered = 1 WHERE id = ? AND session_code = ?',
      [id, code],
      function (updateErr) {
        if (updateErr) {
          console.error('Mark answered DB error:', updateErr);
          return res.status(500).json({ success: false, message: 'Error updating question' });
        }
        if (this.changes === 0) {
          return res.status(404).json({ success: false, message: 'Question not found' });
        }

        res.status(200).json({ success: true, id: parseInt(id), isAnswered: true });
      }
    );
  });
});

// ─── Start Server ──────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🚀 ClassPulse Backend running on http://localhost:${PORT}`);
  console.log(`\n📋 Endpoints:`);
  console.log(`   [PUBLIC]    GET    /api/health`);
  console.log(`   [PUBLIC]    POST   /api/auth/signup`);
  console.log(`   [PUBLIC]    POST   /api/auth/login`);
  console.log(`   [PROTECTED] GET    /api/users/:id`);
  console.log(`   [PROTECTED] POST   /api/sessions/create`);
  console.log(`   [PUBLIC]    GET    /api/sessions/:code`);
  console.log(`   [PUBLIC]    POST   /api/sessions/:code/join`);
  console.log(`   [PROTECTED] POST   /api/sessions/:code/end`);
  console.log(`   [PROTECTED] GET    /api/sessions/:code/summary`);
  console.log(`   [PUBLIC]    POST   /api/sessions/:code/feedback`);
  console.log(`   [PROTECTED] GET    /api/sessions/:code/feedback/aggregate`);
  console.log(`   [PROTECTED] PATCH  /api/sessions/:code/threshold`);
  console.log(`   [PUBLIC]    POST   /api/sessions/:code/questions`);
  console.log(`   [PROTECTED] GET    /api/sessions/:code/questions`);
  console.log(`   [PROTECTED] PATCH  /api/sessions/:code/questions/:id/answer\n`);
});
