import bcrypt from 'bcryptjs';
import { query } from '../config/database.js';
import { signToken } from '../utils/jwt.js';
import { validateEmail, validatePassword, validateRequired } from '../utils/validation.js';

export const register = async (req, res, next) => {
  try {
    const { name, email, password } = req.body;

    if (!validateEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }

    if (!validatePassword(password)) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    // Email kullanılmış mı kontrol et
    const { rows: exists } = await query(
      'SELECT 1 FROM users WHERE email=$1',
      [email]
    );

    if (exists.length) {
      return res.status(409).json({ error: 'Email already in use' });
    }

    // Şifreyi hash'le
    const hash = await bcrypt.hash(password, 10);

    // Kullanıcı oluştur
    const { rows } = await query(
      'INSERT INTO users (name, email, password_hash) VALUES ($1,$2,$3) RETURNING id, name, email',
      [name, email, hash]
    );

    const user = rows[0];
    const token = signToken(user);

    res.status(201).json({ 
      token, 
      user,
      message: 'Registration successful'
    });
  } catch (error) {
    next(error);
  }
};

export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Validasyon
    validateRequired(['email', 'password'], req.body);

    // Kullanıcıyı bul
    const { rows } = await query(
      'SELECT * FROM users WHERE email=$1',
      [email]
    );

    if (!rows.length) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = rows[0];

    // Şifreyi kontrol et
    const isValid = await bcrypt.compare(password, user.password_hash);

    if (!isValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = signToken(user);

    res.json({ 
      token, 
      user: { 
        id: user.id, 
        name: user.name, 
        email: user.email 
      },
      message: 'Login successful'
    });
  } catch (error) {
    next(error);
  }
};

export const getMe = async (req, res, next) => {
  try {
    res.json({ 
      user: req.user,
      message: 'User retrieved successfully'
    });
  } catch (error) {
    next(error);
  }
};