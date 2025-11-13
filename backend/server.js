// server.js
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { query } from './db.js';

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'dev';

// === yardımcılar ===
function signToken(user) {
  return jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
}

async function authMiddleware(req, res, next) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'No token' });

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    // user’ı çek
    const { rows } = await query('SELECT id, name, email FROM users WHERE id=$1', [payload.id]);
    if (rows.length === 0) return res.status(401).json({ error: 'Invalid token' });
    req.user = rows[0];
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// === Sağlık kontrolü ===
app.get('/', (req, res) => {
  res.json({ ok: true, api: 'FitTrack minimal backend', ver: 1 });
});

// === AUTH ===
app.post('/api/auth/register', async (req, res) => {
  const { name, email, password } = req.body ?? {};
  if (!name || !email || !password) return res.status(400).json({ error: 'Missing fields' });

  const { rows: exists } = await query('SELECT 1 FROM users WHERE email=$1', [email]);
  if (exists.length) return res.status(409).json({ error: 'Email already used' });

  const hash = await bcrypt.hash(password, 10);
  const { rows } = await query(
    'INSERT INTO users (name, email, password_hash) VALUES ($1,$2,$3) RETURNING id, name, email',
    [name, email, hash]
  );

  // ilk gün hedef kaydı oluşturmak istersen otomatik ekleyebiliriz (opsiyonel)
  const user = rows[0];
  const token = signToken(user);
  res.json({ token, user });
});

app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body ?? {};
  if (!email || !password) return res.status(400).json({ error: 'Missing fields' });

  const { rows } = await query('SELECT * FROM users WHERE email=$1', [email]);
  if (!rows.length) return res.status(401).json({ error: 'Invalid credentials' });

  const user = rows[0];
  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

  const token = signToken(user);
  res.json({ token, user: { id: user.id, name: user.name, email: user.email } });
});

app.get('/api/auth/me', authMiddleware, async (req, res) => {
  res.json({ user: req.user });
});

// === DASHBOARD (çok basit) ===
app.get('/api/dashboard/today', authMiddleware, async (req, res) => {
    const day = new Date().toISOString().slice(0, 10);
  
    const [water, steps, exercise] = await Promise.all([
      query('SELECT count, goal FROM water_logs WHERE user_id=$1 AND day=$2', [req.user.id, day]),
      query('SELECT steps, goal FROM step_logs WHERE user_id=$1 AND day=$2', [req.user.id, day]),
      query('SELECT minutes, calories, goal FROM exercise_logs WHERE user_id=$1 AND day=$2', [req.user.id, day])
    ]);
  
    const w = water.rows[0] ?? { count: 0, goal: 8 };
    const s = steps.rows[0] ?? { steps: 0, goal: 10000 };
    const e = exercise.rows[0] ?? { minutes: 0, calories: 0, goal: 30 };
  
    const waterBlock = {
      count: w.count,
      goal: w.goal,
      percent: w.goal ? w.count / w.goal : 0
    };
  
    const stepsBlock = {
      count: s.steps,               // 👈 unify as "count"
      goal: s.goal,
      percent: s.goal ? s.steps / s.goal : 0
    };
  
    const exerciseBlock = {
      count: e.minutes,             // 👈 unify as "count" (minutes)
      goal: e.goal,
      percent: e.goal ? e.minutes / e.goal : 0,
      calories: e.calories
    };
  
    const overall = (waterBlock.percent + stepsBlock.percent + exerciseBlock.percent) / 3;
  
    res.json({
      water: waterBlock,
      steps: stepsBlock,
      exercise: exerciseBlock,
      overall
    });
  });

// === WATER ===
app.get('/api/water/today', authMiddleware, async (req, res) => {
  const day = new Date().toISOString().slice(0, 10);
  const { rows } = await query(
    'SELECT count, goal FROM water_logs WHERE user_id=$1 AND day=$2',
    [req.user.id, day]
  );
  const data = rows[0] ?? { count: 0, goal: 8 };
  res.json(data);
});

