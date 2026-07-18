"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const shareController_1 = require("../controllers/shareController");
const rateLimiter_1 = require("../middleware/rateLimiter");
const router = (0, express_1.Router)();
// Route to upload encrypted payload
router.post('/', rateLimiter_1.uploadLimiter, shareController_1.uploadShareData);
// Route to get and burn encrypted payload
router.get('/:dataId', rateLimiter_1.apiLimiter, shareController_1.getShareData);
exports.default = router;
