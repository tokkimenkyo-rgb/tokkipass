# ============================================================
# fix-tokkipass-encoding.ps1
# Perbaikan untuk error "Parsing ecmascript source code failed"
# akibat karakter khusus (logo, simbol maru/batsu, dst) yang rusak (mojibake)
# saat script sebelumnya dibaca oleh PowerShell di sistem lo.
#
# Script ini AMAN dari masalah encoding karena karakter khusus
# dibuat dari KODE ANGKA (bukan karakter langsung), jadi tidak
# mungkin salah baca di sistem manapun.
#
# CARA PAKAI:
# 1. cd C:\Users\abdul\Documents\Menkyo\tokkipass
# 2. powershell -ExecutionPolicy Bypass -File fix-tokkipass-encoding.ps1
# ============================================================

Write-Host "Menyiapkan karakter khusus dari kode angka (aman dari encoding issue)..." -ForegroundColor Cyan

$MARU   = [char]0x3007
$BATSU  = [char]0x2715
$MENKYO = [char]0x514D
$PARTY  = [System.Char]::ConvertFromUtf32(0x1F389)
$BOOKS  = [System.Char]::ConvertFromUtf32(0x1F4DA)
$STAR   = [char]0x2605
$COPY   = [char]0x00A9
$YEN    = [char]0x00A5

Write-Host "Memperbaiki app/quiz/page.tsx..." -ForegroundColor Cyan

# ============================================================
# app/quiz/page.tsx (fixed: karakter aman + pakai getQuestionText/getExplanation)
# ============================================================
$quizContent = @'
'use client';

import React, {
  useCallback,
  useEffect,
  useReducer,
  useRef,
  useState,
} from 'react';
import {
  CheckCircle2,
  XCircle,
  Clock,
  ChevronRight,
  Star,
  Lock,
  Zap,
  BookOpen,
  Trophy,
  X,
} from 'lucide-react';
import type {
  Question,
  QuizState,
  QuizAction,
  AccountTierType,
} from '@/types/database.types';
import { getQuestionText, getExplanation } from '@/types/database.types';
import type { Locale } from '@/i18n/config';
import { SAMPLE_QUESTIONS } from '@/lib/sample-questions';

const DISPLAY_LOCALE: Locale = 'id';
const KARIAMEN_DURATION_SECONDS = 30 * 60;
const FREE_QUESTION_LIMIT = 2;

function quizReducer(state: QuizState, action: QuizAction): QuizState {
  switch (action.type) {
    case 'ANSWER': {
      const currentQuestion = state.questions[state.currentIndex];
      const isCorrect = action.answer === currentQuestion.correct_answer;
      return {
        ...state,
        answers: { ...state.answers, [action.questionId]: action.answer },
        score: isCorrect ? state.score + 1 : state.score,
        isAnswered: true,
        showExplanation: true,
      };
    }
    case 'NEXT_QUESTION': {
      const nextIndex = state.currentIndex + 1;
      if (nextIndex >= state.questions.length) {
        return { ...state, isFinished: true, showExplanation: false };
      }
      return {
        ...state,
        currentIndex: nextIndex,
        isAnswered: false,
        showExplanation: false,
      };
    }
    case 'SHOW_PAYWALL':
      return { ...state, showPaywall: true };
    case 'FINISH_QUIZ':
      return { ...state, isFinished: true, showExplanation: false };
    case 'RESET_QUIZ':
      return {
        ...state,
        currentIndex: 0,
        score: 0,
        answers: {},
        isFinished: false,
        isAnswered: false,
        showExplanation: false,
        showPaywall: false,
      };
    default:
      return state;
  }
}

