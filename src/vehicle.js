export const UNDERCODE_SOURCE = 'https://autosys-kjoretoy-api.atlas.vegvesen.no/kodeverk-ui/index-kodeverk.html?kodeverkId=TEKNISKUNDERKODE';

export function normalizePlate(value) {
  if (typeof value !== 'string' || value.length > 30) throw new Error('Ugyldig registreringsnummer.');
  const plate = value.replace(/\s/g, '').toUpperCase();
  // Ordinære, veteran- og personlige norske kjennemerker (2–7 tegn).
  if (!/^[A-ZÆØÅ0-9]{2,7}$/u.test(plate)) throw new Error('Bruk et norsk registreringsnummer med 2–7 bokstaver eller tall.');
  return plate;
}

const value = (code) => typeof code?.kodeVerdi === 'string' ? code.kodeVerdi.trim().toUpperCase() : null;

export function assessVehicle(vehicle, plate, { mode = 'live', now = new Date() } = {}) {
  const technical = vehicle.godkjenning?.tekniskGodkjenning;
  const classification = technical?.kjoretoyklassifisering;
  const data = technical?.tekniskeData;
  const category = value(classification?.tekniskKode) ?? value(data?.generelt?.tekniskKode);
  const candidates = [
    ['godkjenning.tekniskGodkjenning.kjoretoyklassifisering.tekniskUnderkode.kodeVerdi', value(classification?.tekniskUnderkode)],
    ['godkjenning.tekniskGodkjenning.tekniskeData.generelt.tekniskUnderkode.kodeVerdi', value(data?.generelt?.tekniskUnderkode)],
  ].filter(([, code]) => code !== null);
  const codes = [...new Set(candidates.map(([, code]) => code))];
  let status = 'unknown';
  let title = 'Tempo 100 kan ikke bekreftes';
  let explanation = 'Oppslaget mangler en entydig teknisk underkode. Manglende data betyr ikke at hengeren er uten godkjenning.';
  if (category && !['O1', 'O2'].includes(category)) {
    status = 'not_applicable'; title = 'Utenfor Tempo 100-ordningen';
    explanation = 'Denne ordningen gjelder tilhengere i kjøretøyklasse O1 og O2.';
  } else if (['O1', 'O2'].includes(category) && codes.length === 1) {
    if (codes[0] === 'TEMPO100') {
      status = 'approved'; title = 'Registrert som Tempo 100-godkjent';
      explanation = 'Teknisk underkode TEMPO100 er registrert på hengeren. Dette bekrefter registrert godkjenning, men ikke at den aktuelle kjøringen oppfyller alle krav.';
    } else {
      status = 'not_recorded'; title = 'Tempo 100-kode er ikke registrert';
      explanation = 'Oppslaget har en annen teknisk underkode enn TEMPO100. Kontroller vognkort og godkjenningsattest hvis dette er uventet.';
    }
  } else if (codes.length > 1) {
    explanation = 'Oppslaget inneholder motstridende tekniske underkoder. Godkjenningen må kontrolleres hos Statens vegvesen.';
  }
  const today = new Intl.DateTimeFormat('sv-SE', { timeZone: 'Europe/Oslo' }).format(now);
  const deadline = vehicle.periodiskKjoretoyKontroll?.kontrollfrist;
  const validDate = typeof deadline === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(deadline)
    && !Number.isNaN(Date.parse(deadline)) && new Date(deadline).toISOString().slice(0, 10) === deadline;
  const inspection = !validDate ? 'unknown' : deadline < today ? 'overdue' : 'within_deadline';
  const registration = vehicle.registrering?.registreringsstatus;
  const registrationCode = value(registration);
  const blockers = [];
  if (inspection === 'overdue') blockers.push('Fristen for EU-kontroll er utløpt.');
  if (registrationCode && registrationCode !== 'REGISTRERT') blockers.push('Registreringsstatus må avklares før kjøring.');
  return {
    plate, mode, checkedAt: now.toISOString(),
    vehicle: {
      brand: data?.generelt?.merke?.[0]?.merke ?? null,
      model: data?.generelt?.handelsbetegnelse?.[0] ?? null,
      category, totalWeight: data?.vekter?.tillattTotalvekt ?? null,
      registration: registration?.kodeBeskrivelse ?? registration?.kodeNavn ?? registrationCode,
    },
    tempo100: { status, title, explanation, evidence: candidates.map(([field, code]) => ({ field, code })), source: UNDERCODE_SOURCE },
    inspection: { status: inspection, deadline: validDate ? deadline : null, lastApproved: vehicle.periodiskKjoretoyKontroll?.sistGodkjent ?? null },
    driving: {
      status: blockers.length ? 'requires_attention' : 'not_assessed', blockers,
      explanation: 'Lovlig kjøring i 100 km/t kan ikke avgjøres fra hengerens registreringsnummer alene. Trekkbil, godkjenningsattest, dekk, last og veiens fartsgrense må også kontrolleres.',
    },
  };
}
