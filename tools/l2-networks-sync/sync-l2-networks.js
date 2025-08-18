#!/usr/bin/env node

import BeaconL2Sync from './beacon-l2-sync.js';
import fs from 'fs';
import path from 'path';

class L2NetworkSyncRunner {
  constructor() {
    this.sync = new BeaconL2Sync();
    this.outputDir = process.env.OUTPUT_DIR || './output';
    this.ensureOutputDir();
  }

  ensureOutputDir() {
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }
  }

  async runSync() {
    try {
      console.log('🚀 Starting L2 Network Synchronization...');
      console.log('=' .repeat(60));
      
      // Get current timestamp
      const timestamp = new Date().toISOString();
      console.log(`📅 Sync started at: ${timestamp}`);
      
      // Run the synchronization
      const networks = await this.sync.syncAllL2Networks();
      
      if (!networks || networks.length === 0) {
        console.error('❌ No networks found during synchronization');
        process.exit(1);
      }
      
      // Separate L1 and L2 networks
      const l1Networks = networks.filter(n => n.network_type === 'L1');
      const l2Networks = networks.filter(n => n.network_type === 'L2');
      
      console.log('\n📊 Synchronization Results:');
      console.log(`   L1 Networks: ${l1Networks.length}`);
      console.log(`   L2 Networks: ${l2Networks.length}`);
      console.log(`   Total Networks: ${networks.length}`);
      
      // Save results to files
      await this.saveResults(networks, timestamp);
      
      // Generate summary report
      await this.generateSummaryReport(networks, timestamp);
      
      console.log('\n✅ Synchronization completed successfully!');
      console.log(`📁 Results saved to: ${this.outputDir}`);
      
    } catch (error) {
      console.error('❌ Synchronization failed:', error.message);
      console.error(error.stack);
      process.exit(1);
    }
  }

  async saveResults(networks, timestamp) {
    try {
      // Save all networks
      const allNetworksFile = path.join(this.outputDir, `all-networks-${timestamp.split('T')[0]}.json`);
      fs.writeFileSync(allNetworksFile, JSON.stringify(networks, null, 2));
      console.log(`💾 All networks saved to: ${allNetworksFile}`);
      
      // Save L2 networks separately
      const l2Networks = networks.filter(n => n.network_type === 'L2');
      const l2NetworksFile = path.join(this.outputDir, `l2-networks-${timestamp.split('T')[0]}.json`);
      fs.writeFileSync(l2NetworksFile, JSON.stringify(l2Networks, null, 2));
      console.log(`💾 L2 networks saved to: ${l2NetworksFile}`);
      
      // Save L1 networks separately
      const l1Networks = networks.filter(n => n.network_type === 'L1');
      const l1NetworksFile = path.join(this.outputDir, `l1-networks-${timestamp.split('T')[0]}.json`);
      fs.writeFileSync(l1NetworksFile, JSON.stringify(l1Networks, null, 2));
      console.log(`💾 L1 networks saved to: ${l1NetworksFile}`);
      
      // Save latest networks (for easy access)
      fs.writeFileSync(path.join(this.outputDir, 'latest-networks.json'), JSON.stringify(networks, null, 2));
      fs.writeFileSync(path.join(this.outputDir, 'latest-l2-networks.json'), JSON.stringify(l2Networks, null, 2));
      fs.writeFileSync(path.join(this.outputDir, 'latest-l1-networks.json'), JSON.stringify(l1Networks, null, 2));
      
    } catch (error) {
      console.error('Error saving results:', error.message);
    }
  }

  async generateSummaryReport(networks, timestamp) {
    try {
      const l2Networks = networks.filter(n => n.network_type === 'L2');
      const l1Networks = networks.filter(n => n.network_type === 'L1');
      
      const report = {
        sync_info: {
          timestamp: timestamp,
          total_networks: networks.length,
          l1_networks: l1Networks.length,
          l2_networks: l2Networks.length
        },
        l1_summary: l1Networks.map(n => ({
          name: n.name,
          chain_id: n.chain_id,
          source: n.source,
          last_block_number: n.last_block_number,
          last_sync_time: n.last_sync_time
        })),
        l2_summary: l2Networks.map(n => ({
          name: n.name,
          chain_id: n.chain_id,
          source: n.source,
          rpc_url: n.rpc_url,
          explorer_url: n.explorer_url,
          block_time: n.block_time,
          last_sync_time: n.last_sync_time
        })),
        sources: this.getSourceBreakdown(networks),
        rollup_types: this.getRollupTypeBreakdown(l2Networks)
      };
      
      const reportFile = path.join(this.outputDir, `sync-report-${timestamp.split('T')[0]}.json`);
      fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));
      console.log(`📋 Summary report saved to: ${reportFile}`);
      
      // Also save latest report
      fs.writeFileSync(path.join(this.outputDir, 'latest-sync-report.json'), JSON.stringify(report, null, 2));
      
    } catch (error) {
      console.error('Error generating summary report:', error.message);
    }
  }

  getSourceBreakdown(networks) {
    const sources = {};
    networks.forEach(network => {
      const source = network.source;
      sources[source] = (sources[source] || 0) + 1;
    });
    return sources;
  }

  getRollupTypeBreakdown(l2Networks) {
    const rollupTypes = {};
    l2Networks.forEach(network => {
      const type = network.metadata?.rollup_type || 'unknown';
      rollupTypes[type] = (rollupTypes[type] || 0) + 1;
    });
    return rollupTypes;
  }

  async validateNetworks(networks) {
    console.log('\n🔍 Validating networks...');
    
    const validationResults = {
      total: networks.length,
      valid: 0,
      invalid: 0,
      errors: []
    };
    
    networks.forEach((network, index) => {
      try {
        // Basic validation
        if (!network.name || !network.chain_id || !network.network_type) {
          validationResults.errors.push({
            index,
            network: network.name || 'Unknown',
            error: 'Missing required fields'
          });
          validationResults.invalid++;
          return;
        }
        
        // Chain ID validation
        if (isNaN(network.chain_id) || network.chain_id <= 0) {
          validationResults.errors.push({
            index,
            network: network.name,
            error: 'Invalid chain_id'
          });
          validationResults.invalid++;
          return;
        }
        
        // L2 specific validation
        if (network.network_type === 'L2') {
          if (!network.rpc_url) {
            validationResults.errors.push({
              index,
              network: network.name,
              error: 'L2 network missing RPC URL'
            });
            validationResults.invalid++;
            return;
          }
        }
        
        validationResults.valid++;
        
      } catch (error) {
        validationResults.errors.push({
          index,
          network: network.name || 'Unknown',
          error: error.message
        });
        validationResults.invalid++;
      }
    });
    
    console.log(`   Valid: ${validationResults.valid}`);
    console.log(`   Invalid: ${validationResults.invalid}`);
    
    if (validationResults.errors.length > 0) {
      console.log('\n⚠️  Validation errors:');
      validationResults.errors.forEach(error => {
        console.log(`   - ${error.network}: ${error.error}`);
      });
    }
    
    return validationResults;
  }
}

// Main execution
async function main() {
  const runner = new L2NetworkSyncRunner();
  
  try {
    await runner.runSync();
    
    // Optional: Run validation
    if (process.env.RUN_VALIDATION === 'true') {
      const networks = JSON.parse(fs.readFileSync(path.join(runner.outputDir, 'latest-networks.json'), 'utf8'));
      await runner.validateNetworks(networks);
    }
    
  } catch (error) {
    console.error('Fatal error:', error.message);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export default L2NetworkSyncRunner;