function useCountdownTimer(
  initialSeconds: number,
  onExpire: () => void
): { secondsLeft: number; isExpired: boolean } {
  const [secondsLeft, setSecondsLeft] = useState(initialSeconds);
  const [isExpired, setIsExpired] = useState(false);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (isExpired) return;

    intervalRef.current = setInterval(() => {
      setSecondsLeft((prev) => {
        if (prev <= 1) {
          clearInterval(intervalRef.current!);
          setIsExpired(true);
          onExpire();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isExpired]);

  return { secondsLeft, isExpired };
}

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60).toString().padStart(2, '0');
  const s = (seconds % 60).toString().padStart(2, '0');
  return `${m}:${s}`;
}

interface ProgressBarProps {
  current: number;
  total: number;
}

function ProgressBar({ current, total }: ProgressBarProps) {
  const pct = Math.round((current / total) * 100);
  return (
    <div className="w-full bg-gray-200 rounded-full h-2">
      <div
        className="h-2 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 transition-all duration-500"
        style={{ width: `${pct}%` }}
      />
    </div>
  );
}

interface TimerDisplayProps {
  secondsLeft: number;
  isExpired: boolean;
}

function TimerDisplay({ secondsLeft, isExpired }: TimerDisplayProps) {
  const isWarning = secondsLeft <= 5 * 60;
  const isDanger = secondsLeft <= 2 * 60;

  return (
    <div
      className={`flex items-center gap-1.5 font-mono font-bold text-lg px-3 py-1.5 rounded-xl border-2 transition-colors ${
        isDanger
          ? 'bg-red-50 border-red-400 text-red-600 animate-pulse'
          : isWarning
          ? 'bg-amber-50 border-amber-400 text-amber-600'
          : 'bg-slate-50 border-slate-300 text-slate-700'
      }`}
    >
      <Clock className="w-4 h-4" />
      {isExpired ? '00:00' : formatTime(secondsLeft)}
    </div>
  );
}

interface AnswerButtonProps {
  type: 'maru' | 'batsu';
  onClick: () => void;
  disabled: boolean;
  isSelected: boolean;
  isCorrect: boolean | null;
  showResult: boolean;
}

function AnswerButton({
  type,
  onClick,
  disabled,
  isSelected,
  isCorrect,
  showResult,
}: AnswerButtonProps) {
  const isMaru = type === 'maru';

  let baseClasses =
    'relative flex items-center justify-center rounded-full w-36 h-36 md:w-44 md:h-44 text-6xl md:text-7xl font-bold border-4 transition-all duration-200 select-none ';

  if (!showResult) {
    baseClasses += isMaru
      ? 'border-blue-500 bg-blue-50 text-blue-500 hover:bg-blue-500 hover:text-white active:scale-95 cursor-pointer shadow-lg hover:shadow-blue-200'
      : 'border-red-500 bg-red-50 text-red-500 hover:bg-red-500 hover:text-white active:scale-95 cursor-pointer shadow-lg hover:shadow-red-200';
  } else if (isSelected) {
    baseClasses += isCorrect
      ? 'border-green-500 bg-green-500 text-white shadow-xl shadow-green-200 scale-105'
      : 'border-red-500 bg-red-500 text-white shadow-xl shadow-red-200';
  } else {
    baseClasses += 'border-gray-200 bg-gray-50 text-gray-300 cursor-default';
  }

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={baseClasses}
      aria-label={isMaru ? 'Maru (Benar)' : 'Batsu (Salah)'}
    >
      __MARU_OR_BATSU__
      {showResult && isSelected && (
        <span className="absolute -top-2 -right-2">
          {isCorrect ? (
            <CheckCircle2 className="w-8 h-8 text-green-400 bg-white rounded-full" />
          ) : (
            <XCircle className="w-8 h-8 text-red-400 bg-white rounded-full" />
          )}
        </span>
      )}
    </button>
  );
}

interface ExplanationCardProps {
  isCorrect: boolean;
  explanation: string;
  correctAnswer: boolean;
}

function ExplanationCard({
  isCorrect,
  explanation,
  correctAnswer,
}: ExplanationCardProps) {
  return (
    <div
      className={`mt-4 rounded-2xl p-4 border-l-4 text-sm leading-relaxed animate-in fade-in slide-in-from-bottom-4 duration-300 ${
        isCorrect
          ? 'bg-green-50 border-green-500 text-green-900'
          : 'bg-red-50 border-red-500 text-red-900'
      }`}
    >
      <div className="flex items-center gap-2 font-bold mb-2">
        {isCorrect ? (
          <CheckCircle2 className="w-5 h-5 text-green-600" />
        ) : (
          <XCircle className="w-5 h-5 text-red-600" />
        )}
        <span>{isCorrect ? 'Jawaban Benar!' : 'Jawaban Salah'}</span>
        <span className="ml-auto text-xs font-normal">
          Jawaban benar:{' '}
          <strong>{correctAnswer ? '__MARU__ (Benar)' : '__BATSU__ (Salah)'}</strong>
        </span>
      </div>
      <p>{explanation}</p>
    </div>
  );
}

interface PaywallModalProps {
  onClose: () => void;
}

