const webpush = require('web-push');
const logger = require('./logger');
const db = require('../config/database');
const redis = require('../config/redis');

class PushNotificationService {
  constructor() {
    this.vapidKeys = {
      publicKey: process.env.PUSH_VAPID_PUBLIC_KEY,
      privateKey: process.env.PUSH_VAPID_PRIVATE_KEY
    };

    this.subject = process.env.PUSH_SUBJECT || 'mailto:admin@defimon.highfunk.uk';

    if (!this.vapidKeys.publicKey || !this.vapidKeys.privateKey) {
      logger.warn('VAPID keys not configured. Push notifications will be disabled.');
      this.enabled = false;
    } else {
      webpush.setVapidDetails(
        this.subject,
        this.vapidKeys.publicKey,
        this.vapidKeys.privateKey
      );
      this.enabled = true;
      logger.info('Push notification service initialized');
    }
  }

  async subscribeUser(userId, subscription) {
    try {
      if (!this.enabled) {
        throw new Error('Push notifications are not enabled');
      }

      const query = `
        INSERT INTO push_subscriptions (user_id, endpoint, p256dh, auth)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (user_id) 
        DO UPDATE SET 
          endpoint = EXCLUDED.endpoint,
          p256dh = EXCLUDED.p256dh,
          auth = EXCLUDED.auth,
          updated_at = NOW()
      `;

      await db.query(query, [
        userId,
        subscription.endpoint,
        subscription.keys.p256dh,
        subscription.keys.auth
      ]);

      logger.info('User subscribed to push notifications', { userId });
      return { success: true };
    } catch (error) {
      logger.error('Failed to subscribe user to push notifications', { userId, error: error.message });
      throw error;
    }
  }

  async unsubscribeUser(userId) {
    try {
      const query = 'DELETE FROM push_subscriptions WHERE user_id = $1';
      await db.query(query, [userId]);
      
      logger.info('User unsubscribed from push notifications', { userId });
      return { success: true };
    } catch (error) {
      logger.error('Failed to unsubscribe user from push notifications', { userId, error: error.message });
      throw error;
    }
  }

  async sendNotification(userId, notification) {
    try {
      if (!this.enabled) {
        logger.warn('Push notifications are disabled');
        return { success: false, reason: 'disabled' };
      }

      const subscription = await this.getUserSubscription(userId);
      if (!subscription) {
        logger.warn('No subscription found for user', { userId });
        return { success: false, reason: 'no_subscription' };
      }

      const payload = JSON.stringify({
        title: notification.title,
        body: notification.body,
        icon: notification.icon || '/icon-192x192.png',
        badge: notification.badge || '/badge-72x72.png',
        data: notification.data || {},
        actions: notification.actions || [],
        tag: notification.tag || 'default',
        requireInteraction: notification.requireInteraction || false,
        silent: notification.silent || false
      });

      const pushSubscription = {
        endpoint: subscription.endpoint,
        keys: {
          p256dh: subscription.p256dh,
          auth: subscription.auth
        }
      };

      const result = await webpush.sendNotification(pushSubscription, payload);
      
      logger.info('Push notification sent successfully', { 
        userId, 
        title: notification.title,
        statusCode: result.statusCode 
      });

      // Cache the notification for history
      await this.cacheNotification(userId, notification);

      return { success: true, statusCode: result.statusCode };
    } catch (error) {
      logger.error('Failed to send push notification', { 
        userId, 
        error: error.message,
        statusCode: error.statusCode 
      });

      // Handle subscription errors
      if (error.statusCode === 410 || error.statusCode === 404) {
        await this.unsubscribeUser(userId);
        logger.info('Removed invalid subscription', { userId });
      }

      return { success: false, error: error.message };
    }
  }

  async sendAlert(level, message, context = {}) {
    try {
      const notification = {
        title: `DEFIMON Alert: ${level.toUpperCase()}`,
        body: message,
        icon: '/alert-icon.png',
        badge: '/alert-badge.png',
        data: {
          type: 'alert',
          level,
          context,
          timestamp: new Date().toISOString()
        },
        tag: `alert-${level}`,
        requireInteraction: level === 'critical',
        silent: level === 'info'
      };

      // Get all admin users
      const users = await this.getAllAdminUsers();
      
      const results = await Promise.allSettled(
        users.map(user => this.sendNotification(user.id, notification))
      );

      const successful = results.filter(r => r.status === 'fulfilled' && r.value.success).length;
      const failed = results.length - successful;

      logger.info('Alert notification sent', { 
        level, 
        message, 
        successful, 
        failed,
        total: results.length 
      });

      return { successful, failed, total: results.length };
    } catch (error) {
      logger.error('Failed to send alert notification', { level, message, error: error.message });
      throw error;
    }
  }

  async sendServiceStatusAlert(serviceName, status, details = {}) {
    const level = status === 'healthy' ? 'info' : 'warning';
    const message = `Service ${serviceName} is ${status}`;
    
    return this.sendAlert(level, message, {
      service: serviceName,
      status,
      details
    });
  }

  async sendBackupAlert(backupType, success, details = {}) {
    const level = success ? 'info' : 'critical';
    const message = success 
      ? `Backup ${backupType} completed successfully`
      : `Backup ${backupType} failed`;

    return this.sendAlert(level, message, {
      backupType,
      success,
      details
    });
  }

  async sendSSLCertificateAlert(daysUntilExpiry) {
    let level = 'info';
    let message = `SSL certificate expires in ${daysUntilExpiry} days`;

    if (daysUntilExpiry <= 7) {
      level = 'critical';
      message = `SSL certificate expires in ${daysUntilExpiry} days - URGENT ACTION REQUIRED`;
    } else if (daysUntilExpiry <= 30) {
      level = 'warning';
      message = `SSL certificate expires in ${daysUntilExpiry} days - renewal needed soon`;
    }

    return this.sendAlert(level, message, {
      daysUntilExpiry,
      type: 'ssl_certificate'
    });
  }

  async getUserSubscription(userId) {
    try {
      const query = 'SELECT * FROM push_subscriptions WHERE user_id = $1';
      const result = await db.query(query, [userId]);
      return result.rows[0] || null;
    } catch (error) {
      logger.error('Failed to get user subscription', { userId, error: error.message });
      return null;
    }
  }

  async getAllAdminUsers() {
    try {
      const query = 'SELECT id, username, email FROM users WHERE role = $1 AND active = $2';
      const result = await db.query(query, ['admin', true]);
      return result.rows;
    } catch (error) {
      logger.error('Failed to get admin users', { error: error.message });
      return [];
    }
  }

  async cacheNotification(userId, notification) {
    try {
      const cacheKey = `notifications:${userId}`;
      const notifications = await redis.get(cacheKey) || [];
      
      notifications.unshift({
        ...notification,
        timestamp: new Date().toISOString()
      });

      // Keep only last 50 notifications
      if (notifications.length > 50) {
        notifications.splice(50);
      }

      await redis.set(cacheKey, notifications, 86400); // 24 hours
    } catch (error) {
      logger.error('Failed to cache notification', { userId, error: error.message });
    }
  }

  async getNotificationHistory(userId, limit = 20) {
    try {
      const cacheKey = `notifications:${userId}`;
      const notifications = await redis.get(cacheKey) || [];
      return notifications.slice(0, limit);
    } catch (error) {
      logger.error('Failed to get notification history', { userId, error: error.message });
      return [];
    }
  }

  getPublicKey() {
    return this.vapidKeys.publicKey;
  }

  isEnabled() {
    return this.enabled;
  }
}

module.exports = new PushNotificationService();
