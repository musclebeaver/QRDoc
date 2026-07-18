import { Router } from 'express';
import { uploadShareData, getShareData } from '../controllers/shareController';
import { apiLimiter, uploadLimiter } from '../middleware/rateLimiter';

const router = Router();

// Route to upload encrypted payload
router.post('/', uploadLimiter, uploadShareData);

// Route to get and burn encrypted payload
router.get('/:dataId', apiLimiter, getShareData);

export default router;
