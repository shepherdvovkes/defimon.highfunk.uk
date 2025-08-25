'use client'

import { motion, useMotionValue, useTransform, AnimatePresence } from 'framer-motion'
import { useState, useEffect, useRef } from 'react'
import { 
  Sparkles,
  Zap,
  Brain,
  Globe,
  TrendingUp,
  Shield,
  Target,
  Cpu,
  Activity,
  Database,
  Eye,
  Play,
  ChevronDown
} from 'lucide-react'

interface Particle {
  id: number
  x: number
  y: number
  vx: number
  vy: number
  size: number
  color: string
  life: number
}

interface FloatingElement {
  id: string
  icon: any
  color: string
  position: { x: number, y: number }
  delay: number
}

const InteractiveHero = ({ onStartDemo }: { onStartDemo: () => void }) => {
  const [particles, setParticles] = useState<Particle[]>([])
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 })
  const [showDetails, setShowDetails] = useState(false)
  
  const containerRef = useRef<HTMLDivElement>(null)
  const mouseX = useMotionValue(0)
  const mouseY = useMotionValue(0)
  
  const rotateX = useTransform(mouseY, [-300, 300], [10, -10])
  const rotateY = useTransform(mouseX, [-300, 300], [-10, 10])

  const floatingElements: FloatingElement[] = [
    { id: 'brain', icon: Brain, color: '#8B5CF6', position: { x: 15, y: 20 }, delay: 0 },
    { id: 'globe', icon: Globe, color: '#10B981', position: { x: 85, y: 15 }, delay: 0.5 },
    { id: 'shield', icon: Shield, color: '#3B82F6', position: { x: 10, y: 70 }, delay: 1 },
    { id: 'cpu', icon: Cpu, color: '#F59E0B', position: { x: 90, y: 75 }, delay: 1.5 },
    { id: 'activity', icon: Activity, color: '#EF4444', position: { x: 50, y: 10 }, delay: 2 },
    { id: 'database', icon: Database, color: '#06B6D4', position: { x: 20, y: 45 }, delay: 2.5 }
  ]

  const features = [
    {
      title: "Real-time Analytics",
      description: "Live monitoring of 50+ blockchain networks",
      icon: Activity,
      color: "from-blue-500 to-cyan-500"
    },
    {
      title: "AI Predictions",
      description: "Machine learning powered market forecasts",
      icon: Brain,
      color: "from-purple-500 to-pink-500"
    },
    {
      title: "Risk Assessment",
      description: "Advanced security and volatility analysis",
      icon: Shield,
      color: "from-green-500 to-emerald-500"
    },
    {
      title: "Multi-chain Support",
      description: "Ethereum, Cosmos, Polkadot ecosystems",
      icon: Globe,
      color: "from-orange-500 to-red-500"
    }
  ]

  // Particle system
  useEffect(() => {
    const createParticle = (): Particle => ({
      id: Math.random(),
      x: Math.random() * window.innerWidth,
      y: window.innerHeight + 10,
      vx: (Math.random() - 0.5) * 2,
      vy: -Math.random() * 3 - 1,
      size: Math.random() * 3 + 1,
      color: ['#8B5CF6', '#10B981', '#3B82F6', '#F59E0B'][Math.floor(Math.random() * 4)],
      life: 1
    })

    const updateParticles = () => {
      setParticles(prev => {
        let newParticles = prev.map(particle => ({
          ...particle,
          x: particle.x + particle.vx,
          y: particle.y + particle.vy,
          life: particle.life - 0.01
        })).filter(particle => particle.life > 0 && particle.y > -10)

        // Add new particles
        if (Math.random() < 0.1 && newParticles.length < 50) {
          newParticles.push(createParticle())
        }

        return newParticles
      })
    }

    const interval = setInterval(updateParticles, 50)
    return () => clearInterval(interval)
  }, [])

  const handleMouseMove = (event: React.MouseEvent) => {
    if (!containerRef.current) return
    
    const rect = containerRef.current.getBoundingClientRect()
    const x = event.clientX - rect.left
    const y = event.clientY - rect.top
    
    setMousePosition({ x, y })
    mouseX.set(x - rect.width / 2)
    mouseY.set(y - rect.height / 2)
  }

  return (
    <motion.div
      ref={containerRef}
      className="relative min-h-screen flex items-center justify-center overflow-hidden"
      onMouseMove={handleMouseMove}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 1 }}
    >
      {/* Animated Background */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-gradient-to-br from-purple-900/20 via-black to-blue-900/20"></div>
        <motion.div 
          className="absolute top-1/4 left-1/4 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl"
          animate={{ 
            scale: [1, 1.2, 1],
            opacity: [0.3, 0.6, 0.3]
          }}
          transition={{ duration: 4, repeat: Infinity }}
        />
        <motion.div 
          className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-blue-500/10 rounded-full blur-3xl"
          animate={{ 
            scale: [1.2, 1, 1.2],
            opacity: [0.6, 0.3, 0.6]
          }}
          transition={{ duration: 4, repeat: Infinity, delay: 2 }}
        />
      </div>

      {/* Particle System */}
      <div className="absolute inset-0 pointer-events-none">
        {particles.map(particle => (
          <motion.div
            key={particle.id}
            className="hero-particle"
            style={{
              left: `${particle.x}px`,
              top: `${particle.y}px`,
              width: `${particle.size}px`,
              height: `${particle.size}px`,
              backgroundColor: particle.color,
              opacity: particle.life,
              boxShadow: `0 0 ${particle.size * 4}px ${particle.color}`
            }}
          />
        ))}
      </div>

      {/* Floating Elements */}
      {floatingElements.map((element) => {
        const Icon = element.icon
        return (
          <motion.div
            key={element.id}
            className="absolute pointer-events-none"
            style={{
              left: `${element.position.x}%`,
              top: `${element.position.y}%`
            }}
            initial={{ opacity: 0, scale: 0 }}
            animate={{ 
              opacity: [0, 0.6, 0],
              scale: [0, 1, 0],
              y: [0, -20, 0]
            }}
            transition={{
              duration: 4,
              repeat: Infinity,
              delay: element.delay,
              ease: "easeInOut"
            }}
          >
            <div 
              className="p-4 hero-floating-element border"
              style={{ 
                backgroundColor: `${element.color}20`,
                borderColor: element.color,
                boxShadow: `0 0 20px ${element.color}40`
              }}
            >
              <Icon className="w-8 h-8" style={{ color: element.color }} />
            </div>
          </motion.div>
        )
      })}

      {/* Main Content */}
      <motion.div
        className="relative z-10 text-center max-w-6xl mx-auto px-6"
        style={{
          rotateX: rotateX,
          rotateY: rotateY,
          transformStyle: "preserve-3d"
        }}
      >
        {/* Main Title */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 1, delay: 0.5 }}
          className="mb-8"
        >
          <motion.h1
            className="text-7xl md:text-9xl font-black mb-6 leading-tight"
            style={{ transformStyle: "preserve-3d" }}
          >
            <motion.span
              className="block bg-gradient-to-r from-purple-400 via-pink-400 to-blue-400 bg-clip-text text-transparent"
              animate={{ 
                backgroundPosition: ['0% 50%', '100% 50%', '0% 50%']
              }}
              transition={{ duration: 5, repeat: Infinity }}
              style={{ backgroundSize: '200% 200%' }}
            >
              DeFiMon
            </motion.span>
            <motion.span
              className="block bg-gradient-to-r from-emerald-400 via-teal-400 to-cyan-400 bg-clip-text text-transparent"
              animate={{ 
                backgroundPosition: ['100% 50%', '0% 50%', '100% 50%']
              }}
              transition={{ duration: 5, repeat: Infinity, delay: 0.5 }}
              style={{ backgroundSize: '200% 200%' }}
            >
              Analytics
            </motion.span>
          </motion.h1>

          <motion.p
            className="text-2xl md:text-3xl text-gray-300 max-w-4xl mx-auto mb-12 leading-relaxed"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 1, delay: 1 }}
          >
            Experience the future of blockchain analytics with 
            <span className="text-purple-400 font-semibold"> AI-powered insights</span>,
            <span className="text-blue-400 font-semibold"> real-time monitoring</span>, and
            <span className="text-green-400 font-semibold"> interactive visualizations</span>
          </motion.p>
        </motion.div>

        {/* Interactive Stats */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 1, delay: 1.5 }}
          className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-12"
        >
          {[
            { label: "Networks", value: "50+", icon: Globe, color: "#10B981" },
            { label: "AI Models", value: "12", icon: Brain, color: "#8B5CF6" },
            { label: "Accuracy", value: "96%", icon: Target, color: "#3B82F6" },
            { label: "Uptime", value: "99.9%", icon: Shield, color: "#F59E0B" }
          ].map((stat, index) => (
            <motion.div
              key={stat.label}
              className="relative group cursor-pointer"
              whileHover={{ scale: 1.05, y: -5 }}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 1.5 + index * 0.1 }}
            >
              <div className="glass-ultra rounded-2xl p-6 text-center group-hover:shadow-2xl transition-all duration-300">
                <div 
                  className="hero-stat-icon group-hover:scale-110"
                  style={{ 
                    backgroundColor: `${stat.color}20`,
                    boxShadow: `0 0 20px ${stat.color}30`
                  }}
                >
                  <stat.icon className="w-6 h-6" style={{ color: stat.color }} />
                </div>
                <div className="text-3xl font-black text-white mb-2">{stat.value}</div>
                <div className="text-sm text-gray-400 font-medium">{stat.label}</div>
              </div>
            </motion.div>
          ))}
        </motion.div>

        {/* Main CTA */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 1, delay: 2 }}
          className="mb-12"
        >
          <motion.button
            onClick={onStartDemo}
            className="group relative px-12 py-6 bg-gradient-to-r from-purple-600 via-pink-600 to-blue-600 text-white rounded-2xl font-black text-xl shadow-2xl shadow-purple-500/25 overflow-hidden"
            whileHover={{ 
              scale: 1.05, 
              boxShadow: "0 25px 50px -12px rgba(139, 92, 246, 0.4)"
            }}
            whileTap={{ scale: 0.95 }}
          >
            {/* Animated Background */}
            <motion.div
              className="absolute inset-0 bg-gradient-to-r from-purple-400 via-pink-400 to-blue-400"
              animate={{
                backgroundPosition: ['0% 50%', '100% 50%', '0% 50%']
              }}
              transition={{ duration: 3, repeat: Infinity }}
              style={{ backgroundSize: '200% 200%' }}
            />
            
            <div className="relative z-10 flex items-center space-x-3">
              <Play className="w-6 h-6 group-hover:scale-110 transition-transform" />
              <span>Start Interactive Demo</span>
              <Sparkles className="w-6 h-6 group-hover:rotate-180 transition-transform duration-500" />
            </div>
          </motion.button>
        </motion.div>

        {/* Feature Preview */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 2.5 }}
        >
          <motion.button
            onClick={() => setShowDetails(!showDetails)}
            className="flex items-center space-x-2 text-gray-400 hover:text-white transition-colors mx-auto mb-6"
            whileHover={{ scale: 1.05 }}
          >
            <span>Preview Features</span>
            <motion.div
              animate={{ rotate: showDetails ? 180 : 0 }}
              transition={{ duration: 0.3 }}
            >
              <ChevronDown className="w-5 h-5" />
            </motion.div>
          </motion.button>

          <AnimatePresence>
            {showDetails && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                transition={{ duration: 0.5 }}
                className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl mx-auto"
              >
                {features.map((feature, index) => (
                  <motion.div
                    key={feature.title}
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: index * 0.1 }}
                    className="glass-ultra rounded-2xl p-6 hover:scale-105 transition-all duration-300"
                  >
                    <div className={`w-16 h-16 bg-gradient-to-r ${feature.color} rounded-2xl flex items-center justify-center mb-4 mx-auto shadow-lg`}>
                      <feature.icon className="w-8 h-8 text-white" />
                    </div>
                    <h3 className="text-xl font-bold text-white mb-2">{feature.title}</h3>
                    <p className="text-gray-400">{feature.description}</p>
                  </motion.div>
                ))}
              </motion.div>
            )}
          </AnimatePresence>
        </motion.div>

        {/* Scroll Indicator */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 3 }}
          className="absolute bottom-8 left-1/2 transform -translate-x-1/2"
        >
          <motion.div
            animate={{ y: [0, 10, 0] }}
            transition={{ duration: 2, repeat: Infinity }}
            className="flex flex-col items-center space-y-2 text-gray-400"
          >
            <span className="text-sm">Scroll to explore</span>
            <ChevronDown className="w-5 h-5" />
          </motion.div>
        </motion.div>
      </motion.div>

      {/* Interactive Cursor Effect */}
      <motion.div
        className="absolute pointer-events-none z-50"
        style={{
          left: mousePosition.x,
          top: mousePosition.y,
          transform: 'translate(-50%, -50%)'
        }}
      >
        <motion.div
          className="w-8 h-8 rounded-full bg-gradient-to-r from-purple-500 to-blue-500 opacity-30"
          animate={{
            scale: [1, 1.5, 1],
            opacity: [0.3, 0.6, 0.3]
          }}
          transition={{ duration: 2, repeat: Infinity }}
        />
      </motion.div>
    </motion.div>
  )
}

export default InteractiveHero
