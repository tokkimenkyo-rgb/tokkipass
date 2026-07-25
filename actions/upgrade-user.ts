'use server';

import { createAdminClient } from '@/lib/supabase/admin';
import { revalidatePath } from 'next/cache';
import type { AccountTierType } from '@/types/database.types';

export interface UpgradeUserResult {
  success: boolean;
  message: string;
  userId?: string;
  error?: string;
}

function isValidUUID(value: string): boolean {
  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(value);
}

export async function upgradeUserToPremium(
  userId: string
): Promise<UpgradeUserResult> {
  if (!userId || typeof userId !== 'string') {
    return {
      success: false,
      message: 'Validasi gagal',
      error: 'userId tidak boleh kosong',
    };
  }

  if (!isValidUUID(userId)) {
    return {
      success: false,
      message: 'Validasi gagal',
      error: 'Format userId tidak valid (harus UUID)',
    };
  }

  const adminClient = createAdminClient();

  const { data: existingProfileData, error: fetchError } = await adminClient
    .from('profiles')
    .select('id, tier, full_name')
    .eq('id', userId)
    .single();

  const existingProfile = existingProfileData as {
    id: string;
    tier: AccountTierType;
    full_name: string | null;
  } | null;

  if (fetchError || !existingProfile) {
    return {
      success: false,
      message: 'User tidak ditemukan',
      error: fetchError?.message ?? 'Profile tidak ada di database',
    };
  }

  if (existingProfile.tier === 'premium') {
    return {
      success: true,
      message: `User ${userId} sudah Premium, tidak ada perubahan`,
      userId,
    };
  }

  const { error: updateError } = await adminClient
    .from('profiles')
    .update({
      tier: 'premium',
      updated_at: new Date().toISOString(),
    } as never)
    .eq('id', userId);

  if (updateError) {
    console.error('[upgradeUserToPremium] Update error:', updateError);
    return {
      success: false,
      message: 'Gagal upgrade user',
      error: updateError.message,
    };
  }

  revalidatePath('/dashboard');
  revalidatePath('/quiz');

  console.info(
    `[upgradeUserToPremium] SUCCESS: User ${userId} (${existingProfile.full_name}) upgraded to premium at ${new Date().toISOString()}`
  );

  return {
    success: true,
    message: `User berhasil diupgrade ke Premium`,
    userId,
  };
}