'use client'

import { useState, useEffect } from 'react'
import { 
  CheckCircleIcon, 
  XCircleIcon, 
  ExclamationTriangleIcon,
  ClockIcon,
  ArrowPathIcon,
  InformationCircleIcon
} from '@heroicons/react/24/outline'

interface APIStatus {
  name: string
  status: 'online' | 'offline' | 'error' | 'loading'
  lastCheck: string
  responseTime: number
  data?: any
  error?: string
  endpoint: string
  apiKey?: string
  description: string
  category: string
}

interface APICategory {
  name: string
  apis: APIStatus[]
}

export default function APIDashboard() {
  const [apiStatuses, setApiStatuses] = useState<APICategory[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [lastUpdate, setLastUpdate] = useState<string>('')
  const [autoRefresh, setAutoRefresh] = useState(true)

  const apiConfigs = [
    {
      name: 'QuickNode',
      endpoint: '/api/external-apis/quicknode/block-number',
      description: 'Ethereum RPC provider for blockchain data',
      category: 'Blockchain RPC',
      apiKey: 'QN_6a9c24b3a5fc491f88e8c24c3294ef36'
    },
    {
      name: 'Blast (Alchemy)',
      endpoint: '/api/external-apis/blast/block-number',
      description: 'Blast API using Alchemy as provider',
      category: 'Blockchain RPC',
      apiKey: 'ALCHEMY_API_KEY'
    },
    {
      name: 'CoinGecko',
      endpoint: '/api/external-apis/coingecko/bitcoin-price',
      description: 'Cryptocurrency price and market data',
      category: 'Crypto Data',
      apiKey: 'CG-32UZHngR3w1V7u2vQ76tP3Fi'
    },
    {
      name: 'CoinCap',
      endpoint: '/api/external-apis/coincap/assets',
      description: 'Alternative cryptocurrency data provider',
      category: 'Crypto Data',
      apiKey: 'dbdbfe12346bb92d9dac28504e5fee49ee721659429345b8a8fd8da5bab9c715'
    },
    {
      name: 'GitHub',
      endpoint: '/api/external-apis/github/user',
      description: 'GitHub repositories and user data',
      category: 'Development',
      apiKey: 'GITHUB_TOKEN'
    },
    {
      name: 'DeFiLlama',
      endpoint: '/api/external-apis/defillama/protocols',
      description: 'DeFi TVL and protocol data',
      category: 'DeFi Analytics',
      apiKey: 'DEFILLAMA_API_KEY'
    },
    {
      name: 'The Graph',
      endpoint: '/api/external-apis/thegraph/uniswap',
      description: 'Subgraph data for DeFi protocols',
      category: 'DeFi Analytics',
      apiKey: 'THE_GRAPH_API_KEY'
    },
    {
      name: 'Etherscan',
      endpoint: '/api/external-apis/etherscan/transactions',
      description: 'Ethereum transaction and contract data',
      category: 'Blockchain Explorer',
      apiKey: 'ETHERSCAN_API_KEY'
    },
    {
      name: 'Arbiscan',
      endpoint: '/api/external-apis/arbiscan/transactions',
      description: 'Arbitrum transaction and contract data',
      category: 'Blockchain Explorer',
      apiKey: 'ARBISCAN_API_KEY'
    },
    {
      name: 'Polygonscan',
      endpoint: '/api/external-apis/polygonscan/transactions',
      description: 'Polygon transaction and contract data',
      category: 'Blockchain Explorer',
      apiKey: 'POLYGONSCAN_API_KEY'
    }
  ]

  const checkAPIStatus = async (config: any): Promise<APIStatus> => {
    const startTime = Date.now()
    
    try {
      const response = await fetch(`http://localhost:8002${config.endpoint}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        signal: AbortSignal.timeout(10000) // 10 second timeout
      })

      const responseTime = Date.now() - startTime
      const data = await response.json()

      return {
        name: config.name,
        status: response.ok ? 'online' : 'error',
        lastCheck: new Date().toISOString(),
        responseTime,
        data: response.ok ? data : undefined,
        error: response.ok ? undefined : data.error || 'Unknown error',
        endpoint: config.endpoint,
        apiKey: config.apiKey,
        description: config.description,
        category: config.category
      }
    } catch (error: any) {
      const responseTime = Date.now() - startTime
      return {
        name: config.name,
        status: 'offline',
        lastCheck: new Date().toISOString(),
        responseTime,
        error: error.message || 'Connection failed',
        endpoint: config.endpoint,
        apiKey: config.apiKey,
        description: config.description,
        category: config.category
      }
    }
  }

  const fetchAllAPIStatuses = async () => {
    setIsLoading(true)
    
    try {
      const promises = apiConfigs.map(config => checkAPIStatus(config))
      const results = await Promise.all(promises)
      
      // Group by category
      const grouped = results.reduce((acc, api) => {
        const category = acc.find(cat => cat.name === api.category)
        if (category) {
          category.apis.push(api)
        } else {
          acc.push({ name: api.category, apis: [api] })
        }
        return acc
      }, [] as APICategory[])
      
      setApiStatuses(grouped)
      setLastUpdate(new Date().toISOString())
    } catch (error) {
      console.error('Error fetching API statuses:', error)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchAllAPIStatuses()
    
    if (autoRefresh) {
      const interval = setInterval(fetchAllAPIStatuses, 30000) // Refresh every 30 seconds
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

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'online':
        return 'bg-green-100 text-green-800 border-green-200'
      case 'offline':
        return 'bg-red-100 text-red-800 border-red-200'
      case 'error':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200'
      case 'loading':
        return 'bg-blue-100 text-blue-800 border-blue-200'
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200'
    }
  }

  const formatResponseTime = (time: number) => {
    if (time < 1000) return `${time}ms`
    return `${(time / 1000).toFixed(2)}s`
  }

  const formatData = (data: any) => {
    if (!data) return null
    
    if (data.success && data.block_number) {
      return (
        <div className="text-sm">
          <div>Block: {data.block_number.toLocaleString()}</div>
          {data.gas_price_gwei && <div>Gas: {data.gas_price_gwei.toFixed(2)} Gwei</div>}
        </div>
      )
    }
    
    if (data.success && data.data?.bitcoin) {
      const btc = data.data.bitcoin
      return (
        <div className="text-sm">
          <div>BTC: ${btc.usd?.toLocaleString()}</div>
          <div>24h: {btc.usd_24h_change?.toFixed(2)}%</div>
        </div>
      )
    }
    
    return <div className="text-sm text-gray-600">Data available</div>
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">API Dashboard</h1>
              <p className="mt-2 text-gray-600">
                Real-time monitoring of all external APIs and their status
              </p>
              <div className="mt-4">
                <a 
                  href="/enhanced-api-dashboard" 
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700"
                >
                  🚀 View Enhanced Dashboard (23+ Networks)
                </a>
              </div>
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
                onClick={fetchAllAPIStatuses}
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
          {['online', 'offline', 'error', 'loading'].map((status) => {
            const count = apiStatuses
              .flatMap(cat => cat.apis)
              .filter(api => api.status === status).length
            
            return (
              <div key={status} className="bg-white rounded-lg shadow p-6">
                <div className="flex items-center">
                  {getStatusIcon(status)}
                  <div className="ml-3">
                    <p className="text-sm font-medium text-gray-500 capitalize">{status}</p>
                    <p className="text-2xl font-semibold text-gray-900">{count}</p>
                  </div>
                </div>
              </div>
            )
          })}
        </div>

        {/* API Categories */}
        {isLoading ? (
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          </div>
        ) : (
          <div className="space-y-8">
            {apiStatuses.map((category) => (
              <div key={category.name} className="bg-white rounded-lg shadow">
                <div className="px-6 py-4 border-b border-gray-200">
                  <h2 className="text-lg font-semibold text-gray-900">{category.name}</h2>
                  <p className="text-sm text-gray-600">
                    {category.apis.length} API{category.apis.length !== 1 ? 's' : ''}
                  </p>
                </div>
                
                <div className="divide-y divide-gray-200">
                  {category.apis.map((api) => (
                    <div key={api.name} className="p-6">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                                                     <div className="flex items-center space-x-3">
                             {getStatusIcon(api.status)}
                             <div>
                               <h3 className="text-lg font-medium text-gray-900">
                                 <a 
                                   href={`/api-dashboard/${encodeURIComponent(api.name)}`}
                                   className="hover:text-blue-600 transition-colors"
                                 >
                                   {api.name}
                                 </a>
                               </h3>
                               <p className="text-sm text-gray-600">{api.description}</p>
                             </div>
                           </div>
                          
                          <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                              <p className="text-sm font-medium text-gray-500">Endpoint</p>
                              <p className="text-sm text-gray-900 font-mono">{api.endpoint}</p>
                            </div>
                            
                            <div>
                              <p className="text-sm font-medium text-gray-500">API Key</p>
                              <p className="text-sm text-gray-900 font-mono">
                                {api.apiKey ? `${api.apiKey.substring(0, 8)}...` : 'Not configured'}
                              </p>
                            </div>
                            
                            <div>
                              <p className="text-sm font-medium text-gray-500">Response Time</p>
                              <p className="text-sm text-gray-900">{formatResponseTime(api.responseTime)}</p>
                            </div>
                            
                            <div>
                              <p className="text-sm font-medium text-gray-500">Last Check</p>
                              <p className="text-sm text-gray-900">
                                {new Date(api.lastCheck).toLocaleTimeString()}
                              </p>
                            </div>
                          </div>
                          
                          {api.error && (
                            <div className="mt-4">
                              <p className="text-sm font-medium text-gray-500">Error</p>
                              <p className="text-sm text-red-600">{api.error}</p>
                            </div>
                          )}
                          
                          {api.data && (
                            <div className="mt-4">
                              <p className="text-sm font-medium text-gray-500">Latest Data</p>
                              <div className="mt-2 p-3 bg-gray-50 rounded-md">
                                {formatData(api.data)}
                              </div>
                            </div>
                          )}
                        </div>
                        
                        <div className="ml-4">
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${getStatusColor(api.status)}`}>
                            {api.status}
                          </span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
