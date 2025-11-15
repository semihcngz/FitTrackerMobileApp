import express from 'express';
import { getTodayStats } from '../controllers/dashboard.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

router.get('/today', getTodayStats);

export default router;