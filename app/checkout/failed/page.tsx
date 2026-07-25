import Link from 'next/link';
import { XCircle } from 'lucide-react';

export default function CheckoutFailedPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-red-50 flex items-center justify-center p-4">
      <div className="w-full max-w-sm bg-white rounded-3xl shadow-xl border border-gray-100 p-8 text-center">
        <div className="inline-flex items-center justify-center w-16 h-16 bg-red-100 rounded-full mb-4">
          <XCircle className="w-8 h-8 text-red-600" />
        </div>
        <h1 className="text-xl font-extrabold text-gray-900 mb-2">
          Pembayaran Gagal
        </h1>
        <p className="text-sm text-gray-500 mb-6 leading-relaxed">
          Pembayaran tidak berhasil diproses. Tidak ada yang dikenakan biaya.
          Coba lagi dengan metode pembayaran yang berbeda.
        </p>
        <Link
          href="/checkout"
          className="block w-full py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-2xl transition-colors mb-2"
        >
          Coba Lagi
        </Link>
        <Link
          href="/dashboard"
          className="block text-sm text-gray-400 hover:text-gray-600 transition-colors"
        >
          Kembali ke Dashboard
        </Link>
      </div>
    </div>
  );
}
