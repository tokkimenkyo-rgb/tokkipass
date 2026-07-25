import Link from 'next/link';
import { Clock } from 'lucide-react';

export default function CheckoutPendingPage({
  searchParams,
}: {
  searchParams: { order_id?: string };
}) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-amber-50 flex items-center justify-center p-4">
      <div className="w-full max-w-sm bg-white rounded-3xl shadow-xl border border-gray-100 p-8 text-center">
        <div className="inline-flex items-center justify-center w-16 h-16 bg-amber-100 rounded-full mb-4">
          <Clock className="w-8 h-8 text-amber-600" />
        </div>
        <h1 className="text-xl font-extrabold text-gray-900 mb-2">
          Menunggu Pembayaran
        </h1>
        <p className="text-sm text-gray-500 mb-2 leading-relaxed">
          Pembayaran kamu sedang diproses. Akun akan diupgrade otomatis dalam beberapa menit setelah pembayaran dikonfirmasi.
        </p>
        {searchParams.order_id && (
          <p className="text-xs text-gray-400 font-mono mb-6">
            Order: {searchParams.order_id}
          </p>
        )}
        <p className="text-xs text-amber-600 bg-amber-50 border border-amber-200 rounded-xl px-4 py-3 mb-5">
          Jika menggunakan transfer bank, selesaikan sebelum batas waktu yang tertera di instruksi pembayaran.
        </p>
        <Link
          href="/dashboard"
          className="block w-full py-3 border border-gray-200 hover:bg-gray-50 text-gray-700 font-bold rounded-2xl transition-colors"
        >
          Kembali ke Dashboard
        </Link>
      </div>
    </div>
  );
}
