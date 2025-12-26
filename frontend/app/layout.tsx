import './globals.css'
import type { Metadata } from 'next'
import { ReactNode } from 'react'

export const metadata: Metadata = {
  title: 'ТОВ Лекс ЕйАй (Lex AI) - IT розробка та технічне супроводження',
  description: 'ТОВ Лекс ЕйАй - компанія з розробки програмного забезпечення та технічного супроводу IT проектів. Досвід інтеграції з Закононлайн, Укрпатент, Рада.гов.юа та іншими сервісами.',
}

export default function RootLayout({
  children,
}: {
  children: ReactNode
}) {
  return (
    <html lang="uk">
      <body>{children}</body>
    </html>
  )
}
