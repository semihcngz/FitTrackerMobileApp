import { query } from '../config/database.js';

const getCurrentDay = () => new Date().toISOString().slice(0, 10);

// Exercises tablosunu oluştur (ilk kullanımda)
const ensureExercisesTable = async () => {
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
  } catch (error) {
    // Tablo zaten varsa hata göz ardı edilir
  }
};

export const getToday = async (req, res, next) => {
  try {
    const day = getCurrentDay();
    
    // Toplam veriyi çek
    const { rows } = await query(
      'SELECT minutes, calories, goal FROM exercise_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );
    const data = rows[0] || { minutes: 0, calories: 0, goal: 30 };

    // Detaylı egzersiz listesini çek
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
      exercisesList = [];
    }

    res.json({
      ...data,
      list: exercisesList
    });
  } catch (error) {
    next(error);
  }
};

export const addExercise = async (req, res, next) => {
  try {
    const { type, activity, minutes, calories } = req.body;
    const incMin = Number.isInteger(minutes) ? minutes : 5;
    const incCal = Number.isInteger(calories) ? calories : 20;
    const day = getCurrentDay();
    const exType = type || 'Cardio';
    const exActivity = activity || 'Exercise';

    // Tablo kontrolü
    await ensureExercisesTable();

    // Detaylı egzersiz kaydı ekle
    await query(
      'INSERT INTO exercises (user_id, day, type, activity, minutes, calories) VALUES ($1, $2, $3, $4, $5, $6)',
      [req.user.id, day, exType, exActivity, incMin, incCal]
    );

    // Toplam değerleri güncelle
    const { rows: existing } = await query(
      'SELECT id, minutes, calories, goal FROM exercise_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );

    let result;

    if (!existing.length) {
      const { rows } = await query(
        'INSERT INTO exercise_logs (user_id, day, minutes, calories, goal) VALUES ($1,$2,$3,$4,$5) RETURNING minutes, calories, goal',
        [req.user.id, day, incMin, incCal, 30]
      );
      result = rows[0];
    } else {
      const current = existing[0];
      const nextMin = current.minutes + incMin;
      const nextCal = current.calories + incCal;
      const { rows } = await query(
        'UPDATE exercise_logs SET minutes=$1, calories=$2 WHERE id=$3 RETURNING minutes, calories, goal',
        [nextMin, nextCal, current.id]
      );
      result = rows[0];
    }

    res.json(result);
  } catch (error) {
    next(error);
  }
};

export const setGoal = async (req, res, next) => {
  try {
    const { goal } = req.body;
    const newGoal = Number.isInteger(goal) && goal > 0 ? goal : 30;
    const day = getCurrentDay();

    const { rows: existing } = await query(
      'SELECT id FROM exercise_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );

    let result;

    if (!existing.length) {
      const { rows } = await query(
        'INSERT INTO exercise_logs (user_id, day, minutes, calories, goal) VALUES ($1,$2,$3,$4,$5) RETURNING minutes, calories, goal',
        [req.user.id, day, 0, 0, newGoal]
      );
      result = rows[0];
    } else {
      const { rows } = await query(
        'UPDATE exercise_logs SET goal=$1 WHERE id=$2 RETURNING minutes, calories, goal',
        [newGoal, existing[0].id]
      );
      result = rows[0];
    }

    res.json(result);
  } catch (error) {
    next(error);
  }
};