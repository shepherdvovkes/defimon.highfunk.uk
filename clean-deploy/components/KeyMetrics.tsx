'use client'

import { motion } from 'framer-motion'
import { 
  TrendingUp, 
  TrendingDown, 
  DollarSign, 
  Users, 
  Activity, 
  Shield, 
  Zap, 
  Globe,
  Cpu,
  Database,
  BarChart3,
  PieChart,
  LineChart,
  Star,
  Target,
  CheckCircle,
  AlertTriangle,
  Clock,
  Play
} from 'lucide-react'

export default function KeyMetrics() {
  const metrics = [
    { 
      name: "TVL", 
      value: "$2.4B", 
      change: "+12.5%", 
      trend: "up", 
      icon: DollarSign,
      description: "Общая заблокированная стоимость"
    },
    { 
      name: "Активные пользователи", 
      value: "45.2K", 
      change: "+8.3%", 
      trend: "up", 
      icon: Users,
      description: "Ежемесячные активные пользователи"
    },
    { 
      name: "Транзакции/сек", 
      value: "1,247", 
      change: "-2.1%", 
      trend: "down", 
      icon: Activity,
      description: "Средняя пропускная способность"
    },
    { 
      name: "Риск-скор", 
      value: "7.2/10", 
      change: "+0.3", 
      trend: "up", 
      icon: Shield,
      description: "Средний показатель безопасности"
    }
  ]

  const advantages = [
    {
      title: "AI/ML Прогнозирование",
      description: "Продвинутые алгоритмы машинного обучения для точного прогнозирования цен и анализа рыночных трендов",
      icon: Cpu,
      color: "from-blue-500 to-cyan-500"
    },
    {
      title: "Мониторинг всех сетей",
      description: "Отслеживание 50+ L2 сетей, Cosmos экосистемы и Polkadot парачейнов в реальном времени",
      icon: Globe,
      color: "from-green-500 to-emerald-500"
    },
    {
      title: "Простые ответы",
      description: "Сложные данные представлены в понятном формате для быстрого принятия решений",
      icon: Zap,
      color: "from-purple-500 to-pink-500"
    },
    {
      title: "Комплексная аналитика",
      description: "Глубокий анализ рисков, ликвидности и безопасности протоколов",
      icon: BarChart3,
      color: "from-orange-500 to-red-500"
    }
  ]

  const competitors = [
    {
      name: "DeFiPulse",
      weakness: "Ограниченная аналитика",
      ourAdvantage: "AI/ML прогнозирование и комплексный анализ"
    },
    {
      name: "DeFiLlama",
      weakness: "Сложный интерфейс для новичков",
      ourAdvantage: "Простые ответы на сложные вопросы"
    },
    {
      name: "CoinGecko",
      weakness: "Только основные метрики",
      ourAdvantage: "Мониторинг всех сетей и экосистем"
    },
    {
      name: "DefiPulse",
      weakness: "Отсутствие AI/ML функций",
      ourAdvantage: "Искусственный интеллект для прогнозирования"
    }
  ]

  return (
    <div className="py-20 bg-gradient-to-b from-dark-800 to-dark-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Key Metrics Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            Ключевые <span className="gradient-text">метрики</span>
          </h2>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Реальные данные и показатели нашей платформы в реальном времени
          </p>
        </motion.div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-16">
          {metrics.map((metric, index) => (
            <motion.div
              key={metric.name}
              initial={{ opacity: 0, scale: 0.9 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              viewport={{ once: true }}
              className="glass rounded-2xl p-6 text-center group hover:scale-105 transition-transform"
            >
              <div className="flex items-center justify-between mb-4">
                <metric.icon className="w-6 h-6 text-primary-400" />
                <div className={`flex items-center space-x-1 ${
                  metric.trend === 'up' ? 'text-green-400' : 'text-red-400'
                }`}>
                  {metric.trend === 'up' ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
                  <span className="text-sm font-medium">{metric.change}</span>
                </div>
              </div>
              <div className="text-3xl font-bold text-white mb-2">{metric.value}</div>
              <div className="text-lg font-semibold text-gray-300 mb-2">{metric.name}</div>
              <div className="text-sm text-gray-400">{metric.description}</div>
            </motion.div>
          ))}
        </div>

        {/* Advantages Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            Наши <span className="gradient-text">преимущества</span>
          </h2>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Что отличает DeFiMon от конкурентов
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-16">
          {advantages.map((advantage, index) => (
            <motion.div
              key={advantage.title}
              initial={{ opacity: 0, x: index % 2 === 0 ? -20 : 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              viewport={{ once: true }}
              className="glass rounded-2xl p-8 group hover:scale-105 transition-transform"
            >
              <div className={`w-16 h-16 bg-gradient-to-r ${advantage.color} rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform`}>
                <advantage.icon className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-2xl font-bold text-white mb-4">{advantage.title}</h3>
              <p className="text-gray-300 leading-relaxed">{advantage.description}</p>
            </motion.div>
          ))}
        </div>

        {/* Competitive Analysis */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-center mb-12"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            Сравнение с <span className="gradient-text">конкурентами</span>
          </h2>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Почему DeFiMon - лучший выбор для вашей аналитики
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {competitors.map((competitor, index) => (
            <motion.div
              key={competitor.name}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              viewport={{ once: true }}
              className="glass rounded-2xl p-6 border border-white/10"
            >
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-xl font-bold text-white">{competitor.name}</h3>
                <div className="flex items-center space-x-2">
                  <AlertTriangle className="w-5 h-5 text-red-400" />
                  <span className="text-sm text-red-400">Слабость</span>
                </div>
              </div>
              
              <div className="mb-4 p-3 bg-red-500/10 rounded-lg border border-red-500/20">
                <p className="text-gray-300 text-sm">{competitor.weakness}</p>
              </div>
              
              <div className="flex items-center space-x-2">
                <CheckCircle className="w-5 h-5 text-green-400" />
                <span className="text-sm text-green-400 font-medium">Наше преимущество:</span>
              </div>
              <p className="text-white font-medium mt-1">{competitor.ourAdvantage}</p>
            </motion.div>
          ))}
        </div>

        {/* Call to Action */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="mt-16 text-center"
        >
          <div className="bg-gradient-to-r from-primary-600 to-accent-600 rounded-2xl p-8">
            <h3 className="text-3xl font-bold text-white mb-4">
              Готовы попробовать?
            </h3>
            <p className="text-xl text-white/90 mb-6 max-w-2xl mx-auto">
              Начните использовать DeFiMon сегодня и получите доступ к лучшей аналитике DeFi
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <a
                href="/demo"
                className="px-8 py-4 bg-white text-primary-600 rounded-lg font-semibold text-lg hover:bg-gray-100 transition-colors flex items-center justify-center space-x-2"
              >
                <Play className="w-5 h-5" />
                <span>Посмотреть демо</span>
              </a>
              <button className="px-8 py-4 bg-white/10 text-white rounded-lg font-semibold text-lg hover:bg-white/20 transition-colors border border-white/20">
                Начать бесплатно
              </button>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  )
}
