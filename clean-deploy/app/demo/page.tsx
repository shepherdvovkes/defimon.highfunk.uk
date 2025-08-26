'use client'

import '../globals.css'
import { useState } from 'react'
import { ArrowLeft } from 'lucide-react'
import Link from 'next/link'
import InteractiveNetworkMap from '../../components/demo/InteractiveNetworkMap'

export default function DemoPage() {
  return (
    <main className="compact-container">
      {/* Header */}
      <header className="nav-compact">
        <div className="flex items-center justify-between w-full">
          <div className="flex items-center space-x-4">
            <Link href="/" className="flex items-center space-x-2 text-text-primary hover:text-accent-blue transition-colors">
              <ArrowLeft className="w-4 h-4" />
              <span className="text-sm">Back</span>
            </Link>
          </div>
          <div className="text-center">
            <h1 className="font-display font-bold text-lg">Network Topology</h1>
            <span className="text-muted text-xs">Interactive Demo</span>
          </div>
          <div className="w-16"></div> {/* Spacer for centering */}
        </div>
      </header>

      {/* Network Map */}
      <div className="mt-4">
        <InteractiveNetworkMap />
      </div>
    </main>
  )
}
