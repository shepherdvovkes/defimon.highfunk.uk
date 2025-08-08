const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const axios = require('axios');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Import database health checks
const { 
  checkPostgreSQL, 
  checkClickHouse, 
  checkRedis, 
  checkKafka, 
  checkBlockchainNode 
} = require('./health-checks');

// Service configurations
const services = {
  'api-gateway': { port: 8001, health: '/status' },
  'analytics-api': { port: 8002, health: '/health' },
  'ai-ml-service': { port: 8001, health: '/health' },
  'prometheus': { port: 9090, health: '/-/healthy' },
  'grafana': { port: 3001, health: '/api/health' }
};

// Health check function
async function checkServiceHealth(serviceName, config) {
  try {
    const response = await axios.get(`http://${serviceName}:${config.port}${config.health}`, {
      timeout: 5000
    });
    return {
      name: serviceName,
      status: 'healthy',
      responseTime: response.headers['x-response-time'] || 'N/A',
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    return {
      name: serviceName,
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}

// Check all services health
async function checkAllServices() {
  const results = [];
  
  // Check regular services
  for (const [serviceName, config] of Object.entries(services)) {
    const health = await checkServiceHealth(serviceName, config);
    results.push(health);
  }
  
  // Check database services with special handlers
  const dbChecks = [
    checkPostgreSQL(),
    checkClickHouse(),
    checkRedis(),
    checkKafka(),
    checkBlockchainNode()
  ];
  
  const dbResults = await Promise.all(dbChecks);
  results.push(...dbResults);
  
  return results;
}

// API Routes
app.get('/api/health', async (req, res) => {
  try {
    const healthData = await checkAllServices();
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      services: healthData
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

app.get('/api/services', (req, res) => {
  res.json({
    services: Object.keys(services).map(name => ({
      name,
      config: services[name]
    }))
  });
});

app.get('/api/metrics', async (req, res) => {
  try {
    // Get Prometheus metrics
    const prometheusResponse = await axios.get('http://prometheus:9090/api/v1/query?query=up');
    const metrics = prometheusResponse.data;
    
    res.json({
      timestamp: new Date().toISOString(),
      metrics: metrics.data?.result || []
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// WebSocket connection for real-time updates
io.on('connection', (socket) => {
  console.log('Admin client connected');
  
  // Send initial health data
  checkAllServices().then(healthData => {
    socket.emit('health-update', healthData);
  });
  
  // Periodic health checks
  const healthInterval = setInterval(async () => {
    const healthData = await checkAllServices();
    socket.emit('health-update', healthData);
  }, 10000); // Every 10 seconds
  
  socket.on('disconnect', () => {
    console.log('Admin client disconnected');
    clearInterval(healthInterval);
  });
  
  socket.on('request-health', async () => {
    const healthData = await checkAllServices();
    socket.emit('health-update', healthData);
  });
});

// Serve the main dashboard
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`Admin dashboard running on port ${PORT}`);
});
