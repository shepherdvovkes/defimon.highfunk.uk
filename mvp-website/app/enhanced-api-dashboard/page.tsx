'use client'

import { useState, useEffect } from 'react'
import { 
  CheckCircleIcon, 
  XCircleIcon, 
  ExclamationTriangleIcon,
  ClockIcon,
  ArrowPathIcon,
  InformationCircleIcon,
  FireIcon,
  BoltIcon,
  ChartBarIcon,
  GlobeAltIcon,
  CubeIcon,
  CurrencyDollarIcon
} from '@heroicons/react/24/outline'

interface NetworkStatus {
  network: string
  network_name: string
  chain_id: number
  status: 'online' | 'offline' | 'error' | 'loading'
  block_number?: number
  gas_price_gwei?: number
  currency: string
  priority: number
  tvl_usd?: number
  volume_24h?: number
  features?: string[]
  provider: string
  lastCheck: string
  responseTime: number
  error?: string
}

interface ProviderSummary {
  name: string
  total_networks: number
  working_networks: number
  networks: { [key: string]: NetworkStatus }
  total_tvl: number
  total_volume: number
}

interface EnhancedAPIStatus {
  timestamp: string
  total_networks: number
  providers: {
    quicknode: ProviderSummary
    alchemy: ProviderSummary
  }
  statistics: {
    total_tvl: number
    total_volume_24h: number
  }
}

