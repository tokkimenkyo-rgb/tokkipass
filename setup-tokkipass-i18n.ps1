# ============================================================
# setup-tokkipass-i18n.ps1
# Tahap 2: Multi-language support (9 bahasa) + rename ke TokkiPass
#
# JALANKAN SETELAH setup-tokkipass.ps1 (tahap 1) sudah dijalankan.
#
# CARA PAKAI:
# 1. Pastikan posisi terminal di folder project:
#    cd C:\Users\abdul\Documents\Menkyo\tokkipass
# 2. Jalankan:
#    powershell -ExecutionPolicy Bypass -File setup-tokkipass-i18n.ps1
# ============================================================

Write-Host "Install next-intl..." -ForegroundColor Cyan
npm install next-intl

Write-Host "Membuat folder tambahan..." -ForegroundColor Cyan
$folders = @("i18n", "messages", "components\ui", "app\api\set-locale")
foreach ($f in $folders) {
    New-Item -ItemType Directory -Force -Path $f | Out-Null
}

Write-Host "Membuat file i18n & types..." -ForegroundColor Cyan

# ============================================================
# i18n/config.ts
# ============================================================
Set-Content -Encoding UTF8 -Path "i18n\config.ts" -Value @'
export const LOCALES = [
  'en', 'ja', 'id', 'zh', 'vi', 'ko', 'tl', 'pt', 'ne'
] as const;

export type Locale = (typeof LOCALES)[number];

export const DEFAULT_LOCALE: Locale = 'en';

export const LOCALE_META: Record<
  Locale,
  { name: string; nativeName: string; flag: string; dir: 'ltr' | 'rtl' }
> = {
  en: { name: 'English',    nativeName: 'English',      flag: '🇬🇧', dir: 'ltr' },
  ja: { name: 'Japanese',   nativeName: '日本語',        flag: '🇯🇵', dir: 'ltr' },
  id: { name: 'Indonesian', nativeName: 'Indonesia',    flag: '🇮🇩', dir: 'ltr' },
  zh: { name: 'Chinese',    nativeName: '中文',          flag: '🇨🇳', dir: 'ltr' },
  vi: { name: 'Vietnamese', nativeName: 'Tiếng Việt',   flag: '🇻🇳', dir: 'ltr' },
  ko: { name: 'Korean',     nativeName: '한국어',         flag: '🇰🇷', dir: 'ltr' },
  tl: { name: 'Filipino',   nativeName: 'Filipino',     flag: '🇵🇭', dir: 'ltr' },
  pt: { name: 'Portuguese', nativeName: 'Português',    flag: '🇧🇷', dir: 'ltr' },
  ne: { name: 'Nepali',     nativeName: 'नेपाली',        flag: '🇳🇵', dir: 'ltr' },
};

export const COUNTRY_TO_LOCALE: Record<string, Locale> = {
  GB: 'en', US: 'en', AU: 'en',
  JP: 'ja',
  ID: 'id',
  CN: 'zh', TW: 'zh', HK: 'zh',
  VN: 'vi',
  KR: 'ko',
  PH: 'tl',
  BR: 'pt', PT: 'pt',
  NP: 'ne',
};
'@

Write-Host "  - i18n/config.ts OK" -ForegroundColor Green

# ============================================================
# i18n/request.ts
# ============================================================
Set-Content -Encoding UTF8 -Path "i18n\request.ts" -Value @'
import { getRequestConfig } from 'next-intl/server';
import { cookies } from 'next/headers';
import { DEFAULT_LOCALE, LOCALES, type Locale } from './config';

export default getRequestConfig(async () => {
  const cookieStore = await cookies();
  const cookieLocale = cookieStore.get('tokkipass-locale')?.value;

  const locale: Locale =
    cookieLocale && (LOCALES as readonly string[]).includes(cookieLocale)
      ? (cookieLocale as Locale)
      : DEFAULT_LOCALE;

  return {
    locale,
    messages: (await import(`../messages/${locale}.json`)).default,
  };
});
'@

Write-Host "  - i18n/request.ts OK" -ForegroundColor Green

# ============================================================
# next.config.ts (overwrite)
# ============================================================
Set-Content -Encoding UTF8 -Path "next.config.ts" -Value @'
import type { NextConfig } from 'next';
import createNextIntlPlugin from 'next-intl/plugin';

const withNextIntl = createNextIntlPlugin('./i18n/request.ts');

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.supabase.co',
      },
    ],
  },
};

export default withNextIntl(nextConfig);
'@

Write-Host "  - next.config.ts OK (overwritten)" -ForegroundColor Green

# ============================================================
# middleware.ts (overwrite - gabung auth guard + locale detect)
# ============================================================
Set-Content -Encoding UTF8 -Path "middleware.ts" -Value @'
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
import {
  LOCALES,
  DEFAULT_LOCALE,
  COUNTRY_TO_LOCALE,
  type Locale,
} from './i18n/config';

const PROTECTED_ROUTES = ['/dashboard', '/quiz'];
const AUTH_ROUTES = ['/login', '/register'];

function detectLocale(request: NextRequest): Locale {
  const cookieLocale = request.cookies.get('tokkipass-locale')?.value;
  if (cookieLocale && (LOCALES as readonly string[]).includes(cookieLocale)) {
    return cookieLocale as Locale;
  }

  const acceptLang = request.headers.get('accept-language') ?? '';
  const preferred = acceptLang
    .split(',')
    .map((l) => l.split(';')[0].trim().toLowerCase().slice(0, 2));

  for (const lang of preferred) {
    if ((LOCALES as readonly string[]).includes(lang)) {
      return lang as Locale;
    }
  }

  const country = request.headers.get('cf-ipcountry') ?? '';
  if (country && COUNTRY_TO_LOCALE[country]) {
    return COUNTRY_TO_LOCALE[country];
  }

  return DEFAULT_LOCALE;
}

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return request.cookies.getAll(); },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          );
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  const { data: { user } } = await supabase.auth.getUser();
  const { pathname } = request.nextUrl;

  if (!request.cookies.get('tokkipass-locale')) {
    const detectedLocale = detectLocale(request);
    supabaseResponse.cookies.set('tokkipass-locale', detectedLocale, {
      path: '/',
      maxAge: 60 * 60 * 24 * 365,
      sameSite: 'lax',
    });
  }

  const isProtected = PROTECTED_ROUTES.some((r) => pathname.startsWith(r));
  if (isProtected && !user) {
    const loginUrl = request.nextUrl.clone();
    loginUrl.pathname = '/login';
    loginUrl.searchParams.set('redirectTo', pathname);
    return NextResponse.redirect(loginUrl);
  }

  const isAuthPage = AUTH_ROUTES.some((r) => pathname.startsWith(r));
  if (isAuthPage && user) {
    const dashUrl = request.nextUrl.clone();
    dashUrl.pathname = '/dashboard';
    return NextResponse.redirect(dashUrl);
  }

  return supabaseResponse;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
};
'@

Write-Host "  - middleware.ts OK (overwritten, gabung auth + locale)" -ForegroundColor Green

# ============================================================
# components/ui/LanguageSwitcher.tsx
# ============================================================
Set-Content -Encoding UTF8 -Path "components\ui\LanguageSwitcher.tsx" -Value @'
'use client';

import { useState, useRef, useEffect, useTransition } from 'react';
import { Globe, Check, ChevronDown } from 'lucide-react';
import { LOCALES, LOCALE_META, type Locale } from '@/i18n/config';

interface LanguageSwitcherProps {
  currentLocale: Locale;
  variant?: 'navbar' | 'standalone';
}

