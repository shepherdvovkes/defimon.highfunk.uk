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
  Download,
  BarChart3,
  TrendingUp,
  Shield,
  Cpu
} from 'lucide-react'

// Import our custom components
import AdvancedMetricsPanel from '../../components/demo/AdvancedMetricsPanel'
import AIAnalyticsInterface from '../../components/demo/AIAnalyticsInterface'
import InteractiveNetworkMap from '../../components/demo/InteractiveNetworkMap'
import InteractiveHero from '../../components/demo/InteractiveHero'
import EnhancedDashboard from '../../components/demo/EnhancedDashboard'
import ModernLandingPage from '../../components/demo/ModernLandingPage'
import DeepAnalysisPanel from '../../components/demo/DeepAnalysisPanel'

export default function DemoPage() {
  const [activeSection, setActiveSection] = useState<'metrics' | 'ai' | 'networks' | 'enhanced' | 'landing' | 'analysis'>('metrics')
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
      icon: BarChart3,
      color: 'from-blue-500 via-purple-500 to-pink-500',
      gradient: 'bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500',
      component: AdvancedMetricsPanel
    },
    {
      id: 'ai',
      title: 'AI Intelligence',
      subtitle: 'Machine learning predictions and market analysis',
      icon: Brain,
      color: 'from-purple-500 via-pink-500 to-red-500',
      gradient: 'bg-gradient-to-r from-purple-500 via-pink-500 to-red-500',
      component: AIAnalyticsInterface
    },
    {
      id: 'networks',
      title: 'Network Topology',
      subtitle: 'Real-time blockchain infrastructure visualization',
      icon: Network,
      color: 'from-emerald-500 via-teal-500 to-blue-500',
      gradient: 'bg-gradient-to-r from-emerald-500 via-teal-500 to-blue-500',
      component: InteractiveNetworkMap
    },
    {
      id: 'analysis',
      title: 'Deep Analysis',
      subtitle: 'Advanced risk assessment and predictive insights',
      icon: Shield,
      color: 'from-orange-500 via-red-500 to-pink-500',
      gradient: 'bg-gradient-to-r from-orange-500 via-red-500 to-pink-500',
      component: DeepAnalysisPanel
    },
    {
      id: 'enhanced',
      title: 'Enhanced Dashboard',
      subtitle: 'Modern design with advanced features',
      icon: TrendingUp,
      color: 'from-indigo-500 via-purple-500 to-pink-500',
      gradient: 'bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500',
      component: EnhancedDashboard
    },
    {
      id: 'landing',
      title: 'Modern Landing',
      subtitle: 'Showcase page with design system',
      icon: Globe,
      color: 'from-emerald-500 via-teal-500 to-cyan-500',
      gradient: 'bg-gradient-to-r from-emerald-500 via-teal-500 to-cyan-500',
      component: ModernLandingPage
    }
  ]

  const tourSteps = [
    "Explore real-time DeFi metrics",
    "Discover AI-powered predictions",
    "Monitor network infrastructure",
    "Analyze risk and performance",
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

  const handleSectionChange = (sectionId: 'metrics' | 'ai' | 'networks' | 'enhanced' | 'landing' | 'analysis') => {
    setActiveSection(sectionId)
    setDemoMode('interactive')
  }

  const handleStartDemo = () => {
    setShowHero(false)
    setActiveSection('metrics')
    setDemoMode('guided')
  }

  return (
    <div ref={containerRef} className="min-h-screen overflow-hidden bg-gradient-to-br from-neutral-950 via-neutral-900 to-neutral-800">
      {/* Hero Section */}
      <AnimatePresence>
        {showHero && (
          <motion.div
            initial={{ opacity: 1 }}
            exit={{ opacity: 0, y: -100 }}
            transition={{ duration: 0.8, ease: "easeInOut" }}
            className="fixed inset-0 z-50"
          >
            <InteractiveHero onStartDemo={handleStartDemo} />
          </motion.div>
        )}
      </AnimatePresence>

      {/* Animated Background */}
      <motion.div 
        className="absolute inset-0 opacity-20"
        style={{ y: backgroundY }}
      >
        <div className="absolute inset-0 bg-gradient-to-br from-purple-900/30 via-transparent to-blue-900/30"></div>
        <div className="absolute top-20 left-20 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-40 right-40 w-80 h-80 bg-blue-500/10 rounded-full blur-3xl animate-pulse delay-1000"></div>
        <div className="absolute top-1/2 left-1/2 w-64 h-64 bg-emerald-500/10 rounded-full blur-3xl animate-pulse delay-500"></div>
        <div className="absolute top-1/3 right-1/3 w-48 h-48 bg-pink-500/10 rounded-full blur-3xl animate-pulse delay-1500"></div>
      </motion.div>

      {/* Main Demo Content */}
      {!showHero && (
        <>
          {/* Navigation Header */}
          <motion.header 
            className="relative z-50 glass-dark border-b border-white/5"
            initial={{ y: -100, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ type: "spring", stiffness: 100, damping: 20, delay: 0.2 }}
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
                    <div className="w-12 h-12 bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 rounded-2xl flex items-center justify-center shadow-lg shadow-purple-500/25">
                      <Sparkles className="w-7 h-7 text-white" />
                    </div>
                    <div className="absolute inset-0 bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 rounded-2xl blur-lg opacity-30 animate-pulse"></div>
                  </motion.div>
                  <div>
                    <h1 className="text-2xl font-black text-white font-display">DeFiMon</h1>
                    <p className="text-sm text-neutral-400 font-medium">Advanced Analytics Platform</p>
                  </div>
                </div>

                {/* Demo Controls */}
                <div className="flex items-center space-x-4">
                  {/* Mode Toggle */}
                  <div className="flex glass rounded-2xl p-1 border border-white/10">
                    <motion.button
                      onClick={() => setDemoMode('interactive')}
                      className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all duration-300 ${
                        demoMode === 'interactive'
                          ? 'bg-gradient-to-r from-blue-500 to-purple-500 text-white shadow-lg shadow-blue-500/25'
                          : 'text-neutral-400 hover:text-white hover:bg-white/5'
                      }`}
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                    >
                      Interactive
                    </motion.button>
                    <motion.button
                      onClick={() => setDemoMode('guided')}
                      className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all duration-300 ${
                        demoMode === 'guided'
                          ? 'bg-gradient-to-r from-blue-500 to-purple-500 text-white shadow-lg shadow-blue-500/25'
                          : 'text-neutral-400 hover:text-white hover:bg-white/5'
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
                    className="p-3 glass hover:bg-white/10 rounded-xl text-white border border-white/10 transition-all duration-300"
                    whileHover={{ scale: 1.05, boxShadow: "0 10px 25px -5px rgba(0, 0, 0, 0.25)" }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <Maximize2 className="w-5 h-5" />
                  </motion.button>

                  <motion.a
                    href="/"
                    className="flex items-center space-x-2 px-6 py-3 bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-xl font-semibold shadow-lg shadow-emerald-500/25 hover:shadow-emerald-500/40 transition-all duration-300"
                    whileHover={{ scale: 1.05, y: -2 }}
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
                <h1 className="text-6xl md:text-8xl font-black font-display text-transparent bg-clip-text bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400 mb-6 leading-tight">
                  Future of
                  <br />
                  <span className="bg-gradient-to-r from-emerald-400 via-teal-400 to-cyan-400 bg-clip-text text-transparent">
                    DeFi Analytics
                  </span>
                </h1>
                <p className="text-xl md:text-2xl text-neutral-300 max-w-4xl mx-auto mb-8 font-medium leading-relaxed">
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
                    className="inline-flex items-center space-x-4 px-6 py-3 glass rounded-2xl border border-white/10 mb-12"
                  >
                    <div className="flex space-x-2">
                      {tourSteps.map((_, index) => (
                        <motion.div
                          key={index}
                          className={`w-3 h-3 rounded-full transition-all duration-300 ${
                            index === currentTour ? 'bg-blue-500 scale-125' : 'bg-neutral-600'
                          }`}
                          animate={index === currentTour ? { scale: [1, 1.25, 1] } : {}}
                          transition={{ duration: 2, repeat: Infinity }}
                        />
                      ))}
                    </div>
                    <span className="text-neutral-300 font-semibold">
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
                <div className="flex space-x-2 p-2 glass rounded-3xl border border-white/10">
                  {sections.map((section) => {
                    const Icon = section.icon
                    return (
                      <motion.button
                        key={section.id}
                        onClick={() => handleSectionChange(section.id as any)}
                        className={`relative flex items-center space-x-3 px-8 py-4 rounded-2xl font-semibold transition-all duration-300 ${
                          activeSection === section.id
                            ? 'text-white shadow-2xl'
                            : 'text-neutral-400 hover:text-white hover:bg-white/5'
                        }`}
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                      >
                        {activeSection === section.id && (
                          <motion.div
                            className={`absolute inset-0 ${section.gradient} rounded-2xl opacity-80`}
                            layoutId="activeSection"
                            initial={false}
                            transition={{ type: "spring", stiffness: 500, damping: 40 }}
                          />
                        )}
                        <Icon className="w-6 h-6 relative z-10" />
                        <div className="relative z-10">
                          <div className="font-bold text-sm">{section.title}</div>
                          <div className="text-xs opacity-75 font-medium">{section.subtitle}</div>
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
            className={`relative z-10 ${isFullscreen ? 'fixed inset-0 bg-neutral-950 z-50' : 'pb-20'}`}
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
                  {activeSection === 'analysis' && <DeepAnalysisPanel />}
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
                className="fixed top-6 right-6 z-60 p-3 glass hover:bg-white/10 rounded-xl text-white border border-white/20 transition-all duration-300"
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
                <div className="relative overflow-hidden glass rounded-3xl p-12 border border-white/10">
                  <div className="absolute inset-0 bg-gradient-to-r from-blue-600/10 via-purple-600/10 to-pink-600/10 animate-pulse"></div>
                  
                  <div className="relative z-10 text-center">
                    <motion.h2 
                      className="text-4xl md:text-6xl font-black font-display text-white mb-6 leading-tight"
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
                      className="text-xl text-neutral-300 max-w-3xl mx-auto mb-10 font-medium leading-relaxed"
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
                        className="group flex items-center space-x-3 px-10 py-5 bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-2xl font-bold text-lg shadow-2xl shadow-emerald-500/25 hover:shadow-emerald-500/40 transition-all duration-300"
                        whileHover={{ scale: 1.05, y: -5 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        <span>Start Free Trial</span>
                        <ArrowRight className="w-6 h-6 group-hover:translate-x-1 transition-transform duration-300" />
                      </motion.button>
                      
                      <motion.button
                        className="group flex items-center space-x-3 px-10 py-5 glass text-white rounded-2xl font-bold text-lg border border-white/20 hover:bg-white/10 transition-all duration-300"
                        whileHover={{ scale: 1.05, y: -5 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        <Github className="w-5 h-5" />
                        <span>View on GitHub</span>
                        <ExternalLink className="w-4 h-4 group-hover:translate-x-1 transition-transform duration-300" />
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
                        <Download className="w-5 h-5 text-neutral-400" />
                        <span className="text-neutral-400 font-medium">Export Data</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Settings className="w-5 h-5 text-neutral-400" />
                        <span className="text-neutral-400 font-medium">Custom Alerts</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Eye className="w-5 h-5 text-neutral-400" />
                        <span className="text-neutral-400 font-medium">24/7 Monitoring</span>
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
