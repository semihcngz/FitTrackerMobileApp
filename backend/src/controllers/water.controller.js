import { query } from '../config/database.js';

const getCurrentDay = () => new Date().toISOString().slice(0, 10);

export const getToday = async (req, res, next) => {
  try {
    const day = getCurrentDay();
    const { rows } = await query(
      'SELECT count, goal FROM water_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );

    const data = rows[0] || { count: 0, goal: 8 };
    res.json(data);
  } catch (error) {
    next(error);
  }
};

export const addWater = async (req, res, next) => {
  try {
    const { glasses } = req.body;
    const increment = Number.isInteger(glasses) ? glasses : 1;
    const day = getCurrentDay();

    // Mevcut kaydı kontrol et
    const { rows: existing } = await query(
      'SELECT id, count, goal FROM water_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );

    let result;

    if (!existing.length) {
      // Yeni kayıt oluştur
      const { rows } = await query(
        'INSERT INTO water_logs (user_id, day, count, goal) VALUES ($1,$2,$3,$4) RETURNING count, goal',
        [req.user.id, day, Math.max(0, increment), 8]
      );
      result = rows[0];
    } else {
      // Mevcut kaydı güncelle
      const newCount = Math.max(0, existing[0].count + increment);
      const { rows } = await query(
        'UPDATE water_logs SET count=$1 WHERE id=$2 RETURNING count, goal',
        [newCount, existing[0].id]
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
    const newGoal = Number.isInteger(goal) && goal > 0 ? goal : 8;
    const day = getCurrentDay();

    // Mevcut kaydı kontrol et
    const { rows: existing } = await query(
      'SELECT id FROM water_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );

    let result;

    if (!existing.length) {
      // Yeni kayıt oluştur
      const { rows } = await query(
        'INSERT INTO water_logs (user_id, day, count, goal) VALUES ($1,$2,$3,$4) RETURNING count, goal',
        [req.user.id, day, 0, newGoal]
      );
      result = rows[0];
    } else {
      // Hedefi güncelle
      const { rows } = await query(
        'UPDATE water_logs SET goal=$1 WHERE id=$2 RETURNING count, goal',
        [newGoal, existing[0].id]
      );
      result = rows[0];
    }

    res.json(result);
  } catch (error) {
    next(error);
  }
};