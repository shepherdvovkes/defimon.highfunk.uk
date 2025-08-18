const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const cron = require('node-cron');
const logger = require('./logger');
const pushNotifications = require('./pushNotifications');

class BackupService {
  constructor() {
    this.backupPath = process.env.BACKUP_PATH || '/backups';
    this.retentionDays = parseInt(process.env.BACKUP_RETENTION_DAYS) || 30;
    this.enabled = process.env.BACKUP_ENABLED === 'true';
    this.schedule = process.env.BACKUP_SCHEDULE || '0 2 * * *'; // Default: 2 AM daily
    
    if (this.enabled) {
      this.initializeBackupDirectory();
      this.scheduleBackups();
      logger.info('Backup service initialized', {
        backupPath: this.backupPath,
        retentionDays: this.retentionDays,
        schedule: this.schedule
      });
    } else {
      logger.info('Backup service disabled');
    }
  }

  async initializeBackupDirectory() {
    try {
      await fs.mkdir(this.backupPath, { recursive: true });
      logger.info('Backup directory initialized', { path: this.backupPath });
    } catch (error) {
      logger.error('Failed to initialize backup directory', { error: error.message });
    }
  }

  scheduleBackups() {
    if (!this.enabled) return;

    cron.schedule(this.schedule, async () => {
      logger.info('Starting scheduled backup');
      await this.performBackup('scheduled');
    }, {
      scheduled: true,
      timezone: "UTC"
    });

    logger.info('Backup schedule configured', { schedule: this.schedule });
  }

  async performBackup(type = 'manual') {
    const startTime = Date.now();
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `backup-${type}-${timestamp}.sql`;
    const filepath = path.join(this.backupPath, filename);

    try {
      logger.info('Starting database backup', { type, filename });

      // Create backup using pg_dump
      const backupCommand = this.buildBackupCommand(filepath);
      
      const success = await this.executeBackupCommand(backupCommand);
      
      if (success) {
        const duration = Date.now() - startTime;
        const fileSize = await this.getFileSize(filepath);
        
        logger.info('Backup completed successfully', {
          type,
          filename,
          duration: `${duration}ms`,
          size: `${fileSize} bytes`
        });

        // Store backup metadata
        await this.storeBackupMetadata({
          filename,
          type,
          size: fileSize,
          duration,
          status: 'success',
          timestamp: new Date().toISOString()
        });

        // Send success notification
        await pushNotifications.sendBackupAlert(type, true, {
          filename,
          size: fileSize,
          duration
        });

        // Clean up old backups
        await this.cleanupOldBackups();

        return {
          success: true,
          filename,
          size: fileSize,
          duration
        };
      } else {
        throw new Error('Backup command failed');
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      
      logger.error('Backup failed', {
        type,
        filename,
        error: error.message,
        duration: `${duration}ms`
      });

      // Store failed backup metadata
      await this.storeBackupMetadata({
        filename,
        type,
        duration,
        status: 'failed',
        error: error.message,
        timestamp: new Date().toISOString()
      });

      // Send failure notification
      await pushNotifications.sendBackupAlert(type, false, {
        filename,
        error: error.message,
        duration
      });

      return {
        success: false,
        error: error.message,
        duration
      };
    }
  }

  buildBackupCommand(filepath) {
    const host = process.env.POSTGRES_HOST || 'postgres';
    const port = process.env.POSTGRES_PORT || 5432;
    const database = process.env.POSTGRES_DB || 'admin_dashboard';
    const user = process.env.POSTGRES_USER || 'admin_user';
    const password = process.env.POSTGRES_PASSWORD || 'password';

    return `PGPASSWORD="${password}" pg_dump -h ${host} -p ${port} -U ${user} -d ${database} -f ${filepath} --verbose --no-password`;
  }

  async executeBackupCommand(command) {
    return new Promise((resolve) => {
      exec(command, { timeout: 300000 }, (error, stdout, stderr) => {
        if (error) {
          logger.error('Backup command error', {
            error: error.message,
            stderr,
            code: error.code
          });
          resolve(false);
        } else {
          logger.debug('Backup command output', { stdout });
          resolve(true);
        }
      });
    });
  }

  async getFileSize(filepath) {
    try {
      const stats = await fs.stat(filepath);
      return stats.size;
    } catch (error) {
      logger.error('Failed to get backup file size', { filepath, error: error.message });
      return 0;
    }
  }

  async storeBackupMetadata(metadata) {
    try {
      const query = `
        INSERT INTO backup_history (
          filename, type, size, duration, status, error, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      `;

      await require('../config/database').query(query, [
        metadata.filename,
        metadata.type,
        metadata.size || 0,
        metadata.duration,
        metadata.status,
        metadata.error || null,
        metadata.timestamp
      ]);

      logger.debug('Backup metadata stored', { filename: metadata.filename });
    } catch (error) {
      logger.error('Failed to store backup metadata', { error: error.message });
    }
  }

  async cleanupOldBackups() {
    try {
      const files = await fs.readdir(this.backupPath);
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - this.retentionDays);

      let deletedCount = 0;
      let totalSize = 0;

      for (const file of files) {
        if (!file.endsWith('.sql')) continue;

        const filepath = path.join(this.backupPath, file);
        const stats = await fs.stat(filepath);

        if (stats.mtime < cutoffDate) {
          await fs.unlink(filepath);
          deletedCount++;
          totalSize += stats.size;
          
          logger.info('Deleted old backup file', {
            filename: file,
            size: stats.size,
            age: Math.floor((Date.now() - stats.mtime.getTime()) / (1000 * 60 * 60 * 24))
          });
        }
      }

      if (deletedCount > 0) {
        logger.info('Backup cleanup completed', {
          deletedCount,
          totalSize: `${totalSize} bytes`,
          retentionDays: this.retentionDays
        });
      }
    } catch (error) {
      logger.error('Failed to cleanup old backups', { error: error.message });
    }
  }

