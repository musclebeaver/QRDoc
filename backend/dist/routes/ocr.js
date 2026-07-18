"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const multer_1 = __importDefault(require("multer"));
const ocrController_1 = require("../controllers/ocrController");
const rateLimiter_1 = require("../middleware/rateLimiter");
const router = (0, express_1.Router)();
// Configure memory storage for multer (images are stored only in memory for privacy)
const upload = (0, multer_1.default)({
    storage: multer_1.default.memoryStorage(),
    limits: {
        fileSize: 5 * 1024 * 1024, // Limit image size to 5MB
    },
    fileFilter: (req, file, cb) => {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        }
        else {
            cb(new Error('Only image files are allowed.'));
        }
    },
});
// Endpoint for OCR translation of prescription images
router.post('/', upload.single('image'), rateLimiter_1.uploadLimiter, ocrController_1.processPrescriptionOCR);
exports.default = router;
