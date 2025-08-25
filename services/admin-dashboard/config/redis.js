const redis = require('redis');
const logger = require('../utils/logger');

class RedisClient {
  constructor() {
    this.client = null;
    this.isConnected = false;
  }

  async connect() {
    try {
      this.client = redis.createClient({
        socket: {
          host: process.env.REDIS_HOST || 'redis',
          port: process.env.REDIS_PORT || 6379,
          connectTimeout: 10000,
          lazyConnect: true,
        },
        password: process.env.REDIS_PASSWORD || undefined,
        database: parseInt(process.env.REDIS_DB) || 0,
        retry_strategy: (options) => {
          if (options.error && options.error.code === 'ECONNREFUSED') {
            logger.error('Redis server refused connection');
            return new Error('Redis server refused connection');
          }
          if (options.total_retry_time > 1000 * 60 * 60) {
            logger.error('Redis retry time exhausted');
            return new Error('Retry time exhausted');
          }
          if (options.attempt > 10) {
            logger.error('Redis max retry attempts reached');
            return undefined;
          }
          return Math.min(options.attempt * 100, 3000);
        }
      });

      this.client.on('error', (err) => {
        logger.error('Redis Client Error', err);
        this.isConnected = false;
      });

      this.client.on('connect', () => {
        logger.info('Connected to Redis');
        this.isConnected = true;
      });

      this.client.on('ready', () => {
        logger.info('Redis client ready');
        this.isConnected = true;
      });

      this.client.on('end', () => {
        logger.info('Redis connection ended');
        this.isConnected = false;
      });

      await this.client.connect();
      return this.client;
    } catch (error) {
      logger.error('Failed to connect to Redis', error);
      throw error;
    }
  }

  async get(key) {
    try {
      if (!this.isConnected) {
        throw new Error('Redis not connected');
      }
      const value = await this.client.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      logger.error('Redis GET error', { key, error: error.message });
      return null;
    }
  }

  async set(key, value, ttl = 300) {
    try {
      if (!this.isConnected) {
        throw new Error('Redis not connected');
      }
      const serializedValue = JSON.stringify(value);
      await this.client.setEx(key, ttl, serializedValue);
      logger.debug('Redis SET', { key, ttl });
    } catch (error) {
      logger.error('Redis SET error', { key, error: error.message });
    }
  }

  async del(key) {
    try {
      if (!this.isConnected) {
        throw new Error('Redis not connected');
      }
      await this.client.del(key);
      logger.debug('Redis DEL', { key });
    } catch (error) {
      logger.error('Redis DEL error', { key, error: error.message });
    }
  }

  async exists(key) {
    try {
      if (!this.isConnected) {
        throw new Error('Redis not connected');
      }
      return await this.client.exists(key);
    } catch (error) {
      logger.error('Redis EXISTS error', { key, error: error.message });
      return false;
    }
  }

  async healthCheck() {
    try {
      if (!this.isConnected) {
        return {
          status: 'unhealthy',
          error: 'Not connected to Redis',
          timestamp: new Date().toISOString()
        };
      }

      const start = Date.now();
      await this.client.ping();
      const responseTime = Date.now() - start;

      return {
        status: 'healthy',
        responseTime,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Redis health check failed', error);
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  async close() {
    try {
      if (this.client) {
        await this.client.quit();
        logger.info('Redis connection closed');
      }
    } catch (error) {
      logger.error('Error closing Redis connection', error);
    }
  }
}

module.exports = new RedisClient();
