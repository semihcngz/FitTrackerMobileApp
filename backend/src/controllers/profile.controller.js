import { query } from '../config/database.js';

// Profil getir
export const getProfile = async (req, res, next) => {
  try {
    const { rows } = await query(
      'SELECT * FROM profiles WHERE user_id=$1',
      [req.user.id]
    );

    if (!rows.length) {
      return res.json({ profile: null });
    }

    const profile = rows[0];
    
    // BMI hesapla (eğer boy ve kilo varsa)
    let bmi = null;
    if (profile.height && profile.weight) {
      const heightInMeters = profile.height / 100;
      bmi = (profile.weight / (heightInMeters * heightInMeters)).toFixed(1);
    }

    res.json({ 
      profile: {
        ...profile,
        bmi
      }
    });
  } catch (error) {
    next(error);
  }
};

// Profil oluştur veya güncelle
export const upsertProfile = async (req, res, next) => {
  try {
    const { age, gender, height, weight, target_weight, activity_level } = req.body;

    // Mevcut profil var mı kontrol et
    const { rows: existing } = await query(
      'SELECT id FROM profiles WHERE user_id=$1',
      [req.user.id]
    );

    let result;

    if (!existing.length) {
      // Yeni profil oluştur
      const { rows } = await query(
        `INSERT INTO profiles (user_id, age, gender, height, weight, target_weight, activity_level) 
         VALUES ($1, $2, $3, $4, $5, $6, $7) 
         RETURNING *`,
        [req.user.id, age, gender, height, weight, target_weight, activity_level]
      );
      result = rows[0];
    } else {
      // Mevcut profili güncelle
      const { rows } = await query(
        `UPDATE profiles 
         SET age=$1, gender=$2, height=$3, weight=$4, target_weight=$5, activity_level=$6, updated_at=CURRENT_TIMESTAMP
         WHERE user_id=$7 
         RETURNING *`,
        [age, gender, height, weight, target_weight, activity_level, req.user.id]
      );
      result = rows[0];
    }

    // BMI hesapla
    let bmi = null;
    if (result.height && result.weight) {
      const heightInMeters = result.height / 100;
      bmi = (result.weight / (heightInMeters * heightInMeters)).toFixed(1);
    }

    res.json({ 
      profile: {
        ...result,
        bmi
      }
    });
  } catch (error) {
    next(error);
  }
};

// Kilo güncelle (hızlı güncelleme için)
export const updateWeight = async (req, res, next) => {
  try {
    const { weight } = req.body;

    if (!weight || weight <= 0) {
      return res.status(400).json({ error: 'Invalid weight' });
    }

    const { rows } = await query(
      'UPDATE profiles SET weight=$1, updated_at=CURRENT_TIMESTAMP WHERE user_id=$2 RETURNING *',
      [weight, req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    const profile = rows[0];
    
    // BMI hesapla
    let bmi = null;
    if (profile.height && profile.weight) {
      const heightInMeters = profile.height / 100;
      bmi = (profile.weight / (heightInMeters * heightInMeters)).toFixed(1);
    }

    res.json({ 
      profile: {
        ...profile,
        bmi
      }
    });
  } catch (error) {
    next(error);
  }
};