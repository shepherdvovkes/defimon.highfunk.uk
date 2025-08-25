'use client'

import { useState, useEffect } from 'react'
import { XMarkIcon } from '@heroicons/react/24/outline'
import axios from 'axios'

interface L2Network {
  id: string
  name: string
  chain_id: number
  network_type: string
  rpc_url?: string
  explorer_url?: string
  native_currency?: string
  block_time?: number
  is_active: boolean
  metadata?: any
}

interface NetworkModalProps {
  isOpen: boolean
  onClose: () => void
  network?: L2Network | null
  onSave: () => void
}

export default function NetworkModal({ isOpen, onClose, network, onSave }: NetworkModalProps) {
  const [formData, setFormData] = useState({
    name: '',
    chain_id: '',
    network_type: 'L2',
    rpc_url: '',
    explorer_url: '',
    native_currency: '',
    block_time: '',
    is_active: true
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (network) {
      setFormData({
        name: network.name,
        chain_id: network.chain_id.toString(),
        network_type: network.network_type,
        rpc_url: network.rpc_url || '',
        explorer_url: network.explorer_url || '',
        native_currency: network.native_currency || '',
        block_time: network.block_time?.toString() || '',
        is_active: network.is_active
      })
    } else {
      setFormData({
        name: '',
        chain_id: '',
        network_type: 'L2',
        rpc_url: '',
        explorer_url: '',
        native_currency: '',
        block_time: '',
        is_active: true
      })
    }
    setError('')
  }, [network])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.name || !formData.chain_id) {
      setError('Name and Chain ID are required')
      return
    }

    try {
      setLoading(true)
      setError('')
      
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080'
      const payload = {
        ...formData,
        chain_id: parseInt(formData.chain_id),
        block_time: formData.block_time ? parseInt(formData.block_time) : undefined
      }

      if (network) {
        // Update existing network
        await axios.put(`${apiUrl}/api/l2-networks/${network.id}`, payload)
      } else {
        // Create new network
        await axios.post(`${apiUrl}/api/l2-networks`, payload)
      }

      onSave()
      onClose()
    } catch (error: any) {
      console.error('Error saving network:', error)
      setError(error.response?.data?.error || 'Error saving network')
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? (e.target as HTMLInputElement).checked : value
    }))
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div className="mt-3">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-medium text-gray-900">
              {network ? 'Edit Network' : 'Add New Network'}
            </h3>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600"
              aria-label="Close modal"
            >
              <XMarkIcon className="h-6 w-6" />
            </button>
          </div>

          {error && (
            <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Network Name *
              </label>
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Chain ID *
              </label>
              <input
                type="number"
                name="chain_id"
                value={formData.chain_id}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Network Type
              </label>
              <select
                name="network_type"
                value={formData.network_type}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                aria-label="Network Type"
              >
                <option value="L1">L1 (Layer 1)</option>
                <option value="L2">L2 (Layer 2)</option>
                <option value="L3">L3 (Layer 3)</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                RPC URL
              </label>
              <input
                type="url"
                name="rpc_url"
                value={formData.rpc_url}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="https://..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Explorer URL
              </label>
              <input
                type="url"
                name="explorer_url"
                value={formData.explorer_url}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="https://..."
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Native Currency
                </label>
                <input
                  type="text"
                  name="native_currency"
                  value={formData.native_currency}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="ETH"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Block Time (seconds)
                </label>
                <input
                  type="number"
                  name="block_time"
                  value={formData.block_time}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="12"
                />
              </div>
            </div>

            <div className="flex items-center">
              <input
                type="checkbox"
                name="is_active"
                checked={formData.is_active}
                onChange={handleInputChange}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                aria-label="Active Network"
              />
              <label className="ml-2 block text-sm text-gray-900">
                Active Network
              </label>
            </div>

            <div className="flex justify-end space-x-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
                aria-label="Cancel"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700 disabled:opacity-50"
                aria-label={loading ? 'Saving...' : (network ? 'Update' : 'Create')}
              >
                {loading ? 'Saving...' : (network ? 'Update' : 'Create')}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
