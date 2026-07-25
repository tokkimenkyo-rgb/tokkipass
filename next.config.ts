import type { NextConfig } from 'next';
import createNextIntlPlugin from 'next-intl/plugin';

const withNextIntl = createNextIntlPlugin('./i18n/request.ts');

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.supabase.co',
      },
    ],
  },
  turbopack: {
    resolveAlias: {
      ws: './lib/empty-module.ts',
      bufferutil: './lib/empty-module.ts',
      'utf-8-validate': './lib/empty-module.ts',
    },
  },
};

export default withNextIntl(nextConfig);