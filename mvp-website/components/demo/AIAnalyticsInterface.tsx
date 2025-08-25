'use client'

import { motion, AnimatePresence } from 'framer-motion'
import { useState, useEffect, useRef } from 'react'
import { 
  Brain,
  Cpu,
  Target,
  TrendingUp,
  TrendingDown,
  Zap,
  Eye,
  Bot,
  Sparkles,
  Activity,
  AlertTriangle,
  CheckCircle,
  Clock,
  ChevronDown,
  ChevronUp,
  PlayCircle,
  PauseCircle
} from 'lucide-react'

interface Prediction {
  id: string
  asset: string
  timeframe: string
  prediction: 'bullish' | 'bearish' | 'neutral'
  confidence: number
  priceTarget: string
  currentPrice: string
  reasoning: string[]
  accuracy: number
  status: 'active' | 'completed' | 'pending'
}

interface AIInsight {
  type: 'risk' | 'opportunity' | 'alert' | 'trend'
  title: string
  description: string
  impact: 'high' | 'medium' | 'low'
  confidence: number
  action?: string
}

const AIAnalyticsInterface = () => {
  const [activeTab, setActiveTab] = useState<'predictions' | 'insights' | 'analysis'>('predictions')
  const [aiStatus, setAiStatus] = useState<'processing' | 'idle' | 'learning'>('processing')
  const [expandedPrediction, setExpandedPrediction] = useState<string | null>(null)
  const [realTimeMode, setRealTimeMode] = useState(true)
  const [processingStep, setProcessingStep] = useState(0)

  const canvasRef = useRef<HTMLCanvasElement>(null)

  const predictions: Prediction[] = [
    {
      id: '1',
      asset: 'ETH',
      timeframe: '24h',
      prediction: 'bullish',
      confidence: 87,
      priceTarget: '$2,450',
      currentPrice: '$2,380',
      reasoning: [
        'Strong institutional inflows detected',
        'Network activity increasing 23%',
        'Technical indicators showing bullish divergence',
        'L2 adoption metrics improving'
      ],
      accuracy: 91,
      status: 'active'
    },
    {
      id: '2',
      asset: 'ARB',
      timeframe: '7d',
      prediction: 'bullish',
      confidence: 94,
      priceTarget: '$1.85',
      currentPrice: '$1.62',
      reasoning: [
        'Major protocol upgrades scheduled',
        'TVL growth acceleration',
        'Ecosystem expansion signals',
        'Reduced selling pressure'
      ],
      accuracy: 88,
      status: 'active'
    },
    {
      id: '3',
      asset: 'MATIC',
      timeframe: '3d',
      prediction: 'neutral',
      confidence: 73,
      priceTarget: '$0.82',
      currentPrice: '$0.79',
      reasoning: [
        'Mixed market signals',
        'Sideways consolidation pattern',
        'Awaiting major announcements',
        'Moderate trading volume'
      ],
      accuracy: 85,
      status: 'pending'
    }
  ]

  const insights: AIInsight[] = [
    {
      type: 'opportunity',
      title: 'Arbitrum Ecosystem Growth',
      description: 'AI detected 340% increase in new project deployments',
      impact: 'high',
      confidence: 92,
      action: 'Consider ARB exposure'
    },
    {
      type: 'risk',
      title: 'Market Correlation Risk',
      description: 'High correlation between L2 tokens indicates systematic risk',
      impact: 'medium',
      confidence: 78,
      action: 'Diversify holdings'
    },
    {
      type: 'trend',
      title: 'DeFi TVL Recovery',
      description: 'Machine learning models show sustained TVL growth trend',
      impact: 'high',
      confidence: 89
    },
    {
      type: 'alert',
      title: 'Unusual Whale Activity',
      description: 'Large wallet movements detected across multiple networks',
      impact: 'medium',
      confidence: 95,
      action: 'Monitor closely'
    }
  ]

  const processingSteps = [
    'Analyzing market data...',
    'Processing on-chain metrics...',
    'Running ML models...',
    'Calculating predictions...',
    'Validating results...',
    'Generating insights...'
  ]

  // Animate neural network background
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const ctx = canvas.getContext('2d')
    if (!ctx) return

    canvas.width = canvas.offsetWidth
    canvas.height = canvas.offsetHeight

    const nodes = Array.from({ length: 20 }, () => ({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height,
      vx: (Math.random() - 0.5) * 0.5,
      vy: (Math.random() - 0.5) * 0.5,
      connections: []
    }))

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      
      // Update nodes
      nodes.forEach(node => {
        node.x += node.vx
        node.y += node.vy

        if (node.x <= 0 || node.x >= canvas.width) node.vx *= -1
        if (node.y <= 0 || node.y >= canvas.height) node.vy *= -1
      })

      // Draw connections
      ctx.strokeStyle = 'rgba(139, 92, 246, 0.1)'
      ctx.lineWidth = 0.5
      
      for (let i = 0; i < nodes.length; i++) {
        for (let j = i + 1; j < nodes.length; j++) {
          const dx = nodes[i].x - nodes[j].x
          const dy = nodes[i].y - nodes[j].y
          const distance = Math.sqrt(dx * dx + dy * dy)
          
          if (distance < 150) {
            ctx.beginPath()
            ctx.moveTo(nodes[i].x, nodes[i].y)
            ctx.lineTo(nodes[j].x, nodes[j].y)
            ctx.stroke()
          }
        }
      }

      // Draw nodes
      ctx.fillStyle = 'rgba(139, 92, 246, 0.3)'
      nodes.forEach(node => {
        ctx.beginPath()
        ctx.arc(node.x, node.y, 2, 0, Math.PI * 2)
        ctx.fill()
      })

      requestAnimationFrame(animate)
    }

    animate()
  }, [])

  // Processing animation
  useEffect(() => {
    if (aiStatus === 'processing') {
      const interval = setInterval(() => {
        setProcessingStep(prev => (prev + 1) % processingSteps.length)
      }, 1500)
      return () => clearInterval(interval)
    }
  }, [aiStatus])

  const getInsightIcon = (type: string) => {
    switch (type) {
      case 'risk': return AlertTriangle
      case 'opportunity': return Target
      case 'trend': return TrendingUp
      case 'alert': return Eye
      default: return Sparkles
    }
  }

  const getInsightColor = (type: string) => {
    switch (type) {
      case 'risk': return 'from-red-500 to-orange-500'
      case 'opportunity': return 'from-green-500 to-emerald-500'
      case 'trend': return 'from-blue-500 to-purple-500'
      case 'alert': return 'from-yellow-500 to-amber-500'
      default: return 'from-gray-500 to-gray-600'
    }
  }

  return (
    <div className="relative">
      {/* Neural Network Background */}
      <canvas
        ref={canvasRef}
        className="absolute inset-0 w-full h-full opacity-30 neural-canvas"
      />

      {/* Header */}
      <div className="relative z-10 mb-8">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <motion.div
              className="p-4 bg-gradient-to-r from-purple-500 to-pink-600 rounded-2xl shadow-lg shadow-purple-500/25"
              animate={{ 
                rotate: aiStatus === 'processing' ? 360 : 0,
                scale: aiStatus === 'processing' ? [1, 1.1, 1] : 1
              }}
              transition={{ 
                duration: 2,
                repeat: aiStatus === 'processing' ? Infinity : 0,
                ease: "linear"
              }}
            >
              <Brain className="w-8 h-8 text-white" />
            </motion.div>
            
            <div>
              <h2 className="text-3xl font-black text-white mb-1">AI Analytics Engine</h2>
              <div className="flex items-center space-x-3">
                <div className={`flex items-center space-x-2 px-3 py-1 rounded-full text-sm font-medium ${
                  aiStatus === 'processing' ? 'bg-blue-500/20 text-blue-400' :
                  aiStatus === 'learning' ? 'bg-purple-500/20 text-purple-400' :
                  'bg-green-500/20 text-green-400'
                }`}>
                  <div className={`w-2 h-2 rounded-full ${
                    aiStatus === 'processing' ? 'bg-blue-400 animate-pulse' :
                    aiStatus === 'learning' ? 'bg-purple-400 animate-pulse' :
                    'bg-green-400'
                  }`}></div>
                  <span className="capitalize">{aiStatus}</span>
                </div>
                
                {aiStatus === 'processing' && (
                  <motion.div
                    className="text-sm text-gray-400"
                    key={processingStep}
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -20 }}
                  >
                    {processingSteps[processingStep]}
                  </motion.div>
                )}
              </div>
            </div>
          </div>
          
          <div className="flex items-center space-x-3">
            <motion.button
              onClick={() => setRealTimeMode(!realTimeMode)}
              className={`flex items-center space-x-2 px-4 py-2 rounded-xl font-medium transition-all ${
                realTimeMode
                  ? 'bg-gradient-to-r from-green-500 to-emerald-600 text-white shadow-lg shadow-green-500/25'
                  : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
              }`}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              {realTimeMode ? <PlayCircle className="w-4 h-4" /> : <PauseCircle className="w-4 h-4" />}
              <span>{realTimeMode ? 'Live' : 'Paused'}</span>
            </motion.button>
            
            <select
              title="AI Status Mode"
              className="bg-gray-800 text-white px-4 py-2 rounded-xl border border-gray-700 focus:border-purple-500 outline-none"
              onChange={(e) => setAiStatus(e.target.value as any)}
            >
              <option value="processing">Processing</option>
              <option value="idle">Idle</option>
              <option value="learning">Learning</option>
            </select>
          </div>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="relative z-10 mb-8">
        <div className="flex space-x-1 bg-gray-800/50 rounded-2xl p-1">
          {[
            { key: 'predictions', label: 'AI Predictions', icon: Target },
            { key: 'insights', label: 'Market Insights', icon: Sparkles },
            { key: 'analysis', label: 'Deep Analysis', icon: Cpu }
          ].map((tab) => (
            <motion.button
              key={tab.key}
              onClick={() => setActiveTab(tab.key as any)}
              className={`flex items-center space-x-2 px-6 py-3 rounded-xl font-medium transition-all ${
                activeTab === tab.key
                  ? 'bg-gradient-to-r from-purple-500 to-pink-600 text-white shadow-lg shadow-purple-500/25'
                  : 'text-gray-400 hover:text-white hover:bg-gray-700'
              }`}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <tab.icon className="w-5 h-5" />
              <span>{tab.label}</span>
            </motion.button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="relative z-10">
        <AnimatePresence mode="wait">
          {activeTab === 'predictions' && (
            <motion.div
              key="predictions"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              {predictions.map((prediction, index) => (
                <motion.div
                  key={prediction.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className={`p-6 rounded-2xl backdrop-blur-xl border transition-all duration-300 cursor-pointer ${
                    expandedPrediction === prediction.id
                      ? 'bg-white/15 border-white/30 shadow-2xl'
                      : 'bg-white/5 border-white/10 hover:bg-white/10'
                  }`}
                  onClick={() => setExpandedPrediction(
                    expandedPrediction === prediction.id ? null : prediction.id
                  )}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4">
                      <div className={`px-3 py-1 rounded-full text-sm font-bold ${
                        prediction.prediction === 'bullish' ? 'bg-green-500/20 text-green-400' :
                        prediction.prediction === 'bearish' ? 'bg-red-500/20 text-red-400' :
                        'bg-yellow-500/20 text-yellow-400'
                      }`}>
                        {prediction.asset}
                      </div>
                      
                      <div className="flex items-center space-x-2">
                        {prediction.prediction === 'bullish' ? (
                          <TrendingUp className="w-5 h-5 text-green-400" />
                        ) : prediction.prediction === 'bearish' ? (
                          <TrendingDown className="w-5 h-5 text-red-400" />
                        ) : (
                          <Activity className="w-5 h-5 text-yellow-400" />
                        )}
                        <span className={`font-medium ${
                          prediction.prediction === 'bullish' ? 'text-green-400' :
                          prediction.prediction === 'bearish' ? 'text-red-400' :
                          'text-yellow-400'
                        }`}>
                          {prediction.prediction.toUpperCase()}
                        </span>
                      </div>
                      
                      <div className="text-white font-mono">
                        {prediction.currentPrice} → {prediction.priceTarget}
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-4">
                      <div className="text-center">
                        <div className="text-2xl font-bold text-purple-400">
                          {prediction.confidence}%
                        </div>
                        <div className="text-xs text-gray-400">Confidence</div>
                      </div>
                      
                      <div className="text-center">
                        <div className="text-sm text-gray-400">{prediction.timeframe}</div>
                        <div className={`text-xs px-2 py-1 rounded ${
                          prediction.status === 'active' ? 'bg-blue-500/20 text-blue-400' :
                          prediction.status === 'completed' ? 'bg-green-500/20 text-green-400' :
                          'bg-gray-500/20 text-gray-400'
                        }`}>
                          {prediction.status}
                        </div>
                      </div>
                      
                      {expandedPrediction === prediction.id ? 
                        <ChevronUp className="w-5 h-5 text-gray-400" /> : 
                        <ChevronDown className="w-5 h-5 text-gray-400" />
                      }
                    </div>
                  </div>
                  
                  <AnimatePresence>
                    {expandedPrediction === prediction.id && (
                      <motion.div
                        initial={{ opacity: 0, height: 0 }}
                        animate={{ opacity: 1, height: 'auto' }}
                        exit={{ opacity: 0, height: 0 }}
                        className="mt-6 pt-6 border-t border-white/10"
                      >
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                          <div>
                            <h4 className="font-semibold text-white mb-3">AI Reasoning:</h4>
                            <div className="space-y-2">
                              {prediction.reasoning.map((reason, idx) => (
                                <motion.div
                                  key={idx}
                                  initial={{ opacity: 0, x: -10 }}
                                  animate={{ opacity: 1, x: 0 }}
                                  transition={{ delay: idx * 0.1 }}
                                  className="flex items-center space-x-3"
                                >
                                  <CheckCircle className="w-4 h-4 text-green-400 flex-shrink-0" />
                                  <span className="text-gray-300 text-sm">{reason}</span>
                                </motion.div>
                              ))}
                            </div>
                          </div>
                          
                          <div>
                            <h4 className="font-semibold text-white mb-3">Model Performance:</h4>
                            <div className="space-y-3">
                              <div className="flex justify-between">
                                <span className="text-gray-400">Historical Accuracy:</span>
                                <span className="text-white font-medium">{prediction.accuracy}%</span>
                              </div>
                              <div className="w-full bg-gray-700 rounded-full h-2">
                                <motion.div
                                  className="bg-gradient-to-r from-purple-500 to-pink-500 h-2 rounded-full"
                                  initial={{ width: 0 }}
                                  animate={{ width: `${prediction.accuracy}%` }}
                                  transition={{ duration: 1, ease: "easeOut" }}
                                />
                              </div>
                              <div className="text-xs text-gray-500">
                                Based on 1,247 previous predictions
                              </div>
                            </div>
                          </div>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </motion.div>
              ))}
            </motion.div>
          )}
          
          {activeTab === 'insights' && (
            <motion.div
              key="insights"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="grid grid-cols-1 md:grid-cols-2 gap-6"
            >
              {insights.map((insight, index) => {
                const Icon = getInsightIcon(insight.type)
                return (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: index * 0.1 }}
                    className="p-6 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10 hover:bg-white/10 transition-all"
                  >
                    <div className="flex items-start justify-between mb-4">
                      <div className={`p-3 rounded-xl bg-gradient-to-r ${getInsightColor(insight.type)} shadow-lg`}>
                        <Icon className="w-6 h-6 text-white" />
                      </div>
                      <div className="text-right">
                        <div className="text-2xl font-bold text-white">{insight.confidence}%</div>
                        <div className="text-xs text-gray-400">Confidence</div>
                      </div>
                    </div>
                    
                    <h3 className="text-xl font-bold text-white mb-2">{insight.title}</h3>
                    <p className="text-gray-300 mb-4">{insight.description}</p>
                    
                    <div className="flex items-center justify-between">
                      <div className={`px-3 py-1 rounded-full text-sm font-medium ${
                        insight.impact === 'high' ? 'bg-red-500/20 text-red-400' :
                        insight.impact === 'medium' ? 'bg-yellow-500/20 text-yellow-400' :
                        'bg-green-500/20 text-green-400'
                      }`}>
                        {insight.impact} impact
                      </div>
                      
                      {insight.action && (
                        <motion.button
                          className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm transition-colors"
                          whileHover={{ scale: 1.05 }}
                          whileTap={{ scale: 0.95 }}
                        >
                          {insight.action}
                        </motion.button>
                      )}
                    </div>
                  </motion.div>
                )
              })}
            </motion.div>
          )}
          
          {activeTab === 'analysis' && (
            <motion.div
              key="analysis"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="text-center py-20"
            >
              <motion.div
                animate={{ 
                  rotate: 360,
                  scale: [1, 1.2, 1]
                }}
                transition={{ 
                  duration: 2,
                  repeat: Infinity,
                  ease: "linear"
                }}
                className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-600 rounded-full flex items-center justify-center mx-auto mb-6"
              >
                <Bot className="w-8 h-8 text-white" />
              </motion.div>
              
              <h3 className="text-2xl font-bold text-white mb-4">Deep Analysis Coming Soon</h3>
              <p className="text-gray-400">Advanced ML models are being trained for comprehensive market analysis</p>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  )
}

export default AIAnalyticsInterface
