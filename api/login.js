export default function handler(req, res) {
  if (req.method === "POST") {
    let body = "";
    req.on("data", chunk => body += chunk);
    req.on("end", () => {
      const params = new URLSearchParams(body);
      const password = params.get("password");

      // 🔑 Defina sua senha fixa aqui
      if (password === "UFMS2025") {
        // Define cookie de sessão válido
        res.setHeader("Set-Cookie", "sess=ok; Path=/; HttpOnly; 
SameSite=Lax; Max-Age=3600");
        res.writeHead(302, { Location: "/app" });
        res.end();
      } else {
        res.statusCode = 401;
        res.end("Senha incorreta");
      }
    });
  } else {
    res.statusCode = 405;
    res.end("Método não permitido");
  }
}

