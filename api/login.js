// api/login.js
export default function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  const password = (req.body?.password || req.query?.password || '').toString();
  const expected = process.env.SITE_PASSWORD || '';

  if (!expected) {
    return res.status(500).send('SITE_PASSWORD não configurada no Vercel');
  }

  if (password !== expected) {
    return res.status(401).send('Senha incorreta');
  }

  // Cookie por 12 horas
  const maxAge = 60 * 60 * 12;
  res.setHeader('Set-Cookie', `sess=ok; Max-Age=${maxAge}; Path=/; HttpOnly; SameSite=Lax; Secure`);
  // Depois de logar, manda para o app
  return res.redirect(302, '/app/');
}

