'use client'

import { motion, AnimatePresence } from 'framer-motion'
import { useState, useEffect, useRef, useCallback } from 'react'
import { 
  Brain,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  Shield,
  BarChart3,
  PieChart,
  LineChart,
  Activity,
  Zap,
  Target,
  Eye,
  Search,
  Filter,
  Download,
  Share2,
  RefreshCw,
  Clock,
  DollarSign,
  Users,
  Globe,
  Cpu,
  Database,
  Network,
  Layers,
  ArrowUpRight,
  ArrowDownRight,
  Minus,
  CheckCircle,
  XCircle,
  Info,
  Settings,
  Maximize2,
  Minimize2
} from 'lucide-react'

interface AnalysisData {
  riskMetrics: {
    overallRisk: number
    smartContractRisk: number
    liquidityRisk: number
    marketRisk: number
    governanceRisk: number
    counterpartyRisk: number
    riskFactors: string[]
  }
  predictions: {
    pricePrediction: number
    confidenceScore: number
    timeframe: string
    modelVersion: string
    features: string[]
  }
  marketAnalysis: {
    correlationMatrix: number[][]
    volatilityIndex: number
    marketSentiment: 'bullish' | 'bearish' | 'neutral'
    keyMetrics: {
      sharpeRatio: number
      beta: number
      alpha: number
      maxDrawdown: number
    }
  }
  protocolInsights: {
    tvlTrend: 'up' | 'down' | 'stable'
    volumeGrowth: number
    userGrowth: number
    feeRevenue: number
    efficiencyScore: number
  }
}

interface DeepAnalysisPanelProps {
  protocolId?: string
  timeframe?: '1h' | '24h' | '7d' | '30d' | '90d'
}

