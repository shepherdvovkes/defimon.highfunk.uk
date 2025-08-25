import NodeSync from './node-sync.js';
import dotenv from 'dotenv';

dotenv.config();

async function testChainlistAPI() {
  console.log('🧪 Testing Chainlist API Integration...\n');
  
  const nodeSync = new NodeSync();
  
  try {
    console.log('📡 Fetching networks from Chainlist API...');
    const networks = await nodeSync.getChainlistNetworks();
    
    if (networks.length === 0) {
      console.log('❌ No networks found from Chainlist API');
      return;
    }
    
    console.log(`✅ Found ${networks.length} networks from Chainlist API\n`);
    
    // Show first 5 networks as examples
    console.log('📋 Sample networks:');
    networks.slice(0, 5).forEach((network, index) => {
      console.log(`\n${index + 1}. ${network.name} (Chain ID: ${network.chain_id})`);
      console.log(`   Type: ${network.network_type}`);
      console.log(`   Currency: ${network.native_currency}`);
      console.log(`   RPC: ${network.rpc_url || 'N/A'}`);
      console.log(`   Explorer: ${network.explorer_url || 'N/A'}`);
      console.log(`   Source: ${network.source}`);
      
      if (network.metadata.rollup_type !== 'unknown') {
        console.log(`   Rollup: ${network.metadata.rollup_type}`);
      }
    });
    
    // Show statistics
    const l2Networks = networks.filter(n => n.network_type === 'L2');
    const mainnetNetworks = networks.filter(n => n.metadata.network_type === 'mainnet');
    const testnetNetworks = networks.filter(n => n.metadata.network_type === 'testnet');
    
    console.log('\n📊 Statistics:');
    console.log(`   Total networks: ${networks.length}`);
    console.log(`   L2 networks: ${l2Networks.length}`);
    console.log(`   Mainnet networks: ${mainnetNetworks.length}`);
    console.log(`   Testnet networks: ${testnetNetworks.length}`);
    
    // Show unique sources
    const sources = [...new Set(networks.map(n => n.source))];
    console.log(`   Sources: ${sources.join(', ')}`);
    
  } catch (error) {
    console.error('❌ Error testing Chainlist API:', error.message);
    console.error('Stack trace:', error.stack);
  }
}

async function testFullSync() {
  console.log('\n🔄 Testing full network synchronization...\n');
  
  const nodeSync = new NodeSync();
  
  try {
    const allNetworks = await nodeSync.syncAllNetworks();
    
    if (allNetworks.length === 0) {
      console.log('❌ No networks found during full sync');
      return;
    }
    
    console.log(`✅ Full sync completed. Found ${allNetworks.length} total networks\n`);
    
    // Group networks by source
    const networksBySource = {};
    allNetworks.forEach(network => {
      const source = network.source;
      if (!networksBySource[source]) {
        networksBySource[source] = [];
      }
      networksBySource[source].push(network);
    });
    
    console.log('📊 Networks by source:');
    Object.entries(networksBySource).forEach(([source, networks]) => {
      console.log(`   ${source}: ${networks.length} networks`);
    });
    
    // Show some examples from each source
    Object.entries(networksBySource).forEach(([source, networks]) => {
      console.log(`\n🔍 Sample from ${source}:`);
      networks.slice(0, 3).forEach((network, index) => {
        console.log(`   ${index + 1}. ${network.name} (${network.chain_id})`);
      });
    });
    
  } catch (error) {
    console.error('❌ Error during full sync:', error.message);
  }
}

// Run tests
async function runTests() {
  console.log('🚀 Starting Chainlist API Integration Tests\n');
  
  await testChainlistAPI();
  await testFullSync();
  
  console.log('\n✨ Tests completed!');
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runTests().catch(console.error);
}

export { testChainlistAPI, testFullSync };
