'use client'

import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { 
  Zap, 
  Cpu, 
  Network, 
  Shield, 
  Activity, 
  TrendingUp, 
  DollarSign,
  Users,
  BarChart3,
  Settings,
  Palette,
  Eye,
  Code
} from 'lucide-react'

// Import new design components
import { 
  NeumorphismCard, 
  NeumorphismButton, 
  NeumorphismInput, 
  NeumorphismToggle 
} from '../../components/new-designs/NeumorphismCard'

import {
  CyberpunkCard,
  CyberpunkButton,
  CyberpunkDataDisplay,
  CyberpunkTerminal,
  CyberpunkProgressBar,
  CyberpunkAlert
} from '../../components/new-designs/CyberpunkInterface'

// Import CSS files
import '../neumorphism.css'
import '../cyberpunk.css'

export default function DesignsShowcase() {
  const [neumorphismToggle, setNeumorphismToggle] = useState(false)
  const [cyberpunkToggle, setCyberpunkToggle] = useState(true)
  const [terminalFullscreen, setTerminalFullscreen] = useState(false)
  const [showAlert, setShowAlert] = useState(false)

  const metrics = [
    { title: 'TVL', value: '$2.4B', unit: 'USD', trend: 'up' as const, status: 'online' as const },
    { title: 'Volume', value: '856M', unit: 'USD', trend: 'up' as const, status: 'online' as const },
    { title: 'Users', value: '124K', unit: 'Active', trend: 'down' as const, status: 'warning' as const },
    { title: 'APY', value: '12.4', unit: '%', trend: 'neutral' as const, status: 'online' as const }
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-black to-gray-800">
      {/* Header */}
      <header className="relative z-10 pt-8 pb-16">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <h1 className="text-5xl md:text-7xl font-black text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-blue-400 mb-6">
              Design Systems
            </h1>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              Коллекция современных дизайн-систем для DeFiMon проекта
            </p>
          </motion.div>
        </div>
      </header>

      {/* Navigation */}
      <nav className="sticky top-0 z-20 bg-black/50 backdrop-blur-md border-b border-gray-800">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center space-x-8">
              <a href="#neumorphism" className="text-gray-300 hover:text-white transition-colors">
                Neumorphism
              </a>
              <a href="#cyberpunk" className="text-gray-300 hover:text-white transition-colors">
                Cyberpunk
              </a>
              <a href="#comparison" className="text-gray-300 hover:text-white transition-colors">
                Comparison
              </a>
            </div>
            <div className="flex items-center space-x-4">
              <button className="text-gray-300 hover:text-white transition-colors" aria-label="Design palette">
                <Palette className="w-5 h-5" />
              </button>
              <button className="text-gray-300 hover:text-white transition-colors" aria-label="View code">
                <Code className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* Neumorphism Section */}
      <section id="neumorphism" className="py-20">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl font-bold text-white mb-4">Neumorphism Design</h2>
            <p className="text-gray-300 max-w-2xl mx-auto">
              Современный неоморфизм с мягкими тенями и минималистичными формами
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {/* Neumorphism Cards */}
            <NeumorphismCard interactive className="neumorphism-float">
              <div className="text-center">
                <DollarSign className="w-12 h-12 text-blue-600 mx-auto mb-4" />
                <h3 className="text-xl font-bold text-gray-800 mb-2">TVL</h3>
                <p className="text-3xl font-bold text-blue-600">$2.4B</p>
                <p className="text-green-600 text-sm mt-2">+12.5%</p>
              </div>
            </NeumorphismCard>

            <NeumorphismCard interactive className="neumorphism-float">
              <div className="text-center">
                <Users className="w-12 h-12 text-purple-600 mx-auto mb-4" />
                <h3 className="text-xl font-bold text-gray-800 mb-2">Users</h3>
                <p className="text-3xl font-bold text-purple-600">124K</p>
                <p className="text-green-600 text-sm mt-2">+8.3%</p>
              </div>
            </NeumorphismCard>

            <NeumorphismCard interactive className="neumorphism-float">
              <div className="text-center">
                <Activity className="w-12 h-12 text-emerald-600 mx-auto mb-4" />
                <h3 className="text-xl font-bold text-gray-800 mb-2">Volume</h3>
                <p className="text-3xl font-bold text-emerald-600">$856M</p>
                <p className="text-green-600 text-sm mt-2">+15.2%</p>
              </div>
            </NeumorphismCard>
          </div>

          {/* Neumorphism Controls */}
          <div className="mt-16 grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="space-y-6">
              <h3 className="text-2xl font-bold text-white mb-6">Controls</h3>
              
              <div className="space-y-4">
                <NeumorphismButton variant="primary" size="lg">
                  Primary Action
                </NeumorphismButton>
                
                <NeumorphismButton variant="secondary" size="md">
                  Secondary Action
                </NeumorphismButton>
                
                <NeumorphismButton variant="success" size="sm">
                  Success Action
                </NeumorphismButton>
              </div>

              <div className="space-y-4">
                <NeumorphismInput 
                  placeholder="Enter your data..."
                  size="md"
                />
                
                <div className="flex items-center space-x-4">
                  <span className="text-gray-300">Auto Refresh:</span>
                  <NeumorphismToggle
                    checked={neumorphismToggle}
                    onChange={setNeumorphismToggle}
                  />
                </div>
              </div>
            </div>

            <div className="space-y-6">
              <h3 className="text-2xl font-bold text-white mb-6">Features</h3>
              
              <div className="space-y-4">
                <NeumorphismCard className="neumorphism-pulse">
                  <div className="flex items-center space-x-4">
                    <Zap className="w-8 h-8 text-orange-500" />
                    <div>
                      <h4 className="font-bold text-gray-800">Real-time Updates</h4>
                      <p className="text-gray-600 text-sm">Live data streaming</p>
                    </div>
                  </div>
                </NeumorphismCard>

                <NeumorphismCard className="neumorphism-glow">
                  <div className="flex items-center space-x-4">
                    <Shield className="w-8 h-8 text-green-500" />
                    <div>
                      <h4 className="font-bold text-gray-800">Security First</h4>
                      <p className="text-gray-600 text-sm">Enterprise-grade protection</p>
                    </div>
                  </div>
                </NeumorphismCard>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Cyberpunk Section */}
      <section id="cyberpunk" className="py-20 bg-black/50">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-pink-400 to-cyan-400 mb-4">
              Cyberpunk Interface
            </h2>
            <p className="text-gray-300 max-w-2xl mx-auto">
              Футуристический дизайн с неоновыми акцентами и глитч-эффектами
            </p>
          </motion.div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-16">
            {/* Cyberpunk Data Displays */}
            <div className="space-y-4">
              {metrics.map((metric, index) => (
                <motion.div
                  key={metric.title}
                  initial={{ opacity: 0, x: -20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  transition={{ duration: 0.6, delay: index * 0.1 }}
                  viewport={{ once: true }}
                >
                  <CyberpunkDataDisplay
                    title={metric.title}
                    value={metric.value}
                    unit={metric.unit}
                    trend={metric.trend}
                    status={metric.status}
                  />
                </motion.div>
              ))}
            </div>

            {/* Cyberpunk Terminal */}
            <div>
              <CyberpunkTerminal
                title="SYSTEM_MONITOR"
                fullscreen={terminalFullscreen}
                onFullscreenToggle={() => setTerminalFullscreen(!terminalFullscreen)}
              >
                <div className="space-y-2 text-sm">
                  <div className="text-green-400">$ system_status</div>
                  <div className="text-white">Network: ONLINE</div>
                  <div className="text-white">Database: CONNECTED</div>
                  <div className="text-white">API: RESPONDING</div>
                  <div className="text-green-400">$ load_analytics</div>
                  <div className="text-white">Loading market data...</div>
                  <div className="text-cyan-400">✓ Data loaded successfully</div>
                  <div className="text-green-400">$</div>
                </div>
              </CyberpunkTerminal>
            </div>
          </div>

          {/* Cyberpunk Controls */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="space-y-6">
              <h3 className="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-pink-400 to-cyan-400 mb-6">
                Controls
              </h3>
              
              <div className="space-y-4">
                <CyberpunkButton variant="primary" size="lg" icon={<Zap className="w-5 h-5" />}>
                  Initialize System
                </CyberpunkButton>
                
                <CyberpunkButton variant="secondary" size="md" icon={<Cpu className="w-5 h-5" />}>
                  Run Analysis
                </CyberpunkButton>
                
                <CyberpunkButton variant="danger" size="sm" icon={<Shield className="w-5 h-5" />}>
                  Emergency Stop
                </CyberpunkButton>
              </div>

              <div className="space-y-4">
                <CyberpunkProgressBar
                  progress={75}
                  label="System Load"
                  variant="primary"
                />
                
                <CyberpunkProgressBar
                  progress={45}
                  label="Memory Usage"
                  variant="secondary"
                />
              </div>
            </div>

            <div className="space-y-6">
              <h3 className="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-pink-400 to-cyan-400 mb-6">
                Alerts
              </h3>
              
              <div className="space-y-4">
                <CyberpunkAlert
                  type="info"
                  title="System Update"
                  message="New data available for analysis"
                  onClose={() => setShowAlert(false)}
                />
                
                <CyberpunkAlert
                  type="warning"
                  title="High Load"
                  message="System resources at 85% capacity"
                  onClose={() => setShowAlert(false)}
                />
                
                <CyberpunkAlert
                  type="success"
                  title="Operation Complete"
                  message="Data processing finished successfully"
                  onClose={() => setShowAlert(false)}
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Comparison Section */}
      <section id="comparison" className="py-20">
        <div className="max-w-7xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl font-bold text-white mb-4">Design Comparison</h2>
            <p className="text-gray-300 max-w-2xl mx-auto">
              Сравнение различных дизайн-подходов для разных сценариев использования
            </p>
          </motion.div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Neumorphism Example */}
            <div className="space-y-6">
              <h3 className="text-2xl font-bold text-white mb-6">Neumorphism - Clean & Modern</h3>
              
              <NeumorphismCard className="neumorphism-float">
                <div className="text-center">
                  <BarChart3 className="w-16 h-16 text-blue-600 mx-auto mb-4" />
                  <h4 className="text-xl font-bold text-gray-800 mb-2">Analytics Dashboard</h4>
                  <p className="text-gray-600 mb-4">
                    Идеально подходит для корпоративных приложений и финансовых дашбордов
                  </p>
                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">Простота:</span>
                      <span className="text-green-600">★★★★★</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">Современность:</span>
                      <span className="text-green-600">★★★★☆</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">Внимание:</span>
                      <span className="text-yellow-600">★★★☆☆</span>
                    </div>
                  </div>
                </div>
              </NeumorphismCard>
            </div>

            {/* Cyberpunk Example */}
            <div className="space-y-6">
              <h3 className="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-pink-400 to-cyan-400 mb-6">
                Cyberpunk - Futuristic & Bold
              </h3>
              
              <CyberpunkCard variant="primary" glow glitch>
                <div className="text-center">
                  <Network className="w-16 h-16 text-pink-400 mx-auto mb-4" />
                  <h4 className="text-xl font-bold text-white mb-2">Network Monitor</h4>
                  <p className="text-gray-300 mb-4">
                    Отлично подходит для технических мониторингов и крипто-приложений
                  </p>
                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-300">Простота:</span>
                      <span className="text-yellow-400">★★★☆☆</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-300">Современность:</span>
                      <span className="text-pink-400">★★★★★</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-300">Внимание:</span>
                      <span className="text-cyan-400">★★★★★</span>
                    </div>
                  </div>
                </div>
              </CyberpunkCard>
            </div>
          </div>

          {/* Usage Recommendations */}
          <div className="mt-16">
            <h3 className="text-2xl font-bold text-white mb-8 text-center">Рекомендации по использованию</h3>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div className="text-center">
                <div className="w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Settings className="w-8 h-8 text-white" />
                </div>
                <h4 className="text-xl font-bold text-white mb-2">Neumorphism</h4>
                <p className="text-gray-300">
                  Используйте для корпоративных дашбордов, финансовых приложений и B2B решений
                </p>
              </div>
              
              <div className="text-center">
                <div className="w-16 h-16 bg-gradient-to-r from-pink-500 to-cyan-500 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Zap className="w-8 h-8 text-white" />
                </div>
                <h4 className="text-xl font-bold text-white mb-2">Cyberpunk</h4>
                <p className="text-gray-300">
                  Идеально для крипто-приложений, технических мониторингов и геймификации
                </p>
              </div>
              
              <div className="text-center">
                <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-blue-500 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Eye className="w-8 h-8 text-white" />
                </div>
                <h4 className="text-xl font-bold text-white mb-2">Гибридный подход</h4>
                <p className="text-gray-300">
                  Комбинируйте стили для создания уникального пользовательского опыта
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 border-t border-gray-800">
        <div className="max-w-7xl mx-auto px-6 text-center">
          <p className="text-gray-400">
            DeFiMon Design Systems - Современные решения для финансовых приложений
          </p>
        </div>
      </footer>
    </div>
  )
}
