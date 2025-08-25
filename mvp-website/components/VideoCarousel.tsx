'use client'

import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Play, Pause, Volume2, VolumeX, SkipForward, SkipBack } from 'lucide-react'

const videos = [
  { id: 1, src: '/1.mp4', title: 'DeFi Analytics Overview' },
  { id: 2, src: '/2.mp4', title: 'AI-Powered Predictions' },
  { id: 3, src: '/3.mp4', title: 'Multi-Chain Monitoring' },
  { id: 4, src: '/4.mp4', title: 'Real-time Dashboard' }
]

export default function VideoCarousel() {
  const [currentVideoIndex, setCurrentVideoIndex] = useState(0)
  const [isPlaying, setIsPlaying] = useState(true)
  const [isMuted, setIsMuted] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const [autoplayBlocked, setAutoplayBlocked] = useState(false)
  const videoRef = useRef<HTMLVideoElement>(null)
  const [videoDuration, setVideoDuration] = useState(0)
  const [currentTime, setCurrentTime] = useState(0)

  // Auto-play and cycle through videos
  useEffect(() => {
    if (videoRef.current) {
      // Set muted to true for autoplay to work in most browsers
      videoRef.current.muted = true
      setIsMuted(true)
      
      const playPromise = videoRef.current.play()
      
      if (playPromise !== undefined) {
        playPromise
          .then(() => {
            console.log('Video autoplay started successfully')
            setIsPlaying(true)
          })
          .catch((error) => {
            console.log('Autoplay was prevented:', error)
            setIsPlaying(false)
            setAutoplayBlocked(true)
            // Show a message to user that they need to click to play
          })
      }
    }
  }, [currentVideoIndex])

  // Handle video end to cycle to next video
  const handleVideoEnd = () => {
    setCurrentVideoIndex((prev) => (prev + 1) % videos.length)
  }

  // Handle video time update
  const handleTimeUpdate = () => {
    if (videoRef.current) {
      setCurrentTime(videoRef.current.currentTime)
    }
  }

  // Handle video loaded metadata
  const handleLoadedMetadata = () => {
    if (videoRef.current) {
      setVideoDuration(videoRef.current.duration)
      setIsLoading(false)
    }
  }

  // Toggle play/pause
  const togglePlay = () => {
    if (videoRef.current) {
      if (isPlaying) {
        videoRef.current.pause()
        setIsPlaying(false)
      } else {
        const playPromise = videoRef.current.play()
        if (playPromise !== undefined) {
          playPromise
            .then(() => {
              setIsPlaying(true)
              setAutoplayBlocked(false)
            })
            .catch((error) => {
              console.error('Failed to play video:', error)
            })
        }
      }
    }
  }

  // Toggle mute
  const toggleMute = () => {
    if (videoRef.current) {
      videoRef.current.muted = !isMuted
      setIsMuted(!isMuted)
    }
  }

  // Navigate to next video
  const nextVideo = () => {
    setCurrentVideoIndex((prev) => (prev + 1) % videos.length)
  }

  // Navigate to previous video
  const prevVideo = () => {
    setCurrentVideoIndex((prev) => (prev - 1 + videos.length) % videos.length)
  }

  // Format time
  const formatTime = (time: number) => {
    const minutes = Math.floor(time / 60)
    const seconds = Math.floor(time % 60)
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  return (
    <section className="relative h-screen flex items-center justify-center overflow-hidden">
      {/* Background gradient */}
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
            {/* Video player */}
            <div className="relative w-full h-full">
              <AnimatePresence mode="wait">
                <motion.video
                  key={currentVideoIndex}
                  ref={videoRef}
                  className="w-full h-full object-cover"
                  autoPlay
                  muted={isMuted}
                  onEnded={handleVideoEnd}
                  onTimeUpdate={handleTimeUpdate}
                  onLoadedMetadata={handleLoadedMetadata}
                  onLoadStart={() => setIsLoading(true)}
                  onCanPlay={() => setIsLoading(false)}
                  onError={(e) => {
                    console.error('Video error:', e)
                    console.error('Video src:', videos[currentVideoIndex].src)
                  }}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.5 }}
                >
                  <source src={videos[currentVideoIndex].src} type="video/mp4" />
                  Your browser does not support the video tag.
                </motion.video>
              </AnimatePresence>

              {/* Loading overlay */}
              {isLoading && (
                <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                  <div className="text-white text-lg">Loading video...</div>
                </div>
              )}

              {/* Autoplay blocked overlay */}
              {autoplayBlocked && !isPlaying && (
                <div className="absolute inset-0 bg-black/70 flex items-center justify-center">
                  <div className="text-center text-white">
                    <div className="text-xl mb-4">Click to start video playback</div>
                    <button
                      onClick={togglePlay}
                      className="px-6 py-3 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors duration-200"
                    >
                      <Play className="w-5 h-5 inline mr-2" />
                      Play Video
                    </button>
                  </div>
                </div>
              )}

              {/* Video overlay with controls */}
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent">
                {/* Video title */}
                <div className="absolute top-6 left-6 right-6">
                  <motion.h3
                    key={currentVideoIndex}
                    initial={{ opacity: 0, y: -20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5 }}
                    className="text-2xl font-bold text-white"
                  >
                    {videos[currentVideoIndex].title}
                  </motion.h3>
                  <motion.div
                    key={`progress-${currentVideoIndex}`}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ duration: 0.5, delay: 0.2 }}
                    className="text-sm text-gray-300 mt-2"
                  >
                    Video {currentVideoIndex + 1} of {videos.length}
                  </motion.div>
                </div>

                {/* Video controls */}
                <div className="absolute bottom-6 left-6 right-6">
                  {/* Progress bar */}
                  <div className="mb-4">
                    <div className="w-full h-1 bg-white/20 rounded-full overflow-hidden">
                      <motion.div
                        className="h-full bg-primary-500"
                        initial={{ width: "0%" }}
                        animate={{ width: `${(currentTime / videoDuration) * 100}%` }}
                        transition={{ duration: 0.1 }}
                      />
                    </div>
                    <div className="flex justify-between text-sm text-gray-300 mt-2">
                      <span>{formatTime(currentTime)}</span>
                      <span>{formatTime(videoDuration)}</span>
                    </div>
                  </div>

                  {/* Control buttons */}
                  <div className="flex items-center justify-center gap-4">
                    <button
                      onClick={prevVideo}
                      title="Previous video"
                      className="p-3 bg-white/10 hover:bg-white/20 text-white rounded-lg transition-colors duration-200"
                    >
                      <SkipBack className="w-5 h-5" />
                    </button>

                    <button
                      onClick={togglePlay}
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
                          Play
                        </>
                      )}
                    </button>

                    <button
                      onClick={nextVideo}
                      title="Next video"
                      className="p-3 bg-white/10 hover:bg-white/20 text-white rounded-lg transition-colors duration-200"
                    >
                      <SkipForward className="w-5 h-5" />
                    </button>

                    <button
                      onClick={toggleMute}
                      className="p-3 bg-white/10 hover:bg-white/20 text-white rounded-lg transition-colors duration-200"
                    >
                      {isMuted ? (
                        <VolumeX className="w-5 h-5" />
                      ) : (
                        <Volume2 className="w-5 h-5" />
                      )}
                    </button>
                  </div>
                </div>
              </div>
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
