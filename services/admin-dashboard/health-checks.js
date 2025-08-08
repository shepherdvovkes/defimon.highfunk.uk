const axios = require('axios');

// Database health check functions
async function checkPostgreSQL() {
  try {
    // Try to connect to PostgreSQL using a simple query
    const response = await axios.get('http://postgres-exporter:9187/metrics', {
      timeout: 5000
    });
    return {
      name: 'postgres',
      status: 'healthy',
      responseTime: 'N/A',
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    return {
      name: 'postgres',
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}

async function checkClickHouse() {
  try {
    const response = await axios.get('http://clickhouse:8123/ping', {
      timeout: 5000
    });
    return {
      name: 'clickhouse',
      status: 'healthy',
      responseTime: 'N/A',
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    return {
      name: 'clickhouse',
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}

async function checkRedis() {
  try {
    const response = await axios.get('http://redis-exporter:9121/metrics', {
      timeout: 5000
    });
    return {
      name: 'redis',
      status: 'healthy',
      responseTime: 'N/A',
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    return {
      name: 'redis',
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}

async function checkKafka() {
  try {
    // Kafka doesn't have a direct HTTP health endpoint
    // We'll check if the exporter is running
    const response = await axios.get('http://kafka:9092', {
      timeout: 5000
    });
    return {
      name: 'kafka',
      status: 'healthy',
      responseTime: 'N/A',
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    return {
      name: 'kafka',
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}

async function checkBlockchainNode() {
  try {
    // Check if the blockchain node is responding to RPC calls
    const response = await axios.post('http://blockchain-node:8545', {
      jsonrpc: '2.0',
      method: 'eth_blockNumber',
      params: [],
      id: 1
    }, {
      timeout: 5000,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    return {
      name: 'blockchain-node',
      status: 'healthy',
      responseTime: 'N/A',
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    return {
      name: 'blockchain-node',
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = {
  checkPostgreSQL,
  checkClickHouse,
  checkRedis,
  checkKafka,
  checkBlockchainNode
};
