export function plateCandidates(text) {
  return [...new Set((String(text).toUpperCase().match(/\b[A-Z]{2}\s*\d{4,5}\b/g) ?? []).map(value => value.replace(/\s/g, '')))];
}
export function makePlateTracker() {
  let previous = null, count = 0;
  return (text, confidence) => {
    const matches = plateCandidates(text);
    if (matches.length !== 1 || !Number.isFinite(confidence) || confidence < 70) { previous = null; count = 0; return null; }
    const candidate = matches[0];
    count = candidate === previous ? count + 1 : 1;
    previous = candidate;
    return count >= 3 ? candidate : null;
  };
}
