'use client'

import { motion, AnimatePresence } from 'framer-motion'
import { useState } from 'react'
import { 
  Download,
  FileText,
  FileSpreadsheet,
  FileJson,
  FileText as FilePdf,
  Calendar,
  Filter,
  Settings,
  X,
  Check,
  ChevronDown,
  ChevronUp,
  Search,
  RefreshCw,
  Eye,
  EyeOff
} from 'lucide-react'

interface ExportFormat {
  id: string
  name: string
  icon: any
  description: string
  extensions: string[]
}

interface DataFilter {
  id: string
  name: string
  type: 'date' | 'range' | 'select' | 'boolean'
  value: any
  options?: string[]
}

export default function DataExportPanel({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  const [selectedFormat, setSelectedFormat] = useState<string>('csv')
  const [dateRange, setDateRange] = useState({ start: '', end: '' })
  const [selectedMetrics, setSelectedMetrics] = useState<string[]>(['price', 'volume', 'marketCap'])
  const [filters, setFilters] = useState<DataFilter[]>([
    { id: 'network', name: 'Network', type: 'select', value: 'all', options: ['all', 'ethereum', 'polygon', 'arbitrum', 'optimism'] },
    { id: 'minVolume', name: 'Min Volume', type: 'range', value: 0 },
    { id: 'includeNulls', name: 'Include Null Values', type: 'boolean', value: false }
  ])
  const [isExporting, setIsExporting] = useState(false)
  const [showAdvanced, setShowAdvanced] = useState(false)

  const exportFormats: ExportFormat[] = [
    {
      id: 'csv',
      name: 'CSV',
      icon: FileSpreadsheet,
      description: 'Comma-separated values for spreadsheet applications',
      extensions: ['.csv']
    },
    {
      id: 'json',
      name: 'JSON',
      icon: FileJson,
      description: 'Structured data format for APIs and applications',
      extensions: ['.json']
    },
    {
      id: 'pdf',
      name: 'PDF Report',
      icon: FilePdf,
      description: 'Formatted report with charts and analysis',
      extensions: ['.pdf']
    },
    {
      id: 'excel',
      name: 'Excel',
      icon: FileSpreadsheet,
      description: 'Microsoft Excel format with multiple sheets',
      extensions: ['.xlsx', '.xls']
    }
  ]

  const availableMetrics = [
    { id: 'price', name: 'Price Data', description: 'Historical price information' },
    { id: 'volume', name: 'Volume Data', description: 'Trading volume metrics' },
    { id: 'marketCap', name: 'Market Cap', description: 'Market capitalization data' },
    { id: 'tvl', name: 'TVL', description: 'Total Value Locked metrics' },
    { id: 'transactions', name: 'Transactions', description: 'Transaction count and fees' },
    { id: 'network', name: 'Network Stats', description: 'Network performance metrics' },
    { id: 'predictions', name: 'AI Predictions', description: 'Machine learning predictions' },
    { id: 'correlations', name: 'Correlations', description: 'Asset correlation data' }
  ]

  const handleExport = async () => {
    setIsExporting(true)
    
    // Simulate export process
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    // Create export configuration
    const exportConfig = {
      format: selectedFormat,
      dateRange,
      metrics: selectedMetrics,
      filters: filters.reduce((acc, filter) => {
        acc[filter.id] = filter.value
        return acc
      }, {} as Record<string, any>)
    }
    
    console.log('Exporting with config:', exportConfig)
    
    // Here you would typically call your API to generate the export
    const blob = new Blob(['Sample export data'], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `defimon-export-${new Date().toISOString().split('T')[0]}.${selectedFormat}`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
    
    setIsExporting(false)
    onClose()
  }

  const toggleMetric = (metricId: string) => {
    setSelectedMetrics(prev => 
      prev.includes(metricId) 
        ? prev.filter(id => id !== metricId)
        : [...prev, metricId]
    )
  }

  const updateFilter = (filterId: string, value: any) => {
    setFilters(prev => 
      prev.map(filter => 
        filter.id === filterId ? { ...filter, value } : filter
      )
    )
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4"
          onClick={onClose}
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.9, opacity: 0 }}
            className="bg-gray-900/95 backdrop-blur-2xl rounded-3xl border border-white/10 w-full max-w-4xl max-h-[90vh] overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-white/10">
              <div>
                <h2 className="text-2xl font-bold text-white">Export Data</h2>
                <p className="text-gray-400">Export your financial analytics data</p>
              </div>
              <motion.button
                onClick={onClose}
                className="p-2 text-gray-400 hover:text-white rounded-xl transition-all"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
              >
                <X className="w-6 h-6" />
              </motion.button>
            </div>

            <div className="p-6 overflow-y-auto max-h-[calc(90vh-140px)]">
              {/* Export Format Selection */}
              <div className="mb-8">
                <h3 className="text-lg font-semibold text-white mb-4">Export Format</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {exportFormats.map((format) => {
                    const Icon = format.icon
                    return (
                      <motion.button
                        key={format.id}
                        onClick={() => setSelectedFormat(format.id)}
                        className={`p-4 rounded-2xl border transition-all ${
                          selectedFormat === format.id
                            ? 'bg-purple-500/20 border-purple-500/50 text-white'
                            : 'bg-gray-800/50 border-white/10 text-gray-300 hover:bg-gray-700/50'
                        }`}
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                      >
                        <div className="flex items-center space-x-3">
                          <Icon className="w-6 h-6" />
                          <div className="text-left">
                            <div className="font-semibold">{format.name}</div>
                            <div className="text-sm opacity-75">{format.description}</div>
                          </div>
                        </div>
                      </motion.button>
                    )
                  })}
                </div>
              </div>

              {/* Date Range */}
              <div className="mb-8">
                <h3 className="text-lg font-semibold text-white mb-4">Date Range</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">Start Date</label>
                                         <input
                       type="date"
                       value={dateRange.start}
                       onChange={(e) => setDateRange(prev => ({ ...prev, start: e.target.value }))}
                       className="w-full px-4 py-3 bg-gray-800/50 border border-white/10 rounded-xl text-white focus:outline-none focus:border-purple-500"
                       aria-label="Start date"
                       title="Select start date"
                     />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">End Date</label>
                                         <input
                       type="date"
                       value={dateRange.end}
                       onChange={(e) => setDateRange(prev => ({ ...prev, end: e.target.value }))}
                       className="w-full px-4 py-3 bg-gray-800/50 border border-white/10 rounded-xl text-white focus:outline-none focus:border-purple-500"
                       aria-label="End date"
                       title="Select end date"
                     />
                  </div>
                </div>
              </div>

              {/* Metrics Selection */}
              <div className="mb-8">
                <h3 className="text-lg font-semibold text-white mb-4">Data Metrics</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {availableMetrics.map((metric) => (
                    <motion.button
                      key={metric.id}
                      onClick={() => toggleMetric(metric.id)}
                      className={`p-3 rounded-xl border transition-all text-left ${
                        selectedMetrics.includes(metric.id)
                          ? 'bg-green-500/20 border-green-500/50 text-white'
                          : 'bg-gray-800/50 border-white/10 text-gray-300 hover:bg-gray-700/50'
                      }`}
                      whileHover={{ scale: 1.01 }}
                      whileTap={{ scale: 0.99 }}
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <div className="font-medium">{metric.name}</div>
                          <div className="text-sm opacity-75">{metric.description}</div>
                        </div>
                        {selectedMetrics.includes(metric.id) && (
                          <Check className="w-5 h-5 text-green-400" />
                        )}
                      </div>
                    </motion.button>
                  ))}
                </div>
              </div>

              {/* Advanced Filters */}
              <div className="mb-8">
                <motion.button
                  onClick={() => setShowAdvanced(!showAdvanced)}
                  className="flex items-center space-x-2 text-white hover:text-purple-400 transition-colors"
                  whileHover={{ scale: 1.02 }}
                >
                  <Filter className="w-5 h-5" />
                  <span className="font-semibold">Advanced Filters</span>
                  {showAdvanced ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
                </motion.button>

                <AnimatePresence>
                  {showAdvanced && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      className="mt-4 space-y-4 overflow-hidden"
                    >
                      {filters.map((filter) => (
                        <div key={filter.id} className="p-4 bg-gray-800/30 rounded-xl">
                          <label className="block text-sm font-medium text-gray-300 mb-2">
                            {filter.name}
                          </label>
                          
                          {filter.type === 'select' && (
                                                         <select
                               value={filter.value}
                               onChange={(e) => updateFilter(filter.id, e.target.value)}
                               className="w-full px-4 py-2 bg-gray-800/50 border border-white/10 rounded-lg text-white focus:outline-none focus:border-purple-500"
                               aria-label={filter.name}
                               title={filter.name}
                             >
                              {filter.options?.map((option) => (
                                <option key={option} value={option}>
                                  {option.charAt(0).toUpperCase() + option.slice(1)}
                                </option>
                              ))}
                            </select>
                          )}
                          
                          {filter.type === 'range' && (
                                                         <input
                               type="number"
                               value={filter.value}
                               onChange={(e) => updateFilter(filter.id, parseFloat(e.target.value))}
                               className="w-full px-4 py-2 bg-gray-800/50 border border-white/10 rounded-lg text-white focus:outline-none focus:border-purple-500"
                               aria-label={filter.name}
                               title={filter.name}
                               placeholder={`Enter ${filter.name.toLowerCase()}`}
                             />
                          )}
                          
                          {filter.type === 'boolean' && (
                            <button
                              onClick={() => updateFilter(filter.id, !filter.value)}
                              className={`px-4 py-2 rounded-lg transition-all ${
                                filter.value
                                  ? 'bg-green-500/20 text-green-400 border border-green-500/50'
                                  : 'bg-gray-700/50 text-gray-300 border border-white/10'
                              }`}
                            >
                              {filter.value ? 'Enabled' : 'Disabled'}
                            </button>
                          )}
                        </div>
                      ))}
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            </div>

            {/* Footer */}
            <div className="flex items-center justify-between p-6 border-t border-white/10">
              <div className="text-sm text-gray-400">
                {selectedMetrics.length} metrics selected • {selectedFormat.toUpperCase()} format
              </div>
              <div className="flex items-center space-x-4">
                <motion.button
                  onClick={onClose}
                  className="px-6 py-3 text-gray-400 hover:text-white transition-colors"
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  Cancel
                </motion.button>
                <motion.button
                  onClick={handleExport}
                  disabled={isExporting || selectedMetrics.length === 0}
                  className="px-6 py-3 bg-gradient-to-r from-purple-500 to-blue-500 text-white rounded-xl font-semibold disabled:opacity-50 disabled:cursor-not-allowed"
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  {isExporting ? (
                    <div className="flex items-center space-x-2">
                      <RefreshCw className="w-4 h-4 animate-spin" />
                      <span>Exporting...</span>
                    </div>
                  ) : (
                    <div className="flex items-center space-x-2">
                      <Download className="w-4 h-4" />
                      <span>Export Data</span>
                    </div>
                  )}
                </motion.button>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
