'use client'

import React, { useState, useEffect } from 'react'
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
  Minimize2
} from 'lucide-react'

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

export default function EnhancedDashboard() {
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [showLiveData, setShowLiveData] = useState(true)
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [selectedTimeframe, setSelectedTimeframe] = useState('24h')
  const [selectedNetwork, setSelectedNetwork] = useState('all')

  // Mock data for demonstration
  const metricsData = [
    {
      title: 'Total Value Locked',
      value: '$2.4B',
      change: '+12.5%',
      icon: DollarSign,
      trend: 'up' as const,
      color: 'emerald' as const
    },
    {
      title: 'Daily Volume',
      value: '$856M',
      change: '+8.2%',
      icon: Activity,
      trend: 'up' as const,
      color: 'blue' as const
    },
    {
      title: 'Active Users',
      value: '124.5K',
      change: '-2.1%',
      icon: Users,
      trend: 'down' as const,
      color: 'red' as const
    },
    {
      title: 'Gas Efficiency',
      value: '94.2%',
      change: '+1.8%',
      icon: Zap,
      trend: 'up' as const,
      color: 'purple' as const
    }
  ]

  const liveDataStream = [
    {
      name: 'ETH Price',
      description: 'Ethereum',
      value: '$3,245.67',
      change: 2.3,
      icon: DollarSign
    },
    {
      name: 'BTC Price',
      description: 'Bitcoin',
      value: '$43,567.89',
      change: -1.2,
      icon: DollarSign
    },
    {
      name: 'Network Load',
      description: 'Ethereum',
      value: '87%',
      change: 5.4,
      icon: Activity
    },
    {
      name: 'Gas Price',
      description: 'Current',
      value: '12 gwei',
      change: -8.7,
      icon: Zap
    }
  ]

  const timeframes = ['1h', '24h', '7d', '30d', '1y']
  const networks = ['all', 'ethereum', 'polygon', 'arbitrum', 'optimism', 'base']

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
                    onClick={() => setSelectedTimeframe(timeframe)}
                    className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                      selectedTimeframe === timeframe
                        ? 'bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg shadow-purple-500/25'
                        : 'text-gray-400 hover:text-white hover:bg-white/5'
                    }`}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    {timeframe}
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
                className="flex items-center space-x-2 px-4 py-2 bg-emerald-500/20 backdrop-blur-sm text-emerald-400 rounded-xl border border-emerald-500/30 hover:bg-emerald-500/30 transition-all"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <RefreshCw className="w-4 h-4" />
                <span>Refresh</span>
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
                />
              ))}
            </div>
          </motion.section>

          {/* Network Status and Live Data */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
            {/* Network Status Grid */}
            <motion.section
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.4 }}
            >
              <div className="mb-4">
                <h2 className="text-2xl font-bold text-white mb-2">Network Status</h2>
                <p className="text-gray-400">Real-time network health monitoring</p>
              </div>
              <NetworkStatusGrid />
            </motion.section>

            {/* Live Data Stream */}
            <motion.section
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.5 }}
            >
              <AnimatedDataStream 
                data={liveDataStream}
                title="Live Market Data"
              />
            </motion.section>
          </div>

          {/* Performance Metrics */}
          <motion.section 
            className="mb-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
          >
            <div className="mb-4">
              <h2 className="text-2xl font-bold text-white mb-2">Performance Metrics</h2>
              <p className="text-gray-400">System performance and efficiency indicators</p>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* CPU Usage */}
              <ModernCard className="text-center">
                <div className="flex items-center justify-center mb-4">
                  <Cpu className="w-8 h-8 text-blue-400 mr-3" />
                  <h3 className="text-lg font-semibold text-white">CPU Usage</h3>
                </div>
                <ProgressRing progress={78} color="blue" />
                <p className="text-gray-400 mt-4">System processing load</p>
              </ModernCard>

              {/* Memory Usage */}
              <ModernCard className="text-center">
                <div className="flex items-center justify-center mb-4">
                  <HardDrive className="w-8 h-8 text-purple-400 mr-3" />
                  <h3 className="text-lg font-semibold text-white">Memory Usage</h3>
                </div>
                <ProgressRing progress={65} color="purple" />
                <p className="text-gray-400 mt-4">RAM utilization</p>
              </ModernCard>

              {/* Storage Usage */}
              <ModernCard className="text-center">
                <div className="flex items-center justify-center mb-4">
                  <HardDrive className="w-8 h-8 text-emerald-400 mr-3" />
                  <h3 className="text-lg font-semibold text-white">Storage Usage</h3>
                </div>
                <ProgressRing progress={42} color="emerald" />
                <p className="text-gray-400 mt-4">Disk space utilization</p>
              </ModernCard>
            </div>
          </motion.section>

          {/* Advanced Analytics */}
          <motion.section 
            className="mb-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7 }}
          >
            <div className="mb-4">
              <h2 className="text-2xl font-bold text-white mb-2">Advanced Analytics</h2>
              <p className="text-gray-400">AI-powered insights and predictions</p>
            </div>
            
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
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
