'use client'

import React, { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  ArrowRight,
  Play,
  Pause,
  RotateCcw,
  Sparkles,
  Brain,
  Layers,
  Network,
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
  Star,
  Users,
  TrendingUp,
  Shield,
  CheckCircle,
  ArrowUpRight,
  Menu,
  X
} from 'lucide-react'

import {
  ModernCard,
  AnimatedMetric,
  ProgressRing,
  AnimatedParticles,
  ModernToggle
} from './ModernDesignSystem'

export default function ModernLandingPage() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [activeFeature, setActiveFeature] = useState(0)
  const [isPlaying, setIsPlaying] = useState(true)

  const features = [
    {
      icon: Brain,
      title: 'AI-Powered Analytics',
      description: 'Advanced machine learning algorithms provide real-time insights and predictions',
      color: 'from-purple-500 to-pink-500'
    },
    {
      icon: Network,
      title: 'Multi-Chain Support',
      description: 'Monitor and analyze data across all major blockchain networks',
      color: 'from-blue-500 to-cyan-500'
    },
    {
      icon: Shield,
      title: 'Security First',
      description: 'Enterprise-grade security with real-time threat detection',
      color: 'from-emerald-500 to-teal-500'
    },
    {
      icon: TrendingUp,
      title: 'Real-Time Monitoring',
      description: 'Live data streams with instant alerts and notifications',
      color: 'from-orange-500 to-red-500'
    }
  ]

  const stats = [
    { value: '2.4B+', label: 'Total Value Locked', icon: TrendingUp },
    { value: '124K+', label: 'Active Users', icon: Users },
    { value: '99.9%', label: 'Uptime', icon: CheckCircle },
    { value: '50+', label: 'Supported Networks', icon: Network }
  ]

  const testimonials = [
    {
      name: 'Sarah Chen',
      role: 'DeFi Analyst',
      company: 'Crypto Capital',
      content: 'DeFiMon has revolutionized how we analyze DeFi protocols. The AI insights are incredibly accurate.',
      avatar: 'SC'
    },
    {
      name: 'Marcus Rodriguez',
      role: 'Portfolio Manager',
      company: 'Digital Assets Fund',
      content: 'The real-time monitoring capabilities have given us a significant edge in the market.',
      avatar: 'MR'
    },
    {
      name: 'Alex Thompson',
      role: 'Blockchain Developer',
      company: 'DeFi Labs',
      content: 'The multi-chain support and API integration make it perfect for our development needs.',
      avatar: 'AT'
    }
  ]

  useEffect(() => {
    if (isPlaying) {
      const interval = setInterval(() => {
        setActiveFeature((prev) => (prev + 1) % features.length)
      }, 3000)
      return () => clearInterval(interval)
    }
  }, [isPlaying, features.length])

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-black to-gray-800 relative overflow-hidden">
      {/* Animated Background */}
      <AnimatedParticles />
      
      {/* Navigation */}
      <motion.nav 
        className="relative z-50 bg-black/20 backdrop-blur-2xl border-b border-white/10"
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        transition={{ type: "spring", stiffness: 100, damping: 20 }}
      >
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            {/* Logo */}
            <motion.div
              className="flex items-center space-x-4"
              whileHover={{ scale: 1.05 }}
            >
              <div className="w-12 h-12 bg-gradient-to-r from-purple-500 via-pink-500 to-blue-500 rounded-2xl flex items-center justify-center shadow-lg shadow-purple-500/25">
                <Sparkles className="w-7 h-7 text-white" />
              </div>
              <div>
                <h1 className="text-2xl font-black text-white">DeFiMon</h1>
                <p className="text-sm text-gray-400">Next-Gen Analytics</p>
              </div>
            </motion.div>

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center space-x-8">
              <a href="#features" className="text-gray-300 hover:text-white transition-colors">Features</a>
              <a href="#analytics" className="text-gray-300 hover:text-white transition-colors">Analytics</a>
              <a href="#pricing" className="text-gray-300 hover:text-white transition-colors">Pricing</a>
              <a href="#about" className="text-gray-300 hover:text-white transition-colors">About</a>
            </div>

            {/* CTA Buttons */}
            <div className="hidden md:flex items-center space-x-4">
              <motion.button
                className="px-6 py-2 text-white hover:text-purple-400 transition-colors"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                Sign In
              </motion.button>
              <motion.button
                className="px-6 py-2 bg-gradient-to-r from-purple-500 to-blue-500 text-white rounded-xl font-semibold shadow-lg shadow-purple-500/25 hover:shadow-purple-500/40 transition-all"
                whileHover={{ scale: 1.05, y: -2 }}
                whileTap={{ scale: 0.95 }}
              >
                Get Started
              </motion.button>
            </div>

            {/* Mobile Menu Button */}
            <motion.button
              className="md:hidden p-2 text-white"
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              whileTap={{ scale: 0.95 }}
            >
              {isMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </motion.button>
          </div>

          {/* Mobile Menu */}
          <AnimatePresence>
            {isMenuOpen && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="md:hidden mt-4 space-y-4"
              >
                <a href="#features" className="block text-gray-300 hover:text-white transition-colors">Features</a>
                <a href="#analytics" className="block text-gray-300 hover:text-white transition-colors">Analytics</a>
                <a href="#pricing" className="block text-gray-300 hover:text-white transition-colors">Pricing</a>
                <a href="#about" className="block text-gray-300 hover:text-white transition-colors">About</a>
                <div className="pt-4 space-y-2">
                  <button className="w-full px-6 py-2 text-white hover:text-purple-400 transition-colors">Sign In</button>
                  <button className="w-full px-6 py-2 bg-gradient-to-r from-purple-500 to-blue-500 text-white rounded-xl font-semibold">Get Started</button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </motion.nav>

      {/* Hero Section */}
      <section className="relative z-10 pt-20 pb-32">
        <div className="max-w-7xl mx-auto px-6 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <h1 className="text-6xl md:text-8xl font-black text-transparent bg-clip-text bg-gradient-to-r from-purple-400 via-pink-400 to-blue-400 mb-6">
              The Future of
              <br />
              <span className="bg-gradient-to-r from-emerald-400 via-teal-400 to-cyan-400 bg-clip-text text-transparent">
                DeFi Analytics
              </span>
            </h1>
            <p className="text-xl md:text-2xl text-gray-300 max-w-4xl mx-auto mb-8">
              Experience next-generation blockchain analytics with AI-powered insights, 
              real-time monitoring, and interactive network visualization
            </p>
            
            <div className="flex flex-col sm:flex-row gap-6 justify-center items-center mb-12">
              <motion.button
                className="group flex items-center space-x-3 px-10 py-5 bg-gradient-to-r from-purple-500 to-blue-500 text-white rounded-2xl font-bold text-lg shadow-2xl shadow-purple-500/25 hover:shadow-purple-500/40 transition-all"
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
                <Play className="w-5 h-5" />
                <span>Watch Demo</span>
              </motion.button>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
              {stats.map((stat, index) => {
                const Icon = stat.icon
                return (
                  <motion.div
                    key={stat.label}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.2 + index * 0.1 }}
                    className="text-center"
                  >
                    <div className="flex items-center justify-center mb-2">
                      <Icon className="w-6 h-6 text-purple-400 mr-2" />
                      <span className="text-3xl font-bold text-white">{stat.value}</span>
                    </div>
                    <p className="text-gray-400">{stat.label}</p>
                  </motion.div>
                )
              })}
            </div>
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="relative z-10 py-20">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-6xl font-black text-white mb-6">
              Powerful Features for
              <br />
              <span className="bg-gradient-to-r from-purple-400 to-blue-400 bg-clip-text text-transparent">
                Modern Analytics
              </span>
            </h2>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              Discover the tools that make DeFiMon the most advanced blockchain analytics platform
            </p>
          </motion.div>

          {/* Feature Showcase */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            {/* Feature Cards */}
            <div className="space-y-6">
              {features.map((feature, index) => {
                const Icon = feature.icon
                return (
                  <motion.div
                    key={feature.title}
                    initial={{ opacity: 0, x: -20 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    viewport={{ once: true }}
                    transition={{ delay: index * 0.1 }}
                    className={`p-6 rounded-2xl backdrop-blur-sm border transition-all duration-300 ${
                      activeFeature === index
                        ? 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 border-purple-500/30'
                        : 'bg-white/5 border-white/10 hover:bg-white/10'
                    }`}
                    onClick={() => setActiveFeature(index)}
                  >
                    <div className="flex items-start space-x-4">
                      <div className={`w-12 h-12 bg-gradient-to-r ${feature.color} rounded-xl flex items-center justify-center`}>
                        <Icon className="w-6 h-6 text-white" />
                      </div>
                      <div>
                        <h3 className="text-xl font-bold text-white mb-2">{feature.title}</h3>
                        <p className="text-gray-400">{feature.description}</p>
                      </div>
                    </div>
                  </motion.div>
                )
              })}
            </div>

            {/* Feature Preview */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8 }}
              className="relative"
            >
              <ModernCard className="p-8" glow>
                <div className="text-center mb-6">
                  <div className={`w-16 h-16 bg-gradient-to-r ${features[activeFeature].color} rounded-2xl flex items-center justify-center mx-auto mb-4`}>
                    {React.createElement(features[activeFeature].icon, { className: "w-8 h-8 text-white" })}
                  </div>
                  <h3 className="text-2xl font-bold text-white mb-2">{features[activeFeature].title}</h3>
                  <p className="text-gray-400">{features[activeFeature].description}</p>
                </div>
                
                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Performance</span>
                    <ProgressRing progress={85} color="emerald" size={60} />
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Accuracy</span>
                    <ProgressRing progress={92} color="blue" size={60} />
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Reliability</span>
                    <ProgressRing progress={99} color="purple" size={60} />
                  </div>
                </div>
              </ModernCard>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="relative z-10 py-20">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-6xl font-black text-white mb-6">
              Trusted by
              <br />
              <span className="bg-gradient-to-r from-emerald-400 to-teal-400 bg-clip-text text-transparent">
                Industry Leaders
              </span>
            </h2>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {testimonials.map((testimonial, index) => (
              <motion.div
                key={testimonial.name}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.2 }}
              >
                <ModernCard className="p-6">
                  <div className="flex items-center mb-4">
                    <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-blue-500 rounded-full flex items-center justify-center text-white font-bold mr-4">
                      {testimonial.avatar}
                    </div>
                    <div>
                      <h4 className="text-white font-semibold">{testimonial.name}</h4>
                      <p className="text-gray-400 text-sm">{testimonial.role} at {testimonial.company}</p>
                    </div>
                  </div>
                  <p className="text-gray-300 mb-4">"{testimonial.content}"</p>
                  <div className="flex space-x-1">
                    {[...Array(5)].map((_, i) => (
                      <Star key={i} className="w-4 h-4 text-yellow-400 fill-current" />
                    ))}
                  </div>
                </ModernCard>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="relative z-10 py-20">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
            className="relative overflow-hidden bg-gradient-to-r from-purple-600/20 via-pink-600/20 to-blue-600/20 backdrop-blur-xl rounded-3xl p-12 border border-white/10"
          >
            <div className="absolute inset-0 bg-gradient-to-r from-purple-600/10 via-pink-600/10 to-blue-600/10 animate-pulse"></div>
            
            <div className="relative z-10 text-center">
              <h2 className="text-4xl md:text-6xl font-black text-white mb-6">
                Ready to Transform
                <br />
                <span className="bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent">
                  Your DeFi Strategy?
                </span>
              </h2>
              
              <p className="text-xl text-gray-300 max-w-3xl mx-auto mb-10">
                Join thousands of professionals who rely on DeFiMon for cutting-edge 
                blockchain analytics and AI-powered market insights
              </p>
              
              <div className="flex flex-col sm:flex-row gap-6 justify-center items-center">
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
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="relative z-10 py-12 border-t border-white/10">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <div className="flex items-center space-x-4 mb-4 md:mb-0">
              <div className="w-10 h-10 bg-gradient-to-r from-purple-500 via-pink-500 to-blue-500 rounded-xl flex items-center justify-center">
                <Sparkles className="w-6 h-6 text-white" />
              </div>
              <div>
                <h3 className="text-xl font-bold text-white">DeFiMon</h3>
                <p className="text-sm text-gray-400">Next-Gen Analytics</p>
              </div>
            </div>
            
            <div className="flex items-center space-x-6">
              <a href="#" className="text-gray-400 hover:text-white transition-colors">Privacy</a>
              <a href="#" className="text-gray-400 hover:text-white transition-colors">Terms</a>
              <a href="#" className="text-gray-400 hover:text-white transition-colors">Support</a>
              <a href="#" className="text-gray-400 hover:text-white transition-colors">Contact</a>
            </div>
          </div>
          
          <div className="mt-8 pt-8 border-t border-white/10 text-center">
            <p className="text-gray-400">
              © 2024 DeFiMon. All rights reserved. Built with modern design principles.
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
}
