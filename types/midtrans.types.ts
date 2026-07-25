// Payload notification dari Midtrans webhook
export interface MidtransNotification {
  transaction_time: string;
  transaction_status: string;
  transaction_id: string;
  status_message: string;
  status_code: string;
  signature_key: string;
  payment_type: string;
  order_id: string;
  merchant_id: string;
  gross_amount: string;
  fraud_status?: string;
  currency: string;
  bank?: string;
  va_numbers?: Array<{ bank: string; va_number: string }>;
  payment_amounts?: Array<{ paid_at: string; amount: string }>;
}

export const SUCCESSFUL_TRANSACTION_STATUSES = [
  'capture',
  'settlement',
] as const;

export type SuccessfulTransactionStatus =
  (typeof SUCCESSFUL_TRANSACTION_STATUSES)[number];

export interface CreateSnapTokenRequest {
  userId: string;
  userEmail: string;
  userName: string;
}

export interface CreateSnapTokenResponse {
  token: string;
  redirectUrl: string;
  orderId: string;
}
