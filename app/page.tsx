import Link from 'next/link';
import {
  CheckCircle2,
  X,
  ArrowRight,
  Users,
  MapPin,
} from 'lucide-react';
import { DemoQuiz } from '@/components/landing/DemoQuiz';

const FEATURES = [
  {
    emoji: '🎯',
    title: 'Soal jebakan asli',
    desc: 'Kumpulan soal tipe trick yang sering bikin gagal, diterjemahkan akurat dari ujian resmi.',
    bg: 'bg-indigo-50',
  },
  {
    emoji: '📖',
    title: 'Penjelasan mendalam',
    desc: 'Setiap soal ada konteks hukum lalu lintas Jepang, kamu ngerti bukan cuma hapal.',
    bg: 'bg-green-50',
  },
  {
    emoji: '⏱',
    title: 'Timer ujian realistis',
    desc: 'Kariamen 30 menit, Honmen 50 menit. Persis seperti kondisi ujian di Jepang.',
    bg: 'bg-amber-50',
  },
  {
    emoji: '📊',
    title: 'Lacak progres',
    desc: 'Dashboard akurasi, riwayat soal, dan indikator kesiapan ujian yang jelas.',
    bg: 'bg-pink-50',
  },
];

const TESTIMONIALS = [
  {
    text: 'Soal polisi horizontal bikin kepala pusing, tapi setelah latihan di sini langsung paham.',
    name: 'Rizki H.',
    city: 'Tokyo',
    initials: 'RH',
    avatarBg: 'bg-indigo-100',
    avatarText: 'text-indigo-700',
  },
  {
    text: 'Lulus kariamen pertama kali coba. Penjelasan tiap soal sangat membantu, bukan sekadar tebak-tebakan.',
    name: 'Dewi N.',
    city: 'Osaka',
    initials: 'DN',
    avatarBg: 'bg-green-100',
    avatarText: 'text-green-700',
  },
  {
    text: 'Akhirnya ada platform dalam Bahasa Indonesia. Jauh lebih gampang ngerti aturan lalin Jepang-nya.',
    name: 'Fajar A.',
    city: 'Nagoya',
    initials: 'FA',
    avatarBg: 'bg-amber-100',
    avatarText: 'text-amber-700',
  },
];

const FREE_FEATURES = [
  { text: '2 soal gratis kariamen', included: true },
  { text: 'Penjelasan dasar', included: true },
  { text: '500+ soal premium', included: false },
  { text: 'Mode honmen', included: false },
  { text: 'Lacak progres', included: false },
];

const PREMIUM_FEATURES = [
  '500+ soal kariamen & honmen',
  'Penjelasan mendalam per soal',
  'Mode ujian realistis + timer',
  'Dashboard progres lengkap',
  'Akses soal baru setiap bulan',
];

function Navbar() {
  return (
    <nav className="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100 px-6 h-14 flex items-center justify-between">
      <div className="flex items-center gap-2.5">
        <div className="w-8 h-8 rounded-xl bg-indigo-600 flex items-center justify-center flex-shrink-0">
          <span className="text-white font-black text-sm">免</span>
        </div>
        <span className="font-bold text-gray-900 text-sm">TokkiPass</span>
      </div>
      <div className="flex items-center gap-2">
        <Link
          href="/login"
          className="text-sm text-gray-600 hover:text-gray-900 px-3 py-1.5 transition-colors"
        >
          Masuk
        </Link>
        <Link
          href="/register"
          className="text-sm font-semibold bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-1.5 rounded-xl transition-colors"
        >
          Mulai gratis
        </Link>
      </div>
    </nav>
  );
}

