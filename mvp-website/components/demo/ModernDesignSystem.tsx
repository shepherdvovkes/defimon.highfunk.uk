'use client'

import React from 'react'
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
  Memory,
  HardDrive,
  Network
} from 'lucide-react'

// Modern Card Component with Glassmorphism
export const ModernCard = ({ 
  children, 
  className = '', 
  hover = true, 
  gradient = false,
  glow = false,
  ...props 
}: {
  children: React.ReactNode
  className?: string
  hover?: boolean
  gradient?: boolean
  glow?: boolean
  [key: string]: any
}) => {
  return (
    <motion.div
      className={`
        relative overflow-hidden rounded-2xl p-6
        ${gradient ? 'bg-gradient-to-br from-purple-500/10 via-blue-500/10 to-cyan-500/10' : 'glass-ultra'}
        ${glow ? 'network-node-shadow' : ''}
        ${hover ? 'hover:scale-105 transition-transform duration-300' : ''}
        ${className}
      `}
      whileHover={hover ? { scale: 1.02, y: -5 } : {}}
      whileTap={{ scale: 0.98 }}
      {...props}
    >
      {glow && (
        <div className="absolute inset-0 bg-gradient-to-r from-purple-500/20 via-blue-500/20 to-cyan-500/20 blur-xl opacity-50" />
      )}
      <div className="relative z-10">
        {children}
      </div>
    </motion.div>
  )
}

// Animated Metric Card
export const AnimatedMetric = ({ 
  title, 
  value, 
  change, 
  icon: Icon, 
  trend = 'up',
  color = 'emerald',
  size = 'md'
}: {
  title: string
  value: string
  change: string
  icon: any
  trend?: 'up' | 'down' | 'neutral'
  color?: 'emerald' | 'red' | 'blue' | 'yellow' | 'purple'
  size?: 'sm' | 'md' | 'lg'
}) => {
  const colorClasses = {
    emerald: 'from-emerald-500 to-teal-600',
    red: 'from-red-500 to-pink-600',
    blue: 'from-blue-500 to-cyan-600',
    yellow: 'from-yellow-500 to-orange-600',
    purple: 'from-purple-500 to-indigo-600'
  }

  const sizeClasses = {
    sm: 'p-4',
    md: 'p-6',
    lg: 'p-8'
  }

  return (
    <ModernCard className={`${sizeClasses[size]} group`} hover glow>
      <div className="flex items-center justify-between mb-4">
        <div className={`w-12 h-12 bg-gradient-to-r ${colorClasses[color]} rounded-xl flex items-center justify-center`}>
          <Icon className="w-6 h-6 text-white" />
        </div>
        <div className={`flex items-center space-x-1 text-sm font-medium ${
          trend === 'up' ? 'text-emerald-400' : 
          trend === 'down' ? 'text-red-400' : 'text-gray-400'
        }`}>
          {trend === 'up' && <TrendingUp className="w-4 h-4" />}
          {trend === 'down' && <TrendingDown className="w-4 h-4" />}
          <span>{change}</span>
        </div>
      </div>
      
      <div className="space-y-2">
        <h3 className="text-gray-400 text-sm font-medium">{title}</h3>
        <motion.p 
          className="text-2xl font-bold text-white"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          {value}
        </motion.p>
      </div>
    </ModernCard>
  )
}

// Interactive Network Status Grid
export const NetworkStatusGrid = () => {
  const networkNodes = [
    { name: 'Ethereum', status: 'healthy', icon: Globe, metrics: { tps: '15.2K', gas: '12 gwei' } },
    { name: 'Polygon', status: 'healthy', icon: Network, metrics: { tps: '65K', gas: '30 gwei' } },
    { name: 'Arbitrum', status: 'warning', icon: Zap, metrics: { tps: '8.5K', gas: '0.1 gwei' } },
    { name: 'Optimism', status: 'healthy', icon: Activity, metrics: { tps: '2.1K', gas: '0.001 gwei' } },
    { name: 'Base', status: 'critical', icon: Server, metrics: { tps: '1.8K', gas: '0.001 gwei' } },
    { name: 'Avalanche', status: 'healthy', icon: Cpu, metrics: { tps: '4.5K', gas: '25 gwei' } }
  ]

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy': return 'network-node-healthy'
      case 'warning': return 'network-node-warning'
      case 'critical': return 'network-node-critical'
      default: return 'network-node-healthy'
    }
  }

  return (
    <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
      {networkNodes.map((node, index) => {
        const Icon = node.icon
        return (
          <motion.div
            key={node.name}
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, delay: index * 0.1 }}
            className={`relative p-4 rounded-xl border-2 ${getStatusColor(node.status)} transition-all duration-300 hover:scale-105`}
          >
            <div className="flex items-center space-x-3 mb-3">
              <Icon className="w-6 h-6 text-white" />
              <div>
                <h4 className="font-semibold text-white">{node.name}</h4>
                <div className="flex items-center space-x-2">
                  <div className={`w-2 h-2 rounded-full ${
                    node.status === 'healthy' ? 'bg-emerald-400' :
                    node.status === 'warning' ? 'bg-yellow-400' : 'bg-red-400'
                  }`} />
                  <span className="text-xs text-gray-300 capitalize">{node.status}</span>
                </div>
              </div>
            </div>
            
            <div className="space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-gray-400">TPS:</span>
                <span className="text-white font-mono">{node.metrics.tps}</span>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-gray-400">Gas:</span>
                <span className="text-white font-mono">{node.metrics.gas}</span>
              </div>
            </div>
          </motion.div>
        )
      })}
    </div>
  )
}

