import express from 'express';
import { analyzeFood, getTodayFood, deleteFood } from '../controllers/food.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

router.post('/analyze', analyzeFood);
router.get('/today', getTodayFood);
router.delete('/:id', deleteFood);

export default router;