import express from 'express';
import { getToday, addWater, setGoal } from '../controllers/water.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate); // Tüm route'lar korumalı

router.get('/today', getToday);
router.post('/add', addWater);
router.post('/goal', setGoal);

export default router;
