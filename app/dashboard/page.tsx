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
    <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-4 flex items-center gap-3">
      <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${color}`}>
        {icon}
      </div>
      <div>
        <p className="text-2xl font-black text-gray-900">{value}</p>
        <p className="text-xs text-gray-500">{label}</p>
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
    <div className="flex items-center gap-3 py-3 border-b border-gray-50 last:border-0">
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
        className={`flex-shrink-0 text-xs font-bold px-2 py-0.5 rounded-full ${
          item.is_correct
            ? 'bg-green-100 text-green-700'
            : 'bg-red-100 text-red-600'
        }`}
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
      color: 'from-blue-500 to-indigo-600',
      badge: null as string | null,
    },
    {
      title: 'Honmen',
      desc: 'Ujian SIM Resmi - 95 soal - 50 menit',
      href: isPremium ? '/quiz?type=honmen' : '#',
      color: 'from-purple-500 to-pink-600',
      badge: isPremium ? null : 'Premium',
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-indigo-50">
      <nav className="sticky top-0 z-10 bg-white/80 backdrop-blur-md border-b border-gray-100">
        <div className="max-w-2xl mx-auto px-4 h-14 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-indigo-600 rounded-xl flex items-center justify-center">
              <span className="text-white font-black text-sm">免</span>
            </div>
            <span className="font-extrabold text-gray-900">TokkiPass</span>
          </div>
          <div className="flex items-center gap-3">
            {isPremium ? (
              <span className="text-xs font-bold bg-gradient-to-r from-amber-400 to-orange-500 text-white px-2.5 py-1 rounded-full flex items-center gap-1">
                <Star className="w-3 h-3" /> Premium
              </span>
            ) : (
              <Link
                href="/checkout"
                className="text-xs font-bold bg-indigo-600 text-white px-3 py-1.5 rounded-full hover:bg-indigo-700 transition-colors"
              >
                Upgrade
              </Link>
            )}
            <form action="/auth/signout" method="post">
              <button
                type="submit"
                className="text-gray-400 hover:text-gray-600 transition-colors"
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
          <h1 className="text-2xl font-extrabold text-gray-900">
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
            icon={<Clock className="w-5 h-5 text-purple-600" />}
            label="Sesi Latihan"
            value={Math.ceil(totalAttempted / 10)}
            color="bg-purple-50"
          />
        </div>

        {totalAttempted >= 10 && (
          <div
            className={`rounded-2xl p-4 flex items-center gap-3 ${
              accuracy >= 90
                ? 'bg-green-50 border border-green-200'
                : 'bg-amber-50 border border-amber-200'
            }`}
          >
            <span className="text-2xl">{accuracy >= 90 ? '🎉' : '📚'}</span>
            <div>
              <p className="font-bold text-sm text-gray-800">
                {accuracy >= 90
                  ? 'Kamu siap ujian!'
                  : 'Terus berlatih!'}
              </p>
              <p className="text-xs text-gray-500">
                Batas lulus ujian Jepang: 90%. Akurasi kamu:{' '}
                <strong>{accuracy}%</strong>
              </p>
            </div>
          </div>
        )}

        <div>
          <h2 className="text-base font-bold text-gray-700 mb-3">
            Pilih Mode Ujian
          </h2>
          <div className="space-y-3">
            {examModes.map((mode) => (
              <Link
                key={mode.title}
                href={mode.href}
                className={`group flex items-center justify-between p-4 rounded-2xl bg-gradient-to-r ${mode.color} text-white shadow-lg hover:shadow-xl active:scale-[0.98] transition-all duration-200`}
              >
                <div>
                  <div className="flex items-center gap-2">
                    <p className="font-extrabold text-base">{mode.title}</p>
                    {mode.badge && (
                      <span className="text-xs bg-white/20 backdrop-blur-sm px-2 py-0.5 rounded-full flex items-center gap-1">
                        <Star className="w-2.5 h-2.5" />
                        {mode.badge}
                      </span>
                    )}
                  </div>
                  <p className="text-white/80 text-xs mt-0.5">{mode.desc}</p>
                </div>
                <ChevronRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
              </Link>
            ))}
          </div>
        </div>

        {!isPremium && (
          <div className="bg-gradient-to-br from-indigo-600 to-purple-700 rounded-2xl p-5 text-white">
            <div className="flex items-start gap-3 mb-4">
              <Zap className="w-6 h-6 text-amber-300 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-extrabold">Unlock Premium</p>
                <p className="text-indigo-200 text-sm mt-0.5">
                  500+ soal jebakan, pembahasan mendalam, dan simulasi ujian realistis
                </p>
              </div>
            </div>
            <Link
              href="/checkout"
              className="block w-full py-3 bg-white text-indigo-700 font-bold text-center rounded-xl hover:bg-indigo-50 active:scale-[0.98] transition-all"
            >
              Mulai Premium - ¥980/bulan
            </Link>
          </div>
        )}

        <div>
          <h2 className="text-base font-bold text-gray-700 mb-3">
            Riwayat Latihan Terakhir
          </h2>
          {progress.length === 0 ? (
            <div className="bg-white rounded-2xl border border-gray-100 p-8 text-center">
              <p className="text-gray-400 text-sm">Belum ada riwayat latihan.</p>
              <Link
                href="/quiz?type=kariamen"
                className="inline-block mt-3 text-sm text-indigo-600 font-semibold hover:underline"
              >
                Mulai latihan sekarang
              </Link>
            </div>
          ) : (
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm px-4">
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
