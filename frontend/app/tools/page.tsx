'use client'

import { useState, useEffect } from 'react'
import { Tab } from '@headlessui/react'
import { 
  CogIcon, 
  NetworkIcon, 
  ChartBarIcon, 
  CloudIcon,
  ArrowPathIcon,
  PlusIcon,
  PencilIcon,
  TrashIcon
} from '@heroicons/react/24/outline'
import axios from 'axios'
import NetworkModal from './components/NetworkModal'

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
  last_block_number?: number
  last_sync_time?: string
  source: string
  created_at: string
}

interface L2NetworksResponse {
  networks: L2Network[]
  pagination: {
    page: number
    limit: number
    total: number
    pages: number
  }
}

export default function ToolsPage() {
  const [selectedTab, setSelectedTab] = useState(0)
  const [l2Networks, setL2Networks] = useState<L2Network[]>([])
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 20,
    total: 0,
    pages: 0
  })
  const [loading, setLoading] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [showAddModal, setShowAddModal] = useState(false)
  const [editingNetwork, setEditingNetwork] = useState<L2Network | null>(null)

  useEffect(() => {
    if (selectedTab === 0) {
      fetchL2Networks()
    }
  }, [selectedTab, pagination.page, searchTerm])

  const fetchL2Networks = async () => {
    try {
      setLoading(true)
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080'
      const response = await axios.get(`${apiUrl}/api/l2-networks`, {
        params: {
          page: pagination.page,
          limit: pagination.limit,
          search: searchTerm
        }
      })
      
      const data: L2NetworksResponse = response.data
      setL2Networks(data.networks)
      setPagination(data.pagination)
    } catch (error) {
      console.error('Error fetching L2 networks:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSync = async () => {
    try {
      setLoading(true)
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080'
      await axios.post(`${apiUrl}/api/l2-networks/sync`, { force: true })
      await fetchL2Networks()
    } catch (error) {
      console.error('Error syncing networks:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this network?')) return
    
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080'
      await axios.delete(`${apiUrl}/api/l2-networks/${id}`)
      await fetchL2Networks()
    } catch (error) {
      console.error('Error deleting network:', error)
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const tabs = [
    {
      name: 'L2 Networks',
      icon: NetworkIcon,
      description: 'Manage and monitor Layer 2 networks'
    },
    {
      name: 'Analytics Tools',
      icon: ChartBarIcon,
      description: 'Data analysis and reporting tools'
    },
    {
      name: 'Cloud Services',
      icon: CloudIcon,
      description: 'Cloud infrastructure management'
    },
    {
      name: 'System Tools',
      icon: CogIcon,
      description: 'System administration and monitoring'
    }
  ]

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Tools & Utilities</h1>
              <p className="text-gray-600">Manage system tools and network synchronization</p>
            </div>
            <div className="flex space-x-3">
              <button
                onClick={handleSync}
                disabled={loading}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
              >
                <ArrowPathIcon className="h-4 w-4 mr-2" />
                Sync Networks
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <Tab.Group selectedIndex={selectedTab} onChange={setSelectedTab}>
          <Tab.List className="flex space-x-1 rounded-xl bg-blue-900/20 p-1">
            {tabs.map((tab) => (
              <Tab
                key={tab.name}
                className={({ selected }) =>
                  `w-full rounded-lg py-2.5 text-sm font-medium leading-5
                   ring-white ring-opacity-60 ring-offset-2 ring-offset-blue-400 focus:outline-none focus:ring-2
                   ${selected
                     ? 'bg-white shadow text-blue-700'
                     : 'text-blue-100 hover:bg-white/[0.12] hover:text-white'
                   }`
                }
              >
                <div className="flex items-center justify-center space-x-2">
                  <tab.icon className="h-5 w-5" />
                  <span>{tab.name}</span>
                </div>
              </Tab>
            ))}
          </Tab.List>
          
          <Tab.Panels className="mt-8">
            {/* L2 Networks Tab */}
            <Tab.Panel>
              <div className="bg-white rounded-lg shadow">
                <div className="px-6 py-4 border-b border-gray-200">
                  <div className="flex justify-between items-center">
                    <h3 className="text-lg font-medium text-gray-900">L2 Networks</h3>
                    <button
                      onClick={() => setShowAddModal(true)}
                      className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                    >
                      <PlusIcon className="h-4 w-4 mr-2" />
                      Add Network
                    </button>
                  </div>
                  
                  {/* Search */}
                  <div className="mt-4">
                    <input
                      type="text"
                      placeholder="Search networks..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>

                {/* Networks Table */}
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Network
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Chain ID
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Type
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Status
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Last Sync
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Actions
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {loading ? (
                        <tr>
                          <td colSpan={6} className="px-6 py-4 text-center">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
                          </td>
                        </tr>
                      ) : l2Networks.length === 0 ? (
                        <tr>
                          <td colSpan={6} className="px-6 py-4 text-center text-gray-500">
                            No networks found
                          </td>
                        </tr>
                      ) : (
                        l2Networks.map((network) => (
                          <tr key={network.id}>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <div>
                                <div className="text-sm font-medium text-gray-900">{network.name}</div>
                                {network.native_currency && (
                                  <div className="text-sm text-gray-500">{network.native_currency}</div>
                                )}
                              </div>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              {network.chain_id}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              {network.network_type}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                                network.is_active 
                                  ? 'bg-green-100 text-green-800' 
                                  : 'bg-red-100 text-red-800'
                              }`}>
                                {network.is_active ? 'Active' : 'Inactive'}
                              </span>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                              {network.last_sync_time ? formatDate(network.last_sync_time) : 'Never'}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                              <div className="flex space-x-2">
                                <button
                                  onClick={() => setEditingNetwork(network)}
                                  className="text-blue-600 hover:text-blue-900"
                                  aria-label={`Edit ${network.name}`}
                                >
                                  <PencilIcon className="h-4 w-4" />
                                </button>
                                <button
                                  onClick={() => handleDelete(network.id)}
                                  className="text-red-600 hover:text-red-900"
                                  aria-label={`Delete ${network.name}`}
                                >
                                  <TrashIcon className="h-4 w-4" />
                                </button>
                              </div>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>

                {/* Pagination */}
                {pagination.pages > 1 && (
                  <div className="px-6 py-4 border-t border-gray-200">
                    <div className="flex items-center justify-between">
                      <div className="text-sm text-gray-700">
                        Showing {((pagination.page - 1) * pagination.limit) + 1} to{' '}
                        {Math.min(pagination.page * pagination.limit, pagination.total)} of{' '}
                        {pagination.total} results
                      </div>
                      <div className="flex space-x-2">
                        <button
                          onClick={() => setPagination(prev => ({ ...prev, page: prev.page - 1 }))}
                          disabled={pagination.page === 1}
                          className="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
                        >
                          Previous
                        </button>
                        <button
                          onClick={() => setPagination(prev => ({ ...prev, page: prev.page + 1 }))}
                          disabled={pagination.page === pagination.pages}
                          className="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
                        >
                          Next
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </Tab.Panel>

            {/* Other tabs */}
            <Tab.Panel>
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Analytics Tools</h3>
                <p className="text-gray-600">Analytics tools coming soon...</p>
              </div>
            </Tab.Panel>

            <Tab.Panel>
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Cloud Services</h3>
                <p className="text-gray-600">Cloud services management coming soon...</p>
              </div>
            </Tab.Panel>

            <Tab.Panel>
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">System Tools</h3>
                <p className="text-gray-600">System administration tools coming soon...</p>
              </div>
            </Tab.Panel>
          </Tab.Panels>
        </Tab.Group>
      </div>

      {/* Network Modal */}
      <NetworkModal
        isOpen={showAddModal || !!editingNetwork}
        onClose={() => {
          setShowAddModal(false)
          setEditingNetwork(null)
        }}
        network={editingNetwork}
        onSave={fetchL2Networks}
      />
    </div>
  )
}
