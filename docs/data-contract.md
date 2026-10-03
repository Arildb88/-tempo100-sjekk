# Datagrunnlag og validering

Undersøkt 2026-10-03. Statens vegvesens kodeverk TEKNISKUNDERKODE definerer `TEMPO100` som «Godkjent for Tempo100». Dette er kode for den konkrete registrerte hengeren, ikke dokumentasjon på at en modell kunne blitt godkjent.

## Felt fra offisielt OpenAPI-skjema

Respons: `kjoretoydataListe` med objekter av typen `EnkeltOppslagKjoretoydata`.

| Felt i kjøretøyobjektet | Bruk |
| --- | --- |
| `godkjenning.tekniskGodkjenning.kjoretoyklassifisering.tekniskKode.kodeVerdi` | Klasse O1/O2 |
| `godkjenning.tekniskGodkjenning.kjoretoyklassifisering.tekniskUnderkode.kodeVerdi` | TEMPO100-status |
| `godkjenning.tekniskGodkjenning.tekniskeData.generelt.tekniskKode.kodeVerdi` | Alternativ klasseplassering i skjemaet |
| `godkjenning.tekniskGodkjenning.tekniskeData.generelt.tekniskUnderkode.kodeVerdi` | Alternativ underkodeplassering; avvik mellom feltene gir ukjent |
| `periodiskKjoretoyKontroll.kontrollfrist` | Frist, ikke Tempo 100-bevis |
| `registrering.registreringsstatus` | Separat registreringsstatus |

Skjemaet definerer feltene, men dokumenterer ikke uttrykkelig at alle Tempo 100-hengere alltid får feltet utlevert i denne API-tjenesten. Derfor er dette en implementasjon basert på dokumentert kodeverk og struktur som må valideres mot reelle oppslag. Manglende felt gir ukjent. Fritekst, maksimal konstruktiv hastighet, historiske koder og EU-frist brukes aldri til å bekrefte godkjenning.

## Før reell bruk

1. Skaff API-nøkkel via Vegvesenets egen innlogging.
2. Test kjent Tempo 100-godkjent O1 og O2. Sammenlign dagens vognkort/attest med API-kode.
3. Test ordinær henger og tidligere godkjent, utmeldt henger. Kontroller om ingen underkode eller INGENKODE faktisk leveres.
4. Test personlig kjennemerke og kontroller at riktig kjøretøy returneres.
5. Kontroller manglende EU-felt, avregistrering og oppdateringsforsinkelse etter endring.
6. Hvis underkoden ikke leveres: avklar med api-kjoretoy@vegvesen.no. Ikke erstatt den med heuristikk.

Tester i prosjektet er syntetiske og erstatter ikke disse reelle kontrollene. Ingen forespørsel til Vegvesenet er sendt med en API-nøkkel i utviklingen.

## Avgrensning

Appen avgjør hengerens registerstatus. Vurdering av faktisk kjøring krever trekkbil og forhold som ikke nødvendigvis kan hentes fra kjøretøyregisteret: dekkalder, montert utstyr, riktig bruk av stabilisering, last og attestens vilkår. Ingen generell «lov å kjøre 100»-status returneres.

Se kildehenvisningene i README for aktuelle API- og regelverkssider.
