"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const redis_1 = require("./config/redis");
const share_1 = __importDefault(require("./routes/share"));
const ocr_1 = __importDefault(require("./routes/ocr"));
dotenv_1.default.config();
const app = (0, express_1.default)();
const port = process.env.PORT || 3000;
const corsOrigin = process.env.CORS_ORIGIN || '*';
// Initialize middleware
app.use((0, cors_1.default)({
    origin: corsOrigin,
}));
app.use(express_1.default.json());
app.use(express_1.default.urlencoded({ extended: true }));
// Health check endpoint
app.get('/health', async (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});
// Register routers
app.use('/api/share', share_1.default);
app.use('/api/ocr', ocr_1.default);
// Global Error Handler
app.use((err, req, res, next) => {
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
        await (0, redis_1.connectRedis)();
        // 2. Start Listening
        app.listen(port, () => {
            console.log(`[Server] QRDoc 중계 서버가 http://localhost:${port} 에서 실행 중입니다.`);
        });
    }
    catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
};
startServer();
