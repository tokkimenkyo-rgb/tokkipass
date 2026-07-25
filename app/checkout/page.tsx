'use client';

import { useEffect, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import {
  Lock,
  Star,
  BookOpen,
  Trophy,
  Zap,
  AlertCircle,
  Loader2,
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { createSnapToken } from '@/actions/create-snap-token';

declare global {
  interface Window {
    snap?: {
      pay: (
        token: string,
        options: {
          onSuccess: (result: unknown) => void;
          onPending: (result: unknown) => void;
          onError: (result: unknown) => void;
          onClose: () => void;
        }
      ) => void;
    };
  }
}

const BENEFITS = [
  {
    icon: <BookOpen className="w-4 h-4 text-indigo-500" />,
    title: '500+ soal kariamen & honmen',
    desc: 'Bank soal lengkap dari ujian resmi, diperbarui rutin',
  },
  {
    icon: <Zap className="w-4 h-4 text-amber-500" />,
    title: 'Penjelasan mendalam per soal',
    desc: 'Konteks hukum lalu lintas Jepang - kamu ngerti, bukan cuma hapal',
  },
  {
    icon: <Trophy className="w-4 h-4 text-green-500" />,
    title: 'Simulasi ujian realistis',
    desc: 'Timer kariamen 30 menit, honmen 50 menit',
  },
  {
    icon: <Star className="w-4 h-4 text-yellow-500" />,
    title: 'Dashboard progres lengkap',
    desc: 'Lacak akurasi, riwayat soal, dan kesiapan ujian',
  },
];

export default function CheckoutPage() {
  const router = useRouter();
  const [snapLoaded, setSnapLoaded] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    const clientKey = process.env.NEXT_PUBLIC_MIDTRANS_CLIENT_KEY;
    const isProduction = process.env.NEXT_PUBLIC_MIDTRANS_IS_PRODUCTION === 'true';

    if (!clientKey) {
      setErrorMsg('Konfigurasi payment gateway tidak ditemukan.');
      return;
    }

    const script = document.createElement('script');
    script.src = isProduction
      ? 'https://app.midtrans.com/snap/snap.js'
      : 'https://app.sandbox.midtrans.com/snap/snap.js';
    script.setAttribute('data-client-key', clientKey);
    script.onload = () => setSnapLoaded(true);
    script.onerror = () => setErrorMsg('Gagal memuat payment gateway. Coba refresh halaman.');
    document.head.appendChild(script);

    return () => {
      document.head.removeChild(script);
    };
  }, []);

  function handleCheckout() {
    if (!snapLoaded) {
      setErrorMsg('Payment gateway belum siap. Tunggu sebentar.');
      return;
    }

    setErrorMsg('');

    startTransition(async () => {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();

      if (!user) {
        router.push('/login?redirectTo=/checkout');
        return;
      }

      const { data: profileData } = await supabase
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .single();

      const profile = profileData as { full_name: string | null } | null;

      const result = await createSnapToken({
        userId: user.id,
        userEmail: user.email ?? '',
        userName: profile?.full_name ?? user.email?.split('@')[0] ?? 'Pengguna',
      });

      if (!result.success || !result.data) {
        setErrorMsg(result.error ?? 'Gagal membuat sesi pembayaran');
        return;
      }

      window.snap?.pay(result.data.token, {
        onSuccess: () => {
          router.push(`/checkout/success?order_id=${result.data!.orderId}`);
        },
        onPending: () => {
          router.push(`/checkout/pending?order_id=${result.data!.orderId}`);
        },
        onError: () => {
          setErrorMsg(
            'Pembayaran gagal. Coba lagi atau pilih metode lain.'
          );
        },
        onClose: () => {
          console.info('[checkout] Snap popup closed by user');
        },
      });
    });
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-indigo-50 flex items-center justify-center p-4">
      <div className="w-full max-w-sm">
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-14 h-14 bg-indigo-600 rounded-2xl mb-3 shadow-lg shadow-indigo-200">
            <span className="text-3xl text-white font-black">免</span>
          </div>
          <h1 className="text-xl font-extrabold text-gray-900">
            Upgrade ke Premium
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            Akses penuh ke semua soal ujian SIM Jepang
          </p>
        </div>

        <div className="bg-white rounded-3xl shadow-xl border border-gray-100 overflow-hidden mb-4">
          <div className="bg-gradient-to-r from-indigo-600 to-purple-600 px-6 py-5 text-white text-center">
            <p className="text-sm text-indigo-200 mb-1">Harga per bulan</p>
            <div className="flex items-baseline justify-center gap-1">
              <span className="text-5xl font-black">¥980</span>
              <span className="text-indigo-300 text-sm">/ bulan</span>
            </div>
            <p className="text-xs text-indigo-200 mt-1">
              Sekitar Rp 98.000 - Batalkan kapan saja
            </p>
          </div>

          <div className="p-5 space-y-3">
            {BENEFITS.map((b) => (
              <div key={b.title} className="flex items-start gap-3">
                <div className="mt-0.5 w-7 h-7 bg-gray-50 rounded-lg flex items-center justify-center flex-shrink-0">
                  {b.icon}
                </div>
                <div>
                  <p className="text-sm font-semibold text-gray-800">{b.title}</p>
                  <p className="text-xs text-gray-500">{b.desc}</p>
                </div>
              </div>
            ))}
          </div>

          {errorMsg && (
            <div className="mx-5 mb-4 flex items-start gap-2 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-3.5 py-3">
              <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          <div className="px-5 pb-5">
            <button
              onClick={handleCheckout}
              disabled={isPending || !snapLoaded}
              className="flex items-center justify-center gap-2 w-full py-3.5 bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 disabled:from-indigo-300 disabled:to-purple-300 text-white font-bold rounded-2xl shadow-lg shadow-indigo-200 active:scale-[0.98] transition-all duration-200"
            >
              {isPending ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Menyiapkan pembayaran...
                </>
              ) : !snapLoaded ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Memuat payment gateway...
                </>
              ) : (
                <>
                  <Lock className="w-4 h-4" />
                  Bayar Sekarang
                </>
              )}
            </button>

            <div className="flex items-center justify-center gap-1.5 mt-3 text-xs text-gray-400">
              <Lock className="w-3 h-3" />
              Pembayaran aman via Midtrans - GoPay - QRIS - Transfer Bank
            </div>
          </div>
        </div>

        <p className="text-xs text-center text-gray-400">
          Dengan melanjutkan, kamu setuju dengan{' '}
          <a href="/terms" className="underline hover:text-gray-600">
            Syarat & Ketentuan
          </a>{' '}
          kami.
        </p>
      </div>
    </div>
  );
}