const DeepAnalysisPanel = ({ protocolId, timeframe = '7d' }: DeepAnalysisPanelProps) => {
  const [analysisData, setAnalysisData] = useState<AnalysisData | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [selectedMetric, setSelectedMetric] = useState<string>('risk')
  const [timeRange, setTimeRange] = useState(timeframe)
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date())
  
  const containerRef = useRef<HTMLDivElement>(null)

  // Mock data for demonstration - replace with real API calls
  const mockAnalysisData: AnalysisData = {
    riskMetrics: {
      overallRisk: 0.35,
      smartContractRisk: 0.25,
      liquidityRisk: 0.45,
      marketRisk: 0.30,
      governanceRisk: 0.20,
      counterpartyRisk: 0.40,
      riskFactors: [
        'High volatility in token price',
        'Concentration of liquidity in few pools',
        'Recent smart contract upgrades',
        'Regulatory uncertainty in DeFi space'
      ]
    },
    predictions: {
      pricePrediction: 2450.50,
      confidenceScore: 0.78,
      timeframe: '7d',
      modelVersion: 'v2.1.0',
      features: [
        'Historical price patterns',
        'TVL correlation',
        'Volume momentum',
        'Market sentiment analysis',
        'On-chain activity metrics'
      ]
    },
    marketAnalysis: {
      correlationMatrix: [
        [1.0, 0.85, 0.72, 0.68],
        [0.85, 1.0, 0.78, 0.75],
        [0.72, 0.78, 1.0, 0.82],
        [0.68, 0.75, 0.82, 1.0]
      ],
      volatilityIndex: 0.42,
      marketSentiment: 'bullish' as const,
      keyMetrics: {
        sharpeRatio: 1.85,
        beta: 0.92,
        alpha: 0.15,
        maxDrawdown: -0.18
      }
    },
    protocolInsights: {
      tvlTrend: 'up' as const,
      volumeGrowth: 0.23,
      userGrowth: 0.15,
      feeRevenue: 1250000,
      efficiencyScore: 0.88
    }
  }

  const fetchAnalysisData = useCallback(async () => {
    setIsLoading(true)
    try {
      // Simulate API call delay
      await new Promise(resolve => setTimeout(resolve, 1500))
      
      // In real implementation, fetch from API
      // const response = await fetch(`/api/analytics/deep-analysis?protocolId=${protocolId}&timeframe=${timeRange}`)
      // const data = await response.json()
      
      setAnalysisData(mockAnalysisData)
      setLastUpdate(new Date())
    } catch (error) {
      console.error('Error fetching analysis data:', error)
    } finally {
      setIsLoading(false)
    }
  }, [protocolId, timeRange])

  useEffect(() => {
    fetchAnalysisData()
  }, [fetchAnalysisData])

  const getRiskColor = (risk: number) => {
    if (risk < 0.3) return 'text-green-400'
    if (risk < 0.6) return 'text-yellow-400'
    return 'text-red-400'
  }

  const getRiskLevel = (risk: number) => {
    if (risk < 0.3) return 'Low'
    if (risk < 0.6) return 'Medium'
    return 'High'
  }

  const getSentimentColor = (sentiment: string) => {
    switch (sentiment) {
      case 'bullish': return 'text-green-400'
      case 'bearish': return 'text-red-400'
      default: return 'text-yellow-400'
    }
  }

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return <ArrowUpRight className="w-4 h-4 text-green-400" />
      case 'down': return <ArrowDownRight className="w-4 h-4 text-red-400" />
      default: return <Minus className="w-4 h-4 text-gray-400" />
    }
  }

  const metrics = [
    { key: 'risk', label: 'Risk Analysis', icon: Shield, color: 'from-red-500 to-orange-500' },
    { key: 'predictions', label: 'AI Predictions', icon: Brain, color: 'from-purple-500 to-pink-500' },
    { key: 'market', label: 'Market Analysis', icon: BarChart3, color: 'from-blue-500 to-cyan-500' },
    { key: 'insights', label: 'Protocol Insights', icon: Eye, color: 'from-green-500 to-emerald-500' }
  ]

  return (
    <div ref={containerRef} className={`relative bg-gradient-to-br from-gray-900 via-gray-800 to-black rounded-3xl overflow-hidden ${isFullscreen ? 'fixed inset-0 z-50' : ''}`}>
      {/* Header */}
      <div className="relative z-20 p-6 border-b border-white/10">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="p-3 bg-gradient-to-r from-purple-500 to-pink-500 rounded-2xl">
              <Brain className="w-6 h-6 text-white" />
            </div>
            <div>
              <h2 className="text-2xl font-bold text-white">Deep Analysis</h2>
              <p className="text-gray-400">Advanced AI-powered insights and risk assessment</p>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            {/* Time Range Selector */}
            <div className="flex bg-gray-800/50 rounded-xl p-1">
              {['1h', '24h', '7d', '30d', '90d'].map((range) => (
                <motion.button
                  key={range}
                  onClick={() => setTimeRange(range as any)}
                  className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                    timeRange === range
                      ? 'bg-gradient-to-r from-purple-500 to-pink-500 text-white shadow-lg'
                      : 'text-gray-400 hover:text-white hover:bg-gray-700'
                  }`}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  {range}
                </motion.button>
              ))}
            </div>

            {/* Refresh Button */}
            <motion.button
              onClick={fetchAnalysisData}
              disabled={isLoading}
              className={`p-3 rounded-xl transition-all ${
                isLoading
                  ? 'bg-gray-700 text-gray-400'
                  : 'bg-blue-500/20 text-blue-400 hover:bg-blue-500/30'
              }`}
              whileHover={{ scale: isLoading ? 1 : 1.05 }}
              whileTap={{ scale: isLoading ? 1 : 0.95 }}
            >
              <RefreshCw className={`w-5 h-5 ${isLoading ? 'animate-spin' : ''}`} />
            </motion.button>

            {/* Fullscreen Toggle */}
            <motion.button
              onClick={() => setIsFullscreen(!isFullscreen)}
              className="p-3 bg-gray-800/50 text-gray-400 hover:text-white hover:bg-gray-700 rounded-xl transition-all"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              {isFullscreen ? <Minimize2 className="w-5 h-5" /> : <Maximize2 className="w-5 h-5" />}
            </motion.button>
          </div>
        </div>

        {/* Last Update */}
        <div className="mt-4 text-sm text-gray-400">
          Last updated: {lastUpdate.toLocaleString()}
        </div>
      </div>

      {/* Loading State */}
      <AnimatePresence>
        {isLoading && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 bg-gray-900/80 backdrop-blur-sm z-30 flex items-center justify-center"
          >
            <div className="text-center">
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
                className="w-12 h-12 border-4 border-purple-500 border-t-transparent rounded-full mx-auto mb-4"
              />
              <p className="text-white font-medium">Analyzing data...</p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main Content */}
      <div className="p-6">
        {/* Metric Navigation */}
        <div className="flex space-x-2 mb-8 overflow-x-auto">
          {metrics.map((metric) => {
            const Icon = metric.icon
            return (
              <motion.button
                key={metric.key}
                onClick={() => setSelectedMetric(metric.key)}
                className={`flex items-center space-x-3 px-6 py-4 rounded-2xl font-semibold transition-all whitespace-nowrap ${
                  selectedMetric === metric.key
                    ? 'text-white shadow-2xl'
                    : 'text-gray-400 hover:text-white hover:bg-white/5'
                }`}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                {selectedMetric === metric.key && (
                  <motion.div
                    className={`absolute inset-0 bg-gradient-to-r ${metric.color} rounded-2xl opacity-80`}
                    layoutId="selectedMetric"
                    initial={false}
                    transition={{ type: "spring", stiffness: 500, damping: 40 }}
                  />
                )}
                <Icon className="w-6 h-6 relative z-10" />
                <div className="relative z-10">
                  <div className="font-bold text-sm">{metric.label}</div>
                </div>
              </motion.button>
            )
          })}
        </div>

        {/* Analysis Content */}
        <AnimatePresence mode="wait">
          <motion.div
            key={selectedMetric}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.3 }}
            className="space-y-8"
          >
            {selectedMetric === 'risk' && analysisData && (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                {/* Risk Overview */}
                <div className="bg-gray-800/50 rounded-2xl p-6 border border-white/10">
                  <h3 className="text-xl font-bold text-white mb-6 flex items-center space-x-2">
                    <Shield className="w-6 h-6 text-red-400" />
                    <span>Risk Assessment</span>
                  </h3>
                  
                  <div className="space-y-6">
                    {/* Overall Risk */}
                    <div>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-gray-400">Overall Risk</span>
                        <span className={`font-bold ${getRiskColor(analysisData.riskMetrics.overallRisk)}`}>
                          {getRiskLevel(analysisData.riskMetrics.overallRisk)}
                        </span>
                      </div>
                      <div className="w-full bg-gray-700 rounded-full h-3">
                        <motion.div
                          className="bg-gradient-to-r from-red-500 to-orange-500 h-3 rounded-full"
                          initial={{ width: 0 }}
                          animate={{ width: `${analysisData.riskMetrics.overallRisk * 100}%` }}
                          transition={{ duration: 1, delay: 0.2 }}
                        />
                      </div>
                    </div>

                    {/* Risk Categories */}
                    <div className="grid grid-cols-2 gap-4">
                      {[
                        { key: 'smartContractRisk', label: 'Smart Contract', icon: Cpu },
                        { key: 'liquidityRisk', label: 'Liquidity', icon: DollarSign },
                        { key: 'marketRisk', label: 'Market', icon: TrendingUp },
                        { key: 'governanceRisk', label: 'Governance', icon: Users },
                        { key: 'counterpartyRisk', label: 'Counterparty', icon: Network }
                      ].map((risk) => {
                        const Icon = risk.icon
                        const value = analysisData.riskMetrics[risk.key as keyof typeof analysisData.riskMetrics] as number
                        return (
                          <div key={risk.key} className="bg-gray-700/50 rounded-lg p-4">
                            <div className="flex items-center space-x-2 mb-2">
                              <Icon className="w-4 h-4 text-gray-400" />
                              <span className="text-sm text-gray-400">{risk.label}</span>
                            </div>
                            <div className="flex items-center justify-between">
                              <div className="w-full bg-gray-600 rounded-full h-2 mr-3">
                                <motion.div
                                  className={`h-2 rounded-full ${
                                    value < 0.3 ? 'bg-green-500' : value < 0.6 ? 'bg-yellow-500' : 'bg-red-500'
                                  }`}
                                  initial={{ width: 0 }}
                                  animate={{ width: `${value * 100}%` }}
                                  transition={{ duration: 1, delay: 0.3 }}
                                />
                              </div>
                              <span className={`text-sm font-bold ${getRiskColor(value)}`}>
                                {(value * 100).toFixed(0)}%
                              </span>
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  </div>
                </div>

                {/* Risk Factors */}
                <div className="bg-gray-800/50 rounded-2xl p-6 border border-white/10">
                  <h3 className="text-xl font-bold text-white mb-6 flex items-center space-x-2">
                    <AlertTriangle className="w-6 h-6 text-yellow-400" />
                    <span>Risk Factors</span>
                  </h3>
                  
                  <div className="space-y-4">
                    {analysisData.riskMetrics.riskFactors.map((factor, index) => (
                      <motion.div
                        key={index}
                        initial={{ opacity: 0, x: 20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: index * 0.1 }}
                        className="flex items-start space-x-3 p-4 bg-gray-700/50 rounded-lg"
                      >
                        <div className="w-2 h-2 bg-yellow-400 rounded-full mt-2 flex-shrink-0"></div>
                        <p className="text-gray-300 text-sm">{factor}</p>
                      </motion.div>
                    ))}
                  </div>

                  {/* Risk Mitigation */}
                  <div className="mt-6 p-4 bg-green-500/10 border border-green-500/20 rounded-lg">
                    <h4 className="text-green-400 font-semibold mb-2 flex items-center space-x-2">
                      <CheckCircle className="w-4 h-4" />
                      <span>Risk Mitigation</span>
                    </h4>
                    <p className="text-green-300 text-sm">
                      Consider diversifying across multiple protocols and implementing stop-loss strategies to manage exposure.
                    </p>
                  </div>
                </div>
              </div>
            )}

            {selectedMetric === 'predictions' && analysisData && (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                {/* Price Prediction */}
                <div className="bg-gray-800/50 rounded-2xl p-6 border border-white/10">
                  <h3 className="text-xl font-bold text-white mb-6 flex items-center space-x-2">
                    <Brain className="w-6 h-6 text-purple-400" />
                    <span>AI Price Prediction</span>
                  </h3>
                  
                  <div className="text-center mb-6">
                    <div className="text-4xl font-bold text-white mb-2">
                      ${analysisData.predictions.pricePrediction.toLocaleString()}
                    </div>
                    <div className="text-gray-400">Predicted price in {analysisData.predictions.timeframe}</div>
                  </div>

                  <div className="space-y-4">
                    <div className="flex items-center justify-between p-4 bg-gray-700/50 rounded-lg">
                      <span className="text-gray-400">Confidence Score</span>
                      <div className="flex items-center space-x-2">
                        <div className="w-20 bg-gray-600 rounded-full h-2">
                          <motion.div
                            className="bg-gradient-to-r from-purple-500 to-pink-500 h-2 rounded-full"
                            initial={{ width: 0 }}
                            animate={{ width: `${analysisData.predictions.confidenceScore * 100}%` }}
                            transition={{ duration: 1 }}
                          />
                        </div>
                        <span className="text-white font-bold">
                          {(analysisData.predictions.confidenceScore * 100).toFixed(0)}%
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center justify-between p-4 bg-gray-700/50 rounded-lg">
                      <span className="text-gray-400">Model Version</span>
                      <span className="text-white font-mono">{analysisData.predictions.modelVersion}</span>
                    </div>
                  </div>
                </div>

                {/* Model Features */}
                <div className="bg-gray-800/50 rounded-2xl p-6 border border-white/10">
                  <h3 className="text-xl font-bold text-white mb-6 flex items-center space-x-2">
                    <Settings className="w-6 h-6 text-blue-400" />
                    <span>Model Features</span>
                  </h3>
                  
                  <div className="space-y-3">
                    {analysisData.predictions.features.map((feature, index) => (
                      <motion.div
                        key={index}
                        initial={{ opacity: 0, x: 20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: index * 0.1 }}
                        className="flex items-center space-x-3 p-3 bg-gray-700/50 rounded-lg"
                      >
                        <div className="w-2 h-2 bg-blue-400 rounded-full"></div>
                        <span className="text-gray-300 text-sm">{feature}</span>
                      </motion.div>
                    ))}
                  </div>

                  <div className="mt-6 p-4 bg-blue-500/10 border border-blue-500/20 rounded-lg">
                    <h4 className="text-blue-400 font-semibold mb-2">Model Performance</h4>
                    <p className="text-blue-300 text-sm">
                      This model has achieved 78% accuracy in price predictions over the last 30 days.
                    </p>
                  </div>
                </div>
              </div>
            )}

            {selectedMetric === 'market' && analysisData && (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                {/* Market Sentiment */}
                <div className="bg-gray-800/50 rounded-2xl p-6 border border-white/10">
                  <h3 className="text-xl font-bold text-white mb-6 flex items-center space-x-2">
                    <TrendingUp className="w-6 h-6 text-green-400" />
                    <span>Market Analysis</span>
                  </h3>
                  
                  <div className="space-y-6">
                    <div className="text-center p-6 bg-gray-700/50 rounded-lg">
                      <div className="text-2xl font-bold text-white mb-2">
                        Market Sentiment
                      </div>
                      <div className={`text-4xl font-bold ${getSentimentColor(analysisData.marketAnalysis.marketSentiment)}`}>
                        {analysisData.marketAnalysis.marketSentiment.toUpperCase()}
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div className="bg-gray-700/50 rounded-lg p-4">
                        <div className="text-gray-400 text-sm mb-1">Volatility Index</div>
                        <div className="text-2xl font-bold text-white">
                          {(analysisData.marketAnalysis.volatilityIndex * 100).toFixed(1)}%
                        </div>
                      </div>
                      <div className="bg-gray-700/50 rounded-lg p-4">
                        <div className="text-gray-400 text-sm mb-1">Sharpe Ratio</div>
                        <div className="text-2xl font-bold text-white">
                          {analysisData.marketAnalysis.keyMetrics.sharpeRatio.toFixed(2)}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Key Metrics */}
                <div className="bg-gray-800/50 rounded-2xl p-6 border border-white/10">
                  <h3 className="text-xl font-bold text-white mb-6 flex items-center space-x-2">
                    <BarChart3 className="w-6 h-6 text-cyan-400" />
                    <span>Key Metrics</span>
                  </h3>
                  
                  <div className="space-y-4">
                    {[
                      { label: 'Beta', value: analysisData.marketAnalysis.keyMetrics.beta, color: 'text-blue-400' },
                      { label: 'Alpha', value: analysisData.marketAnalysis.keyMetrics.alpha, color: 'text-green-400' },
                      { label: 'Max Drawdown', value: analysisData.marketAnalysis.keyMetrics.maxDrawdown, color: 'text-red-400' }
                    ].map((metric) => (
                      <div key={metric.label} className="flex items-center justify-between p-4 bg-gray-700/50 rounded-lg">
                        <span className="text-gray-400">{metric.label}</span>
                        <span className={`font-bold ${metric.color}`}>
                          {metric.value > 0 ? '+' : ''}{metric.value.toFixed(3)}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {selectedMetric === 'insights' && analysisData && (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                {/* Protocol Performance */}
                <div className="bg-gray-800/50 rounded-2xl p-6 border border-white/10">
                  <h3 className="text-xl font-bold text-white mb-6 flex items-center space-x-2">
                    <Eye className="w-6 h-6 text-emerald-400" />
                    <span>Protocol Insights</span>
                  </h3>
                  
                  <div className="space-y-6">
                    <div className="grid grid-cols-2 gap-4">
                      <div className="bg-gray-700/50 rounded-lg p-4">
                        <div className="flex items-center space-x-2 mb-2">
                          <DollarSign className="w-4 h-4 text-green-400" />
                          <span className="text-gray-400 text-sm">TVL Trend</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          {getTrendIcon(analysisData.protocolInsights.tvlTrend)}
                          <span className="text-white font-bold">Growing</span>
                        </div>
                      </div>

                      <div className="bg-gray-700/50 rounded-lg p-4">
                        <div className="flex items-center space-x-2 mb-2">
                          <Users className="w-4 h-4 text-blue-400" />
                          <span className="text-gray-400 text-sm">User Growth</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <ArrowUpRight className="w-4 h-4 text-green-400" />
                          <span className="text-white font-bold">+{(analysisData.protocolInsights.userGrowth * 100).toFixed(1)}%</span>
                        </div>
                      </div>
                    </div>

                    <div className="bg-gray-700/50 rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-gray-400">Efficiency Score</span>
                        <span className="text-white font-bold">
                          {(analysisData.protocolInsights.efficiencyScore * 100).toFixed(0)}%
                        </span>
                      </div>
                      <div className="w-full bg-gray-600 rounded-full h-3">
                        <motion.div
                          className="bg-gradient-to-r from-green-500 to-emerald-500 h-3 rounded-full"
                          initial={{ width: 0 }}
                          animate={{ width: `${analysisData.protocolInsights.efficiencyScore * 100}%` }}
                          transition={{ duration: 1 }}
                        />
                      </div>
                    </div>
                  </div>
                </div>

                {/* Revenue Analysis */}
                <div className="bg-gray-800/50 rounded-2xl p-6 border border-white/10">
                  <h3 className="text-xl font-bold text-white mb-6 flex items-center space-x-2">
                    <TrendingUp className="w-6 h-6 text-purple-400" />
                    <span>Revenue Analysis</span>
                  </h3>
                  
                  <div className="space-y-4">
                    <div className="text-center p-6 bg-gray-700/50 rounded-lg">
                      <div className="text-2xl font-bold text-white mb-2">
                        Fee Revenue
                      </div>
                      <div className="text-4xl font-bold text-green-400">
                        ${(analysisData.protocolInsights.feeRevenue / 1000000).toFixed(2)}M
                      </div>
                      <div className="text-gray-400 text-sm">Last 30 days</div>
                    </div>

                    <div className="bg-gray-700/50 rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-gray-400">Volume Growth</span>
                        <span className="text-white font-bold">
                          +{(analysisData.protocolInsights.volumeGrowth * 100).toFixed(1)}%
                        </span>
                      </div>
                      <div className="w-full bg-gray-600 rounded-full h-2">
                        <motion.div
                          className="bg-gradient-to-r from-blue-500 to-cyan-500 h-2 rounded-full"
                          initial={{ width: 0 }}
                          animate={{ width: `${Math.min(analysisData.protocolInsights.volumeGrowth * 100, 100)}%` }}
                          transition={{ duration: 1 }}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  )
}

export default DeepAnalysisPanel
