import { GoogleGenAI } from '@google/genai';
import dotenv from 'dotenv';

dotenv.config();

const apiKey = process.env.GEMINI_API_KEY;

if (!apiKey) {
  console.warn('Warning: GEMINI_API_KEY is not set in environment variables. Gemini OCR features will fail.');
}

// Initialize the new Google Gen AI SDK
export const ai = new GoogleGenAI({ apiKey: apiKey || '' });
