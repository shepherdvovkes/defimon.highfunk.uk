'use client'

import { motion } from 'framer-motion'
import { useState, useEffect } from 'react'
import { 
  ArrowRight,
  Play,
  Star,
  CheckCircle,
  Users,
  TrendingUp,
  Shield,
  Globe,
  Brain,
  Sparkles,
  Menu,
  X,
  Github,
  Twitter,
  Linkedin,
  Mail,
  Phone,
  MapPin,
  ChevronDown,
  ExternalLink,
  Zap,
  Target,
  Eye,
  BarChart3,
  Activity,
  Cpu,
  Database,
  Lock,
  Unlock,
  Key,
  Fingerprint,
  Scan,
  Monitor,
  Smartphone,
  Tablet,
  Laptop,
  Server,
  Cloud,
  Wifi,
  Signal,
  Battery,
  Power,
  Volume2,
  VolumeX,
  Mic,
  MicOff,
  Camera,
  CameraOff,
  Video,
  VideoOff,
  Phone as PhoneIcon,
  PhoneOff,
  Mail as MailIcon,
  Send,
  Inbox,
  Archive,
  Trash2,
  Edit,
  Edit3,
  Save,
  Save2,
  File,
  FileText,
  FilePlus,
  FileMinus,
  FileX,
  Folder,
  FolderPlus,
  FolderMinus,
  FolderX,
  Image,
  ImagePlus,
  ImageMinus,
  ImageX,
  Music,
  Video2,
  Headphones,
  Speaker,
  Volume,
  Volume1,
  Volume3,
  Mute,
  Play as PlayIcon,
  Pause,
  SkipBack,
  SkipForward,
  Rewind,
  FastForward,
  RotateCcw,
  RotateCw,
  Repeat,
  Shuffle,
  SkipBack2,
  SkipForward2,
  PlayCircle,
  PauseCircle,
  StopCircle,
  Square,
  Circle,
  Triangle,
  Hexagon,
  Octagon,
  Star2,
  Heart2,
  ThumbsUp,
  ThumbsDown,
  MessageCircle2,
  MessageSquare,
  MessageSquare2,
  MessageSquare3,
  MessageSquare4,
  MessageSquare5,
  MessageSquare6,
  MessageSquare7,
  MessageSquare8,
  MessageSquare9,
  MessageSquare10,
  MessageSquare11,
  MessageSquare12,
  MessageSquare13,
  MessageSquare14,
  MessageSquare15,
  MessageSquare16,
  MessageSquare17,
  MessageSquare18,
  MessageSquare19,
  MessageSquare20,
  MessageSquare21,
  MessageSquare22,
  MessageSquare23,
  MessageSquare24,
  MessageSquare25,
  MessageSquare26,
  MessageSquare27,
  MessageSquare28,
  MessageSquare29,
  MessageSquare30,
  MessageSquare31,
  MessageSquare32,
  MessageSquare33,
  MessageSquare34,
  MessageSquare35,
  MessageSquare36,
  MessageSquare37,
  MessageSquare38,
  MessageSquare39,
  MessageSquare40,
  MessageSquare41,
  MessageSquare42,
  MessageSquare43,
  MessageSquare44,
  MessageSquare45,
  MessageSquare46,
  MessageSquare47,
  MessageSquare48,
  MessageSquare49,
  MessageSquare50,
  MessageSquare51,
  MessageSquare52,
  MessageSquare53,
  MessageSquare54,
  MessageSquare55,
  MessageSquare56,
  MessageSquare57,
  MessageSquare58,
  MessageSquare59,
  MessageSquare60,
  MessageSquare61,
  MessageSquare62,
  MessageSquare63,
  MessageSquare64,
  MessageSquare65,
  MessageSquare66,
  MessageSquare67,
  MessageSquare68,
  MessageSquare69,
  MessageSquare70,
  MessageSquare71,
  MessageSquare72,
  MessageSquare73,
  MessageSquare74,
  MessageSquare75,
  MessageSquare76,
  MessageSquare77,
  MessageSquare78,
  MessageSquare79,
  MessageSquare80,
  MessageSquare81,
  MessageSquare82,
  MessageSquare83,
  MessageSquare84,
  MessageSquare85,
  MessageSquare86,
  MessageSquare87,
  MessageSquare88,
  MessageSquare89,
  MessageSquare90,
  MessageSquare91,
  MessageSquare92,
  MessageSquare93,
  MessageSquare94,
  MessageSquare95,
  MessageSquare96,
  MessageSquare97,
  MessageSquare98,
  MessageSquare99,
  MessageSquare100
} from 'lucide-react'

