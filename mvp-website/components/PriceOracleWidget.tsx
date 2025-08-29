'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

interface PriceData {
  symbol: string;
  price_usd: number;
  volume_24h_usd?: number;
  market_cap_usd?: number;
  price_change_24h_percent?: number;
  last_updated: string;
  oracle_source: string;
}

interface L2NetworkData {
  network: string;
  network_token_symbol: string;
  price_usd: number;
  volume_24h_usd?: number;
  market_cap_usd?: number;
  price_change_24h_percent?: number;
  tvl_usd?: number;
  total_transactions_24h?: number;
  avg_gas_price_gwei?: number;
  last_updated: string;
}

interface PriceOracleWidgetProps {
  apiBaseUrl?: string;
  refreshInterval?: number;
  showL2Networks?: boolean;
  theme?: 'light' | 'dark' | 'cyberpunk';
}

const PriceOracleWidget: React.FC<PriceOracleWidgetProps> = ({
  apiBaseUrl = 'https://api.defimon.highfunk.uk',
  refreshInterval = 30000, // 30 seconds
  showL2Networks = true,
  theme = 'dark'
}) => {
  const [prices, setPrices] = useState<PriceData[]>([]);
  const [l2Networks, setL2Networks] = useState<L2NetworkData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);

  const fetchPrices = async () => {
    try {
      const response = await fetch(`${apiBaseUrl}/prices`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setPrices(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch prices');
    }
  };

  const fetchL2Networks = async () => {
    try {
      const response = await fetch(`${apiBaseUrl}/l2-networks`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setL2Networks(data);
    } catch (err) {
      console.error('Failed to fetch L2 networks:', err);
    }
  };

  const fetchData = async () => {
    setLoading(true);
    await Promise.all([fetchPrices(), showL2Networks ? fetchL2Networks() : Promise.resolve()]);
    setLastUpdate(new Date());
    setLoading(false);
  };

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, refreshInterval);
    return () => clearInterval(interval);
  }, [apiBaseUrl, refreshInterval, showL2Networks]);

  const formatPrice = (price: number) => {
    if (price >= 1) {
      return `$${price.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    } else {
      return `$${price.toLocaleString('en-US', { minimumFractionDigits: 6, maximumFractionDigits: 6 })}`;
    }
  };

  const formatVolume = (volume?: number) => {
    if (!volume) return 'N/A';
    if (volume >= 1e9) {
      return `$${(volume / 1e9).toFixed(2)}B`;
    } else if (volume >= 1e6) {
      return `$${(volume / 1e6).toFixed(2)}M`;
    } else if (volume >= 1e3) {
      return `$${(volume / 1e3).toFixed(2)}K`;
    }
    return `$${volume.toFixed(2)}`;
  };

  const formatMarketCap = (marketCap?: number) => {
    if (!marketCap) return 'N/A';
    if (marketCap >= 1e12) {
      return `$${(marketCap / 1e12).toFixed(2)}T`;
    } else if (marketCap >= 1e9) {
      return `$${(marketCap / 1e9).toFixed(2)}B`;
    } else if (marketCap >= 1e6) {
      return `$${(marketCap / 1e6).toFixed(2)}M`;
    }
    return `$${marketCap.toFixed(2)}`;
  };

  const getPriceChangeColor = (change?: number) => {
    if (!change) return 'text-gray-400';
    return change >= 0 ? 'text-green-400' : 'text-red-400';
  };

  const getPriceChangeIcon = (change?: number) => {
    if (!change) return '→';
    return change >= 0 ? '↗' : '↘';
  };

  const themeClasses = {
    light: 'bg-white text-gray-900 border-gray-200',
    dark: 'bg-gray-900 text-white border-gray-700',
    cyberpunk: 'bg-black text-cyan-400 border-cyan-500'
  };

  const cardClasses = {
    light: 'bg-gray-50 border-gray-200 hover:bg-gray-100',
    dark: 'bg-gray-800 border-gray-700 hover:bg-gray-750',
    cyberpunk: 'bg-gray-900 border-cyan-500 hover:bg-gray-800'
  };

  if (error) {
    return (
      <div className={`p-6 rounded-lg border ${themeClasses[theme]}`}>
        <div className="text-center">
          <div className="text-red-400 text-2xl mb-2">⚠️</div>
          <h3 className="text-lg font-semibold mb-2">Connection Error</h3>
          <p className="text-sm opacity-75">{error}</p>
          <button
            onClick={fetchData}
            className="mt-4 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className={`p-6 rounded-lg border ${themeClasses[theme]}`}>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">Crypto Price Oracle</h2>
        <div className="flex items-center space-x-2">
          {loading && (
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-500"></div>
          )}
          {lastUpdate && (
            <span className="text-sm opacity-75">
              Updated: {lastUpdate.toLocaleTimeString()}
            </span>
          )}
        </div>
      </div>

      {/* Main Cryptocurrencies */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-4">Major Cryptocurrencies</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {prices.slice(0, 6).map((price, index) => (
            <motion.div
              key={price.symbol}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className={`p-4 rounded-lg border ${cardClasses[theme]} transition-all duration-200`}
            >
              <div className="flex justify-between items-start mb-2">
                <div>
                  <h4 className="font-semibold">{price.symbol}</h4>
                  <p className="text-sm opacity-75">{price.oracle_source}</p>
                </div>
                <div className="text-right">
                  <div className="text-lg font-bold">{formatPrice(price.price_usd)}</div>
                  <div className={`text-sm ${getPriceChangeColor(price.price_change_24h_percent)}`}>
                    {getPriceChangeIcon(price.price_change_24h_percent)}
                    {price.price_change_24h_percent ? `${Math.abs(price.price_change_24h_percent).toFixed(2)}%` : 'N/A'}
                  </div>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2 text-xs opacity-75">
                <div>Volume: {formatVolume(price.volume_24h_usd)}</div>
                <div>Market Cap: {formatMarketCap(price.market_cap_usd)}</div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* L2 Networks */}
      {showL2Networks && l2Networks.length > 0 && (
        <div>
          <h3 className="text-lg font-semibold mb-4">L2 Networks</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {l2Networks.map((network, index) => (
              <motion.div
                key={network.network}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                className={`p-4 rounded-lg border ${cardClasses[theme]} transition-all duration-200`}
              >
                <div className="flex justify-between items-start mb-2">
                  <div>
                    <h4 className="font-semibold">{network.network}</h4>
                    <p className="text-sm opacity-75">{network.network_token_symbol}</p>
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-bold">{formatPrice(network.price_usd)}</div>
                    <div className={`text-sm ${getPriceChangeColor(network.price_change_24h_percent)}`}>
                      {getPriceChangeIcon(network.price_change_24h_percent)}
                      {network.price_change_24h_percent ? `${Math.abs(network.price_change_24h_percent).toFixed(2)}%` : 'N/A'}
                    </div>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-2 text-xs opacity-75">
                  <div>TVL: {formatVolume(network.tvl_usd)}</div>
                  <div>Gas: {network.avg_gas_price_gwei ? `${network.avg_gas_price_gwei} gwei` : 'N/A'}</div>
                </div>
                {network.total_transactions_24h && (
                  <div className="text-xs opacity-75 mt-1">
                    Transactions (24h): {network.total_transactions_24h.toLocaleString()}
                  </div>
                )}
              </motion.div>
            ))}
          </div>
        </div>
      )}

      {/* API Status */}
      <div className="mt-6 pt-4 border-t border-gray-600">
        <div className="flex justify-between items-center text-sm opacity-75">
          <span>Powered by Multi-Oracle Price Feed</span>
          <span>Refresh: {refreshInterval / 1000}s</span>
        </div>
      </div>
    </div>
  );
};

export default PriceOracleWidget;
