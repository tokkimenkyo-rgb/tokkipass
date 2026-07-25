import Link from 'next/link';
import { CheckCircle2 } from 'lucide-react';

export default function CheckoutSuccessPage({
  searchParams,
}: {
  searchParams: { order_id?: string };
}) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-indigo-50 flex items-center justify-center p-4">
      <div className="w-full max-w-sm bg-white rounded-3xl shadow-xl border border-gray-100 p-8 text-center">
        <div className="inline-flex items-center justify-center w-16 h-16 bg-green-100 rounded-full mb-4">
          <CheckCircle2 className="w-8 h-8 text-green-600" />
        </div>
        <h1 className="text-xl font-extrabold text-gray-900 mb-2">
          Pembayaran Berhasil!
        </h1>
        <p className="text-sm text-gray-500 mb-2 leading-relaxed">
          Akun kamu sudah diupgrade ke Premium. Akses semua soal jebakan sekarang.
        </p>
        {searchParams.order_id && (
          <p className="text-xs text-gray-400 font-mono mb-6">
            Order: {searchParams.order_id}
          </p>
        )}
        <Link
          href="/quiz"
          className="block w-full py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-2xl transition-colors"
        >
          Mulai Latihan Premium
        </Link>
        <Link
          href="/dashboard"
          className="block mt-2 text-sm text-gray-400 hover:text-gray-600 transition-colors"
        >
          Ke Dashboard
        </Link>
      </div>
    </div>
  );
}
