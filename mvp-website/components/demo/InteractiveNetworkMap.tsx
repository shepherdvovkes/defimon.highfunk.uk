'use client'

import { motion, AnimatePresence } from 'framer-motion'
import { useState, useEffect, useRef, useCallback } from 'react'
import { 
  Globe,
  Zap,
  Users,
  DollarSign,
  TrendingUp,
  TrendingDown,
  Activity,
  Shield,
  Cpu,
  Database,
  Link,
  BarChart3,
  Eye,
  Play,
  Pause,
  RotateCw,
  Layers,
  Network,
  MapPin,
  Wifi,
  Server,
  Cloud,
  Satellite,
  Radio,
  Signal,
  WifiOff,
  CheckCircle,
  AlertTriangle,
  XCircle
} from 'lucide-react'

interface NetworkNode {
  id: string
  name: string
  type: 'validator' | 'rpc' | 'bridge' | 'dex' | 'liquidity' | 'oracle'
  x: number
  y: number
  z: number
  region: string
  country: string
  connections: string[]
  status: 'online' | 'offline' | 'degraded'
  latency: number
  bandwidth: number
  uptime: number
  color: string
  size: number
  dataFlow: number
  lastUpdate: Date
}

interface NetworkConnection {
  from: string
  to: string
  type: 'direct' | 'relay' | 'bridge'
  strength: number
  latency: number
  bandwidth: number
  status: 'active' | 'congested' | 'down'
  dataFlow: number
}

interface NetworkRegion {
  name: string
  nodes: string[]
  color: string
  center: { x: number, y: number }
}

