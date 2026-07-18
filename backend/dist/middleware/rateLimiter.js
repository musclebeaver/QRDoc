"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadLimiter = exports.apiLimiter = void 0;
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
exports.apiLimiter = (0, express_rate_limit_1.default)({
    windowMs: 60 * 1000, // 1 minute
    max: 10, // Limit each IP to 10 requests per minute
    message: {
        error: 'Too many requests from this IP, please try again after a minute.',
    },
    standardHeaders: true,
    legacyHeaders: false,
});
exports.uploadLimiter = (0, express_rate_limit_1.default)({
    windowMs: 60 * 1000, // 1 minute
    max: 3, // Limit each IP to 3 uploads per minute (tighter for OCR/Share)
    message: {
        error: 'Upload limit exceeded. Please wait a minute before trying again.',
    },
    standardHeaders: true,
    legacyHeaders: false,
});
