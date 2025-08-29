'use client'

import React, { useState, useEffect, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  TrendingUp, 
  TrendingDown, 
  DollarSign, 
  Activity, 
  Zap,
  Shield,
  Target,
  BarChart3,
  PieChart,
  LineChart,
  Smartphone,
  Monitor,
  Globe,
  Wifi,
  Server,
  Database,
  Cpu,
  HardDrive,
  Network,
  Settings,
  Bell,
  Search,
  Filter,
  Download,
  Share2,
  RefreshCw,
  Eye,
  EyeOff,
  Maximize2,
  Minimize2,
  Loader2
} from 'lucide-react'
import { LineChart as RechartsLineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts'

import {
  ModernCard,
  AnimatedMetric,
  NetworkStatusGrid,
  AnimatedDataStream,
  FloatingActionButton,
  ProgressRing,
  AnimatedParticles,
  ModernToggle
} from './ModernDesignSystem'

// Data interfaces
interface MetricData {
  title: string
  value: string
  change: string
  icon: any
  trend: 'up' | 'down'
  color: 'emerald' | 'blue' | 'red' | 'purple'
}

interface LiveDataItem {
  name: string
  description: string
  value: string
  change: number
  icon: any
}

interface ChartData {
  name: string
  volume: number
  price: number
}[]

export default function EnhancedDashboard() {
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [showLiveData, setShowLiveData] = useState(true)
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [selectedTimeframe, setSelectedTimeframe] = useState('24h')
  const [selectedNetwork, setSelectedNetwork] = useState('all')
  const [isLoading, setIsLoading] = useState(false)
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date())

  // Data states
  const [metricsData, setMetricsData] = useState<MetricData[]>([])
  const [liveDataStream, setLiveDataStream] = useState<LiveDataItem[]>([])
  const [chartData, setChartData] = useState<ChartData | null>(null)

  const timeframes = ['1h', '24h', '7d', '30d', '1y']
  const networks = ['all', 'ethereum', 'polygon', 'arbitrum', 'optimism', 'base']

  // Generate different data based on timeframe
  const generateTimeframeData = useCallback((timeframe: string) => {
    const baseValues = {
      '1h': { tvl: 2.1, volume: 45, users: 12.1, efficiency: 92.8 },
      '24h': { tvl: 2.4, volume: 856, users: 124.5, efficiency: 94.2 },
      '7d': { tvl: 2.8, volume: 1250, users: 156.2, efficiency: 95.1 },
      '30d': { tvl: 3.2, volume: 2100, users: 189.7, efficiency: 96.3 },
      '1y': { tvl: 4.1, volume: 3500, users: 245.3, efficiency: 97.8 }
    }

    const baseChanges = {
      '1h': { tvl: 0.8, volume: 2.1, users: -0.5, efficiency: 0.3 },
      '24h': { tvl: 12.5, volume: 8.2, users: -2.1, efficiency: 1.8 },
      '7d': { tvl: 18.7, volume: 15.3, users: 5.2, efficiency: 2.4 },
      '30d': { tvl: 25.4, volume: 22.1, users: 12.8, efficiency: 3.1 },
      '1y': { tvl: 45.2, volume: 38.7, users: 28.4, efficiency: 4.2 }
    }

    const values = baseValues[timeframe as keyof typeof baseValues] || baseValues['24h']
    const changes = baseChanges[timeframe as keyof typeof baseChanges] || baseChanges['24h']

    return [
      {
        title: 'Total Value Locked',
        value: `$${values.tvl}B`,
        change: `${changes.tvl > 0 ? '+' : ''}${changes.tvl}%`,
        icon: DollarSign,
        trend: changes.tvl >= 0 ? 'up' as const : 'down' as const,
        color: changes.tvl >= 0 ? 'emerald' as const : 'red' as const
      },
      {
        title: 'Daily Volume',
        value: `$${values.volume}M`,
        change: `${changes.volume > 0 ? '+' : ''}${changes.volume}%`,
        icon: Activity,
        trend: changes.volume >= 0 ? 'up' as const : 'down' as const,
        color: changes.volume >= 0 ? 'blue' as const : 'red' as const
      },
      {
        title: 'Active Users',
        value: `${values.users}K`,
        change: `${changes.users > 0 ? '+' : ''}${changes.users}%`,
        icon: Users,
        trend: changes.users >= 0 ? 'up' as const : 'down' as const,
        color: changes.users >= 0 ? 'emerald' as const : 'red' as const
      },
      {
        title: 'Gas Efficiency',
        value: `${values.efficiency}%`,
        change: `${changes.efficiency > 0 ? '+' : ''}${changes.efficiency}%`,
        icon: Zap,
        trend: changes.efficiency >= 0 ? 'up' as const : 'down' as const,
        color: changes.efficiency >= 0 ? 'purple' as const : 'red' as const
      }
    ]
  }, [])

  // Generate live data based on timeframe
  const generateLiveData = useCallback((timeframe: string) => {
    const basePrices = {
      '1h': { eth: 3245.67, btc: 43567.89 },
      '24h': { eth: 3245.67, btc: 43567.89 },
      '7d': { eth: 3180.45, btc: 42890.12 },
      '30d': { eth: 2950.23, btc: 41200.78 },
      '1y': { eth: 2450.67, btc: 38500.45 }
    }

    const baseChanges = {
      '1h': { eth: 2.3, btc: -1.2, load: 5.4, gas: -8.7 },
      '24h': { eth: 2.3, btc: -1.2, load: 5.4, gas: -8.7 },
      '7d': { eth: 8.7, btc: 1.8, load: 12.3, gas: -15.2 },
      '30d': { eth: 15.2, btc: 5.7, load: 18.9, gas: -22.1 },
      '1y': { eth: 32.4, btc: 13.2, load: 25.6, gas: -35.8 }
    }

    const prices = basePrices[timeframe as keyof typeof basePrices] || basePrices['24h']
    const changes = baseChanges[timeframe as keyof typeof baseChanges] || baseChanges['24h']

    return [
      {
        name: 'ETH Price',
        description: 'Ethereum',
        value: `$${prices.eth.toLocaleString()}`,
        change: changes.eth,
        icon: DollarSign
      },
      {
        name: 'BTC Price',
        description: 'Bitcoin',
        value: `$${prices.btc.toLocaleString()}`,
        change: changes.btc,
        icon: DollarSign
      },
      {
        name: 'Network Load',
        description: 'Ethereum',
        value: '87%',
        change: changes.load,
        icon: Activity
      },
      {
        name: 'Gas Price',
        description: 'Current',
        value: '12 gwei',
        change: changes.gas,
        icon: Zap
      }
    ]
  }, [])

  // Generate chart data based on timeframe
  const generateChartData = useCallback((timeframe: string) => {
    const dataPoints = {
      '1h': 12,
      '24h': 24,
      '7d': 7,
      '30d': 30,
      '1y': 12
    }

    const points = dataPoints[timeframe as keyof typeof dataPoints] || 24
    const chartData = []

    for (let i = 0; i < points; i++) {
      let name = ''
      if (timeframe === '1h') {
        name = `${i * 5}:${(i * 5 % 60).toString().padStart(2, '0')}`
      } else if (timeframe === '24h') {
        name = `${i}:00`
      } else if (timeframe === '7d') {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        name = days[i % 7]
      } else if (timeframe === '30d') {
        name = `Day ${i + 1}`
      } else {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        name = months[i % 12]
      }

      chartData.push({
        name,
        volume: Math.floor(Math.random() * 2000) + 500,
        price: Math.floor(Math.random() * 1000) + 2000
      })
    }

    return chartData
  }, [])

  // Fetch data based on timeframe
  const fetchData = useCallback(async (timeframe: string) => {
    setIsLoading(true)
    
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 800))
    
    const newMetricsData = generateTimeframeData(timeframe)
    const newLiveData = generateLiveData(timeframe)
    const newChartData = generateChartData(timeframe)
    
    setMetricsData(newMetricsData)
    setLiveDataStream(newLiveData)
    setChartData(newChartData)
    setLastUpdate(new Date())
    setIsLoading(false)
  }, [generateTimeframeData, generateLiveData, generateChartData])

  // Load initial data
  useEffect(() => {
    fetchData(selectedTimeframe)
  }, [fetchData, selectedTimeframe])

  // Auto-refresh functionality
  useEffect(() => {
    if (!autoRefresh) return

    const interval = setInterval(() => {
      fetchData(selectedTimeframe)
    }, 30000) // Refresh every 30 seconds

    return () => clearInterval(interval)
  }, [autoRefresh, selectedTimeframe, fetchData])

  // Handle timeframe change
  const handleTimeframeChange = (timeframe: string) => {
    setSelectedTimeframe(timeframe)
    fetchData(timeframe)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-black to-gray-800 relative overflow-hidden">
      {/* Animated Background */}
      <AnimatedParticles />
      
      {/* Enhanced Header */}
      <motion.header 
        className="relative z-50 bg-black/20 backdrop-blur-2xl border-b border-white/10"
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        transition={{ type: "spring", stiffness: 100, damping: 20 }}
      >
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            {/* Logo and Title */}
            <div className="flex items-center space-x-4">
              <motion.div
                className="relative"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <div className="w-12 h-12 bg-gradient-to-r from-purple-500 via-pink-500 to-blue-500 rounded-2xl flex items-center justify-center shadow-lg shadow-purple-500/25">
                  <BarChart3 className="w-7 h-7 text-white" />
                </div>
                <div className="absolute inset-0 bg-gradient-to-r from-purple-500 via-pink-500 to-blue-500 rounded-2xl blur-lg opacity-30 animate-pulse"></div>
              </motion.div>
              <div>
                <h1 className="text-2xl font-black text-white">DeFiMon Pro</h1>
                <p className="text-sm text-gray-400">Enhanced Analytics Dashboard</p>
              </div>
            </div>

            {/* Controls */}
            <div className="flex items-center space-x-4">
              {/* Search */}
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search metrics..."
                  className="pl-10 pr-4 py-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500/50"
                />
              </div>

              {/* Toggles */}
              <ModernToggle
                checked={showLiveData}
                onChange={setShowLiveData}
                label="Live Data"
              />
              <ModernToggle
                checked={autoRefresh}
                onChange={setAutoRefresh}
                label="Auto Refresh"
              />

              {/* Action Buttons */}
              <motion.button
                onClick={() => setIsFullscreen(!isFullscreen)}
                className="p-3 bg-gray-800/50 backdrop-blur-sm hover:bg-gray-700/50 rounded-xl text-white border border-white/10 transition-all"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                {isFullscreen ? <Minimize2 className="w-5 h-5" /> : <Maximize2 className="w-5 h-5" />}
              </motion.button>

              <motion.button
                className="p-3 bg-gray-800/50 backdrop-blur-sm hover:bg-gray-700/50 rounded-xl text-white border border-white/10 transition-all"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <Settings className="w-5 h-5" />
              </motion.button>
            </div>
          </div>
        </div>
      </motion.header>

      {/* Filters and Timeframe */}
      <motion.section 
        className="relative z-40 py-6"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
      >
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex flex-wrap items-center justify-between gap-4">
            {/* Timeframe Selector */}
            <div className="flex items-center space-x-2">
              <span className="text-gray-400 font-medium">Timeframe:</span>
              <div className="flex bg-gray-800/50 backdrop-blur-sm rounded-xl p-1 border border-white/10">
                {timeframes.map((timeframe) => (
                  <motion.button
                    key={timeframe}
                    onClick={() => handleTimeframeChange(timeframe)}
                    disabled={isLoading}
                    className={`px-4 py-2 rounded-lg text-sm font-medium transition-all flex items-center space-x-2 ${
                      selectedTimeframe === timeframe
                        ? 'bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg shadow-purple-500/25'
                        : 'text-gray-400 hover:text-white hover:bg-white/5'
                    } ${isLoading ? 'opacity-50 cursor-not-allowed' : ''}`}
                    whileHover={!isLoading ? { scale: 1.02 } : {}}
                    whileTap={!isLoading ? { scale: 0.98 } : {}}
                  >
                    {isLoading && selectedTimeframe === timeframe && (
                      <Loader2 className="w-3 h-3 animate-spin" />
                    )}
                    <span>{timeframe}</span>
                  </motion.button>
                ))}
              </div>
            </div>

            {/* Network Filter */}
            <div className="flex items-center space-x-2">
              <label htmlFor="network-select" className="text-gray-400 font-medium">Network:</label>
              <select
                id="network-select"
                value={selectedNetwork}
                onChange={(e) => setSelectedNetwork(e.target.value)}
                className="px-4 py-2 bg-gray-800/50 backdrop-blur-sm border border-white/20 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-purple-500/50"
                aria-label="Select network"
              >
                {networks.map((network) => (
                  <option key={network} value={network} className="bg-gray-800">
                    {network.charAt(0).toUpperCase() + network.slice(1)}
                  </option>
                ))}
              </select>
            </div>

            {/* Action Buttons */}
            <div className="flex items-center space-x-2">
              <motion.button
                onClick={() => fetchData(selectedTimeframe)}
                disabled={isLoading}
                className={`flex items-center space-x-2 px-4 py-2 bg-emerald-500/20 backdrop-blur-sm text-emerald-400 rounded-xl border border-emerald-500/30 hover:bg-emerald-500/30 transition-all ${
                  isLoading ? 'opacity-50 cursor-not-allowed' : ''
                }`}
                whileHover={!isLoading ? { scale: 1.02 } : {}}
                whileTap={!isLoading ? { scale: 0.98 } : {}}
              >
                {isLoading ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : (
                  <RefreshCw className="w-4 h-4" />
                )}
                <span>{isLoading ? 'Loading...' : 'Refresh'}</span>
              </motion.button>

              <motion.button
                className="flex items-center space-x-2 px-4 py-2 bg-blue-500/20 backdrop-blur-sm text-blue-400 rounded-xl border border-blue-500/30 hover:bg-blue-500/30 transition-all"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <Download className="w-4 h-4" />
                <span>Export</span>
              </motion.button>

              <motion.button
                className="flex items-center space-x-2 px-4 py-2 bg-purple-500/20 backdrop-blur-sm text-purple-400 rounded-xl border border-purple-500/30 hover:bg-purple-500/30 transition-all"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <Share2 className="w-4 h-4" />
                <span>Share</span>
              </motion.button>
            </div>
          </div>

          {/* Last Update Indicator */}
          <div className="mt-4 flex items-center justify-between">
            <div className="text-sm text-gray-400">
              Last updated: {lastUpdate.toLocaleTimeString()}
            </div>
            <div className="text-sm text-gray-400">
              Timeframe: {selectedTimeframe} • Network: {selectedNetwork}
            </div>
          </div>
        </div>
      </motion.section>

      {/* Main Dashboard Content */}
      <main className={`relative z-10 ${isFullscreen ? 'fixed inset-0 bg-black z-50' : 'pb-20'}`}>
        <div className={`${isFullscreen ? 'h-full' : 'max-w-7xl'} mx-auto px-6`}>
          
          {/* Metrics Grid */}
          <motion.section 
            className="mb-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
          >
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {metricsData.map((metric, index) => (
                <AnimatedMetric
                  key={metric.title}
                  title={metric.title}
                  value={metric.value}
                  change={metric.change}
                  icon={metric.icon}
                  trend={metric.trend}
                  color={metric.color}
                  delay={index * 0.1}
                />
              ))}
            </div>
          </motion.section>

          {/* Live Data Stream */}
          {showLiveData && (
            <motion.section 
              className="mb-8"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
            >
              <AnimatedDataStream data={liveDataStream} />
            </motion.section>
          )}

          {/* Network Status Grid */}
          <motion.section 
            className="mb-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5 }}
          >
            <NetworkStatusGrid />
          </motion.section>

          {/* Charts and Analytics */}
          <motion.section 
            className="mb-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
          >
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Price and Volume Chart */}
              <ModernCard gradient>
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center space-x-3">
                    <LineChart className="w-8 h-8 text-purple-400" />
                    <h3 className="text-xl font-bold text-white">Price & Volume ({selectedTimeframe})</h3>
                  </div>
                </div>
                
                {chartData && (
                  <div className="h-64">
                    <ResponsiveContainer width="100%" height="100%">
                      <RechartsLineChart data={chartData}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                        <XAxis 
                          dataKey="name" 
                          stroke="#9ca3af"
                          fontSize={12}
                        />
                        <YAxis 
                          stroke="#9ca3af"
                          fontSize={12}
                          yAxisId="left"
                        />
                        <YAxis 
                          stroke="#9ca3af"
                          fontSize={12}
                          yAxisId="right"
                          orientation="right"
                        />
                        <Tooltip 
                          contentStyle={{
                            backgroundColor: '#1f2937',
                            border: '1px solid #374151',
                            borderRadius: '8px',
                            color: '#f3f4f6'
                          }}
                        />
                        <Legend />
                        <Line 
                          yAxisId="left"
                          type="monotone" 
                          dataKey="volume" 
                          stroke="#8b5cf6" 
                          strokeWidth={2}
                          dot={{ fill: '#8b5cf6', strokeWidth: 2, r: 4 }}
                          activeDot={{ r: 6 }}
                        />
                        <Line 
                          yAxisId="right"
                          type="monotone" 
                          dataKey="price" 
                          stroke="#3b82f6" 
                          strokeWidth={2}
                          dot={{ fill: '#3b82f6', strokeWidth: 2, r: 4 }}
                          activeDot={{ r: 6 }}
                        />
                      </RechartsLineChart>
                    </ResponsiveContainer>
                  </div>
                )}
                
                {isLoading && (
                  <div className="h-64 flex items-center justify-center">
                    <div className="flex items-center space-x-2 text-gray-400">
                      <Loader2 className="w-6 h-6 animate-spin" />
                      <span>Loading chart data...</span>
                    </div>
                  </div>
                )}
              </ModernCard>

              {/* Risk Assessment */}
              <ModernCard gradient glow>
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center space-x-3">
                    <Shield className="w-8 h-8 text-emerald-400" />
                    <h3 className="text-xl font-bold text-white">Risk Assessment</h3>
                  </div>
                  <div className="text-right">
                    <p className="text-2xl font-bold text-emerald-400">Low</p>
                    <p className="text-sm text-gray-400">Risk Level</p>
                  </div>
                </div>
                
                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Market Volatility</span>
                    <span className="text-white font-mono">23%</span>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-2">
                    <div className="bg-emerald-500 h-2 rounded-full" style={{ width: '23%' }}></div>
                  </div>
                  
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Liquidity Risk</span>
                    <span className="text-white font-mono">8%</span>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-2">
                    <div className="bg-emerald-500 h-2 rounded-full" style={{ width: '8%' }}></div>
                  </div>
                  
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Smart Contract Risk</span>
                    <span className="text-white font-mono">15%</span>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-2">
                    <div className="bg-emerald-500 h-2 rounded-full" style={{ width: '15%' }}></div>
                  </div>
                </div>
              </ModernCard>

              {/* Market Sentiment */}
              <ModernCard gradient glow>
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center space-x-3">
                    <Target className="w-8 h-8 text-blue-400" />
                    <h3 className="text-xl font-bold text-white">Market Sentiment</h3>
                  </div>
                  <div className="text-right">
                    <p className="text-2xl font-bold text-blue-400">Bullish</p>
                    <p className="text-sm text-gray-400">Sentiment</p>
                  </div>
                </div>
                
                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Fear & Greed Index</span>
                    <span className="text-white font-mono">72</span>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-2">
                    <div className="bg-blue-500 h-2 rounded-full" style={{ width: '72%' }}></div>
                  </div>
                  
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Social Sentiment</span>
                    <span className="text-white font-mono">+18%</span>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-2">
                    <div className="bg-blue-500 h-2 rounded-full" style={{ width: '65%' }}></div>
                  </div>
                  
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">News Sentiment</span>
                    <span className="text-white font-mono">+12%</span>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-2">
                    <div className="bg-blue-500 h-2 rounded-full" style={{ width: '58%' }}></div>
                  </div>
                </div>
              </ModernCard>
            </div>
          </motion.section>
        </div>

        {/* Fullscreen Exit */}
        {isFullscreen && (
          <motion.button
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            onClick={() => setIsFullscreen(false)}
            className="fixed top-6 right-6 z-60 p-3 bg-black/50 backdrop-blur-sm hover:bg-black/70 rounded-xl text-white border border-white/20 transition-all"
          >
            <Eye className="w-5 h-5" />
          </motion.button>
        )}
      </main>

      {/* Floating Action Button */}
      <FloatingActionButton
        icon={Bell}
        onClick={() => console.log('Notifications')}
        label="Notifications"
        color="purple"
      />
    </div>
  )
}

// Missing Users icon component
const Users = ({ className }: { className?: string }) => (
  <svg className={className} fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
  </svg>
)
