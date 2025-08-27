'use client'

import React, { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  Zap, 
  Cpu, 
  Network, 
  Shield, 
  Activity, 
  TrendingUp, 
  AlertTriangle,
  CheckCircle,
  XCircle,
  Play,
  Pause,
  RotateCcw,
  Settings,
  Maximize2,
  Minimize2
} from 'lucide-react'

// Cyberpunk Card Component
interface CyberpunkCardProps {
  children: React.ReactNode
  className?: string
  variant?: 'primary' | 'secondary' | 'danger' | 'success'
  glow?: boolean
  glitch?: boolean
  interactive?: boolean
  onClick?: () => void
}

export const CyberpunkCard: React.FC<CyberpunkCardProps> = ({
  children,
  className = '',
  variant = 'primary',
  glow = false,
  glitch = false,
  interactive = false,
  onClick
}) => {
  const [isGlitching, setIsGlitching] = useState(false)

  useEffect(() => {
    if (glitch) {
      const interval = setInterval(() => {
        setIsGlitching(Math.random() > 0.8)
      }, 2000)
      return () => clearInterval(interval)
    }
  }, [glitch])

  const variantColors = {
    primary: { border: '#ff00ff', glow: '#ff00ff', bg: 'rgba(255, 0, 255, 0.1)' },
    secondary: { border: '#00ffff', glow: '#00ffff', bg: 'rgba(0, 255, 255, 0.1)' },
    danger: { border: '#ff0000', glow: '#ff0000', bg: 'rgba(255, 0, 0, 0.1)' },
    success: { border: '#00ff00', glow: '#00ff00', bg: 'rgba(0, 255, 0, 0.1)' }
  }

  const colors = variantColors[variant]

  return (
    <motion.div
      className={`cyberpunk-card ${className}`}
      style={{
        borderColor: colors.border,
        boxShadow: glow ? `0 0 20px ${colors.glow}` : 'none',
        backgroundColor: colors.bg,
        transform: isGlitching ? 'skew(1deg)' : 'skew(0deg)'
      }}
      whileHover={interactive ? { scale: 1.02, y: -2 } : {}}
      whileTap={interactive ? { scale: 0.98 } : {}}
      onClick={onClick}
      animate={{
        filter: isGlitching ? 'hue-rotate(90deg)' : 'hue-rotate(0deg)'
      }}
      transition={{ duration: 0.1 }}
    >
      {glitch && (
        <div className="cyberpunk-glitch-overlay" />
      )}
      <div className="cyberpunk-content">
        {children}
      </div>
    </motion.div>
  )
}

// Cyberpunk Button Component
interface CyberpunkButtonProps {
  children: React.ReactNode
  variant?: 'primary' | 'secondary' | 'danger' | 'success'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  onClick?: () => void
  className?: string
  icon?: React.ReactNode
}

export const CyberpunkButton: React.FC<CyberpunkButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  disabled = false,
  onClick,
  className = '',
  icon
}) => {
  const variantColors = {
    primary: { border: '#ff00ff', bg: 'rgba(255, 0, 255, 0.2)', text: '#ff00ff' },
    secondary: { border: '#00ffff', bg: 'rgba(0, 255, 255, 0.2)', text: '#00ffff' },
    danger: { border: '#ff0000', bg: 'rgba(255, 0, 0, 0.2)', text: '#ff0000' },
    success: { border: '#00ff00', bg: 'rgba(0, 255, 0, 0.2)', text: '#00ff00' }
  }

  const colors = variantColors[variant]
  const sizeClasses = {
    sm: 'px-3 py-2 text-sm',
    md: 'px-6 py-3 text-base',
    lg: 'px-8 py-4 text-lg'
  }

  return (
    <motion.button
      className={`cyberpunk-button ${sizeClasses[size]} ${className}`}
      style={{
        borderColor: colors.border,
        backgroundColor: colors.bg,
        color: colors.text
      }}
      whileHover={!disabled ? { scale: 1.05, boxShadow: `0 0 15px ${colors.border}` } : {}}
      whileTap={!disabled ? { scale: 0.95 } : {}}
      onClick={onClick}
      disabled={disabled}
    >
      {icon && <span className="cyberpunk-button-icon">{icon}</span>}
      {children}
    </motion.button>
  )
}

// Cyberpunk Data Display
interface CyberpunkDataDisplayProps {
  title: string
  value: string | number
  unit?: string
  trend?: 'up' | 'down' | 'neutral'
  status?: 'online' | 'offline' | 'warning' | 'error'
  className?: string
}

export const CyberpunkDataDisplay: React.FC<CyberpunkDataDisplayProps> = ({
  title,
  value,
  unit,
  trend,
  status = 'online',
  className = ''
}) => {
  const statusColors = {
    online: '#00ff00',
    offline: '#ff0000',
    warning: '#ffff00',
    error: '#ff0000'
  }

  const trendIcons = {
    up: <TrendingUp className="w-4 h-4" />,
    down: <TrendingUp className="w-4 h-4 transform rotate-180" />,
    neutral: <Activity className="w-4 h-4" />
  }

  return (
    <div className={`cyberpunk-data-display ${className}`}>
      <div className="cyberpunk-data-header">
        <h3 className="cyberpunk-data-title">{title}</h3>
        <div 
          className="cyberpunk-status-indicator"
          style={{ backgroundColor: statusColors[status] }}
        />
      </div>
      <div className="cyberpunk-data-value">
        <span className="value">{value}</span>
        {unit && <span className="unit">{unit}</span>}
        {trend && (
          <span className="trend-icon">
            {trendIcons[trend]}
          </span>
        )}
      </div>
    </div>
  )
}

