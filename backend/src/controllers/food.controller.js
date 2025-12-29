import { query } from '../config/database.js';
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// Fotoğraftan kalori analizi
export const analyzeFood = async (req, res, next) => {
  try {
    const { image_base64, meal_type } = req.body;

    if (!image_base64) {
      return res.status(400).json({ error: 'Image is required' });
    }

    console.log('🔍 Analyzing food image...');

    // GPT-4 Vision'a gönder
    const response = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: `Analyze this food image and provide nutrition information. 

IMPORTANT: Respond ONLY with valid JSON in this EXACT format (no markdown, no code blocks):
{
  "food_name": "yemek adı (Türkçe)",
  "description": "kısa açıklama (Türkçe)",
  "calories": sayı,
  "protein": sayı,
  "carbs": sayı,
  "fat": sayı
}

Example:
{"food_name":"Izgara Tavuk","description":"Yaklaşık 200g ızgara tavuk göğsü","calories":330,"protein":62,"carbs":0,"fat":7}

Be realistic with portions. Only return JSON, nothing else.`
            },
            {
              type: "image_url",
              image_url: {
                url: `data:image/jpeg;base64,${image_base64}`
              }
            }
          ]
        }
      ],
      max_tokens: 300,
      temperature: 0.3  // Daha tutarlı sonuçlar için
    });

    const result = response.choices[0].message.content;
    console.log('📥 GPT Response:', result);

    let foodData;

    try {
      // JSON parse et
      // Eğer markdown code block içindeyse temizle
      let cleanResult = result.trim();
      
      // ```json ... ``` varsa temizle
      if (cleanResult.startsWith('```')) {
        cleanResult = cleanResult
          .replace(/```json\n?/g, '')
          .replace(/```\n?/g, '')
          .trim();
      }

      console.log('🧹 Cleaned result:', cleanResult);
      foodData = JSON.parse(cleanResult);

      // Validasyon
      if (!foodData.food_name || !foodData.calories) {
        throw new Error('Missing required fields');
      }

    } catch (parseError) {
      console.error('❌ JSON Parse Error:', parseError);
      console.error('Raw response:', result);
      
      // Manuel parsing denemesi
      try {
        const caloriesMatch = result.match(/calories['":\s]+(\d+)/i);
        const proteinMatch = result.match(/protein['":\s]+([\d.]+)/i);
        const carbsMatch = result.match(/carbs['":\s]+([\d.]+)/i);
        const fatMatch = result.match(/fat['":\s]+([\d.]+)/i);
        const nameMatch = result.match(/food_name['":\s]+"([^"]+)"/i);

        if (caloriesMatch) {
          foodData = {
            food_name: nameMatch ? nameMatch[1] : 'Unknown Food',
            description: 'Otomatik tespit edildi',
            calories: parseInt(caloriesMatch[1]),
            protein: proteinMatch ? parseFloat(proteinMatch[1]) : 20,
            carbs: carbsMatch ? parseFloat(carbsMatch[1]) : 30,
            fat: fatMatch ? parseFloat(fatMatch[1]) : 10
          };
        } else {
          throw new Error('Could not extract nutrition info');
        }
      } catch (manualError) {
        return res.status(500).json({ 
          error: 'Failed to parse AI response',
          details: result.substring(0, 200) // İlk 200 karakter
        });
      }
    }

    console.log('✅ Parsed food data:', foodData);

    // Veritabanına kaydet
    const { rows } = await query(
      `INSERT INTO food_logs (user_id, day, food_name, description, calories, protein, carbs, fat, meal_type) 
       VALUES ($1, CURRENT_DATE, $2, $3, $4, $5, $6, $7, $8) 
       RETURNING *`,
      [
        req.user.id,
        foodData.food_name,
        foodData.description || '',
        foodData.calories || 0,
        foodData.protein || 0,
        foodData.carbs || 0,
        foodData.fat || 0,
        meal_type || 'snack'
      ]
    );

    res.json({
      analysis: foodData,
      log: rows[0]
    });
  } catch (error) {
    console.error('❌ OpenAI Error:', error);
    next(error);
  }
};

// Bugünkü yemekleri getir
export const getTodayFood = async (req, res, next) => {
  try {
    const day = new Date().toISOString().slice(0, 10);

    const { rows } = await query(
      `SELECT * FROM food_logs 
       WHERE user_id=$1 AND day=$2 
       ORDER BY created_at DESC`,
      [req.user.id, day]
    );

    // Toplam hesapla
    const total = {
      calories: rows.reduce((sum, r) => sum + (r.calories || 0), 0),
      protein: rows.reduce((sum, r) => sum + parseFloat(r.protein || 0), 0).toFixed(1),
      carbs: rows.reduce((sum, r) => sum + parseFloat(r.carbs || 0), 0).toFixed(1),
      fat: rows.reduce((sum, r) => sum + parseFloat(r.fat || 0), 0).toFixed(1),
    };

    res.json({
      logs: rows,
      total
    });
  } catch (error) {
    next(error);
  }
};

// Yemek sil
export const deleteFood = async (req, res, next) => {
  try {
    const { id } = req.params;

    const { rows } = await query(
      'DELETE FROM food_logs WHERE id=$1 AND user_id=$2 RETURNING *',
      [id, req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Food log not found' });
    }

    res.json({ success: true });
  } catch (error) {
    next(error);
  }
};