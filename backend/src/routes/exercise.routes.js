import express from 'express';
import { getToday, addExercise, getWeeklyStats } from '../controllers/exercise.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

router.get('/today', getToday);
router.post('/add', addExercise);
router.get('/stats/weekly', getWeeklyStats);


export default router;