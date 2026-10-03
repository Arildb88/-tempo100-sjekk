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
  result.append(node('span', data.plate, 'badge'), node('h2', data.tempo100.title), node('p', data.tempo100.explanation));
  const details = node('dl');
  const fields = [
    ['Merke og modell', [data.vehicle.brand, data.vehicle.model].filter(Boolean).join(' ') || null],
    ['Kjøretøyklasse', data.vehicle.category], ['Tillatt totalvekt', data.vehicle.totalWeight == null ? null : `${data.vehicle.totalWeight} kg`],
    ['Registreringsstatus', data.vehicle.registration], ['Frist for EU-kontroll', data.inspection.deadline],
    ['Hentet', new Date(data.checkedAt).toLocaleString('nb-NO', { timeZone: 'Europe/Oslo' })],
  ];
  for (const [label, value] of fields) { const pair = node('div'); pair.append(node('dt', label), node('dd', display(value))); details.append(pair); }
  result.append(details);
  for (const warning of data.driving.blockers) result.append(node('p', warning, 'warning'));
  if (data.inspection.status === 'unknown') result.append(node('p', 'EU-kontrollstatus er ikke avklart i oppslaget.', 'small'));
  const notice = node('div', undefined, 'notice');
  notice.append(node('strong', 'Kan denne ekvipasjen kjøre i 100 km/t?'), node('p', data.driving.explanation));
  result.append(notice);
  const evidence = node('details'); evidence.append(node('summary', 'Datagrunnlag'));
  for (const item of data.tempo100.evidence) evidence.append(node('p', `${item.field}: ${item.code}`, 'small'));
  const source = node('a', 'Offisielt kodeverk for teknisk underkode ↗');
  source.href = data.tempo100.source; source.target = '_blank'; source.rel = 'noopener noreferrer';
  evidence.append(source); result.append(evidence); result.hidden = false;
}
form.addEventListener('submit', async (event) => {
  event.preventDefault(); error.hidden = true; result.hidden = true; submit.disabled = true; submit.textContent = 'Sjekker …';
  try {
    const response = await fetch('/api/lookup', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ plate: plate.value }), signal: AbortSignal.timeout(15000) });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error ?? 'Oppslaget feilet.');
    render(data);
  } catch (failure) { error.textContent = failure.name === 'TimeoutError' ? 'Oppslaget tok for lang tid. Prøv igjen.' : failure.message; error.hidden = false; }
  finally { submit.disabled = false; submit.textContent = 'Sjekk hengeren →'; }
});
document.querySelectorAll('[data-plate]').forEach(button => button.addEventListener('click', () => { plate.value = button.dataset.plate; form.requestSubmit(); }));
async function initialize() {
  try {
    const response = await fetch('/api/config');
    if (!response.ok) throw new Error('Konfigurasjonen kunne ikke lastes.');
    ({ mode } = await response.json());
    const banner = document.querySelector('#mode');
    banner.textContent = mode === 'demo' ? 'Demomodus · Kun fiktive eksempler. Ekte oppslag krever API-nøkkel.' : 'Ekte oppslag · Tekniske registerdata fra Statens vegvesen';
    banner.classList.toggle('live', mode === 'live');
    document.querySelector('#demo').hidden = mode !== 'demo';
    plate.placeholder = mode === 'demo' ? 'DEMO100' : 'AB 1234';
    submit.disabled = false;
  } catch { document.querySelector('#mode').textContent = 'Kunne ikke koble til serveren. Last siden på nytt.'; }
}
initialize();