export default function SaaSLandingPage() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [isScrolled, setIsScrolled] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50)
    }
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const features = [
    {
      icon: Brain,
      title: 'AI-Powered Insights',
      description: 'Advanced machine learning algorithms provide real-time predictions and market analysis',
      color: 'from-blue-500 to-purple-500'
    },
    {
      icon: Globe,
      title: 'Multi-Chain Support',
      description: 'Monitor and analyze data across all major blockchain networks simultaneously',
      color: 'from-green-500 to-emerald-500'
    },
    {
      icon: Shield,
      title: 'Enterprise Security',
      description: 'Bank-grade security with real-time threat detection and compliance',
      color: 'from-red-500 to-pink-500'
    },
    {
      icon: TrendingUp,
      title: 'Real-Time Analytics',
      description: 'Live data streams with instant alerts and comprehensive reporting',
      color: 'from-orange-500 to-yellow-500'
    }
  ]

  const benefits = [
    'Reduce risk with AI-powered predictions',
    'Monitor 50+ blockchain networks',
    'Get instant alerts and notifications',
    'Access comprehensive API documentation',
    '24/7 customer support',
    'Enterprise-grade security'
  ]

  const pricingPlans = [
    {
      name: 'Starter',
      price: '$29',
      period: '/month',
      description: 'Perfect for individual traders',
      features: [
        'Real-time DeFi analytics',
        'Basic AI insights',
        '5 network monitoring',
        'Email support',
        'API access (1K calls/month)'
      ],
      popular: false,
      color: 'from-blue-500 to-cyan-500'
    },
    {
      name: 'Professional',
      price: '$99',
      period: '/month',
      description: 'Ideal for growing teams',
      features: [
        'Everything in Starter',
        'Advanced AI predictions',
        'All network monitoring',
        'Priority support',
        'API access (10K calls/month)',
        'Custom alerts',
        'Data export'
      ],
      popular: true,
      color: 'from-purple-500 to-pink-500'
    },
    {
      name: 'Enterprise',
      price: 'Custom',
      period: '',
      description: 'Tailored for large organizations',
      features: [
        'Everything in Professional',
        'Custom AI models',
        'Dedicated support',
        'Unlimited API access',
        'White-label solutions',
        'On-premise deployment'
      ],
      popular: false,
      color: 'from-emerald-500 to-teal-500'
    }
  ]

  const testimonials = [
    {
      name: 'Sarah Chen',
      role: 'DeFi Analyst',
      company: 'Crypto Capital',
      content: 'DeFiMon has revolutionized how we analyze DeFi protocols. The AI insights are incredibly accurate.',
      avatar: 'SC',
      rating: 5
    },
    {
      name: 'Marcus Rodriguez',
      role: 'Portfolio Manager',
      company: 'Digital Assets Fund',
      content: 'The real-time monitoring capabilities have given us a significant edge in the market.',
      avatar: 'MR',
      rating: 5
    },
    {
      name: 'Alex Thompson',
      role: 'Blockchain Developer',
      company: 'DeFi Labs',
      content: 'The multi-chain support and API integration make it perfect for our development needs.',
      avatar: 'AT',
      rating: 5
    }
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-blue-50">
      {/* Navigation */}
      <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled ? 'bg-white/95 backdrop-blur-xl shadow-lg border-b border-gray-200' : 'bg-transparent'
      }`}>
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-500 rounded-xl flex items-center justify-center">
                <Sparkles className="w-6 h-6 text-white" />
              </div>
              <span className="text-2xl font-black text-gray-900">DeFiMon</span>
            </div>

            <div className="hidden md:flex items-center space-x-8">
              {['Features', 'Pricing', 'About', 'Contact'].map((item) => (
                <a
                  key={item}
                  href={`#${item.toLowerCase()}`}
                  className="text-gray-600 hover:text-gray-900 font-medium transition-colors"
                >
                  {item}
                </a>
              ))}
            </div>

            <div className="hidden md:flex items-center space-x-4">
              <a
                href="/demo"
                className="text-gray-600 hover:text-gray-900 font-medium transition-colors"
              >
                Demo
              </a>
              <a
                href="/investor-insights"
                className="text-gray-600 hover:text-gray-900 font-medium transition-colors"
              >
                Investor Insights
              </a>
              <button className="px-6 py-2 bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-xl font-semibold hover:from-blue-600 hover:to-purple-600 transition-all duration-300">
                Get Started
              </button>
            </div>

            <button
              className="md:hidden p-2 text-gray-600"
              onClick={() => setIsMenuOpen(!isMenuOpen)}
            >
              {isMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>

          {isMenuOpen && (
            <div className="md:hidden mt-4 pb-4 border-t border-gray-200">
              <div className="flex flex-col space-y-4 pt-4">
                {['Features', 'Pricing', 'About', 'Contact'].map((item) => (
                  <a
                    key={item}
                    href={`#${item.toLowerCase()}`}
                    className="text-gray-600 hover:text-gray-900 font-medium transition-colors"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    {item}
                  </a>
                ))}
                <div className="pt-4 border-t border-gray-200">
                  <a
                    href="/demo"
                    className="block text-gray-600 hover:text-gray-900 font-medium transition-colors mb-2"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Demo
                  </a>
                  <a
                    href="/investor-insights"
                    className="block text-gray-600 hover:text-gray-900 font-medium transition-colors mb-4"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Investor Insights
                  </a>
                  <button className="w-full px-6 py-3 bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-xl font-semibold hover:from-blue-600 hover:to-purple-600 transition-all duration-300">
                    Get Started
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative pt-32 pb-20 overflow-hidden">
        <div className="absolute inset-0">
          <div className="absolute inset-0 bg-gradient-to-br from-blue-50/50 via-transparent to-purple-50/50"></div>
          <div className="absolute top-20 left-20 w-96 h-96 bg-blue-500/5 rounded-full blur-3xl animate-pulse"></div>
          <div className="absolute bottom-40 right-40 w-80 h-80 bg-purple-500/5 rounded-full blur-3xl animate-pulse delay-1000"></div>
        </div>

        <div className="relative max-w-7xl mx-auto px-6">
          <div className="text-center">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8 }}
            >
              <h1 className="text-5xl md:text-7xl font-black text-gray-900 mb-6 leading-tight">
                The Future of
                <br />
                <span className="bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 bg-clip-text text-transparent">
                  DeFi Analytics
                </span>
              </h1>
              <p className="text-xl md:text-2xl text-gray-600 max-w-4xl mx-auto mb-8 leading-relaxed">
                Advanced AI-powered analytics platform for real-time DeFi monitoring, 
                risk assessment, and investment insights across 50+ blockchain networks.
              </p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.2 }}
              className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-12"
            >
              <button className="group flex items-center space-x-3 px-8 py-4 bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-2xl font-bold text-lg hover:from-blue-600 hover:to-purple-600 transition-all duration-300 shadow-2xl shadow-blue-500/25">
                <span>Start Free Trial</span>
                <ArrowRight className="w-6 h-6 group-hover:translate-x-1 transition-transform duration-300" />
              </button>
              
              <button className="group flex items-center space-x-3 px-8 py-4 bg-white text-gray-900 rounded-2xl font-bold text-lg hover:bg-gray-50 transition-all duration-300 border-2 border-gray-200 shadow-lg">
                <Play className="w-6 h-6" />
                <span>Watch Demo</span>
              </button>
            </motion.div>

            {/* Benefits */}
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.4 }}
              className="grid grid-cols-2 md:grid-cols-3 gap-4 max-w-4xl mx-auto"
            >
              {benefits.map((benefit, index) => (
                <motion.div
                  key={benefit}
                  className="flex items-center space-x-2 text-gray-600"
                  whileHover={{ scale: 1.05 }}
                  transition={{ delay: index * 0.1 }}
                >
                  <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                  <span className="text-sm font-medium">{benefit}</span>
                </motion.div>
              ))}
            </motion.div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-black text-gray-900 mb-6">
              Why Choose <span className="bg-gradient-to-r from-blue-500 to-purple-500 bg-clip-text text-transparent">DeFiMon</span>?
            </h2>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Powerful features designed to give you the edge in DeFi analytics and investment decisions.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, index) => {
              const Icon = feature.icon
              return (
                <motion.div
                  key={feature.title}
                  initial={{ opacity: 0, y: 30 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.6, delay: index * 0.1 }}
                  viewport={{ once: true }}
                  className="group"
                >
                  <div className="bg-white rounded-2xl p-8 shadow-lg hover:shadow-2xl transition-all duration-300 group-hover:scale-105 border border-gray-100">
                    <div className={`w-16 h-16 bg-gradient-to-r ${feature.color} rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300`}>
                      <Icon className="w-8 h-8 text-white" />
                    </div>
                    <h3 className="text-xl font-bold text-gray-900 mb-4">{feature.title}</h3>
                    <p className="text-gray-600 leading-relaxed">{feature.description}</p>
                  </div>
                </motion.div>
              )
            })}
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-black text-gray-900 mb-6">
              Trusted by <span className="bg-gradient-to-r from-blue-500 to-purple-500 bg-clip-text text-transparent">Thousands</span>
            </h2>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              See what our users say about DeFiMon's impact on their DeFi strategies.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {testimonials.map((testimonial, index) => (
              <motion.div
                key={testimonial.name}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-all duration-300"
              >
                <div className="flex items-center mb-4">
                  {[...Array(testimonial.rating)].map((_, i) => (
                    <Star key={i} className="w-5 h-5 text-yellow-400 fill-current" />
                  ))}
                </div>
                <p className="text-gray-600 mb-6 leading-relaxed">"{testimonial.content}"</p>
                <div className="flex items-center">
                  <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full flex items-center justify-center text-white font-bold mr-4">
                    {testimonial.avatar}
                  </div>
                  <div>
                    <div className="text-gray-900 font-semibold">{testimonial.name}</div>
                    <div className="text-gray-500 text-sm">{testimonial.role} at {testimonial.company}</div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-black text-gray-900 mb-6">
              Simple, <span className="bg-gradient-to-r from-blue-500 to-purple-500 bg-clip-text text-transparent">Transparent</span> Pricing
            </h2>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Choose the plan that fits your needs. No hidden fees, no surprises.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {pricingPlans.map((plan, index) => (
              <motion.div
                key={plan.name}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                viewport={{ once: true }}
                className={`relative ${plan.popular ? 'scale-105' : ''}`}
              >
                {plan.popular && (
                  <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                    <span className="bg-gradient-to-r from-blue-500 to-purple-500 text-white px-4 py-2 rounded-full text-sm font-semibold">
                      Most Popular
                    </span>
                  </div>
                )}
                <div className="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-all duration-300 border-2 border-gray-100 h-full">
                  <div className="text-center mb-8">
                    <h3 className="text-2xl font-bold text-gray-900 mb-2">{plan.name}</h3>
                    <div className="flex items-baseline justify-center mb-4">
                      <span className="text-4xl font-black text-gray-900">{plan.price}</span>
                      <span className="text-gray-500 ml-1">{plan.period}</span>
                    </div>
                    <p className="text-gray-600">{plan.description}</p>
                  </div>
                  <ul className="space-y-4 mb-8">
                    {plan.features.map((feature) => (
                      <li key={feature} className="flex items-center">
                        <CheckCircle className="w-5 h-5 text-green-500 mr-3 flex-shrink-0" />
                        <span className="text-gray-700">{feature}</span>
                      </li>
                    ))}
                  </ul>
                  <button className={`w-full py-3 bg-gradient-to-r ${plan.color} text-white rounded-xl font-semibold hover:opacity-90 transition-all duration-300`}>
                    {plan.name === 'Enterprise' ? 'Contact Sales' : 'Get Started'}
                  </button>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-gradient-to-r from-blue-500 to-purple-500">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
          >
            <h2 className="text-4xl md:text-5xl font-black text-white mb-6">
              Ready to Transform Your <span className="text-blue-100">DeFi Strategy</span>?
            </h2>
            <p className="text-xl text-blue-100 mb-8 max-w-2xl mx-auto">
              Join thousands of professionals who trust DeFiMon for their DeFi analytics and investment decisions.
            </p>
            <button className="px-8 py-4 bg-white text-gray-900 rounded-2xl font-bold text-lg hover:bg-gray-100 transition-all duration-300 shadow-2xl">
              Start Your Free Trial Today
            </button>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="md:col-span-2">
              <div className="flex items-center space-x-3 mb-4">
                <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-500 rounded-xl flex items-center justify-center">
                  <Sparkles className="w-6 h-6 text-white" />
                </div>
                <span className="text-2xl font-black">DeFiMon</span>
              </div>
              <p className="text-gray-400 mb-6 max-w-md">
                Advanced DeFi analytics platform with AI/ML integration for predictions and risk assessment.
              </p>
              <div className="flex space-x-4">
                {[Twitter, Github, Linkedin].map((Icon, index) => (
                  <a
                    key={index}
                    href="#"
                    className="w-10 h-10 bg-gray-800 hover:bg-gray-700 rounded-lg flex items-center justify-center text-gray-400 hover:text-white transition-all duration-300"
                  >
                    <Icon className="w-5 h-5" />
                  </a>
                ))}
              </div>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4">Product</h3>
              <ul className="space-y-2">
                {['Features', 'Pricing', 'API', 'Documentation'].map((item) => (
                  <li key={item}>
                    <a href="#" className="text-gray-400 hover:text-white transition-colors">
                      {item}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4">Company</h3>
              <ul className="space-y-2">
                {['About', 'Blog', 'Careers', 'Contact'].map((item) => (
                  <li key={item}>
                    <a href="#" className="text-gray-400 hover:text-white transition-colors">
                      {item}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          </div>
          
          <div className="border-t border-gray-800 mt-8 pt-8 text-center">
            <p className="text-gray-400">
              © 2024 DeFiMon. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
}