app.post('/api/water/add', authMiddleware, async (req, res) => {
  const { glasses } = req.body ?? {};
  const inc = Number.isInteger(glasses) ? glasses : 1;
  const day = new Date().toISOString().slice(0, 10);

  // upsert benzeri: önce satır var mı bak, yoksa oluştur
  const exist = await query(
    'SELECT id, count, goal FROM water_logs WHERE user_id=$1 AND day=$2',
    [req.user.id, day]
  );
  if (!exist.rows.length) {
    const { rows } = await query(
      'INSERT INTO water_logs (user_id, day, count, goal) VALUES ($1,$2,$3,$4) RETURNING count, goal',
      [req.user.id, day, Math.max(0, inc), 8]
    );
    return res.json(rows[0]);
  } else {
    const row = exist.rows[0];
    const next = Math.max(0, row.count + inc);
    const { rows } = await query(
      'UPDATE water_logs SET count=$1 WHERE id=$2 RETURNING count, goal',
      [next, row.id]
    );
    return res.json(rows[0]);
  }
});

app.post('/api/water/goal', authMiddleware, async (req, res) => {
  const { goal } = req.body ?? {};
  const g = Number.isInteger(goal) && goal > 0 ? goal : 8;
  const day = new Date().toISOString().slice(0, 10);

  const exist = await query(
    'SELECT id, count, goal FROM water_logs WHERE user_id=$1 AND day=$2',
    [req.user.id, day]
  );
  if (!exist.rows.length) {
    const { rows } = await query(
      'INSERT INTO water_logs (user_id, day, count, goal) VALUES ($1,$2,$3,$4) RETURNING count, goal',
      [req.user.id, day, 0, g]
    );
    return res.json(rows[0]);
  } else {
    const { rows } = await query(
      'UPDATE water_logs SET goal=$1 WHERE id=$2 RETURNING count, goal',
      [g, exist.rows[0].id]
    );
    return res.json(rows[0]);
  }
});


