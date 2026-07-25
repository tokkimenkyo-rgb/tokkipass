export const LOCALES = [
  'en', 'ja', 'id', 'zh', 'vi', 'ko', 'tl', 'pt', 'ne'
] as const;

export type Locale = (typeof LOCALES)[number];

export const DEFAULT_LOCALE: Locale = 'en';

export const LOCALE_META: Record<
  Locale,
  { name: string; nativeName: string; flag: string; dir: 'ltr' | 'rtl' }
> = {
  en: { name: 'English',    nativeName: 'English',      flag: '🇬🇧', dir: 'ltr' },
  ja: { name: 'Japanese',   nativeName: '日本語',        flag: '🇯🇵', dir: 'ltr' },
  id: { name: 'Indonesian', nativeName: 'Indonesia',    flag: '🇮🇩', dir: 'ltr' },
  zh: { name: 'Chinese',    nativeName: '中文',          flag: '🇨🇳', dir: 'ltr' },
  vi: { name: 'Vietnamese', nativeName: 'Tiếng Việt',   flag: '🇻🇳', dir: 'ltr' },
  ko: { name: 'Korean',     nativeName: '한국어',         flag: '🇰🇷', dir: 'ltr' },
  tl: { name: 'Filipino',   nativeName: 'Filipino',     flag: '🇵🇭', dir: 'ltr' },
  pt: { name: 'Portuguese', nativeName: 'Português',    flag: '🇧🇷', dir: 'ltr' },
  ne: { name: 'Nepali',     nativeName: 'नेपाली',        flag: '🇳🇵', dir: 'ltr' },
};

export const COUNTRY_TO_LOCALE: Record<string, Locale> = {
  GB: 'en', US: 'en', AU: 'en',
  JP: 'ja',
  ID: 'id',
  CN: 'zh', TW: 'zh', HK: 'zh',
  VN: 'vi',
  KR: 'ko',
  PH: 'tl',
  BR: 'pt', PT: 'pt',
  NP: 'ne',
};
