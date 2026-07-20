import { Request, Response } from 'express';
import { redisClient } from '../config/redis';
import crypto from 'crypto';

// Max payload size limit: 50KB (51200 bytes)
const MAX_PAYLOAD_SIZE = 50 * 1024;

export const uploadShareData = async (req: Request, res: Response): Promise<void> => {
  try {
    const { ciphertext, iv, tag, expireSeconds } = req.body;

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

    // Determine custom expiration time (clamped between 60s and 1800s, default 180s)
    let expireSecondsInt = 180;
    if (expireSeconds !== undefined) {
      const parsed = parseInt(expireSeconds, 10);
      if (!isNaN(parsed)) {
        expireSecondsInt = Math.max(60, Math.min(parsed, 1800));
      }
    }

    // Generate unique short ID or UUID
    const dataId = crypto.randomUUID();

    // Store in Redis with custom TTL
    const redisKey = `share:${dataId}`;
    await redisClient.set(redisKey, payloadString, {
      EX: expireSecondsInt,
    });

    res.status(201).json({
      dataId,
      expiresIn: expireSecondsInt,
    });
  } catch (error) {
    console.error('Error uploading share data:', error);
    res.status(500).json({ error: 'Internal server error occurred while storing data.' });
  }
};

export const getShareData = async (req: Request, res: Response): Promise<void> => {
  try {
    const { dataId } = req.params;

    if (!dataId) {
      res.status(400).json({ error: 'Data ID is required.' });
      return;
    }

    const redisKey = `share:${dataId}`;
    
    // Fetch remaining TTL before deletion
    const ttl = await redisClient.ttl(redisKey);
    const rawData = await redisClient.get(redisKey);

    if (!rawData) {
      res.status(404).json({ error: '데이터가 만료되었거나 존재하지 않습니다.' });
      return;
    }

    // [보안 핵심] Burn-After-Reading: 최초 조회 시 Redis에서 데이터를 즉시 삭제
    await redisClient.del(redisKey);

    // Parse and return the payload with remaining TTL
    const parsedData = JSON.parse(rawData);
    res.status(200).json({
      ...parsedData,
      expiresIn: Math.max(0, ttl),
    });
  } catch (error) {
    console.error('Error fetching share data:', error);
    res.status(500).json({ error: 'Internal server error occurred while retrieving data.' });
  }
};