// === STEPS ===
app.get('/api/steps/today', authMiddleware, async (req, res) => {
    const day = new Date().toISOString().slice(0, 10);
    const { rows } = await query(
      'SELECT steps, goal FROM step_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );
    const data = rows[0] ?? { steps: 0, goal: 10000 };
    res.json(data);
  });
  
  app.post('/api/steps/add', authMiddleware, async (req, res) => {
    const { steps } = req.body ?? {};
    const inc = Number.isInteger(steps) ? steps : 500;
    const day = new Date().toISOString().slice(0, 10);
  
    const exist = await query(
      'SELECT id, steps, goal FROM step_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );
  
    if (!exist.rows.length) {
      const { rows } = await query(
        'INSERT INTO step_logs (user_id, day, steps, goal) VALUES ($1,$2,$3,$4) RETURNING steps, goal',
        [req.user.id, day, inc, 10000]
      );
      res.json(rows[0]);
    } else {
      const current = exist.rows[0];
      const next = current.steps + inc;
      const { rows } = await query(
        'UPDATE step_logs SET steps=$1 WHERE id=$2 RETURNING steps, goal',
        [next, current.id]
      );
      res.json(rows[0]);
    }
  });
  
  app.post('/api/steps/goal', authMiddleware, async (req, res) => {
    const { goal } = req.body ?? {};
    const g = Number.isInteger(goal) && goal > 0 ? goal : 10000;
    const day = new Date().toISOString().slice(0, 10);
  
    const exist = await query(
      'SELECT id FROM step_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );
  
    if (!exist.rows.length) {
      const { rows } = await query(
        'INSERT INTO step_logs (user_id, day, steps, goal) VALUES ($1,$2,$3,$4) RETURNING steps, goal',
        [req.user.id, day, 0, g]
      );
      res.json(rows[0]);
    } else {
      const { rows } = await query(
        'UPDATE step_logs SET goal=$1 WHERE id=$2 RETURNING steps, goal',
        [g, exist.rows[0].id]
      );
      res.json(rows[0]);
    }
  });
  
  // === EXERCISE ===
  app.get('/api/exercise/today', authMiddleware, async (req, res) => {
    const day = new Date().toISOString().slice(0, 10);
    const { rows } = await query(
      'SELECT minutes, calories, goal FROM exercise_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );
    const data = rows[0] ?? { minutes: 0, calories: 0, goal: 30 };
    
    // Get list of individual exercises for today
    let exercisesList = [];
    try {
      const { rows: exRows } = await query(
        'SELECT id, type, activity, minutes, calories, created_at FROM exercises WHERE user_id=$1 AND day=$2 ORDER BY created_at DESC',
        [req.user.id, day]
      );
      exercisesList = exRows.map(row => ({
        id: row.id,
        type: row.type,
        activity: row.activity,
        minutes: row.minutes,
        calories: row.calories,
        createdAt: row.created_at
      }));
    } catch (e) {
      // exercises table might not exist yet
      exercisesList = [];
    }
    
    res.json({
      ...data,
      list: exercisesList
    });
  });
  
  app.post('/api/exercise/add', authMiddleware, async (req, res) => {
    const { type, activity, minutes, calories } = req.body ?? {};
    const incMin = Number.isInteger(minutes) ? minutes : 5;
    const incCal = Number.isInteger(calories) ? calories : 20;
    const day = new Date().toISOString().slice(0, 10);
    const exType = type || 'Cardio';
    const exActivity = activity || 'Exercise';
  
    // Create exercises table if it doesn't exist (with error handling for existing table)
    try {
      await query(`
        CREATE TABLE IF NOT EXISTS exercises (
          id SERIAL PRIMARY KEY,
          user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          day DATE NOT NULL,
          type VARCHAR(50) NOT NULL,
          activity VARCHAR(100) NOT NULL,
          minutes INTEGER NOT NULL,
          calories INTEGER NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      await query('CREATE INDEX IF NOT EXISTS idx_exercises_user_day ON exercises(user_id, day)');
    } catch (e) {
      // Table might already exist, ignore
    }
  
    // Insert individual exercise
    await query(
      'INSERT INTO exercises (user_id, day, type, activity, minutes, calories) VALUES ($1, $2, $3, $4, $5, $6)',
      [req.user.id, day, exType, exActivity, incMin, incCal]
    );
  
    // Update or insert aggregated log
    const exist = await query(
      'SELECT id, minutes, calories, goal FROM exercise_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );
  
    if (!exist.rows.length) {
      const { rows } = await query(
        'INSERT INTO exercise_logs (user_id, day, minutes, calories, goal) VALUES ($1,$2,$3,$4,$5) RETURNING minutes, calories, goal',
        [req.user.id, day, incMin, incCal, 30]
      );
      res.json(rows[0]);
    } else {
      const current = exist.rows[0];
      const nextMin = current.minutes + incMin;
      const nextCal = current.calories + incCal;
      const { rows } = await query(
        'UPDATE exercise_logs SET minutes=$1, calories=$2 WHERE id=$3 RETURNING minutes, calories, goal',
        [nextMin, nextCal, current.id]
      );
      res.json(rows[0]);
    }
  });
  
  app.post('/api/exercise/goal', authMiddleware, async (req, res) => {
    const { goal } = req.body ?? {};
    const g = Number.isInteger(goal) && goal > 0 ? goal : 30;
    const day = new Date().toISOString().slice(0, 10);
  
    const exist = await query(
      'SELECT id FROM exercise_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );
  
    if (!exist.rows.length) {
      const { rows } = await query(
        'INSERT INTO exercise_logs (user_id, day, minutes, calories, goal) VALUES ($1,$2,$3,$4,$5) RETURNING minutes, calories, goal',
        [req.user.id, day, 0, 0, g]
      );
      res.json(rows[0]);
    } else {
      const { rows } = await query(
        'UPDATE exercise_logs SET goal=$1 WHERE id=$2 RETURNING minutes, calories, goal',
        [g, exist.rows[0].id]
      );
      res.json(rows[0]);
    }
  });


app.listen(PORT, () => {
  console.log(`API running on http://127.0.0.1:${PORT}`);
});
