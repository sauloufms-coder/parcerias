export default function handler(req, res) {
  res.setHeader('Set-Cookie', 'sess=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0');
  res.writeHead(302, { Location: '/login' });
  res.end();
}
