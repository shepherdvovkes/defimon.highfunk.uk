'use client'

import './globals.css'
import { useState, useEffect } from 'react'
import { 
  TrendingUp,
  TrendingDown,
  DollarSign,
  BarChart3,
  Activity,
  Network,
  Shield,
  AlertTriangle,
  CheckCircle,
  Info,
  Eye,
  Settings
} from 'lucide-react'

export default function Home() {
  const [activeTab, setActiveTab] = useState('overview')
  const [realData, setRealData] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  // Load real data from database
  useEffect(() => {
    const loadRealData = async () => {
      try {
        // Add cache busting parameter
        const response = await fetch(`/real_data.json?v=${Date.now()}`)
        if (response.ok) {
          const data = await response.json()
          console.log('Real data loaded:', data)
          setRealData(data)
        } else {
          console.log('Real data not available, using fallback')
        }
      } catch (error) {
        console.log('Error loading real data, using fallback:', error)
      } finally {
        setLoading(false)
      }
    }

    // Add a timeout to prevent infinite loading
    const timeout = setTimeout(() => {
      setLoading(false)
    }, 5000)

    loadRealData()

    return () => clearTimeout(timeout)
  }, [])

  // Sample data (fallback)
  const networkMetrics = [
    { name: 'Ethereum', tvl: 45.2, change: 2.3, status: 'online', nodes: 892, gasPrice: 23.4, tps: 15.2 },
    { name: 'Polygon', tvl: 12.8, change: -1.2, status: 'online', nodes: 156, gasPrice: 12.1, tps: 65.8 },
    { name: 'Arbitrum', tvl: 8.9, change: 5.7, status: 'online', nodes: 234, gasPrice: 0.8, tps: 4.2 },
    { name: 'Optimism', tvl: 6.4, change: 1.8, status: 'degraded', nodes: 89, gasPrice: 1.2, tps: 2.1 },
    { name: 'Base', tvl: 3.2, change: -0.5, status: 'offline', nodes: 45, gasPrice: 0.5, tps: 1.8 },
  ]

  const alerts = [
    { id: 1, type: 'warning', message: 'Gas price spike detected', time: '2 min ago' },
    { id: 2, type: 'info', message: 'New protocol added to monitoring', time: '5 min ago' },
    { id: 3, type: 'success', message: 'Network optimization completed', time: '10 min ago' },
  ]

  const marketMetrics = [
    { name: 'Market Cap', value: '$2.4T', change: '+2.3%', trend: 'up' },
    { name: '24h Volume', value: '$847B', change: '+8.3%', trend: 'up' },
    { name: 'Dominance', value: '42.3%', change: '-1.2%', trend: 'down' },
    { name: 'Fear Index', value: '45', change: '+5', trend: 'neutral' },
  ]

  const protocolMetrics = [
    { name: 'Uniswap V3', tvl: 3.2, volume: 1.8, users: 125000, change: 5.2 },
    { name: 'Aave V3', tvl: 2.8, volume: 0.9, users: 89000, change: 3.1 },
    { name: 'Compound V3', tvl: 1.9, volume: 0.6, users: 67000, change: -1.8 },
    { name: 'Curve Finance', tvl: 1.7, volume: 0.4, users: 45000, change: 2.4 },
  ]

  const riskMetrics = [
    { name: 'Systemic Risk', value: 'Low', score: 23, color: 'success-green' },
    { name: 'Liquidity Risk', value: 'Medium', score: 45, color: 'warning-orange' },
    { name: 'Volatility Risk', value: 'High', score: 78, color: 'danger-red' },
    { name: 'Regulatory Risk', value: 'Low', score: 31, color: 'success-green' },
  ]

  const performanceMetrics = [
    { name: 'APY Average', value: '8.4%', change: '+0.3%', trend: 'up' },
    { name: 'Impermanent Loss', value: '2.1%', change: '-0.5%', trend: 'down' },
    { name: 'Slippage Avg', value: '0.15%', change: '+0.02%', trend: 'up' },
    { name: 'MEV Revenue', value: '$12.4M', change: '+15.2%', trend: 'up' },
  ]

  // Use real data if available, otherwise use sample data
  const displayData = realData || {
    ethereum: {
      total_value_locked: '$2.4B',
      volume_24h: '$847M',
      active_protocols: 1247,
      network_nodes: 892,
      avg_gas_price: '23.4 Gwei',
      block_height: '18,947,392',
      protocols: [
        { name: 'Uniswap V3', tvl: 3.2, volume: 1.8, users: 125000, change: 5.2 },
        { name: 'Aave V3', tvl: 2.8, volume: 0.9, users: 89000, change: 3.1 },
        { name: 'Compound V3', tvl: 1.9, volume: 0.6, users: 67000, change: -1.8 },
        { name: 'Curve Finance', tvl: 1.7, volume: 0.4, users: 45000, change: 2.4 }
      ]
    },
    l2_networks: {
      networks: networkMetrics,
      total_networks: 5,
      total_nodes: 1416,
      avg_gas_price: 7.6,
      total_tvl: 76.5
    }
  }

  if (loading) {
    return (
      <main className="compact-container">
        <div className="flex items-center justify-center h-64">
          <div className="loading-compact"></div>
          <span className="ml-3 text-muted">Loading real data...</span>
        </div>
      </main>
    )
  }

  return (
    <main className="compact-container">
      {/* Header */}
      <header className="nav-compact">
        <div className="flex items-center justify-between w-full">
          <div className="flex items-center space-x-4">
            <h1 className="font-display font-bold text-lg">DeFiMon</h1>
            <span className="text-muted text-xs">Analytics Platform</span>
            {realData && (
              <div className="flex items-center space-x-2">
                <div className="w-2 h-2 rounded-full bg-success-green"></div>
                <span className="text-xs text-success-green">Real Data</span>
              </div>
            )}
          </div>
          <nav className="flex space-x-2">
            <button 
              className={`nav-item ${activeTab === 'overview' ? 'active' : ''}`}
              onClick={() => setActiveTab('overview')}
            >
              Overview
            </button>
            <button 
              className={`nav-item ${activeTab === 'networks' ? 'active' : ''}`}
              onClick={() => setActiveTab('networks')}
            >
              Networks
            </button>
            <button 
              className={`nav-item ${activeTab === 'alerts' ? 'active' : ''}`}
              onClick={() => setActiveTab('alerts')}
            >
              Alerts
            </button>
            <a href="/demo" className="nav-item">Demo</a>
          </nav>
        </div>
      </header>

      {activeTab === 'overview' && (
        <>
          {/* Core KPIs */}
          <div className="dashboard-grid">
            <div className="dashboard-card">
              <h3>Total Value Locked</h3>
              <div className="value">{displayData.ethereum.total_value_locked}</div>
              <div className="text-xs text-success-green mt-2">+12.5%</div>
            </div>
            
            <div className="dashboard-card">
              <h3>24h Volume</h3>
              <div className="value">{displayData.ethereum.volume_24h}</div>
              <div className="text-xs text-success-green mt-2">+8.3%</div>
            </div>
            
            <div className="dashboard-card">
              <h3>Active Protocols</h3>
              <div className="value">{displayData.ethereum.active_protocols.toLocaleString()}</div>
              <div className="text-xs text-accent-blue mt-2">+23</div>
            </div>
            
            <div className="dashboard-card">
              <h3>Network Nodes</h3>
              <div className="value">{displayData.ethereum.network_nodes.toLocaleString()}</div>
              <div className="text-xs status-online mt-2">Online</div>
            </div>
            
            <div className="dashboard-card">
              <h3>Avg Gas Price</h3>
              <div className="value">{displayData.ethereum.avg_gas_price}</div>
              <div className="text-xs text-warning-orange mt-2">High</div>
            </div>
            
            <div className="dashboard-card">
              <h3>Block Height</h3>
              <div className="value">{displayData.ethereum.block_height}</div>
              <div className="text-xs text-muted mt-2">Latest</div>
            </div>
          </div>

          {/* Market Metrics */}
          <div className="financial-card">
            <h3 className="metric-label">Market Overview</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-4">
              {marketMetrics.map((metric, index) => (
                <div key={index} className="text-center p-3 bg-surface-dark rounded border border-border-dark">
                  <div className="text-xs text-muted mb-1">{metric.name}</div>
                  <div className="font-mono font-semibold text-lg">{metric.value}</div>
                  <div className={`text-xs ${
                    metric.trend === 'up' ? 'text-success-green' : 
                    metric.trend === 'down' ? 'text-danger-red' : 'text-muted'
                  }`}>
                    {metric.change}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Protocol Performance */}
          <div className="financial-card">
            <h3 className="metric-label">Top Protocols</h3>
            <div className="space-y-3 mt-4">
              {displayData.ethereum.protocols.map((protocol: any, index: number) => (
                <div key={index} className="flex items-center justify-between p-3 bg-surface-dark rounded border border-border-dark">
                  <div className="flex items-center space-x-3">
                    <div className="w-2 h-2 rounded-full bg-accent-blue"></div>
                    <div>
                      <div className="font-mono font-semibold">{protocol.name}</div>
                      <div className="text-xs text-muted">{protocol.users.toLocaleString()} users</div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="font-mono font-semibold">${protocol.tvl}B TVL</div>
                    <div className={`text-xs ${
                      protocol.change >= 0 ? 'text-success-green' : 'text-danger-red'
                    }`}>
                      {protocol.change >= 0 ? '+' : ''}{protocol.change}%
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Risk Assessment */}
          <div className="financial-card">
            <h3 className="metric-label">Risk Assessment</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-4">
              {riskMetrics.map((risk, index) => (
                <div key={index} className="text-center p-3 bg-surface-dark rounded border border-border-dark">
                  <div className="text-xs text-muted mb-1">{risk.name}</div>
                  <div className={`font-mono font-semibold text-lg ${risk.color}`}>{risk.value}</div>
                  <div className="text-xs text-muted">Score: {risk.score}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Performance Metrics */}
          <div className="financial-card">
            <h3 className="metric-label">Performance Metrics</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-4">
              {performanceMetrics.map((metric, index) => (
                <div key={index} className="text-center p-3 bg-surface-dark rounded border border-border-dark">
                  <div className="text-xs text-muted mb-1">{metric.name}</div>
                  <div className="font-mono font-semibold text-lg">{metric.value}</div>
                  <div className={`text-xs ${
                    metric.trend === 'up' ? 'text-success-green' : 
                    metric.trend === 'down' ? 'text-danger-red' : 'text-muted'
                  }`}>
                    {metric.change}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Quick Actions */}
          <div className="compact-grid">
            <div className="financial-card">
              <h3 className="metric-label">Network Status</h3>
              <div className="flex items-center space-x-4">
                <div className="status-online">●</div>
                <span className="text-sm">All systems operational</span>
              </div>
            </div>
            
            <div className="financial-card">
              <h3 className="metric-label">Recent Alerts</h3>
              <div className="space-y-2">
                <div className="alert-compact alert-info">Gas price spike detected</div>
                <div className="alert-compact alert-success">New protocol added</div>
              </div>
            </div>
          </div>
        </>
      )}

      {activeTab === 'networks' && (
        <div className="space-y-4">
          {/* Network Overview */}
          <div className="financial-card">
            <h3 className="metric-label">Network Overview</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-4">
              <div className="text-center p-3 bg-surface-dark rounded border border-border-dark">
                <div className="text-xs text-muted mb-1">Total Networks</div>
                <div className="font-mono font-semibold text-lg">{displayData.l2_networks.total_networks}</div>
                <div className="text-xs text-muted">Active</div>
              </div>
              <div className="text-center p-3 bg-surface-dark rounded border border-border-dark">
                <div className="text-xs text-muted mb-1">Total Nodes</div>
                <div className="font-mono font-semibold text-lg">{displayData.l2_networks.total_nodes.toLocaleString()}</div>
                <div className="text-xs text-muted">Online</div>
              </div>
              <div className="text-center p-3 bg-surface-dark rounded border border-border-dark">
                <div className="text-xs text-muted mb-1">Avg Gas Price</div>
                <div className="font-mono font-semibold text-lg">{displayData.l2_networks.avg_gas_price.toFixed(1)} Gwei</div>
                <div className="text-xs text-muted">Across Networks</div>
              </div>
              <div className="text-center p-3 bg-surface-dark rounded border border-border-dark">
                <div className="text-xs text-muted mb-1">Total TVL</div>
                <div className="font-mono font-semibold text-lg">${displayData.l2_networks.total_tvl.toFixed(1)}B</div>
                <div className="text-xs text-muted">Combined</div>
              </div>
            </div>
          </div>

          {/* Network Performance */}
          <div className="financial-card">
            <h3 className="metric-label">Network Performance</h3>
            <div className="space-y-3 max-h-96 overflow-y-auto">
              {displayData.l2_networks.networks.map((network: any, index: number) => (
                <div key={index} className="p-4 bg-surface-dark rounded border border-border-dark">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center space-x-3">
                      <div className={`w-2 h-2 rounded-full ${
                        network.status === 'online' ? 'status-online' :
                        network.status === 'degraded' ? 'status-degraded' : 'status-offline'
                      }`} />
                      <div>
                        <div className="font-mono font-semibold">{network.name}</div>
                        <div className="text-xs text-muted">{network.nodes} nodes</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="font-mono font-semibold">${network.tvl}B</div>
                      <div className={`text-xs ${
                        network.change >= 0 ? 'text-success-green' : 'text-danger-red'
                      }`}>
                        {network.change >= 0 ? '+' : ''}{network.change}%
                      </div>
                    </div>
                  </div>
                  <div className="grid grid-cols-4 gap-4 text-center">
                    <div>
                      <div className="text-xs text-muted mb-1">Gas Price</div>
                      <div className="font-mono font-semibold">{network.gasPrice} Gwei</div>
                    </div>
                    <div>
                      <div className="text-xs text-muted mb-1">TPS</div>
                      <div className="font-mono font-semibold">{network.tps.toLocaleString()}</div>
                    </div>
                    <div>
                      <div className="text-xs text-muted mb-1">Volume 24h</div>
                      <div className="font-mono font-semibold">${network.volume_24h?.toFixed(1) || '0.0'}M</div>
                    </div>
                    <div>
                      <div className="text-xs text-muted mb-1">Status</div>
                      <div className={`text-xs font-semibold ${
                        network.status === 'online' ? 'status-online' :
                        network.status === 'degraded' ? 'status-degraded' : 'status-offline'
                      }`}>
                        {network.status}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Network Categories */}
          <div className="financial-card">
            <h3 className="metric-label">Network Categories</h3>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mt-4">
              <div className="text-center p-3 bg-surface-dark rounded border border-border-dark">
                <div className="text-xs text-muted mb-1">Rollups</div>
                <div className="font-mono font-semibold text-lg">8</div>
                <div className="text-xs text-muted">Optimistic & ZK</div>
              </div>
              <div className="text-center p-3 bg-surface-dark rounded border border-border-dark">
                <div className="text-xs text-muted mb-1">Sidechains</div>
                <div className="font-mono font-semibold text-lg">4</div>
                <div className="text-xs text-muted">Polygon, etc.</div>
              </div>
              <div className="text-center p-3 bg-surface-dark rounded border border-border-dark">
                <div className="text-xs text-muted mb-1">Validiums</div>
                <div className="font-mono font-semibold text-lg">6</div>
                <div className="text-xs text-muted">StarkNet, etc.</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {activeTab === 'alerts' && (
        <div className="space-y-4">
          <div className="financial-card">
            <h3 className="metric-label">Active Alerts</h3>
            <div className="space-y-3">
              {alerts.map((alert) => (
                <div key={alert.id} className="flex items-center justify-between p-3 bg-surface-dark rounded border border-border-dark">
                  <div className="flex items-center space-x-3">
                    <div className={`p-1 rounded ${
                      alert.type === 'warning' ? 'bg-warning-orange/20' :
                      alert.type === 'info' ? 'bg-accent-blue/20' :
                      'bg-success-green/20'
                    }`}>
                      {alert.type === 'warning' ? <AlertTriangle className="w-3 h-3 text-warning-orange" /> :
                       alert.type === 'info' ? <Info className="w-3 h-3 text-accent-blue" /> :
                       <CheckCircle className="w-3 h-3 text-success-green" />}
                    </div>
                    <div>
                      <div className="text-sm">{alert.message}</div>
                      <div className="text-xs text-muted">{alert.time}</div>
                    </div>
                  </div>
                                     <button className="btn-compact" title="View alert details">
                     <Eye className="w-3 h-3" />
                   </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Call to Action */}
      <div className="text-center mt-8">
        <a href="/demo" className="btn-compact primary">
          View Full Demo
        </a>
      </div>
    </main>
  )
}
