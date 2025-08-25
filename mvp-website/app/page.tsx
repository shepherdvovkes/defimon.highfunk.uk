'use client'

import './globals.css'
import { motion, AnimatePresence, useScroll, useTransform } from 'framer-motion'
import { useState, useEffect, useRef } from 'react'
import { 
  TrendingUp,
  TrendingDown,
  DollarSign,
  BarChart3,
  PieChart,
  Activity,
  Target,
  Zap,
  Eye,
  Download,
  Bookmark,
  Search,
  Filter,
  Settings,
  Bell,
  User,
  ChevronDown,
  ArrowUpRight,
  ArrowDownRight,
  Clock,
  Globe,
  Shield,
  Cpu,
  Database,
  Network,
  Brain,
  Sparkles,
  Layers,
  Maximize2,
  Minimize2,
  RefreshCw,
  Plus,
  MoreHorizontal,
  Info,
  AlertTriangle,
  CheckCircle,
  XCircle
} from 'lucide-react'

// Import chart components
import { LineChart, Line, AreaChart, Area, BarChart, Bar, PieChart as RechartsPieChart, Cell, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts'
import DataExportPanel from '../components/DataExportPanel'
import AIQuestionInterface from '../components/AIQuestionInterface'

export default function FinancialAnalyticsDashboard() {
  const [activeTab, setActiveTab] = useState('overview')
  const [timeRange, setTimeRange] = useState('24h')
  const [selectedAsset, setSelectedAsset] = useState('ETH')
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [showNotifications, setShowNotifications] = useState(false)
  const [showExportPanel, setShowExportPanel] = useState(false)
  const [bookmarks, setBookmarks] = useState<string[]>([])
  
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({ target: containerRef })
  
  // Transform for parallax effects
  const backgroundY = useTransform(scrollYProgress, [0, 1], ['0%', '50%'])
  const titleScale = useTransform(scrollYProgress, [0, 0.2], [1, 0.9])

  // Sample data for charts
  const priceData = [
    { time: '00:00', price: 2450, volume: 1200, marketCap: 295000000000 },
    { time: '04:00', price: 2480, volume: 1400, marketCap: 298000000000 },
    { time: '08:00', price: 2520, volume: 1600, marketCap: 302000000000 },
    { time: '12:00', price: 2490, volume: 1300, marketCap: 299000000000 },
    { time: '16:00', price: 2510, volume: 1500, marketCap: 301000000000 },
    { time: '20:00', price: 2530, volume: 1700, marketCap: 303000000000 },
  ]

  const portfolioData = [
    { name: 'Ethereum', value: 45, color: '#6366f1' },
    { name: 'Bitcoin', value: 30, color: '#f59e0b' },
    { name: 'Polygon', value: 15, color: '#8b5cf6' },
    { name: 'Arbitrum', value: 10, color: '#06b6d4' },
  ]

  const networkMetrics = [
    { name: 'Ethereum', tvl: 45.2, change: 2.3, status: 'active' },
    { name: 'Polygon', tvl: 12.8, change: -1.2, status: 'active' },
    { name: 'Arbitrum', tvl: 8.9, change: 5.7, status: 'active' },
    { name: 'Optimism', tvl: 6.4, change: 1.8, status: 'warning' },
    { name: 'Base', tvl: 3.2, change: -0.5, status: 'error' },
  ]

  const aiPredictions = [
    { metric: 'Price Prediction', value: '$2,650', confidence: 85, trend: 'up' },
    { metric: 'Volatility', value: 'Medium', confidence: 72, trend: 'neutral' },
    { metric: 'Risk Score', value: 'Low', confidence: 88, trend: 'down' },
    { metric: 'Market Sentiment', value: 'Bullish', confidence: 76, trend: 'up' },
  ]

  const alerts = [
    { id: 1, type: 'price', message: 'ETH price dropped below $2,450', severity: 'high', time: '2 min ago' },
    { id: 2, type: 'volume', message: 'Unusual volume spike detected', severity: 'medium', time: '5 min ago' },
    { id: 3, type: 'network', message: 'Polygon network congestion', severity: 'low', time: '10 min ago' },
  ]

  const toggleBookmark = (item: string) => {
    setBookmarks(prev => 
      prev.includes(item) 
        ? prev.filter(b => b !== item)
        : [...prev, item]
    )
  }

  const exportData = (format: 'csv' | 'json' | 'pdf') => {
    setShowExportPanel(true)
  }

  return (
    <div ref={containerRef} className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 overflow-hidden">
      {/* Animated Background */}
      <motion.div 
        className="absolute inset-0 opacity-20"
        style={{ y: backgroundY }}
      >
        <div className="absolute inset-0 bg-gradient-to-br from-purple-900/30 via-transparent to-blue-900/30"></div>
        <div className="absolute top-20 left-20 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-40 right-40 w-80 h-80 bg-blue-500/10 rounded-full blur-3xl animate-pulse delay-1000"></div>
        <div className="absolute top-1/2 left-1/2 w-64 h-64 bg-green-500/10 rounded-full blur-3xl animate-pulse delay-500"></div>
      </motion.div>

      {/* Header */}
      <motion.header 
        className="relative z-50 bg-black/20 backdrop-blur-2xl border-b border-white/10"
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        transition={{ type: "spring", stiffness: 100, damping: 20 }}
      >
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            {/* Logo */}
            <div className="flex items-center space-x-4">
              <motion.div
                className="relative"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <div className="w-12 h-12 bg-gradient-to-r from-purple-500 via-pink-500 to-blue-500 rounded-2xl flex items-center justify-center shadow-lg shadow-purple-500/25">
                  <Sparkles className="w-7 h-7 text-white" />
                </div>
                <div className="absolute inset-0 bg-gradient-to-r from-purple-500 via-pink-500 to-blue-500 rounded-2xl blur-lg opacity-30 animate-pulse"></div>
              </motion.div>
              <div>
                <h1 className="text-2xl font-black text-white">DeFiMon Analytics</h1>
                <p className="text-sm text-gray-400">Professional Financial Intelligence</p>
              </div>
            </div>

            {/* Controls */}
            <div className="flex items-center space-x-4">
              {/* Time Range Selector */}
              <div className="flex bg-gray-800/50 backdrop-blur-sm rounded-2xl p-1 border border-white/10">
                {['1h', '24h', '7d', '30d', '1y'].map((range) => (
                  <motion.button
                    key={range}
                    onClick={() => setTimeRange(range)}
                    className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
                      timeRange === range
                        ? 'bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg shadow-purple-500/25'
                        : 'text-gray-400 hover:text-white'
                    }`}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    {range}
                  </motion.button>
                ))}
              </div>

              {/* Action Buttons */}
              <motion.button
                onClick={() => setShowNotifications(!showNotifications)}
                className="relative p-3 bg-gray-800/50 backdrop-blur-sm hover:bg-gray-700/50 rounded-xl text-white border border-white/10 transition-all"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <Bell className="w-5 h-5" />
                {alerts.length > 0 && (
                  <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 rounded-full text-xs flex items-center justify-center">
                    {alerts.length}
                  </span>
                )}
              </motion.button>

              <motion.button
                onClick={() => setIsFullscreen(!isFullscreen)}
                className="p-3 bg-gray-800/50 backdrop-blur-sm hover:bg-gray-700/50 rounded-xl text-white border border-white/10 transition-all"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                {isFullscreen ? <Minimize2 className="w-5 h-5" /> : <Maximize2 className="w-5 h-5" />}
              </motion.button>

              <motion.button className="p-3 bg-gray-800/50 backdrop-blur-sm hover:bg-gray-700/50 rounded-xl text-white border border-white/10 transition-all">
                <User className="w-5 h-5" />
              </motion.button>
            </div>
          </div>
        </div>
      </motion.header>

      {/* Main Content */}
      <div className={`relative z-10 ${isFullscreen ? 'fixed inset-0 bg-black z-50' : 'pt-6'}`}>
        <div className={`${isFullscreen ? 'h-full' : 'max-w-7xl'} mx-auto px-6`}>
          {/* Tab Navigation */}
          <motion.nav 
            className="mb-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            <div className="flex space-x-2 p-2 bg-black/20 backdrop-blur-2xl rounded-3xl border border-white/10">
              {[
                { id: 'overview', label: 'Overview', icon: BarChart3 },
                { id: 'analytics', label: 'Analytics', icon: TrendingUp },
                { id: 'portfolio', label: 'Portfolio', icon: PieChart },
                { id: 'networks', label: 'Networks', icon: Network },
                { id: 'ai', label: 'AI Insights', icon: Brain },
                { id: 'alerts', label: 'Alerts', icon: Bell },
              ].map((tab) => {
                const Icon = tab.icon
                return (
                  <motion.button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`relative flex items-center space-x-2 px-6 py-3 rounded-2xl font-semibold transition-all ${
                      activeTab === tab.id
                        ? 'text-white'
                        : 'text-gray-400 hover:text-white hover:bg-white/5'
                    }`}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    {activeTab === tab.id && (
                      <motion.div
                        className="absolute inset-0 bg-gradient-to-r from-purple-500 to-blue-500 rounded-2xl opacity-80"
                        layoutId="activeTab"
                        initial={false}
                        transition={{ type: "spring", stiffness: 500, damping: 40 }}
                      />
                    )}
                    <Icon className="w-5 h-5 relative z-10" />
                    <span className="relative z-10">{tab.label}</span>
                  </motion.button>
                )
              })}
            </div>
          </motion.nav>

          {/* Content Area */}
          <AnimatePresence mode="wait">
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
              className="space-y-6"
            >
              {activeTab === 'overview' && (
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                  {/* Key Metrics */}
                  <div className="lg:col-span-2 space-y-6">
                    {/* Price Chart */}
                    <motion.div 
                      className="bg-black/20 backdrop-blur-2xl rounded-3xl p-6 border border-white/10"
                      whileHover={{ scale: 1.02 }}
                      transition={{ type: "spring", stiffness: 300 }}
                    >
                      <div className="flex items-center justify-between mb-6">
                        <div>
                          <h3 className="text-xl font-bold text-white">Price Analysis</h3>
                          <p className="text-gray-400">Real-time price tracking</p>
                        </div>
                        <div className="flex items-center space-x-2">
                          <motion.button
                            onClick={() => toggleBookmark('price-chart')}
                            className={`p-2 rounded-xl transition-all ${
                              bookmarks.includes('price-chart') 
                                ? 'bg-yellow-500/20 text-yellow-400' 
                                : 'bg-gray-800/50 text-gray-400 hover:text-white'
                            }`}
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                          >
                            <Bookmark className="w-4 h-4" />
                          </motion.button>
                          <motion.button
                            onClick={() => exportData('csv')}
                            className="p-2 bg-gray-800/50 text-gray-400 hover:text-white rounded-xl transition-all"
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                          >
                            <Download className="w-4 h-4" />
                          </motion.button>
                        </div>
                      </div>
                      
                      <div className="h-64">
                        <ResponsiveContainer width="100%" height="100%">
                          <AreaChart data={priceData}>
                            <defs>
                              <linearGradient id="priceGradient" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.3}/>
                                <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0}/>
                              </linearGradient>
                            </defs>
                            <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                            <XAxis dataKey="time" stroke="#9ca3af" />
                            <YAxis stroke="#9ca3af" />
                            <Tooltip 
                              contentStyle={{ 
                                backgroundColor: '#1f2937', 
                                border: '1px solid #374151',
                                borderRadius: '12px'
                              }}
                            />
                            <Area 
                              type="monotone" 
                              dataKey="price" 
                              stroke="#8b5cf6" 
                              fill="url(#priceGradient)"
                              strokeWidth={2}
                            />
                          </AreaChart>
                        </ResponsiveContainer>
                      </div>
                    </motion.div>

                    {/* Market Overview */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <motion.div 
                        className="bg-black/20 backdrop-blur-2xl rounded-3xl p-6 border border-white/10"
                        whileHover={{ scale: 1.02 }}
                        transition={{ type: "spring", stiffness: 300 }}
                      >
                        <div className="flex items-center justify-between mb-4">
                          <h4 className="text-lg font-semibold text-white">Market Cap</h4>
                          <TrendingUp className="w-5 h-5 text-green-400" />
                        </div>
                        <div className="text-3xl font-bold text-white mb-2">$295.2B</div>
                        <div className="flex items-center text-green-400 text-sm">
                          <ArrowUpRight className="w-4 h-4 mr-1" />
                          +2.3% (24h)
                        </div>
                      </motion.div>

                      <motion.div 
                        className="bg-black/20 backdrop-blur-2xl rounded-3xl p-6 border border-white/10"
                        whileHover={{ scale: 1.02 }}
                        transition={{ type: "spring", stiffness: 300 }}
                      >
                        <div className="flex items-center justify-between mb-4">
                          <h4 className="text-lg font-semibold text-white">24h Volume</h4>
                          <Activity className="w-5 h-5 text-blue-400" />
                        </div>
                        <div className="text-3xl font-bold text-white mb-2">$1.2B</div>
                        <div className="flex items-center text-red-400 text-sm">
                          <ArrowDownRight className="w-4 h-4 mr-1" />
                          -1.8% (24h)
                        </div>
                      </motion.div>
                    </div>
                  </div>

                  {/* Portfolio Distribution */}
                  <motion.div 
                    className="bg-black/20 backdrop-blur-2xl rounded-3xl p-6 border border-white/10"
                    whileHover={{ scale: 1.02 }}
                    transition={{ type: "spring", stiffness: 300 }}
                  >
                    <div className="flex items-center justify-between mb-6">
                      <h3 className="text-xl font-bold text-white">Portfolio</h3>
                      <motion.button
                        onClick={() => toggleBookmark('portfolio')}
                        className={`p-2 rounded-xl transition-all ${
                          bookmarks.includes('portfolio') 
                            ? 'bg-yellow-500/20 text-yellow-400' 
                            : 'bg-gray-800/50 text-gray-400 hover:text-white'
                        }`}
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        <Bookmark className="w-4 h-4" />
                      </motion.button>
                    </div>
                    
                    <div className="h-48 mb-4">
                      <ResponsiveContainer width="100%" height="100%">
                        <RechartsPieChart>
                          <Pie
                            data={portfolioData}
                            cx="50%"
                            cy="50%"
                            innerRadius={40}
                            outerRadius={80}
                            paddingAngle={5}
                            dataKey="value"
                          >
                            {portfolioData.map((entry, index) => (
                              <Cell key={`cell-${index}`} fill={entry.color} />
                            ))}
                          </Pie>
                          <Tooltip 
                            contentStyle={{ 
                              backgroundColor: '#1f2937', 
                              border: '1px solid #374151',
                              borderRadius: '12px'
                            }}
                          />
                        </RechartsPieChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="space-y-3">
                      {portfolioData.map((item, index) => (
                        <div key={index} className="flex items-center justify-between">
                          <div className="flex items-center space-x-3">
                            <div 
                              className="w-3 h-3 rounded-full" 
                              style={{ backgroundColor: item.color }}
                            />
                            <span className="text-gray-300">{item.name}</span>
                          </div>
                          <span className="text-white font-semibold">{item.value}%</span>
                        </div>
                      ))}
                    </div>
                  </motion.div>
                </div>
              )}

              {activeTab === 'analytics' && (
                <div className="space-y-6">
                  {/* Advanced Analytics */}
                  <motion.div 
                    className="bg-black/20 backdrop-blur-2xl rounded-3xl p-6 border border-white/10"
                    whileHover={{ scale: 1.02 }}
                    transition={{ type: "spring", stiffness: 300 }}
                  >
                    <div className="flex items-center justify-between mb-6">
                      <h3 className="text-xl font-bold text-white">Advanced Analytics</h3>
                      <div className="flex items-center space-x-2">
                        <motion.button className="p-2 bg-gray-800/50 text-gray-400 hover:text-white rounded-xl transition-all">
                          <RefreshCw className="w-4 h-4" />
                        </motion.button>
                        <motion.button className="p-2 bg-gray-800/50 text-gray-400 hover:text-white rounded-xl transition-all">
                          <Settings className="w-4 h-4" />
                        </motion.button>
                      </div>
                    </div>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <div className="h-64">
                        <ResponsiveContainer width="100%" height="100%">
                          <BarChart data={priceData}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                            <XAxis dataKey="time" stroke="#9ca3af" />
                            <YAxis stroke="#9ca3af" />
                            <Tooltip 
                              contentStyle={{ 
                                backgroundColor: '#1f2937', 
                                border: '1px solid #374151',
                                borderRadius: '12px'
                              }}
                            />
                            <Bar dataKey="volume" fill="#8b5cf6" radius={[4, 4, 0, 0]} />
                          </BarChart>
                        </ResponsiveContainer>
                      </div>
                      
                      <div className="space-y-4">
                        <div className="bg-gray-800/30 rounded-2xl p-4">
                          <h4 className="text-lg font-semibold text-white mb-2">Correlation Analysis</h4>
                          <div className="space-y-2">
                            <div className="flex justify-between">
                              <span className="text-gray-400">ETH-BTC</span>
                              <span className="text-white">0.85</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-400">ETH-POLYGON</span>
                              <span className="text-white">0.72</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-400">BTC-ARBITRUM</span>
                              <span className="text-white">0.68</span>
                            </div>
                          </div>
                        </div>
                        
                        <div className="bg-gray-800/30 rounded-2xl p-4">
                          <h4 className="text-lg font-semibold text-white mb-2">Volatility Metrics</h4>
                          <div className="space-y-2">
                            <div className="flex justify-between">
                              <span className="text-gray-400">Current Volatility</span>
                              <span className="text-yellow-400">Medium</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-400">Risk Score</span>
                              <span className="text-green-400">Low</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </motion.div>
                </div>
              )}

              {activeTab === 'networks' && (
                <div className="space-y-6">
                  {/* Network Status */}
                  <motion.div 
                    className="bg-black/20 backdrop-blur-2xl rounded-3xl p-6 border border-white/10"
                    whileHover={{ scale: 1.02 }}
                    transition={{ type: "spring", stiffness: 300 }}
                  >
                    <div className="flex items-center justify-between mb-6">
                      <h3 className="text-xl font-bold text-white">Network Status</h3>
                      <div className="flex items-center space-x-2">
                        <motion.button className="p-2 bg-gray-800/50 text-gray-400 hover:text-white rounded-xl transition-all">
                          <RefreshCw className="w-4 h-4" />
                        </motion.button>
                        <motion.button className="p-2 bg-gray-800/50 text-gray-400 hover:text-white rounded-xl transition-all">
                          <Eye className="w-4 h-4" />
                        </motion.button>
                      </div>
                    </div>
                    
                    <div className="space-y-4">
                      {networkMetrics.map((network, index) => (
                        <motion.div 
                          key={index}
                          className="flex items-center justify-between p-4 bg-gray-800/30 rounded-2xl"
                          whileHover={{ scale: 1.02 }}
                          transition={{ type: "spring", stiffness: 300 }}
                        >
                          <div className="flex items-center space-x-4">
                            <div className={`w-3 h-3 rounded-full ${
                              network.status === 'active' ? 'bg-green-400' :
                              network.status === 'warning' ? 'bg-yellow-400' : 'bg-red-400'
                            }`} />
                            <div>
                              <h4 className="text-white font-semibold">{network.name}</h4>
                              <p className="text-gray-400 text-sm">TVL: ${network.tvl}B</p>
                            </div>
                          </div>
                          <div className="text-right">
                            <div className={`flex items-center text-sm ${
                              network.change >= 0 ? 'text-green-400' : 'text-red-400'
                            }`}>
                              {network.change >= 0 ? (
                                <ArrowUpRight className="w-4 h-4 mr-1" />
                              ) : (
                                <ArrowDownRight className="w-4 h-4 mr-1" />
                              )}
                              {Math.abs(network.change)}%
                            </div>
                          </div>
                        </motion.div>
                      ))}
                    </div>
                  </motion.div>
                </div>
              )}

              {activeTab === 'ai' && (
                <div className="space-y-6">
                  {/* AI Predictions */}
                  <motion.div 
                    className="bg-black/20 backdrop-blur-2xl rounded-3xl p-6 border border-white/10"
                    whileHover={{ scale: 1.02 }}
                    transition={{ type: "spring", stiffness: 300 }}
                  >
                    <div className="flex items-center justify-between mb-6">
                      <h3 className="text-xl font-bold text-white">AI Insights</h3>
                      <div className="flex items-center space-x-2">
                        <Brain className="w-5 h-5 text-purple-400" />
                        <span className="text-gray-400 text-sm">Powered by ML</span>
                      </div>
                    </div>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      {aiPredictions.map((prediction, index) => (
                        <motion.div 
                          key={index}
                          className="bg-gray-800/30 rounded-2xl p-4"
                          whileHover={{ scale: 1.02 }}
                          transition={{ type: "spring", stiffness: 300 }}
                        >
                          <div className="flex items-center justify-between mb-3">
                            <h4 className="text-white font-semibold">{prediction.metric}</h4>
                            <div className={`p-1 rounded-lg ${
                              prediction.trend === 'up' ? 'bg-green-500/20 text-green-400' :
                              prediction.trend === 'down' ? 'bg-red-500/20 text-red-400' :
                              'bg-gray-500/20 text-gray-400'
                            }`}>
                              {prediction.trend === 'up' ? <TrendingUp className="w-4 h-4" /> :
                               prediction.trend === 'down' ? <TrendingDown className="w-4 h-4" /> :
                               <Activity className="w-4 h-4" />}
                            </div>
                          </div>
                          <div className="text-2xl font-bold text-white mb-2">{prediction.value}</div>
                          <div className="flex items-center justify-between">
                            <span className="text-gray-400 text-sm">Confidence</span>
                            <span className="text-white font-semibold">{prediction.confidence}%</span>
                          </div>
                          <div className="w-full bg-gray-700 rounded-full h-2 mt-2">
                            <div 
                              className="bg-gradient-to-r from-purple-500 to-blue-500 h-2 rounded-full"
                              style={{ width: `${prediction.confidence}%` }}
                            />
                          </div>
                        </motion.div>
                      ))}
                    </div>
                  </motion.div>
                </div>
              )}

              {activeTab === 'portfolio' && (
                <div className="space-y-6">
                  {/* Portfolio Overview */}
                  <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    {/* Portfolio Value */}
                    <motion.div 
                      className="lg:col-span-2 bg-black/20 backdrop-blur-2xl rounded-3xl p-6 border border-white/10"
                      whileHover={{ scale: 1.02 }}
                      transition={{ type: "spring", stiffness: 300 }}
                    >
                      <div className="flex items-center justify-between mb-6">
                        <div>
                          <h3 className="text-xl font-bold text-white">Portfolio Performance</h3>
                          <p className="text-gray-400">Total value and performance tracking</p>
                        </div>
                        <div className="flex items-center space-x-2">
                          <motion.button
                            onClick={() => toggleBookmark('portfolio-performance')}
                            className={`p-2 rounded-xl transition-all ${
                              bookmarks.includes('portfolio-performance') 
                                ? 'bg-yellow-500/20 text-yellow-400' 
                                : 'bg-gray-800/50 text-gray-400 hover:text-white'
                            }`}
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                          >
                            <Bookmark className="w-4 h-4" />
                          </motion.button>
                          <motion.button
                            onClick={() => exportData('csv')}
                            className="p-2 bg-gray-800/50 text-gray-400 hover:text-white rounded-xl transition-all"
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                          >
                            <Download className="w-4 h-4" />
                          </motion.button>
                        </div>
                      </div>
                      
                      <div className="h-64">
                        <ResponsiveContainer width="100%" height="100%">
                          <LineChart data={priceData}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                            <XAxis dataKey="time" stroke="#9ca3af" />
                            <YAxis stroke="#9ca3af" />
                            <Tooltip 
                              contentStyle={{ 
                                backgroundColor: '#1f2937', 
                                border: '1px solid #374151',
                                borderRadius: '12px'
                              }}
                            />
                            <Line 
                              type="monotone" 
                              dataKey="price" 
                              stroke="#8b5cf6" 
                              strokeWidth={3}
                              dot={{ fill: '#8b5cf6', strokeWidth: 2, r: 4 }}
                            />
                          </LineChart>
                        </ResponsiveContainer>
                      </div>
                    </motion.div>

                    {/* Portfolio Stats */}
                    <motion.div 
                      className="bg-black/20 backdrop-blur-2xl rounded-3xl p-6 border border-white/10"
                      whileHover={{ scale: 1.02 }}
                      transition={{ type: "spring", stiffness: 300 }}
                    >
                      <h3 className="text-xl font-bold text-white mb-6">Portfolio Stats</h3>
                      
                      <div className="space-y-4">
                        <div className="bg-gray-800/30 rounded-2xl p-4">
                          <div className="flex items-center justify-between mb-2">
                            <span className="text-gray-400 text-sm">Total Value</span>
                            <TrendingUp className="w-4 h-4 text-green-400" />
                          </div>
                          <div className="text-2xl font-bold text-white">$125,430</div>
                          <div className="flex items-center text-green-400 text-sm">
                            <ArrowUpRight className="w-4 h-4 mr-1" />
                            +12.5% (24h)
                          </div>
                        </div>

                        <div className="bg-gray-800/30 rounded-2xl p-4">
                          <div className="flex items-center justify-between mb-2">
                            <span className="text-gray-400 text-sm">Daily P&L</span>
                            <Activity className="w-4 h-4 text-blue-400" />
                          </div>
                          <div className="text-2xl font-bold text-white">+$13,890</div>
                          <div className="flex items-center text-green-400 text-sm">
                            <ArrowUpRight className="w-4 h-4 mr-1" />
                            +12.5%
                          </div>
                        </div>

                        <div className="bg-gray-800/30 rounded-2xl p-4">
                          <div className="flex items-center justify-between mb-2">
                            <span className="text-gray-400 text-sm">Risk Score</span>
                            <Shield className="w-4 h-4 text-yellow-400" />
                          </div>
                          <div className="text-2xl font-bold text-white">6.2/10</div>
                          <div className="text-yellow-400 text-sm">Moderate</div>
                        </div>
                      </div>
                    </motion.div>
                  </div>

                  {/* AI Question Interface */}
                  <motion.div 
                    className="bg-black/20 backdrop-blur-2xl rounded-3xl border border-white/10"
                    whileHover={{ scale: 1.02 }}
                    transition={{ type: "spring", stiffness: 300 }}
                  >
                    <AIQuestionInterface />
                  </motion.div>
                </div>
              )}

              {activeTab === 'alerts' && (
                <div className="space-y-6">
                  {/* Alerts Panel */}
                  <motion.div 
                    className="bg-black/20 backdrop-blur-2xl rounded-3xl p-6 border border-white/10"
                    whileHover={{ scale: 1.02 }}
                    transition={{ type: "spring", stiffness: 300 }}
                  >
                    <div className="flex items-center justify-between mb-6">
                      <h3 className="text-xl font-bold text-white">Active Alerts</h3>
                      <motion.button className="px-4 py-2 bg-purple-500 text-white rounded-xl font-semibold">
                        <Plus className="w-4 h-4 mr-2 inline" />
                        New Alert
                      </motion.button>
                    </div>
                    
                    <div className="space-y-4">
                      {alerts.map((alert) => (
                        <motion.div 
                          key={alert.id}
                          className="flex items-center justify-between p-4 bg-gray-800/30 rounded-2xl"
                          whileHover={{ scale: 1.02 }}
                          transition={{ type: "spring", stiffness: 300 }}
                        >
                          <div className="flex items-center space-x-4">
                            <div className={`p-2 rounded-xl ${
                              alert.severity === 'high' ? 'bg-red-500/20 text-red-400' :
                              alert.severity === 'medium' ? 'bg-yellow-500/20 text-yellow-400' :
                              'bg-blue-500/20 text-blue-400'
                            }`}>
                              {alert.severity === 'high' ? <AlertTriangle className="w-5 h-5" /> :
                               alert.severity === 'medium' ? <Info className="w-5 h-5" /> :
                               <CheckCircle className="w-5 h-5" />}
                            </div>
                            <div>
                              <p className="text-white font-medium">{alert.message}</p>
                              <p className="text-gray-400 text-sm">{alert.time}</p>
                            </div>
                          </div>
                          <div className="flex items-center space-x-2">
                            <motion.button className="p-2 bg-gray-700/50 text-gray-400 hover:text-white rounded-xl transition-all">
                              <Eye className="w-4 h-4" />
                            </motion.button>
                            <motion.button className="p-2 bg-gray-700/50 text-gray-400 hover:text-white rounded-xl transition-all">
                              <XCircle className="w-4 h-4" />
                            </motion.button>
                          </div>
                        </motion.div>
                      ))}
                    </div>
                  </motion.div>
                </div>
              )}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>

             {/* Notifications Panel */}
       <AnimatePresence>
         {showNotifications && (
           <motion.div
             initial={{ opacity: 0, x: 300 }}
             animate={{ opacity: 1, x: 0 }}
             exit={{ opacity: 0, x: 300 }}
             className="fixed top-20 right-6 w-80 bg-black/20 backdrop-blur-2xl rounded-3xl p-6 border border-white/10 z-50"
           >
             <div className="flex items-center justify-between mb-4">
               <h3 className="text-lg font-bold text-white">Notifications</h3>
               <motion.button
                 onClick={() => setShowNotifications(false)}
                 className="p-1 text-gray-400 hover:text-white"
                 whileHover={{ scale: 1.1 }}
                 whileTap={{ scale: 0.9 }}
               >
                 <XCircle className="w-5 h-5" />
               </motion.button>
             </div>
             <div className="space-y-3">
               {alerts.map((alert) => (
                 <div key={alert.id} className="p-3 bg-gray-800/30 rounded-2xl">
                   <p className="text-white text-sm">{alert.message}</p>
                   <p className="text-gray-400 text-xs mt-1">{alert.time}</p>
                 </div>
               ))}
             </div>
           </motion.div>
         )}
       </AnimatePresence>

       {/* Data Export Panel */}
       <DataExportPanel isOpen={showExportPanel} onClose={() => setShowExportPanel(false)} />
     </div>
   )
 }
