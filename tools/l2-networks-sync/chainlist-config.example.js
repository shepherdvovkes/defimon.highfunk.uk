// Пример конфигурации для Chainlist API интеграции
// Скопируйте этот файл в chainlist-config.js и настройте под ваши нужды

export const chainlistConfig = {
  // Основные эндпоинты Chainlist API
  api: {
    baseUrl: 'https://chainlist.org/api/v1',
    mainnet: 'https://chainlist.org/api/v1/mainnet',
    testnet: 'https://chainlist.org/api/v1/testnet',
    timeout: 30000, // 30 секунд
    retryAttempts: 3
  },

  // Настройки фильтрации сетей
  filtering: {
    // Минимальные требования для сети
    minRequirements: {
      hasRpc: true,
      hasExplorer: true,
      hasChainId: true
    },

    // Приоритетные сети (всегда включаются)
    priorityNetworks: [
      1,      // Ethereum Mainnet
      137,    // Polygon
      56,     // BSC
      42161,  // Arbitrum One
      10,     // Optimism
      8453,   // Base
      324,    // zkSync Era
      1101,   // Polygon zkEVM
      534352, // Scroll
      5000,   // Mantle
      59144   // Linea
    ],

    // Ключевые слова для L2 сетей
    l2Keywords: [
      'rollup',
      'layer 2',
      'l2',
      'optimistic',
      'zk',
      'polygon',
      'arbitrum',
      'optimism',
      'base',
      'scroll',
      'mantle',
      'linea'
    ],

    // Сети, которые нужно исключить
    excludedNetworks: [
      // Добавьте chain_id сетей, которые нужно исключить
    ]
  },

  // Настройки обработки данных
  processing: {
    // Максимальное количество сетей для обработки за раз
    maxNetworksPerRequest: 1000,
    
    // Задержка между запросами (в миллисекундах)
    requestDelay: 100,
    
    // Таймаут для обработки одной сети
    networkProcessingTimeout: 5000
  },

  // Настройки логирования
  logging: {
    enabled: true,
    level: 'info', // 'debug', 'info', 'warn', 'error'
    includeNetworkDetails: false, // Включать ли детали сетей в логи
    logFailedNetworks: true
  },

  // Настройки кэширования
  caching: {
    enabled: true,
    ttl: 3600000, // 1 час в миллисекундах
    maxSize: 1000 // Максимальное количество кэшированных сетей
  },

  // Настройки уведомлений
  notifications: {
    enabled: false,
    webhookUrl: null,
    notifyOnNewNetworks: true,
    notifyOnErrors: true
  }
};

// Функция для валидации конфигурации
export function validateConfig(config) {
  const errors = [];
  
  if (!config.api.baseUrl) {
    errors.push('API base URL is required');
  }
  
  if (!config.api.mainnet) {
    errors.push('Mainnet API URL is required');
  }
  
  if (!config.api.testnet) {
    errors.push('Testnet API URL is required');
  }
  
  if (config.api.timeout < 1000) {
    errors.push('API timeout should be at least 1000ms');
  }
  
  if (config.api.retryAttempts < 1) {
    errors.push('Retry attempts should be at least 1');
  }
  
  if (config.processing.maxNetworksPerRequest < 1) {
    errors.push('Max networks per request should be at least 1');
  }
  
  return {
    isValid: errors.length === 0,
    errors
  };
}

// Функция для получения конфигурации по умолчанию
export function getDefaultConfig() {
  return {
    ...chainlistConfig,
    api: {
      ...chainlistConfig.api,
      timeout: parseInt(process.env.CHAINLIST_TIMEOUT_MS) || chainlistConfig.api.timeout,
      retryAttempts: parseInt(process.env.CHAINLIST_RETRY_ATTEMPTS) || chainlistConfig.api.retryAttempts
    }
  };
}

// Пример использования:
// import { getDefaultConfig, validateConfig } from './chainlist-config.js';
// 
// const config = getDefaultConfig();
// const validation = validateConfig(config);
// 
// if (!validation.isValid) {
//   console.error('Configuration errors:', validation.errors);
//   process.exit(1);
// }
