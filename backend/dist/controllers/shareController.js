"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getShareData = exports.uploadShareData = void 0;
const redis_1 = require("../config/redis");
const crypto_1 = __importDefault(require("crypto"));
// Max payload size limit: 50KB (51200 bytes)
const MAX_PAYLOAD_SIZE = 50 * 1024;
const uploadShareData = async (req, res) => {
    try {
        const { ciphertext, iv, tag } = req.body;
        if (!ciphertext || !iv || !tag) {
            res.status(400).json({ error: 'Missing required parameters: ciphertext, iv, and tag are required.' });
            return;
        }
        // Validate payload size
        const payloadString = JSON.stringify({ ciphertext, iv, tag });
        if (Buffer.byteLength(payloadString, 'utf8') > MAX_PAYLOAD_SIZE) {
            res.status(413).json({ error: 'Payload size exceeds the 50KB limit.' });
            return;
        }
        // Generate unique short ID or UUID
        const dataId = crypto_1.default.randomUUID();
        // Store in Redis with 180 seconds (3 minutes) TTL
        const redisKey = `share:${dataId}`;
        await redis_1.redisClient.set(redisKey, payloadString, {
            EX: 180, // Expire in 180 seconds
        });
        res.status(201).json({
            dataId,
            expiresIn: 180,
        });
    }
    catch (error) {
        console.error('Error uploading share data:', error);
        res.status(500).json({ error: 'Internal server error occurred while storing data.' });
    }
};
exports.uploadShareData = uploadShareData;
const getShareData = async (req, res) => {
    try {
        const { dataId } = req.params;
        if (!dataId) {
            res.status(400).json({ error: 'Data ID is required.' });
            return;
        }
        const redisKey = `share:${dataId}`;
        const rawData = await redis_1.redisClient.get(redisKey);
        if (!rawData) {
            res.status(404).json({ error: '데이터가 만료되었거나 존재하지 않습니다.' });
            return;
        }
        // [보안 핵심] Burn-After-Reading: 최초 조회 시 Redis에서 데이터를 즉시 삭제
        await redis_1.redisClient.del(redisKey);
        // Parse and return the payload
        const parsedData = JSON.parse(rawData);
        res.status(200).json(parsedData);
    }
    catch (error) {
        console.error('Error fetching share data:', error);
        res.status(500).json({ error: 'Internal server error occurred while retrieving data.' });
    }
};
exports.getShareData = getShareData;
