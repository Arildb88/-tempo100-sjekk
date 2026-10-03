const form = document.querySelector('#lookup');
const plate = document.querySelector('#plate');
const submit = document.querySelector('#submit');
const result = document.querySelector('#result');
const error = document.querySelector('#error');
let mode;
const node = (tag, text, className) => {
  const element = document.createElement(tag);
  if (text !== undefined) element.textContent = text;
  if (className) element.className = className;
  return element;
};
const display = (value) => value ?? 'Ikke oppgitt';
function render(data) {
  result.replaceChildren();
  result.className = `card result ${data.tempo100.status}`;
  if (data.mode === 'demo') result.append(node('p', 'DEMO · FIKTIVE DATA · IKKE ET REELT OPPSLAG', 'demo-label'));
  const compact = {
    approved: ['✓', 'Godkjent', 'Registrert for Tempo 100'],
    not_recorded: ['×', 'Ingen registrert godkjenning', 'Tempo 100-kode mangler i registeret'],
    unknown: ['?', 'Ukjent', 'Godkjenningen kan ikke bekreftes'],
    not_applicable: ['–', 'Ikke omfattet', 'Dette kjøretøyet er utenfor ordningen'],
  }[data.tempo100.status] ?? ['?', 'Ukjent', ''];
  result.append(node('span', data.plate, 'badge'), node('div', compact[0], 'status-symbol'), node('h2', compact[1]), node('p', compact[2], 'status-caption'));
  const expanded = node('details', undefined, 'expanded');
  expanded.append(node('summary', 'Utvidet informasjon'), node('p', data.tempo100.explanation));
  const details = node('dl');
  const fields = [
    ['Merke og modell', [data.vehicle.brand, data.vehicle.model].filter(Boolean).join(' ') || null],
    ['Kjøretøyklasse', data.vehicle.category], ['Tillatt totalvekt', data.vehicle.totalWeight == null ? null : `${data.vehicle.totalWeight} kg`],
    ['Registreringsstatus', data.vehicle.registration], ['Frist for EU-kontroll', data.inspection.deadline],
    ['Hentet', new Date(data.checkedAt).toLocaleString('nb-NO', { timeZone: 'Europe/Oslo' })],
  ];
  for (const [label, value] of fields) { const pair = node('div'); pair.append(node('dt', label), node('dd', display(value))); details.append(pair); }
  expanded.append(details);
  for (const warning of data.driving.blockers) expanded.append(node('p', warning, 'warning'));
  if (data.inspection.status === 'unknown') expanded.append(node('p', 'EU-kontrollstatus er ikke avklart i oppslaget.', 'small'));
  const notice = node('div', undefined, 'notice');
  notice.append(node('strong', 'Kan denne ekvipasjen kjøre i 100 km/t?'), node('p', data.driving.explanation));
  expanded.append(notice);
  const evidence = node('details'); evidence.append(node('summary', 'Datagrunnlag'));
  for (const item of data.tempo100.evidence) evidence.append(node('p', `${item.field}: ${item.code}`, 'small'));
  const source = node('a', 'Offisielt kodeverk for teknisk underkode ↗');
  source.href = data.tempo100.source; source.target = '_blank'; source.rel = 'noopener noreferrer';
  evidence.append(source); expanded.append(evidence); result.append(expanded); result.hidden = false;
}
form.addEventListener('submit', async (event) => {
  event.preventDefault(); error.hidden = true; result.hidden = true; submit.disabled = true; submit.textContent = 'Sjekker …';
  try {
    const response = await fetch('/api/lookup', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ plate: plate.value }), signal: AbortSignal.timeout(15000) });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error ?? 'Oppslaget feilet.');
    render(data);
  } catch (failure) { error.textContent = failure.name === 'TimeoutError' ? 'Oppslaget tok for lang tid. Prøv igjen.' : failure.message; error.hidden = false; }
  finally { submit.disabled = false; submit.textContent = 'Sjekk'; }
});
document.querySelectorAll('[data-plate]').forEach(button => button.addEventListener('click', () => { plate.value = button.dataset.plate; form.requestSubmit(); }));
async function initialize() {
  try {
    const response = await fetch('/api/config');
    if (!response.ok) throw new Error('Konfigurasjonen kunne ikke lastes.');
    ({ mode } = await response.json());
    const banner = document.querySelector('#mode');
    banner.textContent = mode === 'demo' ? 'Demo · Fiktive data' : 'Registeroppslag · Statens vegvesen';
    banner.classList.toggle('live', mode === 'live');
    document.querySelector('#demo').hidden = mode !== 'demo';
    plate.placeholder = mode === 'demo' ? 'DEMO100' : 'AB 1234';
    submit.disabled = false;
  } catch { document.querySelector('#mode').textContent = 'Kunne ikke koble til serveren. Last siden på nytt.'; }
}
initialize();

