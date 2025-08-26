'use client'

import { motion, AnimatePresence } from 'framer-motion'
import { useState, useRef, useEffect } from 'react'
import { 
  Send,
  Brain,
  Sparkles,
  MessageSquare,
  Bot,
  User,
  Loader2,
  Copy,
  Download,
  Share2,
  ThumbsUp,
  ThumbsDown,
  RefreshCw,
  TrendingUp,
  BarChart3,
  PieChart,
  LineChart,
  Target,
  AlertTriangle,
  CheckCircle,
  Info
} from 'lucide-react'

interface Question {
  id: string
  text: string
  timestamp: Date
  response?: AIResponse
  isProcessing?: boolean
}

interface AIResponse {
  answer: string
  confidence: number
  data?: any
  chartType?: 'line' | 'bar' | 'pie' | 'area'
  insights: string[]
  sources: string[]
  actions: Action[]
}

interface Action {
  id: string
  label: string
  icon: any
  action: () => void
}

export default function AIQuestionInterface() {
  const [questions, setQuestions] = useState<Question[]>([])
  const [currentQuestion, setCurrentQuestion] = useState('')
  const [isProcessing, setIsProcessing] = useState(false)
  const [suggestedQuestions] = useState([
    "What's the current market sentiment for Ethereum?",
    "Show me the correlation between BTC and ETH prices",
    "Which L2 networks have the highest TVL growth?",
    "What are the risk factors for DeFi protocols?",
    "Predict ETH price movement for the next 24 hours",
    "Compare gas fees across different networks"
  ])

  const messagesEndRef = useRef<HTMLDivElement>(null)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" })
  }

  useEffect(() => {
    scrollToBottom()
  }, [questions])

  const handleAskQuestion = async () => {
    if (!currentQuestion.trim() || isProcessing) return

    const newQuestion: Question = {
      id: Date.now().toString(),
      text: currentQuestion,
      timestamp: new Date(),
      isProcessing: true
    }

    setQuestions(prev => [...prev, newQuestion])
    setCurrentQuestion('')
    setIsProcessing(true)

    // Simulate AI processing
    await new Promise(resolve => setTimeout(resolve, 2000))

    const mockResponse: AIResponse = {
      answer: generateMockAnswer(currentQuestion),
      confidence: Math.random() * 30 + 70, // 70-100%
      data: generateMockData(),
      chartType: getChartType(currentQuestion),
      insights: generateInsights(currentQuestion),
      sources: ['CoinGecko API', 'DeFi Pulse', 'Ethereum Analytics'],
      actions: [
        {
          id: 'export',
          label: 'Export Data',
          icon: Download,
          action: () => console.log('Export data')
        },
        {
          id: 'share',
          label: 'Share Analysis',
          icon: Share2,
          action: () => console.log('Share analysis')
        },
        {
          id: 'bookmark',
          label: 'Bookmark',
          icon: Sparkles,
          action: () => console.log('Bookmark')
        }
      ]
    }

    setQuestions(prev => 
      prev.map(q => 
        q.id === newQuestion.id 
          ? { ...q, response: mockResponse, isProcessing: false }
          : q
      )
    )
    setIsProcessing(false)
  }

  const generateMockAnswer = (question: string): string => {
    const answers = {
      sentiment: "Based on recent market analysis, Ethereum shows bullish sentiment with increasing institutional adoption and positive technical indicators. The Fear & Greed Index indicates moderate greed, suggesting continued upward momentum.",
      correlation: "The correlation coefficient between BTC and ETH is currently 0.85, indicating a strong positive correlation. This relationship has remained stable over the past 30 days.",
      tvl: "Arbitrum leads L2 networks with 45% TVL growth, followed by Optimism at 32% and Polygon at 28%. This growth is primarily driven by DeFi protocol adoption.",
      risk: "Key risk factors include smart contract vulnerabilities, regulatory uncertainty, and market volatility. Current risk score is 6.2/10, indicating moderate risk.",
      prediction: "AI models predict ETH price to reach $2,650-$2,750 within 24 hours, with 78% confidence. Key support level at $2,450.",
      gas: "Ethereum mainnet has the highest gas fees at $15-25, while Polygon averages $0.01-0.05. Arbitrum and Optimism offer 90%+ savings."
    }

    const questionLower = question.toLowerCase()
    if (questionLower.includes('sentiment')) return answers.sentiment
    if (questionLower.includes('correlation')) return answers.correlation
    if (questionLower.includes('tvl')) return answers.tvl
    if (questionLower.includes('risk')) return answers.risk
    if (questionLower.includes('predict')) return answers.prediction
    if (questionLower.includes('gas')) return answers.gas

    return "Based on comprehensive analysis of market data, I can provide insights on this topic. The current market conditions show..."
  }

  const generateMockData = () => {
    return [
      { time: '00:00', value: 2450 },
      { time: '04:00', value: 2480 },
      { time: '08:00', value: 2520 },
      { time: '12:00', value: 2490 },
      { time: '16:00', value: 2510 },
      { time: '20:00', value: 2530 },
    ]
  }

  const getChartType = (question: string): 'line' | 'bar' | 'pie' | 'area' => {
    const questionLower = question.toLowerCase()
    if (questionLower.includes('correlation')) return 'bar'
    if (questionLower.includes('tvl')) return 'pie'
    if (questionLower.includes('gas')) return 'bar'
    return 'line'
  }

  const generateInsights = (question: string): string[] => {
    return [
      "Market volatility has increased by 15% in the last 24 hours",
      "Institutional adoption continues to grow steadily",
      "Technical indicators suggest bullish momentum",
      "Risk metrics remain within acceptable ranges"
    ]
  }

  const handleSuggestedQuestion = (question: string) => {
    setCurrentQuestion(question)
  }

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text)
  }

  return (
    <div className="h-full flex flex-col bg-black/20 backdrop-blur-2xl rounded-3xl border border-white/10">
      {/* Header */}
      <div className="flex items-center justify-between p-6 border-b border-white/10">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 bg-gradient-to-r from-purple-500 to-blue-500 rounded-xl flex items-center justify-center">
            <Brain className="w-6 h-6 text-white" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-white">AI Financial Assistant</h2>
            <p className="text-sm text-gray-400">Ask questions about your data</p>
          </div>
        </div>
        <motion.button
          className="p-2 text-gray-400 hover:text-white rounded-xl transition-all"
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.9 }}
        >
          <RefreshCw className="w-5 h-5" />
        </motion.button>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {questions.length === 0 && (
          <div className="text-center py-12">
            <div className="w-16 h-16 bg-gradient-to-r from-purple-500/20 to-blue-500/20 rounded-2xl flex items-center justify-center mx-auto mb-4">
              <MessageSquare className="w-8 h-8 text-purple-400" />
            </div>
            <h3 className="text-lg font-semibold text-white mb-2">Start a conversation</h3>
            <p className="text-gray-400 mb-6">Ask me anything about your financial data</p>
            
            {/* Suggested Questions */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 max-w-2xl mx-auto">
              {suggestedQuestions.map((question, index) => (
                <motion.button
                  key={index}
                  onClick={() => handleSuggestedQuestion(question)}
                  className="p-3 text-left bg-gray-800/50 hover:bg-gray-700/50 rounded-xl border border-white/10 text-gray-300 hover:text-white transition-all"
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                >
                  <div className="flex items-center space-x-2">
                    <Sparkles className="w-4 h-4 text-purple-400" />
                    <span className="text-sm">{question}</span>
                  </div>
                </motion.button>
              ))}
            </div>
          </div>
        )}

        {questions.map((question) => (
          <div key={question.id} className="space-y-4">
            {/* User Question */}
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              className="flex items-start space-x-3"
            >
              <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center flex-shrink-0">
                <User className="w-4 h-4 text-white" />
              </div>
              <div className="flex-1 bg-blue-500/20 rounded-2xl p-4 border border-blue-500/30">
                <p className="text-white">{question.text}</p>
                <p className="text-xs text-gray-400 mt-2">
                  {question.timestamp.toLocaleTimeString()}
                </p>
              </div>
            </motion.div>

            {/* AI Response */}
            {question.isProcessing ? (
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                className="flex items-start space-x-3"
              >
                <div className="w-8 h-8 bg-gradient-to-r from-purple-500 to-blue-500 rounded-full flex items-center justify-center flex-shrink-0">
                  <Bot className="w-4 h-4 text-white" />
                </div>
                <div className="flex-1 bg-gray-800/50 rounded-2xl p-4 border border-white/10">
                  <div className="flex items-center space-x-2">
                    <Loader2 className="w-4 h-4 text-purple-400 animate-spin" />
                    <span className="text-gray-300">Analyzing your question...</span>
                  </div>
                </div>
              </motion.div>
            ) : question.response && (
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                className="flex items-start space-x-3"
              >
                <div className="w-8 h-8 bg-gradient-to-r from-purple-500 to-blue-500 rounded-full flex items-center justify-center flex-shrink-0">
                  <Bot className="w-4 h-4 text-white" />
                </div>
                <div className="flex-1 space-y-4">
                  {/* Answer */}
                  <div className="bg-gray-800/50 rounded-2xl p-4 border border-white/10">
                    <p className="text-white mb-3">{question.response.answer}</p>
                    
                    {/* Confidence */}
                    <div className="flex items-center space-x-2 mb-4">
                      <div className="flex items-center space-x-1">
                        <Target className="w-4 h-4 text-purple-400" />
                        <span className="text-sm text-gray-400">Confidence:</span>
                        <span className="text-sm font-semibold text-white">
                          {question.response.confidence.toFixed(0)}%
                        </span>
                      </div>
                    </div>

                    {/* Insights */}
                    <div className="space-y-2">
                      <h4 className="text-sm font-semibold text-white">Key Insights:</h4>
                      <div className="space-y-1">
                        {question.response.insights.map((insight, index) => (
                          <div key={index} className="flex items-start space-x-2">
                            <CheckCircle className="w-3 h-3 text-green-400 mt-0.5 flex-shrink-0" />
                            <span className="text-sm text-gray-300">{insight}</span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center space-x-2 mt-4 pt-4 border-t border-white/10">
                      {question.response.actions.map((action) => {
                        const Icon = action.icon
                        return (
                          <motion.button
                            key={action.id}
                            onClick={action.action}
                            className="p-2 text-gray-400 hover:text-white rounded-lg transition-all"
                            whileHover={{ scale: 1.1 }}
                            whileTap={{ scale: 0.9 }}
                            title={action.label}
                          >
                            <Icon className="w-4 h-4" />
                          </motion.button>
                        )
                      })}
                      <motion.button
                        onClick={() => copyToClipboard(question.response!.answer)}
                        className="p-2 text-gray-400 hover:text-white rounded-lg transition-all"
                        whileHover={{ scale: 1.1 }}
                        whileTap={{ scale: 0.9 }}
                        title="Copy answer"
                      >
                        <Copy className="w-4 h-4" />
                      </motion.button>
                    </div>
                  </div>

                  {/* Sources */}
                  <div className="bg-gray-800/30 rounded-xl p-3">
                    <h4 className="text-sm font-semibold text-white mb-2">Sources:</h4>
                    <div className="flex flex-wrap gap-2">
                      {question.response.sources.map((source, index) => (
                        <span
                          key={index}
                          className="px-2 py-1 bg-gray-700/50 rounded-lg text-xs text-gray-300"
                        >
                          {source}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              </motion.div>
            )}
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="p-6 border-t border-white/10">
        <div className="flex items-center space-x-3">
          <div className="flex-1 relative">
            <input
              type="text"
              value={currentQuestion}
              onChange={(e) => setCurrentQuestion(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleAskQuestion()}
              placeholder="Ask about your financial data..."
              className="w-full px-4 py-3 bg-gray-800/50 border border-white/10 rounded-xl text-white placeholder-gray-400 focus:outline-none focus:border-purple-500"
              disabled={isProcessing}
            />
          </div>
          <motion.button
            onClick={handleAskQuestion}
            disabled={!currentQuestion.trim() || isProcessing}
            className="p-3 bg-gradient-to-r from-purple-500 to-blue-500 text-white rounded-xl disabled:opacity-50 disabled:cursor-not-allowed"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            {isProcessing ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              <Send className="w-5 h-5" />
            )}
          </motion.button>
        </div>
      </div>
    </div>
  )
}