function PaywallModal({ onClose }: PaywallModalProps) {
  const benefits = [
    {
      icon: <BookOpen className="w-5 h-5 text-indigo-500" />,
      title: 'Akses 500+ Soal Jebakan',
      desc: 'Bank soal lengkap dari ujian nyata, diperbarui rutin',
    },
    {
      icon: <Zap className="w-5 h-5 text-amber-500" />,
      title: 'Pembahasan AI Mendalam',
      desc: 'Penjelasan interaktif per soal dengan konteks hukum lalin Jepang',
    },
    {
      icon: <Trophy className="w-5 h-5 text-green-500" />,
      title: 'Simulasi Ujian Realistis',
      desc: 'Kariamen & Honmen mode dengan skor dan laporan akhir',
    },
    {
      icon: <Star className="w-5 h-5 text-yellow-500" />,
      title: 'Garansi Lulus',
      desc: 'Ribuan diaspora sudah lulus dengan TokkiPass',
    },
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div className="relative w-full max-w-md bg-white rounded-3xl shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200">
        <div className="bg-gradient-to-br from-indigo-600 to-purple-700 px-6 pt-8 pb-10 text-white text-center">
          <button
            onClick={onClose}
            className="absolute top-4 right-4 text-white/70 hover:text-white transition-colors"
            aria-label="Tutup"
          >
            <X className="w-5 h-5" />
          </button>
          <div className="inline-flex items-center justify-center w-16 h-16 bg-white/20 rounded-2xl mb-4">
            <Lock className="w-8 h-8 text-white" />
          </div>
          <h2 className="text-2xl font-extrabold mb-1">Soal Premium</h2>
          <p className="text-indigo-200 text-sm">
            Soal ini hanya tersedia untuk pengguna Premium
          </p>
        </div>

        <div className="-mt-4 mx-4 bg-white rounded-2xl shadow-lg border border-gray-100 p-4 space-y-3">
          {benefits.map((b, i) => (
            <div key={i} className="flex items-start gap-3">
              <div className="mt-0.5 flex-shrink-0 w-8 h-8 bg-gray-50 rounded-xl flex items-center justify-center">
                {b.icon}
              </div>
              <div>
                <p className="text-sm font-semibold text-gray-800">{b.title}</p>
                <p className="text-xs text-gray-500">{b.desc}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="px-6 py-5">
          <div className="text-center mb-4">
            <span className="text-4xl font-extrabold text-gray-900">
              __YEN__980
            </span>
            <span className="text-gray-500 text-sm"> / bulan</span>
          </div>

          <a
            href="/checkout"
            className="block w-full py-3.5 bg-gradient-to-r from-indigo-600 to-purple-600 text-white text-center font-bold rounded-2xl shadow-lg shadow-indigo-200 hover:shadow-indigo-300 active:scale-[0.98] transition-all duration-200"
          >
            Upgrade ke Premium Sekarang
          </a>

          <button
            onClick={onClose}
            className="mt-2 block w-full py-2.5 text-sm text-gray-400 hover:text-gray-600 transition-colors"
          >
            Lanjut dengan versi gratis
          </button>
        </div>
      </div>
    </div>
  );
}

interface ResultScreenProps {
  score: number;
  total: number;
  onReset: () => void;
}

function ResultScreen({ score, total, onReset }: ResultScreenProps) {
  const pct = Math.round((score / total) * 100);
  const passed = pct >= 90;

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-indigo-50 flex items-center justify-center p-4">
      <div className="w-full max-w-sm bg-white rounded-3xl shadow-xl p-8 text-center">
        <div
          className={`inline-flex items-center justify-center w-24 h-24 rounded-full mb-6 text-5xl ${
            passed ? 'bg-green-100' : 'bg-red-100'
          }`}
        >
          {passed ? '__PARTY__' : '__BOOKS__'}
        </div>
        <h2 className="text-2xl font-extrabold text-gray-900 mb-1">
          {passed ? 'Lulus! Selamat!' : 'Belum Lulus'}
        </h2>
        <p className="text-gray-500 text-sm mb-6">
          {passed
            ? 'Kamu siap menghadapi ujian SIM Jepang!'
            : 'Terus berlatih, kamu pasti bisa!'}
        </p>

        <div className="bg-gray-50 rounded-2xl p-4 mb-6">
          <p className="text-5xl font-black text-indigo-600">{pct}%</p>
          <p className="text-gray-500 text-sm mt-1">
            {score} benar dari {total} soal
          </p>
          <p className="text-xs text-gray-400 mt-1">
            Batas lulus ujian Jepang: 90%
          </p>
        </div>

        <button
          onClick={onReset}
          className="w-full py-3 bg-indigo-600 text-white font-bold rounded-2xl hover:bg-indigo-700 active:scale-95 transition-all"
        >
          Coba Lagi
        </button>
      </div>
    </div>
  );
}

export default function QuizPage() {
  const [userTier] = useState<AccountTierType>('free');

  const initialState: QuizState = {
    questions: SAMPLE_QUESTIONS,
    currentIndex: 0,
    score: 0,
    answers: {},
    isFinished: false,
    isAnswered: false,
    showExplanation: false,
    showPaywall: false,
  };

  const [state, dispatch] = useReducer(quizReducer, initialState);

  const handleTimerExpire = useCallback(() => {
    dispatch({ type: 'FINISH_QUIZ' });
  }, []);

  const { secondsLeft, isExpired } = useCountdownTimer(
    KARIAMEN_DURATION_SECONDS,
    handleTimerExpire
  );

  const currentQuestion: Question = state.questions[state.currentIndex];
  const totalQuestions = state.questions.length;

  useEffect(() => {
    if (
      userTier === 'free' &&
      currentQuestion?.is_premium &&
      !state.showPaywall &&
      !state.isFinished
    ) {
      dispatch({ type: 'SHOW_PAYWALL' });
    }
  }, [currentQuestion, userTier, state.showPaywall, state.isFinished]);

  const userAnswer = state.answers[currentQuestion?.id] ?? null;
  const isCorrectAnswer =
    userAnswer !== null ? userAnswer === currentQuestion?.correct_answer : null;

  function handleAnswer(answer: boolean) {
    if (state.isAnswered || isExpired || state.isFinished) return;
    dispatch({ type: 'ANSWER', questionId: currentQuestion.id, answer });
  }

  function handleNext() {
    if (!state.isAnswered) return;
    const nextIndex = state.currentIndex + 1;

    if (nextIndex < totalQuestions) {
      const nextQuestion = state.questions[nextIndex];
      if (userTier === 'free' && nextQuestion.is_premium) {
        dispatch({ type: 'SHOW_PAYWALL' });
        return;
      }
    }

    dispatch({ type: 'NEXT_QUESTION' });
  }

  if (state.isFinished) {
    return (
      <ResultScreen
        score={state.score}
        total={totalQuestions}
        onReset={() => dispatch({ type: 'RESET_QUIZ' })}
      />
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-indigo-50 flex flex-col">
      {state.showPaywall && (
        <PaywallModal onClose={() => dispatch({ type: 'FINISH_QUIZ' })} />
      )}

      <header className="sticky top-0 z-10 bg-white/80 backdrop-blur-md border-b border-gray-100 px-4 py-3">
        <div className="max-w-2xl mx-auto">
          <div className="flex items-center justify-between mb-2">
            <div className="text-sm font-medium text-gray-500">
              Soal{' '}
              <span className="text-indigo-600 font-bold">
                {state.currentIndex + 1}
              </span>{' '}
              dari <span className="font-bold">{totalQuestions}</span>
            </div>
            <TimerDisplay secondsLeft={secondsLeft} isExpired={isExpired} />
          </div>
          <ProgressBar
            current={state.currentIndex + 1}
            total={totalQuestions}
          />
        </div>
      </header>

      <main className="flex-1 flex flex-col max-w-2xl w-full mx-auto px-4 py-6 gap-6">
        <div className="flex items-center gap-2">
          <span className="text-xs font-mono bg-indigo-100 text-indigo-700 px-2.5 py-1 rounded-full">
            {currentQuestion.question_code}
          </span>
          <span className="text-xs bg-slate-100 text-slate-600 px-2.5 py-1 rounded-full capitalize">
            {currentQuestion.type}
          </span>
          {currentQuestion.is_premium && (
            <span className="text-xs bg-amber-100 text-amber-700 px-2.5 py-1 rounded-full flex items-center gap-1">
              <Star className="w-3 h-3" /> Premium
            </span>
          )}
        </div>

        <div className="bg-white rounded-3xl shadow-sm border border-gray-100 p-6">
          {currentQuestion.image_url && (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={currentQuestion.image_url}
              alt="Ilustrasi soal"
              className="w-full rounded-2xl mb-4 object-cover max-h-48"
            />
          )}
          <p className="text-gray-800 text-lg md:text-xl leading-relaxed font-medium">
            {getQuestionText(currentQuestion, DISPLAY_LOCALE)}
          </p>
        </div>

        <div className="flex items-center justify-center gap-1.5 text-sm text-gray-500">
          <Trophy className="w-4 h-4 text-amber-500" />
          <span>
            Skor:{' '}
            <strong className="text-gray-700">
              {state.score}/{state.currentIndex + (state.isAnswered ? 1 : 0)}
            </strong>
          </span>
        </div>

        <div className="flex items-center justify-center gap-8 md:gap-16 py-4">
          <AnswerButton
            type="maru"
            onClick={() => handleAnswer(true)}
            disabled={state.isAnswered || isExpired}
            isSelected={userAnswer === true}
            isCorrect={userAnswer === true ? isCorrectAnswer : null}
            showResult={state.showExplanation}
          />

          <AnswerButton
            type="batsu"
            onClick={() => handleAnswer(false)}
            disabled={state.isAnswered || isExpired}
            isSelected={userAnswer === false}
            isCorrect={userAnswer === false ? isCorrectAnswer : null}
            showResult={state.showExplanation}
          />
        </div>

        <div className="flex justify-center gap-16 md:gap-32 -mt-2">
          <span className="text-xs text-blue-500 font-semibold text-center w-36 md:w-44">
            __MARU__ Betul
          </span>
          <span className="text-xs text-red-500 font-semibold text-center w-36 md:w-44">
            __BATSU__ Salah
          </span>
        </div>

        {state.showExplanation && isCorrectAnswer !== null && (
          <ExplanationCard
            isCorrect={isCorrectAnswer}
            explanation={getExplanation(currentQuestion, DISPLAY_LOCALE)}
            correctAnswer={currentQuestion.correct_answer}
          />
        )}

        {state.isAnswered && (
          <button
            onClick={handleNext}
            className="flex items-center justify-center gap-2 w-full py-3.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-2xl shadow-lg shadow-indigo-200 active:scale-[0.98] transition-all duration-200 animate-in fade-in slide-in-from-bottom-2"
          >
            {state.currentIndex + 1 >= totalQuestions
              ? 'Lihat Hasil'
              : 'Soal Berikutnya'}
            <ChevronRight className="w-5 h-5" />
          </button>
        )}
      </main>
    </div>
  );
}
'@

$quizContent = $quizContent -replace '__MARU_OR_BATSU__', "{isMaru ? '$MARU' : '$BATSU'}"
$quizContent = $quizContent -replace '__MARU__', $MARU
$quizContent = $quizContent -replace '__BATSU__', $BATSU
$quizContent = $quizContent -replace '__YEN__', $YEN
$quizContent = $quizContent -replace '__PARTY__', $PARTY
$quizContent = $quizContent -replace '__BOOKS__', $BOOKS

Set-Content -Encoding UTF8 -Path "app\quiz\page.tsx" -Value $quizContent
Write-Host "  - app/quiz/page.tsx FIXED" -ForegroundColor Green

Write-Host "Memperbaiki app/(auth)/login/page.tsx dan register/page.tsx..." -ForegroundColor Cyan

# ============================================================
# app/(auth)/login/page.tsx
# ============================================================
$loginContent = @'
'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { Eye, EyeOff, LogIn, AlertCircle } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

export default function LoginPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectTo = searchParams.get('redirectTo') ?? '/dashboard';

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [isPending, startTransition] = useTransition();

  const supabase = createClient();

  function handleLogin() {
    setErrorMsg('');

    if (!email || !password) {
      setErrorMsg('Email dan password wajib diisi.');
      return;
    }

    startTransition(async () => {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        if (error.message.includes('Invalid login credentials')) {
          setErrorMsg('Email atau password salah. Coba lagi.');
        } else if (error.message.includes('Email not confirmed')) {
          setErrorMsg('Email belum dikonfirmasi. Cek inbox/spam kamu.');
        } else {
          setErrorMsg(error.message);
        }
        return;
      }

      router.push(redirectTo);
      router.refresh();
    });
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-indigo-50 flex items-center justify-center p-4">
      <div className="w-full max-w-sm">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-indigo-600 rounded-2xl mb-4 shadow-lg shadow-indigo-200">
            <span className="text-3xl text-white font-black">__MENKYO__</span>
          </div>
          <h1 className="text-2xl font-extrabold text-gray-900">TokkiPass</h1>
          <p className="text-sm text-gray-500 mt-1">Masuk ke akun kamu</p>
        </div>

        <div className="bg-white rounded-3xl shadow-xl border border-gray-100 p-6 space-y-4">
          {errorMsg && (
            <div className="flex items-start gap-2.5 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-3.5 py-3">
              <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-700" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              type="email"
              autoComplete="email"
              placeholder="nama@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleLogin()}
              className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 outline-none text-sm transition-all"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-700" htmlFor="password">
              Password
            </label>
            <div className="relative">
              <input
                id="password"
                type={showPassword ? 'text' : 'password'}
                autoComplete="current-password"
                placeholder="Minimal 8 karakter"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleLogin()}
                className="w-full px-4 py-3 pr-11 rounded-xl border border-gray-200 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 outline-none text-sm transition-all"
              />
              <button
                type="button"
                onClick={() => setShowPassword((v) => !v)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                aria-label={showPassword ? 'Sembunyikan password' : 'Tampilkan password'}
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          <button
            onClick={handleLogin}
            disabled={isPending}
            className="flex items-center justify-center gap-2 w-full py-3.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-300 text-white font-bold rounded-xl shadow-lg shadow-indigo-200 active:scale-[0.98] transition-all duration-200"
          >
            {isPending ? (
              <>
                <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" strokeDasharray="40" strokeDashoffset="10" />
                </svg>
                Memproses...
              </>
            ) : (
              <>
                <LogIn className="w-4 h-4" />
                Masuk
              </>
            )}
          </button>

          <div className="text-center text-sm text-gray-500">
            Belum punya akun?{' '}
            <Link href="/register" className="text-indigo-600 font-semibold hover:underline">
              Daftar gratis
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
'@

$loginContent = $loginContent -replace '__MENKYO__', $MENKYO
Set-Content -Encoding UTF8 -Path "app\(auth)\login\page.tsx" -Value $loginContent
Write-Host "  - app/(auth)/login/page.tsx FIXED" -ForegroundColor Green

# ============================================================
# app/(auth)/register/page.tsx
# ============================================================
$registerContent = @'
'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { Eye, EyeOff, UserPlus, AlertCircle, CheckCircle2 } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

type FormStep = 'form' | 'success';

export default function RegisterPage() {
  const [step, setStep] = useState<FormStep>('form');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [isPending, startTransition] = useTransition();

  const supabase = createClient();

  function validate(): string | null {
    if (!fullName.trim()) return 'Nama lengkap wajib diisi.';
    if (!email) return 'Email wajib diisi.';
    if (password.length < 8) return 'Password minimal 8 karakter.';
    if (password !== confirmPassword) return 'Password dan konfirmasi tidak cocok.';
    return null;
  }

  function handleRegister() {
    setErrorMsg('');
    const validationError = validate();
    if (validationError) {
      setErrorMsg(validationError);
      return;
    }

    startTransition(async () => {
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { full_name: fullName.trim() },
          emailRedirectTo: `${window.location.origin}/dashboard`,
        },
      });

      if (error) {
        if (error.message.includes('User already registered')) {
          setErrorMsg('Email ini sudah terdaftar. Silakan login.');
        } else {
          setErrorMsg(error.message);
        }
        return;
      }

      setStep('success');
    });
  }

  if (step === 'success') {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 to-indigo-50 flex items-center justify-center p-4">
        <div className="w-full max-w-sm bg-white rounded-3xl shadow-xl border border-gray-100 p-8 text-center">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-green-100 rounded-full mb-4">
            <CheckCircle2 className="w-8 h-8 text-green-600" />
          </div>
          <h2 className="text-xl font-extrabold text-gray-900 mb-2">Cek Email Kamu!</h2>
          <p className="text-sm text-gray-500 leading-relaxed mb-2">
            Link konfirmasi sudah dikirim ke
          </p>
          <p className="text-sm font-bold text-indigo-600 mb-6">{email}</p>
          <p className="text-xs text-gray-400 mb-6">
            Cek folder Spam jika tidak muncul dalam 5 menit.
          </p>
          <Link
            href="/login"
            className="block w-full py-3 bg-indigo-600 text-white font-bold rounded-xl hover:bg-indigo-700 transition-colors"
          >
            Kembali ke Login
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-indigo-50 flex items-center justify-center p-4">
      <div className="w-full max-w-sm">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-indigo-600 rounded-2xl mb-4 shadow-lg shadow-indigo-200">
            <span className="text-3xl text-white font-black">__MENKYO__</span>
          </div>
          <h1 className="text-2xl font-extrabold text-gray-900">Daftar Gratis</h1>
          <p className="text-sm text-gray-500 mt-1">Mulai latihan ujian SIM Jepang</p>
        </div>

        <div className="bg-white rounded-3xl shadow-xl border border-gray-100 p-6 space-y-4">
          {errorMsg && (
            <div className="flex items-start gap-2.5 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-3.5 py-3">
              <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-700" htmlFor="fullName">
              Nama Lengkap
            </label>
            <input
              id="fullName"
              type="text"
              autoComplete="name"
              placeholder="Ahmad Jabir"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 outline-none text-sm transition-all"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-700" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              type="email"
              autoComplete="email"
              placeholder="nama@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 outline-none text-sm transition-all"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-700" htmlFor="password">
              Password
            </label>
            <div className="relative">
              <input
                id="password"
                type={showPassword ? 'text' : 'password'}
                autoComplete="new-password"
                placeholder="Minimal 8 karakter"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 pr-11 rounded-xl border border-gray-200 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 outline-none text-sm transition-all"
              />
              <button
                type="button"
                onClick={() => setShowPassword((v) => !v)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                aria-label={showPassword ? 'Sembunyikan' : 'Tampilkan'}
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-700" htmlFor="confirmPassword">
              Konfirmasi Password
            </label>
            <input
              id="confirmPassword"
              type={showPassword ? 'text' : 'password'}
              autoComplete="new-password"
              placeholder="Ulangi password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleRegister()}
              className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 outline-none text-sm transition-all"
            />
          </div>

          {password.length > 0 && (
            <div className="space-y-1">
              <div className="flex gap-1">
                {[...Array(4)].map((_, i) => {
                  const strength =
                    password.length >= 12
                      ? 4
                      : password.length >= 10
                      ? 3
                      : password.length >= 8
                      ? 2
                      : 1;
                  return (
                    <div
                      key={i}
                      className={`h-1 flex-1 rounded-full transition-colors ${
                        i < strength
                          ? strength <= 1
                            ? 'bg-red-400'
                            : strength <= 2
                            ? 'bg-amber-400'
                            : strength <= 3
                            ? 'bg-blue-400'
                            : 'bg-green-400'
                          : 'bg-gray-200'
                      }`}
                    />
                  );
                })}
              </div>
              <p className="text-xs text-gray-400">
                {password.length < 8
                  ? 'Terlalu pendek'
                  : password.length < 10
                  ? 'Cukup'
                  : password.length < 12
                  ? 'Bagus'
                  : 'Kuat'}
              </p>
            </div>
          )}

          <button
            onClick={handleRegister}
            disabled={isPending}
            className="flex items-center justify-center gap-2 w-full py-3.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-300 text-white font-bold rounded-xl shadow-lg shadow-indigo-200 active:scale-[0.98] transition-all duration-200"
          >
            {isPending ? (
              <>
                <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" strokeDasharray="40" strokeDashoffset="10" />
                </svg>
                Mendaftar...
              </>
            ) : (
              <>
                <UserPlus className="w-4 h-4" />
                Daftar Sekarang
              </>
            )}
          </button>

          <div className="text-center text-sm text-gray-500">
            Sudah punya akun?{' '}
            <Link href="/login" className="text-indigo-600 font-semibold hover:underline">
              Masuk
            </Link>
          </div>

          <p className="text-xs text-gray-400 text-center">
            Dengan mendaftar, kamu setuju dengan{' '}
            <Link href="/terms" className="underline hover:text-gray-600">
              Syarat & Ketentuan
            </Link>{' '}
            kami.
          </p>
        </div>
      </div>
    </div>
  );
}
'@

$registerContent = $registerContent -replace '__MENKYO__', $MENKYO
Set-Content -Encoding UTF8 -Path "app\(auth)\register\page.tsx" -Value $registerContent
Write-Host "  - app/(auth)/register/page.tsx FIXED" -ForegroundColor Green

Write-Host "Memperbaiki app/page.tsx (landing) dan DemoQuiz.tsx..." -ForegroundColor Cyan

# ============================================================
# app/page.tsx (landing)
# ============================================================
$landingContent = @'
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
    emoji: 'TARGET_EMOJI',
    title: 'Soal jebakan asli',
    desc: 'Kumpulan soal tipe trick yang sering bikin gagal, diterjemahkan akurat dari ujian resmi.',
    bg: 'bg-indigo-50',
  },
  {
    emoji: 'BOOK_EMOJI',
    title: 'Penjelasan mendalam',
    desc: 'Setiap soal ada konteks hukum lalu lintas Jepang, kamu ngerti bukan cuma hapal.',
    bg: 'bg-green-50',
  },
  {
    emoji: 'CLOCK_EMOJI',
    title: 'Timer ujian realistis',
    desc: 'Kariamen 30 menit, Honmen 50 menit. Persis seperti kondisi ujian di Jepang.',
    bg: 'bg-amber-50',
  },
  {
    emoji: 'CHART_EMOJI',
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
          <span className="text-white font-black text-sm">__MENKYO__</span>
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
              <div className="text-amber-400 text-sm mb-2">STAR5_PLACEHOLDER</div>
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
              __YEN__0{' '}
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
              __YEN__980{' '}
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
          <div className="text-5xl mb-4">__MARU__</div>
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
          <p className="text-xs text-gray-400">COPY_PLACEHOLDER 2026 TokkiPass</p>
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
'@

$landingContent = $landingContent -replace 'TARGET_EMOJI', ([System.Char]::ConvertFromUtf32(0x1F3AF))
$landingContent = $landingContent -replace 'BOOK_EMOJI', ([System.Char]::ConvertFromUtf32(0x1F4D6))
$landingContent = $landingContent -replace 'CLOCK_EMOJI', ([System.Char]::ConvertFromUtf32(0x23F1))
$landingContent = $landingContent -replace 'CHART_EMOJI', ([System.Char]::ConvertFromUtf32(0x1F4CA))
$landingContent = $landingContent -replace '__MENKYO__', $MENKYO
$landingContent = $landingContent -replace 'STAR5_PLACEHOLDER', ($STAR.ToString() * 5)
$landingContent = $landingContent -replace '__YEN__', $YEN
$landingContent = $landingContent -replace '__MARU__', $MARU
$landingContent = $landingContent -replace 'COPY_PLACEHOLDER', $COPY

Set-Content -Encoding UTF8 -Path "app\page.tsx" -Value $landingContent
Write-Host "  - app/page.tsx FIXED" -ForegroundColor Green

Write-Host "Memperbaiki components/landing/DemoQuiz.tsx..." -ForegroundColor Cyan

# ============================================================
# components/landing/DemoQuiz.tsx
# ============================================================
$demoQuizContent = @'
'use client';

import { useState } from 'react';
import { CheckCircle2, XCircle, ChevronRight } from 'lucide-react';
import Link from 'next/link';

const DEMO_QUESTIONS = [
  {
    code: 'KM-001',
    text: 'Ketika polisi berdiri di persimpangan dengan kedua tangan terentang ke samping (horizontal), semua kendaraan dari segala arah harus berhenti.',
    answer: true,
    explanationCorrect:
      'Benar. Tangan horizontal berarti semua arah berhenti, setara lampu merah penuh. Tidak ada arah yang diizinkan melaju.',
    explanationWrong:
      'Salah. Tangan horizontal berarti semua arah berhenti, termasuk arah samping. Tidak ada pengecualian.',
  },
  {
    code: 'KM-002',
    text: 'Di jalan umum tanpa rambu batas kecepatan, kecepatan maksimum kendaraan penumpang adalah 60 km/jam.',
    answer: true,
    explanationCorrect:
      'Benar. Ini disebut hoteisokudo (kecepatan undang-undang). Tanpa rambu di jalan biasa, maksimum 60 km/jam.',
    explanationWrong:
      'Salah. Tanpa rambu di jalan umum, batas default tetap 60 km/jam berdasarkan UU lalu lintas Jepang.',
  },
  {
    code: 'KM-003',
    text: 'Mendahului kendaraan di dekat zebra cross boleh dilakukan asalkan tidak ada pejalan kaki yang sedang menyeberang.',
    answer: false,
    explanationCorrect:
      'Benar. Mendahului di dekat zebra cross dilarang keras, ada atau tidak ada pejalan kaki.',
    explanationWrong:
      'Salah. Mendahului di dekat zebra cross selalu dilarang, bukan hanya saat ada pejalan kaki.',
  },
];

type AnswerState = 'idle' | 'correct' | 'wrong';

export function DemoQuiz() {
  const [currentIdx, setCurrentIdx] = useState(0);
  const [answerState, setAnswerState] = useState<AnswerState>('idle');
  const [userAnswer, setUserAnswer] = useState<boolean | null>(null);
  const [doneAll, setDoneAll] = useState(false);

  const q = DEMO_QUESTIONS[currentIdx];
  const isAnswered = answerState !== 'idle';
  const isLast = currentIdx === DEMO_QUESTIONS.length - 1;

  function handleAnswer(answer: boolean) {
    if (isAnswered) return;
    const isCorrect = answer === q.answer;
    setUserAnswer(answer);
    setAnswerState(isCorrect ? 'correct' : 'wrong');
  }

  function handleNext() {
    if (isLast) {
      setDoneAll(true);
      return;
    }
    setCurrentIdx((i) => i + 1);
    setAnswerState('idle');
    setUserAnswer(null);
  }

  if (doneAll) {
    return (
      <div className="w-full bg-white border border-gray-100 rounded-2xl p-6 text-center shadow-sm">
        <div className="text-3xl mb-3">__PARTY__</div>
        <p className="font-bold text-gray-900 mb-1">Soal demo selesai!</p>
        <p className="text-sm text-gray-500 mb-4">
          Masih ada 500+ soal jebakan lainnya menunggu.
        </p>
        <Link
          href="/register"
          className="inline-flex items-center gap-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-bold px-5 py-2.5 rounded-xl transition-colors"
        >
          Akses semua soal gratis
          <ChevronRight className="w-4 h-4" />
        </Link>
      </div>
    );
  }

  return (
    <div className="w-full bg-white border border-gray-100 rounded-2xl shadow-sm overflow-hidden">
      <div className="flex items-center justify-between px-4 py-3 bg-gray-50 border-b border-gray-100">
        <span className="text-xs text-gray-400 uppercase tracking-wide font-medium">
          Coba langsung
        </span>
        <span className="text-xs font-mono bg-indigo-50 text-indigo-600 border border-indigo-100 px-2 py-0.5 rounded-md">
          {q.code}
        </span>
      </div>

      <div className="px-5 pt-4 pb-2">
        <p className="text-sm text-gray-800 leading-relaxed">{q.text}</p>
      </div>

      <div className="flex justify-center gap-6 px-5 py-4">
        <button
          onClick={() => handleAnswer(true)}
          disabled={isAnswered}
          className={`w-20 h-20 rounded-full text-4xl font-bold border-2 transition-all duration-150 active:scale-95
            ${
              !isAnswered
                ? 'border-blue-300 bg-blue-50 text-blue-500 hover:bg-blue-500 hover:text-white'
                : userAnswer === true
                ? answerState === 'correct'
                  ? 'border-green-500 bg-green-500 text-white scale-105'
                  : 'border-red-500 bg-red-500 text-white'
                : 'border-gray-100 bg-gray-50 text-gray-200'
            }`}
          aria-label="Maru - Benar"
        >
          __MARU__
        </button>

        <button
          onClick={() => handleAnswer(false)}
          disabled={isAnswered}
          className={`w-20 h-20 rounded-full text-4xl font-bold border-2 transition-all duration-150 active:scale-95
            ${
              !isAnswered
                ? 'border-red-300 bg-red-50 text-red-500 hover:bg-red-500 hover:text-white'
                : userAnswer === false
                ? answerState === 'correct'
                  ? 'border-green-500 bg-green-500 text-white scale-105'
                  : 'border-red-500 bg-red-500 text-white'
                : 'border-gray-100 bg-gray-50 text-gray-200'
            }`}
          aria-label="Batsu - Salah"
        >
          __BATSU__
        </button>
      </div>

      {isAnswered && (
        <div
          className={`mx-4 mb-3 rounded-xl p-3.5 text-xs leading-relaxed flex items-start gap-2 ${
            answerState === 'correct'
              ? 'bg-green-50 text-green-800 border border-green-200'
              : 'bg-red-50 text-red-800 border border-red-200'
          }`}
        >
          {answerState === 'correct' ? (
            <CheckCircle2 className="w-3.5 h-3.5 mt-0.5 flex-shrink-0 text-green-600" />
          ) : (
            <XCircle className="w-3.5 h-3.5 mt-0.5 flex-shrink-0 text-red-500" />
          )}
          {answerState === 'correct' ? q.explanationCorrect : q.explanationWrong}
        </div>
      )}

      {isAnswered && (
        <div className="px-4 pb-4">
          <button
            onClick={handleNext}
            className="flex items-center justify-center gap-1.5 w-full py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-bold rounded-xl transition-colors active:scale-[0.98]"
          >
            {isLast ? 'Akses semua soal' : 'Soal berikutnya'}
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      )}

      <div className="flex gap-1 px-4 pb-3">
        {DEMO_QUESTIONS.map((_, i) => (
          <div
            key={i}
            className={`h-0.5 flex-1 rounded-full transition-colors duration-300 ${
              i < currentIdx || (i === currentIdx && isAnswered)
                ? 'bg-indigo-500'
                : 'bg-gray-200'
            }`}
          />
        ))}
      </div>
    </div>
  );
}
'@

$demoQuizContent = $demoQuizContent -replace '__PARTY__', $PARTY
$demoQuizContent = $demoQuizContent -replace '__MARU__', $MARU
$demoQuizContent = $demoQuizContent -replace '__BATSU__', $BATSU

Set-Content -Encoding UTF8 -Path "components\landing\DemoQuiz.tsx" -Value $demoQuizContent
Write-Host "  - components/landing/DemoQuiz.tsx FIXED" -ForegroundColor Green

Write-Host "Memperbaiki app/dashboard/page.tsx..." -ForegroundColor Cyan

# ============================================================
# app/dashboard/page.tsx
# ============================================================
$dashboardContent = @'
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
              <span className="text-white font-black text-sm">__MENKYO__</span>
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
            <span className="text-2xl">{accuracy >= 90 ? '__PARTY__' : '__BOOKS__'}</span>
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
              Mulai Premium - __YEN__980/bulan
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
'@

$dashboardContent = $dashboardContent -replace '__MENKYO__', $MENKYO
$dashboardContent = $dashboardContent -replace '__PARTY__', $PARTY
$dashboardContent = $dashboardContent -replace '__BOOKS__', $BOOKS
$dashboardContent = $dashboardContent -replace '__YEN__', $YEN

Set-Content -Encoding UTF8 -Path "app\dashboard\page.tsx" -Value $dashboardContent
Write-Host "  - app/dashboard/page.tsx FIXED" -ForegroundColor Green

Write-Host "Memperbaiki app/checkout/page.tsx..." -ForegroundColor Cyan

# ============================================================
# app/checkout/page.tsx
# ============================================================
$checkoutContent = @'
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

      const { data: profile } = await supabase
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .single();

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
            <span className="text-3xl text-white font-black">__MENKYO__</span>
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
              <span className="text-5xl font-black">__YEN__980</span>
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
'@

$checkoutContent = $checkoutContent -replace '__MENKYO__', $MENKYO
$checkoutContent = $checkoutContent -replace '__YEN__', $YEN

Set-Content -Encoding UTF8 -Path "app\checkout\page.tsx" -Value $checkoutContent
Write-Host "  - app/checkout/page.tsx FIXED" -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SEMUA 7 FILE SELESAI DIPERBAIKI" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Yang diperbaiki:" -ForegroundColor Yellow
Write-Host " - Karakter khusus (logo, maru/batsu, emoji, yen, bintang) dibuat dari kode"
Write-Host "   angka, jadi tidak mungkin salah baca lagi di sistem manapun."
Write-Host " - app/quiz/page.tsx: diperbaiki supaya pakai getQuestionText()/getExplanation()"
Write-Host "   sesuai tipe Question yang baru (multi-bahasa)."
Write-Host " - app/dashboard/page.tsx: diperbaiki referensi field yang sudah tidak ada."
Write-Host ""
Write-Host "Langkah berikutnya:" -ForegroundColor Yellow
Write-Host "     npm run build"
Write-Host ""
