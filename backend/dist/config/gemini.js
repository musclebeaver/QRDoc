"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ai = void 0;
const genai_1 = require("@google/genai");
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
    console.warn('Warning: GEMINI_API_KEY is not set in environment variables. Gemini OCR features will fail.');
}
// Initialize the new Google Gen AI SDK
exports.ai = new genai_1.GoogleGenAI({ apiKey: apiKey || '' });
