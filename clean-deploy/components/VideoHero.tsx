'use client'

import { useState } from 'react'
import { Play, Pause, Volume2, VolumeX } from 'lucide-react'
import { motion } from 'framer-motion'

export default function VideoHero() {
  const [isPlaying, setIsPlaying] = useState(false)
  const [isMuted, setIsMuted] = useState(false)

  return (
    <section className="relative h-screen flex items-center justify-center overflow-hidden">
      {/* Video Placeholder */}
      <div className="absolute inset-0 bg-gradient-to-br from-dark-900 via-dark-800 to-dark-900">
        {/* Animated background pattern */}
        <div className="absolute inset-0 opacity-20">
          <div className="absolute top-1/4 left-1/4 w-64 h-64 bg-primary-500/20 rounded-full blur-3xl animate-pulse-slow"></div>
          <div className="absolute top-3/4 right-1/4 w-96 h-96 bg-accent-500/20 rounded-full blur-3xl animate-pulse-slow delay-1000"></div>
          <div className="absolute bottom-1/4 left-1/2 w-80 h-80 bg-blue-500/20 rounded-full blur-3xl animate-pulse-slow delay-2000"></div>
        </div>
        
        {/* Video container */}
        <div className="relative w-full h-full flex items-center justify-center">
          <div className="relative w-4/5 h-3/4 max-w-6xl rounded-2xl overflow-hidden glass-dark">
            {/* Video placeholder with overlay */}
            <div className="w-full h-full bg-gradient-to-br from-dark-800 to-dark-900 flex items-center justify-center">
              <div className="text-center">
                <motion.div
                  initial={{ scale: 0.8, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ duration: 0.8, ease: "easeOut" }}
                  className="mb-8"
                >
                  <div className="w-24 h-24 mx-auto bg-primary-500/20 rounded-full flex items-center justify-center mb-4">
                    <Play className="w-12 h-12 text-primary-400 ml-1" />
                  </div>
                  <h3 className="text-2xl font-bold text-white mb-2">
                    DEFIMON Platform Demo
                  </h3>
                  <p className="text-gray-300 max-w-md mx-auto">
                    Watch our advanced demo showcasing real-time DeFi analytics, 
                    AI-powered predictions, and multi-blockchain monitoring capabilities.
                  </p>
                </motion.div>
                
                {/* Video controls */}
                <motion.div
                  initial={{ y: 20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ duration: 0.8, delay: 0.3 }}
                  className="flex items-center justify-center gap-4"
                >
                  <button
                    onClick={() => setIsPlaying(!isPlaying)}
                    className="flex items-center gap-2 px-6 py-3 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors duration-200"
                  >
                    {isPlaying ? (
                      <>
                        <Pause className="w-5 h-5" />
                        Pause
                      </>
                    ) : (
                      <>
                        <Play className="w-5 h-5" />
                        Play Demo
                      </>
                    )}
                  </button>
                  
                  <button
                    onClick={() => setIsMuted(!isMuted)}
                    className="p-3 bg-white/10 hover:bg-white/20 text-white rounded-lg transition-colors duration-200"
                  >
                    {isMuted ? (
                      <VolumeX className="w-5 h-5" />
                    ) : (
                      <Volume2 className="w-5 h-5" />
                    )}
                  </button>
                </motion.div>
                
                {/* Video info */}
                <motion.div
                  initial={{ y: 20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ duration: 0.8, delay: 0.6 }}
                  className="mt-8 text-sm text-gray-400"
                >
                  <p>Duration: 3:45 • Resolution: 4K • Subtitles: Available</p>
                </motion.div>
              </div>
            </div>
            
            {/* Video progress bar */}
            <div className="absolute bottom-0 left-0 right-0 h-1 bg-white/20">
              <motion.div
                className="h-full bg-primary-500"
                initial={{ width: "0%" }}
                animate={{ width: isPlaying ? "45%" : "0%" }}
                transition={{ duration: 0.5 }}
              />
            </div>
          </div>
        </div>
      </div>
      
      {/* Floating elements */}
      <motion.div
        className="absolute top-20 left-20 text-primary-400"
        animate={{ y: [0, -10, 0] }}
        transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
      >
        <div className="w-2 h-2 bg-primary-400 rounded-full"></div>
      </motion.div>
      
      <motion.div
        className="absolute top-40 right-32 text-accent-400"
        animate={{ y: [0, 10, 0] }}
        transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
      >
        <div className="w-3 h-3 bg-accent-400 rounded-full"></div>
      </motion.div>
      
      <motion.div
        className="absolute bottom-32 left-1/3 text-blue-400"
        animate={{ y: [0, -15, 0] }}
        transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
      >
        <div className="w-1 h-1 bg-blue-400 rounded-full"></div>
      </motion.div>
    </section>
  )
}