// Bildet behandles lokalt. OCR-motoren lastes først når et bilde velges.
const photo = document.querySelector('#camera-photo');
const scanStatus = document.querySelector('#scan-status');
const candidates = document.querySelector('#scan-candidates');
let ocrLoader;
function loadOCR() {
  if (window.Tesseract) return Promise.resolve(window.Tesseract);
  if (!ocrLoader) ocrLoader = new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/tesseract.js@5.1.1/dist/tesseract.min.js';
    script.onload = () => resolve(window.Tesseract);
    script.onerror = () => { script.remove(); ocrLoader = null; reject(new Error('Kameraleseren kunne ikke lastes. Skriv nummeret manuelt.')); };
    document.head.append(script);
  });
  return ocrLoader;
}
photo.addEventListener('change', async () => {
  const file = photo.files?.[0];
  if (!file) return;
  candidates.replaceChildren(); result.hidden = true; error.hidden = true;
  photo.disabled = true; submit.disabled = true;
  let worker, bitmap;
  try {
    if (!file.type.startsWith('image/')) throw new Error('Velg et bilde.');
    if (file.size > 25000000) throw new Error('Bildet er for stort. Ta et nytt bilde av skiltet.');
    scanStatus.textContent = 'Leser skilt … Første gang kan ta litt tid.';
    const engine = await loadOCR();
    bitmap = await createImageBitmap(file);
    const canvas = document.createElement('canvas');
    const ratio = Math.min(1, 1800 / Math.max(bitmap.width, bitmap.height));
    canvas.width = Math.round(bitmap.width * ratio); canvas.height = Math.round(bitmap.height * ratio);
    canvas.getContext('2d').drawImage(bitmap, 0, 0, canvas.width, canvas.height);
    worker = await engine.createWorker('eng', 1, { logger: message => {
      if (message.status === 'recognizing text') scanStatus.textContent = `Leser skilt … ${Math.round(message.progress * 100)} %`;
    } });
    await worker.setParameters({ tessedit_char_whitelist: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ', tessedit_pageseg_mode: '11' });
    const { data } = await worker.recognize(canvas);
    const matches = [...new Set((data.text.toUpperCase().match(/\b[A-Z]{2}\s*\d{4,5}\b/g) ?? []).map(text => text.replace(/\s/g, '')))];
    if (!matches.length) throw new Error('Fant ikke et tydelig skilt. Prøv et nærmere bilde eller skriv nummeret selv.');
    scanStatus.textContent = 'Velg riktig nummer. Kontroller og rett det før du trykker Sjekk.';
    for (const match of matches) {
      const button = node('button', match); button.type = 'button';
      button.addEventListener('click', () => { plate.value = match; plate.focus(); scanStatus.textContent = 'Kontroller nummeret og trykk Sjekk. Bildet er ikke lagret.'; candidates.replaceChildren(); });
      candidates.append(button);
    }
  } catch (failure) { scanStatus.textContent = failure.message || 'Kunne ikke lese bildet. Skriv nummeret manuelt.'; }
  finally { bitmap?.close(); if (worker) await worker.terminate().catch(() => {}); photo.value = ''; photo.disabled = false; submit.disabled = !mode; }
});
