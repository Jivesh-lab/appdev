const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes

/**
 * POST /api/auth/signup
 * Register a new teacher account
 */
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    // Validation
    if (!name || !email || !password || !role) {
      return res.status(400).json({ 
        success: false, 
        message: 'All fields are required' 
      });
    }

    if (password.length < 6) {
      return res.status(400).json({ 
        success: false, 
        message: 'Password must be at least 6 characters' 
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert user into database
    db.run(
      'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
      [name, email, hashedPassword, role],
      function(err) {
        if (err) {
          if (err.message.includes('UNIQUE constraint failed')) {
            return res.status(400).json({ 
              success: false, 
              message: 'Email already registered' 
            });
          }
          console.error('Database error:', err);
          return res.status(500).json({ 
            success: false, 
            message: 'Error creating account' 
          });
        }

        // Return success
        res.status(201).json({ 
          success: true, 
          message: 'Account created successfully. Please login with your credentials.',
          user: {
            id: this.lastID,
            name,
            email,
            role
          }
        });
      }
    );
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during signup' 
    });
  }
});

/**
 * POST /api/auth/login
 * Authenticate teacher and return user data
 */
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password, role } = req.body;

    // Validation
    if (!email || !password || !role) {
      return res.status(400).json({ 
        success: false, 
        message: 'Email and password are required' 
      });
    }

    // Find user in database
    db.get(
      'SELECT * FROM users WHERE email = ?',
      [email],
      async (err, user) => {
        if (err) {
          console.error('Database error:', err);
          return res.status(500).json({ 
            success: false, 
            message: 'Server error' 
          });
        }

        if (!user) {
          return res.status(401).json({ 
            success: false, 
            message: 'Invalid email or password' 
          });
        }

        // Verify password
        const passwordMatch = await bcrypt.compare(password, user.password);

        if (!passwordMatch) {
          return res.status(401).json({ 
            success: false, 
            message: 'Invalid email or password' 
          });
        }

        // Return success with user data
        res.status(200).json({ 
          success: true, 
          message: 'Login successful',
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role
          }
        });
      }
    );
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during login' 
    });
  }
});

/**
 * GET /api/users/:id
 * Get user details by ID
 */
app.get('/api/users/:id', (req, res) => {
  try {
    const { id } = req.params;

    db.get(
      'SELECT id, name, email, role, created_at FROM users WHERE id = ?',
      [id],
      (err, user) => {
        if (err) {
          console.error('Database error:', err);
          return res.status(500).json({ 
            success: false, 
            message: 'Server error' 
          });
        }

        if (!user) {
          return res.status(404).json({ 
            success: false, 
            message: 'User not found' 
          });
        }

        res.status(200).json({ 
          success: true, 
          user 
        });
      }
    );
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error' 
    });
  }
});

/**
 * POST /api/sessions/create
 * Create a new session for a teacher
 */
app.post('/api/sessions/create', (req, res) => {
  try {
    const { classCode, className, teacherId, sessionCode, joinLink } = req.body;

    // Validation
    if (!sessionCode || !teacherId || !className) {
      return res.status(400).json({ 
        success: false, 
        message: 'Session code, teacher ID, and class name are required' 
      });
    }

    const sessionId = `session_${sessionCode}_${Date.now()}`;

    // Insert session into database
    db.run(
      'INSERT INTO sessions (id, class_code, class_name, teacher_id, session_code, join_link) VALUES (?, ?, ?, ?, ?, ?)',
      [sessionId, classCode || 'DEFAULT', className, teacherId, sessionCode, joinLink],
      function(err) {
        if (err) {
          if (err.message.includes('UNIQUE constraint failed')) {
            return res.status(400).json({ 
              success: false, 
              message: 'Session code already exists' 
            });
          }
          console.error('Database error:', err);
          return res.status(500).json({ 
            success: false, 
            message: 'Error creating session' 
          });
        }

        res.status(201).json({ 
          success: true, 
          message: 'Session created successfully',
          session: {
            id: sessionId,
            sessionCode,
            joinLink,
            studentCount: 0
          }
        });
      }
    );
  } catch (error) {
    console.error('Create session error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during session creation' 
    });
  }
});

