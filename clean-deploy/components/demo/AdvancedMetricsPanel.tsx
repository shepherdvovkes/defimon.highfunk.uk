'use client'

import { motion, useMotionValue, useTransform, useSpring } from 'framer-motion'
import { useState, useEffect, useRef } from 'react'
import { 
  TrendingUp, 
  TrendingDown, 
  DollarSign, 
  Users, 
  Activity, 
  Shield, 
  Zap,
  BarChart3,
  Eye,
  Cpu,
  Database,
  Globe,
  Clock,
  Target,
  AlertTriangle,
  CheckCircle
} from 'lucide-react'

interface MetricData {
  id: string
  name: string
  value: string
  change: string
  trend: 'up' | 'down'
  icon: any
  color: string
  gradient: string
  description: string
  realTimeData: number[]
  accuracy: number
  status: 'healthy' | 'warning' | 'critical'
}

const AdvancedMetricsPanel = () => {
  const [activeMetric, setActiveMetric] = useState<string | null>(null)
  const [realTimeMode, setRealTimeMode] = useState(true)
  const [animatedValues, setAnimatedValues] = useState<{[key: string]: number}>({})
  
  const mouseX = useMotionValue(0)
  const mouseY = useMotionValue(0)
  
  const rotateX = useTransform(mouseY, [-300, 300], [10, -10])
  const rotateY = useTransform(mouseX, [-300, 300], [-10, 10])
  
  const springConfig = { damping: 25, stiffness: 700 }
  const rotateXSpring = useSpring(rotateX, springConfig)
  const rotateYSpring = useSpring(rotateY, springConfig)

  const metrics: MetricData[] = [
    {
      id: 'tvl',
      name: 'Total Value Locked',
      value: '$2.847B',
      change: '+14.8%',
      trend: 'up',
      icon: DollarSign,
      color: '#10B981',
      gradient: 'from-emerald-500 via-teal-500 to-cyan-500',
      description: 'Total value locked across all DeFi protocols',
      realTimeData: [2.1, 2.3, 2.5, 2.7, 2.8, 2.85],
      accuracy: 98.7,
      status: 'healthy'
    },
    {
      id: 'users',
      name: 'Active Users',
      value: '127.3K',
      change: '+23.2%',
      trend: 'up',
      icon: Users,
      color: '#8B5CF6',
      gradient: 'from-purple-500 via-pink-500 to-rose-500',
      description: 'Active users across all networks in 24h',
      realTimeData: [98, 105, 112, 119, 124, 127],
      accuracy: 94.2,
      status: 'healthy'
    },
    {
      id: 'tps',
      name: 'Transactions/sec',
      value: '3,247',
      change: '+8.9%',
      trend: 'up',
      icon: Activity,
      color: '#F59E0B',
      gradient: 'from-orange-500 via-red-500 to-pink-500',
      description: 'Average network throughput across chains',
      realTimeData: [2800, 2950, 3100, 3180, 3220, 3247],
      accuracy: 96.8,
      status: 'warning'
    },
    {
      id: 'risk',
      name: 'AI Risk Score',
      value: '8.4/10',
      change: '+0.7',
      trend: 'up',
      icon: Shield,
      color: '#3B82F6',
      gradient: 'from-blue-500 via-cyan-500 to-teal-500',
      description: 'ML-powered security assessment score',
      realTimeData: [7.2, 7.6, 7.9, 8.1, 8.3, 8.4],
      accuracy: 97.5,
      status: 'healthy'
    }
  ]

  const handleMouseMove = (event: React.MouseEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect()
    const centerX = rect.left + rect.width / 2
    const centerY = rect.top + rect.height / 2
    mouseX.set(event.clientX - centerX)
    mouseY.set(event.clientY - centerY)
  }

  // Real-time data simulation
  useEffect(() => {
    if (realTimeMode) {
      const interval = setInterval(() => {
        setAnimatedValues(prev => {
          const newValues = {...prev}
          metrics.forEach(metric => {
            const baseValue = parseFloat(metric.value.replace(/[^\d.]/g, ''))
            const variation = (Math.random() - 0.5) * 0.1 // ±5% variation
            newValues[metric.id] = baseValue * (1 + variation)
          })
          return newValues
        })
      }, 2000)
      
      return () => clearInterval(interval)
    }
  }, [realTimeMode])

  const MiniChart = ({ data, gradient }: { data: number[], gradient: string }) => {
    const maxValue = Math.max(...data)
    const minValue = Math.min(...data)
    const range = maxValue - minValue || 1
    
    const pathData = data.map((value, index) => {
      const x = (index / (data.length - 1)) * 100
      const y = 100 - ((value - minValue) / range) * 100
      return `${index === 0 ? 'M' : 'L'} ${x} ${y}`
    }).join(' ')

    return (
      <div className="h-20 w-full relative overflow-hidden">
        <svg className="absolute inset-0 w-full h-full" viewBox="0 0 100 100" preserveAspectRatio="none">
          <defs>
            <linearGradient id={`gradient-${gradient}`} x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="currentColor" stopOpacity="0.8" />
              <stop offset="100%" stopColor="currentColor" stopOpacity="0.3" />
            </linearGradient>
          </defs>
          <motion.path
            d={pathData}
            stroke={`url(#gradient-${gradient})`}
            strokeWidth="2.5"
            fill="none"
            className="text-current"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            transition={{ duration: 1.5, ease: "easeInOut" }}
          />
          <motion.path
            d={`${pathData} L 100 100 L 0 100 Z`}
            fill={`url(#gradient-${gradient})`}
            className="text-current opacity-20"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            transition={{ duration: 1.5, ease: "easeInOut", delay: 0.5 }}
          />
        </svg>
      </div>
    )
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy':
        return <CheckCircle className="w-4 h-4 text-emerald-400" />
      case 'warning':
        return <AlertTriangle className="w-4 h-4 text-orange-400" />
      case 'critical':
        return <AlertTriangle className="w-4 h-4 text-red-400" />
      default:
        return <CheckCircle className="w-4 h-4 text-emerald-400" />
    }
  }

  return (
    <div className="relative">
      {/* Control Panel */}
      <div className="flex items-center justify-between mb-12">
        <div className="flex items-center space-x-6">
          <div className="flex items-center space-x-3">
            <div className={`w-3 h-3 rounded-full ${realTimeMode ? 'bg-emerald-400' : 'bg-neutral-400'} animate-pulse`}></div>
            <span className="text-white font-semibold text-lg">Real-time Analytics</span>
          </div>
          <motion.button
            onClick={() => setRealTimeMode(!realTimeMode)}
            className={`px-6 py-3 rounded-2xl font-semibold transition-all duration-300 ${
              realTimeMode 
                ? 'bg-gradient-to-r from-emerald-500 to-teal-600 text-white shadow-lg shadow-emerald-500/25' 
                : 'glass text-neutral-300 hover:bg-white/10 border border-white/10'
            }`}
            whileHover={{ scale: 1.05, y: -2 }}
            whileTap={{ scale: 0.95 }}
          >
            {realTimeMode ? 'Live Mode' : 'Static Mode'}
          </motion.button>
        </div>
        
        <div className="flex items-center space-x-3">
          <Eye className="w-5 h-5 text-neutral-400" />
          <span className="text-neutral-400 font-medium">Advanced View</span>
        </div>
      </div>

      {/* Main Metrics Panel */}
      <motion.div
        className="relative"
        onMouseMove={handleMouseMove}
        style={{
          rotateX: rotateXSpring,
          rotateY: rotateYSpring,
          transformStyle: "preserve-3d"
        }}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {metrics.map((metric, index) => (
            <motion.div
              key={metric.id}
              className={`relative p-8 rounded-3xl transition-all duration-500 cursor-pointer ${
                activeMetric === metric.id
                  ? 'glass border border-white/20 shadow-2xl shadow-white/10 scale-[1.02]'
                  : 'glass hover:bg-white/10 hover:scale-[1.01] border border-white/5'
              }`}
              style={{ transformStyle: "preserve-3d" }}
              onClick={() => setActiveMetric(activeMetric === metric.id ? null : metric.id)}
              initial={{ opacity: 0, rotateX: -15, z: -50 }}
              animate={{ opacity: 1, rotateX: 0, z: 0 }}
              transition={{ 
                duration: 0.8, 
                delay: index * 0.2,
                type: "spring",
                stiffness: 100
              }}
              whileHover={{ 
                z: 50,
                transition: { duration: 0.2 }
              }}
            >
              {/* Background Gradient */}
              <div className={`absolute inset-0 bg-gradient-to-br ${metric.gradient} opacity-5 rounded-3xl`}></div>
              
              {/* Animated Border */}
              <div className="absolute inset-0 rounded-3xl overflow-hidden">
                <motion.div
                  className={`absolute inset-0 bg-gradient-to-r ${metric.gradient} opacity-30`}
                  style={{ 
                    maskImage: 'linear-gradient(90deg, transparent, white, transparent)',
                    maskSize: '200% 100%'
                  }}
                  animate={{ 
                    maskPosition: ['200% 0%', '-200% 0%'] 
                  }}
                  transition={{ 
                    duration: 3,
                    repeat: Infinity,
                    repeatType: "loop",
                    ease: "linear"
                  }}
                />
              </div>

              {/* Content */}
              <div className="relative z-10">
                {/* Header */}
                <div className="flex items-start justify-between mb-8">
                  <div className={`p-4 rounded-2xl bg-gradient-to-br ${metric.gradient} shadow-lg`}>
                    <metric.icon className="w-8 h-8 text-white" />
                  </div>
                  <div className="text-right">
                    <div className="flex items-center space-x-2 mb-2">
                      {metric.trend === 'up' ? (
                        <TrendingUp className="w-5 h-5 text-emerald-400" />
                      ) : (
                        <TrendingDown className="w-5 h-5 text-red-400" />
                      )}
                      <span className={`font-bold text-lg ${
                        metric.trend === 'up' ? 'text-emerald-400' : 'text-red-400'
                      }`}>
                        {metric.change}
                      </span>
                    </div>
                    <div className="text-sm text-neutral-400 font-medium">24h change</div>
                  </div>
                </div>

                {/* Value */}
                <div className="mb-6">
                  <motion.div 
                    className="text-5xl font-black text-white mb-3 font-display"
                    key={animatedValues[metric.id]}
                    initial={{ scale: 1.1, opacity: 0.7 }}
                    animate={{ scale: 1, opacity: 1 }}
                    transition={{ duration: 0.3 }}
                  >
                    {realTimeMode && animatedValues[metric.id] ? 
                      (metric.id === 'tvl' ? `$${(animatedValues[metric.id] / 1000).toFixed(2)}B` :
                       metric.id === 'users' ? `${Math.round(animatedValues[metric.id])}K` :
                       metric.id === 'tps' ? Math.round(animatedValues[metric.id]).toLocaleString() :
                       `${animatedValues[metric.id].toFixed(1)}/10`) :
                      metric.value
                    }
                  </motion.div>
                  <div className="text-xl font-bold text-neutral-200 mb-2">{metric.name}</div>
                  <div className="text-sm text-neutral-400 font-medium">{metric.description}</div>
                </div>

                {/* Mini Chart */}
                <div className={`text-current ${metric.gradient.split(' ')[1]} opacity-80 mb-6`}>
                  <MiniChart data={metric.realTimeData} gradient={metric.id} />
                </div>

                {/* Status and Accuracy */}
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center space-x-3">
                    {getStatusIcon(metric.status)}
                    <span className="text-sm font-semibold text-neutral-300">Status</span>
                  </div>
                  <div className="flex items-center space-x-3">
                    <Cpu className="w-4 h-4 text-purple-400" />
                    <span className="text-sm text-purple-400 font-semibold">AI Accuracy</span>
                    <span className="text-sm font-bold text-purple-400">
                      {metric.accuracy}%
                    </span>
                  </div>
                </div>

                {/* Expanded Details */}
                {activeMetric === metric.id && (
                  <motion.div
                    initial={{ opacity: 0, height: 0, y: -20 }}
                    animate={{ opacity: 1, height: 'auto', y: 0 }}
                    exit={{ opacity: 0, height: 0, y: -20 }}
                    transition={{ duration: 0.3 }}
                    className="mt-6 pt-6 border-t border-white/10"
                  >
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div className="flex items-center space-x-2">
                        <Database className="w-4 h-4 text-neutral-400" />
                        <span className="text-neutral-400">Source:</span>
                        <span className="text-white font-medium">Multiple APIs</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Clock className="w-4 h-4 text-neutral-400" />
                        <span className="text-neutral-400">Updated:</span>
                        <span className="text-white font-medium">2s ago</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Target className="w-4 h-4 text-neutral-400" />
                        <span className="text-neutral-400">Confidence:</span>
                        <span className="text-emerald-400 font-medium">High</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <TrendingUp className="w-4 h-4 text-neutral-400" />
                        <span className="text-neutral-400">Trend:</span>
                        <span className="text-blue-400 font-medium">Bullish</span>
                      </div>
                    </div>
                  </motion.div>
                )}
              </div>

              {/* Floating Elements */}
              <div className="absolute top-4 right-4 opacity-20">
                <motion.div
                  animate={{ 
                    rotate: 360,
                    scale: [1, 1.1, 1]
                  }}
                  transition={{ 
                    duration: 8,
                    repeat: Infinity,
                    ease: "linear"
                  }}
                >
                  <BarChart3 className="w-16 h-16" />
                </motion.div>
              </div>
            </motion.div>
          ))}
        </div>
      </motion.div>

      {/* Global Controls */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1.5 }}
        className="mt-12 flex items-center justify-center space-x-6"
      >
        <motion.button
          className="flex items-center space-x-3 px-8 py-4 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-2xl font-semibold shadow-lg shadow-blue-500/25"
          whileHover={{ scale: 1.05, y: -2, boxShadow: "0 25px 50px -12px rgba(59, 130, 246, 0.25)" }}
          whileTap={{ scale: 0.95 }}
        >
          <Database className="w-5 h-5" />
          <span>Export Data</span>
        </motion.button>
        
        <motion.button
          className="flex items-center space-x-3 px-8 py-4 bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-2xl font-semibold shadow-lg shadow-emerald-500/25"
          whileHover={{ scale: 1.05, y: -2, boxShadow: "0 25px 50px -12px rgba(16, 185, 129, 0.25)" }}
          whileTap={{ scale: 0.95 }}
        >
          <Globe className="w-5 h-5" />
          <span>View All Networks</span>
        </motion.button>
      </motion.div>
    </div>
  )
}

export default AdvancedMetricsPanel