function ProofStrip() {
  const items = [
    { icon: <Users className="w-3.5 h-3.5" />, num: '2.400+', label: 'pengguna aktif' },
    { icon: <CheckCircle2 className="w-3.5 h-3.5" />, num: '94%', label: 'tingkat kelulusan' },
    { icon: <MapPin className="w-3.5 h-3.5" />, label: 'Tokyo, Osaka, Nagoya, Aichi' },
  ];

  return (
    <div className="flex flex-wrap items-center justify-center gap-4 md:gap-6 pt-4 pb-1">
      {items.map((item, i) => (
        <div key={i} className="flex items-center gap-1.5 text-sm text-gray-500">
          <span className="text-gray-400">{item.icon}</span>
          {item.num && (
            <span className="font-semibold text-gray-700">{item.num}</span>
          )}
          <span>{item.label}</span>
        </div>
      ))}
    </div>
  );
}

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-slate-50">
      <Navbar />

      <section className="max-w-2xl mx-auto px-4 pt-14 pb-10 flex flex-col items-center text-center gap-6">
        <div className="inline-flex items-center gap-2 bg-white border border-gray-200 px-4 py-1.5 rounded-full text-xs text-gray-500 shadow-sm">
          <span className="w-1.5 h-1.5 rounded-full bg-green-500" />
          500+ soal ujian resmi Jepang
        </div>

        <h1 className="text-3xl md:text-4xl font-extrabold text-gray-900 leading-tight max-w-lg">
          Soal jebakan ujian SIM Jepang bikin pusing?{' '}
          <span className="text-indigo-600">Latihan dulu di sini.</span>
        </h1>

        <p className="text-gray-500 text-base max-w-sm leading-relaxed">
          Simulator ujian teori kariamen dan honmen dalam Bahasa Indonesia. Tiap soal ada
          penjelasan mendalam, bukan sekadar jawaban benar/salah.
        </p>

        <DemoQuiz />

        <ProofStrip />
      </section>

      <hr className="border-gray-100 max-w-2xl mx-auto" />

      <section className="max-w-2xl mx-auto px-4 py-12">
        <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2">
          Kenapa TokkiPass
        </p>
        <h2 className="text-xl font-extrabold text-gray-900 mb-6">
          Dirancang untuk diaspora, bukan turis
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {FEATURES.map((f) => (
            <div
              key={f.title}
              className="bg-white border border-gray-100 rounded-2xl p-4 shadow-sm"
            >
              <div
                className={`w-9 h-9 ${f.bg} rounded-xl flex items-center justify-center text-lg mb-3`}
              >
                {f.emoji}
              </div>
              <p className="text-sm font-semibold text-gray-800 mb-1">{f.title}</p>
              <p className="text-xs text-gray-500 leading-relaxed">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      <hr className="border-gray-100 max-w-2xl mx-auto" />

      <section className="max-w-2xl mx-auto px-4 py-12">
        <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2">
          Dari komunitas Indonesia
        </p>
        <h2 className="text-xl font-extrabold text-gray-900 mb-6">
          Sudah dipakai, sudah lulus
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {TESTIMONIALS.map((t) => (
            <div
              key={t.name}
              className="bg-white border border-gray-100 rounded-2xl p-4 shadow-sm"
            >
              <div className="text-amber-400 text-sm mb-2">★★★★★</div>
              <p className="text-xs text-gray-600 leading-relaxed mb-3">{t.text}</p>
              <div className="flex items-center gap-2">
                <div
                  className={`w-7 h-7 rounded-full ${t.avatarBg} ${t.avatarText} flex items-center justify-center text-xs font-bold flex-shrink-0`}
                >
                  {t.initials}
                </div>
                <div>
                  <p className="text-xs font-semibold text-gray-800">{t.name}</p>
                  <p className="text-xs text-gray-400">{t.city}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      <hr className="border-gray-100 max-w-2xl mx-auto" />

      <section className="max-w-2xl mx-auto px-4 py-12">
        <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2">
          Harga
        </p>
        <h2 className="text-xl font-extrabold text-gray-900 mb-6">
          Mulai gratis, upgrade kalau butuh lebih
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-white border border-gray-200 rounded-2xl p-5">
            <p className="font-extrabold text-gray-900 mb-1">Gratis</p>
            <p className="text-3xl font-black text-gray-900">
              ¥0{' '}
              <span className="text-sm font-normal text-gray-400">/ selamanya</span>
            </p>
            <ul className="mt-4 space-y-2">
              {FREE_FEATURES.map((f) => (
                <li key={f.text} className="flex items-center gap-2 text-sm">
                  {f.included ? (
                    <CheckCircle2 className="w-4 h-4 text-green-500 flex-shrink-0" />
                  ) : (
                    <X className="w-4 h-4 text-gray-300 flex-shrink-0" />
                  )}
                  <span className={f.included ? 'text-gray-700' : 'text-gray-400'}>
                    {f.text}
                  </span>
                </li>
              ))}
            </ul>
            <Link
              href="/register"
              className="mt-5 block text-center py-2.5 border border-gray-200 rounded-xl text-sm font-semibold text-gray-700 hover:bg-gray-50 transition-colors"
            >
              Mulai gratis
            </Link>
          </div>

          <div className="bg-white border-2 border-indigo-500 rounded-2xl p-5 relative">
            <span className="absolute -top-3 left-4 bg-indigo-600 text-white text-xs font-bold px-3 py-1 rounded-full">
              Paling populer
            </span>
            <p className="font-extrabold text-gray-900 mb-1">Premium</p>
            <p className="text-3xl font-black text-gray-900">
              ¥980{' '}
              <span className="text-sm font-normal text-gray-400">/ bulan</span>
            </p>
            <ul className="mt-4 space-y-2">
              {PREMIUM_FEATURES.map((f) => (
                <li key={f} className="flex items-center gap-2 text-sm text-gray-700">
                  <CheckCircle2 className="w-4 h-4 text-green-500 flex-shrink-0" />
                  {f}
                </li>
              ))}
            </ul>
            <Link
              href="/register?plan=premium"
              className="mt-5 flex items-center justify-center gap-2 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-sm font-semibold transition-colors"
            >
              Mulai Premium
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </section>

      <section className="max-w-2xl mx-auto px-4 pb-16">
        <div className="bg-white border border-gray-100 rounded-3xl shadow-sm p-10 text-center">
          <div className="text-5xl mb-4">〇</div>
          <h2 className="text-2xl font-extrabold text-gray-900 mb-2">
            Siap lulus ujian SIM Jepang?
          </h2>
          <p className="text-gray-500 text-sm mb-6">
            Daftar gratis dalam 30 detik. Tidak perlu kartu kredit.
          </p>
          <Link
            href="/register"
            className="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold px-8 py-3.5 rounded-2xl shadow-lg shadow-indigo-200 active:scale-[0.98] transition-all"
          >
            <ArrowRight className="w-5 h-5" />
            Mulai latihan sekarang
          </Link>
          <p className="text-xs text-gray-400 mt-3">
            Sudah digunakan oleh 2.400+ diaspora Indonesia di Jepang
          </p>
        </div>
      </section>

      <footer className="border-t border-gray-100">
        <div className="max-w-2xl mx-auto px-4 py-5 flex items-center justify-between">
          <p className="text-xs text-gray-400">© 2026 TokkiPass</p>
          <div className="flex gap-4">
            <Link href="/terms" className="text-xs text-gray-400 hover:text-gray-600">
              Syarat & Ketentuan
            </Link>
            <Link href="/privacy" className="text-xs text-gray-400 hover:text-gray-600">
              Privasi
            </Link>
            <Link href="/contact" className="text-xs text-gray-400 hover:text-gray-600">
              Kontak
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
