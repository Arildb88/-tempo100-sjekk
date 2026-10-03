# Tempo 100 Sjekk

En mobiltilpasset norsk webapp som slår opp tilhengerens registreringsnummer og undersøker om **teknisk underkode `TEMPO100`** finnes i Statens vegvesens registerdata.

**Status: første versjon.** Kodeverket og API-strukturen er undersøkt. Ekte oppslag er ikke prøvd med en API-nøkkel eller en kjent Tempo 100-henger. Demoen bruker utelukkende fiktive data. Appen avgjør ikke om en konkret bil/henger-kombinasjon har lov til å kjøre i 100 km/t.

## Start lokalt

Installer Node.js 22 eller nyere. Ingen eksterne npm-pakker er nødvendige.

```sh
npm start
```

Åpne http://localhost:3000. Standard er demomodus. Trykk på eksempelknappene, eller skriv `DEMO100`, `DEMO80`, `DEMOU`, `DEMOE` eller `DEMOBIL`.

## Ekte oppslag

1. Bestill en API-nøkkel fra [Statens vegvesen](https://www.vegvesen.no/fag/teknologi/apne-data/et-utvalg-apne-data/api-for-tekniske-kjoretoyopplysninger/). Dette krever egen innlogging med norsk elektronisk ID.
2. Kopier `.env.example` til `.env`. På PowerShell: `Copy-Item .env.example .env`. På macOS/Linux: `cp .env.example .env`.
3. Sett `DATA_MODE=live` og `SVV_API_KEY=din-nøkkel` i `.env`. Ikke del nøkkelen i chat, frontend eller GitHub.
4. Start serveren på nytt med `npm start`.
5. Test med en kjent godkjent henger og sammenlign med vognkort/godkjenningsattest. Test også en ordinær og en utmeldt henger før løsningen tas i bruk.

Appen bruker `GET /enkeltoppslag/kjoretoydata?kjennemerke=...` mot Vegvesenet, med `SVV-Authorization: Apikey ...`. Nettleseren sender `POST /api/lookup` med `{ "plate": "AB1234" }` til egen server. API-nøkkelen forlater aldri serveren til nettleseren. Ekte API-feil gir feilmelding, aldri demoresultater.

## Hva statusene betyr

| Status | Betydning |
| --- | --- |
| Registrert som Tempo 100-godkjent | Klasse O1/O2 og entydig underkode TEMPO100 |
| Tempo 100-kode er ikke registrert | Klasse O1/O2 og annen eksplisitt underkode |
| Tempo 100 kan ikke bekreftes | Manglende klasse/underkode eller motstridende underkoder |
| Utenfor Tempo 100-ordningen | Kjøretøyklasse utenfor O1/O2 |

EU-kontrollfrist brukes ikke som bevis for Tempo 100-godkjenning. Utløpt frist eller annen registreringsstatus enn REGISTRERT flagges separat. En fremtidig kontrollfrist er heller ikke en garanti for at kjøretøyet har godkjent kontroll eller er lovlig å bruke akkurat nå.

Bilens ABS, egenvekt, totalvekt, tilhengerens utstyr, attestens krav, dekkenes alder, faktisk last og veiens fartsgrense er ikke kontrollert i denne versjonen. Resultatet er derfor en registerstatus, ikke en tillatelse til 100 km/t eller bevis på en trafikkovertredelse.

## Filer og tester

- `src/server.js`: HTTP-server, ruter, statiske filer, ratebegrensning.
- `src/provider.js`: Vegvesen-kall og fiktive demodata.
- `src/vehicle.js`: registerstatus og EU-kontrollfrist.
- `public/`: norsk brukergrensesnitt og mobilmanifest.
- `test/`: tester for manglende/motstridende data, API-feil, statuslogikk og HTTP.
- `docs/data-contract.md`: dokumenterte felter, kilder og gjenværende validering.
- `.github/workflows/ci.yml`: syntakssjekk og tester ved push/PR.

```sh
npm run check
npm test
```

## Docker

```sh
docker build -t tempo100-sjekk .
docker run --rm -p 3000:3000 tempo100-sjekk
```

For ekte oppslag: legg til `--env-file .env` før imagenavnet. Nettleseren kan legge siden til på hjemskjermen. Dette er en webapp med manifest; ingen offline-oppslag eller native App Store/Google Play-app er laget.

## Publisering og personvern

Ingen database, analyseverktøy eller oppslagshistorikk er inkludert. Serveren logger ikke registreringsnumre eller rådata. Registreringsnummeret sendes til Statens vegvesen ved ekte oppslag og er en personopplysning. Før offentlig lansering: avklar behandlingsgrunnlag, personverntekst og API-vilkår; kontroller også hostingens/proxyens logger. Bruk HTTPS og tilgangsbegrensning ved behov. Ratebegrensningen er per tilkoblings-IP i én serverprosess og stoler ikke på klientens X-Forwarded-For.

## Kilder

- [API for kjøretøyopplysninger](https://www.vegvesen.no/fag/teknologi/apne-data/et-utvalg-apne-data/api-for-tekniske-kjoretoyopplysninger/)
- [Offisiell API-veiledning](https://autosys-kjoretoy-api.atlas.vegvesen.no/api-ui/index-api.html?apiId=enkeltoppslag)
- [OpenAPI-skjema](https://akfell-datautlevering.atlas.vegvesen.no/v3/api-docs)
- [Teknisk underkode: TEMPO100](https://autosys-kjoretoy-api.atlas.vegvesen.no/kodeverk-ui/index-kodeverk.html?kodeverkId=TEKNISKUNDERKODE)
- [Tempo 100 og krav til trekkbil/tilhenger](https://www.vegvesen.no/kjoretoy/eie-og-vedlikeholde/tilhenger/tempo100/krav-til-trekkbil-og-tilhenger-for-tempo-100-godkjenning/)

Undersøkt 3. oktober 2026.
