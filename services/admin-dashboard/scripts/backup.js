#!/usr/bin/env node

require('dotenv').config();
const backupService = require('../utils/backup');
const logger = require('../utils/logger');

async function runBackup() {
  try {
    logger.info('Starting manual backup...');
    
    const result = await backupService.performBackup('manual');
    
    if (result.success) {
      logger.info('Backup completed successfully', {
        filename: result.filename,
        size: result.size,
        duration: result.duration
      });
      console.log(`✅ Backup completed: ${result.filename} (${result.size} bytes, ${result.duration}ms)`);
    } else {
      logger.error('Backup failed', result);
      console.log(`❌ Backup failed: ${result.error}`);
      process.exit(1);
    }
  } catch (error) {
    logger.error('Backup script error:', error);
    console.log(`❌ Backup script error: ${error.message}`);
    process.exit(1);
  }
}

// Run backup if this script is executed directly
if (require.main === module) {
  runBackup();
}

module.exports = { runBackup };
