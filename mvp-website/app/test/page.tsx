'use client'

import { useState, useEffect } from 'react'

export default function TestPage() {
  const [videoStatus, setVideoStatus] = useState<{[key: string]: string}>({
    '1.mp4': 'Loading...',
    '2.mp4': 'Loading...',
    '3.mp4': 'Loading...',
    '4.mp4': 'Loading...'
  })

  useEffect(() => {
    // Test video URLs
    const videos = ['/1.mp4', '/2.mp4', '/3.mp4', '/4.mp4']
    
    videos.forEach((url) => {
      fetch(url)
        .then(response => {
          if (response.ok) {
            setVideoStatus(prev => ({
              ...prev,
              [url.split('/')[1]]: `✅ Accessible (${response.status})`
            }))
          } else {
            setVideoStatus(prev => ({
              ...prev,
              [url.split('/')[1]]: `❌ Error (${response.status})`
            }))
          }
        })
        .catch(error => {
          console.error(`Error fetching ${url}:`, error)
          setVideoStatus(prev => ({
            ...prev,
            [url.split('/')[1]]: '❌ Network error'
          }))
        })
    })
  }, [])

  return (
    <div className="min-h-screen bg-dark-900 text-white p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold mb-8">Video Test Page</h1>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {['1.mp4', '2.mp4', '3.mp4', '4.mp4'].map((video) => (
            <div key={video} className="bg-dark-800 rounded-lg p-6">
              <h2 className="text-xl font-semibold mb-4">Test {video}</h2>
              
              <div className="mb-4">
                <video 
                  controls 
                  className="w-full rounded-lg"
                  onLoadStart={() => console.log(`${video} loading...`)}
                  onCanPlay={() => console.log(`${video} ready to play`)}
                  onError={(e) => console.error(`${video} error:`, e)}
                >
                  <source src={`/${video}`} type="video/mp4" />
                  Your browser does not support the video tag.
                </video>
              </div>
              
              <div className="bg-dark-700 p-3 rounded">
                <strong>Status:</strong> {videoStatus[video]}
              </div>
              
              <div className="mt-4 text-sm text-gray-400">
                <div>URL: <code>/{video}</code></div>
                <div>Size: {video === '1.mp4' ? '7.6MB' : 
                           video === '2.mp4' ? '6.1MB' :
                           video === '3.mp4' ? '6.5MB' : '3.2MB'}</div>
              </div>
            </div>
          ))}
        </div>
        
        <div className="mt-8 p-6 bg-dark-800 rounded-lg">
          <h3 className="text-xl font-semibold mb-4">Debug Information</h3>
          <div className="space-y-2 text-sm">
            <div>Current URL: {typeof window !== 'undefined' ? window.location.href : 'Server-side'}</div>
            <div>User Agent: {typeof navigator !== 'undefined' ? navigator.userAgent : 'Server-side'}</div>
            <div>Video Support: {typeof document !== 'undefined' && typeof document.createElement('video').canPlayType === 'function' ? 'Yes' : 'No'}</div>
          </div>
        </div>
        
        <div className="mt-8 text-center">
          <a 
            href="/" 
            className="inline-block px-6 py-3 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors"
          >
            Back to Main Site
          </a>
        </div>
      </div>
    </div>
  )
}
