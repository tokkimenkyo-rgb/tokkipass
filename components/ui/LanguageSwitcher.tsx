'use client';

import { useState, useRef, useEffect, useTransition } from 'react';
import { Globe, Check, ChevronDown } from 'lucide-react';
import { LOCALES, LOCALE_META, type Locale } from '@/i18n/config';

interface LanguageSwitcherProps {
  currentLocale: Locale;
  variant?: 'navbar' | 'standalone';
}

export function LanguageSwitcher({
  currentLocale,
  variant = 'navbar',
}: LanguageSwitcherProps) {
  const [open, setOpen] = useState(false);
  const [isPending, startTransition] = useTransition();
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  function handleSelect(locale: Locale) {
    setOpen(false);
    startTransition(async () => {
      await fetch('/api/set-locale', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ locale }),
      });
      window.location.reload();
    });
  }

  const current = LOCALE_META[currentLocale];

  return (
    <div ref={ref} className="relative">
      <button
        onClick={() => setOpen((v) => !v)}
        disabled={isPending}
        className={`flex items-center gap-1.5 text-sm transition-colors ${
          variant === 'navbar'
            ? 'text-gray-500 hover:text-gray-800 px-2 py-1.5 rounded-lg hover:bg-gray-100'
            : 'bg-white border border-gray-200 text-gray-700 px-3 py-2 rounded-xl hover:bg-gray-50'
        }`}
        aria-label="Select language"
        aria-expanded={open}
        aria-haspopup="listbox"
      >
        {isPending ? (
          <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3"
              strokeDasharray="40" strokeDashoffset="10" />
          </svg>
        ) : (
          <Globe className="w-4 h-4" />
        )}
        <span>{current.flag} {current.nativeName}</span>
        <ChevronDown
          className={`w-3 h-3 transition-transform ${open ? 'rotate-180' : ''}`}
        />
      </button>

      {open && (
        <div
          role="listbox"
          aria-label="Select language"
          className="absolute right-0 top-full mt-1.5 w-52 bg-white border border-gray-200 rounded-2xl shadow-xl overflow-hidden z-50"
        >
          <div className="py-1.5 max-h-80 overflow-y-auto">
            {LOCALES.map((locale) => {
              const meta = LOCALE_META[locale];
              const isSelected = locale === currentLocale;
              return (
                <button
                  key={locale}
                  role="option"
                  aria-selected={isSelected}
                  onClick={() => handleSelect(locale)}
                  className={`w-full flex items-center gap-3 px-3.5 py-2.5 text-left text-sm transition-colors ${
                    isSelected
                      ? 'bg-indigo-50 text-indigo-700'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <span className="text-base flex-shrink-0">{meta.flag}</span>
                  <span className="flex-1">
                    <span className="block font-medium">{meta.nativeName}</span>
                    <span className="block text-xs text-gray-400">{meta.name}</span>
                  </span>
                  {isSelected && (
                    <Check className="w-3.5 h-3.5 text-indigo-600 flex-shrink-0" />
                  )}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