/**
 * GET /api/sessions/:code
 * Get session details and student count
 */
app.get('/api/sessions/:code', (req, res) => {
  try {
    const { code } = req.params;

    db.get(
      'SELECT id, session_code, class_name, join_link, is_active FROM sessions WHERE session_code = ?',
      [code],
      (err, session) => {
        if (err) {
          console.error('Database error:', err);
          return res.status(500).json({ 
            success: false, 
            message: 'Server error' 
          });
        }

        if (!session) {
          return res.status(404).json({ 
            success: false, 
            message: 'Session not found' 
          });
        }

        // Count students joined
        db.get(
          'SELECT COUNT(*) as count FROM students_joined WHERE session_code = ?',
          [code],
          (countErr, countResult) => {
            if (countErr) {
              console.error('Count error:', countErr);
              return res.status(500).json({ 
                success: false, 
                message: 'Server error' 
              });
            }

            res.status(200).json({ 
              success: true, 
              session: {
                id: session.id,
                sessionCode: session.session_code,
                className: session.class_name,
                joinLink: session.join_link,
                isActive: session.is_active,
                studentCount: countResult.count || 0
              }
            });
          }
        );
      }
    );
  } catch (error) {
    console.error('Get session error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error' 
    });
  }
});

/**
 * POST /api/sessions/:code/join
 * Student joins a session
 */
app.post('/api/sessions/:code/join', (req, res) => {
  try {
    const { code } = req.params;
    const { studentName, studentEmail } = req.body;

    // First verify session exists
    db.get(
      'SELECT id, session_code FROM sessions WHERE session_code = ?',
      [code],
      (sessionErr, session) => {
        if (sessionErr) {
          console.error('Database error:', sessionErr);
          return res.status(500).json({ 
            success: false, 
            message: 'Server error' 
          });
        }

        if (!session) {
          return res.status(404).json({ 
            success: false, 
            message: 'Session not found' 
          });
        }

        // Add student to students_joined
        db.run(
          'INSERT INTO students_joined (session_code, student_name, student_email) VALUES (?, ?, ?)',
          [code, studentName || 'Anonymous Student', studentEmail || null],
          function(err) {
            if (err) {
              console.error('Database error:', err);
              return res.status(500).json({ 
                success: false, 
                message: 'Error joining session' 
              });
            }

            // Get updated student count
            db.get(
              'SELECT COUNT(*) as count FROM students_joined WHERE session_code = ?',
              [code],
              (countErr, countResult) => {
                if (countErr) {
                  console.error('Count error:', countErr);
                  return res.status(500).json({ 
                    success: false, 
                    message: 'Error getting student count' 
                  });
                }

                res.status(200).json({ 
                  success: true, 
                  message: 'Successfully joined session',
                  studentCount: countResult.count
                });
              }
            );
          }
        );
      }
    );
  } catch (error) {
    console.error('Join session error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during join' 
    });
  }
});

/**
 * Health check endpoint
 */
app.get('/api/health', (req, res) => {
  res.status(200).json({ 
    success: true, 
    message: 'ClassPulse API is running' 
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`\n🚀 ClassPulse Backend Server running on http://localhost:${PORT}`);
  console.log(`📝 API Documentation:`);
  console.log(`   POST   /api/auth/signup          - Register new teacher`);
  console.log(`   POST   /api/auth/login           - Login teacher`);
  console.log(`   GET    /api/users/:id            - Get user details`);
  console.log(`   POST   /api/sessions/create      - Create new session`);
  console.log(`   GET    /api/sessions/:code       - Get session with student count`);
  console.log(`   POST   /api/sessions/:code/join  - Student joins session`);
  console.log(`   GET    /api/health               - Health check\n`);
});
