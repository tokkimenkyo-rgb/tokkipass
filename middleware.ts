import { NextResponse, type NextRequest } from 'next/server';
import {
  LOCALES,
  DEFAULT_LOCALE,
  COUNTRY_TO_LOCALE,
  type Locale,
} from './i18n/config';

function detectLocale(request: NextRequest): Locale {
  const cookieLocale = request.cookies.get('tokkipass-locale')?.value;
  if (cookieLocale && (LOCALES as readonly string[]).includes(cookieLocale)) {
    return cookieLocale as Locale;
  }

  const acceptLang = request.headers.get('accept-language') ?? '';
  const preferred = acceptLang
    .split(',')
    .map((l) => l.split(';')[0].trim().toLowerCase().slice(0, 2));

  for (const lang of preferred) {
    if ((LOCALES as readonly string[]).includes(lang)) {
      return lang as Locale;
    }
  }

  const country = request.headers.get('cf-ipcountry') ?? '';
  if (country && COUNTRY_TO_LOCALE[country]) {
    return COUNTRY_TO_LOCALE[country];
  }

  return DEFAULT_LOCALE;
}

export function middleware(request: NextRequest) {
  const response = NextResponse.next();

  if (!request.cookies.get('tokkipass-locale')) {
    const detectedLocale = detectLocale(request);
    response.cookies.set('tokkipass-locale', detectedLocale, {
      path: '/',
      maxAge: 60 * 60 * 24 * 365,
      sameSite: 'lax',
    });
  }

  return response;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
};