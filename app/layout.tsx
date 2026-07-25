import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'TokkiPass - Simulator Ujian SIM Jepang',
  description:
    'Latihan ujian teori SIM Jepang untuk diaspora Indonesia. 500+ soal jebakan dengan pembahasan mendalam.',
  keywords: ['ujian sim jepang', 'menkyo', 'gakka shiken', 'indonesian japan', 'kariamen', 'honmen'],
  openGraph: {
    title: 'TokkiPass',
    description: 'Simulator Ujian SIM Jepang untuk Diaspora Indonesia',
    locale: 'id_ID',
    type: 'website',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id">
      <body className={`${inter.className} antialiased`}>{children}</body>
    </html>
  );
}

