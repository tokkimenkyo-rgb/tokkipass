'use server';

import { createClient } from '@/lib/supabase/server';

const XP_CORRECT = 10;
const XP_WRONG = 2;
const COINS_CORRECT = 2;
const STREAK_BONUS_XP = 20;
const STREAK_BONUS_COINS = 5;

export async function submitAnswer(questionId: string, isCorrect: boolean) {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { error: 'Belum login' };
  }

  // 1. Simpan attempt-nya ke user_progress (sama seperti sebelumnya, cuma sekarang beneran ke-save)
  const { error: insertError } = await supabase.from('user_progress').insert({
    user_id: user.id,
    question_id: questionId,
    is_correct: isCorrect,
  } as never);

  if (insertError) {
    return { error: insertError.message };
  }

  // 2. Ambil xp/coins/streak profile saat ini
  const { data: profileData, error: profileError } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single();

  if (profileError || !profileData) {
    return { error: profileError?.message ?? 'Profil tidak ditemukan' };
  }

  const profile = profileData as {
    xp: number;
    coins: number;
    streak_days: number;
    last_activity_date: string | null;
  };

  // 3. Hitung streak harian
  const today = new Date().toISOString().slice(0, 10); // 'YYYY-MM-DD'
  let newStreak = profile.streak_days;
  let streakBonus = false;

  if (!profile.last_activity_date) {
    newStreak = 1;
    streakBonus = true;
  } else if (profile.last_activity_date === today) {
    // udah keitung hari ini, streak tetap
  } else {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().slice(0, 10);

    if (profile.last_activity_date === yesterdayStr) {
      newStreak = profile.streak_days + 1;
      streakBonus = true;
    } else {
      newStreak = 1; // ada hari yang kelewat, streak reset
      streakBonus = true;
    }
  }

  // 4. Hitung reward XP/koin
  let xpGain = isCorrect ? XP_CORRECT : XP_WRONG;
  let coinsGain = isCorrect ? COINS_CORRECT : 0;

  if (streakBonus) {
    xpGain += STREAK_BONUS_XP;
    coinsGain += STREAK_BONUS_COINS;
  }

  const newXp = profile.xp + xpGain;
  const newCoins = profile.coins + coinsGain;

  // 5. Simpan hasil barunya
  const { error: updateError } = await supabase
    .from('profiles')
    .update({
      xp: newXp,
      coins: newCoins,
      streak_days: newStreak,
      last_activity_date: today,
    } as never)
    .eq('id', user.id);

  if (updateError) {
    return { error: updateError.message };
  }

  return { xp: newXp, coins: newCoins, streakDays: newStreak, xpGain, coinsGain };
}