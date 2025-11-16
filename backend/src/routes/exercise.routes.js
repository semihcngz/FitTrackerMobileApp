import express from 'express';
import { getToday, addExercise} from '../controllers/exercise.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

router.get('/today', getToday);
router.post('/add', addExercise);


export default router;