export function LanguageSwitcher({
  currentLocale,
  variant = 'navbar',
}: LanguageSwitcherProps) {
  const [open, setOpen] = useState(false);
  const [isPending, startTransition] = useTransition();
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  function handleSelect(locale: Locale) {
    setOpen(false);
    startTransition(async () => {
      await fetch('/api/set-locale', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ locale }),
      });
      window.location.reload();
    });
  }

  const current = LOCALE_META[currentLocale];

  return (
    <div ref={ref} className="relative">
      <button
        onClick={() => setOpen((v) => !v)}
        disabled={isPending}
        className={`flex items-center gap-1.5 text-sm transition-colors ${
          variant === 'navbar'
            ? 'text-gray-500 hover:text-gray-800 px-2 py-1.5 rounded-lg hover:bg-gray-100'
            : 'bg-white border border-gray-200 text-gray-700 px-3 py-2 rounded-xl hover:bg-gray-50'
        }`}
        aria-label="Select language"
        aria-expanded={open}
        aria-haspopup="listbox"
      >
        {isPending ? (
          <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3"
              strokeDasharray="40" strokeDashoffset="10" />
          </svg>
        ) : (
          <Globe className="w-4 h-4" />
        )}
        <span>{current.flag} {current.nativeName}</span>
        <ChevronDown
          className={`w-3 h-3 transition-transform ${open ? 'rotate-180' : ''}`}
        />
      </button>

      {open && (
        <div
          role="listbox"
          aria-label="Select language"
          className="absolute right-0 top-full mt-1.5 w-52 bg-white border border-gray-200 rounded-2xl shadow-xl overflow-hidden z-50"
        >
          <div className="py-1.5 max-h-80 overflow-y-auto">
            {LOCALES.map((locale) => {
              const meta = LOCALE_META[locale];
              const isSelected = locale === currentLocale;
              return (
                <button
                  key={locale}
                  role="option"
                  aria-selected={isSelected}
                  onClick={() => handleSelect(locale)}
                  className={`w-full flex items-center gap-3 px-3.5 py-2.5 text-left text-sm transition-colors ${
                    isSelected
                      ? 'bg-indigo-50 text-indigo-700'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <span className="text-base flex-shrink-0">{meta.flag}</span>
                  <span className="flex-1">
                    <span className="block font-medium">{meta.nativeName}</span>
                    <span className="block text-xs text-gray-400">{meta.name}</span>
                  </span>
                  {isSelected && (
                    <Check className="w-3.5 h-3.5 text-indigo-600 flex-shrink-0" />
                  )}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
'@

Write-Host "  - components/ui/LanguageSwitcher.tsx OK" -ForegroundColor Green

# ============================================================
# app/api/set-locale/route.ts
# ============================================================
Set-Content -Encoding UTF8 -Path "app\api\set-locale\route.ts" -Value @'
import { NextRequest, NextResponse } from 'next/server';
import { LOCALES } from '@/i18n/config';

export async function POST(req: NextRequest) {
  const { locale } = (await req.json()) as { locale: string };

  if (!(LOCALES as readonly string[]).includes(locale)) {
    return NextResponse.json({ error: 'Invalid locale' }, { status: 400 });
  }

  const response = NextResponse.json({ ok: true });
  response.cookies.set('tokkipass-locale', locale, {
    path: '/',
    maxAge: 60 * 60 * 24 * 365,
    sameSite: 'lax',
    httpOnly: false,
  });

  return response;
}
'@

Write-Host "  - app/api/set-locale/route.ts OK" -ForegroundColor Green

# ============================================================
# types/database.types.ts (overwrite - Question multi-language)
# ============================================================
Set-Content -Encoding UTF8 -Path "types\database.types.ts" -Value @'
import type { Locale } from '@/i18n/config';

export type AccountTierType = 'free' | 'premium';
export type ExamType = 'kariamen' | 'honmen';

export interface Profile {
  id: string;
  full_name: string | null;
  tier: AccountTierType;
  updated_at: string | null;
}

export interface Question {
  id: string;
  question_code: string;
  type: ExamType;
  question_text_en: string;
  question_text_ja: string;
  question_text_id: string;
  explanation_en: string;
  explanation_ja: string;
  explanation_id: string;
  explanation_zh: string | null;
  explanation_vi: string | null;
  explanation_ko: string | null;
  explanation_tl: string | null;
  explanation_pt: string | null;
  explanation_ne: string | null;
  image_url: string | null;
  correct_answer: boolean;
  is_premium: boolean;
}

export function getQuestionText(q: Question, locale: Locale): string {
  if (locale === 'ja' && q.question_text_ja) return q.question_text_ja;
  if (locale === 'id' && q.question_text_id) return q.question_text_id;
  return q.question_text_en;
}

export function getExplanation(q: Question, locale: Locale): string {
  const key = `explanation_${locale}` as keyof Question;
  const val = q[key] as string | null;
  return val ?? q.explanation_en;
}

export interface UserProgress {
  id: string;
  user_id: string;
  question_id: string;
  user_answer: boolean;
  is_correct: boolean;
  created_at: string;
}

export type InsertProfile = Omit<Profile, 'updated_at'>;

export type InsertUserProgress = Omit<UserProgress, 'id' | 'created_at'>;

export interface QuizState {
  questions: Question[];
  currentIndex: number;
  score: number;
  answers: Record<string, boolean | null>;
  isFinished: boolean;
  isAnswered: boolean;
  showExplanation: boolean;
  showPaywall: boolean;
}

export type QuizAction =
  | { type: 'ANSWER'; questionId: string; answer: boolean }
  | { type: 'NEXT_QUESTION' }
  | { type: 'SHOW_PAYWALL' }
  | { type: 'FINISH_QUIZ' }
  | { type: 'RESET_QUIZ' };

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: InsertProfile;
        Update: Partial<Profile>;
      };
      questions: {
        Row: Question;
        Insert: Omit<Question, 'id'>;
        Update: Partial<Question>;
      };
      user_progress: {
        Row: UserProgress;
        Insert: InsertUserProgress;
        Update: Partial<UserProgress>;
      };
    };
    Enums: {
      account_tier_type: AccountTierType;
      exam_type: ExamType;
    };
  };
}
'@

Write-Host "  - types/database.types.ts OK (overwritten, multi-language Question)" -ForegroundColor Green

# ============================================================
# lib/sample-questions.ts (overwrite - multi-language, 10 soal lengkap)
# ============================================================
Set-Content -Encoding UTF8 -Path "lib\sample-questions.ts" -Value @'
import type { Question } from '@/types/database.types';

export const SAMPLE_QUESTIONS: Question[] = [
  {
    id: 'q-001',
    question_code: 'KM-001',
    type: 'kariamen',
    is_premium: false,
    correct_answer: true,
    image_url: null,
    question_text_en:
      'When a police officer stands at an intersection with both arms extended horizontally to the sides, all vehicles from every direction must stop.',
    question_text_ja:
      '警察官が交差点で両腕を横（水平）に伸ばして立っているとき、すべての方向の車は停止しなければならない。',
    question_text_id:
      'Ketika polisi berdiri di persimpangan dengan kedua tangan terentang ke samping (horizontal), semua kendaraan dari segala arah harus berhenti.',
    explanation_en:
      'Correct. A police officer with arms extended horizontally signals a full red light for ALL directions. No direction is permitted to proceed. This overrides any traffic signal currently showing.',
    explanation_ja:
      '正解。警察官の両腕水平は全方向停止を意味します。交通信号よりも警察官の手信号が優先されます。',
    explanation_id:
      'Benar. Tangan horizontal = semua arah berhenti, setara lampu merah penuh. Isyarat polisi selalu mengalahkan lampu lalu lintas.',
    explanation_zh:
      '正确。警察双臂水平伸展表示所有方向停车,无论交通信号灯显示什么,都必须服从警察的手势信号。',
    explanation_vi:
      'Đúng. Cảnh sát giang tay ngang có nghĩa là tất cả các hướng phải dừng lại - tín hiệu của cảnh sát luôn ưu tiên hơn đèn giao thông.',
    explanation_ko:
      '정답. 경찰관이 양팔을 수평으로 뻗으면 모든 방향 정지 신호입니다. 신호등보다 경찰관 수신호가 우선합니다.',
    explanation_tl:
      'Tama. Ang pulis na nakabukas ang mga braso nang pahalang ay nangangahulugang hinto para sa lahat ng direksyon, mas mahalaga ito kaysa sa traffic lights.',
    explanation_pt:
      'Correto. Policial com bracos estendidos horizontalmente significa parada total em todas as direcoes - o sinal do policial tem prioridade sobre o semaforo.',
    explanation_ne:
      'सही छ। प्रहरीले दुवै हात तेर्सो फैलाएको अवस्थामा सबै दिशाबाट गाडी रोक्नुपर्छ, ट्राफिक लाइटभन्दा प्रहरीको संकेत प्राथमिकतामा हुन्छ।',
  },
  {
    id: 'q-002',
    question_code: 'KM-002',
    type: 'kariamen',
    is_premium: false,
    correct_answer: true,
    image_url: null,
    question_text_en:
      'On a public road with no posted speed limit sign, the maximum speed for a regular passenger vehicle is 60 km/h.',
    question_text_ja:
      '速度制限の標識がない一般道路では、普通自動車の最高速度は時速60キロメートルである。',
    question_text_id:
      'Di jalan umum tanpa rambu batas kecepatan, kecepatan maksimum kendaraan penumpang biasa adalah 60 km/jam.',
    explanation_en:
      'Correct. This is the statutory speed - 60 km/h on public roads without a posted limit. Do not confuse with expressways (100 km/h default). The question specifies a regular public road.',
    explanation_ja:
      '正解。これは法定速度です。標識のない一般道路での最高速度は時速60km。高速道路（100km/h）と混同しないでください。',
    explanation_id:
      'Benar. Ini disebut kecepatan undang-undang (hoteisokudo). Tanpa rambu di jalan biasa = maksimum 60 km/jam. Jangan keliru dengan jalan tol (100 km/jam).',
    explanation_zh:
      '正确。这是法定速度,无限速标志的普通公路最高时速60公里。不要与高速公路(100公里/小时)混淆。',
    explanation_vi:
      'Đúng. Đây là tốc độ pháp định - 60 km/h trên đường công cộng không có biển giới hạn tốc độ. Không nhầm với đường cao tốc (100 km/h).',
    explanation_ko:
      '정답. 이것은 법정속도입니다. 속도 표지판이 없는 일반 도로에서 최고속도는 60km/h. 고속도로(100km/h)와 혼동하지 마세요.',
    explanation_tl:
      'Tama. Ito ang statutory speed - 60 km/h sa pampublikong daan na walang speed limit sign. Huwag paghalo sa expressway (100 km/h).',
    explanation_pt:
      'Correto. Esta e a velocidade legal - 60 km/h em vias publicas sem placa de limite. Nao confunda com rodovias (100 km/h).',
    explanation_ne:
      'सही छ। यो कानूनी गति हो, गति सीमाको साइन नभएको सार्वजनिक सडकमा अधिकतम ६० किमी/घण्टा। एक्सप्रेसवे (१०० किमी/घण्टा) सँग भ्रमित नगर्नुहोस्।',
  },
  {
    id: 'q-003',
    question_code: 'KM-003',
    type: 'kariamen',
    is_premium: true,
    correct_answer: false,
    image_url: null,
    question_text_en:
      'A 50 km/h speed limit sign posted on the roadside applies to all types of motor vehicles passing through that road, including large motorcycles.',
    question_text_ja:
      '道路脇に設置された時速50キロの速度制限標識は、大型自動二輪車を含む、その道路を通行するすべての種類の自動車に適用される。',
    question_text_id:
      'Rambu batas kecepatan 50 km/jam yang dipasang di tepi jalan berlaku untuk semua jenis kendaraan bermotor yang melintas di jalan tersebut, termasuk sepeda motor besar.',
    explanation_en:
      'SUBTLE TRAP: Large motorcycles follow the posted sign. But mopeds (under 50cc) are still capped at 30 km/h even when the sign shows 50. Read carefully which vehicle type the question refers to.',
    explanation_ja:
      'ひっかけ問題：大型自動二輪車は標識に従います。しかし原動機付自転車（50cc未満）は標識が50でも最高速度30km/hのままです。問題文がどの車両種別を指しているか注意して読みましょう。',
    explanation_id:
      'JEBAKAN HALUS: Motor besar mengikuti rambu. Tapi moped (di bawah 50cc) tetap punya batas maksimum 30 km/jam meskipun rambu menunjukkan 50. Baca baik-baik jenis kendaraan yang disebutkan pada soal.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-004',
    question_code: 'KM-004',
    type: 'kariamen',
    is_premium: true,
    correct_answer: true,
    image_url: null,
    question_text_en:
      "A police officer is standing at an intersection with one arm pointing straight up (vertical). The traffic light is green. The driver must still follow the police officer's signal and stop.",
    question_text_ja:
      '警察官が交差点で片腕を垂直に上げて立っている。信号は青（緑）を示している。運転者はそれでも警察官の合図に従い、停止しなければならない。',
    question_text_id:
      'Seorang polisi berdiri di persimpangan dengan satu tangan menunjuk ke atas (vertikal). Lampu lalu lintas menunjukkan hijau. Pengemudi tetap harus mengikuti isyarat polisi dan berhenti.',
    explanation_en:
      "Correct. A police officer's signal always overrides the traffic light. An arm pointing straight up is equivalent to a yellow signal. Priority order: police signal, traffic light, road sign, road markings.",
    explanation_ja:
      '正解。警察官の合図は常に信号よりも優先されます。腕を垂直に上げるのは黄色信号に相当します。優先順位：警察官の合図＞信号＞標識＞道路標示。',
    explanation_id:
      'Benar. Isyarat polisi selalu mengalahkan lampu lalu lintas. Tangan polisi menunjuk vertikal ke atas setara sinyal kuning. Urutan prioritas: isyarat polisi, sinyal lalu lintas, rambu, marka jalan.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-005',
    question_code: 'KM-005',
    type: 'kariamen',
    is_premium: true,
    correct_answer: false,
    image_url: null,
    question_text_en:
      "When about to overtake a bicycle traveling along the edge of the road, a car driver may overtake from the bicycle's left side to avoid disrupting oncoming traffic.",
    question_text_ja:
      '路肩を走行している自転車を追い越す際、対向車の流れを妨げないよう、自転車の左側から追い越してもよい。',
    question_text_id:
      'Saat akan mendahului sebuah sepeda yang sedang melaju di tepi jalan, pengemudi mobil boleh mendahului dari sisi kiri sepeda tersebut agar tidak mengganggu arus lalu lintas dari arah berlawanan.',
    explanation_en:
      'Incorrect. In Japan, motor vehicles must overtake from the RIGHT side. Overtaking from the left is prohibited except in very specific circumstances.',
    explanation_ja:
      '誤り。日本では自動車は右側から追い越さなければなりません。左側からの追い越しは、非常に限られた特定の状況を除き禁止されています。',
    explanation_id:
      'Salah. Di Jepang, kendaraan bermotor wajib mendahului dari sisi KANAN. Mendahului dari kiri dilarang kecuali kondisi tertentu yang sangat spesifik.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-006',
    question_code: 'KM-006',
    type: 'kariamen',
    is_premium: true,
    correct_answer: true,
    image_url: null,
    question_text_en:
      'In an area with a no-horn sign, drivers may still sound the horn if necessary to prevent an accident that is about to happen.',
    question_text_ja:
      '警笛禁止の標識がある区域でも、まさに起ころうとしている事故を防ぐために必要な場合は、運転者は警笛を鳴らしてもよい。',
    question_text_id:
      'Di area dengan rambu larangan klakson, pengemudi tetap boleh membunyikan klakson apabila diperlukan untuk mencegah kecelakaan yang akan terjadi secara langsung.',
    explanation_en:
      'Correct. Even where a no-horn sign is posted, using the horn is still permitted in emergencies to avoid a life-threatening accident.',
    explanation_ja:
      '正解。警笛禁止の標識があっても、命に関わる事故を避けるための緊急時にはクラクションの使用が認められています。',
    explanation_id:
      'Benar. Meskipun ada rambu dilarang klakson, penggunaan klakson tetap diperbolehkan dalam situasi darurat untuk menghindari kecelakaan yang mengancam nyawa.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-007',
    question_code: 'KM-007',
    type: 'kariamen',
    is_premium: true,
    correct_answer: false,
    image_url: null,
    question_text_en:
      'When about to overtake a vehicle near a pedestrian crossing, a driver may overtake as long as no pedestrian is currently crossing.',
    question_text_ja:
      '横断歩道付近で車両を追い越そうとする場合、その時点で歩行者が横断していなければ追い越してもよい。',
    question_text_id:
      'Ketika hendak mendahului kendaraan di dekat zebra cross, pengemudi boleh mendahului asalkan tidak ada pejalan kaki yang sedang menyeberang saat itu.',
    explanation_en:
      'Incorrect. Overtaking a vehicle near a pedestrian crossing is strictly prohibited, regardless of whether a pedestrian is crossing at that moment.',
    explanation_ja:
      '誤り。横断歩道付近での追い越しは、その時歩行者が横断しているかどうかにかかわらず、固く禁止されています。',
    explanation_id:
      'Salah. Mendahului kendaraan di sekitar zebra cross dilarang keras, terlepas ada atau tidaknya pejalan kaki yang menyeberang saat itu.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-008',
    question_code: 'KM-008',
    type: 'kariamen',
    is_premium: true,
    correct_answer: true,
    image_url: null,
    question_text_en:
      'A vehicle that has just been in an accident and stopped suddenly inside a tunnel must immediately turn on its hazard lights and place a warning triangle behind the vehicle.',
    question_text_ja:
      'トンネル内で事故に遭い急停止した車両は、直ちにハザードランプを点灯し、車両の後方に停止表示器材を設置しなければならない。',
    question_text_id:
      'Kendaraan yang baru saja mengalami kecelakaan dan berhenti mendadak di dalam terowongan wajib segera menyalakan lampu hazard dan menempatkan segitiga pengaman di belakang kendaraan.',
    explanation_en:
      'Correct. Inside a tunnel, a stopped vehicle must turn on its hazard lights and set up a warning triangle. This requirement applies in tunnels and on expressways.',
    explanation_ja:
      '正解。トンネル内で停止した車両はハザードランプを点灯し、停止表示器材を設置する義務があります。この義務はトンネル内と高速道路で適用されます。',
    explanation_id:
      'Benar. Di dalam terowongan, kendaraan yang berhenti wajib menyalakan hazard dan memasang segitiga pengaman. Kewajiban ini berlaku di terowongan dan jalan tol.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-009',
    question_code: 'KM-009',
    type: 'kariamen',
    is_premium: true,
    correct_answer: false,
    image_url: null,
    question_text_en:
      'A driver who sees a STOP sign must come to a complete stop exactly at the stop line, but if there is no stop line, the driver only needs to slow down to a low speed before entering the intersection.',
    question_text_ja:
      '「止まれ」の標識を見た運転者は停止線の直前で完全に停止しなければならないが、停止線がない場合は交差点に入る前に低速まで減速するだけでよい。',
    question_text_id:
      'Pengemudi yang melihat rambu STOP wajib berhenti sepenuhnya tepat di garis berhenti, namun jika tidak ada garis berhenti, pengemudi cukup memperlambat kendaraan hingga kecepatan rendah sebelum memasuki persimpangan.',
    explanation_en:
      'Incorrect. If there is a STOP sign but no stop line, the driver must still come to a complete stop, not merely slow down.',
    explanation_ja:
      '誤り。「止まれ」の標識があっても停止線がない場合でも、運転者は減速するだけでなく完全に停止しなければなりません。',
    explanation_id:
      'Salah. Jika ada rambu STOP tapi tidak ada garis berhenti, pengemudi tetap wajib berhenti sepenuhnya, bukan sekadar memperlambat.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
  {
    id: 'q-010',
    question_code: 'KM-010',
    type: 'kariamen',
    is_premium: true,
    correct_answer: true,
    image_url: null,
    question_text_en:
      'A vehicle traveling on a priority road does not need to give way to a vehicle emerging from a minor road, even if that vehicle already reached the intersection first.',
    question_text_ja:
      '優先道路を走行している車両は、他の車両が先に交差点に到達していたとしても、小さい道路から出てくる車両に道を譲る必要はない。',
    question_text_id:
      'Kendaraan yang sedang berjalan di jalan utama tidak perlu memberikan prioritas kepada kendaraan yang keluar dari jalan kecil, meskipun kendaraan tersebut sudah berada di persimpangan lebih dahulu.',
    explanation_en:
      'Correct. A vehicle on a priority road has a higher right of way than a vehicle entering from a minor road, regardless of who arrived at the intersection first.',
    explanation_ja:
      '正解。優先道路上の車両は、どちらが先に交差点に到達したかに関わらず、小さな道路から進入する車両よりも優先的な通行権を持ちます。',
    explanation_id:
      'Benar. Kendaraan di jalan prioritas memiliki hak lewat lebih tinggi dari kendaraan yang masuk dari jalan kecil, terlepas dari siapa yang lebih dulu tiba di persimpangan.',
    explanation_zh: null,
    explanation_vi: null,
    explanation_ko: null,
    explanation_tl: null,
    explanation_pt: null,
    explanation_ne: null,
  },
];
'@

Write-Host "  - lib/sample-questions.ts OK (overwritten, 10 soal x 3 bahasa wajib)" -ForegroundColor Green

Write-Host "Membuat file messages (9 bahasa)..." -ForegroundColor Cyan

# ============================================================
# messages/en.json
# ============================================================
Set-Content -Encoding UTF8 -Path "messages\en.json" -Value @'
{
  "nav": { "brand": "TokkiPass", "tagline": "Japan Driver's License Exam", "login": "Sign in", "register": "Get started", "dashboard": "Dashboard", "logout": "Sign out" },
  "hero": { "eyebrow": "500+ official Japan exam questions", "headline": "Japan driving test got you stressed?", "headlineAccent": "Practice here first.", "sub": "Theory exam simulator for kariamen and honmen in your language. Every question comes with a deep explanation, not just right or wrong.", "demoLabel": "Try it now", "proofUsers": "active users", "proofPass": "pass rate", "demoFinishedTitle": "Demo complete!", "demoFinishedSub": "500+ trick questions are waiting for you.", "demoFinishedCta": "Access all questions free" },
  "quiz": { "question": "Question", "of": "of", "correct": "Correct!", "wrong": "Wrong answer", "correctAnswer": "Correct answer", "maru": "True", "batsu": "False", "next": "Next question", "seeResult": "See results", "score": "Score", "timer": "Time left", "expired": "Time's up", "kariamen": "Provisional license", "honmen": "Full license", "premium": "Premium", "restart": "Try again" },
  "result": { "passed": "You passed!", "failed": "Not quite there", "passedSub": "You're ready for the Japan driving test!", "failedSub": "Keep practicing, you'll get there!", "passMark": "Japan exam pass mark: 90%", "accuracy": "accuracy", "correct": "correct", "attempted": "attempted", "sessions": "sessions" },
  "paywall": { "title": "Premium question", "sub": "This question is only available to Premium users", "benefit1Title": "500+ trick questions", "benefit1Desc": "Full bank from official exams, updated regularly", "benefit2Title": "Deep explanations", "benefit2Desc": "Japan traffic law context per question", "benefit3Title": "Realistic exam mode", "benefit3Desc": "Kariamen and Honmen with timer and score report", "benefit4Title": "Pass guarantee", "benefit4Desc": "Thousands have passed using TokkiPass", "cta": "Upgrade to Premium", "continueFree": "Continue with free version" },
  "auth": { "loginTitle": "Welcome back", "loginSub": "Sign in to your account", "registerTitle": "Create free account", "registerSub": "Start practicing for your Japan driving test", "email": "Email", "password": "Password", "confirmPassword": "Confirm password", "fullName": "Full name", "loginCta": "Sign in", "registerCta": "Create account", "noAccount": "Don't have an account?", "hasAccount": "Already have an account?", "signUpFree": "Sign up free", "signIn": "Sign in", "checkEmail": "Check your email!", "checkEmailSub": "We sent a confirmation link to", "checkSpam": "Check spam if it doesn't arrive within 5 minutes.", "backToLogin": "Back to sign in", "passwordTooShort": "Password must be at least 8 characters", "passwordMismatch": "Passwords don't match", "nameRequired": "Full name is required", "invalidCredentials": "Invalid email or password", "emailNotConfirmed": "Email not confirmed. Check your inbox.", "alreadyRegistered": "This email is already registered. Sign in instead.", "weakPassword": "Too short", "fairPassword": "Fair", "goodPassword": "Good", "strongPassword": "Strong" },
  "dashboard": { "greeting": "Welcome back", "attempted": "Attempted", "accuracy": "Accuracy", "correct": "Correct", "sessions": "Sessions", "readyTitle": "You're ready!", "practiceMoreTitle": "Keep practicing!", "readySub": "Pass mark is 90%. Your accuracy:", "examModes": "Choose exam mode", "kariamenDesc": "Provisional license, 50 questions, 30 min", "honmenDesc": "Full license, 95 questions, 50 min", "recentHistory": "Recent practice history", "noHistory": "No practice history yet.", "startNow": "Start practicing now", "unlockPremium": "Unlock Premium", "premiumDesc": "500+ trick questions, deep explanations, realistic exam simulation", "premiumCta": "Start Premium" },
  "pricing": { "free": "Free", "premium": "Premium", "forever": "/ forever", "perMonth": "/ month", "mostPopular": "Most popular", "freeCta": "Get started free", "premiumCta": "Start Premium", "freeF1": "2 free kariamen questions", "freeF2": "Basic explanations", "freeF3": "500+ premium questions", "freeF4": "Honmen mode", "freeF5": "Progress tracking", "premiumF1": "500+ kariamen and honmen questions", "premiumF2": "Deep explanation per question", "premiumF3": "Realistic exam mode + timer", "premiumF4": "Full progress dashboard", "premiumF5": "New questions every month" },
  "checkout": { "title": "Upgrade to Premium", "sub": "Full access to all Japan driving exam questions", "perMonth": "/ month", "approx": "approx.", "cancelAnytime": "Cancel anytime", "payNow": "Pay now", "loading": "Loading payment gateway...", "preparing": "Preparing payment...", "secureNote": "Secured by Midtrans, Stripe, GoPay, QRIS, Bank Transfer", "successTitle": "Payment successful!", "successSub": "Your account has been upgraded to Premium.", "successCta": "Start Premium practice", "pendingTitle": "Awaiting payment", "pendingSub": "Your account will be upgraded automatically once payment is confirmed.", "failedTitle": "Payment failed", "failedSub": "Nothing was charged. Try again with a different payment method.", "tryAgain": "Try again" },
  "common": { "kariamen": "Kariamen", "honmen": "Honmen", "back": "Back", "loading": "Loading...", "error": "Something went wrong", "retry": "Retry", "close": "Close", "terms": "Terms of Service", "privacy": "Privacy Policy", "contact": "Contact", "copyright": "\u00a9 2026 TokkiPass" },
  "language": { "select": "Language", "en": "English", "ja": "\u65e5\u672c\u8a9e", "id": "Indonesia", "zh": "\u4e2d\u6587", "vi": "Ti\u1ebfng Vi\u1ec7t", "ko": "\ud55c\uad6d\uc5b4", "tl": "Filipino", "pt": "Portugu\u00eas", "ne": "\u0928\u0947\u092a\u093e\u0932\u0940" }
}
'@

Write-Host "  - messages/en.json OK" -ForegroundColor Green

# ============================================================
# messages/id.json
# ============================================================
Set-Content -Encoding UTF8 -Path "messages\id.json" -Value @'
{
  "nav": { "brand": "TokkiPass", "tagline": "Ujian Teori SIM Jepang", "login": "Masuk", "register": "Mulai gratis", "dashboard": "Dashboard", "logout": "Keluar" },
  "hero": { "eyebrow": "500+ soal ujian resmi Jepang", "headline": "Soal jebakan ujian SIM Jepang bikin pusing?", "headlineAccent": "Latihan dulu di sini.", "sub": "Simulator ujian teori kariamen dan honmen dalam bahasamu. Tiap soal ada penjelasan mendalam, bukan sekadar benar/salah.", "demoLabel": "Coba langsung", "proofUsers": "pengguna aktif", "proofPass": "tingkat kelulusan", "demoFinishedTitle": "Soal demo selesai!", "demoFinishedSub": "Masih ada 500+ soal jebakan menunggu.", "demoFinishedCta": "Akses semua soal gratis" },
  "quiz": { "question": "Soal", "of": "dari", "correct": "Jawaban Benar!", "wrong": "Jawaban Salah", "correctAnswer": "Jawaban benar", "maru": "Betul", "batsu": "Salah", "next": "Soal Berikutnya", "seeResult": "Lihat Hasil", "score": "Skor", "timer": "Sisa Waktu", "expired": "Waktu Habis", "kariamen": "Kariamen", "honmen": "Honmen", "premium": "Premium", "restart": "Coba Lagi" },
  "result": { "passed": "Lulus! Selamat!", "failed": "Belum Lulus", "passedSub": "Kamu siap menghadapi ujian SIM Jepang!", "failedSub": "Terus berlatih, kamu pasti bisa!", "passMark": "Batas lulus ujian Jepang: 90%", "accuracy": "akurasi", "correct": "benar", "attempted": "dikerjakan", "sessions": "sesi" },
  "paywall": { "title": "Soal Premium", "sub": "Soal ini hanya tersedia untuk pengguna Premium", "benefit1Title": "500+ Soal Jebakan", "benefit1Desc": "Bank soal lengkap dari ujian resmi, diperbarui rutin", "benefit2Title": "Penjelasan Mendalam", "benefit2Desc": "Konteks hukum lalin Jepang per soal", "benefit3Title": "Simulasi Ujian Realistis", "benefit3Desc": "Kariamen dan Honmen dengan timer dan laporan skor", "benefit4Title": "Garansi Lulus", "benefit4Desc": "Ribuan diaspora sudah lulus dengan TokkiPass", "cta": "Upgrade ke Premium Sekarang", "continueFree": "Lanjut dengan versi gratis" },
  "auth": { "loginTitle": "Selamat datang kembali", "loginSub": "Masuk ke akun kamu", "registerTitle": "Daftar Gratis", "registerSub": "Mulai latihan ujian SIM Jepang", "email": "Email", "password": "Password", "confirmPassword": "Konfirmasi Password", "fullName": "Nama Lengkap", "loginCta": "Masuk", "registerCta": "Daftar Sekarang", "noAccount": "Belum punya akun?", "hasAccount": "Sudah punya akun?", "signUpFree": "Daftar gratis", "signIn": "Masuk", "checkEmail": "Cek Email Kamu!", "checkEmailSub": "Link konfirmasi sudah dikirim ke", "checkSpam": "Cek folder Spam jika tidak muncul dalam 5 menit.", "backToLogin": "Kembali ke Login", "passwordTooShort": "Password minimal 8 karakter", "passwordMismatch": "Password dan konfirmasi tidak cocok", "nameRequired": "Nama lengkap wajib diisi", "invalidCredentials": "Email atau password salah", "emailNotConfirmed": "Email belum dikonfirmasi. Cek inbox kamu.", "alreadyRegistered": "Email ini sudah terdaftar. Silakan login.", "weakPassword": "Terlalu pendek", "fairPassword": "Cukup", "goodPassword": "Bagus", "strongPassword": "Kuat" },
  "dashboard": { "greeting": "Selamat datang", "attempted": "Dikerjakan", "accuracy": "Akurasi", "correct": "Benar", "sessions": "Sesi", "readyTitle": "Kamu siap ujian!", "practiceMoreTitle": "Terus berlatih!", "readySub": "Batas lulus 90%. Akurasi kamu:", "examModes": "Pilih Mode Ujian", "kariamenDesc": "Ujian SIM Sementara, 50 soal, 30 menit", "honmenDesc": "Ujian SIM Resmi, 95 soal, 50 menit", "recentHistory": "Riwayat Latihan Terakhir", "noHistory": "Belum ada riwayat latihan.", "startNow": "Mulai latihan sekarang", "unlockPremium": "Unlock Premium", "premiumDesc": "500+ soal jebakan, penjelasan mendalam, simulasi ujian realistis", "premiumCta": "Mulai Premium" },
  "pricing": { "free": "Gratis", "premium": "Premium", "forever": "/ selamanya", "perMonth": "/ bulan", "mostPopular": "Paling populer", "freeCta": "Mulai gratis", "premiumCta": "Mulai Premium", "freeF1": "2 soal gratis kariamen", "freeF2": "Penjelasan dasar", "freeF3": "500+ soal premium", "freeF4": "Mode honmen", "freeF5": "Lacak progres", "premiumF1": "500+ soal kariamen dan honmen", "premiumF2": "Penjelasan mendalam per soal", "premiumF3": "Mode ujian realistis + timer", "premiumF4": "Dashboard progres lengkap", "premiumF5": "Akses soal baru setiap bulan" },
  "checkout": { "title": "Upgrade ke Premium", "sub": "Akses penuh ke semua soal ujian SIM Jepang", "perMonth": "/ bulan", "approx": "sekitar", "cancelAnytime": "Batalkan kapan saja", "payNow": "Bayar Sekarang", "loading": "Memuat payment gateway...", "preparing": "Menyiapkan pembayaran...", "secureNote": "Pembayaran aman via Midtrans, GoPay, QRIS, Transfer Bank", "successTitle": "Pembayaran Berhasil!", "successSub": "Akun kamu sudah diupgrade ke Premium.", "successCta": "Mulai Latihan Premium", "pendingTitle": "Menunggu Pembayaran", "pendingSub": "Akun akan diupgrade otomatis setelah pembayaran dikonfirmasi.", "failedTitle": "Pembayaran Gagal", "failedSub": "Tidak ada yang dikenakan biaya. Coba lagi dengan metode lain.", "tryAgain": "Coba Lagi" },
  "common": { "kariamen": "Kariamen", "honmen": "Honmen", "back": "Kembali", "loading": "Memuat...", "error": "Terjadi kesalahan", "retry": "Coba lagi", "close": "Tutup", "terms": "Syarat & Ketentuan", "privacy": "Kebijakan Privasi", "contact": "Kontak", "copyright": "\u00a9 2026 TokkiPass" },
  "language": { "select": "Bahasa", "en": "English", "ja": "\u65e5\u672c\u8a9e", "id": "Indonesia", "zh": "\u4e2d\u6587", "vi": "Ti\u1ebfng Vi\u1ec7t", "ko": "\ud55c\uad6d\uc5b4", "tl": "Filipino", "pt": "Portugu\u00eas", "ne": "\u0928\u0947\u092a\u093e\u0932\u0940" }
}
'@

Write-Host "  - messages/id.json OK" -ForegroundColor Green

# ============================================================
# messages/ja.json (dilengkapi: dashboard, pricing, checkout)
# ============================================================
Set-Content -Encoding UTF8 -Path "messages\ja.json" -Value @'
{
  "nav": { "brand": "TokkiPass", "tagline": "運転免許学科試験", "login": "ログイン", "register": "無料で始める", "dashboard": "ダッシュボード", "logout": "ログアウト" },
  "hero": { "eyebrow": "公式試験問題500問以上", "headline": "学科試験に不安を感じていますか？", "headlineAccent": "ここで練習しましょう。", "sub": "仮免・本免の学科試験シミュレーター。各問題に詳しい解説付き。", "demoLabel": "今すぐ試す", "proofUsers": "アクティブユーザー", "proofPass": "合格率", "demoFinishedTitle": "デモ完了！", "demoFinishedSub": "500問以上の問題が待っています。", "demoFinishedCta": "全問題に無料アクセス" },
  "quiz": { "question": "問題", "of": "/", "correct": "正解！", "wrong": "不正解", "correctAnswer": "正解", "maru": "○（正しい）", "batsu": "✕（誤り）", "next": "次の問題", "seeResult": "結果を見る", "score": "スコア", "timer": "残り時間", "expired": "時間切れ", "kariamen": "仮免許", "honmen": "本免許", "premium": "プレミアム", "restart": "もう一度" },
  "result": { "passed": "合格！おめでとう！", "failed": "不合格", "passedSub": "運転免許試験の準備ができています！", "failedSub": "練習を続けましょう！", "passMark": "合格基準：90%", "accuracy": "正答率", "correct": "正解", "attempted": "挑戦", "sessions": "セッション" },
  "paywall": { "title": "プレミアム問題", "sub": "この問題はプレミアムユーザー限定です", "benefit1Title": "500問以上のひっかけ問題", "benefit1Desc": "公式試験からの完全な問題集", "benefit2Title": "詳しい解説", "benefit2Desc": "日本の道路交通法に基づく解説", "benefit3Title": "本番さながらの模擬試験", "benefit3Desc": "タイマー付き仮免・本免モード", "benefit4Title": "合格保証", "benefit4Desc": "多くの外国人がTokkiPassで合格", "cta": "プレミアムにアップグレード", "continueFree": "無料版を続ける" },
  "auth": { "loginTitle": "おかえりなさい", "loginSub": "アカウントにサインイン", "registerTitle": "無料アカウント作成", "registerSub": "学科試験の練習を始めましょう", "email": "メールアドレス", "password": "パスワード", "confirmPassword": "パスワード確認", "fullName": "氏名", "loginCta": "ログイン", "registerCta": "アカウントを作成", "noAccount": "アカウントをお持ちでない方は", "hasAccount": "すでにアカウントをお持ちの方は", "signUpFree": "無料登録", "signIn": "ログイン", "checkEmail": "メールをご確認ください！", "checkEmailSub": "確認リンクを送信しました：", "checkSpam": "5分以内に届かない場合はスパムフォルダをご確認ください。", "backToLogin": "ログインに戻る", "passwordTooShort": "パスワードは8文字以上", "passwordMismatch": "パスワードが一致しません", "nameRequired": "氏名は必須です", "invalidCredentials": "メールまたはパスワードが正しくありません", "emailNotConfirmed": "メールが未確認です。受信トレイを確認してください。", "alreadyRegistered": "このメールはすでに登録済みです。", "weakPassword": "短すぎる", "fairPassword": "普通", "goodPassword": "良い", "strongPassword": "強い" },
  "dashboard": { "greeting": "おかえりなさい", "attempted": "挑戦した問題数", "accuracy": "正答率", "correct": "正解数", "sessions": "セッション数", "readyTitle": "試験の準備ができています！", "practiceMoreTitle": "練習を続けましょう！", "readySub": "合格基準は90%です。あなたの正答率：", "examModes": "試験モードを選択", "kariamenDesc": "仮免許・50問・30分", "honmenDesc": "本免許・95問・50分", "recentHistory": "最近の練習履歴", "noHistory": "まだ練習履歴がありません。", "startNow": "今すぐ練習を始める", "unlockPremium": "プレミアムを解除", "premiumDesc": "500問以上のひっかけ問題、詳しい解説、本番さながらの模擬試験", "premiumCta": "プレミアムを始める" },
  "pricing": { "free": "無料", "premium": "プレミアム", "forever": "/ 永久", "perMonth": "/ 月", "mostPopular": "一番人気", "freeCta": "無料で始める", "premiumCta": "プレミアムを始める", "freeF1": "仮免問題2問無料", "freeF2": "基本的な解説", "freeF3": "プレミアム問題500問以上", "freeF4": "本免モード", "freeF5": "進捗トラッキング", "premiumF1": "仮免・本免問題500問以上", "premiumF2": "各問題の詳しい解説", "premiumF3": "本番さながらの試験モード＋タイマー", "premiumF4": "完全な進捗ダッシュボード", "premiumF5": "毎月新しい問題を追加" },
  "checkout": { "title": "プレミアムにアップグレード", "sub": "すべての日本運転免許試験問題にフルアクセス", "perMonth": "/ 月", "approx": "約", "cancelAnytime": "いつでもキャンセル可能", "payNow": "今すぐ支払う", "loading": "決済ゲートウェイを読み込み中...", "preparing": "支払いを準備中...", "secureNote": "Midtrans・Stripe・GoPay・QRIS・銀行振込で安全に保護されています", "successTitle": "支払い完了！", "successSub": "アカウントがプレミアムにアップグレードされました。", "successCta": "プレミアム練習を始める", "pendingTitle": "支払い確認待ち", "pendingSub": "支払いが確認され次第、アカウントは自動的にアップグレードされます。", "failedTitle": "支払いに失敗しました", "failedSub": "料金は発生していません。別の支払い方法でもう一度お試しください。", "tryAgain": "再試行" },
  "common": { "kariamen": "仮免許 (Kariamen)", "honmen": "本免許 (Honmen)", "back": "戻る", "loading": "読み込み中...", "error": "エラーが発生しました", "retry": "再試行", "close": "閉じる", "terms": "利用規約", "privacy": "プライバシーポリシー", "contact": "お問い合わせ", "copyright": "© 2026 TokkiPass" },
  "language": { "select": "言語", "en": "English", "ja": "日本語", "id": "Indonesia", "zh": "中文", "vi": "Tiếng Việt", "ko": "한국어", "tl": "Filipino", "pt": "Português", "ne": "नेपाली" }
}
'@

Write-Host "  - messages/ja.json OK (lengkap)" -ForegroundColor Green

# ============================================================
# messages/zh.json
# ============================================================
Set-Content -Encoding UTF8 -Path "messages\zh.json" -Value @'
{
  "nav": { "brand": "TokkiPass", "tagline": "日本驾照考试", "login": "登录", "register": "免费开始", "dashboard": "仪表盘", "logout": "退出登录" },
  "hero": { "eyebrow": "500+ 官方日本考试题", "headline": "日本驾照考试让你头疼？", "headlineAccent": "先在这里练习。", "sub": "仮免・本免学科考试模拟器，支持你的语言。每道题都有详细解释，而不仅仅是对错。", "demoLabel": "立即体验", "proofUsers": "活跃用户", "proofPass": "通过率", "demoFinishedTitle": "演示完成！", "demoFinishedSub": "还有500多道陷阱题等着你。", "demoFinishedCta": "免费获取全部题目" },
  "quiz": { "question": "问题", "of": "/", "correct": "回答正确！", "wrong": "回答错误", "correctAnswer": "正确答案", "maru": "对", "batsu": "错", "next": "下一题", "seeResult": "查看结果", "score": "得分", "timer": "剩余时间", "expired": "时间到", "kariamen": "临时驾照", "honmen": "正式驾照", "premium": "高级会员", "restart": "再试一次" },
  "result": { "passed": "通过了！恭喜！", "failed": "尚未通过", "passedSub": "你已准备好参加日本驾照考试！", "failedSub": "继续练习，你一定可以的！", "passMark": "日本考试及格线：90%", "accuracy": "正确率", "correct": "正确", "attempted": "已完成", "sessions": "练习次数" },
  "paywall": { "title": "高级题目", "sub": "此题目仅限高级会员使用", "benefit1Title": "500+ 陷阱题", "benefit1Desc": "来自官方考试的完整题库，定期更新", "benefit2Title": "深入解析", "benefit2Desc": "每道题都有日本交通法背景说明", "benefit3Title": "真实模拟考试", "benefit3Desc": "带计时器的临时驾照和正式驾照模式", "benefit4Title": "通过保证", "benefit4Desc": "已有数千人使用TokkiPass通过考试", "cta": "升级为高级会员", "continueFree": "继续使用免费版" },
  "auth": { "loginTitle": "欢迎回来", "loginSub": "登录你的账户", "registerTitle": "创建免费账户", "registerSub": "开始练习日本驾照考试", "email": "电子邮箱", "password": "密码", "confirmPassword": "确认密码", "fullName": "姓名", "loginCta": "登录", "registerCta": "创建账户", "noAccount": "还没有账户？", "hasAccount": "已经有账户？", "signUpFree": "免费注册", "signIn": "登录", "checkEmail": "请查收邮件！", "checkEmailSub": "确认链接已发送至", "checkSpam": "如果5分钟内未收到，请检查垃圾邮件文件夹。", "backToLogin": "返回登录", "passwordTooShort": "密码至少需要8个字符", "passwordMismatch": "两次密码不一致", "nameRequired": "请填写姓名", "invalidCredentials": "邮箱或密码错误", "emailNotConfirmed": "邮箱尚未验证，请查收邮箱。", "alreadyRegistered": "该邮箱已注册，请直接登录。", "weakPassword": "太短", "fairPassword": "一般", "goodPassword": "良好", "strongPassword": "强" },
  "dashboard": { "greeting": "欢迎回来", "attempted": "已完成", "accuracy": "正确率", "correct": "正确", "sessions": "练习次数", "readyTitle": "你已经准备好了！", "practiceMoreTitle": "继续加油练习！", "readySub": "及格线为90%。你的正确率：", "examModes": "选择考试模式", "kariamenDesc": "临时驾照 · 50题 · 30分钟", "honmenDesc": "正式驾照 · 95题 · 50分钟", "recentHistory": "最近练习记录", "noHistory": "暂无练习记录。", "startNow": "立即开始练习", "unlockPremium": "解锁高级会员", "premiumDesc": "500+ 陷阱题，深入解析，真实模拟考试", "premiumCta": "开通高级会员" },
  "pricing": { "free": "免费", "premium": "高级会员", "forever": "/ 永久", "perMonth": "/ 月", "mostPopular": "最受欢迎", "freeCta": "免费开始", "premiumCta": "开通高级会员", "freeF1": "2道免费临时驾照题", "freeF2": "基础解析", "freeF3": "500+ 高级题目", "freeF4": "正式驾照模式", "freeF5": "进度追踪", "premiumF1": "500+ 临时及正式驾照题目", "premiumF2": "每题深入解析", "premiumF3": "真实考试模式 + 计时器", "premiumF4": "完整进度仪表盘", "premiumF5": "每月更新新题目" },
  "checkout": { "title": "升级为高级会员", "sub": "全面访问所有日本驾照考试题目", "perMonth": "/ 月", "approx": "约", "cancelAnytime": "随时可取消", "payNow": "立即支付", "loading": "正在加载支付网关...", "preparing": "正在准备支付...", "secureNote": "由 Midtrans · Stripe · GoPay · QRIS · 银行转账 提供安全支付", "successTitle": "支付成功！", "successSub": "你的账户已升级为高级会员。", "successCta": "开始高级练习", "pendingTitle": "等待支付", "pendingSub": "支付确认后账户将自动升级。", "failedTitle": "支付失败", "failedSub": "未产生任何费用，请尝试其他支付方式。", "tryAgain": "重试" },
  "common": { "kariamen": "临时驾照 (仮免)", "honmen": "正式驾照 (本免)", "back": "返回", "loading": "加载中...", "error": "出现错误", "retry": "重试", "close": "关闭", "terms": "服务条款", "privacy": "隐私政策", "contact": "联系我们", "copyright": "© 2026 TokkiPass" },
  "language": { "select": "语言", "en": "English", "ja": "日本語", "id": "Indonesia", "zh": "中文", "vi": "Tiếng Việt", "ko": "한국어", "tl": "Filipino", "pt": "Português", "ne": "नेपाली" }
}
'@

Write-Host "  - messages/zh.json OK" -ForegroundColor Green

# ============================================================
# messages/vi.json
# ============================================================
Set-Content -Encoding UTF8 -Path "messages\vi.json" -Value @'
{
  "nav": { "brand": "TokkiPass", "tagline": "Kỳ thi bằng lái xe Nhật Bản", "login": "Đăng nhập", "register": "Bắt đầu miễn phí", "dashboard": "Bảng điều khiển", "logout": "Đăng xuất" },
  "hero": { "eyebrow": "500+ câu hỏi thi chính thức của Nhật", "headline": "Kỳ thi lái xe Nhật Bản khiến bạn căng thẳng?", "headlineAccent": "Hãy luyện tập ở đây trước.", "sub": "Trình mô phỏng thi lý thuyết kariamen và honmen bằng ngôn ngữ của bạn. Mỗi câu hỏi đều có giải thích chi tiết.", "demoLabel": "Thử ngay", "proofUsers": "người dùng hoạt động", "proofPass": "tỷ lệ đậu", "demoFinishedTitle": "Hoàn thành phần demo!", "demoFinishedSub": "Còn hơn 500 câu hỏi đánh lừa đang chờ bạn.", "demoFinishedCta": "Truy cập tất cả câu hỏi miễn phí" },
  "quiz": { "question": "Câu hỏi", "of": "/", "correct": "Chính xác!", "wrong": "Sai rồi", "correctAnswer": "Đáp án đúng", "maru": "Đúng", "batsu": "Sai", "next": "Câu tiếp theo", "seeResult": "Xem kết quả", "score": "Điểm số", "timer": "Thời gian còn lại", "expired": "Hết giờ", "kariamen": "Bằng lái tạm thời", "honmen": "Bằng lái chính thức", "premium": "Premium", "restart": "Thử lại" },
  "result": { "passed": "Đậu rồi! Chúc mừng!", "failed": "Chưa đậu", "passedSub": "Bạn đã sẵn sàng cho kỳ thi lái xe Nhật Bản!", "failedSub": "Tiếp tục luyện tập, bạn sẽ làm được!", "passMark": "Điểm đậu kỳ thi Nhật: 90%", "accuracy": "độ chính xác", "correct": "đúng", "attempted": "đã làm", "sessions": "phiên luyện tập" },
  "paywall": { "title": "Câu hỏi Premium", "sub": "Câu hỏi này chỉ dành cho người dùng Premium", "benefit1Title": "500+ câu hỏi đánh lừa", "benefit1Desc": "Ngân hàng câu hỏi đầy đủ từ kỳ thi chính thức", "benefit2Title": "Giải thích chuyên sâu", "benefit2Desc": "Bối cảnh luật giao thông Nhật Bản cho từng câu hỏi", "benefit3Title": "Mô phỏng thi thực tế", "benefit3Desc": "Chế độ Kariamen và Honmen có đồng hồ đếm giờ", "benefit4Title": "Đảm bảo đậu", "benefit4Desc": "Hàng ngàn người đã đậu nhờ TokkiPass", "cta": "Nâng cấp lên Premium", "continueFree": "Tiếp tục với bản miễn phí" },
  "auth": { "loginTitle": "Chào mừng trở lại", "loginSub": "Đăng nhập vào tài khoản của bạn", "registerTitle": "Tạo tài khoản miễn phí", "registerSub": "Bắt đầu luyện thi lái xe Nhật Bản", "email": "Email", "password": "Mật khẩu", "confirmPassword": "Xác nhận mật khẩu", "fullName": "Họ và tên", "loginCta": "Đăng nhập", "registerCta": "Tạo tài khoản", "noAccount": "Chưa có tài khoản?", "hasAccount": "Đã có tài khoản?", "signUpFree": "Đăng ký miễn phí", "signIn": "Đăng nhập", "checkEmail": "Kiểm tra email của bạn!", "checkEmailSub": "Chúng tôi đã gửi liên kết xác nhận đến", "checkSpam": "Kiểm tra thư mục spam nếu không thấy trong vòng 5 phút.", "backToLogin": "Quay lại đăng nhập", "passwordTooShort": "Mật khẩu phải có ít nhất 8 ký tự", "passwordMismatch": "Mật khẩu không khớp", "nameRequired": "Vui lòng nhập họ tên", "invalidCredentials": "Email hoặc mật khẩu không đúng", "emailNotConfirmed": "Email chưa được xác nhận.", "alreadyRegistered": "Email này đã được đăng ký. Vui lòng đăng nhập.", "weakPassword": "Quá ngắn", "fairPassword": "Tạm được", "goodPassword": "Tốt", "strongPassword": "Mạnh" },
  "dashboard": { "greeting": "Chào mừng trở lại", "attempted": "Đã làm", "accuracy": "Độ chính xác", "correct": "Đúng", "sessions": "Phiên luyện tập", "readyTitle": "Bạn đã sẵn sàng thi!", "practiceMoreTitle": "Tiếp tục luyện tập!", "readySub": "Điểm đậu là 90%. Độ chính xác của bạn:", "examModes": "Chọn chế độ thi", "kariamenDesc": "Bằng lái tạm thời · 50 câu · 30 phút", "honmenDesc": "Bằng lái chính thức · 95 câu · 50 phút", "recentHistory": "Lịch sử luyện tập gần đây", "noHistory": "Chưa có lịch sử luyện tập.", "startNow": "Bắt đầu luyện tập ngay", "unlockPremium": "Mở khóa Premium", "premiumDesc": "500+ câu hỏi đánh lừa, giải thích chuyên sâu", "premiumCta": "Bắt đầu Premium" },
  "pricing": { "free": "Miễn phí", "premium": "Premium", "forever": "/ mãi mãi", "perMonth": "/ tháng", "mostPopular": "Phổ biến nhất", "freeCta": "Bắt đầu miễn phí", "premiumCta": "Bắt đầu Premium", "freeF1": "2 câu hỏi kariamen miễn phí", "freeF2": "Giải thích cơ bản", "freeF3": "500+ câu hỏi premium", "freeF4": "Chế độ honmen", "freeF5": "Theo dõi tiến độ", "premiumF1": "500+ câu hỏi kariamen và honmen", "premiumF2": "Giải thích chuyên sâu từng câu", "premiumF3": "Chế độ thi thực tế + đồng hồ đếm giờ", "premiumF4": "Bảng điều khiển tiến độ đầy đủ", "premiumF5": "Câu hỏi mới mỗi tháng" },
  "checkout": { "title": "Nâng cấp lên Premium", "sub": "Truy cập đầy đủ tất cả câu hỏi thi lái xe Nhật Bản", "perMonth": "/ tháng", "approx": "khoảng", "cancelAnytime": "Hủy bất cứ lúc nào", "payNow": "Thanh toán ngay", "loading": "Đang tải cổng thanh toán...", "preparing": "Đang chuẩn bị thanh toán...", "secureNote": "Bảo mật bởi Midtrans, Stripe, GoPay, QRIS, Chuyển khoản ngân hàng", "successTitle": "Thanh toán thành công!", "successSub": "Tài khoản của bạn đã được nâng cấp lên Premium.", "successCta": "Bắt đầu luyện tập Premium", "pendingTitle": "Đang chờ thanh toán", "pendingSub": "Tài khoản sẽ tự động nâng cấp sau khi thanh toán được xác nhận.", "failedTitle": "Thanh toán thất bại", "failedSub": "Không có khoản phí nào bị tính. Hãy thử lại.", "tryAgain": "Thử lại" },
  "common": { "kariamen": "Kariamen (仮免)", "honmen": "Honmen (本免)", "back": "Quay lại", "loading": "Đang tải...", "error": "Đã xảy ra lỗi", "retry": "Thử lại", "close": "Đóng", "terms": "Điều khoản dịch vụ", "privacy": "Chính sách bảo mật", "contact": "Liên hệ", "copyright": "© 2026 TokkiPass" },
  "language": { "select": "Ngôn ngữ", "en": "English", "ja": "日本語", "id": "Indonesia", "zh": "中文", "vi": "Tiếng Việt", "ko": "한국어", "tl": "Filipino", "pt": "Português", "ne": "नेपाली" }
}
'@

Write-Host "  - messages/vi.json OK" -ForegroundColor Green

# ============================================================
# messages/ko.json
# ============================================================
Set-Content -Encoding UTF8 -Path "messages\ko.json" -Value @'
{
  "nav": { "brand": "TokkiPass", "tagline": "일본 운전면허 시험", "login": "로그인", "register": "무료로 시작하기", "dashboard": "대시보드", "logout": "로그아웃" },
  "hero": { "eyebrow": "공식 일본 시험 문제 500개 이상", "headline": "일본 운전면허 시험이 걱정되시나요?", "headlineAccent": "여기서 먼저 연습하세요.", "sub": "당신의 언어로 보는 가리멘・혼멘 학과시험 시뮬레이터. 모든 문제에 자세한 해설이 있습니다.", "demoLabel": "지금 체험하기", "proofUsers": "활성 사용자", "proofPass": "합격률", "demoFinishedTitle": "데모 완료!", "demoFinishedSub": "500개 이상의 함정 문제가 기다리고 있습니다.", "demoFinishedCta": "모든 문제 무료로 이용하기" },
  "quiz": { "question": "문제", "of": "/", "correct": "정답입니다!", "wrong": "오답입니다", "correctAnswer": "정답", "maru": "맞음", "batsu": "틀림", "next": "다음 문제", "seeResult": "결과 보기", "score": "점수", "timer": "남은 시간", "expired": "시간 종료", "kariamen": "가리면허", "honmen": "혼면허", "premium": "프리미엄", "restart": "다시 시도" },
  "result": { "passed": "합격! 축하합니다!", "failed": "아직 합격하지 못했습니다", "passedSub": "일본 운전면허 시험을 볼 준비가 되었습니다!", "failedSub": "계속 연습하면 할 수 있습니다!", "passMark": "일본 시험 합격 기준: 90%", "accuracy": "정답률", "correct": "정답", "attempted": "시도", "sessions": "연습 횟수" },
  "paywall": { "title": "프리미엄 문제", "sub": "이 문제는 프리미엄 사용자만 이용할 수 있습니다", "benefit1Title": "500개 이상의 함정 문제", "benefit1Desc": "공식 시험에서 나온 완전한 문제 은행", "benefit2Title": "심층 해설", "benefit2Desc": "문제마다 일본 교통법 배경 설명", "benefit3Title": "실전과 같은 모의고사", "benefit3Desc": "타이머가 있는 가리멘 및 혼멘 모드", "benefit4Title": "합격 보장", "benefit4Desc": "수천 명이 TokkiPass로 합격했습니다", "cta": "프리미엄으로 업그레이드", "continueFree": "무료 버전으로 계속하기" },
  "auth": { "loginTitle": "다시 오신 것을 환영합니다", "loginSub": "계정에 로그인하세요", "registerTitle": "무료 계정 만들기", "registerSub": "일본 운전면허 시험 연습을 시작하세요", "email": "이메일", "password": "비밀번호", "confirmPassword": "비밀번호 확인", "fullName": "이름", "loginCta": "로그인", "registerCta": "계정 만들기", "noAccount": "계정이 없으신가요?", "hasAccount": "이미 계정이 있으신가요?", "signUpFree": "무료 가입", "signIn": "로그인", "checkEmail": "이메일을 확인하세요!", "checkEmailSub": "확인 링크를 다음 주소로 보냈습니다:", "checkSpam": "5분 이내에 도착하지 않으면 스팸 폴더를 확인하세요.", "backToLogin": "로그인으로 돌아가기", "passwordTooShort": "비밀번호는 최소 8자 이상이어야 합니다", "passwordMismatch": "비밀번호가 일치하지 않습니다", "nameRequired": "이름을 입력해주세요", "invalidCredentials": "이메일 또는 비밀번호가 올바르지 않습니다", "emailNotConfirmed": "이메일이 확인되지 않았습니다.", "alreadyRegistered": "이미 등록된 이메일입니다.", "weakPassword": "너무 짧음", "fairPassword": "보통", "goodPassword": "좋음", "strongPassword": "강함" },
  "dashboard": { "greeting": "다시 오신 것을 환영합니다", "attempted": "시도한 문제", "accuracy": "정답률", "correct": "정답", "sessions": "연습 횟수", "readyTitle": "시험 준비가 되었습니다!", "practiceMoreTitle": "계속 연습하세요!", "readySub": "합격 기준은 90%입니다. 당신의 정답률:", "examModes": "시험 모드 선택", "kariamenDesc": "가리면허 · 50문제 · 30분", "honmenDesc": "혼면허 · 95문제 · 50분", "recentHistory": "최근 연습 기록", "noHistory": "아직 연습 기록이 없습니다.", "startNow": "지금 연습 시작하기", "unlockPremium": "프리미엄 잠금 해제", "premiumDesc": "500개 이상의 함정 문제, 심층 해설", "premiumCta": "프리미엄 시작하기" },
  "pricing": { "free": "무료", "premium": "프리미엄", "forever": "/ 평생", "perMonth": "/ 월", "mostPopular": "가장 인기", "freeCta": "무료로 시작하기", "premiumCta": "프리미엄 시작하기", "freeF1": "무료 가리멘 문제 2개", "freeF2": "기본 해설", "freeF3": "500개 이상의 프리미엄 문제", "freeF4": "혼멘 모드", "freeF5": "진행 상황 추적", "premiumF1": "500개 이상의 가리멘 및 혼멘 문제", "premiumF2": "문제별 심층 해설", "premiumF3": "실전 시험 모드 + 타이머", "premiumF4": "완전한 진행 상황 대시보드", "premiumF5": "매월 새로운 문제 제공" },
  "checkout": { "title": "프리미엄으로 업그레이드", "sub": "모든 일본 운전면허 시험 문제에 대한 전체 액세스", "perMonth": "/ 월", "approx": "약", "cancelAnytime": "언제든지 취소 가능", "payNow": "지금 결제하기", "loading": "결제 게이트웨이 로딩 중...", "preparing": "결제 준비 중...", "secureNote": "Midtrans, Stripe, GoPay, QRIS, 계좌이체로 안전하게 보호됩니다", "successTitle": "결제 성공!", "successSub": "계정이 프리미엄으로 업그레이드되었습니다.", "successCta": "프리미엄 연습 시작하기", "pendingTitle": "결제 대기 중", "pendingSub": "결제가 확인되면 계정이 자동으로 업그레이드됩니다.", "failedTitle": "결제 실패", "failedSub": "청구된 금액이 없습니다. 다시 시도하세요.", "tryAgain": "다시 시도" },
  "common": { "kariamen": "가리멘 (仮免)", "honmen": "혼멘 (本免)", "back": "뒤로", "loading": "로딩 중...", "error": "오류가 발생했습니다", "retry": "다시 시도", "close": "닫기", "terms": "이용약관", "privacy": "개인정보 처리방침", "contact": "문의하기", "copyright": "© 2026 TokkiPass" },
  "language": { "select": "언어", "en": "English", "ja": "日本語", "id": "Indonesia", "zh": "中文", "vi": "Tiếng Việt", "ko": "한국어", "tl": "Filipino", "pt": "Português", "ne": "नेपाली" }
}
'@

Write-Host "  - messages/ko.json OK" -ForegroundColor Green

# ============================================================
# messages/tl.json
# ============================================================
Set-Content -Encoding UTF8 -Path "messages\tl.json" -Value @'
{
  "nav": { "brand": "TokkiPass", "tagline": "Pagsusulit sa Lisensya sa Pagmamaneho ng Japan", "login": "Mag-sign in", "register": "Magsimula nang libre", "dashboard": "Dashboard", "logout": "Mag-sign out" },
  "hero": { "eyebrow": "500+ opisyal na tanong sa pagsusulit ng Japan", "headline": "Nakakastress ba ang pagsusulit sa pagmamaneho sa Japan?", "headlineAccent": "Mag-practice muna dito.", "sub": "Simulator ng theory exam para sa kariamen at honmen sa iyong sariling wika. Bawat tanong ay may malalim na paliwanag.", "demoLabel": "Subukan ngayon", "proofUsers": "aktibong users", "proofPass": "passing rate", "demoFinishedTitle": "Tapos na ang demo!", "demoFinishedSub": "May 500+ pang trick questions na naghihintay sa iyo.", "demoFinishedCta": "I-access lahat ng tanong nang libre" },
  "quiz": { "question": "Tanong", "of": "sa", "correct": "Tama!", "wrong": "Maling sagot", "correctAnswer": "Tamang sagot", "maru": "Tama", "batsu": "Mali", "next": "Susunod na tanong", "seeResult": "Tingnan ang resulta", "score": "Iskor", "timer": "Natitirang oras", "expired": "Naubos na ang oras", "kariamen": "Pansamantalang lisensya", "honmen": "Opisyal na lisensya", "premium": "Premium", "restart": "Subukan muli" },
  "result": { "passed": "Pumasa ka! Congrats!", "failed": "Hindi pa pumasa", "passedSub": "Handa ka na sa pagsusulit sa pagmamaneho sa Japan!", "failedSub": "Magpatuloy sa pag-practice, kaya mo yan!", "passMark": "Passing mark sa Japan: 90%", "accuracy": "accuracy", "correct": "tama", "attempted": "nasagutan", "sessions": "sessions" },
  "paywall": { "title": "Premium na Tanong", "sub": "Ang tanong na ito ay para lamang sa mga Premium user", "benefit1Title": "500+ Trick Questions", "benefit1Desc": "Kumpletong question bank mula sa opisyal na pagsusulit", "benefit2Title": "Malalim na Paliwanag", "benefit2Desc": "Konteksto ng batas trapiko ng Japan sa bawat tanong", "benefit3Title": "Makatotohanang Simulation", "benefit3Desc": "Kariamen at Honmen mode na may timer", "benefit4Title": "Guaranteed na Pumasa", "benefit4Desc": "Libu-libong diaspora na ang pumasa gamit ang TokkiPass", "cta": "I-upgrade sa Premium", "continueFree": "Magpatuloy sa libreng bersyon" },
  "auth": { "loginTitle": "Maligayang pagbabalik", "loginSub": "Mag-sign in sa iyong account", "registerTitle": "Gumawa ng libreng account", "registerSub": "Magsimulang mag-practice para sa pagsusulit sa pagmamaneho sa Japan", "email": "Email", "password": "Password", "confirmPassword": "Kumpirmahin ang password", "fullName": "Buong pangalan", "loginCta": "Mag-sign in", "registerCta": "Gumawa ng account", "noAccount": "Wala pang account?", "hasAccount": "May account ka na?", "signUpFree": "Mag-sign up nang libre", "signIn": "Mag-sign in", "checkEmail": "Tingnan ang iyong email!", "checkEmailSub": "Ipinadala namin ang confirmation link sa", "checkSpam": "Tingnan ang spam folder kung hindi dumating sa loob ng 5 minuto.", "backToLogin": "Bumalik sa sign in", "passwordTooShort": "Dapat hindi bababa sa 8 karakter ang password", "passwordMismatch": "Hindi tugma ang password", "nameRequired": "Kailangan ang buong pangalan", "invalidCredentials": "Maling email o password", "emailNotConfirmed": "Hindi pa nakumpirma ang email.", "alreadyRegistered": "Nakarehistro na ang email na ito.", "weakPassword": "Masyadong maikli", "fairPassword": "Katamtaman", "goodPassword": "Maganda", "strongPassword": "Malakas" },
  "dashboard": { "greeting": "Maligayang pagbabalik", "attempted": "Nasagutan", "accuracy": "Accuracy", "correct": "Tama", "sessions": "Sessions", "readyTitle": "Handa ka na sa exam!", "practiceMoreTitle": "Magpatuloy sa pag-practice!", "readySub": "Ang passing mark ay 90%. Ang iyong accuracy:", "examModes": "Pumili ng exam mode", "kariamenDesc": "Pansamantalang lisensya · 50 tanong · 30 minuto", "honmenDesc": "Opisyal na lisensya · 95 tanong · 50 minuto", "recentHistory": "Kamakailang history ng pag-practice", "noHistory": "Wala pang history ng pag-practice.", "startNow": "Magsimulang mag-practice ngayon", "unlockPremium": "I-unlock ang Premium", "premiumDesc": "500+ trick questions, malalim na paliwanag", "premiumCta": "Simulan ang Premium" },
  "pricing": { "free": "Libre", "premium": "Premium", "forever": "/ habang buhay", "perMonth": "/ buwan", "mostPopular": "Pinakasikat", "freeCta": "Magsimula nang libre", "premiumCta": "Simulan ang Premium", "freeF1": "2 libreng tanong sa kariamen", "freeF2": "Basic na paliwanag", "freeF3": "500+ premium na tanong", "freeF4": "Honmen mode", "freeF5": "Pag-track ng progress", "premiumF1": "500+ tanong sa kariamen at honmen", "premiumF2": "Malalim na paliwanag sa bawat tanong", "premiumF3": "Makatotohanang exam mode + timer", "premiumF4": "Kumpletong progress dashboard", "premiumF5": "Bagong tanong bawat buwan" },
  "checkout": { "title": "I-upgrade sa Premium", "sub": "Buong access sa lahat ng tanong sa pagsusulit sa pagmamaneho sa Japan", "perMonth": "/ buwan", "approx": "humigit-kumulang", "cancelAnytime": "Puwedeng kanselahin anumang oras", "payNow": "Magbayad ngayon", "loading": "Nilo-load ang payment gateway...", "preparing": "Inihahanda ang bayad...", "secureNote": "Ligtas sa pamamagitan ng Midtrans, Stripe, GoPay, QRIS, Bank Transfer", "successTitle": "Matagumpay ang bayad!", "successSub": "Na-upgrade na ang iyong account sa Premium.", "successCta": "Simulan ang Premium practice", "pendingTitle": "Naghihintay ng bayad", "pendingSub": "Awtomatikong ma-a-upgrade ang account kapag na-confirm na ang bayad.", "failedTitle": "Nabigo ang bayad", "failedSub": "Walang na-charge. Subukan ulit gamit ang ibang paraan.", "tryAgain": "Subukan muli" },
  "common": { "kariamen": "Kariamen (仮免)", "honmen": "Honmen (本免)", "back": "Bumalik", "loading": "Naglo-load...", "error": "May naganap na error", "retry": "Subukan muli", "close": "Isara", "terms": "Mga Tuntunin ng Serbisyo", "privacy": "Patakaran sa Privacy", "contact": "Makipag-ugnayan", "copyright": "© 2026 TokkiPass" },
  "language": { "select": "Wika", "en": "English", "ja": "日本語", "id": "Indonesia", "zh": "中文", "vi": "Tiếng Việt", "ko": "한국어", "tl": "Filipino", "pt": "Português", "ne": "नेपाली" }
}
'@

Write-Host "  - messages/tl.json OK" -ForegroundColor Green

# ============================================================
# messages/pt.json
# ============================================================
Set-Content -Encoding UTF8 -Path "messages\pt.json" -Value @'
{
  "nav": { "brand": "TokkiPass", "tagline": "Exame de Habilitação do Japão", "login": "Entrar", "register": "Comece grátis", "dashboard": "Painel", "logout": "Sair" },
  "hero": { "eyebrow": "500+ questões oficiais do exame japonês", "headline": "O exame de habilitação japonês está te estressando?", "headlineAccent": "Pratique aqui primeiro.", "sub": "Simulador de exame teórico kariamen e honmen no seu idioma. Cada questão vem com uma explicação detalhada.", "demoLabel": "Experimente agora", "proofUsers": "usuários ativos", "proofPass": "taxa de aprovação", "demoFinishedTitle": "Demonstração concluída!", "demoFinishedSub": "Mais de 500 questões traiçoeiras esperando por você.", "demoFinishedCta": "Acesse todas as questões grátis" },
  "quiz": { "question": "Questão", "of": "de", "correct": "Correto!", "wrong": "Resposta errada", "correctAnswer": "Resposta correta", "maru": "Verdadeiro", "batsu": "Falso", "next": "Próxima questão", "seeResult": "Ver resultados", "score": "Pontuação", "timer": "Tempo restante", "expired": "Tempo esgotado", "kariamen": "Licença provisória", "honmen": "Licença definitiva", "premium": "Premium", "restart": "Tentar novamente" },
  "result": { "passed": "Aprovado! Parabéns!", "failed": "Ainda não passou", "passedSub": "Você está pronto para o exame de habilitação japonês!", "failedSub": "Continue praticando, você vai conseguir!", "passMark": "Nota mínima do exame japonês: 90%", "accuracy": "precisão", "correct": "corretas", "attempted": "respondidas", "sessions": "sessões" },
  "paywall": { "title": "Questão Premium", "sub": "Esta questão está disponível apenas para usuários Premium", "benefit1Title": "500+ questões traiçoeiras", "benefit1Desc": "Banco completo de questões de exames oficiais", "benefit2Title": "Explicações detalhadas", "benefit2Desc": "Contexto da lei de trânsito japonesa em cada questão", "benefit3Title": "Simulação realista de exame", "benefit3Desc": "Modos Kariamen e Honmen com cronômetro", "benefit4Title": "Garantia de aprovação", "benefit4Desc": "Milhares já foram aprovados usando o TokkiPass", "cta": "Fazer upgrade para Premium", "continueFree": "Continuar com a versão grátis" },
  "auth": { "loginTitle": "Bem-vindo de volta", "loginSub": "Entre na sua conta", "registerTitle": "Criar conta grátis", "registerSub": "Comece a praticar para o exame de habilitação japonês", "email": "Email", "password": "Senha", "confirmPassword": "Confirmar senha", "fullName": "Nome completo", "loginCta": "Entrar", "registerCta": "Criar conta", "noAccount": "Não tem uma conta?", "hasAccount": "Já tem uma conta?", "signUpFree": "Cadastre-se grátis", "signIn": "Entrar", "checkEmail": "Verifique seu email!", "checkEmailSub": "Enviamos um link de confirmação para", "checkSpam": "Verifique a pasta de spam se não chegar em 5 minutos.", "backToLogin": "Voltar para o login", "passwordTooShort": "A senha deve ter pelo menos 8 caracteres", "passwordMismatch": "As senhas não coincidem", "nameRequired": "O nome completo é obrigatório", "invalidCredentials": "Email ou senha inválidos", "emailNotConfirmed": "Email não confirmado.", "alreadyRegistered": "Este email já está cadastrado.", "weakPassword": "Muito curta", "fairPassword": "Razoável", "goodPassword": "Boa", "strongPassword": "Forte" },
  "dashboard": { "greeting": "Bem-vindo de volta", "attempted": "Respondidas", "accuracy": "Precisão", "correct": "Corretas", "sessions": "Sessões", "readyTitle": "Você está pronto para o exame!", "practiceMoreTitle": "Continue praticando!", "readySub": "A nota mínima é 90%. Sua precisão:", "examModes": "Escolha o modo de exame", "kariamenDesc": "Licença provisória · 50 questões · 30 minutos", "honmenDesc": "Licença definitiva · 95 questões · 50 minutos", "recentHistory": "Histórico recente de prática", "noHistory": "Ainda não há histórico de prática.", "startNow": "Comece a praticar agora", "unlockPremium": "Desbloquear Premium", "premiumDesc": "500+ questões traiçoeiras, explicações detalhadas", "premiumCta": "Começar Premium" },
  "pricing": { "free": "Grátis", "premium": "Premium", "forever": "/ para sempre", "perMonth": "/ mês", "mostPopular": "Mais popular", "freeCta": "Comece grátis", "premiumCta": "Começar Premium", "freeF1": "2 questões grátis de kariamen", "freeF2": "Explicações básicas", "freeF3": "500+ questões premium", "freeF4": "Modo honmen", "freeF5": "Acompanhamento de progresso", "premiumF1": "500+ questões de kariamen e honmen", "premiumF2": "Explicação detalhada por questão", "premiumF3": "Modo de exame realista + cronômetro", "premiumF4": "Painel completo de progresso", "premiumF5": "Novas questões todo mês" },
  "checkout": { "title": "Fazer upgrade para Premium", "sub": "Acesso completo a todas as questões do exame de habilitação japonês", "perMonth": "/ mês", "approx": "aproximadamente", "cancelAnytime": "Cancele quando quiser", "payNow": "Pagar agora", "loading": "Carregando gateway de pagamento...", "preparing": "Preparando pagamento...", "secureNote": "Protegido por Midtrans, Stripe, GoPay, QRIS, Transferência bancária", "successTitle": "Pagamento aprovado!", "successSub": "Sua conta foi atualizada para Premium.", "successCta": "Começar prática Premium", "pendingTitle": "Aguardando pagamento", "pendingSub": "Sua conta será atualizada automaticamente assim que o pagamento for confirmado.", "failedTitle": "Pagamento falhou", "failedSub": "Nada foi cobrado. Tente novamente.", "tryAgain": "Tentar novamente" },
  "common": { "kariamen": "Kariamen (仮免)", "honmen": "Honmen (本免)", "back": "Voltar", "loading": "Carregando...", "error": "Algo deu errado", "retry": "Tentar novamente", "close": "Fechar", "terms": "Termos de Serviço", "privacy": "Política de Privacidade", "contact": "Contato", "copyright": "© 2026 TokkiPass" },
  "language": { "select": "Idioma", "en": "English", "ja": "日本語", "id": "Indonesia", "zh": "中文", "vi": "Tiếng Việt", "ko": "한국어", "tl": "Filipino", "pt": "Português", "ne": "नेपाली" }
}
'@

Write-Host "  - messages/pt.json OK" -ForegroundColor Green

# ============================================================
# messages/ne.json
# ============================================================
Set-Content -Encoding UTF8 -Path "messages\ne.json" -Value @'
{
  "nav": { "brand": "TokkiPass", "tagline": "जापान ड्राइभिङ लाइसेन्स परीक्षा", "login": "साइन इन गर्नुहोस्", "register": "नि:शुल्क सुरु गर्नुहोस्", "dashboard": "ड्यासबोर्ड", "logout": "साइन आउट गर्नुहोस्" },
  "hero": { "eyebrow": "५००+ आधिकारिक जापान परीक्षा प्रश्नहरू", "headline": "जापान ड्राइभिङ परीक्षाले तनाव दिइरहेको छ?", "headlineAccent": "पहिले यहाँ अभ्यास गर्नुहोस्।", "sub": "तपाईंको भाषामा कारिमेन र होन्मेन सिद्धान्त परीक्षा सिमुलेटर। हरेक प्रश्नमा गहिरो व्याख्या छ।", "demoLabel": "अहिले प्रयास गर्नुहोस्", "proofUsers": "सक्रिय प्रयोगकर्ताहरू", "proofPass": "उत्तीर्ण दर", "demoFinishedTitle": "डेमो सम्पन्न भयो!", "demoFinishedSub": "५००+ भ्रामक प्रश्नहरू तपाईंको पर्खाइमा छन्।", "demoFinishedCta": "सबै प्रश्नहरू नि:शुल्क पहुँच गर्नुहोस्" },
  "quiz": { "question": "प्रश्न", "of": "मध्ये", "correct": "सही!", "wrong": "गलत उत्तर", "correctAnswer": "सही उत्तर", "maru": "सही", "batsu": "गलत", "next": "अर्को प्रश्न", "seeResult": "नतिजा हेर्नुहोस्", "score": "अंक", "timer": "बाँकी समय", "expired": "समय सकियो", "kariamen": "अस्थायी लाइसेन्स", "honmen": "पूर्ण लाइसेन्स", "premium": "प्रिमियम", "restart": "फेरि प्रयास गर्नुहोस्" },
  "result": { "passed": "उत्तीर्ण! बधाई छ!", "failed": "अझै उत्तीर्ण भएको छैन", "passedSub": "तपाईं जापान ड्राइभिङ परीक्षाको लागि तयार हुनुहुन्छ!", "failedSub": "अभ्यास जारी राख्नुहोस्, तपाईं सफल हुनुहुनेछ!", "passMark": "जापान परीक्षा उत्तीर्ण अंक: ९०%", "accuracy": "शुद्धता", "correct": "सही", "attempted": "प्रयास गरिएको", "sessions": "सत्रहरू" },
  "paywall": { "title": "प्रिमियम प्रश्न", "sub": "यो प्रश्न केवल प्रिमियम प्रयोगकर्ताहरूको लागि उपलब्ध छ", "benefit1Title": "५००+ भ्रामक प्रश्नहरू", "benefit1Desc": "आधिकारिक परीक्षाबाट पूर्ण प्रश्न बैंक", "benefit2Title": "गहिरो व्याख्या", "benefit2Desc": "हरेक प्रश्नमा जापानी ट्राफिक कानूनको सन्दर्भ", "benefit3Title": "यथार्थवादी परीक्षा सिमुलेसन", "benefit3Desc": "टाइमरसहित कारिमेन र होन्मेन मोड", "benefit4Title": "उत्तीर्ण ग्यारेन्टी", "benefit4Desc": "हजारौंले TokkiPass प्रयोग गरी उत्तीर्ण भएका छन्", "cta": "प्रिमियममा अपग्रेड गर्नुहोस्", "continueFree": "नि:शुल्क संस्करणसँग जारी राख्नुहोस्" },
  "auth": { "loginTitle": "फेरि स्वागत छ", "loginSub": "आफ्नो खातामा साइन इन गर्नुहोस्", "registerTitle": "नि:शुल्क खाता बनाउनुहोस्", "registerSub": "जापान ड्राइभिङ परीक्षाको लागि अभ्यास सुरु गर्नुहोस्", "email": "इमेल", "password": "पासवर्ड", "confirmPassword": "पासवर्ड पुष्टि गर्नुहोस्", "fullName": "पूरा नाम", "loginCta": "साइन इन गर्नुहोस्", "registerCta": "खाता बनाउनुहोस्", "noAccount": "खाता छैन?", "hasAccount": "पहिले नै खाता छ?", "signUpFree": "नि:शुल्क साइन अप गर्नुहोस्", "signIn": "साइन इन गर्नुहोस्", "checkEmail": "आफ्नो इमेल जाँच गर्नुहोस्!", "checkEmailSub": "हामीले पुष्टिकरण लिङ्क पठाएका छौं:", "checkSpam": "५ मिनेटभित्र नआएमा स्प्याम फोल्डर जाँच गर्नुहोस्।", "backToLogin": "साइन इनमा फर्कनुहोस्", "passwordTooShort": "पासवर्ड कम्तिमा ८ अक्षरको हुनुपर्छ", "passwordMismatch": "पासवर्ड मेल खाएन", "nameRequired": "पूरा नाम आवश्यक छ", "invalidCredentials": "इमेल वा पासवर्ड गलत छ", "emailNotConfirmed": "इमेल पुष्टि भएको छैन।", "alreadyRegistered": "यो इमेल पहिले नै दर्ता भइसकेको छ।", "weakPassword": "धेरै छोटो", "fairPassword": "ठीकै", "goodPassword": "राम्रो", "strongPassword": "बलियो" },
  "dashboard": { "greeting": "फेरि स्वागत छ", "attempted": "प्रयास गरिएको", "accuracy": "शुद्धता", "correct": "सही", "sessions": "सत्रहरू", "readyTitle": "तपाईं परीक्षाको लागि तयार हुनुहुन्छ!", "practiceMoreTitle": "अभ्यास जारी राख्नुहोस्!", "readySub": "उत्तीर्ण अंक ९०% हो। तपाईंको शुद्धता:", "examModes": "परीक्षा मोड छान्नुहोस्", "kariamenDesc": "अस्थायी लाइसेन्स · ५० प्रश्न · ३० मिनेट", "honmenDesc": "पूर्ण लाइसेन्स · ९५ प्रश्न · ५० मिनेट", "recentHistory": "भर्खरको अभ्यास इतिहास", "noHistory": "अझै कुनै अभ्यास इतिहास छैन।", "startNow": "अहिले अभ्यास सुरु गर्नुहोस्", "unlockPremium": "प्रिमियम अनलक गर्नुहोस्", "premiumDesc": "५००+ भ्रामक प्रश्नहरू, गहिरो व्याख्या", "premiumCta": "प्रिमियम सुरु गर्नुहोस्" },
  "pricing": { "free": "नि:शुल्क", "premium": "प्रिमियम", "forever": "/ सधैंको लागि", "perMonth": "/ महिना", "mostPopular": "सबैभन्दा लोकप्रिय", "freeCta": "नि:शुल्क सुरु गर्नुहोस्", "premiumCta": "प्रिमियम सुरु गर्नुहोस्", "freeF1": "२ नि:शुल्क कारिमेन प्रश्नहरू", "freeF2": "आधारभूत व्याख्या", "freeF3": "५००+ प्रिमियम प्रश्नहरू", "freeF4": "होन्मेन मोड", "freeF5": "प्रगति ट्र्याकिङ", "premiumF1": "५००+ कारिमेन र होन्मेन प्रश्नहरू", "premiumF2": "प्रत्येक प्रश्नको गहिरो व्याख्या", "premiumF3": "यथार्थवादी परीक्षा मोड + टाइमर", "premiumF4": "पूर्ण प्रगति ड्यासबोर्ड", "premiumF5": "हरेक महिना नयाँ प्रश्नहरू" },
  "checkout": { "title": "प्रिमियममा अपग्रेड गर्नुहोस्", "sub": "सबै जापान ड्राइभिङ परीक्षा प्रश्नहरूमा पूर्ण पहुँच", "perMonth": "/ महिना", "approx": "लगभग", "cancelAnytime": "जुनसुकै बेला रद्द गर्न सकिन्छ", "payNow": "अहिले भुक्तान गर्नुहोस्", "loading": "भुक्तानी गेटवे लोड हुँदैछ...", "preparing": "भुक्तानी तयार गर्दै...", "secureNote": "Midtrans, Stripe, GoPay, QRIS, बैंक स्थानान्तरण द्वारा सुरक्षित", "successTitle": "भुक्तानी सफल भयो!", "successSub": "तपाईंको खाता प्रिमियममा अपग्रेड गरिएको छ।", "successCta": "प्रिमियम अभ्यास सुरु गर्नुहोस्", "pendingTitle": "भुक्तानी पर्खिँदै", "pendingSub": "भुक्तानी पुष्टि भएपछि खाता स्वचालित रूपमा अपग्रेड हुनेछ।", "failedTitle": "भुक्तानी असफल भयो", "failedSub": "कुनै शुल्क लिइएको छैन। फेरि प्रयास गर्नुहोस्।", "tryAgain": "फेरि प्रयास गर्नुहोस्" },
  "common": { "kariamen": "कारिमेन (仮免)", "honmen": "होन्मेन (本免)", "back": "पछाडि", "loading": "लोड हुँदैछ...", "error": "केही गलत भयो", "retry": "फेरि प्रयास गर्नुहोस्", "close": "बन्द गर्नुहोस्", "terms": "सेवाका सर्तहरू", "privacy": "गोपनीयता नीति", "contact": "सम्पर्क", "copyright": "© 2026 TokkiPass" },
  "language": { "select": "भाषा", "en": "English", "ja": "日本語", "id": "Indonesia", "zh": "中文", "vi": "Tiếng Việt", "ko": "한국어", "tl": "Filipino", "pt": "Português", "ne": "नेपाली" }
}
'@

Write-Host "  - messages/ne.json OK" -ForegroundColor Green
Write-Host "  Semua 9 file bahasa selesai!" -ForegroundColor Green

Write-Host "Rename brand 'Menkyo Master' -> 'TokkiPass' di file yang sudah ada..." -ForegroundColor Cyan

$brandFiles = @(
    "app\layout.tsx",
    "app\page.tsx",
    "app\(auth)\login\page.tsx",
    "app\dashboard\page.tsx"
)

foreach ($f in $brandFiles) {
    if (Test-Path $f) {
        $content = Get-Content -Raw -Path $f
        $newContent = $content -replace 'Menkyo Master', 'TokkiPass'
        Set-Content -Encoding UTF8 -Path $f -Value $newContent
        Write-Host "  - $f OK (brand diganti)" -ForegroundColor Green
    } else {
        Write-Host "  - $f TIDAK DITEMUKAN, dilewati (mungkin belum dibuat di tahap 1)" -ForegroundColor Yellow
    }
}

# ============================================================
# SELESAI
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " TAHAP 2 SELESAI - Multi-language + Rebrand ke TokkiPass" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "APA YANG BERUBAH:" -ForegroundColor Yellow
Write-Host " - next-intl terinstall"
Write-Host " - i18n/config.ts, i18n/request.ts dibuat"
Write-Host " - next.config.ts & middleware.ts di-update (gabung auth guard + locale detect)"
Write-Host " - components/ui/LanguageSwitcher.tsx dibuat (belum dipasang di halaman manapun)"
Write-Host " - app/api/set-locale/route.ts dibuat"
Write-Host " - types/database.types.ts: Question sekarang multi-bahasa (en/ja/id wajib)"
Write-Host " - lib/sample-questions.ts: 10 soal lengkap dalam EN/JA/ID"
Write-Host " - messages/*.json: 9 bahasa lengkap (en, id, ja, zh, vi, ko, tl, pt, ne)"
Write-Host " - Brand 'Menkyo Master' diganti jadi 'TokkiPass' di layout, landing, login, dashboard"
Write-Host ""
Write-Host "PENTING - BELUM DIKERJAKAN (next step):" -ForegroundColor Red
Write-Host " - Halaman (landing, login, register, dashboard, quiz, checkout) MASIH pakai teks"
Write-Host "   hardcoded Bahasa Indonesia. LanguageSwitcher belum dipasang di navbar manapun."
Write-Host "   Jadi app akan tetap tampil Bahasa Indonesia untuk semua orang buat sekarang -"
Write-Host "   infrastrukturnya sudah siap, tinggal setiap halaman di-refactor pakai useTranslations()."
Write-Host " - Untuk 8 dari 10 soal, terjemahan zh/vi/ko/tl/pt/ne belum ada (otomatis fallback ke EN)."
Write-Host ""
Write-Host "Langkah berikutnya:" -ForegroundColor Yellow
Write-Host "     npm run build"
Write-Host ""
