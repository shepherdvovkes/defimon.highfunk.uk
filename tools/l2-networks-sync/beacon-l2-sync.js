import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

class BeaconL2Sync {
  constructor() {
    // Beacon Chain API endpoints
    this.beaconApiUrl = process.env.BEACON_API_URL || 'http://localhost:5052';
    this.ethereumFoundationApiUrl = 'https://api.ethereum.org/api/v1';
    this.chainlistApiUrl = 'https://chainlist.org/api/v1';
    
    // Timeout and retry settings
    this.timeout = parseInt(process.env.SYNC_TIMEOUT_MS) || 30000;
    this.retryAttempts = parseInt(process.env.SYNC_RETRY_ATTEMPTS) || 3;
    
    // Known L2 networks for validation
    this.knownL2Networks = new Map([
      [137, { name: 'Polygon', type: 'rollup', data_availability: 'ethereum' }],
      [42161, { name: 'Arbitrum One', type: 'rollup', data_availability: 'ethereum' }],
      [10, { name: 'Optimism', type: 'rollup', data_availability: 'ethereum' }],
      [8453, { name: 'Base', type: 'rollup', data_availability: 'ethereum' }],
      [324, { name: 'zkSync Era', type: 'rollup', data_availability: 'ethereum' }],
      [1101, { name: 'Polygon zkEVM', type: 'rollup', data_availability: 'ethereum' }],
      [534352, { name: 'Scroll', type: 'rollup', data_availability: 'ethereum' }],
      [5000, { name: 'Mantle', type: 'rollup', data_availability: 'ethereum' }],
      [59144, { name: 'Linea', type: 'rollup', data_availability: 'ethereum' }],
      [100, { name: 'Gnosis Chain', type: 'rollup', data_availability: 'ethereum' }],
      [250, { name: 'Fantom', type: 'rollup', data_availability: 'ethereum' }],
      [43114, { name: 'Avalanche C-Chain', type: 'rollup', data_availability: 'ethereum' }]
    ]);
  }

