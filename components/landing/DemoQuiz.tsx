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
        <div className="text-3xl mb-3">🎉</div>
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
          〇
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
          ✕
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
