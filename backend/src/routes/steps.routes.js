import express from 'express';
import { getToday, addSteps} from '../controllers/steps.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

router.get('/today', getToday);
router.post('/add', addSteps);

export default router;