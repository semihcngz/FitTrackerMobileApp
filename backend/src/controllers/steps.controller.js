import { query } from '../config/database.js';

const getCurrentDay = () => new Date().toISOString().slice(0, 10);

export const getToday = async (req, res, next) => {
  try {
    const day = getCurrentDay();
    const { rows } = await query(
      'SELECT steps, goal FROM step_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );

    const data = rows[0] || { steps: 0, goal: 10000 };
    res.json(data);
  } catch (error) {
    next(error);
  }
};

export const addSteps = async (req, res, next) => {
  try {
    const { steps } = req.body;
    const increment = Number.isInteger(steps) ? steps : 500;
    const day = getCurrentDay();

    const { rows: existing } = await query(
      'SELECT id, steps, goal FROM step_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );

    let result;

    if (!existing.length) {
      const { rows } = await query(
        'INSERT INTO step_logs (user_id, day, steps, goal) VALUES ($1,$2,$3,$4) RETURNING steps, goal',
        [req.user.id, day, increment, 10000]
      );
      result = rows[0];
    } else {
      const newSteps = existing[0].steps + increment;
      const { rows } = await query(
        'UPDATE step_logs SET steps=$1 WHERE id=$2 RETURNING steps, goal',
        [newSteps, existing[0].id]
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
    const newGoal = Number.isInteger(goal) && goal > 0 ? goal : 10000;
    const day = getCurrentDay();

    const { rows: existing } = await query(
      'SELECT id FROM step_logs WHERE user_id=$1 AND day=$2',
      [req.user.id, day]
    );

    let result;

    if (!existing.length) {
      const { rows } = await query(
        'INSERT INTO step_logs (user_id, day, steps, goal) VALUES ($1,$2,$3,$4) RETURNING steps, goal',
        [req.user.id, day, 0, newGoal]
      );
      result = rows[0];
    } else {
      const { rows } = await query(
        'UPDATE step_logs SET goal=$1 WHERE id=$2 RETURNING steps, goal',
        [newGoal, existing[0].id]
      );
      result = rows[0];
    }

    res.json(result);
  } catch (error) {
    next(error);
  }
};