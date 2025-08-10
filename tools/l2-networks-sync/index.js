#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import ora from 'ora';
import Database from './database.js';
import NodeSync from './node-sync.js';
import dotenv from 'dotenv';

dotenv.config();

const program = new Command();

program
  .name('l2-networks-sync')
  .description('Tool for synchronizing Ethereum L2 networks from geth and lighthouse nodes')
  .version('1.0.0');

program
  .command('sync')
  .description('Synchronize networks from nodes and update database')
  .option('-f, --force', 'Force sync even if recent sync exists')
  .option('-v, --verbose', 'Verbose output')
  .action(async (options) => {
    await syncNetworks(options);
  });

program
  .command('list')
  .description('List all networks in database')
  .option('-p, --page <number>', 'Page number', '1')
  .option('-l, --limit <number>', 'Items per page', '20')
  .option('-s, --search <term>', 'Search term for network names')
  .option('--raw', 'Raw output without formatting')
  .action(async (options) => {
    await listNetworks(options);
  });

program
  .command('search')
  .description('Search networks by name')
  .argument('<term>', 'Search term (minimum 2 characters)')
  .option('-p, --page <number>', 'Page number', '1')
  .option('-l, --limit <number>', 'Items per page', '20')
  .option('--raw', 'Raw output without formatting')
  .action(async (term, options) => {
    await searchNetworks(term, options);
  });

program
  .command('init')
  .description('Initialize database and create required tables')
  .action(async () => {
    await initializeDatabase();
  });

program
  .command('status')
  .description('Show sync status and database information')
  .action(async () => {
    await showStatus();
  });

async function syncNetworks(options) {
  const spinner = ora('Synchronizing networks...').start();
  
  try {
    const db = new Database();
    const nodeSync = new NodeSync();
    
    // Create table if not exists
    await db.createL2NetworksTable();
    
    // Get networks from nodes
    const networks = await nodeSync.syncAllNetworks();
    
    if (networks.length === 0) {
      spinner.fail('No networks found to sync');
      return;
    }
    
    spinner.text = `Syncing ${networks.length} networks to database...`;
    
    // Insert/update networks in database
    let syncedCount = 0;
    let errorCount = 0;
    
    for (const network of networks) {
      try {
        await db.insertOrUpdateNetwork(network);
        syncedCount++;
        
        if (options.verbose) {
          console.log(chalk.green(`✓ Synced: ${network.name} (Chain ID: ${network.chain_id})`));
        }
      } catch (error) {
        errorCount++;
        console.error(chalk.red(`✗ Error syncing ${network.name}: ${error.message}`));
      }
    }
    
    await db.close();
    
    if (errorCount === 0) {
      spinner.succeed(`Successfully synced ${syncedCount} networks`);
    } else {
      spinner.warn(`Synced ${syncedCount} networks with ${errorCount} errors`);
    }
    
  } catch (error) {
    spinner.fail(`Sync failed: ${error.message}`);
    console.error(chalk.red('Error details:'), error);
    process.exit(1);
  }
}

async function listNetworks(options) {
  const spinner = ora('Fetching networks...').start();
  
  try {
    const db = new Database();
    const page = parseInt(options.page);
    const limit = parseInt(options.limit);
    const search = options.search;
    
    const result = await db.getNetworks(page, limit, search);
    await db.close();
    
    spinner.succeed(`Found ${result.networks.length} networks`);
    
    if (options.raw) {
      console.log(JSON.stringify(result, null, 2));
      return;
    }
    
    displayNetworks(result.networks, result.pagination);
    
  } catch (error) {
    spinner.fail(`Failed to fetch networks: ${error.message}`);
    console.error(chalk.red('Error details:'), error);
    process.exit(1);
  }
}

async function searchNetworks(term, options) {
  if (term.length < 2) {
    console.error(chalk.red('Search term must be at least 2 characters long'));
    process.exit(1);
  }
  
  const spinner = ora(`Searching for networks matching "${term}"...`).start();
  
  try {
    const db = new Database();
    const page = parseInt(options.page);
    const limit = parseInt(options.limit);
    
    const result = await db.getNetworks(page, limit, term);
    await db.close();
    
    spinner.succeed(`Found ${result.networks.length} networks matching "${term}"`);
    
    if (options.raw) {
      console.log(JSON.stringify(result, null, 2));
      return;
    }
    
    displayNetworks(result.networks, result.pagination);
    
  } catch (error) {
    spinner.fail(`Search failed: ${error.message}`);
    console.error(chalk.red('Error details:'), error);
    process.exit(1);
  }
}

