export default function handler(req, res) {
  if (req.method !== 'POST') {
    res.statusCode = 405;
    return res.end('Método não permitido');
  }

  let body = '';
  req.on('data', (chunk) => (body += chunk));
  req.on('end', () => {
    // Aceita application/x-www-form-urlencoded (form padrão)
    const params = new URLSearchParams(body || '');
    const password = params.get('password') || '';

    const VALID = process.env.LOGIN_PASSWORD || 'UFMS2025';
    if (password === VALID) {
      // Cookie de sessão
      res.setHeader(
        'Set-Cookie',
        'sess=ok; Path=/; HttpOnly; SameSite=Lax; Max-Age=43200; Secure'
      );
      res.writeHead(302, { Location: '/app' });
      return res.end();
    }

    // Senha errada -> volta pra /login com err=1
    res.writeHead(302, { Location: '/login?err=1' });
    return res.end();
  });
}

