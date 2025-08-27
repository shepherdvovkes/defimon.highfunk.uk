'use client'

import { motion, AnimatePresence, useScroll, useTransform } from 'framer-motion'
import { useState, useEffect, useRef } from 'react'
import { 
  TrendingUp,
  TrendingDown,
  DollarSign,
  BarChart3,
  PieChart,
  LineChart,
  Activity,
  Zap,
  Target,
  Eye,
  Search,
  Filter,
  Download,
  Share2,
  RefreshCw,
  Clock,
  Users,
  Globe,
  Cpu,
  Database,
  Network,
  Layers,
  ArrowUpRight,
  ArrowDownRight,
  Minus,
  CheckCircle,
  XCircle,
  Info,
  Settings,
  Maximize2,
  Minimize2,
  AlertTriangle,
  Shield,
  Brain,
  Star,
  Heart,
  ThumbsUp,
  ThumbsDown,
  MessageCircle,
  ExternalLink,
  ChevronRight,
  ChevronDown,
  Calendar,
  MapPin,
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
  Phone,
  PhoneOff,
  Mail,
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
  Play,
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
  ThumbsUp2,
  ThumbsDown2,
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

interface InvestmentOpportunity {
  id: string
  name: string
  symbol: string
  category: string
  riskLevel: 'Low' | 'Medium' | 'High' | 'Very High'
  potentialReturn: number
  confidenceScore: number
  marketCap: number
  volume24h: number
  priceChange24h: number
  priceChange7d: number
  tvl: number
  apy: number
  teamScore: number
  communityScore: number
  technologyScore: number
  marketScore: number
  overallScore: number
  recommendation: 'Strong Buy' | 'Buy' | 'Hold' | 'Sell' | 'Strong Sell'
  analysis: string
  risks: string[]
  opportunities: string[]
  socialSentiment: 'Very Positive' | 'Positive' | 'Neutral' | 'Negative' | 'Very Negative'
  expertOpinions: {
    name: string
    role: string
    opinion: string
    rating: number
  }[]
}

interface MarketData {
  totalMarketCap: number
  totalVolume24h: number
  btcDominance: number
  ethDominance: number
  fearGreedIndex: number
  marketSentiment: 'Extreme Fear' | 'Fear' | 'Neutral' | 'Greed' | 'Extreme Greed'
  trendingCoins: string[]
  topGainers: string[]
  topLosers: string[]
}

export default function InvestorInsightsPage() {
  const [selectedOpportunity, setSelectedOpportunity] = useState<string | null>(null)
  const [timeframe, setTimeframe] = useState<'1h' | '24h' | '7d' | '30d' | '90d'>('7d')
  const [filterCategory, setFilterCategory] = useState<string>('all')
  const [filterRisk, setFilterRisk] = useState<string>('all')
  const [sortBy, setSortBy] = useState<'score' | 'potential' | 'marketCap' | 'volume'>('score')
  const [isLoading, setIsLoading] = useState(false)
  const [marketData, setMarketData] = useState<MarketData | null>(null)
  
  const containerRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({ target: containerRef })
  
  // Transform for parallax effects
  const backgroundY = useTransform(scrollYProgress, [0, 1], ['0%', '50%'])

  // Mock data for demonstration
  const investmentOpportunities: InvestmentOpportunity[] = [
    {
      id: '1',
      name: 'Ethereum',
      symbol: 'ETH',
      category: 'Layer 1',
      riskLevel: 'Low',
      potentialReturn: 85,
      confidenceScore: 92,
      marketCap: 450000000000,
      volume24h: 15000000000,
      priceChange24h: 3.2,
      priceChange7d: 12.5,
      tvl: 28000000000,
      apy: 4.2,
      teamScore: 95,
      communityScore: 88,
      technologyScore: 92,
      marketScore: 89,
      overallScore: 91,
      recommendation: 'Strong Buy',
      analysis: 'Ethereum continues to dominate the DeFi ecosystem with strong fundamentals, upcoming upgrades, and growing institutional adoption.',
      risks: ['Regulatory uncertainty', 'Competition from other L1s', 'Gas fee volatility'],
      opportunities: ['EIP-4844 implementation', 'Institutional adoption', 'DeFi growth'],
      socialSentiment: 'Very Positive',
      expertOpinions: [
        {
          name: 'Dr. Sarah Chen',
          role: 'Crypto Analyst at Goldman Sachs',
          opinion: 'ETH fundamentals remain strong with clear roadmap and growing ecosystem.',
          rating: 9.2
        },
        {
          name: 'Marcus Rodriguez',
          role: 'Portfolio Manager at Digital Assets Fund',
          opinion: 'Best positioned L1 for institutional adoption and DeFi growth.',
          rating: 9.0
        }
      ]
    },
    {
      id: '2',
      name: 'Uniswap',
      symbol: 'UNI',
      category: 'DeFi',
      riskLevel: 'Medium',
      potentialReturn: 120,
      confidenceScore: 78,
      marketCap: 8500000000,
      volume24h: 450000000,
      priceChange24h: -1.8,
      priceChange7d: 8.3,
      tvl: 3200000000,
      apy: 15.8,
      teamScore: 85,
      communityScore: 82,
      technologyScore: 88,
      marketScore: 75,
      overallScore: 82,
      recommendation: 'Buy',
      analysis: 'Leading DEX with strong market position, but facing increasing competition and regulatory challenges.',
      risks: ['Regulatory pressure', 'Competition from new DEXs', 'Tokenomics concerns'],
      opportunities: ['V4 upgrade', 'Cross-chain expansion', 'Institutional partnerships'],
      socialSentiment: 'Positive',
      expertOpinions: [
        {
          name: 'Alex Thompson',
          role: 'DeFi Research Analyst',
          opinion: 'Solid fundamentals but needs to innovate to maintain market leadership.',
          rating: 7.8
        }
      ]
    },
    {
      id: '3',
      name: 'Polygon',
      symbol: 'MATIC',
      category: 'Layer 2',
      riskLevel: 'Medium',
      potentialReturn: 95,
      confidenceScore: 81,
      marketCap: 12000000000,
      volume24h: 680000000,
      priceChange24h: 2.1,
      priceChange7d: 15.7,
      tvl: 850000000,
      apy: 8.5,
      teamScore: 88,
      communityScore: 85,
      technologyScore: 82,
      marketScore: 78,
      overallScore: 83,
      recommendation: 'Buy',
      analysis: 'Strong L2 solution with growing adoption and strategic partnerships.',
      risks: ['Ethereum scaling solutions competition', 'Tokenomics dilution', 'Technical complexity'],
      opportunities: ['zkEVM adoption', 'Enterprise partnerships', 'Cross-chain bridges'],
      socialSentiment: 'Positive',
      expertOpinions: [
        {
          name: 'Dr. Michael Chang',
          role: 'Blockchain Technology Expert',
          opinion: 'Excellent technical execution and strong partnership strategy.',
          rating: 8.3
        }
      ]
    }
  ]

  const mockMarketData: MarketData = {
    totalMarketCap: 2850000000000,
    totalVolume24h: 85000000000,
    btcDominance: 48.5,
    ethDominance: 18.2,
    fearGreedIndex: 65,
    marketSentiment: 'Greed',
    trendingCoins: ['ETH', 'MATIC', 'UNI', 'LINK', 'AAVE'],
    topGainers: ['MATIC', 'LINK', 'AAVE', 'COMP', 'MKR'],
    topLosers: ['SOL', 'ADA', 'DOT', 'AVAX', 'ATOM']
  }

  useEffect(() => {
    setMarketData(mockMarketData)
  }, [])

  const getRiskColor = (risk: string) => {
    switch (risk) {
      case 'Low': return 'text-emerald-400 bg-emerald-400/10'
      case 'Medium': return 'text-yellow-400 bg-yellow-400/10'
      case 'High': return 'text-orange-400 bg-orange-400/10'
      case 'Very High': return 'text-red-400 bg-red-400/10'
      default: return 'text-neutral-400 bg-neutral-400/10'
    }
  }

  const getRecommendationColor = (rec: string) => {
    switch (rec) {
      case 'Strong Buy': return 'text-emerald-400 bg-emerald-400/10'
      case 'Buy': return 'text-green-400 bg-green-400/10'
      case 'Hold': return 'text-yellow-400 bg-yellow-400/10'
      case 'Sell': return 'text-orange-400 bg-orange-400/10'
      case 'Strong Sell': return 'text-red-400 bg-red-400/10'
      default: return 'text-neutral-400 bg-neutral-400/10'
    }
  }

  const getSentimentColor = (sentiment: string) => {
    switch (sentiment) {
      case 'Very Positive': return 'text-emerald-400'
      case 'Positive': return 'text-green-400'
      case 'Neutral': return 'text-yellow-400'
      case 'Negative': return 'text-orange-400'
      case 'Very Negative': return 'text-red-400'
      default: return 'text-neutral-400'
    }
  }

  const formatCurrency = (value: number) => {
    if (value >= 1e12) return `$${(value / 1e12).toFixed(2)}T`
    if (value >= 1e9) return `$${(value / 1e9).toFixed(2)}B`
    if (value >= 1e6) return `$${(value / 1e6).toFixed(2)}M`
    if (value >= 1e3) return `$${(value / 1e3).toFixed(2)}K`
    return `$${value.toFixed(2)}`
  }

  const formatPercentage = (value: number) => {
    const sign = value >= 0 ? '+' : ''
    return `${sign}${value.toFixed(2)}%`
  }

  return (
    <div ref={containerRef} className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 overflow-hidden">
      {/* Animated Background */}
      <motion.div 
        className="absolute inset-0 opacity-10"
        style={{ y: backgroundY }}
      >
        <div className="absolute inset-0 bg-gradient-to-br from-blue-900/20 via-transparent to-purple-900/20"></div>
        <div className="absolute top-20 left-20 w-96 h-96 bg-blue-500/5 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-40 right-40 w-80 h-80 bg-purple-500/5 rounded-full blur-3xl animate-pulse delay-1000"></div>
        <div className="absolute top-1/2 left-1/2 w-64 h-64 bg-emerald-500/5 rounded-full blur-3xl animate-pulse delay-500"></div>
      </motion.div>

      {/* Header */}
      <motion.header 
        className="relative z-50 border-b border-slate-700/50 bg-slate-900/80 backdrop-blur-xl"
        initial={{ y: -100, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ type: "spring", stiffness: 100, damping: 20 }}
      >
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-gradient-to-r from-emerald-500 to-teal-500 rounded-xl flex items-center justify-center shadow-lg shadow-emerald-500/25">
                <DollarSign className="w-7 h-7 text-white" />
              </div>
              <div>
                <h1 className="text-2xl font-black text-white">Investor Insights</h1>
                <p className="text-sm text-slate-400 font-medium">Advanced Crypto Investment Analytics</p>
              </div>
            </div>

            <div className="flex items-center space-x-4">
              <motion.button
                className="p-3 bg-slate-800 hover:bg-slate-700 rounded-xl text-slate-300 border border-slate-600 transition-all duration-300"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <RefreshCw className="w-5 h-5" />
              </motion.button>

              <motion.a
                href="/"
                className="flex items-center space-x-2 px-6 py-3 bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-xl font-semibold shadow-lg shadow-emerald-500/25 hover:shadow-emerald-500/40 transition-all duration-300"
                whileHover={{ scale: 1.05, y: -2 }}
                whileTap={{ scale: 0.95 }}
              >
                <span>Back to Home</span>
                <ChevronRight className="w-4 h-4" />
              </motion.a>
            </div>
          </div>
        </div>
      </motion.header>

      {/* Market Overview */}
      <motion.section 
        className="relative z-10 pt-8"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
      >
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            {marketData && (
              <>
                <motion.div 
                  className="bg-slate-800/50 backdrop-blur-xl rounded-2xl p-6 border border-slate-700/50"
                  whileHover={{ scale: 1.02, y: -2 }}
                  transition={{ type: "spring", stiffness: 300 }}
                >
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-slate-400 text-sm font-medium">Total Market Cap</h3>
                    <Globe className="w-5 h-5 text-emerald-400" />
                  </div>
                  <p className="text-3xl font-black text-white mb-2">
                    {formatCurrency(marketData.totalMarketCap)}
                  </p>
                  <div className="flex items-center space-x-2">
                    <TrendingUp className="w-4 h-4 text-emerald-400" />
                    <span className="text-emerald-400 text-sm font-medium">+2.4%</span>
                  </div>
                </motion.div>

                <motion.div 
                  className="bg-slate-800/50 backdrop-blur-xl rounded-2xl p-6 border border-slate-700/50"
                  whileHover={{ scale: 1.02, y: -2 }}
                  transition={{ type: "spring", stiffness: 300 }}
                >
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-slate-400 text-sm font-medium">24h Volume</h3>
                    <Activity className="w-5 h-5 text-blue-400" />
                  </div>
                  <p className="text-3xl font-black text-white mb-2">
                    {formatCurrency(marketData.totalVolume24h)}
                  </p>
                  <div className="flex items-center space-x-2">
                    <TrendingUp className="w-4 h-4 text-blue-400" />
                    <span className="text-blue-400 text-sm font-medium">+5.1%</span>
                  </div>
                </motion.div>

                <motion.div 
                  className="bg-slate-800/50 backdrop-blur-xl rounded-2xl p-6 border border-slate-700/50"
                  whileHover={{ scale: 1.02, y: -2 }}
                  transition={{ type: "spring", stiffness: 300 }}
                >
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-slate-400 text-sm font-medium">Fear & Greed</h3>
                    <Brain className="w-5 h-5 text-purple-400" />
                  </div>
                  <p className="text-3xl font-black text-white mb-2">
                    {marketData.fearGreedIndex}
                  </p>
                  <div className="flex items-center space-x-2">
                    <span className={`text-sm font-medium ${
                      marketData.marketSentiment === 'Greed' ? 'text-yellow-400' : 'text-emerald-400'
                    }`}>
                      {marketData.marketSentiment}
                    </span>
                  </div>
                </motion.div>

                <motion.div 
                  className="bg-slate-800/50 backdrop-blur-xl rounded-2xl p-6 border border-slate-700/50"
                  whileHover={{ scale: 1.02, y: -2 }}
                  transition={{ type: "spring", stiffness: 300 }}
                >
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-slate-400 text-sm font-medium">BTC Dominance</h3>
                    <Bitcoin className="w-5 h-5 text-orange-400" />
                  </div>
                  <p className="text-3xl font-black text-white mb-2">
                    {marketData.btcDominance}%
                  </p>
                  <div className="flex items-center space-x-2">
                    <TrendingDown className="w-4 h-4 text-orange-400" />
                    <span className="text-orange-400 text-sm font-medium">-0.8%</span>
                  </div>
                </motion.div>
              </>
            )}
          </div>
        </div>
      </motion.section>

      {/* Main Content */}
      <motion.main 
        className="relative z-10 pb-20"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
      >
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Investment Opportunities List */}
            <div className="lg:col-span-2">
              <div className="bg-slate-800/50 backdrop-blur-xl rounded-2xl border border-slate-700/50 overflow-hidden">
                <div className="p-6 border-b border-slate-700/50">
                  <div className="flex items-center justify-between mb-4">
                    <h2 className="text-2xl font-black text-white">Investment Opportunities</h2>
                    <div className="flex items-center space-x-2">
                      <motion.button
                        className="p-2 bg-slate-700 hover:bg-slate-600 rounded-lg text-slate-300 transition-all duration-300"
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        <Filter className="w-4 h-4" />
                      </motion.button>
                      <motion.button
                        className="p-2 bg-slate-700 hover:bg-slate-600 rounded-lg text-slate-300 transition-all duration-300"
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        <Download className="w-4 h-4" />
                      </motion.button>
                    </div>
                  </div>

                                     {/* Filters */}
                   <div className="flex flex-wrap gap-4">
                     <select 
                       value={filterCategory}
                       onChange={(e) => setFilterCategory(e.target.value)}
                       className="px-4 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                       aria-label="Filter by category"
                     >
                       <option value="all">All Categories</option>
                       <option value="Layer 1">Layer 1</option>
                       <option value="Layer 2">Layer 2</option>
                       <option value="DeFi">DeFi</option>
                       <option value="Gaming">Gaming</option>
                       <option value="Infrastructure">Infrastructure</option>
                     </select>

                     <select 
                       value={filterRisk}
                       onChange={(e) => setFilterRisk(e.target.value)}
                       className="px-4 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                       aria-label="Filter by risk level"
                     >
                       <option value="all">All Risk Levels</option>
                       <option value="Low">Low Risk</option>
                       <option value="Medium">Medium Risk</option>
                       <option value="High">High Risk</option>
                       <option value="Very High">Very High Risk</option>
                     </select>

                     <select 
                       value={sortBy}
                       onChange={(e) => setSortBy(e.target.value as any)}
                       className="px-4 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                       aria-label="Sort by criteria"
                     >
                       <option value="score">Sort by Score</option>
                       <option value="potential">Sort by Potential</option>
                       <option value="marketCap">Sort by Market Cap</option>
                       <option value="volume">Sort by Volume</option>
                     </select>
                   </div>
                </div>

                <div className="divide-y divide-slate-700/50">
                  {investmentOpportunities.map((opportunity) => (
                    <motion.div
                      key={opportunity.id}
                      className={`p-6 cursor-pointer transition-all duration-300 ${
                        selectedOpportunity === opportunity.id 
                          ? 'bg-slate-700/50 border-l-4 border-emerald-500' 
                          : 'hover:bg-slate-700/30'
                      }`}
                      onClick={() => setSelectedOpportunity(opportunity.id)}
                      whileHover={{ scale: 1.01 }}
                      whileTap={{ scale: 0.99 }}
                    >
                      <div className="flex items-center justify-between mb-4">
                        <div className="flex items-center space-x-4">
                          <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-500 rounded-xl flex items-center justify-center">
                            <span className="text-white font-bold text-lg">{opportunity.symbol}</span>
                          </div>
                          <div>
                            <h3 className="text-xl font-bold text-white">{opportunity.name}</h3>
                            <p className="text-slate-400 text-sm">{opportunity.category}</p>
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="flex items-center space-x-2 mb-2">
                            <span className={`px-3 py-1 rounded-full text-xs font-semibold ${getRiskColor(opportunity.riskLevel)}`}>
                              {opportunity.riskLevel} Risk
                            </span>
                            <span className={`px-3 py-1 rounded-full text-xs font-semibold ${getRecommendationColor(opportunity.recommendation)}`}>
                              {opportunity.recommendation}
                            </span>
                          </div>
                          <div className="flex items-center space-x-4 text-sm">
                            <span className="text-slate-400">Score: <span className="text-white font-bold">{opportunity.overallScore}</span></span>
                            <span className="text-slate-400">Potential: <span className="text-emerald-400 font-bold">{opportunity.potentialReturn}%</span></span>
                          </div>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                        <div>
                          <p className="text-slate-400">Market Cap</p>
                          <p className="text-white font-semibold">{formatCurrency(opportunity.marketCap)}</p>
                        </div>
                        <div>
                          <p className="text-slate-400">24h Volume</p>
                          <p className="text-white font-semibold">{formatCurrency(opportunity.volume24h)}</p>
                        </div>
                        <div>
                          <p className="text-slate-400">24h Change</p>
                          <p className={`font-semibold ${opportunity.priceChange24h >= 0 ? 'text-emerald-400' : 'text-red-400'}`}>
                            {formatPercentage(opportunity.priceChange24h)}
                          </p>
                        </div>
                        <div>
                          <p className="text-slate-400">TVL</p>
                          <p className="text-white font-semibold">{formatCurrency(opportunity.tvl)}</p>
                        </div>
                      </div>

                      <div className="mt-4 flex items-center justify-between">
                        <div className="flex items-center space-x-4">
                          <div className="flex items-center space-x-1">
                            <span className="text-slate-400 text-sm">Sentiment:</span>
                            <span className={`text-sm font-medium ${getSentimentColor(opportunity.socialSentiment)}`}>
                              {opportunity.socialSentiment}
                            </span>
                          </div>
                        </div>
                        <ChevronRight className="w-5 h-5 text-slate-400" />
                      </div>
                    </motion.div>
                  ))}
                </div>
              </div>
            </div>

            {/* Detailed Analysis Panel */}
            <div className="lg:col-span-1">
              <div className="bg-slate-800/50 backdrop-blur-xl rounded-2xl border border-slate-700/50 p-6 sticky top-6">
                <h2 className="text-xl font-black text-white mb-6">Detailed Analysis</h2>
                
                {selectedOpportunity ? (
                  <AnimatePresence mode="wait">
                    <motion.div
                      key={selectedOpportunity}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -20 }}
                      transition={{ duration: 0.3 }}
                    >
                      {(() => {
                        const opportunity = investmentOpportunities.find(o => o.id === selectedOpportunity)
                        if (!opportunity) return null

                        return (
                          <div className="space-y-6">
                            {/* Score Breakdown */}
                            <div>
                              <h3 className="text-lg font-bold text-white mb-4">Score Breakdown</h3>
                              <div className="space-y-3">
                                <div className="flex items-center justify-between">
                                  <span className="text-slate-400 text-sm">Team</span>
                                  <div className="flex items-center space-x-2">
                                    <div className="w-24 bg-slate-700 rounded-full h-2">
                                      <div 
                                        className="bg-emerald-500 h-2 rounded-full" 
                                        style={{ width: `${opportunity.teamScore}%` }}
                                      ></div>
                                    </div>
                                    <span className="text-white text-sm font-semibold">{opportunity.teamScore}</span>
                                  </div>
                                </div>
                                <div className="flex items-center justify-between">
                                  <span className="text-slate-400 text-sm">Technology</span>
                                  <div className="flex items-center space-x-2">
                                    <div className="w-24 bg-slate-700 rounded-full h-2">
                                      <div 
                                        className="bg-blue-500 h-2 rounded-full" 
                                        style={{ width: `${opportunity.technologyScore}%` }}
                                      ></div>
                                    </div>
                                    <span className="text-white text-sm font-semibold">{opportunity.technologyScore}</span>
                                  </div>
                                </div>
                                <div className="flex items-center justify-between">
                                  <span className="text-slate-400 text-sm">Market</span>
                                  <div className="flex items-center space-x-2">
                                    <div className="w-24 bg-slate-700 rounded-full h-2">
                                      <div 
                                        className="bg-purple-500 h-2 rounded-full" 
                                        style={{ width: `${opportunity.marketScore}%` }}
                                      ></div>
                                    </div>
                                    <span className="text-white text-sm font-semibold">{opportunity.marketScore}</span>
                                  </div>
                                </div>
                                <div className="flex items-center justify-between">
                                  <span className="text-slate-400 text-sm">Community</span>
                                  <div className="flex items-center space-x-2">
                                    <div className="w-24 bg-slate-700 rounded-full h-2">
                                      <div 
                                        className="bg-orange-500 h-2 rounded-full" 
                                        style={{ width: `${opportunity.communityScore}%` }}
                                      ></div>
                                    </div>
                                    <span className="text-white text-sm font-semibold">{opportunity.communityScore}</span>
                                  </div>
                                </div>
                              </div>
                            </div>

                            {/* Analysis */}
                            <div>
                              <h3 className="text-lg font-bold text-white mb-3">Analysis</h3>
                              <p className="text-slate-300 text-sm leading-relaxed">{opportunity.analysis}</p>
                            </div>

                            {/* Risks */}
                            <div>
                              <h3 className="text-lg font-bold text-white mb-3">Key Risks</h3>
                              <div className="space-y-2">
                                {opportunity.risks.map((risk, index) => (
                                  <div key={index} className="flex items-start space-x-2">
                                    <AlertTriangle className="w-4 h-4 text-red-400 mt-0.5 flex-shrink-0" />
                                    <span className="text-slate-300 text-sm">{risk}</span>
                                  </div>
                                ))}
                              </div>
                            </div>

                            {/* Opportunities */}
                            <div>
                              <h3 className="text-lg font-bold text-white mb-3">Opportunities</h3>
                              <div className="space-y-2">
                                {opportunity.opportunities.map((opp, index) => (
                                  <div key={index} className="flex items-start space-x-2">
                                    <TrendingUp className="w-4 h-4 text-emerald-400 mt-0.5 flex-shrink-0" />
                                    <span className="text-slate-300 text-sm">{opp}</span>
                                  </div>
                                ))}
                              </div>
                            </div>

                            {/* Expert Opinions */}
                            <div>
                              <h3 className="text-lg font-bold text-white mb-3">Expert Opinions</h3>
                              <div className="space-y-4">
                                {opportunity.expertOpinions.map((expert, index) => (
                                  <div key={index} className="bg-slate-700/50 rounded-lg p-4">
                                    <div className="flex items-center justify-between mb-2">
                                      <span className="text-white font-semibold text-sm">{expert.name}</span>
                                      <div className="flex items-center space-x-1">
                                        {[...Array(5)].map((_, i) => (
                                          <Star 
                                            key={i} 
                                            className={`w-3 h-3 ${i < Math.floor(expert.rating) ? 'text-yellow-400 fill-current' : 'text-slate-600'}`} 
                                          />
                                        ))}
                                      </div>
                                    </div>
                                    <p className="text-slate-400 text-xs mb-1">{expert.role}</p>
                                    <p className="text-slate-300 text-sm">{expert.opinion}</p>
                                  </div>
                                ))}
                              </div>
                            </div>

                            {/* Action Buttons */}
                            <div className="space-y-3">
                              <motion.button
                                className="w-full py-3 bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-xl font-semibold shadow-lg shadow-emerald-500/25 hover:shadow-emerald-500/40 transition-all duration-300"
                                whileHover={{ scale: 1.02, y: -2 }}
                                whileTap={{ scale: 0.98 }}
                              >
                                View Full Report
                              </motion.button>
                              <motion.button
                                className="w-full py-3 bg-slate-700 hover:bg-slate-600 text-white rounded-xl font-semibold transition-all duration-300"
                                whileHover={{ scale: 1.02 }}
                                whileTap={{ scale: 0.98 }}
                              >
                                Set Price Alert
                              </motion.button>
                            </div>
                          </div>
                        )
                      })()}
                    </motion.div>
                  </AnimatePresence>
                ) : (
                  <div className="text-center py-12">
                    <BarChart3 className="w-12 h-12 text-slate-600 mx-auto mb-4" />
                    <p className="text-slate-400 text-sm">Select an investment opportunity to view detailed analysis</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </motion.main>
    </div>
  )
}
