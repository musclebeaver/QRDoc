"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.connectRedis = exports.redisClient = void 0;
const redis_1 = require("redis");
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const redisUrl = process.env.REDIS_URL || 'redis://127.0.0.1:6379';
exports.redisClient = (0, redis_1.createClient)({
    url: redisUrl,
});
exports.redisClient.on('error', (err) => {
    console.error('Redis Client Error:', err);
});
const connectRedis = async () => {
    if (!exports.redisClient.isOpen) {
        await exports.redisClient.connect();
        console.log('Successfully connected to Redis.');
    }
};
exports.connectRedis = connectRedis;