// Cyberpunk Terminal
interface CyberpunkTerminalProps {
  title?: string
  children: React.ReactNode
  className?: string
  fullscreen?: boolean
  onFullscreenToggle?: () => void
}

export const CyberpunkTerminal: React.FC<CyberpunkTerminalProps> = ({
  title = 'TERMINAL',
  children,
  className = '',
  fullscreen = false,
  onFullscreenToggle
}) => {
  const [isTyping, setIsTyping] = useState(false)

  useEffect(() => {
    setIsTyping(true)
    const timer = setTimeout(() => setIsTyping(false), 1000)
    return () => clearTimeout(timer)
  }, [children])

  return (
    <div className={`cyberpunk-terminal ${fullscreen ? 'fullscreen' : ''} ${className}`}>
      <div className="cyberpunk-terminal-header">
        <div className="terminal-title">
          <span className="terminal-prefix">$</span>
          {title}
        </div>
        <div className="terminal-controls">
          <button className="terminal-control minimize" aria-label="Minimize terminal">
            <Minimize2 className="w-3 h-3" />
          </button>
          <button className="terminal-control maximize" onClick={onFullscreenToggle} aria-label="Toggle fullscreen">
            <Maximize2 className="w-3 h-3" />
          </button>
          <button className="terminal-control close" aria-label="Close terminal">
            <XCircle className="w-3 h-3" />
          </button>
        </div>
      </div>
      <div className="cyberpunk-terminal-content">
        <div className="terminal-cursor">
          {isTyping && <span className="cursor-blink">|</span>}
        </div>
        {children}
      </div>
    </div>
  )
}

// Cyberpunk Progress Bar
interface CyberpunkProgressBarProps {
  progress: number
  max?: number
  label?: string
  variant?: 'primary' | 'secondary' | 'danger' | 'success'
  animated?: boolean
  className?: string
}

export const CyberpunkProgressBar: React.FC<CyberpunkProgressBarProps> = ({
  progress,
  max = 100,
  label,
  variant = 'primary',
  animated = true,
  className = ''
}) => {
  const percentage = (progress / max) * 100
  const variantColors = {
    primary: '#ff00ff',
    secondary: '#00ffff',
    danger: '#ff0000',
    success: '#00ff00'
  }

  const color = variantColors[variant]

  return (
    <div className={`cyberpunk-progress ${className}`}>
      {label && <div className="progress-label">{label}</div>}
      <div className="progress-container">
        <div 
          className="progress-bar"
          style={{ 
            width: `${percentage}%`,
            backgroundColor: color,
            boxShadow: `0 0 10px ${color}`
          }}
        >
          {animated && (
            <div 
              className="progress-glow"
              style={{ backgroundColor: color }}
            />
          )}
        </div>
        <div className="progress-text">{Math.round(percentage)}%</div>
      </div>
    </div>
  )
}

// Cyberpunk Alert System
interface CyberpunkAlertProps {
  type: 'info' | 'warning' | 'error' | 'success'
  title: string
  message: string
  onClose?: () => void
  autoClose?: boolean
  duration?: number
}

export const CyberpunkAlert: React.FC<CyberpunkAlertProps> = ({
  type,
  title,
  message,
  onClose,
  autoClose = false,
  duration = 5000
}) => {
  const [isVisible, setIsVisible] = useState(true)

  useEffect(() => {
    if (autoClose) {
      const timer = setTimeout(() => {
        setIsVisible(false)
        onClose?.()
      }, duration)
      return () => clearTimeout(timer)
    }
  }, [autoClose, duration, onClose])

  const typeConfig = {
    info: { color: '#00ffff', icon: <Activity className="w-5 h-5" /> },
    warning: { color: '#ffff00', icon: <AlertTriangle className="w-5 h-5" /> },
    error: { color: '#ff0000', icon: <XCircle className="w-5 h-5" /> },
    success: { color: '#00ff00', icon: <CheckCircle className="w-5 h-5" /> }
  }

  const config = typeConfig[type]

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          className="cyberpunk-alert"
          initial={{ opacity: 0, x: -100 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: 100 }}
          style={{ borderColor: config.color }}
        >
          <div className="alert-icon" style={{ color: config.color }}>
            {config.icon}
          </div>
          <div className="alert-content">
            <h4 className="alert-title">{title}</h4>
            <p className="alert-message">{message}</p>
          </div>
          {onClose && (
            <button className="alert-close" onClick={onClose} aria-label="Close alert">
              <XCircle className="w-4 h-4" />
            </button>
          )}
        </motion.div>
      )}
    </AnimatePresence>
  )
}
