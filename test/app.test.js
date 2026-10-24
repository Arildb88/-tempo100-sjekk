import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizePlate, assessVehicle } from '../src/vehicle.js';
import { demoVehicle, fetchVehicle, SVV_ENDPOINT } from '../src/provider.js';
import { makeServer } from '../src/server.js';

const now = new Date('2026-10-03T12:00:00Z');
const assess = (plate) => assessVehicle(demoVehicle(plate), plate, { now });
test('normalizes ordinary and personal plates; rejects injection and invalid types', () => {
  assert.equal(normalizePlate(' ab 1234 '), 'AB1234');
  assert.equal(normalizePlate('ørn'), 'ØRN');
  for (const bad of ['../env', '<svg>', '', 'TOOLONG8', null, 123]) assert.throws(() => normalizePlate(bad));
});
test('TEMPO100 is registry approval, never permission for the whole combination', () => {
  const result = assess('DEMO100');
  assert.equal(result.tempo100.status, 'approved');
  assert.equal(result.driving.status, 'not_assessed');
  assert.equal(result.tempo100.evidence[0].code, 'TEMPO100');
});
test('EU deadline and free-text remarks cannot establish approval', () => {
  const vehicle = demoVehicle('DEMOU');
  vehicle.godkjenning.kjoretoymerknad = [{ merknad: 'Ikke godkjent for Tempo100' }];
  assert.equal(assessVehicle(vehicle, 'DEMOU', { now }).tempo100.status, 'unknown');
});
test('known different code is separate from missing data', () => {
  assert.equal(assess('DEMO80').tempo100.status, 'not_recorded');
  assert.equal(assess('DEMOU').tempo100.status, 'unknown');
  assert.equal(assess('DEMOBIL').tempo100.status, 'not_applicable');
});
test('overdue inspection does not erase approval; it flags driving', () => {
  const result = assess('DEMOE');
  assert.equal(result.tempo100.status, 'approved');
  assert.equal(result.inspection.status, 'overdue');
  assert.equal(result.driving.status, 'requires_attention');
});
test('conflicting codes and missing category are unknown', () => {
  const vehicle = demoVehicle('DEMO100');
  vehicle.godkjenning.tekniskGodkjenning.tekniskeData.generelt.tekniskUnderkode = { kodeVerdi: 'INGENKODE' };
  assert.equal(assessVehicle(vehicle, 'DEMO100', { now }).tempo100.status, 'unknown');
  delete vehicle.godkjenning.tekniskGodkjenning.kjoretoyklassifisering;
  assert.equal(assessVehicle(vehicle, 'DEMO100', { now }).tempo100.status, 'unknown');
});
test('deadline is inclusive and uses Norwegian calendar day', () => {
  const vehicle = demoVehicle('DEMO100');
  vehicle.periodiskKjoretoyKontroll.kontrollfrist = '2026-10-03';
  assert.equal(assessVehicle(vehicle, 'DEMO100', { now }).inspection.status, 'within_deadline');
  assert.equal(assessVehicle(vehicle, 'DEMO100', { now: new Date('2026-10-03T22:01:00Z') }).inspection.status, 'overdue');
  vehicle.periodiskKjoretoyKontroll.kontrollfrist = '2026-02-30';
  assert.equal(assessVehicle(vehicle, 'DEMO100', { now }).inspection.status, 'unknown');
});
test('provider uses documented endpoint and keeps key in header', async () => {
  const vehicle = await fetchVehicle('AB1234', { apiKey: 'test-secret', fetchImpl: async (url, options) => {
    assert.equal(url.origin + url.pathname, SVV_ENDPOINT);
    assert.equal(url.searchParams.get('kjennemerke'), 'AB1234');
    assert.equal(options.headers['SVV-Authorization'], 'Apikey test-secret');
    assert.equal(url.href.includes('test-secret'), false);
    return Response.json({ kjoretoydataListe: [demoVehicle('DEMO100')] });
  } });
  assert.ok(vehicle.kjoretoyId);
});
test('provider fails explicitly on quota, authentication, malformed or ambiguous responses', async () => {
  for (const status of [403, 429, 422, 500]) {
    await assert.rejects(fetchVehicle('AB1234', { apiKey: 'secret', fetchImpl: async () => new Response('', { status }) }));
  }
  for (const data of [{}, { feilmelding: 'OPPLYSNINGER_IKKE_TILGJENGELIGE' }, { kjoretoydataListe: [] }, { kjoretoydataListe: [demoVehicle('DEMO100'), demoVehicle('DEMO80')] }]) {
    await assert.rejects(fetchVehicle('AB1234', { apiKey: 'secret', fetchImpl: async () => Response.json(data) }));
  }
});
async function running(t, options) {
  const server = makeServer(options);
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => { server.close(resolve); server.closeAllConnections(); }));
  const origin = `http://127.0.0.1:${server.address().port}`;
  return { origin, post: (plate) => fetch(`${origin}/api/lookup`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ plate }) }) };
}
test('HTTP demo flow, bad input, security headers and static path allowlist', async t => {
  const { origin, post } = await running(t, { mode: 'demo' });
  const response = await post('DEMO100');
  assert.equal(response.status, 200);
  assert.equal((await response.json()).mode, 'demo');
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.ok(response.headers.get('content-security-policy').includes("frame-ancestors 'none'"));
  assert.equal((await post('<svg>')).status, 400);
  assert.equal((await post('AB1234')).status, 404);
  assert.equal((await fetch(`${origin}/.env`)).status, 404);
  assert.equal((await fetch(`${origin}/api/lookup`)).status, 405);
  for (const path of ['/', '/app.js', '/style.css', '/icon.svg', '/manifest.webmanifest', '/privacy', '/privacy.html']) assert.equal((await fetch(origin + path)).status, 200);
  const policy = await (await fetch(origin + '/privacy')).text();
  assert.match(policy, /Personvernerklæring/);
  assert.match(policy, /Google Mobile Ads SDK/);
});
test('live mode never silently returns demo results or exposes keys', async t => {
  const { post } = await running(t, { mode: 'live', apiKey: 'private-secret', fetchImpl: async () => { throw new Error('private-secret'); } });
  const response = await post('DEMO100');
  assert.equal(response.status, 502);
  assert.equal((await response.text()).includes('private-secret'), false);
});
test('missing API key and rate limiting are explicit', async t => {
  const { post } = await running(t, { mode: 'live', rateLimit: 1 });
  assert.equal((await post('AB1234')).status, 503);
  assert.equal((await post('AB1234')).status, 429);
});
test('configured sponsor is public while the API key stays private', async t => {
  const { origin } = await running(t, { mode: 'live', apiKey: 'private-secret', adText: 'Eksempelpartner', adUrl: 'https://example.com/' });
  const config = await (await fetch(`${origin}/api/config`)).json();
  assert.deepEqual(config.sponsor, { text: 'Eksempelpartner', url: 'https://example.com/' });
  assert.equal(JSON.stringify(config).includes('private-secret'), false);
  assert.equal((await fetch(origin)).headers.get('permissions-policy'), 'camera=(self), microphone=(), geolocation=()');
  assert.throws(() => makeServer({ adText: 'Utrygt', adUrl: 'javascript:alert(1)' }));
});
test('cross-site requests are denied and a daily budget limits live API calls', async t => {
  let calls = 0;
  const { origin, post } = await running(t, { mode: 'live', apiKey: 'secret', dailyLimit: 1, fetchImpl: async () => { calls++; return Response.json({ kjoretoydataListe: [demoVehicle('DEMO100')] }); } });
  const otherSite = await fetch(`${origin}/api/lookup`, { method: 'POST', headers: { Origin: 'https://other.example', 'Content-Type': 'application/json' }, body: JSON.stringify({ plate: 'AB1234' }) });
  assert.equal(otherSite.status, 403);
  assert.equal((await post('AB1234')).status, 200);
  assert.equal((await post('AB1234')).status, 429);
  assert.equal(calls, 1);
});
