'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { ArrowLeftIcon, ArrowPathIcon } from '@heroicons/react/24/outline'
import APIDetailCard from '../../../components/APIDetailCard'

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

export default function APIDetailPage() {
  const params = useParams()
  const router = useRouter()
  const [apiStatus, setApiStatus] = useState<APIStatus | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [lastUpdate, setLastUpdate] = useState<string>('')

  const apiName = decodeURIComponent(params.api as string)
  const apiConfig = apiConfigs.find(config => config.name === apiName)

  const checkAPIStatus = async (config: any): Promise<APIStatus> => {
    const startTime = Date.now()
    
    try {
      const response = await fetch(`http://localhost:8002${config.endpoint}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        signal: AbortSignal.timeout(10000)
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

  const fetchAPIStatus = async () => {
    if (!apiConfig) return
    
    setIsLoading(true)
    try {
      const status = await checkAPIStatus(apiConfig)
      setApiStatus(status)
      setLastUpdate(new Date().toISOString())
    } catch (error) {
      console.error('Error fetching API status:', error)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    if (apiConfig) {
      fetchAPIStatus()
    }
  }, [apiConfig])

  if (!apiConfig) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">API Not Found</h1>
          <p className="text-gray-600 mb-6">The requested API could not be found.</p>
          <button
            onClick={() => router.push('/api-dashboard')}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
          >
            <ArrowLeftIcon className="h-4 w-4 mr-2" />
            Back to Dashboard
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => router.push('/api-dashboard')}
                className="inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                <ArrowLeftIcon className="h-4 w-4 mr-2" />
                Back
              </button>
              <div>
                <h1 className="text-3xl font-bold text-gray-900">{apiConfig.name}</h1>
                <p className="mt-2 text-gray-600">{apiConfig.description}</p>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              {lastUpdate && (
                <div className="text-sm text-gray-500">
                  Last updated: {new Date(lastUpdate).toLocaleString()}
                </div>
              )}
              <button
                onClick={fetchAPIStatus}
                disabled={isLoading}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
              >
                <ArrowPathIcon className={`h-4 w-4 mr-2 ${isLoading ? 'animate-spin' : ''}`} />
                Refresh
              </button>
            </div>
          </div>
        </div>

        {/* API Detail Card */}
        {isLoading ? (
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          </div>
        ) : apiStatus ? (
          <APIDetailCard api={apiStatus} />
        ) : (
          <div className="text-center py-12">
            <p className="text-gray-600">Failed to load API status</p>
          </div>
        )}

        {/* Additional Information */}
        <div className="mt-8 bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">API Information</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-2">Category</h3>
              <p className="text-sm text-gray-900">{apiConfig.category}</p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-2">Endpoint</h3>
              <p className="text-sm text-gray-900 font-mono break-all">{apiConfig.endpoint}</p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-2">API Key Status</h3>
              <p className="text-sm text-gray-900">
                {apiConfig.apiKey ? 'Configured' : 'Not configured'}
              </p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-2">Base URL</h3>
              <p className="text-sm text-gray-900 font-mono">http://localhost:8002</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
