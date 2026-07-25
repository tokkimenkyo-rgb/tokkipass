import MidtransClient from 'midtrans-client';

export function createSnapClient() {
  const serverKey = process.env.MIDTRANS_SERVER_KEY;
  const clientKey = process.env.NEXT_PUBLIC_MIDTRANS_CLIENT_KEY;
  const isProduction = process.env.MIDTRANS_IS_PRODUCTION === 'true';

  if (!serverKey || !clientKey) {
    throw new Error(
      'Missing MIDTRANS_SERVER_KEY or NEXT_PUBLIC_MIDTRANS_CLIENT_KEY'
    );
  }

  return new MidtransClient.Snap({
    isProduction,
    serverKey,
    clientKey,
  });
}

export function createCoreApiClient() {
  const serverKey = process.env.MIDTRANS_SERVER_KEY;
  const isProduction = process.env.MIDTRANS_IS_PRODUCTION === 'true';

  if (!serverKey) {
    throw new Error('Missing MIDTRANS_SERVER_KEY');
  }

  return new MidtransClient.CoreApi({
    isProduction,
    serverKey,
    clientKey: process.env.NEXT_PUBLIC_MIDTRANS_CLIENT_KEY ?? '',
  });
}

export const PREMIUM_PLAN = {
  id: 'menkyo-premium-monthly',
  name: 'Menkyo Master Premium',
  price: 98000,
  currency: 'IDR',
} as const;

export function buildOrderId(userId: string): string {
  const shortId = userId.replace(/-/g, '').slice(0, 6).toUpperCase();
  const ts = Date.now();
  return `MM-${shortId}-${ts}`;
}

export function extractUserIdFromOrderId(
  orderId: string,
  fullUserId: string
): string | null {
  if (orderId.startsWith('MM-')) return fullUserId;
  return null;
}
