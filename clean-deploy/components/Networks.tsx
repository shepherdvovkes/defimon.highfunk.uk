'use client'

import { motion } from 'framer-motion'
import { ExternalLink, CheckCircle } from 'lucide-react'

const networks = {
  ethereum: {
    name: 'Ethereum',
    description: 'Primary blockchain with L2 scaling solutions',
    networks: [
      'Ethereum Mainnet',
      'Optimism',
      'Arbitrum One',
      'Base',
      'zkSync Era',
      'Polygon zkEVM',
      'Linea',
      'Scroll'
    ],
    color: 'from-blue-500 to-purple-500'
  },
  cosmos: {
    name: 'Cosmos',
    description: 'Interoperable blockchain ecosystem',
    networks: [
      'Cosmos Hub',
      'Osmosis',
      'Injective',
      'Celestia',
      'Sei',
      'Neutron',
      'Stride',
      'Quicksilver'
    ],
    color: 'from-green-500 to-teal-500'
  },
  polkadot: {
    name: 'Polkadot',
    description: 'Multi-chain network with parachains',
    networks: [
      'Polkadot Relay Chain',
      'Kusama',
      'Moonbeam',
      'Astar',
      'Acala',
      'Parallel',
      'Centrifuge',
      'HydraDX'
    ],
    color: 'from-pink-500 to-red-500'
  },
  others: {
    name: 'Other Networks',
    description: 'Additional blockchain ecosystems',
    networks: [
      'Bitcoin',
      'Solana',
      'StarkNet',
      'Cardano',
      'Near Protocol',
      'Algorand',
      'Tezos',
      'Avalanche'
    ],
    color: 'from-yellow-500 to-orange-500'
  }
}

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.2
    }
  }
}

const itemVariants = {
  hidden: { y: 30, opacity: 0 },
  visible: {
    y: 0,
    opacity: 1,
    transition: {
      duration: 0.6
    }
  }
}

export default function Networks() {
  return (
    <section id="networks" className="py-20 bg-gradient-to-b from-dark-800 to-dark-900">
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
            Supported <span className="gradient-text">Networks</span>
          </h2>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Advanced coverage across major blockchain ecosystems with real-time 
            monitoring and analytics for 50+ networks.
          </p>
        </motion.div>

        {/* Networks Grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          className="grid grid-cols-1 lg:grid-cols-2 gap-8"
        >
          {Object.entries(networks).map(([key, network]) => (
            <motion.div
              key={key}
              variants={itemVariants}
              whileHover={{ y: -5 }}
              className="group"
            >
              <div className="glass rounded-2xl p-8 h-full transition-all duration-300 hover:shadow-2xl">
                {/* Header */}
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h3 className="text-2xl font-bold text-white mb-2">
                      {network.name}
                    </h3>
                    <p className="text-gray-300">
                      {network.description}
                    </p>
                  </div>
                  <div className={`w-12 h-12 rounded-xl bg-gradient-to-r ${network.color} flex items-center justify-center group-hover:scale-110 transition-transform duration-300`}>
                    <CheckCircle className="w-6 h-6 text-white" />
                  </div>
                </div>

                {/* Networks List */}
                <div className="space-y-3">
                  {network.networks.map((net, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, x: -20 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      transition={{ duration: 0.3, delay: index * 0.1 }}
                      className="flex items-center space-x-3"
                    >
                      <div className="w-2 h-2 bg-primary-400 rounded-full"></div>
                      <span className="text-gray-300">{net}</span>
                    </motion.div>
                  ))}
                </div>

                {/* Action Button */}
                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  className="mt-6 flex items-center space-x-2 text-primary-400 hover:text-primary-300 transition-colors duration-200"
                >
                  <span>View Details</span>
                  <ExternalLink className="w-4 h-4" />
                </motion.button>
              </div>
            </motion.div>
          ))}
        </motion.div>

        {/* Network Stats */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.4 }}
          viewport={{ once: true }}
          className="mt-16 grid grid-cols-2 md:grid-cols-4 gap-8"
        >
          <div className="text-center">
            <div className="text-3xl md:text-4xl font-bold text-blue-400 mb-2">50+</div>
            <div className="text-gray-300">Total Networks</div>
          </div>
          <div className="text-center">
            <div className="text-3xl md:text-4xl font-bold text-green-400 mb-2">4</div>
            <div className="text-gray-300">Ecosystems</div>
          </div>
          <div className="text-center">
            <div className="text-3xl md:text-4xl font-bold text-purple-400 mb-2">24/7</div>
            <div className="text-gray-300">Monitoring</div>
          </div>
          <div className="text-center">
            <div className="text-3xl md:text-4xl font-bold text-yellow-400 mb-2">Real-time</div>
            <div className="text-gray-300">Data</div>
          </div>
        </motion.div>

        {/* CTA Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.6 }}
          viewport={{ once: true }}
          className="mt-16 text-center"
        >
          <div className="glass rounded-2xl p-8 max-w-2xl mx-auto">
            <h3 className="text-2xl font-bold text-white mb-4">
              Ready to Monitor Your Networks?
            </h3>
            <p className="text-gray-300 mb-6">
              Get started with advanced DeFi analytics and real-time monitoring 
              across all supported blockchain networks.
            </p>
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="px-8 py-3 bg-gradient-to-r from-primary-600 to-accent-600 hover:from-primary-700 hover:to-accent-700 text-white rounded-lg font-semibold transition-all duration-200"
            >
              Start Monitoring Now
            </motion.button>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
