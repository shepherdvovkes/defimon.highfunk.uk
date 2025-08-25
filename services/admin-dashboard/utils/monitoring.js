const promClient = require('prom-client');
const logger = require('./logger');

// Create a Registry to register the metrics
const register = new promClient.Registry();

// Add default metrics (CPU, memory, etc.)
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDurationMicroseconds = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5, 10],
  registers: [register],
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

const activeConnections = new promClient.Gauge({
  name: 'websocket_active_connections',
  help: 'Number of active WebSocket connections',
  registers: [register],
});

const serviceHealthStatus = new promClient.Gauge({
  name: 'service_health_status',
  help: 'Health status of monitored services (1 = healthy, 0 = unhealthy)',
  labelNames: ['service_name'],
  registers: [register],
});

const databaseQueryDuration = new promClient.Histogram({
  name: 'database_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['operation', 'table'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5],
  registers: [register],
});

const cacheHitRatio = new promClient.Gauge({
  name: 'cache_hit_ratio',
  help: 'Cache hit ratio (0-1)',
  labelNames: ['cache_type'],
  registers: [register],
});

const alertCount = new promClient.Counter({
  name: 'alerts_total',
  help: 'Total number of alerts generated',
  labelNames: ['level', 'service'],
  registers: [register],
});

const pushNotificationSent = new promClient.Counter({
  name: 'push_notifications_sent_total',
  help: 'Total number of push notifications sent',
  labelNames: ['status'],
  registers: [register],
});

const backupStatus = new promClient.Gauge({
  name: 'backup_status',
  help: 'Status of database backups (1 = successful, 0 = failed)',
  labelNames: ['backup_type'],
  registers: [register],
});

const sslCertificateExpiry = new promClient.Gauge({
  name: 'ssl_certificate_expiry_days',
  help: 'Days until SSL certificate expires',
  registers: [register],
});

// Performance monitoring
const performanceMetrics = {
  startTimer: (operation) => {
    const start = process.hrtime.bigint();
    return {
      end: () => {
        const end = process.hrtime.bigint();
        const duration = Number(end - start) / 1000000; // Convert to milliseconds
        logger.performance(operation, duration);
        return duration;
      }
    };
  },

  recordHttpRequest: (req, res, duration) => {
    const route = req.route?.path || req.path || 'unknown';
    const method = req.method;
    const statusCode = res.statusCode;

    httpRequestDurationMicroseconds
      .labels(method, route, statusCode.toString())
      .observe(duration / 1000); // Convert to seconds

    httpRequestTotal
      .labels(method, route, statusCode.toString())
      .inc();

    logger.access(req, res, duration);
  },

  recordDatabaseQuery: (operation, table, duration) => {
    databaseQueryDuration
      .labels(operation, table)
      .observe(duration / 1000); // Convert to seconds
  },

  recordCacheHit: (cacheType, hit) => {
    // This is a simplified version - in a real implementation you'd track hits/misses over time
    const ratio = hit ? 1 : 0;
    cacheHitRatio.labels(cacheType).set(ratio);
  },

  recordServiceHealth: (serviceName, isHealthy) => {
    serviceHealthStatus
      .labels(serviceName)
      .set(isHealthy ? 1 : 0);
  },

  recordWebSocketConnection: (count) => {
    activeConnections.set(count);
  },

  recordAlert: (level, service) => {
    alertCount.labels(level, service).inc();
  },

  recordPushNotification: (status) => {
    pushNotificationSent.labels(status).inc();
  },

  recordBackupStatus: (backupType, success) => {
    backupStatus.labels(backupType).set(success ? 1 : 0);
  },

  recordSSLCertificateExpiry: (daysUntilExpiry) => {
    sslCertificateExpiry.set(daysUntilExpiry);
  }
};

// Health check monitoring
const healthCheckMetrics = {
  services: new Map(),
  
  updateServiceHealth: (serviceName, healthData) => {
    const isHealthy = healthData.status === 'healthy';
    performanceMetrics.recordServiceHealth(serviceName, isHealthy);
    
    healthCheckMetrics.services.set(serviceName, {
      ...healthData,
      lastCheck: new Date(),
      isHealthy
    });

    logger.monitoring(serviceName, healthData.status, healthData);
  },

  getServiceHealth: (serviceName) => {
    return healthCheckMetrics.services.get(serviceName);
  },

  getAllServicesHealth: () => {
    return Array.from(healthCheckMetrics.services.entries()).map(([name, data]) => ({
      name,
      ...data
    }));
  },

  getHealthSummary: () => {
    const services = Array.from(healthCheckMetrics.services.values());
    const healthy = services.filter(s => s.isHealthy).length;
    const total = services.length;
    
    return {
      total,
      healthy,
      unhealthy: total - healthy,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      cpu: process.cpuUsage()
    };
  }
};

// System metrics monitoring
const systemMetrics = {
  getSystemInfo: () => {
    const os = require('os');
    return {
      platform: os.platform(),
      arch: os.arch(),
      nodeVersion: process.version,
      uptime: os.uptime(),
      totalMemory: os.totalmem(),
      freeMemory: os.freemem(),
      cpuCount: os.cpus().length,
      loadAverage: os.loadavg(),
      networkInterfaces: os.networkInterfaces()
    };
  },

  getProcessInfo: () => {
    return {
      pid: process.pid,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      version: process.version,
      platform: process.platform,
      arch: process.arch
    };
  }
};

// Metrics endpoint
const getMetrics = async () => {
  try {
    return await register.metrics();
  } catch (error) {
    logger.error('Error getting metrics', error);
    throw error;
  }
};

// Reset metrics (useful for testing)
const resetMetrics = () => {
  register.clear();
};

module.exports = {
  register,
  performanceMetrics,
  healthCheckMetrics,
  systemMetrics,
  getMetrics,
  resetMetrics,
  // Export individual metrics for direct access
  httpRequestDurationMicroseconds,
  httpRequestTotal,
  activeConnections,
  serviceHealthStatus,
  databaseQueryDuration,
  cacheHitRatio,
  alertCount,
  pushNotificationSent,
  backupStatus,
  sslCertificateExpiry
};
