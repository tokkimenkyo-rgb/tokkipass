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
    bg: 'bg-blue-50',
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
    bg: 'bg-blue-50',
  },
];

const TESTIMONIALS = [
  {
    text: 'Soal polisi horizontal bikin kepala pusing, tapi setelah latihan di sini langsung paham.',
    name: 'Rizki H.',
    city: 'Tokyo',
    initials: 'RH',
    avatarBg: 'bg-blue-100',
    avatarText: 'text-blue-700',
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

// ---------------------------------------------------------------------------
// Pixel design tokens — scoped to this page only, doesn't touch globals.css
// or tailwind config, so no other page is affected.
// ---------------------------------------------------------------------------
function PixelTheme() {
  return (
    <style>{`
      @import url('https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap');

      .tp-pixel-font { font-family: 'Press Start 2P', monospace; }

      .tp-corners {
        clip-path: polygon(
          0 8px, 8px 8px, 8px 0,
          calc(100% - 8px) 0, calc(100% - 8px) 8px, 100% 8px,
          100% calc(100% - 8px), calc(100% - 8px) calc(100% - 8px), calc(100% - 8px) 100%,
          8px 100%, 8px calc(100% - 8px), 0 calc(100% - 8px)
        );
      }
      .tp-corners-sm {
        clip-path: polygon(
          0 5px, 5px 5px, 5px 0,
          calc(100% - 5px) 0, calc(100% - 5px) 5px, 100% 5px,
          100% calc(100% - 5px), calc(100% - 5px) calc(100% - 5px), calc(100% - 5px) 100%,
          5px 100%, 5px calc(100% - 5px), 0 calc(100% - 5px)
        );
      }

      .tp-outline-text {
        text-shadow:
          2px 0 0 #14213d, -2px 0 0 #14213d, 0 2px 0 #14213d, 0 -2px 0 #14213d,
          2px 2px 0 #14213d, -2px -2px 0 #14213d, 2px -2px 0 #14213d, -2px 2px 0 #14213d;
      }

      .tp-btn {
        border: 3px solid #14213d;
        box-shadow: 4px 4px 0 0 #14213d;
        transition: transform 0.06s ease, box-shadow 0.06s ease;
      }
      .tp-btn:hover { filter: brightness(1.06); }
      .tp-btn:active { transform: translate(4px, 4px); box-shadow: 0 0 0 0 #14213d; }

      .tp-card {
        border: 3px solid #14213d;
        box-shadow: 4px 4px 0 0 #14213d;
      }

      @keyframes tp-drift { from { transform: translateX(0); } to { transform: translateX(-30px); } }
      .tp-cloud { animation: tp-drift 7s ease-in-out infinite alternate; }

      @media (prefers-reduced-motion: reduce) {
        .tp-cloud { animation: none; }
      }
    `}</style>
  );
}

function Navbar() {
  return (
    <nav
      className="sticky top-0 z-50 px-4 sm:px-6 h-16 flex items-center justify-between"
      style={{ background: '#14213d', borderBottom: '4px solid #14213d' }}
    >
      <div className="flex items-center gap-2.5">
        <div
          className="tp-corners-sm w-9 h-9 flex items-center justify-center flex-shrink-0"
          style={{ background: '#2f7fe0', border: '3px solid #fff' }}
        >
          <span className="text-white font-black text-sm">免</span>
        </div>
        <span className="tp-pixel-font text-white" style={{ fontSize: 11 }}>
          TokkiPass
        </span>
      </div>
      <div className="flex items-center gap-2">
        <Link
          href="/login"
          className="tp-pixel-font text-white/80 hover:text-white px-2 sm:px-3 py-1.5 transition-colors"
          style={{ fontSize: 9 }}
        >
          Masuk
        </Link>
        <Link
          href="/register"
          className="tp-btn tp-corners-sm tp-pixel-font"
          style={{ background: '#ffc107', color: '#14213d', fontSize: 9, padding: '8px 14px' }}
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
    <div className="flex flex-wrap items-center justify-center gap-3 pt-5 pb-1">
      {items.map((item, i) => (
        <div
          key={i}
          className="tp-corners-sm flex items-center gap-1.5 text-xs bg-white px-3 py-1.5"
          style={{ border: '2px solid #14213d', color: '#14213d' }}
        >
          <span style={{ color: '#2f7fe0' }}>{item.icon}</span>
          {item.num && <span className="font-bold">{item.num}</span>}
          <span className="text-gray-600">{item.label}</span>
        </div>
      ))}
    </div>
  );
}

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-white">
      <PixelTheme />
      <Navbar />

      {/* ---- Hero: the only section with the full pixel-racing scene ---- */}
      <section className="max-w-3xl mx-auto px-4 pt-6">
        <div
          className="tp-corners relative overflow-hidden px-4 sm:px-8 pt-8 pb-6 flex flex-col items-center text-center gap-5"
          style={{ background: 'linear-gradient(180deg, #7ec8f5 0%, #bfe6ff 75%)', border: '4px solid #14213d' }}
        >
          {/* decorative clouds */}
          <div className="absolute inset-0 pointer-events-none">
            <div className="tp-cloud absolute" style={{ top: '10%', left: '6%', width: 56, height: 22, background: '#fff', border: '2px solid #14213d' }} />
            <div className="tp-cloud absolute" style={{ top: '16%', right: '10%', width: 44, height: 18, background: '#fff', border: '2px solid #14213d', animationDelay: '1.2s' }} />
          </div>
          {/* grass + road baseline */}
          <div className="absolute bottom-0 left-0 right-0" style={{ height: 14, background: '#4CAF50', borderTop: '3px solid #14213d' }} />

          <div
            className="tp-corners-sm relative inline-flex items-center gap-2 bg-white px-3 py-1.5 text-xs text-gray-600"
            style={{ border: '2px solid #14213d' }}
          >
            <span className="w-1.5 h-1.5 rounded-full bg-green-500" />
            500+ soal ujian resmi Jepang
          </div>

          <h1 className="relative text-3xl md:text-4xl font-extrabold text-gray-900 leading-tight max-w-lg">
            Soal jebakan ujian SIM Jepang bikin pusing?{' '}
            <span style={{ color: '#14213d' }}>Latihan dulu di sini.</span>
          </h1>

          <p className="relative text-gray-700 text-base max-w-sm leading-relaxed">
            Simulator ujian teori kariamen dan honmen dalam Bahasa Indonesia. Tiap soal ada
            penjelasan mendalam, bukan sekadar jawaban benar/salah.
          </p>

          <div className="relative w-full">
            <DemoQuiz />
          </div>
        </div>

        <ProofStrip />
      </section>

      {/* ---- Features ---- */}
      <section className="max-w-2xl mx-auto px-4 py-12">
        <p className="tp-pixel-font mb-3" style={{ fontSize: 9, color: '#2f7fe0' }}>
          KENAPA TOKKIPASS
        </p>
        <h2 className="text-xl font-extrabold text-gray-900 mb-6">
          Dirancang untuk diaspora, bukan turis
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {FEATURES.map((f) => (
            <div key={f.title} className="tp-card tp-corners-sm bg-white p-4">
              <div className={`w-9 h-9 ${f.bg} tp-corners-sm flex items-center justify-center text-lg mb-3`} style={{ border: '2px solid #14213d' }}>
                {f.emoji}
              </div>
              <p className="text-sm font-bold text-gray-900 mb-1">{f.title}</p>
              <p className="text-xs text-gray-500 leading-relaxed">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ---- Testimonials ---- */}
      <section className="max-w-2xl mx-auto px-4 py-12">
        <p className="tp-pixel-font mb-3" style={{ fontSize: 9, color: '#2f7fe0' }}>
          DARI KOMUNITAS INDONESIA
        </p>
        <h2 className="text-xl font-extrabold text-gray-900 mb-6">
          Sudah dipakai, sudah lulus
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {TESTIMONIALS.map((t) => (
            <div key={t.name} className="tp-card tp-corners-sm bg-white p-4">
              <div className="text-amber-400 text-sm mb-2">★★★★★</div>
              <p className="text-xs text-gray-600 leading-relaxed mb-3">{t.text}</p>
              <div className="flex items-center gap-2">
                <div
                  className={`w-7 h-7 tp-corners-sm ${t.avatarBg} ${t.avatarText} flex items-center justify-center text-xs font-bold flex-shrink-0`}
                  style={{ border: '2px solid #14213d' }}
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

      {/* ---- Pricing ---- */}
      <section className="max-w-2xl mx-auto px-4 py-12">
        <p className="tp-pixel-font mb-3" style={{ fontSize: 9, color: '#2f7fe0' }}>
          HARGA
        </p>
        <h2 className="text-xl font-extrabold text-gray-900 mb-6">
          Mulai gratis, upgrade kalau butuh lebih
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="tp-card tp-corners bg-white p-5">
            <p className="font-extrabold text-gray-900 mb-1">Gratis</p>
            <p className="text-3xl font-black text-gray-900">
              ¥0 <span className="text-sm font-normal text-gray-400">/ selamanya</span>
            </p>
            <ul className="mt-4 space-y-2">
              {FREE_FEATURES.map((f) => (
                <li key={f.text} className="flex items-center gap-2 text-sm">
                  {f.included ? (
                    <CheckCircle2 className="w-4 h-4 text-green-500 flex-shrink-0" />
                  ) : (
                    <X className="w-4 h-4 text-gray-300 flex-shrink-0" />
                  )}
                  <span className={f.included ? 'text-gray-700' : 'text-gray-400'}>{f.text}</span>
                </li>
              ))}
            </ul>
            <Link
              href="/register"
              className="tp-btn tp-corners-sm tp-pixel-font mt-5 block text-center py-3"
              style={{ background: '#fff', color: '#14213d', fontSize: 9 }}
            >
              Mulai gratis
            </Link>
          </div>

          <div className="tp-card tp-corners bg-white p-5 relative" style={{ borderColor: '#2f7fe0' }}>
            <span
              className="tp-pixel-font tp-corners-sm absolute -top-3 left-4 text-white px-3 py-1.5"
              style={{ background: '#ffc107', color: '#14213d', fontSize: 8, border: '2px solid #14213d' }}
            >
              PALING POPULER
            </span>
            <p className="font-extrabold text-gray-900 mb-1">Premium</p>
            <p className="text-3xl font-black text-gray-900">
              ¥980 <span className="text-sm font-normal text-gray-400">/ bulan</span>
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
              className="tp-btn tp-corners-sm tp-pixel-font mt-5 flex items-center justify-center gap-2 py-3"
              style={{ background: '#2f7fe0', color: '#fff', fontSize: 9 }}
            >
              Mulai Premium
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </section>

      {/* ---- Final CTA ---- */}
      <section className="max-w-2xl mx-auto px-4 pb-16">
        <div className="tp-card tp-corners text-center p-10" style={{ background: '#14213d' }}>
          <div className="text-5xl mb-4">〇</div>
          <h2 className="text-2xl font-extrabold text-white mb-2">
            Siap lulus ujian SIM Jepang?
          </h2>
          <p className="text-white/70 text-sm mb-6">
            Daftar gratis dalam 30 detik. Tidak perlu kartu kredit.
          </p>
          <Link
            href="/register"
            className="tp-btn tp-corners-sm tp-pixel-font inline-flex items-center gap-2 px-8 py-4"
            style={{ background: '#ffc107', color: '#14213d', fontSize: 10 }}
          >
            <ArrowRight className="w-5 h-5" />
            Mulai latihan sekarang
          </Link>
          <p className="text-xs text-white/50 mt-4">
            Sudah digunakan oleh 2.400+ diaspora Indonesia di Jepang
          </p>
        </div>
      </section>

      <footer style={{ borderTop: '4px solid #14213d' }}>
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