const InteractiveNetworkMap = () => {
  const [selectedNode, setSelectedNode] = useState<string | null>(null)
  const [hoveredNode, setHoveredNode] = useState<string | null>(null)
  const [animationRunning, setAnimationRunning] = useState(true)
  const [viewMode, setViewMode] = useState<'topology' | 'geographic' | 'dataflow'>('topology')
  const [selectedRegion, setSelectedRegion] = useState<string | null>(null)
  const [timeScale, setTimeScale] = useState<'realtime' | '1h' | '24h' | '7d'>('realtime')
  const [showConnections, setShowConnections] = useState(true)
  const [showDataFlows, setShowDataFlows] = useState(true)
  
  const containerRef = useRef<HTMLDivElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const animationRef = useRef<number>()
  
  // Network topology data
  const networkNodes: NetworkNode[] = [
    // Ethereum Mainnet Validators
    { id: 'eth-validator-1', name: 'ETH Validator #1', type: 'validator', x: 200, y: 150, z: 0, region: 'North America', country: 'USA', connections: ['eth-rpc-1', 'eth-bridge-1'], status: 'online', latency: 45, bandwidth: 1000, uptime: 99.9, color: '#627EEA', size: 80, dataFlow: 1250, lastUpdate: new Date() },
    { id: 'eth-validator-2', name: 'ETH Validator #2', type: 'validator', x: 180, y: 180, z: 0, region: 'Europe', country: 'Germany', connections: ['eth-rpc-2', 'eth-bridge-2'], status: 'online', latency: 52, bandwidth: 950, uptime: 99.8, color: '#627EEA', size: 75, dataFlow: 1180, lastUpdate: new Date() },
    { id: 'eth-validator-3', name: 'ETH Validator #3', type: 'validator', x: 220, y: 120, z: 0, region: 'Asia', country: 'Singapore', connections: ['eth-rpc-3', 'eth-bridge-3'], status: 'online', latency: 38, bandwidth: 1100, uptime: 99.7, color: '#627EEA', size: 70, dataFlow: 1320, lastUpdate: new Date() },
    
    // RPC Nodes
    { id: 'eth-rpc-1', name: 'ETH RPC #1', type: 'rpc', x: 250, y: 200, z: 0, region: 'North America', country: 'USA', connections: ['eth-validator-1', 'arb-rpc-1'], status: 'online', latency: 28, bandwidth: 2000, uptime: 99.9, color: '#96BEDC', size: 60, dataFlow: 2100, lastUpdate: new Date() },
    { id: 'eth-rpc-2', name: 'ETH RPC #2', type: 'rpc', x: 150, y: 250, z: 0, region: 'Europe', country: 'Netherlands', connections: ['eth-validator-2', 'opt-rpc-1'], status: 'online', latency: 35, bandwidth: 1800, uptime: 99.8, color: '#96BEDC', size: 65, dataFlow: 1950, lastUpdate: new Date() },
    { id: 'arb-rpc-1', name: 'ARB RPC #1', type: 'rpc', x: 300, y: 180, z: 0, region: 'North America', country: 'USA', connections: ['eth-rpc-1', 'arb-bridge-1'], status: 'online', latency: 22, bandwidth: 2500, uptime: 99.9, color: '#FF0420', size: 70, dataFlow: 2400, lastUpdate: new Date() },
    { id: 'opt-rpc-1', name: 'OPT RPC #1', type: 'rpc', x: 120, y: 220, z: 0, region: 'Europe', country: 'UK', connections: ['eth-rpc-2', 'opt-bridge-1'], status: 'online', latency: 31, bandwidth: 2200, uptime: 99.7, color: '#FF0420', size: 68, dataFlow: 2250, lastUpdate: new Date() },
    
    // Bridge Nodes
    { id: 'eth-bridge-1', name: 'ETH Bridge #1', type: 'bridge', x: 280, y: 120, z: 0, region: 'North America', country: 'USA', connections: ['eth-validator-1', 'arb-bridge-1', 'poly-bridge-1'], status: 'online', latency: 15, bandwidth: 1500, uptime: 99.9, color: '#8247E5', size: 85, dataFlow: 1600, lastUpdate: new Date() },
    { id: 'arb-bridge-1', name: 'ARB Bridge #1', type: 'bridge', x: 320, y: 160, z: 0, region: 'North America', country: 'USA', connections: ['arb-rpc-1', 'eth-bridge-1'], status: 'online', latency: 12, bandwidth: 1800, uptime: 99.8, color: '#8247E5', size: 90, dataFlow: 1850, lastUpdate: new Date() },
    { id: 'poly-bridge-1', name: 'POLY Bridge #1', type: 'bridge', x: 200, y: 300, z: 0, region: 'Asia', country: 'India', connections: ['eth-bridge-1', 'poly-rpc-1'], status: 'degraded', latency: 85, bandwidth: 800, uptime: 98.5, color: '#8247E5', size: 75, dataFlow: 750, lastUpdate: new Date() },
    
    // DEX Nodes
    { id: 'uniswap-node', name: 'Uniswap V3', type: 'dex', x: 350, y: 250, z: 0, region: 'North America', country: 'USA', connections: ['eth-rpc-1', 'arb-rpc-1'], status: 'online', latency: 18, bandwidth: 3000, uptime: 99.9, color: '#FF007A', size: 100, dataFlow: 3200, lastUpdate: new Date() },
    { id: 'sushiswap-node', name: 'SushiSwap', type: 'dex', x: 180, y: 320, z: 0, region: 'Europe', country: 'Switzerland', connections: ['eth-rpc-2', 'opt-rpc-1'], status: 'online', latency: 25, bandwidth: 2800, uptime: 99.8, color: '#FF007A', size: 95, dataFlow: 2950, lastUpdate: new Date() },
    
    // Oracle Nodes
    { id: 'chainlink-node', name: 'Chainlink Oracle', type: 'oracle', x: 400, y: 200, z: 0, region: 'North America', country: 'USA', connections: ['eth-rpc-1', 'arb-rpc-1', 'opt-rpc-1'], status: 'online', latency: 20, bandwidth: 2500, uptime: 99.9, color: '#2A5ADA', size: 110, dataFlow: 2600, lastUpdate: new Date() },
    
    // Additional nodes for geographic distribution
    { id: 'cosmos-validator', name: 'Cosmos Validator', type: 'validator', x: 80, y: 400, z: 0, region: 'Europe', country: 'France', connections: ['cosmos-rpc'], status: 'online', latency: 42, bandwidth: 1200, uptime: 99.7, color: '#2E3148', size: 70, dataFlow: 1250, lastUpdate: new Date() },
    { id: 'solana-validator', name: 'Solana Validator', type: 'validator', x: 450, y: 350, z: 0, region: 'North America', country: 'Canada', connections: ['solana-rpc'], status: 'online', latency: 35, bandwidth: 1500, uptime: 99.6, color: '#9945FF', size: 80, dataFlow: 1550, lastUpdate: new Date() }
  ]

  const networkConnections: NetworkConnection[] = [
    // Direct connections
    { from: 'eth-validator-1', to: 'eth-rpc-1', type: 'direct', strength: 0.9, latency: 45, bandwidth: 1000, status: 'active', dataFlow: 1250 },
    { from: 'eth-validator-2', to: 'eth-rpc-2', type: 'direct', strength: 0.8, latency: 52, bandwidth: 950, status: 'active', dataFlow: 1180 },
    { from: 'eth-rpc-1', to: 'arb-rpc-1', type: 'direct', strength: 0.7, latency: 28, bandwidth: 2000, status: 'active', dataFlow: 2100 },
    { from: 'eth-rpc-2', to: 'opt-rpc-1', type: 'direct', strength: 0.6, latency: 35, bandwidth: 1800, status: 'active', dataFlow: 1950 },
    
    // Bridge connections
    { from: 'eth-bridge-1', to: 'arb-bridge-1', type: 'bridge', strength: 0.8, latency: 15, bandwidth: 1500, status: 'active', dataFlow: 1600 },
    { from: 'eth-bridge-1', to: 'poly-bridge-1', type: 'bridge', strength: 0.5, latency: 85, bandwidth: 800, status: 'congested', dataFlow: 750 },
    
    // DEX connections
    { from: 'uniswap-node', to: 'eth-rpc-1', type: 'direct', strength: 0.9, latency: 18, bandwidth: 3000, status: 'active', dataFlow: 3200 },
    { from: 'sushiswap-node', to: 'eth-rpc-2', type: 'direct', strength: 0.7, latency: 25, bandwidth: 2800, status: 'active', dataFlow: 2950 },
    
    // Oracle connections
    { from: 'chainlink-node', to: 'eth-rpc-1', type: 'direct', strength: 0.8, latency: 20, bandwidth: 2500, status: 'active', dataFlow: 2600 },
    { from: 'chainlink-node', to: 'arb-rpc-1', type: 'direct', strength: 0.7, latency: 22, bandwidth: 2500, status: 'active', dataFlow: 2600 }
  ]

  const regions: NetworkRegion[] = [
    { name: 'North America', nodes: ['eth-validator-1', 'eth-rpc-1', 'arb-rpc-1', 'eth-bridge-1', 'arb-bridge-1', 'uniswap-node', 'chainlink-node'], color: '#3B82F6', center: { x: 300, y: 200 } },
    { name: 'Europe', nodes: ['eth-validator-2', 'eth-rpc-2', 'opt-rpc-1', 'sushiswap-node', 'cosmos-validator'], color: '#8B5CF6', center: { x: 150, y: 280 } },
    { name: 'Asia', nodes: ['eth-validator-3', 'poly-bridge-1', 'poly-rpc-1'], color: '#10B981', center: { x: 200, y: 350 } }
  ]

  const getNodeIcon = (type: string) => {
    switch (type) {
      case 'validator': return Server
      case 'rpc': return Cpu
      case 'bridge': return Link
      case 'dex': return BarChart3
      case 'liquidity': return DollarSign
      case 'oracle': return Shield
      default: return Network
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'online': return '#10B981'
      case 'degraded': return '#F59E0B'
      case 'offline': return '#EF4444'
      default: return '#6B7280'
    }
  }

  const getConnectionStatusColor = (status: string) => {
    switch (status) {
      case 'active': return '#10B981'
      case 'congested': return '#F59E0B'
      case 'down': return '#EF4444'
      default: return '#6B7280'
    }
  }

  const filteredNodes = selectedRegion 
    ? networkNodes.filter(node => regions.find(r => r.name === selectedRegion)?.nodes.includes(node.id))
    : networkNodes

  const filteredConnections = showConnections 
    ? networkConnections.filter(conn => 
        filteredNodes.some(node => node.id === conn.from) && 
        filteredNodes.some(node => node.id === conn.to)
      )
    : []

  // 3D Network Visualization
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const resizeCanvas = () => {
      if (containerRef.current) {
        canvas.width = containerRef.current.offsetWidth
        canvas.height = containerRef.current.offsetHeight
      }
    }

    resizeCanvas()
    window.addEventListener('resize', resizeCanvas)

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      
      // Draw connections
      if (showConnections) {
        filteredConnections.forEach(connection => {
          const fromNode = networkNodes.find(n => n.id === connection.from)
          const toNode = networkNodes.find(n => n.id === connection.to)
          
          if (fromNode && toNode) {
            ctx.strokeStyle = getConnectionStatusColor(connection.status)
            ctx.lineWidth = connection.strength * 3
            ctx.globalAlpha = 0.6
            
            ctx.beginPath()
            ctx.moveTo(fromNode.x, fromNode.y)
            ctx.lineTo(toNode.x, toNode.y)
            ctx.stroke()
            
            // Data flow animation
            if (showDataFlows && animationRunning) {
              const progress = (Date.now() / 1000) % 2
              const x = fromNode.x + (toNode.x - fromNode.x) * progress
              const y = fromNode.y + (toNode.y - fromNode.y) * progress
              
              ctx.fillStyle = '#8B5CF6'
              ctx.globalAlpha = 0.8
              ctx.beginPath()
              ctx.arc(x, y, 3, 0, Math.PI * 2)
              ctx.fill()
            }
          }
        })
      }
      
      ctx.globalAlpha = 1
      animationRef.current = requestAnimationFrame(animate)
    }

    animate()

    return () => {
      window.removeEventListener('resize', resizeCanvas)
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current)
      }
    }
  }, [filteredConnections, showConnections, showDataFlows, animationRunning])

  return (
    <div className="relative bg-gradient-to-br from-gray-900 via-gray-800 to-black rounded-3xl overflow-hidden">
      {/* Control Panel */}
      <div className="absolute top-6 left-6 right-6 z-20">
        <div className="flex items-center justify-between">
          {/* Left Controls */}
          <div className="flex items-center space-x-4">
            <motion.button
              onClick={() => setAnimationRunning(!animationRunning)}
              className={`flex items-center space-x-2 px-4 py-2 rounded-xl font-medium transition-all ${
                animationRunning
                  ? 'bg-green-500/20 text-green-400 shadow-lg shadow-green-500/25'
                  : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
              }`}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              {animationRunning ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
              <span>{animationRunning ? 'Live' : 'Paused'}</span>
            </motion.button>

            {/* View Mode Toggle */}
            <div className="flex bg-gray-800/50 rounded-xl p-1">
              {[
                { key: 'topology', label: 'Topology', icon: Network },
                { key: 'geographic', label: 'Geographic', icon: MapPin },
                { key: 'dataflow', label: 'Data Flow', icon: Zap }
              ].map((mode) => (
                <motion.button
                  key={mode.key}
                  onClick={() => setViewMode(mode.key as any)}
                  className={`flex items-center space-x-2 px-3 py-2 rounded-lg text-sm font-medium transition-all ${
                    viewMode === mode.key
                      ? 'bg-purple-500 text-white shadow-lg shadow-purple-500/25'
                      : 'text-gray-400 hover:text-white hover:bg-gray-700'
                  }`}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                >
                  <mode.icon className="w-4 h-4" />
                  <span>{mode.label}</span>
                </motion.button>
              ))}
            </div>

            {/* Connection Toggles */}
            <div className="flex space-x-2">
              <motion.button
                onClick={() => setShowConnections(!showConnections)}
                className={`flex items-center space-x-2 px-3 py-2 rounded-lg text-sm font-medium transition-all ${
                  showConnections
                    ? 'bg-blue-500/20 text-blue-400'
                    : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                }`}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <Link className="w-4 h-4" />
                <span>Connections</span>
              </motion.button>
              
              <motion.button
                onClick={() => setShowDataFlows(!showDataFlows)}
                className={`flex items-center space-x-2 px-3 py-2 rounded-lg text-sm font-medium transition-all ${
                  showDataFlows
                    ? 'bg-green-500/20 text-green-400'
                    : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                }`}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <Signal className="w-4 h-4" />
                <span>Data Flows</span>
              </motion.button>
            </div>
          </div>

          {/* Right Controls */}
          <div className="flex items-center space-x-4">
            {/* Region Filter */}
            <div className="flex space-x-2">
              <motion.button
                onClick={() => setSelectedRegion(null)}
                className={`px-3 py-2 rounded-lg text-sm font-medium transition-all ${
                  !selectedRegion
                    ? 'bg-gradient-to-r from-gray-500 to-gray-600 text-white shadow-lg'
                    : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                }`}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                All Regions
              </motion.button>
              {regions.map((region) => (
                <motion.button
                  key={region.name}
                  onClick={() => setSelectedRegion(
                    selectedRegion === region.name ? null : region.name
                  )}
                  className={`px-3 py-2 rounded-lg text-sm font-medium transition-all ${
                    selectedRegion === region.name
                      ? `bg-gradient-to-r ${region.color.includes('3B82F6') ? 'from-blue-500 to-blue-600' : region.color.includes('8B5CF6') ? 'from-purple-500 to-purple-600' : 'from-green-500 to-green-600'} text-white shadow-lg`
                      : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                  }`}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  {region.name}
                </motion.button>
              ))}
            </div>

            <div className="text-sm text-gray-400">
              {filteredNodes.length} nodes, {filteredConnections.length} connections
            </div>
          </div>
        </div>
      </div>

      {/* Network Visualization Canvas */}
      <div 
        ref={containerRef}
        className="relative h-[700px] overflow-hidden"
      >
        <canvas
          ref={canvasRef}
          className="absolute inset-0 w-full h-full"
        />

        {/* Network Nodes */}
        {filteredNodes.map((node, index) => {
          const Icon = getNodeIcon(node.type)
          return (
            <motion.div
              key={node.id}
              className="absolute cursor-pointer"
              style={{
                left: `${node.x - node.size / 2}px`,
                top: `${node.y - node.size / 2}px`,
                width: `${node.size}px`,
                height: `${node.size}px`
              }}
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ delay: index * 0.1, duration: 0.5 }}
              whileHover={{ scale: 1.1 }}
              onHoverStart={() => setHoveredNode(node.id)}
              onHoverEnd={() => setHoveredNode(null)}
              onClick={() => setSelectedNode(selectedNode === node.id ? null : node.id)}
            >
              {/* Node Base */}
              <div
                className={`
                  w-full h-full rounded-full flex items-center justify-center relative overflow-hidden backdrop-blur-md border-2 transition-all duration-300
                  ${node.status === 'online' ? 'border-green-500/50 bg-green-500/10' :
                    node.status === 'degraded' ? 'border-yellow-500/50 bg-yellow-500/10' :
                    'border-red-500/50 bg-red-500/10'}
                `}
              >
                {/* Status Ring */}
                <div
                  className={`absolute inset-0 rounded-full ${
                    node.status === 'online' ? 'animate-pulse bg-green-500/20' :
                    node.status === 'degraded' ? 'animate-pulse bg-yellow-500/20' :
                    'bg-red-500/20'
                  }`}
                >
                  <div className="w-full h-full rounded-full bg-gray-900/80"></div>
                </div>

                {/* Pulse Effect */}
                {animationRunning && node.status === 'online' && (
                  <motion.div
                    className="absolute inset-0 rounded-full border-2 border-green-400"
                    animate={{
                      scale: [1, 1.5, 1],
                      opacity: [0.5, 0, 0.5]
                    }}
                    transition={{
                      duration: 2,
                      repeat: Infinity,
                      delay: Math.random() * 2
                    }}
                  />
                )}

                {/* Node Icon */}
                <div className="relative z-10">
                  <Icon className="w-6 h-6 text-white" />
                </div>

                {/* Data Flow Indicator */}
                {showDataFlows && (
                  <div className="absolute -top-2 -right-2 bg-purple-500 text-white text-xs px-1 py-0.5 rounded-full font-bold">
                    {Math.round(node.dataFlow / 100)}k
                  </div>
                )}
              </div>

              {/* Node Label */}
              <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2 text-center">
                <div className="text-sm font-semibold text-white whitespace-nowrap">
                  {node.name}
                </div>
                <div className="text-xs text-gray-400">
                  {node.latency}ms
                </div>
              </div>
            </motion.div>
          )
        })}

        {/* Node Details Panel */}
        <AnimatePresence>
          {(selectedNode || hoveredNode) && (
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 20 }}
              className="absolute top-20 right-6 w-80 bg-gray-900/95 backdrop-blur-xl rounded-2xl p-6 border border-white/10"
            >
              {(() => {
                const node = networkNodes.find(n => n.id === (selectedNode || hoveredNode))
                if (!node) return null

                const Icon = getNodeIcon(node.type)
                return (
                  <div>
                    <div className="flex items-center justify-between mb-4">
                      <div className="flex items-center space-x-3">
                        <div className={`p-2 rounded-lg ${node.status === 'online' ? 'bg-green-500/20' : node.status === 'degraded' ? 'bg-yellow-500/20' : 'bg-red-500/20'}`}>
                          <Icon className="w-5 h-5 text-white" />
                        </div>
                        <div>
                          <h3 className="text-lg font-bold text-white">{node.name}</h3>
                          <p className="text-sm text-gray-400 capitalize">{node.type} Node</p>
                        </div>
                      </div>
                      <div 
                        className={`w-3 h-3 rounded-full ${
                          node.status === 'online' ? 'bg-green-500' :
                          node.status === 'degraded' ? 'bg-yellow-500' :
                          'bg-red-500'
                        }`}
                      />
                    </div>

                    <div className="space-y-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div className="bg-gray-800/50 rounded-lg p-3">
                          <div className="flex items-center space-x-2 mb-2">
                            <Signal className="w-4 h-4 text-blue-400" />
                            <span className="text-sm text-gray-400">Latency</span>
                          </div>
                          <div className="text-lg font-bold text-white">
                            {node.latency}ms
                          </div>
                        </div>

                        <div className="bg-gray-800/50 rounded-lg p-3">
                          <div className="flex items-center space-x-2 mb-2">
                            <Wifi className="w-4 h-4 text-green-400" />
                            <span className="text-sm text-gray-400">Bandwidth</span>
                          </div>
                          <div className="text-lg font-bold text-white">
                            {node.bandwidth} Mbps
                          </div>
                        </div>

                        <div className="bg-gray-800/50 rounded-lg p-3">
                          <div className="flex items-center space-x-2 mb-2">
                            <CheckCircle className="w-4 h-4 text-purple-400" />
                            <span className="text-sm text-gray-400">Uptime</span>
                          </div>
                          <div className="text-lg font-bold text-white">
                            {node.uptime}%
                          </div>
                        </div>

                        <div className="bg-gray-800/50 rounded-lg p-3">
                          <div className="flex items-center space-x-2 mb-2">
                            <Zap className="w-4 h-4 text-yellow-400" />
                            <span className="text-sm text-gray-400">Data Flow</span>
                          </div>
                          <div className="text-lg font-bold text-white">
                            {Math.round(node.dataFlow / 1000)}k/s
                          </div>
                        </div>
                      </div>

                      <div className="bg-gray-800/50 rounded-lg p-3">
                        <div className="flex items-center space-x-2 mb-2">
                          <MapPin className="w-4 h-4 text-gray-400" />
                          <span className="text-sm text-gray-400">Location</span>
                        </div>
                        <div className="text-white">
                          {node.country}, {node.region}
                        </div>
                      </div>

                      {node.connections.length > 0 && (
                        <div>
                          <h4 className="text-sm font-semibold text-gray-400 mb-2">Connected to:</h4>
                          <div className="flex flex-wrap gap-2">
                            {node.connections.map((connId) => {
                              const connNode = networkNodes.find(n => n.id === connId)
                              return connNode ? (
                                <div
                                  key={connId}
                                  className="px-2 py-1 bg-gray-700 rounded text-xs text-white"
                                >
                                  {connNode.name}
                                </div>
                              ) : null
                            })}
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                )
              })()}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Legend */}
      <div className="absolute bottom-6 left-6 bg-gray-900/90 backdrop-blur-xl rounded-2xl p-4 border border-white/10">
        <h4 className="text-sm font-semibold text-white mb-3">Network Status</h4>
        <div className="space-y-2">
          <div className="flex items-center space-x-2">
            <div className="w-3 h-3 rounded-full bg-green-500"></div>
            <span className="text-xs text-gray-400">Online</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
            <span className="text-xs text-gray-400">Degraded</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-3 h-3 rounded-full bg-red-500"></div>
            <span className="text-xs text-gray-400">Offline</span>
          </div>
        </div>
        
        <h4 className="text-sm font-semibold text-white mb-3 mt-4">Node Types</h4>
        <div className="space-y-2">
          <div className="flex items-center space-x-2">
            <Server className="w-4 h-4 text-white" />
            <span className="text-xs text-gray-400">Validator</span>
          </div>
          <div className="flex items-center space-x-2">
            <Cpu className="w-4 h-4 text-white" />
            <span className="text-xs text-gray-400">RPC</span>
          </div>
          <div className="flex items-center space-x-2">
            <Link className="w-4 h-4 text-white" />
            <span className="text-xs text-gray-400">Bridge</span>
          </div>
          <div className="flex items-center space-x-2">
            <BarChart3 className="w-4 h-4 text-white" />
            <span className="text-xs text-gray-400">DEX</span>
          </div>
        </div>
      </div>
    </div>
  )
}

export default InteractiveNetworkMap
