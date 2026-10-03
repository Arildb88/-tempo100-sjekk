import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import { normalizePlate, assessVehicle } from './vehicle.js';
import { demoVehicle, fetchVehicle, LookupError } from './provider.js';

const publicDir = fileURLToPath(new URL('../public/', import.meta.url));
const assets = { '/': ['index.html', 'text/html'], '/app.js': ['app.js', 'text/javascript'], '/style.css': ['style.css', 'text/css'], '/icon.svg': ['icon.svg', 'image/svg+xml'], '/manifest.webmanifest': ['manifest.webmanifest', 'application/manifest+json'] };

export function makeServer({ mode = 'demo', apiKey, fetchImpl, rateLimit = 30 } = {}) {
  if (!['demo', 'live'].includes(mode)) throw new Error('DATA_MODE må være demo eller live.');
  const clients = new Map();
  const cleanup = setInterval(() => {
    for (const [ip, item] of clients) if (item.until < Date.now()) clients.delete(ip);
  }, 60000).unref();
  const server = createServer(async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Referrer-Policy', 'no-referrer');
    res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self' https://cdn.jsdelivr.net 'wasm-unsafe-eval'; worker-src 'self' blob:; style-src 'self'; img-src 'self' blob: data:; connect-src 'self' https://cdn.jsdelivr.net https://tessdata.projectnaptha.com; object-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'");
    const json = (status, body) => { res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' }); res.end(JSON.stringify(body)); };
    try {
      const url = new URL(req.url, 'http://localhost');
      if (url.pathname === '/api/config' && req.method === 'GET') return json(200, { mode });
      if (url.pathname === '/api/lookup') {
        if (req.method !== 'POST') { res.setHeader('Allow', 'POST'); return json(405, { error: 'Bruk POST.' }); }
        const ip = req.socket.remoteAddress;
        const existing = clients.get(ip);
        const bucket = existing?.until > Date.now() ? existing : { count: 0, until: Date.now() + 60000 };
        clients.set(ip, bucket);
        if (++bucket.count > rateLimit) { res.setHeader('Retry-After', '60'); return json(429, { error: 'For mange oppslag. Vent ett minutt.' }); }
        if (!req.headers['content-type']?.startsWith('application/json')) return json(415, { error: 'Bruk application/json.' });
        let body = ''; let bytes = 0;
        for await (const chunk of req) { bytes += chunk.length; if (bytes > 1024) return json(413, { error: 'Forespørselen er for stor.' }); body += chunk; }
        let plate;
        try { plate = normalizePlate(JSON.parse(body).plate); } catch { return json(400, { error: 'Skriv et norsk registreringsnummer med 2–7 bokstaver eller tall.' }); }
        const vehicle = mode === 'demo' ? demoVehicle(plate) : await fetchVehicle(plate, { apiKey, fetchImpl });
        return json(200, assessVehicle(vehicle, plate, { mode }));
      }
      const asset = assets[url.pathname];
      if (!asset) return json(404, { error: 'Siden finnes ikke.' });
      if (!['GET', 'HEAD'].includes(req.method)) return json(405, { error: 'Metoden støttes ikke.' });
      const content = await readFile(resolve(publicDir, asset[0]));
      res.writeHead(200, { 'Content-Type': `${asset[1]}; charset=utf-8` });
      res.end(req.method === 'HEAD' ? undefined : content);
    } catch (error) { json(error instanceof LookupError ? error.status : 500, { error: error instanceof LookupError ? error.message : 'En intern feil oppstod.' }); }
  });
  server.on('close', () => clearInterval(cleanup));
  server.requestTimeout = 15000;
  return server;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const mode = process.env.DATA_MODE ?? 'demo';
  const server = makeServer({ mode, apiKey: process.env.SVV_API_KEY });
  const host = process.env.HOST ?? '127.0.0.1';
  const port = Number(process.env.PORT ?? 3000);
  server.listen(port, host, () => console.log(`Tempo 100 Sjekk: http://${host}:${port} (${mode})`));
}
