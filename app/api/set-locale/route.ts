import { NextRequest, NextResponse } from 'next/server';
import { LOCALES } from '@/i18n/config';

export async function POST(req: NextRequest) {
  const { locale } = (await req.json()) as { locale: string };

  if (!(LOCALES as readonly string[]).includes(locale)) {
    return NextResponse.json({ error: 'Invalid locale' }, { status: 400 });
  }

  const response = NextResponse.json({ ok: true });
  response.cookies.set('tokkipass-locale', locale, {
    path: '/',
    maxAge: 60 * 60 * 24 * 365,
    sameSite: 'lax',
    httpOnly: false,
  });

  return response;
}
