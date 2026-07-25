import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';
import { createAdminClient } from '@/lib/supabase/admin';
import { upgradeUserToPremium } from '@/actions/upgrade-user';
import type { MidtransNotification } from '@/types/midtrans.types';
import { SUCCESSFUL_TRANSACTION_STATUSES } from '@/types/midtrans.types';

function validateMidtransSignature(
  notification: MidtransNotification,
  serverKey: string
): boolean {
  const { order_id, status_code, gross_amount, signature_key } = notification;

  const rawString = `${order_id}${status_code}${gross_amount}${serverKey}`;
  const expectedSignature = crypto
    .createHash('sha512')
    .update(rawString)
    .digest('hex');

  return expectedSignature === signature_key;
}

function isTransactionSuccessful(notification: MidtransNotification): boolean {
  const { transaction_status, fraud_status, payment_type } = notification;

  const isSuccessStatus = (
    SUCCESSFUL_TRANSACTION_STATUSES as readonly string[]
  ).includes(transaction_status);

  if (payment_type === 'credit_card') {
    return (
      transaction_status === 'capture' &&
      (fraud_status === 'accept' || fraud_status === undefined)
    );
  }

  return isSuccessStatus && fraud_status !== 'deny';
}

export async function POST(req: NextRequest) {
  const serverKey = process.env.MIDTRANS_SERVER_KEY;

  if (!serverKey) {
    console.error('[midtrans-webhook] MIDTRANS_SERVER_KEY not set');
    return NextResponse.json(
      { error: 'Server configuration error' },
      { status: 500 }
    );
  }

  let notification: MidtransNotification;
  try {
    notification = (await req.json()) as MidtransNotification;
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
  }

  const { order_id, transaction_status, transaction_id } = notification;

  console.info(
    `[midtrans-webhook] Received: order=${order_id} status=${transaction_status} txn=${transaction_id}`
  );

  const isValidSignature = validateMidtransSignature(notification, serverKey);
  if (!isValidSignature) {
    console.warn(
      `[midtrans-webhook] INVALID SIGNATURE for order=${order_id}`
    );
    return NextResponse.json(
      { error: 'Invalid signature' },
      { status: 401 }
    );
  }

  const adminClient = createAdminClient();

  const { data: orderData, error: orderError } = await adminClient
    .from('payment_orders')
    .select('id, user_id, status')
    .eq('order_id', order_id)
    .single();

  const order = orderData as {
    id: string;
    user_id: string;
    status: string;
  } | null;

  if (orderError || !order) {
    console.warn(`[midtrans-webhook] Order not found: ${order_id}`);
    return NextResponse.json(
      { message: 'Order not found, ignored' },
      { status: 200 }
    );
  }

  if (order.status === 'success') {
    console.info(
      `[midtrans-webhook] Order ${order_id} already processed, skipping`
    );
    return NextResponse.json({ message: 'Already processed' });
  }

  let newStatus: string;
  if (isTransactionSuccessful(notification)) {
    newStatus = 'success';
  } else if (transaction_status === 'expire') {
    newStatus = 'expired';
  } else if (
    transaction_status === 'cancel' ||
    transaction_status === 'deny'
  ) {
    newStatus = 'failed';
  } else {
    newStatus = 'pending';
  }

  const { error: updateOrderError } = await adminClient
    .from('payment_orders')
    .update({
      status: newStatus,
      midtrans_transaction_id: transaction_id,
      payment_type: notification.payment_type,
      updated_at: new Date().toISOString(),
    } as never)
    .eq('order_id', order_id);

  if (updateOrderError) {
    console.error(
      '[midtrans-webhook] Failed to update order:',
      updateOrderError
    );
    return NextResponse.json(
      { error: 'Database update failed' },
      { status: 500 }
    );
  }

  if (newStatus === 'success') {
    const upgradeResult = await upgradeUserToPremium(order.user_id);

    if (!upgradeResult.success) {
      console.error(
        `[midtrans-webhook] Upgrade failed for user ${order.user_id}:`,
        upgradeResult.error
      );
      return NextResponse.json(
        { message: 'Payment recorded but user upgrade failed - manual review needed' },
        { status: 200 }
      );
    }

    console.info(
      `[midtrans-webhook] SUCCESS: user ${order.user_id} upgraded to premium via order ${order_id}`
    );
  }

  return NextResponse.json({
    message: `Webhook processed: ${newStatus}`,
    orderId: order_id,
  });
}