# Tempo 100

En mobiltilpasset norsk webapp som slår opp tilhengerens registreringsnummer og undersøker om **teknisk underkode `TEMPO100`** finnes i Statens vegvesens registerdata.

**Navn for iOS og Android:** Tempo 100 - Tilhengersjekk. Flutter-kildekoden ligger i [`mobile/`](mobile/README.md) og bruker samme server for oppslag. Plattformfiler genereres med Flutter på utviklingsmaskinen; Android debug-APK bygges og testes i GitHub Actions.

**Status: testversjon.** Eieren har bekreftet live-oppslag med både godkjent og ikke godkjent tilhenger og testet kameraavlesning via Android-emulator. Demoen bruker utelukkende fiktive data. Appen avgjør ikke om en konkret bil/henger-kombinasjon har lov til å kjøre i 100 km/t.

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
- `public/`: norsk brukergrensesnitt, personvernerklæring (`/privacy`) og mobilmanifest.
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

## Sponsorannonse

Appen støtter en enkel, merket sponsorannonse på hovedsiden og i kameravisningen. Sett begge verdiene i serverens `.env` for å vise den:

```text
ANNONSE_TEKST=Eksempelpartner
ANNONSE_URL=https://example.com/
```

Teksten er begrenset til 90 tegn og lenken må bruke HTTPS. Banneret skjules når sponsor ikke er konfigurert. Det er ingen annonsenettverkskode, informasjonskapsler eller sporing i denne løsningen. Sponsorens nettsted får likevel brukerens vanlige nettverkstrafikk når vedkommende åpner lenken. Ved bruk av Google AdSense eller lignende må samtykke og personvern for deres teknologi vurderes separat.

## Publisering og personvern

Ingen database, analyseverktøy eller oppslagshistorikk er inkludert. Serveren logger ikke registreringsnumre eller rådata. Personvernerklæringen for appen ligger på `/privacy` og er også tilgjengelig fra appens startskjerm. Registreringsnummeret sendes til Statens vegvesen ved ekte oppslag og regnes som en personopplysning. Før offentlig lansering: avklar behandlingsgrunnlag, publiser personverntekst og sjekk vilkårene for viderebruk av API-data; kontroller også hostingens/proxyens logger. Bruk HTTPS med fungerende kameratilgang. Ratebegrensningen er per tilkoblings-IP i én serverprosess og stoler ikke på klientens X-Forwarded-For. `MAX_DAILY_LOOKUPS` begrenser antall live-oppslag per UTC-døgn i samme prosess (standard 50 000). Telleverket lagres bare i minnet og deles ikke mellom instanser eller omstarter; bruk ekstern kvote/ratebegrensning ved større offentlig drift.

Sammenlign et resultat fra en kjent Tempo 100-godkjent henger og en ordinær henger med vognkort/godkjenningsattest. Prøv kamera/OCR på en fysisk mobil i realistiske forhold før utgivelse. Grønn status gjelder bare registrert godkjenning for **hengeren**. Appen avgjør ikke om kjøringen er lovlig, og resultatet er ikke bevis for å anklage en annen trafikant.

## Kilder

- [API for kjøretøyopplysninger](https://www.vegvesen.no/fag/teknologi/apne-data/et-utvalg-apne-data/api-for-tekniske-kjoretoyopplysninger/)
- [Offisiell API-veiledning](https://autosys-kjoretoy-api.atlas.vegvesen.no/api-ui/index-api.html?apiId=enkeltoppslag)
- [OpenAPI-skjema](https://akfell-datautlevering.atlas.vegvesen.no/v3/api-docs)
- [Teknisk underkode: TEMPO100](https://autosys-kjoretoy-api.atlas.vegvesen.no/kodeverk-ui/index-kodeverk.html?kodeverkId=TEKNISKUNDERKODE)
- [Tempo 100 og krav til trekkbil/tilhenger](https://www.vegvesen.no/kjoretoy/eie-og-vedlikeholde/tilhenger/tempo100/krav-til-trekkbil-og-tilhenger-for-tempo-100-godkjenning/)

Undersøkt 3. oktober 2026.

## Kamera og enkel visning

Standardvisningen viser grønn registrert godkjenning, rød ingen registrert godkjenning eller gul ukjent. Detaljer ligger under Utvidet informasjon. Ingen registrert godkjenning er ikke et selvstendig bevis på en trafikkovertredelse.

Et stillbilde kan leses med Tesseract.js 5.1.1 i nettleseren; brukeren velger og kontrollerer nummeret før oppslag. Bildet lastes ikke opp eller lagres av appen. OCR-motor og språkdata lastes fra CDN ved første bruk og trenger nett. Vanlige norske skilt med to bokstaver og 4–5 sifre foreslås; personlige skilt kan skrives manuelt. Kamera/HEIC-støtte og presisjon må prøves på faktisk iPhone/Android.

### Direkte kamera og annonseplass

Kameraknappen åpner en direkte forhåndsvisning med bakre kamera og digital zoom. Kameraet stoppes ved lukking eller når siden skjules. Ingen videoopptak utføres. Kameratilgang krever HTTPS eller localhost. Bildevalg er tilgjengelig som alternativ. Hovedsiden og kameravisningen viser en merket direkte sponsorannonse hvis den er konfigurert.

### Automatisk skiltlesing

Direktekameravisningen analyserer nå kamerarammer fortløpende. Ett entydig norsk skilt med OCR-konfidens minst 70 må leses likt tre ganger på rad før nummeret fylles inn og oppslaget startes automatisk. Ingen Les skilt-knapp eller bildebekreftelse er nødvendig i direktekameramodus. Kameraet stopper etter funn. Ulike eller flere skilt gir ingen automatisk treff. OCR-konfidens er ikke en garanti for at nummeret er riktig, og resultatet viser alltid nummeret. Ytelse og presisjon ved bevegelse må prøves på reell mobil. Brukes av passasjer eller mens bilen er parkert. Bildevalgalternativet har fortsatt manuell nummerbekreftelse.
