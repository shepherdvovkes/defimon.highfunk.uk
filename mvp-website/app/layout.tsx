import type { Metadata, Viewport } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  metadataBase: new URL('https://defimon.highfunk.uk'),
  title: 'DEFIMON - DeFi Analytics Platform',
  description: 'Advanced DeFi analytics platform with AI/ML integration for predictions and risk assessment. Monitor 50+ L2 networks, Cosmos ecosystem, and Polkadot parachains.',
  keywords: 'DeFi, Analytics, Blockchain, Ethereum, L2, Cosmos, Polkadot, AI, ML, Cryptocurrency',
  authors: [{ name: 'DEFIMON Team' }],
  creator: 'DEFIMON',
  publisher: 'DEFIMON',
  robots: 'index, follow',
  openGraph: {
    title: 'DEFIMON - DeFi Analytics Platform',
    description: 'Advanced DeFi analytics platform with AI/ML integration',
    url: 'https://defimon.highfunk.uk',
    siteName: 'DEFIMON',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'DEFIMON DeFi Analytics Platform',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'DEFIMON - DeFi Analytics Platform',
    description: 'Advanced DeFi analytics platform with AI/ML integration',
    images: ['/og-image.png'],
  },
}

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#3b82f6',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="scroll-smooth">
      <head>
        <link rel="icon" href="/favicon.svg" type="image/svg+xml" />
      </head>
      <body className={`${inter.className} antialiased`}>
        {children}
      </body>
    </html>
  )
}
