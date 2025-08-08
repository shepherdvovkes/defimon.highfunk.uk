import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'DeFi Analytics Platform',
  description: 'Real-time DeFi protocol monitoring and analytics with AI/ML predictions',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
