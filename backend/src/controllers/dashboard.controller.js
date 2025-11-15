import { query } from '../config/database.js';

const getCurrentDay = () => new Date().toISOString().slice(0, 10);

export const getTodayStats = async (req, res, next) => {
  try {
    const day = getCurrentDay();

    // Tüm verileri paralel olarak çek
    const [water, steps, exercise] = await Promise.all([
      query('SELECT count, goal FROM water_logs WHERE user_id=$1 AND day=$2', [req.user.id, day]),
      query('SELECT steps, goal FROM step_logs WHERE user_id=$1 AND day=$2', [req.user.id, day]),
      query('SELECT minutes, calories, goal FROM exercise_logs WHERE user_id=$1 AND day=$2', [req.user.id, day])
    ]);

    // Varsayılan değerler
    const w = water.rows[0] || { count: 0, goal: 8 };
    const s = steps.rows[0] || { steps: 0, goal: 10000 };
    const e = exercise.rows[0] || { minutes: 0, calories: 0, goal: 30 };

    // Blokları oluştur
    const waterBlock = {
      count: w.count,
      goal: w.goal,
      percent: w.goal ? w.count / w.goal : 0
    };

    const stepsBlock = {
      count: s.steps,
      goal: s.goal,
      percent: s.goal ? s.steps / s.goal : 0
    };

    const exerciseBlock = {
      count: e.minutes,
      goal: e.goal,
      percent: e.goal ? e.minutes / e.goal : 0,
      calories: e.calories
    };

    // Genel ilerleme
    const overall = (waterBlock.percent + stepsBlock.percent + exerciseBlock.percent) / 3;

    res.json({
      water: waterBlock,
      steps: stepsBlock,
      exercise: exerciseBlock,
      overall,
      date: day
    });
  } catch (error) {
    next(error);
  }
};