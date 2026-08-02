import { redirect } from 'next/navigation';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/server';
import {
  BookOpen,
  Trophy,
  Star,
  ChevronRight,
  LogOut,
  CheckCircle2,
  XCircle,
  Clock,
  Zap,
} from 'lucide-react';
import type { Profile, UserProgress, Question } from '@/types/database.types';

async function getDashboardData(userId: string) {
  const supabase = await createClient();

  const [profileResult, progressResult] = await Promise.all([
    supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single(),
    supabase
      .from('user_progress')
      .select('*, questions(*)')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(50),
  ]);

  return {
    profile: profileResult.data as Profile | null,
    progress: (progressResult.data ?? []) as Array<
      UserProgress & { questions: Question }
    >,
  };
}

// ---------------------------------------------------------------------------
// Pixel design tokens — scoped to this page only (same tokens as app/page.tsx,
// duplicated on purpose so this file has zero shared-file dependency risk).
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
    `}</style>
  );
}

function StatCard({
  icon,
  label,
  value,
  color,
}: {
  icon: React.ReactNode;
  label: string;
  value: string | number;
  color: string;
}) {
  return (
    <div className="tp-card tp-corners-sm bg-white p-4 flex items-center gap-3">
      <div
        className={`w-10 h-10 tp-corners-sm flex items-center justify-center ${color}`}
        style={{ border: '2px solid #14213d' }}
      >
        {icon}
      </div>
      <div>
        <p className="tp-pixel-font text-gray-900" style={{ fontSize: 15 }}>
          {value}
        </p>
        <p className="text-xs text-gray-500 mt-1">{label}</p>
      </div>
    </div>
  );
}

function ProgressItem({
  item,
}: {
  item: UserProgress & { questions: Question };
}) {
  return (
    <div className="flex items-center gap-3 py-3 border-b border-gray-100 last:border-0">
      <div className="flex-shrink-0">
        {item.is_correct ? (
          <CheckCircle2 className="w-5 h-5 text-green-500" />
        ) : (
          <XCircle className="w-5 h-5 text-red-400" />
        )}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm text-gray-800 truncate font-medium">
          {item.questions?.question_code ?? '-'}
        </p>
        <p className="text-xs text-gray-400 mt-0.5">
          {item.questions?.question_code} -{' '}
          {new Date(item.created_at).toLocaleDateString('id-ID', {
            day: 'numeric',
            month: 'short',
            hour: '2-digit',
            minute: '2-digit',
          })}
        </p>
      </div>
      <span
        className={`tp-corners-sm flex-shrink-0 text-xs font-bold px-2 py-0.5 ${
          item.is_correct ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-600'
        }`}
        style={{ border: '2px solid #14213d' }}
      >
        {item.is_correct ? 'Benar' : 'Salah'}
      </span>
    </div>
  );
}

export default async function DashboardPage() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect('/login');

  const { profile, progress } = await getDashboardData(user.id);

  if (!profile) redirect('/login');

  const totalAttempted = progress.length;
  const totalCorrect = progress.filter((p) => p.is_correct).length;
  const accuracy =
    totalAttempted > 0 ? Math.round((totalCorrect / totalAttempted) * 100) : 0;
  const isPremium = profile.tier === 'premium';

  const examModes = [
    {
      title: 'Kariamen',
      desc: 'Ujian SIM Sementara - 50 soal - 30 menit',
      href: '/quiz?type=kariamen',
      icon: '🏁',
      accent: '#2f7fe0',
      badge: null as string | null,
    },
    {
      title: 'Honmen',
      desc: 'Ujian SIM Resmi - 95 soal - 50 menit',
      href: isPremium ? '/quiz?type=honmen' : '#',
      icon: '🚦',
      accent: '#f2a900',
      badge: isPremium ? null : 'Premium',
    },
  ];

  return (
    <div className="min-h-screen bg-white">
      <PixelTheme />

      <nav style={{ background: '#14213d', borderBottom: '4px solid #14213d' }} className="sticky top-0 z-10">
        <div className="max-w-2xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div
              className="tp-corners-sm w-9 h-9 flex items-center justify-center"
              style={{ background: '#2f7fe0', border: '3px solid #fff' }}
            >
              <span className="text-white font-black text-sm">免</span>
            </div>
            <span className="tp-pixel-font text-white" style={{ fontSize: 11 }}>TokkiPass</span>
          </div>
          <div className="flex items-center gap-3">
            {isPremium ? (
              <span
                className="tp-corners-sm text-xs font-bold text-white px-2.5 py-1.5 flex items-center gap-1"
                style={{ background: '#ffc107', color: '#14213d', border: '2px solid #fff' }}
              >
                <Star className="w-3 h-3" /> Premium
              </span>
            ) : (
              <Link
                href="/checkout"
                className="tp-btn tp-corners-sm tp-pixel-font"
                style={{ background: '#ffc107', color: '#14213d', fontSize: 8, padding: '8px 12px' }}
              >
                Upgrade
              </Link>
            )}
            <form action="/auth/signout" method="post">
              <button
                type="submit"
                className="text-white/60 hover:text-white transition-colors"
                aria-label="Logout"
              >
                <LogOut className="w-5 h-5" />
              </button>
            </form>
          </div>
        </div>
      </nav>

      <main className="max-w-2xl mx-auto px-4 py-6 space-y-6">
        <div>
          <p className="text-sm text-gray-500">Selamat datang,</p>
          <h1 className="tp-pixel-font text-gray-900 mt-2" style={{ fontSize: 18, lineHeight: 1.6 }}>
            {profile.full_name || user.email?.split('@')[0] || 'Pengguna'}
          </h1>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <StatCard
            icon={<BookOpen className="w-5 h-5 text-blue-600" />}
            label="Total Dikerjakan"
            value={totalAttempted}
            color="bg-blue-50"
          />
          <StatCard
            icon={<Trophy className="w-5 h-5 text-amber-600" />}
            label="Akurasi"
            value={`${accuracy}%`}
            color="bg-amber-50"
          />
          <StatCard
            icon={<CheckCircle2 className="w-5 h-5 text-green-600" />}
            label="Jawaban Benar"
            value={totalCorrect}
            color="bg-green-50"
          />
          <StatCard
            icon={<Clock className="w-5 h-5 text-blue-600" />}
            label="Sesi Latihan"
            value={Math.ceil(totalAttempted / 10)}
            color="bg-blue-50"
          />
        </div>

        {totalAttempted >= 10 && (
          <div
            className={`tp-card tp-corners-sm p-4 flex items-center gap-3 ${
              accuracy >= 90 ? 'bg-green-50' : 'bg-amber-50'
            }`}
          >
            <span className="text-2xl">{accuracy >= 90 ? '🎉' : '📚'}</span>
            <div>
              <p className="font-bold text-sm text-gray-800">
                {accuracy >= 90 ? 'Kamu siap ujian!' : 'Terus berlatih!'}
              </p>
              <p className="text-xs text-gray-500">
                Batas lulus ujian Jepang: 90%. Akurasi kamu: <strong>{accuracy}%</strong>
              </p>
            </div>
          </div>
        )}

        <div>
          <p className="tp-pixel-font mb-3" style={{ fontSize: 9, color: '#2f7fe0' }}>
            PILIH MODE UJIAN
          </p>
          <div className="space-y-3">
            {examModes.map((mode) => (
              <Link
                key={mode.title}
                href={mode.href}
                className="tp-btn tp-corners group flex items-center justify-between p-4 text-white"
                style={{ background: mode.accent }}
              >
                <div className="flex items-center gap-3">
                  <span className="text-2xl">{mode.icon}</span>
                  <div>
                    <div className="flex items-center gap-2">
                      <p className="tp-pixel-font" style={{ fontSize: 11 }}>{mode.title}</p>
                      {mode.badge && (
                        <span
                          className="tp-corners-sm text-xs bg-white/90 px-2 py-0.5 flex items-center gap-1"
                          style={{ color: '#14213d' }}
                        >
                          <Star className="w-2.5 h-2.5" />
                          {mode.badge}
                        </span>
                      )}
                    </div>
                    <p className="text-white/85 text-xs mt-1">{mode.desc}</p>
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 flex-shrink-0 group-hover:translate-x-1 transition-transform" />
              </Link>
            ))}
          </div>
        </div>

        {!isPremium && (
          <div className="tp-card tp-corners p-5 text-white" style={{ background: '#14213d' }}>
            <div className="flex items-start gap-3 mb-4">
              <Zap className="w-6 h-6 flex-shrink-0 mt-0.5" style={{ color: '#ffc107' }} />
              <div>
                <p className="tp-pixel-font" style={{ fontSize: 11 }}>Unlock Premium</p>
                <p className="text-white/70 text-sm mt-2">
                  500+ soal jebakan, pembahasan mendalam, dan simulasi ujian realistis
                </p>
              </div>
            </div>
            <Link
              href="/checkout"
              className="tp-btn tp-corners-sm tp-pixel-font block w-full py-3 text-center"
              style={{ background: '#ffc107', color: '#14213d', fontSize: 9 }}
            >
              Mulai Premium - ¥980/bulan
            </Link>
          </div>
        )}

        <div>
          <p className="tp-pixel-font mb-3" style={{ fontSize: 9, color: '#2f7fe0' }}>
            RIWAYAT LATIHAN TERAKHIR
          </p>
          {progress.length === 0 ? (
            <div className="tp-card tp-corners-sm p-8 text-center bg-white">
              <p className="text-gray-400 text-sm">Belum ada riwayat latihan.</p>
              <Link
                href="/quiz?type=kariamen"
                className="inline-block mt-3 text-sm font-semibold hover:underline"
                style={{ color: '#2f7fe0' }}
              >
                Mulai latihan sekarang
              </Link>
            </div>
          ) : (
            <div className="tp-card tp-corners-sm bg-white px-4">
              {progress.slice(0, 10).map((item) => (
                <ProgressItem key={item.id} item={item} />
              ))}
              {progress.length > 10 && (
                <p className="text-xs text-center text-gray-400 py-3">
                  +{progress.length - 10} riwayat lainnya
                </p>
              )}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}