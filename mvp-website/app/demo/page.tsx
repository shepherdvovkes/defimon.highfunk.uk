'use client'

import '../globals.css'
import { motion, AnimatePresence, useScroll, useTransform } from 'framer-motion'
import { useState, useEffect, useRef } from 'react'
import { 
  Sparkles,
  Brain,
  Layers,
  Network,
  ArrowRight,
  Play,
  Pause,
  RotateCcw,
  Target,
  Globe,
  Zap,
  Eye,
  Settings,
  Maximize2,
  ChevronDown,
  Github,
  ExternalLink,
  Download
} from 'lucide-react'

// Import our custom components
import AdvancedMetricsPanel from '../../components/demo/AdvancedMetricsPanel'
import AIAnalyticsInterface from '../../components/demo/AIAnalyticsInterface'
import InteractiveNetworkMap from '../../components/demo/InteractiveNetworkMap'
import InteractiveHero from '../../components/demo/InteractiveHero'
import EnhancedDashboard from '../../components/demo/EnhancedDashboard'
import ModernLandingPage from '../../components/demo/ModernLandingPage'

export default function DemoPage() {
  const [activeSection, setActiveSection] = useState<'metrics' | 'ai' | 'networks' | 'enhanced' | 'landing'>('metrics')
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [demoMode, setDemoMode] = useState<'guided' | 'interactive'>('interactive')
  const [currentTour, setCurrentTour] = useState(0)
  const [showHero, setShowHero] = useState(true)
  
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({ target: containerRef })
  
  // Transform for parallax effects
  const backgroundY = useTransform(scrollYProgress, [0, 1], ['0%', '50%'])
  const titleScale = useTransform(scrollYProgress, [0, 0.2], [1, 0.9])
  const titleOpacity = useTransform(scrollYProgress, [0, 0.3], [1, 0])

  const sections = [
    {
      id: 'metrics',
      title: 'Advanced Analytics',
      subtitle: 'Real-time metrics with AI-powered insights',
      icon: Target,
      color: 'from-blue-500 via-purple-500 to-pink-500',
      component: AdvancedMetricsPanel
    },
    {
      id: 'ai',
      title: 'AI Intelligence',
      subtitle: 'Machine learning predictions and market analysis',
      icon: Brain,
      color: 'from-purple-500 via-pink-500 to-red-500',
      component: AIAnalyticsInterface
    },
    {
      id: 'networks',
      title: 'Network Topology',
      subtitle: 'Real-time blockchain infrastructure visualization',
      icon: Network,
      color: 'from-green-500 via-teal-500 to-blue-500',
      component: InteractiveNetworkMap
    },
    {
      id: 'enhanced',
      title: 'Enhanced Dashboard',
      subtitle: 'Modern design with advanced features',
      icon: Sparkles,
      color: 'from-indigo-500 via-purple-500 to-pink-500',
      component: EnhancedDashboard
    },
    {
      id: 'landing',
      title: 'Modern Landing',
      subtitle: 'Showcase page with design system',
      icon: Globe,
      color: 'from-emerald-500 via-teal-500 to-cyan-500',
      component: ModernLandingPage
    }
  ]

  const tourSteps = [
    "Explore real-time DeFi metrics",
    "Discover AI-powered predictions",
    "Monitor network infrastructure",
    "Experience the full platform"
  ]

  useEffect(() => {
    if (demoMode === 'guided') {
      const interval = setInterval(() => {
        setCurrentTour((prev) => {
          const next = (prev + 1) % tourSteps.length
          if (next < sections.length) {
            setActiveSection(sections[next].id as any)
          }
          return next
        })
      }, 8000)
      
      return () => clearInterval(interval)
    }
  }, [demoMode])

  const handleSectionChange = (sectionId: 'metrics' | 'ai' | 'networks' | 'enhanced' | 'landing') => {
    setActiveSection(sectionId)
    setDemoMode('interactive')
  }

  const handleStartDemo = () => {
    setShowHero(false)
    setActiveSection('metrics')
    setDemoMode('guided')
  }

  return (
    <div ref={containerRef} className="min-h-screen overflow-hidden bg-gradient-to-br from-gray-900 via-black to-gray-800">
      {/* Hero Section */}
      <AnimatePresence>
        {showHero && (
          <motion.div
            initial={{ opacity: 1 }}
            exit={{ opacity: 0, y: -100 }}
            transition={{ duration: 0.8 }}
            className="fixed inset-0 z-50"
          >
            <InteractiveHero onStartDemo={handleStartDemo} />
          </motion.div>
        )}
      </AnimatePresence>

      {/* Animated Background */}
      <motion.div 
        className="absolute inset-0 opacity-30"
        style={{ y: backgroundY }}
      >
        <div className="absolute inset-0 bg-gradient-to-br from-purple-900/20 via-transparent to-blue-900/20"></div>
        <div className="absolute top-20 left-20 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-40 right-40 w-80 h-80 bg-blue-500/10 rounded-full blur-3xl animate-pulse delay-1000"></div>
        <div className="absolute top-1/2 left-1/2 w-64 h-64 bg-green-500/10 rounded-full blur-3xl animate-pulse delay-500"></div>
      </motion.div>

      {/* Main Demo Content */}
      {!showHero && (
        <>
          {/* Navigation Header */}
          <motion.header 
            className="relative z-50 bg-black/20 backdrop-blur-2xl border-b border-white/10"
            initial={{ y: -100 }}
            animate={{ y: 0 }}
            transition={{ type: "spring", stiffness: 100, damping: 20 }}
          >
            <div className="max-w-7xl mx-auto px-6 py-4">
              <div className="flex items-center justify-between">
                {/* Logo Section */}
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
                    <h1 className="text-2xl font-black text-white">DeFiMon</h1>
                    <p className="text-sm text-gray-400">Advanced Demo</p>
                  </div>
                </div>

                {/* Demo Controls */}
                <div className="flex items-center space-x-4">
                  {/* Mode Toggle */}
                  <div className="flex bg-gray-800/50 backdrop-blur-sm rounded-2xl p-1 border border-white/10">
                    <motion.button
                      onClick={() => setDemoMode('interactive')}
                      className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
                        demoMode === 'interactive'
                          ? 'bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg shadow-purple-500/25'
                          : 'text-gray-400 hover:text-white'
                      }`}
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                    >
                      Interactive
                    </motion.button>
                    <motion.button
                      onClick={() => setDemoMode('guided')}
                      className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
                        demoMode === 'guided'
                          ? 'bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg shadow-purple-500/25'
                          : 'text-gray-400 hover:text-white'
                      }`}
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                    >
                      Guided Tour
                    </motion.button>
                  </div>

                  {/* Action Buttons */}
                  <motion.button
                    onClick={() => setIsFullscreen(!isFullscreen)}
                    className="p-3 bg-gray-800/50 backdrop-blur-sm hover:bg-gray-700/50 rounded-xl text-white border border-white/10 transition-all"
                    whileHover={{ scale: 1.05, boxShadow: "0 10px 25px -5px rgba(0, 0, 0, 0.25)" }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <Maximize2 className="w-5 h-5" />
                  </motion.button>

                  <motion.a
                    href="/"
                    className="flex items-center space-x-2 px-6 py-3 bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-xl font-semibold shadow-lg shadow-emerald-500/25 hover:shadow-emerald-500/40 transition-all"
                    whileHover={{ scale: 1.05, boxShadow: "0 20px 40px -5px rgba(16, 185, 129, 0.25)" }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <span>Home</span>
                    <ArrowRight className="w-4 h-4" />
                  </motion.a>
                </div>
              </div>
            </div>
          </motion.header>

          {/* Hero Section */}
          <motion.section 
            className="relative z-10 pt-20 pb-12"
            style={{ scale: titleScale, opacity: titleOpacity }}
          >
            <div className="max-w-7xl mx-auto px-6 text-center">
              <motion.div
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: 0.2 }}
              >
                <h1 className="text-6xl md:text-8xl font-black text-transparent bg-clip-text bg-gradient-to-r from-purple-400 via-pink-400 to-blue-400 mb-6">
                  Future of
                  <br />
                  <span className="bg-gradient-to-r from-emerald-400 via-teal-400 to-cyan-400 bg-clip-text text-transparent">
                    DeFi Analytics
                  </span>
                </h1>
                <p className="text-xl md:text-2xl text-gray-300 max-w-4xl mx-auto mb-8">
                  Experience next-generation blockchain analytics with AI-powered insights, 
                  real-time monitoring, and interactive network visualization
                </p>
              </motion.div>

              {/* Guided Tour Progress */}
              <AnimatePresence>
                {demoMode === 'guided' && (
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -20 }}
                    className="inline-flex items-center space-x-4 px-6 py-3 bg-black/30 backdrop-blur-xl rounded-2xl border border-white/10 mb-12"
                  >
                    <div className="flex space-x-2">
                      {tourSteps.map((_, index) => (
                        <motion.div
                          key={index}
                          className={`w-3 h-3 rounded-full transition-all ${
                            index === currentTour ? 'bg-purple-500 scale-125' : 'bg-gray-600'
                          }`}
                          animate={index === currentTour ? { scale: [1, 1.25, 1] } : {}}
                          transition={{ duration: 2, repeat: Infinity }}
                        />
                      ))}
                    </div>
                    <span className="text-gray-300 font-medium">
                      {tourSteps[currentTour]}
                    </span>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </motion.section>

          {/* Section Navigation */}
          <motion.nav 
            className="relative z-20 mb-12"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
          >
            <div className="max-w-7xl mx-auto px-6">
              <div className="flex justify-center">
                <div className="flex space-x-2 p-2 bg-black/20 backdrop-blur-2xl rounded-3xl border border-white/10">
                  {sections.map((section) => {
                    const Icon = section.icon
                    return (
                      <motion.button
                        key={section.id}
                        onClick={() => handleSectionChange(section.id as any)}
                        className={`relative flex items-center space-x-3 px-8 py-4 rounded-2xl font-semibold transition-all duration-300 ${
                          activeSection === section.id
                            ? 'text-white shadow-2xl'
                            : 'text-gray-400 hover:text-white hover:bg-white/5'
                        }`}
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                      >
                        {activeSection === section.id && (
                          <motion.div
                            className={`absolute inset-0 bg-gradient-to-r ${section.color} rounded-2xl opacity-80`}
                            layoutId="activeSection"
                            initial={false}
                            transition={{ type: "spring", stiffness: 500, damping: 40 }}
                          />
                        )}
                        <Icon className="w-6 h-6 relative z-10" />
                        <div className="relative z-10">
                          <div className="font-bold">{section.title}</div>
                          <div className="text-xs opacity-75">{section.subtitle}</div>
                        </div>
                      </motion.button>
                    )
                  })}
                </div>
              </div>
            </div>
          </motion.nav>

          {/* Main Content Area */}
          <motion.main 
            className={`relative z-10 ${isFullscreen ? 'fixed inset-0 bg-black z-50' : 'pb-20'}`}
            layout
          >
            <div className={`${isFullscreen ? 'h-full' : 'max-w-7xl'} mx-auto px-6`}>
              <AnimatePresence mode="wait">
                <motion.div
                  key={activeSection}
                  initial={{ opacity: 0, y: 20, scale: 0.95 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: -20, scale: 1.05 }}
                  transition={{ duration: 0.5, type: "spring", stiffness: 100 }}
                  className="h-full"
                >
                  {activeSection === 'metrics' && <AdvancedMetricsPanel />}
                  {activeSection === 'ai' && <AIAnalyticsInterface />}
                  {activeSection === 'networks' && <InteractiveNetworkMap />}
                  {activeSection === 'enhanced' && <EnhancedDashboard />}
                  {activeSection === 'landing' && <ModernLandingPage />}
                </motion.div>
              </AnimatePresence>
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
          </motion.main>

          {/* Call to Action Footer */}
          {!isFullscreen && (
            <motion.footer 
              className="relative z-10 mt-20"
              initial={{ opacity: 0, y: 50 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8 }}
            >
              <div className="max-w-7xl mx-auto px-6 pb-20">
                <div className="relative overflow-hidden bg-gradient-to-r from-purple-600/20 via-pink-600/20 to-blue-600/20 backdrop-blur-xl rounded-3xl p-12 border border-white/10">
                  <div className="absolute inset-0 bg-gradient-to-r from-purple-600/10 via-pink-600/10 to-blue-600/10 animate-pulse"></div>
                  
                  <div className="relative z-10 text-center">
                    <motion.h2 
                      className="text-4xl md:text-6xl font-black text-white mb-6"
                      initial={{ opacity: 0, y: 20 }}
                      whileInView={{ opacity: 1, y: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: 0.2 }}
                    >
                      Ready to Transform
                      <br />
                      <span className="bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent">
                        Your DeFi Strategy?
                      </span>
                    </motion.h2>
                    
                    <motion.p 
                      className="text-xl text-gray-300 max-w-3xl mx-auto mb-10"
                      initial={{ opacity: 0, y: 20 }}
                      whileInView={{ opacity: 1, y: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: 0.4 }}
                    >
                      Join thousands of professionals who rely on DeFiMon for cutting-edge 
                      blockchain analytics and AI-powered market insights
                    </motion.p>
                    
                    <motion.div 
                      className="flex flex-col sm:flex-row gap-6 justify-center items-center"
                      initial={{ opacity: 0, y: 20 }}
                      whileInView={{ opacity: 1, y: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: 0.6 }}
                    >
                      <motion.button
                        className="group flex items-center space-x-3 px-10 py-5 bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-2xl font-bold text-lg shadow-2xl shadow-emerald-500/25 hover:shadow-emerald-500/40 transition-all"
                        whileHover={{ scale: 1.05, y: -5 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        <span>Start Free Trial</span>
                        <ArrowRight className="w-6 h-6 group-hover:translate-x-1 transition-transform" />
                      </motion.button>
                      
                      <motion.button
                        className="group flex items-center space-x-3 px-10 py-5 bg-white/10 backdrop-blur-sm text-white rounded-2xl font-bold text-lg border border-white/20 hover:bg-white/20 transition-all"
                        whileHover={{ scale: 1.05, y: -5 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        <Github className="w-5 h-5" />
                        <span>View on GitHub</span>
                        <ExternalLink className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                      </motion.button>
                    </motion.div>

                    <motion.div 
                      className="flex items-center justify-center space-x-8 mt-12 pt-8 border-t border-white/10"
                      initial={{ opacity: 0 }}
                      whileInView={{ opacity: 1 }}
                      viewport={{ once: true }}
                      transition={{ delay: 0.8 }}
                    >
                      <div className="flex items-center space-x-2">
                        <Download className="w-5 h-5 text-gray-400" />
                        <span className="text-gray-400">Export Data</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Settings className="w-5 h-5 text-gray-400" />
                        <span className="text-gray-400">Custom Alerts</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Eye className="w-5 h-5 text-gray-400" />
                        <span className="text-gray-400">24/7 Monitoring</span>
                      </div>
                    </motion.div>
                  </div>
                </div>
              </div>
            </motion.footer>
          )}
        </>
      )}
    </div>
  )
}
