'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

interface RateLimitInfo {
  method: string;
  standardMode: number;
  scaleMode: number;
}

interface TestResult {
  method: string;
  success: boolean;
  responseTime: number;
  error?: string;
}

const rateLimits: RateLimitInfo[] = [
  { method: 'getBlock', standardMode: 25, scaleMode: 100 },
  { method: 'getBlockTime', standardMode: 40, scaleMode: 120 },
  { method: 'getBlocks', standardMode: 35, scaleMode: 100 },
  { method: 'getLargestAccounts', standardMode: 0, scaleMode: 0 },
  { method: 'getMultipleAccounts', standardMode: 25, scaleMode: 75 },
  { method: 'getProgramAccounts', standardMode: 0, scaleMode: 5 },
  { method: 'getSignaturesForAddress', standardMode: 50, scaleMode: 150 },
  { method: 'getTokenAccountsByOwner', standardMode: 35, scaleMode: 200 },
  { method: 'getTransaction', standardMode: 20, scaleMode: 60 },
  { method: 'sendTransaction', standardMode: 20, scaleMode: 60 },
  { method: 'Unspecified methods', standardMode: 100, scaleMode: 300 },
];

export default function SyndicaCheckPage() {
  const [apiKey, setApiKey] = useState('4YcmfPnjM4qpReCHiYcVvcrTppHLMDtPZixgVSZyHrH21jPHSvCdxrA3sVNJVLQ4kWeXTYRucgnGbRkJfw7uhztH4KvE6tNEqQZ');
  const [endpoint, setEndpoint] = useState('https://solana-mainnet.api.syndica.io/api-key/4YcmfPnjM4qpReCHiYcVvcrTppHLMDtPZixgVSZyHrH21jPHSvCdxrA3sVNJVLQ4kWeXTYRucgnGbRkJfw7uhztH4KvE6tNEqQZ');
  const [isTesting, setIsTesting] = useState(false);
  const [testResults, setTestResults] = useState<TestResult[]>([]);
  const [connectionStatus, setConnectionStatus] = useState<'idle' | 'testing' | 'success' | 'error'>('idle');
  const [connectionError, setConnectionError] = useState('');

  const testConnection = async () => {
    setIsTesting(true);
    setConnectionStatus('testing');
    setTestResults([]);
    setConnectionError('');

    try {
      // Test basic connection
      const startTime = Date.now();
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          jsonrpc: '2.0',
          id: 1,
          method: 'getHealth',
        }),
      });

      const responseTime = Date.now() - startTime;

      if (response.ok) {
        setConnectionStatus('success');
        const data = await response.json();
        
        // Test various methods
        const methodsToTest = [
          'getBlockHeight',
          'getSlot',
          'getRecentBlockhash',
          'getVersion',
        ];

        const results: TestResult[] = [];

        for (const method of methodsToTest) {
          try {
            const methodStartTime = Date.now();
            const methodResponse = await fetch(endpoint, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                jsonrpc: '2.0',
                id: Math.floor(Math.random() * 1000),
                method: method,
                params: method === 'getRecentBlockhash' ? [] : [],
              }),
            });

            const methodResponseTime = Date.now() - methodStartTime;
            const methodData = await methodResponse.json();

            results.push({
              method,
              success: !methodData.error,
              responseTime: methodResponseTime,
              error: methodData.error?.message,
            });
          } catch (error) {
            results.push({
              method,
              success: false,
              responseTime: 0,
              error: error instanceof Error ? error.message : 'Unknown error',
            });
          }
        }

        setTestResults(results);
      } else {
        setConnectionStatus('error');
        setConnectionError(`HTTP ${response.status}: ${response.statusText}`);
      }
    } catch (error) {
      setConnectionStatus('error');
      setConnectionError(error instanceof Error ? error.message : 'Connection failed');
    } finally {
      setIsTesting(false);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 text-white">
      <div className="container mx-auto px-4 py-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="max-w-6xl mx-auto"
        >
          {/* Header */}
          <div className="text-center mb-12">
            <h1 className="text-4xl font-bold mb-4 bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
              Syndica API Credential Checker
            </h1>
            <p className="text-gray-300 text-lg">
              Test your Syndica API credentials and connection status
            </p>
          </div>

          {/* Credentials Section */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 mb-8 border border-white/20"
          >
            <h2 className="text-2xl font-semibold mb-6 text-purple-300">API Credentials</h2>
            
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  API Key
                </label>
                <div className="relative">
                  <input
                    type="text"
                    value={apiKey}
                    onChange={(e) => setApiKey(e.target.value)}
                    className="w-full bg-white/5 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                    placeholder="Enter your Syndica API key"
                  />
                  <button
                    onClick={() => copyToClipboard(apiKey)}
                    className="absolute right-2 top-1/2 transform -translate-y-1/2 bg-purple-600 hover:bg-purple-700 px-3 py-1 rounded text-sm transition-colors"
                  >
                    Copy
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Endpoint URL
                </label>
                <div className="relative">
                  <input
                    type="text"
                    value={endpoint}
                    onChange={(e) => setEndpoint(e.target.value)}
                    className="w-full bg-white/5 border border-white/20 rounded-lg px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                    placeholder="Enter your Syndica endpoint URL"
                  />
                  <button
                    onClick={() => copyToClipboard(endpoint)}
                    className="absolute right-2 top-1/2 transform -translate-y-1/2 bg-purple-600 hover:bg-purple-700 px-3 py-1 rounded text-sm transition-colors"
                  >
                    Copy
                  </button>
                </div>
              </div>
            </div>

            <div className="mt-6">
              <button
                onClick={testConnection}
                disabled={isTesting}
                className="w-full bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 disabled:opacity-50 disabled:cursor-not-allowed text-white font-semibold py-3 px-6 rounded-lg transition-all duration-200 transform hover:scale-105"
              >
                {isTesting ? (
                  <div className="flex items-center justify-center">
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                    Testing Connection...
                  </div>
                ) : (
                  'Test Connection'
                )}
              </button>
            </div>
          </motion.div>

          {/* Connection Status */}
          {connectionStatus !== 'idle' && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 mb-8 border border-white/20"
            >
              <h2 className="text-2xl font-semibold mb-6 text-purple-300">Connection Status</h2>
              
              <div className="flex items-center mb-4">
                <div className={`w-4 h-4 rounded-full mr-3 ${
                  connectionStatus === 'success' ? 'bg-green-500' :
                  connectionStatus === 'error' ? 'bg-red-500' :
                  'bg-yellow-500 animate-pulse'
                }`}></div>
                <span className="text-lg font-medium">
                  {connectionStatus === 'success' ? 'Connected Successfully' :
                   connectionStatus === 'error' ? 'Connection Failed' :
                   'Testing Connection...'}
                </span>
              </div>

              {connectionError && (
                <div className="bg-red-500/20 border border-red-500/50 rounded-lg p-4 mb-4">
                  <p className="text-red-300">{connectionError}</p>
                </div>
              )}

              {testResults.length > 0 && (
                <div>
                  <h3 className="text-lg font-semibold mb-4 text-gray-300">Method Test Results</h3>
                  <div className="grid gap-3">
                    {testResults.map((result, index) => (
                      <div
                        key={index}
                        className={`p-4 rounded-lg border ${
                          result.success
                            ? 'bg-green-500/20 border-green-500/50'
                            : 'bg-red-500/20 border-red-500/50'
                        }`}
                      >
                        <div className="flex justify-between items-center">
                          <span className="font-medium">{result.method}</span>
                          <div className="flex items-center space-x-4">
                            <span className={`px-2 py-1 rounded text-sm ${
                              result.success
                                ? 'bg-green-600 text-white'
                                : 'bg-red-600 text-white'
                            }`}>
                              {result.success ? 'Success' : 'Failed'}
                            </span>
                            {result.success && (
                              <span className="text-sm text-gray-300">
                                {result.responseTime}ms
                              </span>
                            )}
                          </div>
                        </div>
                        {result.error && (
                          <p className="text-sm text-red-300 mt-2">{result.error}</p>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </motion.div>
          )}

          {/* Rate Limits Section */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 border border-white/20"
          >
            <h2 className="text-2xl font-semibold mb-6 text-purple-300">Rate Limits</h2>
            <p className="text-gray-300 mb-6">
              Based on the <a href="https://docs.syndica.io/platform/resources/rate-limits" target="_blank" rel="noopener noreferrer" className="text-purple-400 hover:text-purple-300 underline">official Syndica documentation</a>
            </p>
            
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-white/20">
                    <th className="text-left py-3 px-4 font-semibold text-purple-300">Method</th>
                    <th className="text-center py-3 px-4 font-semibold text-purple-300">Standard Mode (RPS)</th>
                    <th className="text-center py-3 px-4 font-semibold text-purple-300">Scale Mode (RPS)</th>
                  </tr>
                </thead>
                <tbody>
                  {rateLimits.map((limit, index) => (
                    <tr key={index} className="border-b border-white/10 hover:bg-white/5">
                      <td className="py-3 px-4 font-mono text-sm">{limit.method}</td>
                      <td className="py-3 px-4 text-center">
                        <span className={`px-2 py-1 rounded ${
                          limit.standardMode === 0
                            ? 'bg-red-500/20 text-red-300'
                            : 'bg-green-500/20 text-green-300'
                        }`}>
                          {limit.standardMode}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-center">
                        <span className={`px-2 py-1 rounded ${
                          limit.scaleMode === 0
                            ? 'bg-red-500/20 text-red-300'
                            : 'bg-green-500/20 text-green-300'
                        }`}>
                          {limit.scaleMode}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* WebSocket Limits */}
            <div className="mt-8">
              <h3 className="text-xl font-semibold mb-4 text-purple-300">WebSocket Limits</h3>
              <div className="grid md:grid-cols-2 gap-6">
                <div className="bg-white/5 rounded-lg p-4">
                  <h4 className="font-semibold text-gray-300 mb-2">Max Active Connections</h4>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span>Standard Mode:</span>
                      <span className="text-green-300">100</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Scale Mode:</span>
                      <span className="text-green-300">300</span>
                    </div>
                  </div>
                </div>
                <div className="bg-white/5 rounded-lg p-4">
                  <h4 className="font-semibold text-gray-300 mb-2">Max Total Subscriptions</h4>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span>Standard Mode:</span>
                      <span className="text-green-300">100</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Scale Mode:</span>
                      <span className="text-green-300">600</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </div>
  );
}
