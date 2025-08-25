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
  Globe
} from 'lucide-react'

interface MetricData {
  id: string
  name: string
  value: string
  change: string
  trend: 'up' | 'down'
  icon: any
  color: string
  description: string
  realTimeData: number[]
  accuracy: number
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
      color: 'from-emerald-400 via-teal-500 to-cyan-600',
      description: 'Общая заблокированная стоимость активов',
      realTimeData: [2.1, 2.3, 2.5, 2.7, 2.8, 2.85],
      accuracy: 98.7
    },
    {
      id: 'users',
      name: 'Active Users',
      value: '127.3K',
      change: '+23.2%',
      trend: 'up',
      icon: Users,
      color: 'from-violet-400 via-purple-500 to-indigo-600',
      description: 'Активные пользователи за 24 часа',
      realTimeData: [98, 105, 112, 119, 124, 127],
      accuracy: 94.2
    },
    {
      id: 'tps',
      name: 'Transactions/sec',
      value: '3,247',
      change: '+8.9%',
      trend: 'up',
      icon: Activity,
      color: 'from-orange-400 via-red-500 to-pink-600',
      description: 'Средняя пропускная способность сети',
      realTimeData: [2800, 2950, 3100, 3180, 3220, 3247],
      accuracy: 96.8
    },
    {
      id: 'risk',
      name: 'AI Risk Score',
      value: '8.4/10',
      change: '+0.7',
      trend: 'up',
      icon: Shield,
      color: 'from-blue-400 via-sky-500 to-cyan-600',
      description: 'Оценка безопасности на основе ML',
      realTimeData: [7.2, 7.6, 7.9, 8.1, 8.3, 8.4],
      accuracy: 97.5
    }
  ]

  const handleMouseMove = (event: React.MouseEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect()
    const centerX = rect.left + rect.width / 2
    const centerY = rect.top + rect.height / 2
    mouseX.set(event.clientX - centerX)
    mouseY.set(event.clientY - centerY)
  }

  // Имитация обновления данных в реальном времени
  useEffect(() => {
    if (realTimeMode) {
      const interval = setInterval(() => {
        setAnimatedValues(prev => {
          const newValues = {...prev}
          metrics.forEach(metric => {
            const baseValue = parseFloat(metric.value.replace(/[^\d.]/g, ''))
            const variation = (Math.random() - 0.5) * 0.1 // ±5% вариация
            newValues[metric.id] = baseValue * (1 + variation)
          })
          return newValues
        })
      }, 2000)
      
      return () => clearInterval(interval)
    }
  }, [realTimeMode])

  const MiniChart = ({ data, color }: { data: number[], color: string }) => {
    const maxValue = Math.max(...data)
    const minValue = Math.min(...data)
    const range = maxValue - minValue || 1
    
    const pathData = data.map((value, index) => {
      const x = (index / (data.length - 1)) * 100
      const y = 100 - ((value - minValue) / range) * 100
      return `${index === 0 ? 'M' : 'L'} ${x} ${y}`
    }).join(' ')

    return (
      <div className="h-16 w-full relative overflow-hidden">
        <svg className="absolute inset-0 w-full h-full" viewBox="0 0 100 100" preserveAspectRatio="none">
          <defs>
            <linearGradient id={`gradient-${color}`} x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="currentColor" stopOpacity="0.8" />
              <stop offset="100%" stopColor="currentColor" stopOpacity="0.3" />
            </linearGradient>
          </defs>
          <motion.path
            d={pathData}
            stroke={`url(#gradient-${color})`}
            strokeWidth="2"
            fill="none"
            className="text-current"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            transition={{ duration: 1.5, ease: "easeInOut" }}
          />
          <motion.path
            d={`${pathData} L 100 100 L 0 100 Z`}
            fill={`url(#gradient-${color})`}
            className="text-current opacity-20"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            transition={{ duration: 1.5, ease: "easeInOut", delay: 0.5 }}
          />
        </svg>
      </div>
    )
  }

  return (
    <div className="relative">
      {/* Control Panel */}
      <div className="flex items-center justify-between mb-8">
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2">
            <div className={`w-3 h-3 rounded-full ${realTimeMode ? 'bg-green-400' : 'bg-gray-400'} animate-pulse`}></div>
            <span className="text-white font-medium">Real-time Analytics</span>
          </div>
          <motion.button
            onClick={() => setRealTimeMode(!realTimeMode)}
            className={`px-4 py-2 rounded-xl font-medium transition-all duration-300 ${
              realTimeMode 
                ? 'bg-gradient-to-r from-green-500 to-emerald-600 text-white shadow-lg shadow-green-500/25' 
                : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
            }`}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            {realTimeMode ? 'Live Mode' : 'Static Mode'}
          </motion.button>
        </div>
        
        <div className="flex items-center space-x-2">
          <Eye className="w-5 h-5 text-gray-400" />
          <span className="text-gray-400 text-sm">Advanced View</span>
        </div>
      </div>

      {/* Main Metrics Panel */}
      <motion.div
        className="relative perspective-1000"
        onMouseMove={handleMouseMove}
        style={{
          rotateX: rotateXSpring,
          rotateY: rotateYSpring,
          transformStyle: "preserve-3d"
        }}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {metrics.map((metric, index) => (
            <motion.div
              key={metric.id}
              className={`relative p-8 rounded-3xl backdrop-blur-xl transition-all duration-500 cursor-pointer ${
                activeMetric === metric.id
                  ? 'bg-white/15 shadow-2xl shadow-white/10 ring-2 ring-white/20 scale-[1.02]'
                  : 'bg-white/5 shadow-xl shadow-black/20 hover:bg-white/10 hover:scale-[1.01]'
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
              <div className={`absolute inset-0 bg-gradient-to-br ${metric.color} opacity-10 rounded-3xl`}></div>
              
              {/* Animated Border */}
              <div className="absolute inset-0 rounded-3xl overflow-hidden">
                <motion.div
                  className={`absolute inset-0 bg-gradient-to-r ${metric.color} opacity-50`}
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
                <div className="flex items-start justify-between mb-6">
                  <div className={`p-4 rounded-2xl bg-gradient-to-br ${metric.color} shadow-lg`}>
                    <metric.icon className="w-8 h-8 text-white" />
                  </div>
                  <div className="text-right">
                    <div className="flex items-center space-x-2 mb-1">
                      {metric.trend === 'up' ? (
                        <TrendingUp className="w-5 h-5 text-green-400" />
                      ) : (
                        <TrendingDown className="w-5 h-5 text-red-400" />
                      )}
                      <span className={`font-bold text-lg ${
                        metric.trend === 'up' ? 'text-green-400' : 'text-red-400'
                      }`}>
                        {metric.change}
                      </span>
                    </div>
                    <div className="text-sm text-gray-400">24h change</div>
                  </div>
                </div>

                {/* Value */}
                <div className="mb-4">
                  <motion.div 
                    className="text-4xl font-black text-white mb-2"
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
                  <div className="text-lg font-semibold text-gray-300">{metric.name}</div>
                  <div className="text-sm text-gray-500 mt-1">{metric.description}</div>
                </div>

                {/* Mini Chart */}
                <div className={`text-current ${metric.color.split(' ')[1]} opacity-80`}>
                  <MiniChart data={metric.realTimeData} color={metric.id} />
                </div>

                {/* Accuracy Badge */}
                <div className="flex items-center justify-between mt-4">
                  <div className="flex items-center space-x-2">
                    <Cpu className="w-4 h-4 text-purple-400" />
                    <span className="text-sm text-purple-400">AI Accuracy</span>
                  </div>
                  <div className="text-sm font-bold text-purple-400">
                    {metric.accuracy}%
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
                      <div>
                        <span className="text-gray-400">Source:</span>
                        <span className="text-white ml-2">Multiple APIs</span>
                      </div>
                      <div>
                        <span className="text-gray-400">Updated:</span>
                        <span className="text-white ml-2">2s ago</span>
                      </div>
                      <div>
                        <span className="text-gray-400">Confidence:</span>
                        <span className="text-green-400 ml-2">High</span>
                      </div>
                      <div>
                        <span className="text-gray-400">Trend:</span>
                        <span className="text-blue-400 ml-2">Bullish</span>
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
        className="mt-8 flex items-center justify-center space-x-4"
      >
        <motion.button
          className="flex items-center space-x-2 px-6 py-3 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-xl font-medium shadow-lg shadow-blue-500/25"
          whileHover={{ scale: 1.05, boxShadow: "0 25px 50px -12px rgba(59, 130, 246, 0.25)" }}
          whileTap={{ scale: 0.95 }}
        >
          <Database className="w-5 h-5" />
          <span>Export Data</span>
        </motion.button>
        
        <motion.button
          className="flex items-center space-x-2 px-6 py-3 bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-xl font-medium shadow-lg shadow-emerald-500/25"
          whileHover={{ scale: 1.05, boxShadow: "0 25px 50px -12px rgba(16, 185, 129, 0.25)" }}
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
