import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

class NodeSync {
  constructor() {
    this.gethRpcUrl = process.env.GETH_RPC_URL || 'http://localhost:8545';
    this.lighthouseRpcUrl = process.env.LIGHTHOUSE_RPC_URL || 'http://localhost:5052';
    this.jwtSecretPath = process.env.GETH_JWT_SECRET_PATH || '/path/to/jwtsecret';
    this.timeout = parseInt(process.env.SYNC_TIMEOUT_MS) || 15000;
    this.retryAttempts = parseInt(process.env.SYNC_RETRY_ATTEMPTS) || 3;
    // Chainlist API endpoints
    this.chainlistApiUrl = 'https://chainlist.org/api/v1';
    this.chainlistMainnetUrl = 'https://chainlist.org/api/v1/mainnet';
    this.chainlistTestnetUrl = 'https://chainlist.org/api/v1/testnet';
  }

  async makeRequest(url, options, retryCount = 0) {
    try {
      const response = await axios({
        ...options,
        url,
        timeout: this.timeout,
        headers: {
          'Content-Type': 'application/json',
          ...options.headers
        }
      });
      return response;
    } catch (error) {
      if (retryCount < this.retryAttempts && this.isRetryableError(error)) {
        console.log(`Retry attempt ${retryCount + 1} for ${url}`);
        await this.delay(1000 * (retryCount + 1)); // Exponential backoff
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

  async getGethNetworks() {
    try {
      console.log('Fetching networks from Geth node...');
      
      // Check if JWT secret exists
      if (this.jwtSecretPath && this.jwtSecretPath !== '/path/to/jwtsecret') {
        try {
          const fs = await import('fs');
          const jwtSecret = fs.readFileSync(this.jwtSecretPath, 'utf8').trim();
          if (jwtSecret.length !== 64) {
            console.warn(`Warning: JWT secret should be 64 characters, got ${jwtSecret.length}`);
          }
        } catch (error) {
          console.warn(`Warning: Could not read JWT secret from ${this.jwtSecretPath}: ${error.message}`);
        }
      }
      
      // Get chain ID
      const chainIdResponse = await this.makeRequest(this.gethRpcUrl, {
        method: 'POST',
        data: {
          jsonrpc: '2.0',
          method: 'eth_chainId',
          params: [],
          id: 1
        }
      });

      const chainId = parseInt(chainIdResponse.data.result, 16);
      
      // Get network info
      const networkInfoResponse = await this.makeRequest(this.gethRpcUrl, {
        method: 'POST',
        data: {
          jsonrpc: '2.0',
          method: 'net_version',
          params: [],
          id: 2
        }
      });

      const networkVersion = networkInfoResponse.data.result;
      
      // Get latest block
      const latestBlockResponse = await this.makeRequest(this.gethRpcUrl, {
        method: 'POST',
        data: {
          jsonrpc: '2.0',
          method: 'eth_blockNumber',
          params: [],
          id: 3
        }
      });

      const latestBlockNumber = parseInt(latestBlockResponse.data.result, 16);

      // Get sync status
      let syncStatus = 'unknown';
      try {
        const syncResponse = await this.makeRequest(this.gethRpcUrl, {
          method: 'POST',
          data: {
            jsonrpc: '2.0',
            method: 'eth_syncing',
            params: [],
            id: 4
          }
        });
        
        if (syncResponse.data.result) {
          syncStatus = 'syncing';
        } else {
          syncStatus = 'synced';
        }
      } catch (error) {
        console.warn('Could not get sync status:', error.message);
      }

      // Determine network name based on chain ID
      let networkName = this.getNetworkNameByChainId(chainId);
      
      return {
        name: networkName,
        chain_id: chainId,
        network_type: 'L1', // Geth is typically L1
        rpc_url: this.gethRpcUrl,
        explorer_url: this.getExplorerUrl(chainId),
        native_currency: this.getNativeCurrency(chainId),
        block_time: 12, // Ethereum mainnet block time
        is_active: true,
        last_block_number: latestBlockNumber,
        last_sync_time: new Date(),
        metadata: {
          network_version: networkVersion,
          client: 'geth',
          sync_method: 'rpc',
          sync_status: syncStatus,
          jwt_secret_path: this.jwtSecretPath
        },
        source: 'geth_sync'
      };
    } catch (error) {
      console.error('Error fetching Geth networks:', error.message);
      if (error.code === 'ECONNREFUSED') {
        console.error('  → Geth node is not accessible at', this.gethRpcUrl);
        console.error('  → Check if geth is running and RPC is enabled');
      } else if (error.code === 'ETIMEDOUT') {
        console.error('  → Request to Geth node timed out');
        console.error('  → Check network connectivity and node performance');
      }
      return null;
    }
  }

  async getLighthouseNetworks() {
    try {
      console.log('Fetching networks from Lighthouse node...');
      
      // Get beacon chain info
      const beaconInfoResponse = await this.makeRequest(`${this.lighthouseRpcUrl}/eth/v1/node/info`, {
        method: 'GET'
      });

      const beaconInfo = beaconInfoResponse.data.data;
      
      // Get genesis info
      const genesisResponse = await this.makeRequest(`${this.lighthouseRpcUrl}/eth/v1/beacon/genesis`, {
        method: 'GET'
      });

      const genesis = genesisResponse.data.data;
      
      // Get sync status
      const syncStatusResponse = await this.makeRequest(`${this.lighthouseRpcUrl}/eth/v1/node/syncing`, {
        method: 'GET'
      });

      const syncStatus = syncStatusResponse.data.data;
      
      // Get latest finalized checkpoint
      const finalityResponse = await this.makeRequest(`${this.lighthouseRpcUrl}/eth/v1/beacon/states/finalized/finality_checkpoints`, {
        method: 'GET'
      });

      const finality = finalityResponse.data.data;
      
      // Get validator count
      let validatorCount = 0;
      try {
        const validatorsResponse = await this.makeRequest(`${this.lighthouseRpcUrl}/eth/v1/beacon/states/head/validators`, {
          method: 'GET'
        });
        validatorCount = validatorsResponse.data.data.length;
      } catch (error) {
        console.warn('Could not get validator count:', error.message);
      }
      
      return {
        name: 'Ethereum Beacon Chain',
        chain_id: 1, // Beacon chain is part of Ethereum mainnet
        network_type: 'L1',
        rpc_url: this.lighthouseRpcUrl,
        explorer_url: 'https://beaconcha.in',
        native_currency: 'ETH',
        block_time: 12,
        is_active: true,
        last_block_number: parseInt(finality.finalized.root, 16),
        last_sync_time: new Date(),
        metadata: {
          beacon_version: beaconInfo.version,
          genesis_time: genesis.genesis_time,
          genesis_validators_root: genesis.genesis_validators_root,
          sync_status: syncStatus,
          validator_count: validatorCount,
          client: 'lighthouse',
          sync_method: 'beacon_api'
        },
        source: 'lighthouse_sync'
      };
    } catch (error) {
      console.error('Error fetching Lighthouse networks:', error.message);
      if (error.code === 'ECONNREFUSED') {
        console.error('  → Lighthouse node is not accessible at', this.lighthouseRpcUrl);
        console.error('  → Check if lighthouse is running and API is enabled');
      } else if (error.code === 'ETIMEDOUT') {
        console.error('  → Request to Lighthouse node timed out');
        console.error('  → Check network connectivity and node performance');
      }
      return null;
    }
  }

  async getEthereumFoundationNetworks() {
    try {
      console.log('Fetching networks from Ethereum Foundation APIs...');
      
      const networks = [];
      
      // 1. Ethereum Foundation Beacon Chain API
      try {
        console.log('  → Fetching from Beacon Chain API...');
        const beaconResponse = await this.makeRequest('https://beaconcha.in/api/v1/epoch/latest', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (beaconResponse.data && beaconResponse.data.data) {
          const beaconData = beaconResponse.data.data;
          console.log(`    ✓ Beacon Chain API: Epoch ${beaconData.epoch}, Slot ${beaconData.slot}`);
          networks.push({
            name: 'Ethereum Beacon Chain',
            chain_id: 1,
            network_type: 'L1',
            rpc_url: 'https://beaconcha.in/api',
            explorer_url: 'https://beaconcha.in',
            native_currency: 'ETH',
            block_time: 12,
            is_active: true,
            last_block_number: beaconData.epoch * 32, // Convert epoch to slot
            last_sync_time: new Date(),
            metadata: {
              epoch: beaconData.epoch,
              slot: beaconData.slot,
              finality: beaconData.finality,
              client: 'ethereum_foundation',
              sync_method: 'beacon_api',
              api_source: 'beaconcha.in'
            },
            source: 'ethereum_foundation_beacon'
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Beacon Chain API:', error.message);
      }

      // 2. Ethereum Foundation Execution Layer API
      try {
        console.log('  → Fetching from Execution Layer API...');
        const executionResponse = await this.makeRequest('https://api.ethereum.org/api/v1/execution-layer', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (executionResponse.data) {
          const executionData = executionResponse.data;
          console.log(`    ✓ Execution Layer API: ${JSON.stringify(executionData).substring(0, 100)}...`);
          networks.push({
            name: 'Ethereum Mainnet',
            chain_id: 1,
            network_type: 'L1',
            rpc_url: 'https://api.ethereum.org',
            explorer_url: 'https://etherscan.io',
            native_currency: 'ETH',
            block_time: 12,
            is_active: true,
            last_block_number: executionData.latest_block || null,
            last_sync_time: new Date(),
            metadata: {
              client: 'ethereum_foundation',
              sync_method: 'execution_api',
              api_source: 'api.ethereum.org',
              execution_data: executionData
            },
            source: 'ethereum_foundation_execution'
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Execution Layer API:', error.message);
      }

      // 3. Ethereum Foundation Network Status API
      try {
        console.log('  → Fetching from Network Status API...');
        const statusResponse = await this.makeRequest('https://api.ethereum.org/api/v1/network-status', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (statusResponse.data) {
          const statusData = statusResponse.data;
          // Add network status information to existing networks
          networks.forEach(network => {
            if (network.chain_id === 1) {
              network.metadata.network_status = statusData;
            }
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Network Status API:', error.message);
      }

      // 4. Ethereum Foundation Gas Price API
      try {
        console.log('  → Fetching from Gas Price API...');
        const gasResponse = await this.makeRequest('https://api.ethereum.org/api/v1/gas-price', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (gasResponse.data) {
          const gasData = gasResponse.data;
          // Add gas price information to existing networks
          networks.forEach(network => {
            if (network.chain_id === 1) {
              network.metadata.gas_price = gasData;
            }
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Gas Price API:', error.message);
      }

      // 5. Ethereum Foundation L2 Networks API (if available)
      try {
        console.log('  → Fetching from L2 Networks API...');
        const l2Response = await this.makeRequest('https://api.ethereum.org/api/v1/l2-networks', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (l2Response.data && Array.isArray(l2Response.data)) {
          console.log(`    ✓ L2 Networks API: Found ${l2Response.data.length} L2 networks`);
          l2Response.data.forEach(l2Network => {
            console.log(`      - ${l2Network.name || `L2 Network ${l2Network.chain_id}`} (Chain ID: ${l2Network.chain_id})`);
            networks.push({
              name: l2Network.name || `L2 Network ${l2Network.chain_id}`,
              chain_id: l2Network.chain_id,
              network_type: 'L2',
              rpc_url: l2Network.rpc_url,
              explorer_url: l2Network.explorer_url,
              native_currency: l2Network.native_currency || 'ETH',
              block_time: l2Network.block_time || 2,
              is_active: true,
              last_block_number: null,
              last_sync_time: new Date(),
              metadata: {
                rollup_type: l2Network.rollup_type || 'unknown',
                data_availability: l2Network.data_availability || 'ethereum',
                fraud_proof: l2Network.fraud_proof || false,
                client: 'ethereum_foundation',
                sync_method: 'l2_api',
                api_source: 'api.ethereum.org'
              },
              source: 'ethereum_foundation_l2'
            });
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from L2 Networks API:', error.message);
      }

      console.log(`  → Successfully fetched ${networks.length} networks from Ethereum Foundation APIs`);
      if (networks.length === 0) {
        console.log('  → No networks found from Ethereum Foundation APIs');
      }
      return networks;

    } catch (error) {
      console.error('Error fetching Ethereum Foundation networks:', error.message);
      if (error.code === 'ECONNREFUSED') {
        console.error('  → Ethereum Foundation APIs are not accessible');
        console.error('  → Check internet connectivity and API availability');
      } else if (error.code === 'ETIMEDOUT') {
        console.error('  → Request to Ethereum Foundation APIs timed out');
        console.error('  → Check network connectivity');
      } else if (error.response) {
        console.error(`  → API returned status ${error.response.status}: ${error.response.statusText}`);
      }
      return [];
    }
  }

  async getEthereumFoundationL2Details() {
    try {
      console.log('Fetching detailed L2 information from Ethereum Foundation APIs...');
      
      const l2Details = [];
      
      // 1. Ethereum Foundation Bridges API
      try {
        console.log('  → Fetching from Bridges API...');
        const bridgesResponse = await this.makeRequest('https://api.ethereum.org/api/v1/bridges', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (bridgesResponse.data && Array.isArray(bridgesResponse.data)) {
          bridgesResponse.data.forEach(bridge => {
            if (bridge.destination_chain && bridge.destination_chain.chain_id) {
              l2Details.push({
                name: bridge.destination_chain.name || `Bridge to ${bridge.destination_chain.chain_id}`,
                chain_id: bridge.destination_chain.chain_id,
                network_type: 'L2',
                rpc_url: bridge.destination_chain.rpc_url,
                explorer_url: bridge.destination_chain.explorer_url,
                native_currency: bridge.destination_currency || 'ETH',
                block_time: 2,
                is_active: true,
                last_block_number: null,
                last_sync_time: new Date(),
                metadata: {
                  bridge_name: bridge.name,
                  bridge_type: bridge.type,
                  bridge_address: bridge.address,
                  bridge_abi: bridge.abi,
                  rollup_type: bridge.rollup_type || 'unknown',
                  data_availability: 'ethereum',
                  fraud_proof: bridge.fraud_proof || false,
                  client: 'ethereum_foundation',
                  sync_method: 'bridges_api',
                  api_source: 'api.ethereum.org'
                },
                source: 'ethereum_foundation_bridges'
              });
            }
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Bridges API:', error.message);
      }

      // 2. Ethereum Foundation Rollups API
      try {
        console.log('  → Fetching from Rollups API...');
        const rollupsResponse = await this.makeRequest('https://api.ethereum.org/api/v1/rollups', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (rollupsResponse.data && Array.isArray(rollupsResponse.data)) {
          rollupsResponse.data.forEach(rollup => {
            l2Details.push({
              name: rollup.name,
              chain_id: rollup.chain_id,
              network_type: 'L2',
              rpc_url: rollup.rpc_url,
              explorer_url: rollup.explorer_url,
              native_currency: rollup.native_currency || 'ETH',
              block_time: rollup.block_time || 2,
              is_active: true,
              last_block_number: null,
              last_sync_time: new Date(),
              metadata: {
                rollup_type: rollup.type,
                data_availability: rollup.data_availability || 'ethereum',
                fraud_proof: rollup.fraud_proof || false,
                sequencer: rollup.sequencer,
                verifier: rollup.verifier,
                client: 'ethereum_foundation',
                sync_method: 'rollups_api',
                api_source: 'api.ethereum.org'
              },
              source: 'ethereum_foundation_rollups'
            });
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Rollups API:', error.message);
      }

      // 3. Ethereum Foundation L2 Metrics API
      try {
        console.log('  → Fetching from L2 Metrics API...');
        const metricsResponse = await this.makeRequest('https://api.ethereum.org/api/v1/l2-metrics', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (metricsResponse.data && Array.isArray(metricsResponse.data)) {
          metricsResponse.data.forEach(metric => {
            // Update existing L2 networks with metrics
            l2Details.forEach(network => {
              if (network.chain_id === metric.chain_id) {
                network.metadata.metrics = metric;
              }
            });
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from L2 Metrics API:', error.message);
      }

      // 4. Ethereum Foundation L2 Security API
      try {
        console.log('  → Fetching from L2 Security API...');
        const securityResponse = await this.makeRequest('https://api.ethereum.org/api/v1/l2-security', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (securityResponse.data && Array.isArray(securityResponse.data)) {
          securityResponse.data.forEach(security => {
            // Update existing L2 networks with security info
            l2Details.forEach(network => {
              if (network.chain_id === security.chain_id) {
                network.metadata.security = security;
              }
            });
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from L2 Security API:', error.message);
      }

      console.log(`  → Successfully fetched detailed information for ${l2Details.length} L2 networks`);
      return l2Details;

    } catch (error) {
      console.error('Error fetching Ethereum Foundation L2 details:', error.message);
      if (error.code === 'ECONNREFUSED') {
        console.error('  → Ethereum Foundation L2 APIs are not accessible');
        console.error('  → Check internet connectivity and API availability');
      } else if (error.code === 'ETIMEDOUT') {
        console.error('  → Request to Ethereum Foundation L2 APIs timed out');
        console.error('  → Check network connectivity');
      } else if (error.response) {
        console.error(`  → API returned status ${error.response.status}: ${error.response.statusText}`);
      }
      return [];
    }
  }

  async getEthereumFoundationTestnets() {
    try {
      console.log('Fetching testnet information from Ethereum Foundation APIs...');
      
      const testnets = [];
      
      // 1. Ethereum Foundation Testnet Status API
      try {
        console.log('  → Fetching from Testnet Status API...');
        const testnetStatusResponse = await this.makeRequest('https://api.ethereum.org/api/v1/testnet-status', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (testnetStatusResponse.data && Array.isArray(testnetStatusResponse.data)) {
          testnetStatusResponse.data.forEach(testnet => {
            testnets.push({
              name: testnet.name,
              chain_id: testnet.chain_id,
              network_type: 'testnet',
              rpc_url: testnet.rpc_url,
              explorer_url: testnet.explorer_url,
              native_currency: testnet.native_currency || 'ETH',
              block_time: testnet.block_time || 12,
              is_active: testnet.status === 'active',
              last_block_number: null,
              last_sync_time: new Date(),
              metadata: {
                testnet_type: testnet.type,
                status: testnet.status,
                launch_date: testnet.launch_date,
                end_date: testnet.end_date,
                faucet_url: testnet.faucet_url,
                client: 'ethereum_foundation',
                sync_method: 'testnet_status_api',
                api_source: 'api.ethereum.org'
              },
              source: 'ethereum_foundation_testnet'
            });
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Testnet Status API:', error.message);
      }

      // 2. Ethereum Foundation Devnet API
      try {
        console.log('  → Fetching from Devnet API...');
        const devnetResponse = await this.makeRequest('https://api.ethereum.org/api/v1/devnet', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (devnetResponse.data && Array.isArray(devnetResponse.data)) {
          devnetResponse.data.forEach(devnet => {
            testnets.push({
              name: devnet.name,
              chain_id: devnet.chain_id,
              network_type: 'devnet',
              rpc_url: devnet.rpc_url,
              explorer_url: devnet.explorer_url,
              native_currency: devnet.native_currency || 'ETH',
              block_time: devnet.block_time || 12,
              is_active: devnet.status === 'active',
              last_block_number: null,
              last_sync_time: new Date(),
              metadata: {
                devnet_type: devnet.type,
                status: devnet.status,
                purpose: devnet.purpose,
                features: devnet.features || [],
                client: 'ethereum_foundation',
                sync_method: 'devnet_api',
                api_source: 'api.ethereum.org'
              },
              source: 'ethereum_foundation_devnet'
            });
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Devnet API:', error.message);
      }

      // 3. Ethereum Foundation Staking Testnet API
      try {
        console.log('  → Fetching from Staking Testnet API...');
        const stakingTestnetResponse = await this.makeRequest('https://api.ethereum.org/api/v1/staking-testnet', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (stakingTestnetResponse.data && Array.isArray(stakingTestnetResponse.data)) {
          stakingTestnetResponse.data.forEach(stakingTestnet => {
            testnets.push({
              name: stakingTestnet.name,
              chain_id: stakingTestnet.chain_id,
              network_type: 'staking_testnet',
              rpc_url: stakingTestnet.rpc_url,
              explorer_url: stakingTestnet.explorer_url,
              native_currency: stakingTestnet.native_currency || 'ETH',
              block_time: stakingTestnet.block_time || 12,
              is_active: stakingTestnet.status === 'active',
              last_block_number: null,
              last_sync_time: new Date(),
              metadata: {
                staking_type: stakingTestnet.type,
                status: stakingTestnet.status,
                validator_count: stakingTestnet.validator_count,
                min_stake: stakingTestnet.min_stake,
                client: 'ethereum_foundation',
                sync_method: 'staking_testnet_api',
                api_source: 'api.ethereum.org'
              },
              source: 'ethereum_foundation_staking_testnet'
            });
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Staking Testnet API:', error.message);
      }

      console.log(`  → Successfully fetched ${testnets.length} testnets from Ethereum Foundation APIs`);
      return testnets;

    } catch (error) {
      console.error('Error fetching Ethereum Foundation testnets:', error.message);
      if (error.code === 'ECONNREFUSED') {
        console.error('  → Ethereum Foundation testnet APIs are not accessible');
        console.error('  → Check internet connectivity and API availability');
      } else if (error.code === 'ETIMEDOUT') {
        console.error('  → Request to Ethereum Foundation testnet APIs timed out');
        console.error('  → Check network connectivity');
      } else if (error.response) {
        console.error(`  → API returned status ${error.response.status}: ${error.response.statusText}`);
      }
      return [];
    }
  }

  async getEthereumFoundationForks() {
    try {
      console.log('Fetching fork information from Ethereum Foundation APIs...');
      
      const forks = [];
      
      // 1. Ethereum Foundation Fork Status API
      try {
        console.log('  → Fetching from Fork Status API...');
        const forkStatusResponse = await this.makeRequest('https://api.ethereum.org/api/v1/fork-status', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (forkStatusResponse.data && Array.isArray(forkStatusResponse.data)) {
          forkStatusResponse.data.forEach(fork => {
            forks.push({
              name: fork.name,
              chain_id: fork.chain_id,
              network_type: 'fork',
              rpc_url: fork.rpc_url,
              explorer_url: fork.explorer_url,
              native_currency: fork.native_currency || 'ETH',
              block_time: fork.block_time || 12,
              is_active: fork.status === 'active',
              last_block_number: null,
              last_sync_time: new Date(),
              metadata: {
                fork_type: fork.type,
                status: fork.status,
                fork_block: fork.fork_block,
                fork_hash: fork.fork_hash,
                parent_chain: fork.parent_chain,
                client: 'ethereum_foundation',
                sync_method: 'fork_status_api',
                api_source: 'api.ethereum.org'
              },
              source: 'ethereum_foundation_fork'
            });
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Fork Status API:', error.message);
      }

      // 2. Ethereum Foundation Compatible Networks API
      try {
        console.log('  → Fetching from Compatible Networks API...');
        const compatibleNetworksResponse = await this.makeRequest('https://api.ethereum.org/api/v1/compatible-networks', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (compatibleNetworksResponse.data && Array.isArray(compatibleNetworksResponse.data)) {
          compatibleNetworksResponse.data.forEach(compatibleNetwork => {
            forks.push({
              name: compatibleNetwork.name,
              chain_id: compatibleNetwork.chain_id,
              network_type: 'compatible',
              rpc_url: compatibleNetwork.rpc_url,
              explorer_url: compatibleNetwork.explorer_url,
              native_currency: compatibleNetwork.native_currency || 'ETH',
              block_time: compatibleNetwork.block_time || 12,
              is_active: compatibleNetwork.status === 'active',
              last_block_number: null,
              last_sync_time: new Date(),
              metadata: {
                compatibility_level: compatibleNetwork.compatibility_level,
                evm_version: compatibleNetwork.evm_version,
                supported_eips: compatibleNetwork.supported_eips || [],
                status: compatibleNetwork.status,
                client: 'ethereum_foundation',
                sync_method: 'compatible_networks_api',
                api_source: 'api.ethereum.org'
              },
              source: 'ethereum_foundation_compatible'
            });
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Compatible Networks API:', error.message);
      }

      // 3. Ethereum Foundation Network Upgrades API
      try {
        console.log('  → Fetching from Network Upgrades API...');
        const networkUpgradesResponse = await this.makeRequest('https://api.ethereum.org/api/v1/network-upgrades', {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Defimon-L2-Sync/1.0.0'
          }
        });

        if (networkUpgradesResponse.data && Array.isArray(networkUpgradesResponse.data)) {
          networkUpgradesResponse.data.forEach(upgrade => {
            // Add upgrade information to existing networks
            forks.forEach(network => {
              if (network.chain_id === upgrade.chain_id) {
                network.metadata.upgrades = network.metadata.upgrades || [];
                network.metadata.upgrades.push(upgrade);
              }
            });
          });
        }
      } catch (error) {
        console.warn('  → Could not fetch from Network Upgrades API:', error.message);
      }

      console.log(`  → Successfully fetched ${forks.length} forks and compatible networks from Ethereum Foundation APIs`);
      return forks;

    } catch (error) {
      console.error('Error fetching Ethereum Foundation forks:', error.message);
      if (error.code === 'ECONNREFUSED') {
        console.error('  → Ethereum Foundation fork APIs are not accessible');
        console.error('  → Check internet connectivity and API availability');
      } else if (error.code === 'ETIMEDOUT') {
        console.error('  → Request to Ethereum Foundation fork APIs timed out');
        console.error('  → Check network connectivity');
      } else if (error.response) {
        console.error(`  → API returned status ${error.response.status}: ${error.response.statusText}`);
      }
      return [];
    }
  }

  async getKnownL2Networks() {
    // Predefined list of known L2 networks
    const knownNetworks = [
      {
        name: 'Arbitrum One',
        chain_id: 42161,
        network_type: 'L2',
        rpc_url: 'https://arb1.arbitrum.io/rpc',
        explorer_url: 'https://arbiscan.io',
        native_currency: 'ETH',
        block_time: 1,
        is_active: true,
        metadata: {
          rollup_type: 'optimistic',
          data_availability: 'ethereum',
          fraud_proof: true
        },
        source: 'known_networks'
      },
      {
        name: 'Optimism',
        chain_id: 10,
        network_type: 'L2',
        rpc_url: 'https://mainnet.optimism.io',
        explorer_url: 'https://optimistic.etherscan.io',
        native_currency: 'ETH',
        block_time: 2,
        is_active: true,
        metadata: {
          rollup_type: 'optimistic',
          data_availability: 'ethereum',
          fraud_proof: true
        },
        source: 'known_networks'
      },
      {
        name: 'Polygon zkEVM',
        chain_id: 1101,
        network_type: 'L2',
        rpc_url: 'https://zkevm-rpc.com',
        explorer_url: 'https://zkevm.polygonscan.com',
        native_currency: 'ETH',
        block_time: 1,
        is_active: true,
        metadata: {
          rollup_type: 'zk',
          data_availability: 'ethereum',
          fraud_proof: false
        },
        source: 'known_networks'
      },
      {
        name: 'Base',
        chain_id: 8453,
        network_type: 'L2',
        rpc_url: 'https://mainnet.base.org',
        explorer_url: 'https://basescan.org',
        native_currency: 'ETH',
        block_time: 2,
        is_active: true,
        metadata: {
          rollup_type: 'optimistic',
          data_availability: 'ethereum',
          fraud_proof: true
        },
        source: 'known_networks'
      },
      {
        name: 'zkSync Era',
        chain_id: 324,
        network_type: 'L2',
        rpc_url: 'https://mainnet.era.zksync.io',
        explorer_url: 'https://explorer.zksync.io',
        native_currency: 'ETH',
        block_time: 1,
        is_active: true,
        metadata: {
          rollup_type: 'zk',
          data_availability: 'ethereum',
          fraud_proof: false
        },
        source: 'known_networks'
      },
      {
        name: 'Scroll',
        chain_id: 534352,
        network_type: 'L2',
        rpc_url: 'https://rpc.scroll.io',
        explorer_url: 'https://scrollscan.com',
        native_currency: 'ETH',
        block_time: 1,
        is_active: true,
        metadata: {
          rollup_type: 'zk',
          data_availability: 'ethereum',
          fraud_proof: false
        },
        source: 'known_networks'
      },
      {
        name: 'Mantle',
        chain_id: 5000,
        network_type: 'L2',
        rpc_url: 'https://rpc.mantle.xyz',
        explorer_url: 'https://explorer.mantle.xyz',
        native_currency: 'MNT',
        block_time: 2,
        is_active: true,
        metadata: {
          rollup_type: 'optimistic',
          data_availability: 'ethereum',
          fraud_proof: true
        },
        source: 'known_networks'
      },
      {
        name: 'Linea',
        chain_id: 59144,
        network_type: 'L2',
        rpc_url: 'https://rpc.linea.build',
        explorer_url: 'https://lineascan.build',
        native_currency: 'ETH',
        block_time: 2,
        is_active: true,
        metadata: {
          rollup_type: 'zk',
          data_availability: 'ethereum',
          fraud_proof: false
        },
        source: 'known_networks'
      }
    ];

    return knownNetworks;
  }

  getNetworkNameByChainId(chainId) {
    const networkNames = {
      1: 'Ethereum Mainnet',
      5: 'Goerli Testnet',
      11155111: 'Sepolia Testnet',
      137: 'Polygon',
      56: 'Binance Smart Chain',
      42161: 'Arbitrum One',
      10: 'Optimism',
      8453: 'Base',
      324: 'zkSync Era',
      1101: 'Polygon zkEVM',
      534352: 'Scroll',
      5000: 'Mantle',
      59144: 'Linea'
    };
    
    return networkNames[chainId] || `Unknown Network (${chainId})`;
  }

  getExplorerUrl(chainId) {
    const explorers = {
      1: 'https://etherscan.io',
      5: 'https://goerli.etherscan.io',
      11155111: 'https://sepolia.etherscan.io',
      137: 'https://polygonscan.com',
      56: 'https://bscscan.com',
      42161: 'https://arbiscan.io',
      10: 'https://optimistic.etherscan.io',
      8453: 'https://basescan.org',
      324: 'https://explorer.zksync.io',
      1101: 'https://zkevm.polygonscan.com',
      534352: 'https://scrollscan.com',
      5000: 'https://explorer.mantle.xyz',
      59144: 'https://lineascan.build'
    };
    
    return explorers[chainId] || null;
  }

  getNativeCurrency(chainId) {
    const currencies = {
      1: 'ETH',
      5: 'ETH',
      11155111: 'ETH',
      137: 'MATIC',
      56: 'BNB',
      42161: 'ETH',
      10: 'ETH',
      8453: 'ETH',
      324: 'ETH',
      1101: 'ETH',
      534352: 'ETH',
      5000: 'MNT',
      59144: 'ETH'
    };
    
    return currencies[chainId] || 'ETH';
  }

  async getChainlistNetworks() {
    try {
      console.log('Fetching networks from Ethereum Foundation Chainlist API...');
      
      // Get mainnet networks
      const mainnetResponse = await this.makeRequest(this.chainlistMainnetUrl, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Defimon-L2-Sync/1.0.0'
        }
      });

      // Get testnet networks
      const testnetResponse = await this.makeRequest(this.chainlistTestnetUrl, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Defimon-L2-Sync/1.0.0'
        }
      });

      const mainnetNetworks = mainnetResponse.data || [];
      const testnetNetworks = testnetResponse.data || [];
      
      console.log(`Found ${mainnetNetworks.length} mainnet networks and ${testnetNetworks.length} testnet networks from Chainlist API`);

      // Process and filter networks
      const processedNetworks = [];
      
      // Process mainnet networks
      mainnetNetworks.forEach(network => {
        if (this.isValidL2Network(network)) {
          processedNetworks.push(this.processChainlistNetwork(network, 'mainnet'));
        }
      });

      // Process testnet networks
      testnetNetworks.forEach(network => {
        if (this.isValidL2Network(network)) {
          processedNetworks.push(this.processChainlistNetwork(network, 'testnet'));
        }
      });

      console.log(`Processed ${processedNetworks.length} valid L2 networks from Chainlist API`);
      return processedNetworks;

    } catch (error) {
      console.error('Error fetching Chainlist networks:', error.message);
      if (error.code === 'ECONNREFUSED') {
        console.error('  → Chainlist API is not accessible');
        console.error('  → Check internet connectivity and API availability');
      } else if (error.code === 'ETIMEDOUT') {
        console.error('  → Request to Chainlist API timed out');
        console.error('  → Check network connectivity');
      } else if (error.response) {
        console.error(`  → API returned status ${error.response.status}: ${error.response.statusText}`);
      }
      return [];
    }
  }

  isValidL2Network(network) {
    // Filter for L2 networks and important Ethereum-compatible networks
    if (!network || !network.chainId || !network.name) {
      return false;
    }

    // Include L2 networks, sidechains, and important EVM networks
    const importantChainIds = [
      // L2 Rollups
      42161, // Arbitrum One
      10,    // Optimism
      1101,  // Polygon zkEVM
      8453,  // Base
      324,   // zkSync Era
      534352, // Scroll
      5000,  // Mantle
      59144, // Linea
      137,   // Polygon
      56,    // BSC
      250,   // Fantom
      43114, // Avalanche C-Chain
      100,   // Gnosis Chain
      1,     // Ethereum Mainnet
      
      // Testnets
      5,     // Goerli
      11155111, // Sepolia
      80001, // Mumbai
      97,    // BSC Testnet
      43113, // Fuji
      137,   // Polygon
    ];

    // Check if it's an important network or has L2 characteristics
    return importantChainIds.includes(parseInt(network.chainId)) ||
           network.name.toLowerCase().includes('rollup') ||
           network.name.toLowerCase().includes('layer 2') ||
           network.name.toLowerCase().includes('l2') ||
           network.name.toLowerCase().includes('optimistic') ||
           network.name.toLowerCase().includes('zk') ||
           network.name.toLowerCase().includes('polygon') ||
           network.name.toLowerCase().includes('arbitrum') ||
           network.name.toLowerCase().includes('optimism') ||
           network.name.toLowerCase().includes('base') ||
           network.name.toLowerCase().includes('scroll') ||
           network.name.toLowerCase().includes('mantle') ||
           network.name.toLowerCase().includes('linea');
  }

  processChainlistNetwork(network, networkType) {
    const chainId = parseInt(network.chainId);
    
    // Determine network type
    let networkTypeCategory = 'L1';
    if (network.name.toLowerCase().includes('rollup') ||
        network.name.toLowerCase().includes('layer 2') ||
        network.name.toLowerCase().includes('l2') ||
        network.name.toLowerCase().includes('optimistic') ||
        network.name.toLowerCase().includes('zk')) {
      networkTypeCategory = 'L2';
    }

    // Determine rollup type
    let rollupType = 'unknown';
    if (network.name.toLowerCase().includes('optimistic') || 
        network.name.toLowerCase().includes('arbitrum') ||
        network.name.toLowerCase().includes('optimism') ||
        network.name.toLowerCase().includes('base')) {
      rollupType = 'optimistic';
    } else if (network.name.toLowerCase().includes('zk') ||
               network.name.toLowerCase().includes('scroll') ||
               network.name.toLowerCase().includes('linea') ||
               network.name.toLowerCase().includes('polygon zk')) {
      rollupType = 'zk';
    }

    // Get native currency
    let nativeCurrency = 'ETH';
    if (network.nativeCurrency && network.nativeCurrency.symbol) {
      nativeCurrency = network.nativeCurrency.symbol;
    } else if (chainId === 137) {
      nativeCurrency = 'MATIC';
    } else if (chainId === 56) {
      nativeCurrency = 'BNB';
    } else if (chainId === 5000) {
      nativeCurrency = 'MNT';
    }

    // Get RPC URL
    let rpcUrl = null;
    if (network.rpc && network.rpc.length > 0) {
      // Prefer HTTPS URLs and public RPCs
      const httpsRpc = network.rpc.find(url => url.startsWith('https://'));
      const publicRpc = network.rpc.find(url => 
        url.includes('public') || 
        url.includes('rpc') || 
        url.includes('mainnet') ||
        url.includes('api')
      );
      rpcUrl = httpsRpc || publicRpc || network.rpc[0];
    }

    // Get explorer URL
    let explorerUrl = null;
    if (network.explorers && network.explorers.length > 0) {
      explorerUrl = network.explorers[0].url;
    }

    return {
      name: network.name,
      chain_id: chainId,
      network_type: networkTypeCategory,
      rpc_url: rpcUrl,
      explorer_url: explorerUrl,
      native_currency: nativeCurrency,
      block_time: network.blockTime || this.estimateBlockTime(chainId),
      is_active: true,
      last_block_number: null, // Will be updated by sync process
      last_sync_time: new Date(),
      metadata: {
        network_type: networkType,
        rollup_type: rollupType,
        data_availability: networkTypeCategory === 'L2' ? 'ethereum' : 'local',
        fraud_proof: rollupType === 'optimistic',
        chainlist_id: network.id || null,
        short_name: network.shortName || null,
        title: network.title || null,
        status: network.status || 'active',
        parent: network.parent || null,
        icon: network.icon || null,
        color: network.color || null,
        info_url: network.infoURL || null,
        faucets: network.faucets || [],
        ens: network.ens || null,
        features: network.features || [],
        red_flags: network.redFlags || [],
        slip44: network.slip44 || null,
        chain: network.chain || null
      },
      source: 'chainlist_api'
    };
  }

  estimateBlockTime(chainId) {
    // Estimate block time based on known networks
    const blockTimes = {
      1: 12,      // Ethereum Mainnet
      137: 2,     // Polygon
      56: 3,      // BSC
      42161: 1,   // Arbitrum One
      10: 2,      // Optimism
      8453: 2,    // Base
      324: 1,     // zkSync Era
      1101: 1,    // Polygon zkEVM
      534352: 1,  // Scroll
      5000: 2,    // Mantle
      59144: 2,   // Linea
      100: 5,     // Gnosis Chain
      250: 1,     // Fantom
      43114: 2,   // Avalanche C-Chain
    };
    
    return blockTimes[chainId] || 12; // Default to Ethereum mainnet block time
  }

  async syncAllNetworks() {
    console.log('Starting network synchronization...');
    
    const networks = [];
    
    // Get networks from different sources
    const [gethNetwork, lighthouseNetwork, ethereumFoundationNetworks, ethereumFoundationL2Details, ethereumFoundationTestnets, ethereumFoundationForks, knownNetworks, chainlistNetworks] = await Promise.allSettled([
      this.getGethNetworks(),
      this.getLighthouseNetworks(),
      this.getEthereumFoundationNetworks(),
      this.getEthereumFoundationL2Details(),
      this.getEthereumFoundationTestnets(),
      this.getEthereumFoundationForks(),
      this.getKnownL2Networks(),
      this.getChainlistNetworks()
    ]);

    if (gethNetwork.status === 'fulfilled' && gethNetwork.value) {
      networks.push(gethNetwork.value);
    }

    if (lighthouseNetwork.status === 'fulfilled' && lighthouseNetwork.value) {
      networks.push(lighthouseNetwork.value);
    }

    if (ethereumFoundationNetworks.status === 'fulfilled' && ethereumFoundationNetworks.value.length > 0) {
      // Merge with existing networks, avoiding duplicates by chain_id
      const existingChainIds = new Set(networks.map(n => n.chain_id));
      const uniqueEthereumFoundationNetworks = ethereumFoundationNetworks.value.filter(n => !existingChainIds.has(n.chain_id));
      networks.push(...uniqueEthereumFoundationNetworks);
    }

    if (ethereumFoundationL2Details.status === 'fulfilled' && ethereumFoundationL2Details.value.length > 0) {
      // Merge L2 details with existing networks, avoiding duplicates by chain_id
      const existingChainIds = new Set(networks.map(n => n.chain_id));
      const uniqueL2Details = ethereumFoundationL2Details.value.filter(n => !existingChainIds.has(n.chain_id));
      networks.push(...uniqueL2Details);
    }

    if (ethereumFoundationTestnets.status === 'fulfilled' && ethereumFoundationTestnets.value.length > 0) {
      // Merge testnets with existing networks, avoiding duplicates by chain_id
      const existingChainIds = new Set(networks.map(n => n.chain_id));
      const uniqueTestnets = ethereumFoundationTestnets.value.filter(n => !existingChainIds.has(n.chain_id));
      networks.push(...uniqueTestnets);
    }

    if (ethereumFoundationForks.status === 'fulfilled' && ethereumFoundationForks.value.length > 0) {
      // Merge forks with existing networks, avoiding duplicates by chain_id
      const existingChainIds = new Set(networks.map(n => n.chain_id));
      const uniqueForks = ethereumFoundationForks.value.filter(n => !existingChainIds.has(n.chain_id));
      networks.push(...uniqueForks);
    }

    if (knownNetworks.status === 'fulfilled') {
      networks.push(...knownNetworks.value);
    }

    if (chainlistNetworks.status === 'fulfilled' && chainlistNetworks.value.length > 0) {
      // Merge with known networks, avoiding duplicates by chain_id
      const existingChainIds = new Set(networks.map(n => n.chain_id));
      const uniqueChainlistNetworks = chainlistNetworks.value.filter(n => !existingChainIds.has(n.chain_id));
      networks.push(...uniqueChainlistNetworks);
    }

    console.log(`Found ${networks.length} networks to sync`);
    return networks;
  }
}

export default NodeSync;
