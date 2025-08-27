'use client'

import { motion, AnimatePresence } from 'framer-motion'
import { useState, useEffect } from 'react'
import { 
  ArrowRight,
  Play,
  Star,
  CheckCircle,
  Users,
  TrendingUp,
  Shield,
  Zap,
  Globe,
  Brain,
  Cpu,
  Database,
  BarChart3,
  Activity,
  Target,
  Eye,
  Download,
  Mail,
  Phone,
  MapPin,
  Clock,
  ChevronDown,
  Menu,
  X,
  Github,
  Twitter,
  Linkedin,
  Youtube,
  Instagram,
  Facebook,
  MessageCircle,
  Heart,
  Sparkles,
  Award,
  Trophy,
  Crown,
  Gem,
  Diamond,
  Bitcoin,
  Ethereum,
  Coins,
  Wallet,
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
  ExternalLink,
  ChevronRight,
  ChevronUp,
  Calendar,
  MapPin as MapPinIcon,
  Award as AwardIcon,
  Trophy as TrophyIcon,
  Crown as CrownIcon,
  Gem as GemIcon,
  Diamond as DiamondIcon,
  Bitcoin as BitcoinIcon,
  Ethereum as EthereumIcon,
  Coins as CoinsIcon,
  Wallet as WalletIcon,
  Lock as LockIcon,
  Unlock as UnlockIcon,
  Key as KeyIcon,
  Fingerprint as FingerprintIcon,
  Scan as ScanIcon,
  Monitor as MonitorIcon,
  Smartphone as SmartphoneIcon,
  Tablet as TabletIcon,
  Laptop as LaptopIcon,
  Server as ServerIcon,
  Cloud as CloudIcon,
  Wifi as WifiIcon,
  Signal as SignalIcon,
  Battery as BatteryIcon,
  Power as PowerIcon,
  Volume2 as Volume2Icon,
  VolumeX as VolumeXIcon,
  Mic as MicIcon,
  MicOff as MicOffIcon,
  Camera as CameraIcon,
  CameraOff as CameraOffIcon,
  Video as VideoIcon,
  VideoOff as VideoOffIcon,
  PhoneOff as PhoneOffIcon,
  Mail as MailIcon2,
  Send as SendIcon,
  Inbox as InboxIcon,
  Archive as ArchiveIcon,
  Trash2 as Trash2Icon,
  Edit as EditIcon,
  Edit3 as Edit3Icon,
  Save as SaveIcon,
  Save2 as Save2Icon,
  File as FileIcon,
  FileText as FileTextIcon,
  FilePlus as FilePlusIcon,
  FileMinus as FileMinusIcon,
  FileX as FileXIcon,
  Folder as FolderIcon,
  FolderPlus as FolderPlusIcon,
  FolderMinus as FolderMinusIcon,
  FolderX as FolderXIcon,
  Image as ImageIcon,
  ImagePlus as ImagePlusIcon,
  ImageMinus as ImageMinusIcon,
  ImageX as ImageXIcon,
  Music as MusicIcon,
  Video2 as Video2Icon,
  Headphones as HeadphonesIcon,
  Speaker as SpeakerIcon,
  Volume as VolumeIcon,
  Volume1 as Volume1Icon,
  Volume3 as Volume3Icon,
  Mute as MuteIcon,
  Play as PlayIcon2,
  Pause as PauseIcon,
  SkipBack as SkipBackIcon,
  SkipForward as SkipForwardIcon,
  Rewind as RewindIcon,
  FastForward as FastForwardIcon,
  RotateCcw as RotateCcwIcon,
  RotateCw as RotateCwIcon,
  Repeat as RepeatIcon,
  Shuffle as ShuffleIcon,
  SkipBack2 as SkipBack2Icon,
  SkipForward2 as SkipForward2Icon,
  PlayCircle as PlayCircleIcon,
  PauseCircle as PauseCircleIcon,
  StopCircle as StopCircleIcon,
  Square as SquareIcon,
  Circle as CircleIcon,
  Triangle as TriangleIcon,
  Hexagon as HexagonIcon,
  Octagon as OctagonIcon,
  Star2 as Star2Icon,
  Heart2 as Heart2Icon,
  ThumbsUp as ThumbsUpIcon,
  ThumbsDown as ThumbsDownIcon,
  MessageCircle2 as MessageCircle2Icon,
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

export default function ModernLandingPage() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [activeSection, setActiveSection] = useState('home')
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
      title: 'AI-Powered Analytics',
      description: 'Advanced machine learning algorithms provide real-time insights and predictions',
      color: 'from-purple-500 to-pink-500'
    },
    {
      icon: Globe,
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
    { value: '50+', label: 'Supported Networks', icon: Globe }
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

  const pricingPlans = [
    {
      name: 'Starter',
      price: '$29',
      period: '/month',
      description: 'Perfect for individual traders and small teams',
      features: [
        'Real-time DeFi analytics',
        'Basic AI insights',
        '5 network monitoring',
        'Email support',
        'API access (1000 calls/month)'
      ],
      popular: false,
      color: 'from-blue-500 to-cyan-500'
    },
    {
      name: 'Professional',
      price: '$99',
      period: '/month',
      description: 'Ideal for growing teams and institutions',
      features: [
        'Everything in Starter',
        'Advanced AI predictions',
        'All network monitoring',
        'Priority support',
        'API access (10,000 calls/month)',
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
      description: 'Tailored solutions for large organizations',
      features: [
        'Everything in Professional',
        'Custom AI models',
        'Dedicated support',
        'Unlimited API access',
        'White-label solutions',
        'On-premise deployment',
        'Custom integrations'
      ],
      popular: false,
      color: 'from-emerald-500 to-teal-500'
    }
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      {/* Navigation */}
      <motion.nav 
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
          isScrolled 
            ? 'bg-slate-900/95 backdrop-blur-xl border-b border-white/10' 
            : 'bg-transparent'
        }`}
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        transition={{ duration: 0.6 }}
      >
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            {/* Logo */}
            <motion.div 
              className="flex items-center space-x-3"
              whileHover={{ scale: 1.05 }}
            >
              <div className="w-10 h-10 bg-gradient-to-r from-purple-500 via-pink-500 to-blue-500 rounded-xl flex items-center justify-center">
                <Sparkles className="w-6 h-6 text-white" />
              </div>
              <span className="text-2xl font-black text-white">DeFiMon</span>
            </motion.div>

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center space-x-8">
              {['Home', 'Features', 'Pricing', 'About', 'Contact'].map((item) => (
                <motion.a
                  key={item}
                  href={`#${item.toLowerCase()}`}
                  className="text-white/80 hover:text-white font-medium transition-colors"
                  whileHover={{ y: -2 }}
                >
                  {item}
                </motion.a>
              ))}
            </div>

            {/* CTA Buttons */}
            <div className="hidden md:flex items-center space-x-4">
              <motion.a
                href="/demo"
                className="text-white/80 hover:text-white font-medium transition-colors"
                whileHover={{ y: -2 }}
              >
                Demo
              </motion.a>
              <motion.a
                href="/investor-insights"
                className="text-white/80 hover:text-white font-medium transition-colors"
                whileHover={{ y: -2 }}
              >
                Investor Insights
              </motion.a>
              <motion.button
                className="px-6 py-2 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-xl font-semibold hover:from-purple-600 hover:to-pink-600 transition-all duration-300"
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
                className="md:hidden mt-4 pb-4 border-t border-white/10"
              >
                <div className="flex flex-col space-y-4 pt-4">
                  {['Home', 'Features', 'Pricing', 'About', 'Contact'].map((item) => (
                    <a
                      key={item}
                      href={`#${item.toLowerCase()}`}
                      className="text-white/80 hover:text-white font-medium transition-colors"
                      onClick={() => setIsMenuOpen(false)}
                    >
                      {item}
                    </a>
                  ))}
                  <div className="pt-4 border-t border-white/10">
                    <a
                      href="/demo"
                      className="block text-white/80 hover:text-white font-medium transition-colors mb-2"
                      onClick={() => setIsMenuOpen(false)}
                    >
                      Demo
                    </a>
                    <a
                      href="/investor-insights"
                      className="block text-white/80 hover:text-white font-medium transition-colors mb-4"
                      onClick={() => setIsMenuOpen(false)}
                    >
                      Investor Insights
                    </a>
                    <button className="w-full px-6 py-3 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-xl font-semibold hover:from-purple-600 hover:to-pink-600 transition-all duration-300">
                      Get Started
                    </button>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </motion.nav>

      {/* Hero Section */}
      <section id="home" className="relative pt-32 pb-20 overflow-hidden">
        <div className="absolute inset-0">
          <div className="absolute inset-0 bg-gradient-to-br from-purple-900/30 via-transparent to-blue-900/30"></div>
          <div className="absolute top-20 left-20 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl animate-pulse"></div>
          <div className="absolute bottom-40 right-40 w-80 h-80 bg-blue-500/10 rounded-full blur-3xl animate-pulse delay-1000"></div>
          <div className="absolute top-1/2 left-1/2 w-64 h-64 bg-emerald-500/10 rounded-full blur-3xl animate-pulse delay-500"></div>
        </div>

        <div className="relative max-w-7xl mx-auto px-6">
          <div className="text-center">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8 }}
            >
              <h1 className="text-5xl md:text-7xl font-black text-white mb-6 leading-tight">
                The Future of
                <br />
                <span className="bg-gradient-to-r from-purple-400 via-pink-400 to-blue-400 bg-clip-text text-transparent">
                  DeFi Analytics
                </span>
              </h1>
              <p className="text-xl md:text-2xl text-white/80 max-w-4xl mx-auto mb-8 leading-relaxed">
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
              <motion.button
                className="group flex items-center space-x-3 px-8 py-4 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-2xl font-bold text-lg hover:from-purple-600 hover:to-pink-600 transition-all duration-300 shadow-2xl shadow-purple-500/25"
                whileHover={{ scale: 1.05, y: -2 }}
                whileTap={{ scale: 0.95 }}
              >
                <span>Start Free Trial</span>
                <ArrowRight className="w-6 h-6 group-hover:translate-x-1 transition-transform duration-300" />
              </motion.button>
              
              <motion.button
                className="group flex items-center space-x-3 px-8 py-4 bg-white/10 text-white rounded-2xl font-bold text-lg hover:bg-white/20 transition-all duration-300 border border-white/20"
                whileHover={{ scale: 1.05, y: -2 }}
                whileTap={{ scale: 0.95 }}
              >
                <Play className="w-6 h-6" />
                <span>Watch Demo</span>
              </motion.button>
            </motion.div>

            {/* Stats */}
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.4 }}
              className="grid grid-cols-2 md:grid-cols-4 gap-8"
            >
              {stats.map((stat, index) => {
                const Icon = stat.icon
                return (
                  <motion.div
                    key={stat.label}
                    className="text-center"
                    whileHover={{ scale: 1.05 }}
                    transition={{ delay: index * 0.1 }}
                  >
                    <div className="flex items-center justify-center mb-2">
                      <Icon className="w-8 h-8 text-purple-400" />
                    </div>
                    <div className="text-3xl md:text-4xl font-black text-white mb-1">
                      {stat.value}
                    </div>
                    <div className="text-white/60 text-sm font-medium">
                      {stat.label}
                    </div>
                  </motion.div>
                )
              })}
            </motion.div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 bg-slate-800/20">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-black text-white mb-6">
              Why Choose <span className="bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">DeFiMon</span>?
            </h2>
            <p className="text-xl text-white/80 max-w-3xl mx-auto">
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
                  <div className="bg-slate-800/50 backdrop-blur-xl rounded-2xl p-8 border border-white/10 hover:border-purple-500/30 transition-all duration-300 group-hover:scale-105">
                    <div className={`w-16 h-16 bg-gradient-to-r ${feature.color} rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300`}>
                      <Icon className="w-8 h-8 text-white" />
                    </div>
                    <h3 className="text-xl font-bold text-white mb-4">{feature.title}</h3>
                    <p className="text-white/70 leading-relaxed">{feature.description}</p>
                  </div>
                </motion.div>
              )
            })}
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-black text-white mb-6">
              Trusted by <span className="bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">Thousands</span>
            </h2>
            <p className="text-xl text-white/80 max-w-3xl mx-auto">
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
                className="bg-slate-800/50 backdrop-blur-xl rounded-2xl p-8 border border-white/10"
              >
                <div className="flex items-center mb-4">
                  {[...Array(testimonial.rating)].map((_, i) => (
                    <Star key={i} className="w-5 h-5 text-yellow-400 fill-current" />
                  ))}
                </div>
                <p className="text-white/80 mb-6 leading-relaxed">"{testimonial.content}"</p>
                <div className="flex items-center">
                  <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center text-white font-bold mr-4">
                    {testimonial.avatar}
                  </div>
                  <div>
                    <div className="text-white font-semibold">{testimonial.name}</div>
                    <div className="text-white/60 text-sm">{testimonial.role} at {testimonial.company}</div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-20 bg-slate-800/20">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-black text-white mb-6">
              Simple, <span className="bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">Transparent</span> Pricing
            </h2>
            <p className="text-xl text-white/80 max-w-3xl mx-auto">
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
                    <span className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-4 py-2 rounded-full text-sm font-semibold">
                      Most Popular
                    </span>
                  </div>
                )}
                <div className="bg-slate-800/50 backdrop-blur-xl rounded-2xl p-8 border border-white/10 h-full">
                  <div className="text-center mb-8">
                    <h3 className="text-2xl font-bold text-white mb-2">{plan.name}</h3>
                    <div className="flex items-baseline justify-center mb-4">
                      <span className="text-4xl font-black text-white">{plan.price}</span>
                      <span className="text-white/60 ml-1">{plan.period}</span>
                    </div>
                    <p className="text-white/60">{plan.description}</p>
                  </div>
                  <ul className="space-y-4 mb-8">
                    {plan.features.map((feature) => (
                      <li key={feature} className="flex items-center">
                        <CheckCircle className="w-5 h-5 text-green-400 mr-3 flex-shrink-0" />
                        <span className="text-white/80">{feature}</span>
                      </li>
                    ))}
                  </ul>
                  <motion.button
                    className={`w-full py-3 bg-gradient-to-r ${plan.color} text-white rounded-xl font-semibold hover:opacity-90 transition-all duration-300`}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    {plan.name === 'Enterprise' ? 'Contact Sales' : 'Get Started'}
                  </motion.button>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
          >
            <h2 className="text-4xl md:text-5xl font-black text-white mb-6">
              Ready to Transform Your <span className="bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">DeFi Strategy</span>?
            </h2>
            <p className="text-xl text-white/80 mb-8 max-w-2xl mx-auto">
              Join thousands of professionals who trust DeFiMon for their DeFi analytics and investment decisions.
            </p>
            <motion.button
              className="px-8 py-4 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-2xl font-bold text-lg hover:from-purple-600 hover:to-pink-600 transition-all duration-300 shadow-2xl shadow-purple-500/25"
              whileHover={{ scale: 1.05, y: -2 }}
              whileTap={{ scale: 0.95 }}
            >
              Start Your Free Trial Today
            </motion.button>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-slate-900/50 border-t border-white/10 py-12">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="md:col-span-2">
              <div className="flex items-center space-x-3 mb-4">
                <div className="w-10 h-10 bg-gradient-to-r from-purple-500 via-pink-500 to-blue-500 rounded-xl flex items-center justify-center">
                  <Sparkles className="w-6 h-6 text-white" />
                </div>
                <span className="text-2xl font-black text-white">DeFiMon</span>
              </div>
              <p className="text-white/60 mb-6 max-w-md">
                Advanced DeFi analytics platform with AI/ML integration for predictions and risk assessment.
              </p>
              <div className="flex space-x-4">
                {[Twitter, Github, Linkedin, Youtube].map((Icon, index) => (
                  <motion.a
                    key={index}
                    href="#"
                    className="w-10 h-10 bg-white/10 hover:bg-white/20 rounded-lg flex items-center justify-center text-white/60 hover:text-white transition-all duration-300"
                    whileHover={{ scale: 1.1, y: -2 }}
                  >
                    <Icon className="w-5 h-5" />
                  </motion.a>
                ))}
              </div>
            </div>
            
            <div>
              <h3 className="text-white font-semibold mb-4">Product</h3>
              <ul className="space-y-2">
                {['Features', 'Pricing', 'API', 'Documentation'].map((item) => (
                  <li key={item}>
                    <a href="#" className="text-white/60 hover:text-white transition-colors">
                      {item}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
            
            <div>
              <h3 className="text-white font-semibold mb-4">Company</h3>
              <ul className="space-y-2">
                {['About', 'Blog', 'Careers', 'Contact'].map((item) => (
                  <li key={item}>
                    <a href="#" className="text-white/60 hover:text-white transition-colors">
                      {item}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          </div>
          
          <div className="border-t border-white/10 mt-8 pt-8 text-center">
            <p className="text-white/60">
              © 2024 DeFiMon. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
}