export default function EnhancedAPIDashboard() {
  const [apiStatus, setApiStatus] = useState<EnhancedAPIStatus | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [lastUpdate, setLastUpdate] = useState<string>('')
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [selectedProvider, setSelectedProvider] = useState<'all' | 'quicknode' | 'alchemy'>('all')
  const [selectedPriority, setSelectedPriority] = useState<'all' | 'high' | 'medium' | 'low'>('all')

  const checkEnhancedAPIStatus = async (): Promise<EnhancedAPIStatus> => {
    const startTime = Date.now()
    
    try {
      const response = await fetch(`http://localhost:8002/enhanced-external-apis/comprehensive-summary`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        signal: AbortSignal.timeout(30000) // 30 second timeout
      })

      const responseTime = Date.now() - startTime
      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.detail || 'Failed to fetch enhanced API status')
      }

      return {
        ...data,
        responseTime
      }
    } catch (error: any) {
      console.error('Error fetching enhanced API status:', error)
      throw error
    }
  }

  const fetchEnhancedAPIStatus = async () => {
    setIsLoading(true)
    
    try {
      const result = await checkEnhancedAPIStatus()
      setApiStatus(result)
      setLastUpdate(new Date().toISOString())
    } catch (error) {
      console.error('Error fetching enhanced API status:', error)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchEnhancedAPIStatus()
    
    if (autoRefresh) {
      const interval = setInterval(fetchEnhancedAPIStatus, 60000) // Refresh every minute
      return () => clearInterval(interval)
    }
  }, [autoRefresh])

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'online':
        return <CheckCircleIcon className="h-5 w-5 text-green-500" />
      case 'offline':
        return <XCircleIcon className="h-5 w-5 text-red-500" />
      case 'error':
        return <ExclamationTriangleIcon className="h-5 w-5 text-yellow-500" />
      case 'loading':
        return <ClockIcon className="h-5 w-5 text-blue-500 animate-spin" />
      default:
        return <InformationCircleIcon className="h-5 w-5 text-gray-500" />
    }
  }

  const getPriorityIcon = (priority: number) => {
    if (priority >= 8) return <FireIcon className="h-4 w-4 text-red-500" />
    if (priority >= 6) return <BoltIcon className="h-4 w-4 text-yellow-500" />
    return <ChartBarIcon className="h-4 w-4 text-blue-500" />
  }

  const getPriorityLabel = (priority: number) => {
    if (priority >= 8) return 'High'
    if (priority >= 6) return 'Medium'
    return 'Low'
  }

  const getPriorityColor = (priority: number) => {
    if (priority >= 8) return 'bg-red-100 text-red-800 border-red-200'
    if (priority >= 6) return 'bg-yellow-100 text-yellow-800 border-yellow-200'
    return 'bg-blue-100 text-blue-800 border-blue-200'
  }

  const formatNumber = (num: number) => {
    if (num >= 1e9) return `$${(num / 1e9).toFixed(2)}B`
    if (num >= 1e6) return `$${(num / 1e6).toFixed(2)}M`
    if (num >= 1e3) return `$${(num / 1e3).toFixed(2)}K`
    return `$${num.toFixed(2)}`
  }

  const formatResponseTime = (time: number) => {
    if (time < 1000) return `${time}ms`
    return `${(time / 1000).toFixed(2)}s`
  }

  const getAllNetworks = (): NetworkStatus[] => {
    if (!apiStatus) return []
    
    const networks: NetworkStatus[] = []
    
    // Add QuickNode networks
    Object.entries(apiStatus.providers.quicknode.networks).forEach(([network, data]) => {
      if (data.success) {
        networks.push({
          network,
          network_name: data.network_name,
          chain_id: data.chain_id,
          status: 'online',
          block_number: data.block_number,
          gas_price_gwei: data.gas_price_gwei,
          currency: data.currency,
          priority: data.priority,
          tvl_usd: data.tvl_usd,
          volume_24h: data.volume_24h,
          provider: 'QuickNode',
          lastCheck: apiStatus.timestamp,
          responseTime: 0
        })
      } else {
        networks.push({
          network,
          network_name: network,
          chain_id: 0,
          status: 'error',
          currency: 'Unknown',
          priority: 0,
          provider: 'QuickNode',
          lastCheck: apiStatus.timestamp,
          responseTime: 0,
          error: data.error
        })
      }
    })
    
    // Add Alchemy networks
    Object.entries(apiStatus.providers.alchemy.networks).forEach(([network, data]) => {
      if (data.success) {
        networks.push({
          network,
          network_name: data.network_name,
          chain_id: data.chain_id,
          status: 'online',
          block_number: data.block_number,
          gas_price_gwei: data.gas_price_gwei,
          currency: data.currency,
          priority: data.priority,
          tvl_usd: data.tvl_usd,
          volume_24h: data.volume_24h,
          features: data.features,
          provider: 'Alchemy',
          lastCheck: apiStatus.timestamp,
          responseTime: 0
        })
      } else {
        networks.push({
          network,
          network_name: network,
          chain_id: 0,
          status: 'error',
          currency: 'Unknown',
          priority: 0,
          provider: 'Alchemy',
          lastCheck: apiStatus.timestamp,
          responseTime: 0,
          error: data.error
        })
      }
    })
    
    return networks
  }

  const getFilteredNetworks = (): NetworkStatus[] => {
    let networks = getAllNetworks()
    
    // Filter by provider
    if (selectedProvider !== 'all') {
      networks = networks.filter(network => network.provider.toLowerCase() === selectedProvider)
    }
    
    // Filter by priority
    if (selectedPriority !== 'all') {
      const priorityMap = { high: 8, medium: 6, low: 0 }
      const minPriority = priorityMap[selectedPriority]
      networks = networks.filter(network => network.priority >= minPriority)
    }
    
    return networks
  }

  const getNetworkCategories = () => {
    const networks = getAllNetworks()
    
    return {
      total: networks.length,
      online: networks.filter(n => n.status === 'online').length,
      error: networks.filter(n => n.status === 'error').length,
      highPriority: networks.filter(n => n.priority >= 8).length,
      mediumPriority: networks.filter(n => n.priority >= 6 && n.priority < 8).length,
      lowPriority: networks.filter(n => n.priority < 6).length,
      quicknode: networks.filter(n => n.provider === 'QuickNode').length,
      alchemy: networks.filter(n => n.provider === 'Alchemy').length
    }
  }

  const categories = getNetworkCategories()
  const filteredNetworks = getFilteredNetworks()

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Enhanced API Dashboard</h1>
              <p className="mt-2 text-gray-600">
                Comprehensive monitoring of 23+ Layer 2 networks across QuickNode and Alchemy
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="autoRefresh"
                  checked={autoRefresh}
                  onChange={(e) => setAutoRefresh(e.target.checked)}
                  className="rounded border-gray-300"
                />
                <label htmlFor="autoRefresh" className="text-sm text-gray-600">
                  Auto refresh
                </label>
              </div>
              <button
                onClick={fetchEnhancedAPIStatus}
                disabled={isLoading}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
              >
                <ArrowPathIcon className={`h-4 w-4 mr-2 ${isLoading ? 'animate-spin' : ''}`} />
                Refresh
              </button>
            </div>
          </div>
          
          {lastUpdate && (
            <div className="mt-4 text-sm text-gray-500">
              Last updated: {new Date(lastUpdate).toLocaleString()}
            </div>
          )}
        </div>

        {/* Summary Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <GlobeAltIcon className="h-8 w-8 text-blue-500" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-500">Total Networks</p>
                <p className="text-2xl font-semibold text-gray-900">{categories.total}</p>
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <CheckCircleIcon className="h-8 w-8 text-green-500" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-500">Online</p>
                <p className="text-2xl font-semibold text-gray-900">{categories.online}</p>
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <CurrencyDollarIcon className="h-8 w-8 text-green-500" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-500">Total TVL</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {apiStatus ? formatNumber(apiStatus.statistics.total_tvl) : 'Loading...'}
                </p>
              </div>
            </div>
          </div>
          
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <ChartBarIcon className="h-8 w-8 text-purple-500" />
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-500">24h Volume</p>
                <p className="text-2xl font-semibold text-gray-900">
                  {apiStatus ? formatNumber(apiStatus.statistics.total_volume_24h) : 'Loading...'}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white rounded-lg shadow p-6 mb-8">
          <div className="flex flex-wrap items-center space-x-6">
            <div>
              <label className="text-sm font-medium text-gray-700">Provider</label>
              <select
                value={selectedProvider}
                onChange={(e) => setSelectedProvider(e.target.value as any)}
                className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
                aria-label="Select provider"
              >
                <option value="all">All Providers</option>
                <option value="quicknode">QuickNode ({categories.quicknode})</option>
                <option value="alchemy">Alchemy ({categories.alchemy})</option>
              </select>
            </div>
            
            <div>
              <label className="text-sm font-medium text-gray-700">Priority</label>
              <select
                value={selectedPriority}
                onChange={(e) => setSelectedPriority(e.target.value as any)}
                className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
                aria-label="Select priority"
              >
                <option value="all">All Priorities</option>
                <option value="high">High Priority ({categories.highPriority})</option>
                <option value="medium">Medium Priority ({categories.mediumPriority})</option>
                <option value="low">Low Priority ({categories.lowPriority})</option>
              </select>
            </div>
          </div>
        </div>

        {/* Networks Grid */}
        {isLoading ? (
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredNetworks.map((network) => (
              <div key={`${network.provider}-${network.network}`} className="bg-white rounded-lg shadow hover:shadow-lg transition-shadow">
                <div className="p-6">
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex items-center space-x-2">
                      {getStatusIcon(network.status)}
                      <div>
                        <h3 className="text-lg font-medium text-gray-900">{network.network_name}</h3>
                        <p className="text-sm text-gray-500">{network.provider}</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      {getPriorityIcon(network.priority)}
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${getPriorityColor(network.priority)}`}>
                        {getPriorityLabel(network.priority)}
                      </span>
                    </div>
                  </div>
                  
                  <div className="space-y-3">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-500">Chain ID:</span>
                      <span className="font-medium">{network.chain_id}</span>
                    </div>
                    
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-500">Currency:</span>
                      <span className="font-medium">{network.currency}</span>
                    </div>
                    
                    {network.block_number && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-500">Block:</span>
                        <span className="font-medium">{network.block_number.toLocaleString()}</span>
                      </div>
                    )}
                    
                    {network.gas_price_gwei && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-500">Gas:</span>
                        <span className="font-medium">{network.gas_price_gwei.toFixed(2)} Gwei</span>
                      </div>
                    )}
                    
                    {network.tvl_usd && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-500">TVL:</span>
                        <span className="font-medium">{formatNumber(network.tvl_usd)}</span>
                      </div>
                    )}
                    
                    {network.volume_24h && (
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-500">24h Vol:</span>
                        <span className="font-medium">{formatNumber(network.volume_24h)}</span>
                      </div>
                    )}
                    
                    {network.features && network.features.length > 0 && (
                      <div className="pt-2 border-t border-gray-200">
                        <p className="text-xs text-gray-500 mb-1">Features:</p>
                        <div className="flex flex-wrap gap-1">
                          {network.features.slice(0, 3).map((feature) => (
                            <span key={feature} className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-blue-100 text-blue-800">
                              {feature}
                            </span>
                          ))}
                          {network.features.length > 3 && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-gray-100 text-gray-800">
                              +{network.features.length - 3}
                            </span>
                          )}
                        </div>
                      </div>
                    )}
                    
                    {network.error && (
                      <div className="pt-2 border-t border-gray-200">
                        <p className="text-xs text-red-600">{network.error}</p>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* No Results */}
        {!isLoading && filteredNetworks.length === 0 && (
          <div className="text-center py-12">
            <CubeIcon className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">No networks found</h3>
            <p className="mt-1 text-sm text-gray-500">
              Try adjusting your filters to see more networks.
            </p>
          </div>
        )}
      </div>
    </div>
  )
}
