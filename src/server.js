import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import { normalizePlate, assessVehicle } from './vehicle.js';
import { demoVehicle, fetchVehicle, LookupError } from './provider.js';

const publicDir = fileURLToPath(new URL('../public/', import.meta.url));
const assets = { '/': ['index.html', 'text/html'], '/app.js': ['app.js', 'text/javascript'], '/plate-reader.js': ['plate-reader.js', 'text/javascript'], '/style.css': ['style.css', 'text/css'], '/icon.svg': ['icon.svg', 'image/svg+xml'], '/manifest.webmanifest': ['manifest.webmanifest', 'application/manifest+json'] };

export function makeServer({ mode = 'demo', apiKey, fetchImpl, rateLimit = 30, dailyLimit = 50000, adText, adUrl } = {}) {
  if (!['demo', 'live'].includes(mode)) throw new Error('DATA_MODE må være demo eller live.');
  if (!Number.isSafeInteger(dailyLimit) || dailyLimit < 1) throw new Error('MAX_DAILY_LOOKUPS må være et positivt heltall.');
  let sponsor = null;
  if (adText || adUrl) {
    if (!adText || !adUrl || adText.length > 90) throw new Error('ANNONSE_TEKST og ANNONSE_URL må settes sammen (maks 90 tegn).');
    const url = new URL(adUrl);
    if (url.protocol !== 'https:' || url.username || url.password) throw new Error('ANNONSE_URL må være en HTTPS-adresse uten påloggingsdata.');
    sponsor = { text: adText, url: url.href };
  }
  const clients = new Map();
  let currentDay = new Date().toISOString().slice(0, 10);
  let dailyCount = 0;
  const cleanup = setInterval(() => {
    for (const [ip, item] of clients) if (item.until < Date.now()) clients.delete(ip);
  }, 60000).unref();
  const server = createServer(async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Referrer-Policy', 'no-referrer');
    res.setHeader('Permissions-Policy', 'camera=(self), microphone=(), geolocation=()');
    res.setHeader('Cross-Origin-Resource-Policy', 'same-origin');
    res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self' https://cdn.jsdelivr.net 'wasm-unsafe-eval'; worker-src 'self' blob:; style-src 'self'; img-src 'self' blob: data:; media-src 'self' blob:; connect-src 'self' https://cdn.jsdelivr.net https://tessdata.projectnaptha.com; object-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'");
    const json = (status, body) => { res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' }); res.end(JSON.stringify(body)); };
    try {
      const url = new URL(req.url, 'http://localhost');
      if (url.pathname === '/api/config' && req.method === 'GET') return json(200, { mode, sponsor });
      if (url.pathname === '/api/lookup') {
        if (req.method !== 'POST') { res.setHeader('Allow', 'POST'); return json(405, { error: 'Bruk POST.' }); }
        if (req.headers.origin && req.headers.origin !== `http://${req.headers.host}` && req.headers.origin !== `https://${req.headers.host}`) return json(403, { error: 'Ugyldig forespørsel.' });
        if (req.headers['sec-fetch-site'] === 'cross-site') return json(403, { error: 'Ugyldig forespørsel.' });
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
        if (mode === 'live') {
          const today = new Date().toISOString().slice(0, 10);
          if (today !== currentDay) { currentDay = today; dailyCount = 0; }
          if (dailyCount >= dailyLimit) { res.setHeader('Retry-After', '3600'); return json(429, { error: 'Dagens grense for oppslag er nådd. Prøv igjen senere.' }); }
          dailyCount++;
        }
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
  const server = makeServer({ mode, apiKey: process.env.SVV_API_KEY, dailyLimit: Number(process.env.MAX_DAILY_LOOKUPS ?? 50000), adText: process.env.ANNONSE_TEKST, adUrl: process.env.ANNONSE_URL });
  const host = process.env.HOST ?? '127.0.0.1';
  const port = Number(process.env.PORT ?? 3000);
  server.listen(port, host, () => console.log(`Tempo 100 Sjekk: http://${host}:${port} (${mode})`));
}
