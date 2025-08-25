'use client'

import { useState, useEffect } from 'react'
import axios from 'axios'

interface Coin {
  id: string
  symbol: string
  name: string
  image: string
  current_price: number
  market_cap: number
  market_cap_rank: number
  price_change_percentage_24h: number
  total_volume: number
}

interface TopCoinsWidgetProps {
  limit?: number
}

export default function TopCoinsWidget({ limit = 10 }: TopCoinsWidgetProps) {
  const [coins, setCoins] = useState<Coin[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const fetchTopCoins = async () => {
    try {
      setLoading(true)
      setError('')
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8002'
      const response = await axios.get(`${apiUrl}/api/external-apis/coingecko/top-coins?limit=${limit}`)
      
      if (response.data.success) {
        setCoins(response.data.data)
      } else {
        setError('Failed to fetch data')
      }
    } catch (error) {
      console.error('Error fetching top coins:', error)
      setError('Error fetching data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchTopCoins()
  }, [limit])

  const formatCurrency = (num: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 2
    }).format(num)
  }

  const formatMarketCap = (num: number) => {
    if (num >= 1e12) {
      return `$${(num / 1e12).toFixed(2)}T`
    } else if (num >= 1e9) {
      return `$${(num / 1e9).toFixed(2)}B`
    } else if (num >= 1e6) {
      return `$${(num / 1e6).toFixed(2)}M`
    } else {
      return formatCurrency(num)
    }
  }

  const formatVolume = (num: number) => {
    if (num >= 1e9) {
      return `$${(num / 1e9).toFixed(2)}B`
    } else if (num >= 1e6) {
      return `$${(num / 1e6).toFixed(2)}M`
    } else {
      return formatCurrency(num)
    }
  }

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium text-gray-900">Top Cryptocurrencies</h3>
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
        </div>
        <div className="space-y-3">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="animate-pulse">
              <div className="h-12 bg-gray-200 rounded"></div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium text-gray-900">Top Cryptocurrencies</h3>
          <button
            onClick={fetchTopCoins}
            className="text-sm text-blue-600 hover:text-blue-800"
          >
            Retry
          </button>
        </div>
        <p className="text-red-600">{error}</p>
      </div>
    )
  }

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-lg font-medium text-gray-900">Top Cryptocurrencies</h3>
        <button
          onClick={fetchTopCoins}
          className="text-sm text-blue-600 hover:text-blue-800"
        >
          Refresh
        </button>
      </div>
      
      <div className="space-y-3">
        {coins.map((coin) => (
          <div key={coin.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <div className="flex items-center space-x-3">
              <div className="flex items-center space-x-2">
                <span className="text-sm font-medium text-gray-500">#{coin.market_cap_rank}</span>
                <img 
                  src={coin.image} 
                  alt={coin.name}
                  className="w-8 h-8 rounded-full"
                />
              </div>
              <div>
                <p className="font-medium text-gray-900">{coin.name}</p>
                <p className="text-sm text-gray-500 uppercase">{coin.symbol}</p>
              </div>
            </div>
            
            <div className="text-right">
              <p className="font-medium text-gray-900">{formatCurrency(coin.current_price)}</p>
              <p className={`text-sm ${
                coin.price_change_percentage_24h >= 0 ? 'text-green-600' : 'text-red-600'
              }`}>
                {coin.price_change_percentage_24h >= 0 ? '+' : ''}
                {coin.price_change_percentage_24h.toFixed(2)}%
              </p>
            </div>
            
            <div className="text-right hidden md:block">
              <p className="text-sm text-gray-500">Market Cap</p>
              <p className="font-medium text-gray-900">{formatMarketCap(coin.market_cap)}</p>
            </div>
            
            <div className="text-right hidden lg:block">
              <p className="text-sm text-gray-500">Volume</p>
              <p className="font-medium text-gray-900">{formatVolume(coin.total_volume)}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
