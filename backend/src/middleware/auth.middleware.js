import { verifyToken } from '../utils/jwt.js';
import { query } from '../config/database.js';

export const authenticate = async (req, res, next) => {
  try {
    const auth = req.headers.authorization || '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;

    if (!token) {
      return res.status(401).json({ 
        error: 'No token provided',
        message: 'Authentication required'
      });
    }

    const payload = verifyToken(token);
    
    // Kullanıcıyı veritabanından çek
    const { rows } = await query(
      'SELECT id, name, email FROM users WHERE id=$1',
      [payload.id]
    );

    if (rows.length === 0) {
      return res.status(401).json({ 
        error: 'Invalid token',
        message: 'User not found'
      });
    }

    req.user = rows[0];
    next();
  } catch (error) {
    return res.status(401).json({ 
      error: 'Invalid token',
      message: error.message
    });
  }
};