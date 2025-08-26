'use client'

import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { TrendingUp, Shield, Zap, Star } from 'lucide-react'

const videos = [
  { 
    id: 1, 
    src: '/1.mp4', 
    title: 'DeFi Analytics Overview',
    description: 'Advanced DeFi analytics platform showcasing real-time monitoring of 50+ L2 networks, Cosmos ecosystem, and Polkadot parachains. Our advanced dashboard provides deep insights into blockchain performance, gas optimization, and cross-chain interoperability.',
    features: [
      'Real-time network monitoring',
      'Cross-chain analytics',
      'Gas optimization insights',
      'Performance metrics'
    ]
  },
  { 
    id: 2, 
    src: '/2.mp4', 
    title: 'AI-Powered Predictions',
    description: 'Advanced machine learning models for accurate price forecasting and market trend analysis. Our AI algorithms process vast amounts of blockchain data to provide predictive insights for DeFi investments and risk assessment.',
    features: [
      'ML price predictions',
      'Market trend analysis',
      'Risk assessment scoring',
      'Investment recommendations'
    ]
  },
  { 
    id: 3, 
    src: '/3.mp4', 
    title: 'Multi-Chain Monitoring',
    description: 'Seamless monitoring across multiple blockchain networks with unified analytics dashboard. Track TVL, user activity, and protocol performance across Ethereum L2s, Cosmos, and Polkadot ecosystems in real-time.',
    features: [
      'Multi-chain dashboard',
      'Unified analytics',
      'Protocol monitoring',
      'Cross-chain insights'
    ]
  },
  { 
    id: 4, 
    src: '/4.mp4', 
    title: 'Real-time Dashboard',
    description: 'Live dashboard with instant notifications for market changes, anomalies, and opportunities. Monitor your DeFi portfolio, track performance metrics, and receive alerts for critical market events.',
    features: [
      'Live data streaming',
      'Instant notifications',
      'Portfolio tracking',
      'Market alerts'
    ]
  }
]

export default function VideoWithInfo() {
  const [currentVideoIndex, setCurrentVideoIndex] = useState(0)
  const [isLoading, setIsLoading] = useState(true)
  const videoRef = useRef<HTMLVideoElement>(null)

  // Auto-play and cycle through videos
  useEffect(() => {
    if (videoRef.current) {
      videoRef.current.muted = true
      
      const playPromise = videoRef.current.play()
      
      if (playPromise !== undefined) {
        playPromise
          .then(() => {
            console.log('Video autoplay started successfully')
          })
          .catch((error) => {
            console.log('Autoplay was prevented:', error)
          })
      }
    }
  }, [currentVideoIndex])

  // Handle video end to cycle to next video
  const handleVideoEnd = () => {
    setCurrentVideoIndex((prev) => (prev + 1) % videos.length)
  }

  // Handle video loaded metadata
  const handleLoadedMetadata = () => {
    setIsLoading(false)
  }

  const currentVideo = videos[currentVideoIndex]

  return (
    <section className="py-20 bg-gradient-to-br from-dark-900 via-dark-800 to-dark-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            Platform <span className="gradient-text">Showcase</span>
          </h2>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Explore our advanced DeFi analytics platform through interactive demonstrations
          </p>
        </motion.div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12 items-start">
          {/* Video Section - Left Side */}
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
            className="relative order-1 lg:order-1"
          >
            <div className="relative rounded-2xl overflow-hidden glass-dark">
              {/* Video player */}
              <div className="relative aspect-square">
                <AnimatePresence mode="wait">
                  <motion.video
                    key={currentVideoIndex}
                    ref={videoRef}
                    className="w-full h-full object-cover bg-black"
                    autoPlay
                    muted
                    playsInline
                    onEnded={handleVideoEnd}
                    onLoadedMetadata={handleLoadedMetadata}
                    onLoadStart={() => setIsLoading(true)}
                    onCanPlay={() => setIsLoading(false)}
                    onError={(e) => {
                      console.error('Video error:', e)
                      console.error('Video src:', currentVideo.src)
                    }}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{ duration: 0.5 }}
                  >
                    <source src={currentVideo.src} type="video/mp4" />
                    Your browser does not support the video tag.
                  </motion.video>
                </AnimatePresence>

                {/* Loading overlay */}
                {isLoading && (
                  <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                    <div className="text-white text-lg">Loading video...</div>
                  </div>
                )}

                                {/* Video overlay with title only */}
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent">
                  {/* Video title */}
                  <div className="absolute top-4 left-4 right-4">
                    <motion.h3
                      key={currentVideoIndex}
                      initial={{ opacity: 0, y: -20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.5 }}
                      className="text-xl font-bold text-white"
                    >
                      {currentVideo.title}
                    </motion.h3>
                    <motion.div
                      key={`progress-${currentVideoIndex}`}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      transition={{ duration: 0.5, delay: 0.2 }}
                      className="text-sm text-gray-300 mt-1"
                    >
                      Video {currentVideoIndex + 1} of {videos.length}
                    </motion.div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>

          {/* Information Section - Right Side */}
          <motion.div
            initial={{ opacity: 0, x: 50 }}
            whileInView={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            viewport={{ once: true }}
            className="space-y-6 lg:space-y-8 order-2 lg:order-2"
          >
            {/* Video Title and Description */}
            <div>
              <motion.h3
                key={`title-${currentVideoIndex}`}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6 }}
                className="text-2xl lg:text-3xl font-bold text-white mb-4"
              >
                {currentVideo.title}
              </motion.h3>
              
              <motion.p
                key={`desc-${currentVideoIndex}`}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.1 }}
                className="text-base lg:text-lg text-gray-300 leading-relaxed"
              >
                {currentVideo.description}
              </motion.p>
            </div>

            {/* Key Features */}
            <div>
              <h4 className="text-lg lg:text-xl font-semibold text-white mb-4">Key Features</h4>
              <motion.div
                key={`features-${currentVideoIndex}`}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.2 }}
                className="space-y-3"
              >
                {currentVideo.features.map((feature, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.4, delay: 0.3 + index * 0.1 }}
                    className="flex items-center space-x-3"
                  >
                    <div className="w-2 h-2 bg-primary-500 rounded-full flex-shrink-0"></div>
                    <span className="text-gray-300 text-sm lg:text-base">{feature}</span>
                  </motion.div>
                ))}
              </motion.div>
            </div>

            {/* Call to Action */}
            <motion.div
              key={`cta-${currentVideoIndex}`}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.4 }}
              className="pt-4"
            >
              <button className="w-full lg:w-auto px-6 py-3 bg-gradient-to-r from-primary-600 to-accent-600 hover:from-primary-700 hover:to-accent-700 text-white rounded-lg font-semibold transition-all duration-200">
                Learn More
              </button>
            </motion.div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}
