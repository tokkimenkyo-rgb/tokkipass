'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { Eye, EyeOff, UserPlus, AlertCircle, CheckCircle2 } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

type FormStep = 'form' | 'success';

export default function RegisterForm() {
  const [step, setStep] = useState<FormStep>('form');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [isPending, startTransition] = useTransition();

  const supabase = createClient();

  function validate(): string | null {
    if (!fullName.trim()) return 'Nama lengkap wajib diisi.';
    if (!email) return 'Email wajib diisi.';
    if (password.length < 8) return 'Password minimal 8 karakter.';
    if (password !== confirmPassword) return 'Password dan konfirmasi tidak cocok.';
    return null;
  }

  function handleRegister() {
    setErrorMsg('');
    const validationError = validate();
    if (validationError) {
      setErrorMsg(validationError);
      return;
    }

    startTransition(async () => {
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { full_name: fullName.trim() },
          emailRedirectTo: `${window.location.origin}/dashboard`,
        },
      });

      if (error) {
        if (error.message.includes('User already registered')) {
          setErrorMsg('Email ini sudah terdaftar. Silakan login.');
        } else {
          setErrorMsg(error.message);
        }
        return;
      }

      setStep('success');
    });
  }

  if (step === 'success') {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 to-indigo-50 flex items-center justify-center p-4">
        <div className="w-full max-w-sm bg-white rounded-3xl shadow-xl border border-gray-100 p-8 text-center">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-green-100 rounded-full mb-4">
            <CheckCircle2 className="w-8 h-8 text-green-600" />
          </div>
          <h2 className="text-xl font-extrabold text-gray-900 mb-2">Cek Email Kamu!</h2>
          <p className="text-sm text-gray-500 leading-relaxed mb-2">
            Link konfirmasi sudah dikirim ke
          </p>
          <p className="text-sm font-bold text-indigo-600 mb-6">{email}</p>
          <p className="text-xs text-gray-400 mb-6">
            Cek folder Spam jika tidak muncul dalam 5 menit.
          </p>
          <Link
            href="/login"
            className="block w-full py-3 bg-indigo-600 text-white font-bold rounded-xl hover:bg-indigo-700 transition-colors"
          >
            Kembali ke Login
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-indigo-50 flex items-center justify-center p-4">
      <div className="w-full max-w-sm">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-indigo-600 rounded-2xl mb-4 shadow-lg shadow-indigo-200">
            <span className="text-3xl text-white font-black">免</span>
          </div>
          <h1 className="text-2xl font-extrabold text-gray-900">Daftar Gratis</h1>
          <p className="text-sm text-gray-500 mt-1">Mulai latihan ujian SIM Jepang</p>
        </div>

        <div className="bg-white rounded-3xl shadow-xl border border-gray-100 p-6 space-y-4">
          {errorMsg && (
            <div className="flex items-start gap-2.5 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-3.5 py-3">
              <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-700" htmlFor="fullName">
              Nama Lengkap
            </label>
            <input
              id="fullName"
              type="text"
              autoComplete="name"
              placeholder="Ahmad Jabir"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 outline-none text-sm transition-all"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-700" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              type="email"
              autoComplete="email"
              placeholder="nama@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 outline-none text-sm transition-all"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-700" htmlFor="password">
              Password
            </label>
            <div className="relative">
              <input
                id="password"
                type={showPassword ? 'text' : 'password'}
                autoComplete="new-password"
                placeholder="Minimal 8 karakter"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 pr-11 rounded-xl border border-gray-200 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 outline-none text-sm transition-all"
              />
              <button
                type="button"
                onClick={() => setShowPassword((v) => !v)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                aria-label={showPassword ? 'Sembunyikan' : 'Tampilkan'}
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-gray-700" htmlFor="confirmPassword">
              Konfirmasi Password
            </label>
            <input
              id="confirmPassword"
              type={showPassword ? 'text' : 'password'}
              autoComplete="new-password"
              placeholder="Ulangi password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleRegister()}
              className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 outline-none text-sm transition-all"
            />
          </div>

          {password.length > 0 && (
            <div className="space-y-1">
              <div className="flex gap-1">
                {[...Array(4)].map((_, i) => {
                  const strength =
                    password.length >= 12
                      ? 4
                      : password.length >= 10
                      ? 3
                      : password.length >= 8
                      ? 2
                      : 1;
                  return (
                    <div
                      key={i}
                      className={`h-1 flex-1 rounded-full transition-colors ${
                        i < strength
                          ? strength <= 1
                            ? 'bg-red-400'
                            : strength <= 2
                            ? 'bg-amber-400'
                            : strength <= 3
                            ? 'bg-blue-400'
                            : 'bg-green-400'
                          : 'bg-gray-200'
                      }`}
                    />
                  );
                })}
              </div>
              <p className="text-xs text-gray-400">
                {password.length < 8
                  ? 'Terlalu pendek'
                  : password.length < 10
                  ? 'Cukup'
                  : password.length < 12
                  ? 'Bagus'
                  : 'Kuat'}
              </p>
            </div>
          )}

          <button
            onClick={handleRegister}
            disabled={isPending}
            className="flex items-center justify-center gap-2 w-full py-3.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-300 text-white font-bold rounded-xl shadow-lg shadow-indigo-200 active:scale-[0.98] transition-all duration-200"
          >
            {isPending ? (
              <>
                <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" strokeDasharray="40" strokeDashoffset="10" />
                </svg>
                Mendaftar...
              </>
            ) : (
              <>
                <UserPlus className="w-4 h-4" />
                Daftar Sekarang
              </>
            )}
          </button>

          <div className="text-center text-sm text-gray-500">
            Sudah punya akun?{' '}
            <Link href="/login" className="text-indigo-600 font-semibold hover:underline">
              Masuk
            </Link>
          </div>

          <p className="text-xs text-gray-400 text-center">
            Dengan mendaftar, kamu setuju dengan{' '}
            <Link href="/terms" className="underline hover:text-gray-600">
              Syarat & Ketentuan
            </Link>{' '}
            kami.
          </p>
        </div>
      </div>
    </div>
  );
}