  async makeRequest(url, options, retryCount = 0) {
    try {
      const response = await axios({
        ...options,
        url,
        timeout: this.timeout,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Defimon-Beacon-L2-Sync/1.0.0',
          ...options.headers
        }
      });
      return response;
    } catch (error) {
      if (retryCount < this.retryAttempts && this.isRetryableError(error)) {
        console.log(`Retry attempt ${retryCount + 1} for ${url}`);
        await this.delay(1000 * (retryCount + 1));
        return this.makeRequest(url, options, retryCount + 1);
      }
      throw error;
    }
  }

  isRetryableError(error) {
    return error.code === 'ECONNRESET' || 
           error.code === 'ETIMEDOUT' || 
           error.code === 'ECONNREFUSED' ||
           (error.response && error.response.status >= 500);
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async getBeaconChainInfo() {
    try {
      console.log('Fetching Beacon Chain information...');
      
      const [nodeInfo, genesis, syncStatus, finality] = await Promise.allSettled([
        this.makeRequest(`${this.beaconApiUrl}/eth/v1/node/info`, { method: 'GET' }),
        this.makeRequest(`${this.beaconApiUrl}/eth/v1/beacon/genesis`, { method: 'GET' }),
        this.makeRequest(`${this.beaconApiUrl}/eth/v1/node/syncing`, { method: 'GET' }),
        this.makeRequest(`${this.beaconApiUrl}/eth/v1/beacon/states/finalized/finality_checkpoints`, { method: 'GET' })
      ]);

      const beaconInfo = {
        name: 'Ethereum Beacon Chain',
        chain_id: 1,
        network_type: 'L1',
        rpc_url: this.beaconApiUrl,
        explorer_url: 'https://beaconcha.in',
        native_currency: 'ETH',
        block_time: 12,
        is_active: true,
        last_block_number: finality.status === 'fulfilled' ? parseInt(finality.value.data.data.finalized.root, 16) : null,
        last_sync_time: new Date(),
        metadata: {
          beacon_version: nodeInfo.status === 'fulfilled' ? nodeInfo.value.data.data.version : 'unknown',
          genesis_time: genesis.status === 'fulfilled' ? genesis.value.data.data.genesis_time : 'unknown',
          genesis_validators_root: genesis.status === 'fulfilled' ? genesis.value.data.data.genesis_validators_root : 'unknown',
          sync_status: syncStatus.status === 'fulfilled' ? syncStatus.value.data.data : 'unknown',
          client: 'lighthouse',
          sync_method: 'beacon_api'
        },
        source: 'beacon_chain_sync'
      };

      console.log('✓ Beacon Chain information fetched successfully');
      return beaconInfo;
    } catch (error) {
      console.error('Error fetching Beacon Chain information:', error.message);
      return null;
    }
  }

  async getEthereumFoundationL2Networks() {
    try {
      console.log('Fetching L2 networks from Ethereum Foundation APIs...');
      
      const l2Networks = [];
      
      // 1. Ethereum Foundation Rollups API
      try {
        console.log('  → Fetching from Rollups API...');
        const rollupsResponse = await this.makeRequest(`${this.ethereumFoundationApiUrl}/rollups`, {
          method: 'GET'
        });

        if (rollupsResponse.data && Array.isArray(rollupsResponse.data)) {
          rollupsResponse.data.forEach(rollup => {
            if (this.isValidL2Network(rollup)) {
              l2Networks.push(this.processEthereumFoundationNetwork(rollup, 'rollup'));
            }
          });
          console.log(`    ✓ Found ${rollupsResponse.data.length} rollups`);
        }
      } catch (error) {
        console.warn('  → Could not fetch from Rollups API:', error.message);
      }

      // 2. Ethereum Foundation Bridges API
      try {
        console.log('  → Fetching from Bridges API...');
        const bridgesResponse = await this.makeRequest(`${this.ethereumFoundationApiUrl}/bridges`, {
          method: 'GET'
        });

        if (bridgesResponse.data && Array.isArray(bridgesResponse.data)) {
          bridgesResponse.data.forEach(bridge => {
            if (bridge.destination_chain && this.isValidL2Network(bridge.destination_chain)) {
              l2Networks.push(this.processEthereumFoundationNetwork(bridge.destination_chain, 'bridge'));
            }
          });
          console.log(`    ✓ Found ${bridgesResponse.data.length} bridges`);
        }
      } catch (error) {
        console.warn('  → Could not fetch from Bridges API:', error.message);
      }

      // 3. Ethereum Foundation L2 Metrics API
      try {
        console.log('  → Fetching from L2 Metrics API...');
        const metricsResponse = await this.makeRequest(`${this.ethereumFoundationApiUrl}/l2-metrics`, {
          method: 'GET'
        });

        if (metricsResponse.data && Array.isArray(metricsResponse.data)) {
          // Update existing L2 networks with metrics
          l2Networks.forEach(network => {
            const metric = metricsResponse.data.find(m => m.chain_id === network.chain_id);
            if (metric) {
              network.metadata.metrics = metric;
            }
          });
          console.log(`    ✓ Updated ${metricsResponse.data.length} networks with metrics`);
        }
      } catch (error) {
        console.warn('  → Could not fetch from L2 Metrics API:', error.message);
      }

      console.log(`  → Successfully fetched ${l2Networks.length} L2 networks from Ethereum Foundation`);
      return l2Networks;
    } catch (error) {
      console.error('Error fetching Ethereum Foundation L2 networks:', error.message);
      return [];
    }
  }

  async getChainlistL2Networks() {
    try {
      console.log('Fetching L2 networks from Chainlist API...');
      
      const [mainnetResponse, testnetResponse] = await Promise.allSettled([
        this.makeRequest(`${this.chainlistApiUrl}/mainnet`, { method: 'GET' }),
        this.makeRequest(`${this.chainlistApiUrl}/testnet`, { method: 'GET' })
      ]);

      const l2Networks = [];
      
      if (mainnetResponse.status === 'fulfilled' && mainnetResponse.value.data) {
        mainnetResponse.value.data.forEach(network => {
          if (this.isValidL2Network(network)) {
            l2Networks.push(this.processChainlistNetwork(network, 'mainnet'));
          }
        });
      }

      if (testnetResponse.status === 'fulfilled' && testnetResponse.value.data) {
        testnetResponse.value.data.forEach(network => {
          if (this.isValidL2Network(network)) {
            l2Networks.push(this.processChainlistNetwork(network, 'testnet'));
          }
        });
      }

      console.log(`✓ Found ${l2Networks.length} L2 networks from Chainlist`);
      return l2Networks;
    } catch (error) {
      console.error('Error fetching Chainlist L2 networks:', error.message);
      return [];
    }
  }

  async getKnownL2Networks() {
    try {
      console.log('Fetching known L2 networks...');
      
      const knownNetworks = [];
      
      // Add known L2 networks with their metadata
      this.knownL2Networks.forEach((metadata, chainId) => {
        knownNetworks.push({
          name: metadata.name,
          chain_id: chainId,
          network_type: 'L2',
          rpc_url: this.getDefaultRpcUrl(chainId),
          explorer_url: this.getDefaultExplorerUrl(chainId),
          native_currency: 'ETH',
          block_time: this.estimateBlockTime(chainId),
          is_active: true,
          last_block_number: null,
          last_sync_time: new Date(),
          metadata: {
            rollup_type: metadata.type,
            data_availability: metadata.data_availability,
            fraud_proof: true,
            sequencer: 'centralized',
            verifier: 'ethereum',
            client: 'known_network',
            sync_method: 'static_data',
            source: 'hardcoded_known_networks'
          },
          source: 'known_l2_networks'
        });
      });

      console.log(`✓ Added ${knownNetworks.length} known L2 networks`);
      return knownNetworks;
    } catch (error) {
      console.error('Error processing known L2 networks:', error.message);
      return [];
    }
  }

  isValidL2Network(network) {
    if (!network || !network.chainId) return false;
    
    const chainId = parseInt(network.chainId);
    
    // Must have a valid chain ID
    if (isNaN(chainId) || chainId <= 0) return false;
    
    // Must not be Ethereum mainnet (chain ID 1)
    if (chainId === 1) return false;
    
    // Must have a name
    if (!network.name || typeof network.name !== 'string') return false;
    
    // Must have RPC URL
    if (!network.rpcUrls || !Array.isArray(network.rpcUrls) || network.rpcUrls.length === 0) return false;
    
    return true;
  }

  processEthereumFoundationNetwork(network, type) {
    return {
      name: network.name,
      chain_id: parseInt(network.chain_id || network.chainId),
      network_type: 'L2',
      rpc_url: network.rpc_url || (network.rpcUrls && network.rpcUrls[0]),
      explorer_url: network.explorer_url || (network.explorers && network.explorers[0]?.url),
      native_currency: network.native_currency || 'ETH',
      block_time: network.block_time || this.estimateBlockTime(parseInt(network.chain_id || network.chainId)),
      is_active: true,
      last_block_number: null,
      last_sync_time: new Date(),
      metadata: {
        rollup_type: type,
        data_availability: network.data_availability || 'ethereum',
        fraud_proof: network.fraud_proof || false,
        sequencer: network.sequencer || 'centralized',
        verifier: network.verifier || 'ethereum',
        client: 'ethereum_foundation',
        sync_method: 'api',
        api_source: 'api.ethereum.org'
      },
      source: `ethereum_foundation_${type}`
    };
  }

  processChainlistNetwork(network, networkType) {
    return {
      name: network.name,
      chain_id: parseInt(network.chainId),
      network_type: 'L2',
      rpc_url: network.rpcUrls[0],
      explorer_url: network.explorers?.[0]?.url || null,
      native_currency: network.nativeCurrency?.symbol || 'ETH',
      block_time: this.estimateBlockTime(parseInt(network.chainId)),
      is_active: true,
      last_block_number: null,
      last_sync_time: new Date(),
      metadata: {
        rollup_type: 'unknown',
        data_availability: 'ethereum',
        fraud_proof: false,
        sequencer: 'unknown',
        verifier: 'ethereum',
        client: 'chainlist',
        sync_method: 'api',
        api_source: 'chainlist.org',
        network_type: networkType,
        slip44: network.slip44 || null,
        chain: network.chain || null
      },
      source: 'chainlist_api'
    };
  }

  getDefaultRpcUrl(chainId) {
    const rpcUrls = {
      137: 'https://polygon-rpc.com',
      42161: 'https://arb1.arbitrum.io/rpc',
      10: 'https://mainnet.optimism.io',
      8453: 'https://mainnet.base.org',
      324: 'https://mainnet.era.zksync.io',
      1101: 'https://zkevm-rpc.com',
      534352: 'https://rpc.scroll.io',
      5000: 'https://rpc.mantle.xyz',
      59144: 'https://rpc.linea.build',
      100: 'https://rpc.gnosischain.com',
      250: 'https://rpc.ftm.tools',
      43114: 'https://api.avax.network/ext/bc/C/rpc'
    };
    return rpcUrls[chainId] || null;
  }

  getDefaultExplorerUrl(chainId) {
    const explorerUrls = {
      137: 'https://polygonscan.com',
      42161: 'https://arbiscan.io',
      10: 'https://optimistic.etherscan.io',
      8453: 'https://basescan.org',
      324: 'https://explorer.zksync.io',
      1101: 'https://zkevm.polygonscan.com',
      534352: 'https://scrollscan.com',
      5000: 'https://explorer.mantle.xyz',
      59144: 'https://lineascan.build',
      100: 'https://gnosisscan.io',
      250: 'https://ftmscan.com',
      43114: 'https://snowtrace.io'
    };
    return explorerUrls[chainId] || null;
  }

  estimateBlockTime(chainId) {
    const blockTimes = {
      137: 2,      // Polygon
      42161: 1,    // Arbitrum One
      10: 2,       // Optimism
      8453: 2,     // Base
      324: 1,      // zkSync Era
      1101: 1,     // Polygon zkEVM
      534352: 1,   // Scroll
      5000: 2,     // Mantle
      59144: 2,    // Linea
      100: 5,      // Gnosis Chain
      250: 1,      // Fantom
      43114: 2,    // Avalanche C-Chain
    };
    
    return blockTimes[chainId] || 2; // Default L2 block time
  }

  async syncAllL2Networks() {
    console.log('Starting L2 network synchronization via Beacon Chain...');
    
    const networks = [];
    
    // Get networks from different sources
    const [beaconChain, ethereumFoundationL2, chainlistL2, knownL2] = await Promise.allSettled([
      this.getBeaconChainInfo(),
      this.getEthereumFoundationL2Networks(),
      this.getChainlistL2Networks(),
      this.getKnownL2Networks()
    ]);

    // Add Beacon Chain (L1) if available
    if (beaconChain.status === 'fulfilled' && beaconChain.value) {
      networks.push(beaconChain.value);
    }

    // Add Ethereum Foundation L2 networks
    if (ethereumFoundationL2.status === 'fulfilled' && ethereumFoundationL2.value.length > 0) {
      networks.push(...ethereumFoundationL2.value);
    }

    // Add Chainlist L2 networks
    if (chainlistL2.status === 'fulfilled' && chainlistL2.value.length > 0) {
      networks.push(...chainlistL2.value);
    }

    // Add known L2 networks
    if (knownL2.status === 'fulfilled' && knownL2.value.length > 0) {
      networks.push(...knownL2.value);
    }

    // Remove duplicates by chain_id
    const uniqueNetworks = [];
    const seenChainIds = new Set();
    
    networks.forEach(network => {
      if (!seenChainIds.has(network.chain_id)) {
        seenChainIds.add(network.chain_id);
        uniqueNetworks.push(network);
      }
    });

    console.log(`✓ Found ${uniqueNetworks.length} unique networks (${uniqueNetworks.filter(n => n.network_type === 'L2').length} L2 networks)`);
    return uniqueNetworks;
  }
}

export default BeaconL2Sync;
