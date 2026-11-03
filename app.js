const express = require('express');
const cors = require('cors');
const { randomBytes } = require('node:crypto');
const { hash, verify, Algorithm } = require('@node-rs/argon2');
const { rateLimit } = require('express-rate-limit');

function createApp(db) {
  const app = express();
  const dummyHash = hash(randomBytes(32), { algorithm: Algorithm.Argon2id });
  app.disable('x-powered-by');
  app.use(cors());
  app.use(express.json({ limit: '8kb' }));

  const loginLimit = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 20,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    message: { success: false, message: 'Too many login attempts. Please try again later.' },
  });

  app.post('/login', loginLimit, async (req, res, next) => {
    const { email, password } = req.body || {};
    if (typeof email !== 'string' || typeof password !== 'string'
      || email.trim().length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())
      || password.length === 0 || Buffer.byteLength(password, 'utf8') > 1024) {
      return res.status(400).json({ success: false, message: 'Provide a valid email and password.' });
    }

    try {
      const [users] = await db.execute(
        `SELECT user_id,email,password_hash,display_name,role,status,email_verified_at
         FROM users WHERE email = ? LIMIT 1`,
        [email.trim().toLowerCase()],
      );
      const user = users[0];
      const hasArgon2idHash = user?.password_hash?.startsWith('$argon2id$');
      // Keep unknown users on the password-verification path too.
      const matches = await verify(hasArgon2idHash ? user.password_hash : await dummyHash, password);
      if (!user || !hasArgon2idHash || !matches) {
        return res.status(401).json({ success: false, message: 'Invalid email or password.' });
      }
      if (user.status !== 'active' || !user.email_verified_at) {
        return res.status(403).json({ success: false, message: 'Verify your email and ensure your account is active.' });
      }
      return res.json({
        success: true,
        message: 'Login successful',
        user: { user_id: user.user_id, email: user.email, display_name: user.display_name, role: user.role },
      });
    } catch (error) {
      return next(error);
    }
  });

  app.use((error, req, res, next) => {
    if (error.type === 'entity.parse.failed') {
      return res.status(400).json({ success: false, message: 'Invalid JSON body.' });
    }
    if (error.type === 'entity.too.large') {
      return res.status(413).json({ success: false, message: 'Request body is too large.' });
    }
    console.error('Login request failed:', error.code || error.name);
    return res.status(500).json({ success: false, message: 'Unable to log in. Please try again later.' });
  });
  return app;
}

module.exports = { createApp };

if (require.main === module) {
  const db = require('./db_config');
  const port = Number(process.env.PORT || 3000);
  createApp(db.promise()).listen(port)
    .on('listening', () => console.log(`Server is running at ${port}`))
    .on('error', error => {
      console.error('Server failed to start:', error.code);
      db.end();
      process.exitCode = 1;
    });
}