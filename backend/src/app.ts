import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { connectRedis } from './config/redis';
import shareRouter from './routes/share';
import ocrRouter from './routes/ocr';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;
const corsOrigin = process.env.CORS_ORIGIN || '*';

// Initialize middleware
app.use(cors({
  origin: corsOrigin,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static web viewer files
app.use(express.static(path.join(__dirname, '../../web-viewer')));

// Health check endpoint
app.get('/health', async (req: Request, res: Response) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Register routers
app.use('/api/share', shareRouter);
app.use('/api/ocr', ocrRouter);

// Global Error Handler
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('Unhandled Server Error:', err);
  res.status(500).json({
    error: 'An internal server error occurred.',
    message: err.message || 'Unknown error',
  });
});

// Connect to services and start the server
const startServer = async () => {
  try {
    // 1. Connect to Redis
    await connectRedis();

    // 2. Start Listening
    app.listen(port, () => {
      console.log(`[Server] QRDoc 중계 서버가 http://localhost:${port} 에서 실행 중입니다.`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
