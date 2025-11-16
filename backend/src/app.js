import express from 'express';
import cors from 'cors';
import morgan from 'morgan';

// Routes
import authRoutes from './routes/auth.routes.js';
import waterRoutes from './routes/water.routes.js';
import stepsRoutes from './routes/steps.routes.js';
import exerciseRoutes from './routes/exercise.routes.js';
import dashboardRoutes from './routes/dashboard.routes.js';

// Middleware
import { errorHandler } from './middleware/error.middleware.js';

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Health check
app.get('/', (req, res) => {
  res.json({ 
    ok: true, 
    api: 'FitTrack API', 
    version: '2.0',
    timestamp: new Date().toISOString()
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/water', waterRoutes);
app.use('/api/steps', stepsRoutes);
app.use('/api/exercise', exerciseRoutes);
app.use('/api/dashboard', dashboardRoutes);

// Error handling middleware
app.use(errorHandler);

export default app;