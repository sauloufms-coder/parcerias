// api/login.ts
export const config = {
  runtime: 'edge',
};

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

export default async function handler(req: Request) {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const secret = process.env.APP_PASSWORD || '';
  if (!secret) {
    return new Response('APP_PASSWORD not set', { status: 500 });
  }

  let body: any = {};
  try { body = await req.json(); } catch { /* ignore */ }

  const pw = (body?.password ?? '').toString();
  if (pw !== secret) {
    return new Response(JSON.stringify({ ok: false, error: 'invalid_password' }), {
      status: 401,
      headers: { 'content-type': 'application/json' },
    });
  }

  const data = 'ok';
  const b64 = btoa(data);
  const sig = await hmacHex(secret, data);
  const token = `v1.${b64}.${sig}`;

  // cookie por 12h
  const maxAge = 60 * 60 * 12;
  const cookie = [
    `pauth=${token}`,
    `Path=/`,
    `Max-Age=${maxAge}`,
    `HttpOnly`,
    `Secure`,
    `SameSite=Lax`,
  ].join('; ');

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: {
      'content-type': 'application/json',
      'set-cookie': cookie,
    },
  });
}

