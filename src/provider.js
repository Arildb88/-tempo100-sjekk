export const SVV_ENDPOINT = 'https://akfell-datautlevering.atlas.vegvesen.no/enkeltoppslag/kjoretoydata';

export class LookupError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}

export async function fetchVehicle(plate, { apiKey, fetchImpl = fetch } = {}) {
  if (!apiKey) throw new LookupError(503, 'Ekte oppslag er ikke konfigurert. API-nøkkel fra Statens vegvesen mangler.');
  const url = new URL(SVV_ENDPOINT);
  url.searchParams.set('kjennemerke', plate);
  let response;
  try {
    response = await fetchImpl(url, {
      headers: { 'SVV-Authorization': `Apikey ${apiKey}`, Accept: 'application/json' },
      signal: AbortSignal.timeout(10000),
    });
  } catch { throw new LookupError(502, 'Statens vegvesen kunne ikke nås. Prøv igjen senere.'); }
  if ([401, 403].includes(response.status)) throw new LookupError(503, 'API-tilgangen må kontrolleres av administrator.');
  if ([429, 422].includes(response.status)) throw new LookupError(503, 'Oppslagskvoten hos Statens vegvesen er brukt opp. Prøv senere.');
  if (response.status === 404) throw new LookupError(404, 'Kjøretøyet ble ikke funnet.');
  if (!response.ok) throw new LookupError(502, 'Oppslaget hos Statens vegvesen feilet.');
  let payload;
  try { payload = await response.json(); } catch { throw new LookupError(502, 'Ugyldig svar fra Statens vegvesen.'); }
  if (payload?.feilmelding) throw new LookupError(404, 'Kjøretøyopplysninger er ikke tilgjengelige for dette registreringsnummeret.');
  if (!Array.isArray(payload?.kjoretoydataListe)) throw new LookupError(502, 'Svaret fra Statens vegvesen mangler kjøretøydata.');
  if (!payload.kjoretoydataListe.length) throw new LookupError(404, 'Kjøretøyet ble ikke funnet.');
  if (payload.kjoretoydataListe.length !== 1 || !payload.kjoretoydataListe[0]?.kjoretoyId) throw new LookupError(502, 'Oppslaget ga ikke ett entydig kjøretøy.');
  const vehicle = payload.kjoretoydataListe[0];
  // Personlige kjennemerker kan avvike fra ordinært kjennemerke i responsen.
  return vehicle;
}

export function demoVehicle(plate) {
  // Kun fiktive eksempler, aldri fallback etter feil i et ekte oppslag.
  const fixtures = {
    DEMO100: ['O2', 'TEMPO100', '2030-10-01'],
    DEMO80: ['O2', 'INGENKODE', null],
    DEMOU: ['O2', null, '2030-10-01'],
    DEMOE: ['O2', 'TEMPO100', '2020-01-01'],
    DEMOBIL: ['M1', 'INGENKODE', '2030-10-01'],
  };
  const fixture = fixtures[plate];
  if (!fixture) throw new LookupError(404, 'Demomodus: bruk DEMO100, DEMO80, DEMOU, DEMOE eller DEMOBIL.');
  const [category, undercode, deadline] = fixture;
  return {
    kjoretoyId: { kjennemerke: plate },
    registrering: { registreringsstatus: { kodeVerdi: 'REGISTRERT', kodeBeskrivelse: 'Registrert (fiktivt)' } },
    godkjenning: { tekniskGodkjenning: {
      kjoretoyklassifisering: { tekniskKode: { kodeVerdi: category }, ...(undercode && { tekniskUnderkode: { kodeVerdi: undercode } }) },
      tekniskeData: { generelt: { merke: [{ merke: 'Eksempelhenger' }], handelsbetegnelse: ['Fiktive demonstrasjonsdata'] }, vekter: { tillattTotalvekt: 1500 } },
    } },
    periodiskKjoretoyKontroll: { kontrollfrist: deadline },
  };
}
