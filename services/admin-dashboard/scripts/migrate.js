#!/usr/bin/env node

require('dotenv').config();
const fs = require('fs').promises;
const path = require('path');
const db = require('../config/database');
const logger = require('../utils/logger');

async function runMigration() {
  try {
    logger.info('Starting database migration...');

    // Read the SQL file
    const sqlPath = path.join(__dirname, 'init-database.sql');
    const sqlContent = await fs.readFile(sqlPath, 'utf8');

    // Split SQL into individual statements
    const statements = sqlContent
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      if (statement.trim()) {
        try {
          await db.query(statement);
          logger.info(`Executed statement ${i + 1}/${statements.length}`);
        } catch (error) {
          // Skip if table already exists or other non-critical errors
          if (error.code === '42P07' || error.code === '42710') {
            logger.info(`Skipped statement ${i + 1} (already exists): ${error.message}`);
          } else {
            logger.error(`Error executing statement ${i + 1}:`, error.message);
            throw error;
          }
        }
      }
    }

    logger.info('Database migration completed successfully');
  } catch (error) {
    logger.error('Migration failed:', error);
    process.exit(1);
  } finally {
    await db.close();
  }
}

// Run migration if this script is executed directly
if (require.main === module) {
  runMigration();
}

module.exports = { runMigration };