async function initializeDatabase() {
  const spinner = ora('Initializing database...').start();
  
  try {
    const db = new Database();
    await db.createL2NetworksTable();
    await db.close();
    
    spinner.succeed('Database initialized successfully');
    
  } catch (error) {
    spinner.fail(`Database initialization failed: ${error.message}`);
    console.error(chalk.red('Error details:'), error);
    process.exit(1);
  }
}

async function showStatus() {
  const spinner = ora('Checking status...').start();
  
  try {
    const db = new Database();
    
    // Check database connection
    const healthCheck = await db.healthCheck();
    
    // Get network count
    const countResult = await db.query('SELECT COUNT(*) as total FROM l2_networks');
    const totalNetworks = parseInt(countResult.rows[0].total);
    
    // Get last sync time
    const lastSyncResult = await db.query(`
      SELECT MAX(updated_at) as last_sync 
      FROM l2_networks 
      WHERE source IN ('geth_sync', 'lighthouse_sync', 'known_networks')
    `);
    
    const lastSync = lastSyncResult.rows[0].last_sync;
    
    await db.close();
    
    spinner.succeed('Status check completed');
    
    console.log('\n' + chalk.blue('=== L2 Networks Sync Tool Status ==='));
    console.log(chalk.green(`✓ Database: ${healthCheck.status}`));
    console.log(chalk.cyan(`📊 Total networks: ${totalNetworks}`));
    
    if (lastSync) {
      const timeAgo = getTimeAgo(lastSync);
      console.log(chalk.yellow(`🕒 Last sync: ${timeAgo}`));
    } else {
      console.log(chalk.red('❌ No sync history found'));
    }
    
    console.log(chalk.blue('=====================================\n'));
    
  } catch (error) {
    spinner.fail(`Status check failed: ${error.message}`);
    console.error(chalk.red('Error details:'), error);
    process.exit(1);
  }
}

function displayNetworks(networks, pagination) {
  if (networks.length === 0) {
    console.log(chalk.yellow('No networks found'));
    return;
  }
  
  console.log('\n' + chalk.blue('=== Networks ==='));
  
  networks.forEach((network, index) => {
    const status = network.is_active ? chalk.green('●') : chalk.red('○');
    const type = network.network_type === 'L2' ? chalk.cyan('L2') : chalk.yellow('L1');
    
    console.log(`${status} ${chalk.bold(network.name)} ${type}`);
    console.log(`   Chain ID: ${chalk.gray(network.chain_id)}`);
    console.log(`   Currency: ${chalk.gray(network.native_currency || 'N/A')}`);
    console.log(`   Source: ${chalk.gray(network.source)}`);
    
    if (network.last_sync_time) {
      const timeAgo = getTimeAgo(network.last_sync_time);
      console.log(`   Last sync: ${chalk.gray(timeAgo)}`);
    }
    
    if (index < networks.length - 1) {
      console.log('');
    }
  });
  
  // Display pagination info
  if (pagination.totalPages > 1) {
    console.log('\n' + chalk.blue('=== Pagination ==='));
    console.log(`Page ${pagination.page} of ${pagination.totalPages}`);
    console.log(`Showing ${networks.length} of ${pagination.total} networks`);
    
    if (pagination.page > 1) {
      console.log(`Previous: --page ${pagination.page - 1}`);
    }
    if (pagination.page < pagination.totalPages) {
      console.log(`Next: --page ${pagination.page + 1}`);
    }
  }
  
  console.log(chalk.blue('==================\n'));
}

function getTimeAgo(dateString) {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);
  
  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins} minute${diffMins > 1 ? 's' : ''} ago`;
  if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
  if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
  
  return date.toLocaleDateString();
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error(chalk.red('Unhandled Rejection at:'), promise);
  console.error(chalk.red('Reason:'), reason);
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error(chalk.red('Uncaught Exception:'), error);
  process.exit(1);
});

// Parse command line arguments
program.parse();
