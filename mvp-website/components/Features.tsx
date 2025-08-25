'use client'

import { motion } from 'framer-motion'
import { 
  BarChart3, 
  Brain, 
  Globe, 
  Shield, 
  Zap, 
  TrendingUp,
  Network,
  Cpu,
  Database,
  Activity
} from 'lucide-react'

const features = [
  {
    icon: Globe,
    title: 'Multi-Blockchain Support',
    description: 'Monitor 50+ L2 networks, Cosmos ecosystem, Polkadot parachains, and other blockchains in real-time.',
    color: 'from-blue-500 to-cyan-500'
  },
  {
    icon: Brain,
    title: 'AI/ML Analytics',
    description: 'Advanced machine learning models for price prediction, risk assessment, and anomaly detection.',
    color: 'from-purple-500 to-pink-500'
  },
  {
    icon: Zap,
    title: 'Real-time Monitoring',
    description: 'WebSocket updates and streaming data processing for instant market insights and alerts.',
    color: 'from-yellow-500 to-orange-500'
  },
  {
    icon: Shield,
    title: 'Risk Assessment',
            description: 'Advanced risk scoring and analysis for DeFi protocols and investment opportunities.',
    color: 'from-red-500 to-pink-500'
  },
  {
    icon: TrendingUp,
    title: 'Performance Analytics',
    description: 'Detailed metrics and performance analysis for DeFi protocols and blockchain networks.',
    color: 'from-green-500 to-emerald-500'
  },
  {
    icon: Network,
    title: 'Network Health',
    description: 'Monitor network status, gas fees, and transaction throughput across all supported chains.',
    color: 'from-indigo-500 to-purple-500'
  },
  {
    icon: Cpu,
    title: 'Smart Infrastructure',
    description: 'Scalable microservice architecture with Kubernetes and cloud-native deployment.',
    color: 'from-gray-500 to-slate-500'
  },
  {
    icon: Database,
    title: 'Data Processing',
    description: 'High-performance data processing with PostgreSQL, ClickHouse, and Redis caching.',
    color: 'from-teal-500 to-cyan-500'
  }
]

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1
    }
  }
}

const itemVariants = {
  hidden: { y: 20, opacity: 0 },
  visible: {
    y: 0,
    opacity: 1,
    transition: {
      duration: 0.5
    }
  }
}

export default function Features() {
  return (
    <section id="features" className="py-20 bg-gradient-to-b from-dark-900 to-dark-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            Powerful <span className="gradient-text">Features</span>
          </h2>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Advanced DeFi analytics platform with cutting-edge technology for 
            real-time monitoring, AI-powered insights, and multi-blockchain support.
          </p>
        </motion.div>

        {/* Features Grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8"
        >
          {features.map((feature, index) => (
            <motion.div
              key={index}
              variants={itemVariants}
              whileHover={{ y: -5 }}
              className="group"
            >
              <div className="glass rounded-2xl p-6 h-full transition-all duration-300 hover:shadow-2xl hover:shadow-primary-500/20">
                {/* Icon */}
                <div className={`w-12 h-12 rounded-xl bg-gradient-to-r ${feature.color} flex items-center justify-center mb-4 group-hover:scale-110 transition-transform duration-300`}>
                  <feature.icon className="w-6 h-6 text-white" />
                </div>

                {/* Content */}
                <h3 className="text-xl font-semibold text-white mb-3">
                  {feature.title}
                </h3>
                <p className="text-gray-300 leading-relaxed">
                  {feature.description}
                </p>
              </div>
            </motion.div>
          ))}
        </motion.div>

        {/* Stats Section */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.2 }}
          viewport={{ once: true }}
          className="mt-20 grid grid-cols-2 md:grid-cols-4 gap-8"
        >
          <div className="text-center">
            <div className="text-3xl md:text-4xl font-bold text-primary-400 mb-2">50+</div>
            <div className="text-gray-300">L2 Networks</div>
          </div>
          <div className="text-center">
            <div className="text-3xl md:text-4xl font-bold text-accent-400 mb-2">24/7</div>
            <div className="text-gray-300">Monitoring</div>
          </div>
          <div className="text-center">
            <div className="text-3xl md:text-4xl font-bold text-green-400 mb-2">99.9%</div>
            <div className="text-gray-300">Uptime</div>
          </div>
          <div className="text-center">
            <div className="text-3xl md:text-4xl font-bold text-yellow-400 mb-2">AI/ML</div>
            <div className="text-gray-300">Powered</div>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
