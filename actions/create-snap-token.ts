'use server';

import { createClient } from '@/lib/supabase/server';
import { createSnapClient, PREMIUM_PLAN, buildOrderId } from '@/lib/midtrans';
import type {
  CreateSnapTokenRequest,
  CreateSnapTokenResponse,
} from '@/types/midtrans.types';
import type { AccountTierType } from '@/types/database.types';

export interface SnapTokenResult {
  success: boolean;
  data?: CreateSnapTokenResponse;
  error?: string;
}

export async function createSnapToken(
  req: CreateSnapTokenRequest
): Promise<SnapTokenResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user || user.id !== req.userId) {
    return { success: false, error: 'Unauthorized' };
  }

  const { data: profileData } = await supabase
    .from('profiles')
    .select('tier')
    .eq('id', req.userId)
    .single();

  const profile = profileData as { tier: AccountTierType } | null;

  if (profile?.tier === 'premium') {
    return { success: false, error: 'Akun sudah Premium' };
  }

  const orderId = buildOrderId(req.userId);

  const { error: insertError } = await supabase
    .from('payment_orders')
    .insert({
      order_id: orderId,
      user_id: req.userId,
      amount: PREMIUM_PLAN.price,
      currency: PREMIUM_PLAN.currency,
      status: 'pending',
    } as never);

  if (insertError) {
    console.error('[createSnapToken] Insert order error:', insertError);
    return { success: false, error: 'Gagal membuat order' };
  }

  try {
    const snap = createSnapClient();

    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: PREMIUM_PLAN.price,
      },
      item_details: [
        {
          id: PREMIUM_PLAN.id,
          price: PREMIUM_PLAN.price,
          quantity: 1,
          name: PREMIUM_PLAN.name,
        },
      ],
      customer_details: {
        first_name: req.userName,
        email: req.userEmail,
      },
      callbacks: {
        finish: `${process.env.NEXT_PUBLIC_SITE_URL}/checkout/success?order_id=${orderId}`,
        error: `${process.env.NEXT_PUBLIC_SITE_URL}/checkout/failed?order_id=${orderId}`,
        pending: `${process.env.NEXT_PUBLIC_SITE_URL}/checkout/pending?order_id=${orderId}`,
      },
      enabled_payments: [
        'credit_card',
        'bca_va',
        'bni_va',
        'bri_va',
        'mandiri_bill',
        'gopay',
        'shopeepay',
        'qris',
      ],
    };

    const snapResponse = await snap.createTransaction(parameter);

    return {
      success: true,
      data: {
        token: snapResponse.token,
        redirectUrl: snapResponse.redirect_url,
        orderId,
      },
    };
  } catch (err) {
    console.error('[createSnapToken] Midtrans error:', err);
    return { success: false, error: 'Gagal menghubungi payment gateway' };
  }
}