'use client';

import React, { useState } from 'react';
import PriceOracleWidget from '../../components/PriceOracleWidget';

const PriceOraclePage: React.FC = () => {
  const [theme, setTheme] = useState<'light' | 'dark' | 'cyberpunk'>('dark');
  const [showL2Networks, setShowL2Networks] = useState(true);
  const [refreshInterval, setRefreshInterval] = useState(30000);

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-purple-900">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-white mb-4">
            Crypto Price Oracle Dashboard
          </h1>
          <p className="text-xl text-gray-300 mb-6">
            Real-time cryptocurrency prices from multiple oracle sources
          </p>
          
          {/* Controls */}
          <div className="flex flex-wrap justify-center gap-4 mb-8">
            <div className="flex items-center space-x-2">
              <label className="text-white">Theme:</label>
              <select
                value={theme}
                onChange={(e) => setTheme(e.target.value as 'light' | 'dark' | 'cyberpunk')}
                className="px-3 py-1 bg-gray-800 text-white border border-gray-600 rounded"
                aria-label="Select theme"
              >
                <option value="dark">Dark</option>
                <option value="light">Light</option>
                <option value="cyberpunk">Cyberpunk</option>
              </select>
            </div>
            
            <div className="flex items-center space-x-2">
              <label className="text-white">Refresh:</label>
              <select
                value={refreshInterval}
                onChange={(e) => setRefreshInterval(Number(e.target.value))}
                className="px-3 py-1 bg-gray-800 text-white border border-gray-600 rounded"
                aria-label="Select refresh interval"
              >
                <option value={10000}>10s</option>
                <option value={30000}>30s</option>
                <option value={60000}>1m</option>
                <option value={300000}>5m</option>
              </select>
            </div>
            
            <div className="flex items-center space-x-2">
              <label className="text-white">L2 Networks:</label>
              <input
                type="checkbox"
                checked={showL2Networks}
                onChange={(e) => setShowL2Networks(e.target.checked)}
                className="w-4 h-4"
                aria-label="Show L2 networks"
              />
            </div>
          </div>
        </div>

        {/* Main Widget */}
        <div className="max-w-7xl mx-auto">
          <PriceOracleWidget
            theme={theme}
            showL2Networks={showL2Networks}
            refreshInterval={refreshInterval}
          />
        </div>

        {/* Additional Information */}
        <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
            <h3 className="text-xl font-semibold text-white mb-4">Oracle Sources</h3>
            <ul className="space-y-2 text-gray-300">
              <li>• CoinGecko - Free cryptocurrency data</li>
              <li>• Binance - Exchange prices</li>
              <li>• Kraken - Exchange prices</li>
              <li>• Coinbase - Exchange prices</li>
            </ul>
          </div>
          
          <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
            <h3 className="text-xl font-semibold text-white mb-4">Tracked Assets</h3>
            <ul className="space-y-2 text-gray-300">
              <li>• ETH, BTC - Major cryptocurrencies</li>
              <li>• USDC, USDT - Stablecoins</li>
              <li>• LINK, UNI, AAVE - DeFi tokens</li>
              <li>• L2 Networks - Polygon, Arbitrum, etc.</li>
            </ul>
          </div>
          
          <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
            <h3 className="text-xl font-semibold text-white mb-4">Features</h3>
            <ul className="space-y-2 text-gray-300">
              <li>• Real-time price updates</li>
              <li>• Multi-oracle aggregation</li>
              <li>• L2 network data</li>
              <li>• Historical price tracking</li>
            </ul>
          </div>
        </div>

        {/* API Documentation Link */}
        <div className="mt-8 text-center">
          <a
            href="https://api.defimon.highfunk.uk/docs"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
            </svg>
            API Documentation
          </a>
        </div>
      </div>
    </div>
  );
};

export default PriceOraclePage;
