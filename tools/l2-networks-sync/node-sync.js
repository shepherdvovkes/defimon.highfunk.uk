import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

class NodeSync {
  constructor() {
    this.gethRpcUrl = process.env.GETH_RPC_URL || 'http://localhost:8545';
    this.lighthouseRpcUrl = process.env.LIGHTHOUSE_RPC_URL || 'http://localhost:5052';
    this.jwtSecretPath = process.env.GETH_JWT_SECRET_PATH || '/path/to/jwtsecret';
  }

  async getGethNetworks() {
    try {
      console.log('Fetching networks from Geth node...');
      
      // Get chain ID
      const chainIdResponse = await axios.post(this.gethRpcUrl, {
        jsonrpc: '2.0',
        method: 'eth_chainId',
        params: [],
        id: 1
      }, {
        headers: { 'Content-Type': 'application/json' },
        timeout: 10000
      });

      const chainId = parseInt(chainIdResponse.data.result, 16);
      
      // Get network info
      const networkInfoResponse = await axios.post(this.gethRpcUrl, {
        jsonrpc: '2.0',
        method: 'net_version',
        params: [],
        id: 2
      }, {
        headers: { 'Content-Type': 'application/json' },
        timeout: 10000
      });

      const networkVersion = networkInfoResponse.data.result;
      
      // Get latest block
      const latestBlockResponse = await axios.post(this.gethRpcUrl, {
        jsonrpc: '2.0',
        method: 'eth_blockNumber',
        params: [],
        id: 3
      }, {
        headers: { 'Content-Type': 'application/json' },
        timeout: 10000
      });

      const latestBlockNumber = parseInt(latestBlockResponse.data.result, 16);

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
          sync_method: 'rpc'
        },
        source: 'geth_sync'
      };
    } catch (error) {
      console.error('Error fetching Geth networks:', error.message);
      return null;
    }
  }

  async getLighthouseNetworks() {
    try {
      console.log('Fetching networks from Lighthouse node...');
      
      // Get beacon chain info
      const beaconInfoResponse = await axios.get(`${this.lighthouseRpcUrl}/eth/v1/node/info`, {
        timeout: 10000
      });

      const beaconInfo = beaconInfoResponse.data.data;
      
      // Get genesis info
      const genesisResponse = await axios.get(`${this.lighthouseRpcUrl}/eth/v1/beacon/genesis`, {
        timeout: 10000
      });

      const genesis = genesisResponse.data.data;
      
      // Get sync status
      const syncStatusResponse = await axios.get(`${this.lighthouseRpcUrl}/eth/v1/node/syncing`, {
        timeout: 10000
      });

      const syncStatus = syncStatusResponse.data.data;
      
      // Get latest finalized checkpoint
      const finalityResponse = await axios.get(`${this.lighthouseRpcUrl}/eth/v1/beacon/states/finalized/finality_checkpoints`, {
        timeout: 10000
      });

      const finality = finalityResponse.data.data;
      
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
          client: 'lighthouse',
          sync_method: 'beacon_api'
        },
        source: 'lighthouse_sync'
      };
    } catch (error) {
      console.error('Error fetching Lighthouse networks:', error.message);
      return null;
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

  async syncAllNetworks() {
    console.log('Starting network synchronization...');
    
    const networks = [];
    
    // Get networks from different sources
    const [gethNetwork, lighthouseNetwork, knownNetworks] = await Promise.allSettled([
      this.getGethNetworks(),
      this.getLighthouseNetworks(),
      this.getKnownL2Networks()
    ]);

    if (gethNetwork.status === 'fulfilled' && gethNetwork.value) {
      networks.push(gethNetwork.value);
    }

    if (lighthouseNetwork.status === 'fulfilled' && lighthouseNetwork.value) {
      networks.push(lighthouseNetwork.value);
    }

    if (knownNetworks.status === 'fulfilled') {
      networks.push(...knownNetworks.value);
    }

    console.log(`Found ${networks.length} networks to sync`);
    return networks;
  }
}

export default NodeSync;