// Animated Data Stream
export const AnimatedDataStream = ({ data, title }: { data: any[], title: string }) => {
  return (
    <ModernCard className="relative overflow-hidden">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-white">{title}</h3>
        <div className="flex items-center space-x-2">
          <div className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse" />
          <span className="text-sm text-gray-400">Live</span>
        </div>
      </div>
      
      <div className="space-y-3">
        {data.map((item, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.3, delay: index * 0.1 }}
            className="flex items-center justify-between p-3 bg-white/5 rounded-lg backdrop-blur-sm"
          >
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-gradient-to-r from-purple-500 to-blue-500 rounded-lg flex items-center justify-center">
                <item.icon className="w-4 h-4 text-white" />
              </div>
              <div>
                <p className="text-white font-medium">{item.name}</p>
                <p className="text-xs text-gray-400">{item.description}</p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-white font-mono">{item.value}</p>
              <p className={`text-xs ${item.change >= 0 ? 'text-emerald-400' : 'text-red-400'}`}>
                {item.change >= 0 ? '+' : ''}{item.change}%
              </p>
            </div>
          </motion.div>
        ))}
      </div>
      
      <div className="absolute inset-0 data-stream pointer-events-none" />
    </ModernCard>
  )
}

// Floating Action Button
export const FloatingActionButton = ({ 
  icon: Icon, 
  onClick, 
  label,
  color = 'purple'
}: {
  icon: any
  onClick: () => void
  label: string
  color?: 'purple' | 'blue' | 'emerald' | 'red'
}) => {
  const colorClasses = {
    purple: 'from-purple-500 to-pink-500',
    blue: 'from-blue-500 to-cyan-500',
    emerald: 'from-emerald-500 to-teal-500',
    red: 'from-red-500 to-pink-500'
  }

  return (
    <motion.button
      onClick={onClick}
      className={`
        fixed bottom-6 right-6 z-50
        w-14 h-14 rounded-full
        bg-gradient-to-r ${colorClasses[color]}
        shadow-2xl shadow-purple-500/25
        flex items-center justify-center
        text-white
        hover:shadow-purple-500/40
        transition-all duration-300
      `}
      whileHover={{ scale: 1.1, y: -5 }}
      whileTap={{ scale: 0.9 }}
      initial={{ opacity: 0, scale: 0 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5, delay: 1 }}
    >
      <Icon className="w-6 h-6" />
      <span className="sr-only">{label}</span>
    </motion.button>
  )
}

// Modern Progress Ring
export const ProgressRing = ({ 
  progress, 
  size = 120, 
  strokeWidth = 8,
  color = 'emerald'
}: {
  progress: number
  size?: number
  strokeWidth?: number
  color?: 'emerald' | 'blue' | 'purple' | 'red' | 'yellow'
}) => {
  const radius = (size - strokeWidth) / 2
  const circumference = radius * 2 * Math.PI
  const strokeDasharray = circumference
  const strokeDashoffset = circumference - (progress / 100) * circumference

  const colorClasses = {
    emerald: 'stroke-emerald-500',
    blue: 'stroke-blue-500',
    purple: 'stroke-purple-500',
    red: 'stroke-red-500',
    yellow: 'stroke-yellow-500'
  }

  return (
    <div className="relative inline-flex items-center justify-center">
      <svg
        width={size}
        height={size}
        className="transform -rotate-90"
      >
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke="rgba(255, 255, 255, 0.1)"
          strokeWidth={strokeWidth}
          fill="transparent"
        />
        <motion.circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke="currentColor"
          strokeWidth={strokeWidth}
          fill="transparent"
          className={colorClasses[color]}
          strokeDasharray={strokeDasharray}
          initial={{ strokeDashoffset: circumference }}
          animate={{ strokeDashoffset }}
          transition={{ duration: 1, ease: "easeInOut" }}
          strokeLinecap="round"
        />
      </svg>
      <div className="absolute inset-0 flex items-center justify-center">
        <span className="text-2xl font-bold text-white">{Math.round(progress)}%</span>
      </div>
    </div>
  )
}

// Animated Background Particles
export const AnimatedParticles = () => {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {[...Array(20)].map((_, i) => (
        <motion.div
          key={i}
          className="absolute w-1 h-1 bg-purple-400 rounded-full opacity-30"
          initial={{
            x: Math.random() * window.innerWidth,
            y: Math.random() * window.innerHeight,
          }}
          animate={{
            x: Math.random() * window.innerWidth,
            y: Math.random() * window.innerHeight,
          }}
          transition={{
            duration: Math.random() * 10 + 10,
            repeat: Infinity,
            ease: "linear"
          }}
        />
      ))}
    </div>
  )
}

// Modern Toggle Switch
export const ModernToggle = ({ 
  checked, 
  onChange, 
  label 
}: {
  checked: boolean
  onChange: (checked: boolean) => void
  label: string
}) => {
  return (
    <div className="flex items-center space-x-3">
      <motion.button
        onClick={() => onChange(!checked)}
        className={`
          relative w-14 h-8 rounded-full p-1 transition-colors duration-300
          ${checked ? 'bg-gradient-to-r from-purple-500 to-blue-500' : 'bg-gray-600'}
        `}
        whileTap={{ scale: 0.95 }}
      >
        <motion.div
          className="w-6 h-6 bg-white rounded-full shadow-lg"
          animate={{ x: checked ? 24 : 0 }}
          transition={{ type: "spring", stiffness: 500, damping: 30 }}
        />
      </motion.button>
      <span className="text-white font-medium">{label}</span>
    </div>
  )
}

// Export all components
export default {
  ModernCard,
  AnimatedMetric,
  NetworkStatusGrid,
  AnimatedDataStream,
  FloatingActionButton,
  ProgressRing,
  AnimatedParticles,
  ModernToggle
}
