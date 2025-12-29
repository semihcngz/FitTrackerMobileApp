import { query } from '../config/database.js';

const getCurrentDay = () => new Date().toISOString().slice(0, 10);



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

export const getWeeklyStats = async (req, res, next) => {
  try {
    const { week_offset } = req.query; // 0=bu hafta, 1=geçen hafta, 2=2 hafta önce
    const offset = parseInt(week_offset) || 0;

    // Haftanın başlangıç ve bitiş tarihlerini hesapla
    const today = new Date();
    const dayOfWeek = today.getDay(); // 0=Pazar, 1=Pazartesi, ...
    const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek; // Pazartesi'ye kadar geri git
    
    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() + mondayOffset - (offset * 7));
    startOfWeek.setHours(0, 0, 0, 0);
    
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6);
    endOfWeek.setHours(23, 59, 59, 999);

    const startDate = startOfWeek.toISOString().slice(0, 10);
    const endDate = endOfWeek.toISOString().slice(0, 10);

    // 7 günün verilerini çek
    const { rows } = await query(
      `SELECT day::date as day, 
              COALESCE(SUM(minutes), 0) as total_minutes, 
              COALESCE(SUM(calories), 0) as total_calories,
              COUNT(*) as exercise_count
       FROM exercises 
       WHERE user_id=$1 AND day::date >= $2::date AND day::date <= $3::date
       GROUP BY day::date
       ORDER BY day::date`,
      [req.user.id, startDate, endDate]
    );

    // 7 günlük array oluştur (boş günler için 0)
    const weekData = [];
    for (let i = 0; i < 7; i++) {
      const currentDate = new Date(startOfWeek);
      currentDate.setDate(startOfWeek.getDate() + i);
      const dateStr = currentDate.toISOString().slice(0, 10);
      
      // Convert day from Date/timestamp to string for comparison
      const dayData = rows.find(r => {
        let rowDay;
        if (r.day instanceof Date) {
          rowDay = r.day.toISOString().slice(0, 10);
        } else if (typeof r.day === 'string') {
          rowDay = r.day.slice(0, 10);
        } else {
          // Handle other types (like moment objects or timestamps)
          rowDay = new Date(r.day).toISOString().slice(0, 10);
        }
        return rowDay === dateStr;
      });
      
      weekData.push({
        date: dateStr,
        dayName: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][currentDate.getDay()],
        totalMinutes: dayData ? parseInt(dayData.total_minutes) : 0,
        totalCalories: dayData ? parseInt(dayData.total_calories) : 0,
        exerciseCount: dayData ? parseInt(dayData.exercise_count) : 0
      });
    }

    // Hafta özeti
    const weekSummary = {
      startDate,
      endDate,
      totalMinutes: weekData.reduce((sum, day) => sum + day.totalMinutes, 0),
      totalCalories: weekData.reduce((sum, day) => sum + day.totalCalories, 0),
      totalExercises: weekData.reduce((sum, day) => sum + day.exerciseCount, 0),
      avgCaloriesPerDay: Math.round(weekData.reduce((sum, day) => sum + day.totalCalories, 0) / 7),
      activeDays: weekData.filter(day => day.exerciseCount > 0).length
    };

    res.json({
      weekOffset: offset,
      summary: weekSummary,
      days: weekData
    });
  } catch (error) {
    next(error);
  }
};