import express from 'express';
import { getProfile, upsertProfile, updateWeight } from '../controllers/profile.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

router.get('/', getProfile);
router.post('/', upsertProfile);
router.patch('/weight', updateWeight);

export default router;