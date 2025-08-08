'use client'

import { useState, useEffect } from 'react'
import axios from 'axios'

interface Protocol {
  id: number
  name: string
  display_name: string
  category: string
  chain: string
  tvl?: number
  volume_24h?: number
}

interface MarketOverview {
  total_tvl: number
  top_protocols: Protocol[]
  timestamp: string
}

export default function Home() {
  const [protocols, setProtocols] = useState<Protocol[]>([])
  const [marketOverview, setMarketOverview] = useState<MarketOverview | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'
      
      // Fetch protocols
      const protocolsResponse = await axios.get(`${apiUrl}/api/protocols`)
      setProtocols(protocolsResponse.data.protocols)
      
      // Fetch market overview
      const overviewResponse = await axios.get(`${apiUrl}/api/analytics/overview`)
      setMarketOverview(overviewResponse.data)
      
    } catch (err) {
      setError('Failed to fetch data')
      console.error('Error fetching data:', err)
    } finally {
      setLoading(false)
    }
  }

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      notation: 'compact',
      maximumFractionDigits: 2
    }).format(value)
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading DeFi Analytics...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-600 text-6xl mb-4">⚠️</div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Error</h2>
          <p className="text-gray-600 mb-4">{error}</p>
          <button 
            onClick={fetchData}
            className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
          >
            Retry
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">DeFi Analytics</h1>
              <p className="text-gray-600">Real-time DeFi protocol monitoring and analytics</p>
            </div>
            <div className="text-right">
              <p className="text-sm text-gray-500">Last updated</p>
              <p className="text-sm font-medium text-gray-900">
                {marketOverview?.timestamp ? new Date(marketOverview.timestamp).toLocaleString() : 'N/A'}
              </p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Market Overview */}
        {marketOverview && (
          <div className="bg-white rounded-lg shadow p-6 mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">Market Overview</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="text-center">
                <p className="text-sm font-medium text-gray-500">Total TVL</p>
                <p className="text-3xl font-bold text-green-600">
                  {formatCurrency(marketOverview.total_tvl)}
                </p>
              </div>
              <div className="text-center">
                <p className="text-sm font-medium text-gray-500">Protocols Tracked</p>
                <p className="text-3xl font-bold text-blue-600">{protocols.length}</p>
              </div>
              <div className="text-center">
                <p className="text-sm font-medium text-gray-500">Categories</p>
                <p className="text-3xl font-bold text-purple-600">
                  {new Set(protocols.map(p => p.category)).size}
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Top Protocols */}
        <div className="bg-white rounded-lg shadow p-6 mb-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Top Protocols</h2>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Protocol
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Category
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Chain
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    TVL
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    24h Volume
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {protocols.slice(0, 10).map((protocol) => (
                  <tr key={protocol.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="flex-shrink-0 h-10 w-10">
                          <div className="h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center">
                            <span className="text-sm font-medium text-gray-700">
                              {protocol.display_name?.charAt(0) || protocol.name.charAt(0)}
                            </span>
                          </div>
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">
                            {protocol.display_name || protocol.name}
                          </div>
                          <div className="text-sm text-gray-500">{protocol.name}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800">
                        {protocol.category}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {protocol.chain}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {protocol.tvl ? formatCurrency(protocol.tvl) : 'N/A'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {protocol.volume_24h ? formatCurrency(protocol.volume_24h) : 'N/A'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-2">Protocol Analytics</h3>
            <p className="text-gray-600 mb-4">Detailed metrics and performance analysis</p>
            <button className="w-full bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">
              View Analytics
            </button>
          </div>
          
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-2">Risk Assessment</h3>
            <p className="text-gray-600 mb-4">AI-powered risk scoring and analysis</p>
            <button className="w-full bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700">
              Assess Risk
            </button>
          </div>
          
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-2">Price Predictions</h3>
            <p className="text-gray-600 mb-4">ML-based price forecasting</p>
            <button className="w-full bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700">
              Get Predictions
            </button>
          </div>
          
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-2">Portfolio Tracking</h3>
            <p className="text-gray-600 mb-4">Monitor your DeFi investments</p>
            <button className="w-full bg-purple-600 text-white px-4 py-2 rounded hover:bg-purple-700">
              Track Portfolio
            </button>
          </div>
        </div>
      </main>
    </div>
  )
}
