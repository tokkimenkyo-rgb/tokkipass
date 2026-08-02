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
import { createClient } from '@/lib/supabase/client';
import { submitAnswer } from '@/actions/submit-answer';

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
      {isMaru ? '〇' : '✕'}
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
          <strong>{correctAnswer ? '〇 (Benar)' : '✕ (Salah)'}</strong>
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
              ¥980
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
          {passed ? '🎉' : '📚'}
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
  const [userTier, setUserTier] = useState<AccountTierType>('free');

  useEffect(() => {
    async function fetchUserTier() {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();

      if (!user) return;

      const { data } = await supabase
        .from('profiles')
        .select('tier')
        .eq('id', user.id)
        .single();

      const profile = data as { tier: AccountTierType } | null;
      if (profile?.tier) {
        setUserTier(profile.tier);
      }
    }

    fetchUserTier();
  }, []);

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
  const isCorrect = answer === currentQuestion.correct_answer;
  submitAnswer(currentQuestion.id, isCorrect).catch((err) =>
    console.error('Gagal simpan progress:', err)
  );
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
            〇 Betul
          </span>
          <span className="text-xs text-red-500 font-semibold text-center w-36 md:w-44">
            ✕ Salah
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
