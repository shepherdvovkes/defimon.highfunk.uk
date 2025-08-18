#!/usr/bin/env node

import BeaconL2Sync from './beacon-l2-sync.js';

async function testBeaconAPI() {
  console.log('🧪 Testing Beacon Chain API Connection...');
  console.log('=' .repeat(50));
  
  const sync = new BeaconL2Sync();
  
  try {
    // Test 1: Beacon Chain Info
    console.log('\n1️⃣ Testing Beacon Chain Info...');
    const beaconInfo = await sync.getBeaconChainInfo();
    if (beaconInfo) {
      console.log('✅ Beacon Chain Info:', {
        name: beaconInfo.name,
        chain_id: beaconInfo.chain_id,
        network_type: beaconInfo.network_type,
        last_block_number: beaconInfo.last_block_number,
        source: beaconInfo.source
      });
    } else {
      console.log('❌ Could not get Beacon Chain info');
    }
    
    // Test 2: Known L2 Networks
    console.log('\n2️⃣ Testing Known L2 Networks...');
    const knownNetworks = await sync.getKnownL2Networks();
    console.log(`✅ Found ${knownNetworks.length} known L2 networks`);
    
    // Show first few networks
    knownNetworks.slice(0, 3).forEach(network => {
      console.log(`   - ${network.name} (Chain ID: ${network.chain_id})`);
    });
    
    // Test 3: Ethereum Foundation APIs (may fail if APIs are not available)
    console.log('\n3️⃣ Testing Ethereum Foundation APIs...');
    try {
      const efNetworks = await sync.getEthereumFoundationL2Networks();
      console.log(`✅ Found ${efNetworks.length} networks from Ethereum Foundation APIs`);
    } catch (error) {
      console.log('⚠️  Ethereum Foundation APIs not available:', error.message);
    }
    
    // Test 4: Chainlist APIs (may fail if APIs are not available)
    console.log('\n4️⃣ Testing Chainlist APIs...');
    try {
      const chainlistNetworks = await sync.getChainlistL2Networks();
      console.log(`✅ Found ${chainlistNetworks.length} networks from Chainlist APIs`);
    } catch (error) {
      console.log('⚠️  Chainlist APIs not available:', error.message);
    }
    
    // Test 5: Full Sync (small test)
    console.log('\n5️⃣ Testing Full Sync (small)...');
    const allNetworks = await sync.syncAllL2Networks();
    console.log(`✅ Total networks found: ${allNetworks.length}`);
    
    const l1Count = allNetworks.filter(n => n.network_type === 'L1').length;
    const l2Count = allNetworks.filter(n => n.network_type === 'L2').length;
    
    console.log(`   L1 Networks: ${l1Count}`);
    console.log(`   L2 Networks: ${l2Count}`);
    
    // Show network sources breakdown
    const sources = {};
    allNetworks.forEach(network => {
      sources[network.source] = (sources[network.source] || 0) + 1;
    });
    
    console.log('\n📊 Network Sources:');
    Object.entries(sources).forEach(([source, count]) => {
      console.log(`   ${source}: ${count}`);
    });
    
    console.log('\n🎉 All tests completed successfully!');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run test if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  testBeaconAPI();
}

export default testBeaconAPI;
