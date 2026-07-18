import { Router } from 'express';
import multer from 'multer';
import { processPrescriptionOCR } from '../controllers/ocrController';
import { uploadLimiter } from '../middleware/rateLimiter';

const router = Router();

// Configure memory storage for multer (images are stored only in memory for privacy)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // Limit image size to 5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed.'));
    }
  },
});

// Endpoint for OCR translation of prescription images
router.post('/', upload.single('image'), uploadLimiter, processPrescriptionOCR);

export default router;
