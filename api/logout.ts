// api/logout.ts
export const config = {
  runtime: 'edge',
};

export default function handler(_req: Request) {
  const cookie = [
    `pauth=`,
    `Path=/`,
    `Max-Age=0`,
    `HttpOnly`,
    `Secure`,
    `SameSite=Lax`,
  ].join('; ');

  return new Response('OK', {
    status: 200,
    headers: { 'set-cookie': cookie },
  });
}

