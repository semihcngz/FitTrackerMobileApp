require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { auth } = require('./middleware/auth');
const authRoutes = require('./routes/auth');
const dashboardRoutes = require('./routes/dashboard');
const waterRoutes = require('./routes/water');
const stepsRoutes = require('./routes/steps');
const exerciseRoutes = require('./routes/exercise');
const { prisma } = require('./prisma');

const app = express();
app.use(express.json());
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(helmet());
app.use(morgan('dev'));

// Public
app.use('/auth', authRoutes);

// Secure
app.get('/auth/me', auth, (req, res) => {
  const { id, name, email } = req.user;
  res.json({ id, name, email });
});
app.use('/dashboard', auth, dashboardRoutes);
app.use('/water', auth, waterRoutes);
app.use('/steps', auth, stepsRoutes);
app.use('/exercise', auth, exerciseRoutes);

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`API on http://localhost:${port}`));

// graceful shutdown
process.on('SIGINT', async () => { await prisma.$disconnect(); process.exit(0); });
