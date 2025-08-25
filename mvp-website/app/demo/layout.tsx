import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'DeFiMon Demo - Interactive Platform Demo',
  description: 'Explore DeFiMon capabilities - innovative DeFi analytics platform with AI/ML integration',
}

export default function DemoLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return children
}
