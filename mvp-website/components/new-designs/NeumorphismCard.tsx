'use client'

import React from 'react'
import { motion } from 'framer-motion'

interface NeumorphismCardProps {
  children: React.ReactNode
  className?: string
  variant?: 'light' | 'dark'
  size?: 'sm' | 'md' | 'lg'
  interactive?: boolean
  onClick?: () => void
}

export const NeumorphismCard: React.FC<NeumorphismCardProps> = ({
  children,
  className = '',
  variant = 'light',
  size = 'md',
  interactive = false,
  onClick
}) => {
  const baseClasses = `
    neumorphism-card
    neumorphism-${variant}
    neumorphism-${size}
    ${interactive ? 'neumorphism-interactive' : ''}
    ${className}
  `

  const sizeClasses = {
    sm: 'p-4 rounded-lg',
    md: 'p-6 rounded-xl',
    lg: 'p-8 rounded-2xl'
  }

  const variantClasses = {
    light: 'bg-gray-100 shadow-light',
    dark: 'bg-gray-800 shadow-dark'
  }

  return (
    <motion.div
      className={`${baseClasses} ${sizeClasses[size]} ${variantClasses[variant]}`}
      whileHover={interactive ? { scale: 1.02, y: -2 } : {}}
      whileTap={interactive ? { scale: 0.98 } : {}}
      onClick={onClick}
      style={{ cursor: interactive ? 'pointer' : 'default' }}
    >
      {children}
    </motion.div>
  )
}

// Neumorphism Button Component
interface NeumorphismButtonProps {
  children: React.ReactNode
  variant?: 'primary' | 'secondary' | 'success' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  onClick?: () => void
  className?: string
}

export const NeumorphismButton: React.FC<NeumorphismButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  disabled = false,
  onClick,
  className = ''
}) => {
  const baseClasses = `
    neumorphism-button
    neumorphism-button-${variant}
    neumorphism-button-${size}
    ${disabled ? 'neumorphism-button-disabled' : ''}
    ${className}
  `

  const sizeClasses = {
    sm: 'px-4 py-2 text-sm rounded-lg',
    md: 'px-6 py-3 text-base rounded-xl',
    lg: 'px-8 py-4 text-lg rounded-2xl'
  }

  return (
    <motion.button
      className={`${baseClasses} ${sizeClasses[size]}`}
      whileHover={!disabled ? { scale: 1.05, y: -1 } : {}}
      whileTap={!disabled ? { scale: 0.95 } : {}}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </motion.button>
  )
}

// Neumorphism Input Component
interface NeumorphismInputProps {
  placeholder?: string
  value?: string
  onChange?: (value: string) => void
  type?: 'text' | 'password' | 'email' | 'number'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  className?: string
}

export const NeumorphismInput: React.FC<NeumorphismInputProps> = ({
  placeholder,
  value,
  onChange,
  type = 'text',
  size = 'md',
  disabled = false,
  className = ''
}) => {
  const baseClasses = `
    neumorphism-input
    neumorphism-input-${size}
    ${disabled ? 'neumorphism-input-disabled' : ''}
    ${className}
  `

  const sizeClasses = {
    sm: 'px-3 py-2 text-sm rounded-lg',
    md: 'px-4 py-3 text-base rounded-xl',
    lg: 'px-6 py-4 text-lg rounded-2xl'
  }

  return (
    <input
      type={type}
      placeholder={placeholder}
      value={value}
      onChange={(e) => onChange?.(e.target.value)}
      disabled={disabled}
      className={`${baseClasses} ${sizeClasses[size]}`}
    />
  )
}

// Neumorphism Toggle Component
interface NeumorphismToggleProps {
  checked: boolean
  onChange: (checked: boolean) => void
  disabled?: boolean
  size?: 'sm' | 'md' | 'lg'
  className?: string
}

export const NeumorphismToggle: React.FC<NeumorphismToggleProps> = ({
  checked,
  onChange,
  disabled = false,
  size = 'md',
  className = ''
}) => {
  const baseClasses = `
    neumorphism-toggle
    neumorphism-toggle-${size}
    ${disabled ? 'neumorphism-toggle-disabled' : ''}
    ${className}
  `

  const sizeClasses = {
    sm: 'w-12 h-6',
    md: 'w-16 h-8',
    lg: 'w-20 h-10'
  }

  return (
    <motion.button
      className={`${baseClasses} ${sizeClasses[size]}`}
      onClick={() => !disabled && onChange(!checked)}
      disabled={disabled}
      animate={{
        backgroundColor: checked ? '#3b82f6' : '#e5e7eb',
        x: checked ? (size === 'sm' ? 24 : size === 'md' ? 32 : 40) : 0
      }}
      transition={{ type: 'spring', stiffness: 500, damping: 30 }}
    >
      <motion.div
        className="neumorphism-toggle-thumb"
        animate={{
          scale: checked ? 1 : 0.8
        }}
      />
    </motion.button>
  )
}
