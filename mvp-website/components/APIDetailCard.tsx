'use client'

import { useState } from 'react'
import { 
  CheckCircleIcon, 
  XCircleIcon, 
  ExclamationTriangleIcon,
  ClockIcon,
  InformationCircleIcon,
  EyeIcon,
  EyeSlashIcon
} from '@heroicons/react/24/outline'

interface APIDetailCardProps {
  api: {
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
}

export default function APIDetailCard({ api }: APIDetailCardProps) {
  const [showApiKey, setShowApiKey] = useState(false)
  const [showRawData, setShowRawData] = useState(false)

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
        <div className="space-y-2">
          <div className="flex justify-between">
            <span className="text-sm font-medium">Block Number:</span>
            <span className="text-sm font-mono">{data.block_number.toLocaleString()}</span>
          </div>
          {data.gas_price_gwei && (
            <div className="flex justify-between">
              <span className="text-sm font-medium">Gas Price:</span>
              <span className="text-sm font-mono">{data.gas_price_gwei.toFixed(2)} Gwei</span>
            </div>
          )}
          {data.provider && (
            <div className="flex justify-between">
              <span className="text-sm font-medium">Provider:</span>
              <span className="text-sm font-mono">{data.provider}</span>
            </div>
          )}
        </div>
      )
    }
    
    if (data.success && data.data?.bitcoin) {
      const btc = data.data.bitcoin
      return (
        <div className="space-y-2">
          <div className="flex justify-between">
            <span className="text-sm font-medium">Price (USD):</span>
            <span className="text-sm font-mono">${btc.usd?.toLocaleString()}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm font-medium">24h Change:</span>
            <span className={`text-sm font-mono ${btc.usd_24h_change >= 0 ? 'text-green-600' : 'text-red-600'}`}>
              {btc.usd_24h_change?.toFixed(2)}%
            </span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm font-medium">Market Cap:</span>
            <span className="text-sm font-mono">${(btc.usd_market_cap / 1e9).toFixed(2)}B</span>
          </div>
        </div>
      )
    }
    
    if (data.success && data.data?.total_tvl) {
      return (
        <div className="space-y-2">
          <div className="flex justify-between">
            <span className="text-sm font-medium">Total TVL:</span>
            <span className="text-sm font-mono">${(data.data.total_tvl / 1e9).toFixed(2)}B</span>
          </div>
          {data.data.protocols && (
            <div>
              <span className="text-sm font-medium">Top Protocols:</span>
              <div className="mt-1 space-y-1">
                {data.data.protocols.slice(0, 3).map((protocol: any, index: number) => (
                  <div key={index} className="flex justify-between text-xs">
                    <span>{protocol.name}:</span>
                    <span className="font-mono">${(protocol.tvl / 1e6).toFixed(1)}M</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )
    }
    
    return <div className="text-sm text-gray-600">Data available</div>
  }

  return (
    <div className="bg-white rounded-lg shadow-lg border border-gray-200 overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            {getStatusIcon(api.status)}
            <div>
              <h3 className="text-lg font-semibold text-gray-900">{api.name}</h3>
              <p className="text-sm text-gray-600">{api.description}</p>
            </div>
          </div>
          <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium border ${getStatusColor(api.status)}`}>
            {api.status}
          </span>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-4">
        {/* Basic Info */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          <div>
            <p className="text-sm font-medium text-gray-500 mb-1">Endpoint</p>
            <p className="text-sm text-gray-900 font-mono break-all">{api.endpoint}</p>
          </div>
          
          <div>
            <p className="text-sm font-medium text-gray-500 mb-1">Category</p>
            <p className="text-sm text-gray-900">{api.category}</p>
          </div>
          
          <div>
            <p className="text-sm font-medium text-gray-500 mb-1">Response Time</p>
            <p className="text-sm text-gray-900 font-mono">{formatResponseTime(api.responseTime)}</p>
          </div>
          
          <div>
            <p className="text-sm font-medium text-gray-500 mb-1">Last Check</p>
            <p className="text-sm text-gray-900">
              {new Date(api.lastCheck).toLocaleString()}
            </p>
          </div>
        </div>

        {/* API Key */}
        {api.apiKey && (
          <div className="mb-6">
            <div className="flex items-center justify-between mb-2">
              <p className="text-sm font-medium text-gray-500">API Key</p>
              <button
                onClick={() => setShowApiKey(!showApiKey)}
                className="flex items-center space-x-1 text-sm text-blue-600 hover:text-blue-800"
              >
                {showApiKey ? (
                  <>
                    <EyeSlashIcon className="h-4 w-4" />
                    <span>Hide</span>
                  </>
                ) : (
                  <>
                    <EyeIcon className="h-4 w-4" />
                    <span>Show</span>
                  </>
                )}
              </button>
            </div>
            <p className="text-sm text-gray-900 font-mono bg-gray-50 p-2 rounded">
              {showApiKey ? api.apiKey : `${api.apiKey.substring(0, 8)}...`}
            </p>
          </div>
        )}

        {/* Error */}
        {api.error && (
          <div className="mb-6">
            <p className="text-sm font-medium text-gray-500 mb-2">Error</p>
            <div className="bg-red-50 border border-red-200 rounded-md p-3">
              <p className="text-sm text-red-800">{api.error}</p>
            </div>
          </div>
        )}

        {/* Data */}
        {api.data && (
          <div>
            <div className="flex items-center justify-between mb-2">
              <p className="text-sm font-medium text-gray-500">Latest Data</p>
              <button
                onClick={() => setShowRawData(!showRawData)}
                className="text-sm text-blue-600 hover:text-blue-800"
              >
                {showRawData ? 'Show Formatted' : 'Show Raw'}
              </button>
            </div>
            
            <div className="bg-gray-50 rounded-md p-3">
              {showRawData ? (
                <pre className="text-xs text-gray-800 overflow-auto">
                  {JSON.stringify(api.data, null, 2)}
                </pre>
              ) : (
                formatData(api.data)
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
