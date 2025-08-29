'use client'

import { useState, useEffect } from 'react'
import axios from 'axios'

interface PolygonData {
  network: string
  chain_id: number
  latest_block: {
    number: number
    timestamp: number
    gas_used: number
    transactions_count: number
  }
  statistics: {
    total_blocks: number
    total_transactions: number
    avg_gas_price: number
    max_gas_price: number
    min_gas_price: number
  }
  recent_transactions: Array<{
    hash: string
    from: string
    to: string
    value: string
    gas_used: number
    gas_price: string
  }>
  timestamp: string
  error?: string
}

export default function PolygonDashboard() {
  const [polygonData, setPolygonData] = useState<PolygonData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchPolygonData()
    const interval = setInterval(fetchPolygonData, 30000) // Update every 30 seconds
    return () => clearInterval(interval)
  }, [])

  const fetchPolygonData = async () => {
    try {
      setLoading(true)
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8002'
      const response = await axios.get(`${apiUrl}/api/polygon/data`)
      setPolygonData(response.data)
      setError(null)
    } catch (err) {
      setError('Failed to fetch Polygon data')
      console.error('Error fetching Polygon data:', err)
    } finally {
      setLoading(false)
    }
  }

  const formatNumber = (num: number) => {
    return new Intl.NumberFormat('en-US').format(num)
  }

  const formatGasPrice = (price: number) => {
    return `${(price / 1e9).toFixed(2)} Gwei`
  }

  const formatValue = (value: string) => {
    const ethValue = parseFloat(value) / 1e18
    return `${ethValue.toFixed(4)} MATIC`
  }

  const formatTimestamp = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleString()
  }

  const shortenAddress = (address: string) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`
  }

  const shortenHash = (hash: string) => {
    return `${hash.slice(0, 10)}...${hash.slice(-8)}`
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-purple-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading Polygon Data...</p>
        </div>
      </div>
    )
  }

  if (error || polygonData?.error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-600 text-6xl mb-4">⚠️</div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Error</h2>
          <p className="text-gray-600 mb-4">{error || polygonData?.error}</p>
          <button 
            onClick={fetchPolygonData}
            className="bg-purple-600 text-white px-4 py-2 rounded hover:bg-purple-700"
          >
            Retry
          </button>
        </div>
      </div>
    )
  }

  if (!polygonData) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="text-gray-600 text-6xl mb-4">❌</div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">No Data</h2>
          <p className="text-gray-600 mb-4">No Polygon data available</p>
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
              <h1 className="text-3xl font-bold text-purple-900">Polygon Network Dashboard</h1>
              <p className="text-gray-600">Real-time Polygon blockchain data from your database</p>
            </div>
            <div className="text-right">
              <p className="text-sm text-gray-500">Last updated</p>
              <p className="text-sm font-medium text-gray-900">
                {polygonData.timestamp ? new Date(polygonData.timestamp).toLocaleString() : 'N/A'}
              </p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Network Overview */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                  <span className="text-purple-600 font-bold">P</span>
                </div>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Latest Block</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(polygonData.latest_block.number)}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                  <span className="text-green-600 font-bold">T</span>
                </div>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Total Transactions</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(polygonData.statistics.total_transactions)}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                  <span className="text-blue-600 font-bold">G</span>
                </div>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Avg Gas Price</p>
                <p className="text-2xl font-bold text-gray-900">{formatGasPrice(polygonData.statistics.avg_gas_price)}</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="w-8 h-8 bg-yellow-100 rounded-full flex items-center justify-center">
                  <span className="text-yellow-600 font-bold">B</span>
                </div>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">Total Blocks</p>
                <p className="text-2xl font-bold text-gray-900">{formatNumber(polygonData.statistics.total_blocks)}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Latest Block Details */}
        <div className="bg-white rounded-lg shadow mb-8">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">Latest Block Details</h3>
          </div>
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <p className="text-sm font-medium text-gray-500">Block Number</p>
                <p className="text-lg font-semibold text-gray-900">{formatNumber(polygonData.latest_block.number)}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-500">Timestamp</p>
                <p className="text-lg font-semibold text-gray-900">{formatTimestamp(polygonData.latest_block.timestamp)}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-500">Gas Used</p>
                <p className="text-lg font-semibold text-gray-900">{formatNumber(polygonData.latest_block.gas_used)}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-500">Transactions in Block</p>
                <p className="text-lg font-semibold text-gray-900">{polygonData.latest_block.transactions_count}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-500">Chain ID</p>
                <p className="text-lg font-semibold text-gray-900">{polygonData.chain_id}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-500">Network</p>
                <p className="text-lg font-semibold text-gray-900">{polygonData.network}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Recent Transactions */}
        <div className="bg-white rounded-lg shadow">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">Recent Transactions</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Hash</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">From</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">To</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Value</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Gas Used</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Gas Price</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {polygonData.recent_transactions.map((tx, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-purple-600">
                      {shortenHash(tx.hash)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-900">
                      {shortenAddress(tx.from)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-900">
                      {tx.to ? shortenAddress(tx.to) : 'Contract Creation'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatValue(tx.value)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatNumber(tx.gas_used)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatGasPrice(parseFloat(tx.gas_price))}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  )
}
