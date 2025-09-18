// middleware.ts
import { NextRequest, NextResponse } from 'next/server';

export const config = {
  matcher: ['/app/:path*'], // protege tudo sob /app
};

const COOKIE_NAME = 'pauth';
const TOKEN_PLAINTEXT = 'ok'; // payload fixo
const TOKEN_PREFIX = 'v1';    // versão do token

async function hmacHex(secret: string, data: string): Promise<string> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(data));
  const b = new Uint8Array(sig);
  return [...b].map(x => x.toString(16).padStart(2, '0')).join('');
}

export default async function middleware(req: NextRequest) {
  const url = req.nextUrl;
  const cookie = req.cookies.get(COOKIE_NAME)?.value || '';

  // cookie esperado: v1.<base64(data)>.hexHmac
  const parts = cookie.split('.');
  if (parts.length === 3 && parts[0] === TOKEN_PREFIX) {
    const b64 = parts[1];
    const sig = parts[2];
    try {
      const data = atob(b64);
      // secret não disponível aqui; validação será reexecutada com segredo?
      // -> solução: o middleware também lê o segredo (Vercel expõe env em Edge)
      const secret = process.env.APP_PASSWORD || '';
      if (!secret) throw new Error('Missing APP_PASSWORD');

      const expectSig = await hmacHex(secret, data);
      if (data === TOKEN_PLAINTEXT && sig === expectSig) {
        // autorizado → segue
        return NextResponse.next();
      }
    } catch (_) {
      // cai para redirect
    }
  }

  // não autorizado → manda para /login (mantém destino em query para redirecionar depois, se quiser)
  const loginUrl = new URL('/login', req.url);
  return NextResponse.redirect(loginUrl);
}