  async restoreBackup(filename) {
    const filepath = path.join(this.backupPath, filename);
    const startTime = Date.now();

    try {
      logger.info('Starting backup restoration', { filename });

      // Check if backup file exists
      await fs.access(filepath);

      const restoreCommand = this.buildRestoreCommand(filepath);
      const success = await this.executeRestoreCommand(restoreCommand);

      if (success) {
        const duration = Date.now() - startTime;
        
        logger.info('Backup restoration completed successfully', {
          filename,
          duration: `${duration}ms`
        });

        // Send restoration notification
        await pushNotifications.sendAlert('info', `Backup restoration completed: ${filename}`, {
          filename,
          duration,
          type: 'restore'
        });

        return {
          success: true,
          filename,
          duration
        };
      } else {
        throw new Error('Restore command failed');
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      
      logger.error('Backup restoration failed', {
        filename,
        error: error.message,
        duration: `${duration}ms`
      });

      // Send failure notification
      await pushNotifications.sendAlert('critical', `Backup restoration failed: ${filename}`, {
        filename,
        error: error.message,
        duration,
        type: 'restore'
      });

      return {
        success: false,
        error: error.message,
        duration
      };
    }
  }

  buildRestoreCommand(filepath) {
    const host = process.env.POSTGRES_HOST || 'postgres';
    const port = process.env.POSTGRES_PORT || 5432;
    const database = process.env.POSTGRES_DB || 'admin_dashboard';
    const user = process.env.POSTGRES_USER || 'admin_user';
    const password = process.env.POSTGRES_PASSWORD || 'password';

    return `PGPASSWORD="${password}" psql -h ${host} -p ${port} -U ${user} -d ${database} -f ${filepath} --verbose --no-password`;
  }

  async executeRestoreCommand(command) {
    return new Promise((resolve) => {
      exec(command, { timeout: 600000 }, (error, stdout, stderr) => {
        if (error) {
          logger.error('Restore command error', {
            error: error.message,
            stderr,
            code: error.code
          });
          resolve(false);
        } else {
          logger.debug('Restore command output', { stdout });
          resolve(true);
        }
      });
    });
  }

  async getBackupHistory(limit = 50) {
    try {
      const query = `
        SELECT * FROM backup_history 
        ORDER BY created_at DESC 
        LIMIT $1
      `;

      const result = await require('../config/database').query(query, [limit]);
      return result.rows;
    } catch (error) {
      logger.error('Failed to get backup history', { error: error.message });
      return [];
    }
  }

  async getBackupStats() {
    try {
      const files = await fs.readdir(this.backupPath);
      const backupFiles = files.filter(file => file.endsWith('.sql'));
      
      let totalSize = 0;
      const stats = {
        total: backupFiles.length,
        successful: 0,
        failed: 0,
        totalSize: 0,
        oldest: null,
        newest: null
      };

      for (const file of backupFiles) {
        const filepath = path.join(this.backupPath, file);
        const fileStats = await fs.stat(filepath);
        
        totalSize += fileStats.size;
        
        if (!stats.oldest || fileStats.mtime < stats.oldest) {
          stats.oldest = fileStats.mtime;
        }
        if (!stats.newest || fileStats.mtime > stats.newest) {
          stats.newest = fileStats.mtime;
        }
      }

      stats.totalSize = totalSize;

      // Get success/failure counts from database
      const query = `
        SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN status = 'success' THEN 1 END) as successful,
          COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
        FROM backup_history
        WHERE created_at >= NOW() - INTERVAL '30 days'
      `;

      const result = await require('../config/database').query(query);
      const dbStats = result.rows[0];
      
      stats.successful = parseInt(dbStats.successful) || 0;
      stats.failed = parseInt(dbStats.failed) || 0;

      return stats;
    } catch (error) {
      logger.error('Failed to get backup stats', { error: error.message });
      return null;
    }
  }

  async listBackupFiles() {
    try {
      const files = await fs.readdir(this.backupPath);
      const backupFiles = [];

      for (const file of files) {
        if (!file.endsWith('.sql')) continue;

        const filepath = path.join(this.backupPath, file);
        const stats = await fs.stat(filepath);
        
        backupFiles.push({
          filename: file,
          size: stats.size,
          created: stats.mtime,
          age: Math.floor((Date.now() - stats.mtime.getTime()) / (1000 * 60 * 60 * 24))
        });
      }

      return backupFiles.sort((a, b) => b.created - a.created);
    } catch (error) {
      logger.error('Failed to list backup files', { error: error.message });
      return [];
    }
  }
}

module.exports = new BackupService();
