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

export interface PaymentOrder {
  id: string;
  order_id: string;
  user_id: string;
  amount: number;
  currency: string;
  status: string;
  midtrans_transaction_id: string | null;
  payment_type: string | null;
  created_at: string | null;
  updated_at: string | null;
}

export type InsertProfile = Omit<Profile, 'updated_at'>;

export type InsertUserProgress = Omit<UserProgress, 'id' | 'created_at'>;

export type InsertPaymentOrder = Pick<PaymentOrder, 'order_id' | 'user_id' | 'amount'> &
  Partial<Pick<PaymentOrder, 'currency' | 'status' | 'midtrans_transaction_id' | 'payment_type'>>;

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
  __InternalSupabase: {
    PostgrestVersion: '12';
  };
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: InsertProfile;
        Update: Partial<Profile>;
        Relationships: [];
      };
      questions: {
        Row: Question;
        Insert: Omit<Question, 'id'>;
        Update: Partial<Question>;
        Relationships: [];
      };
      user_progress: {
        Row: UserProgress;
        Insert: InsertUserProgress;
        Update: Partial<UserProgress>;
        Relationships: [];
      };
      payment_orders: {
        Row: PaymentOrder;
        Insert: InsertPaymentOrder;
        Update: Partial<PaymentOrder>;
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: {
      account_tier_type: AccountTierType;
      exam_type: ExamType;
    };
    CompositeTypes: Record<string, never>;
  };
}