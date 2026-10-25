import 'package:flutter/material.dart';

import 'app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr(context, 'Personvernerklæring'))),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(tr(context, 'Personvernerklæring for Tempo 100 - Tilhengersjekk'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(tr(context, 'Sist oppdatert: 25. oktober 2026')),
        SizedBox(height: 18),
        _PolicySection('Hvem er ansvarlig?',
            'Denne erklæringen gjelder Tempo 100 - Tilhengersjekk for Android og iOS. Utvikleren som er oppført under appens utviklerinformasjon i Google Play, er ansvarlig for behandlingen. Spørsmål, innsyns- og sletteforespørsler kan sendes til e-postadressen under «Kontakt utvikler» i Google Play-oppføringen.'),
        _PolicySection('Registreringsnummer',
            'Nummeret du skriver inn eller leser med kamera, sendes til appens server for oppslag. Registreringsnummer regnes som en personopplysning. I live-modus videresender serveren nummeret til Statens vegvesens API, som returnerer tekniske kjøretøyopplysninger uten navn eller kontaktopplysninger om eieren. Nummeret sendes ikke til Googles annonse-SDK.'),
        _PolicySection('Kamera',
            'Kamerarammer behandles på enheten med tekstgjenkjenning for å lese registreringsnummer. Appen tar ikke opp video, og bilder eller kamerarammer lastes ikke opp eller lagres av appen. Du kan også skrive nummeret manuelt.'),
        _PolicySection('Talegjenkjenning',
            'Du kan bruke mikrofonknappen til å si «Tempo 100» etterfulgt av registreringsnummeret. Talegjenkjenning starter bare etter bekreftelse og et trykk på mikrofonknappen. Den stopper når appen går i bakgrunnen. Lyd kan behandles av talegjenkjenningstjenesten på enheten, men appen lagrer ikke lydopptak eller transkripsjoner. Det gjenkjente registreringsnummeret fylles inn i skjemaet og sendes til appserveren når oppslaget utføres. Du kan alltid skrive nummeret manuelt.'),
        _PolicySection('Annonser og Google',
            'Appen bruker Google Mobile Ads SDK til bannerannonser og Googles UMP til samtykkevalg der dette kreves. Annonser forespørres bare når SDK-et oppgir at det er tillatt. Google Mobile Ads SDK kan samle inn og dele IP-adresse (som kan brukes til å anslå omtrentlig plassering), annonse- eller enhetsidentifikatorer, app- og annonseinteraksjoner samt diagnostikk- og ytelsesopplysninger for annonselevering, måling, diagnostikk og beskyttelse mot svindel. Hvilke annonser og behandlinger som brukes, avhenger blant annet av personvernvalgene dine og Googles innstillinger.'),
        _PolicySection('Andre mottakere',
            'Statens vegvesen mottar registreringsnummeret ved et reelt oppslag. Driftsleverandøren som drifter appserveren, kan behandle IP-adresse og tekniske forespørselsdata i drifts- og sikkerhetslogger etter sine egne vilkår og lagringstider. Utvikleren selger ikke registreringsnumre eller oppslagshistorikk.'),
        _PolicySection('Lagring og sikkerhet',
            'Utvikleren lagrer ikke registreringsnumre, kjøretøyresultater eller oppslagshistorikk i en database. Serveren bruker tilkoblingens IP-adresse midlertidig for å håndheve en grense mot for mange oppslag; denne oppføringen fjernes etter omtrent ett minutt. Dagstelleren for live-oppslag inneholder ikke IP-adresser eller registreringsnumre og nullstilles daglig eller når serverprosessen starter på nytt. Releaseversjoner krever HTTPS, og API-nøkkelen til Statens vegvesen ligger på serveren, ikke i appen.'),
        _PolicySection('Valg og rettigheter',
            'Du bestemmer selv om du vil gjøre et oppslag eller bruke kameraet. Du kan skrive nummeret manuelt. Du kan endre annonsesamtykke i «Personvernvalg» i appen når valget er tilgjengelig. For spørsmål eller forespørsler om innsyn, retting eller sletting, kontakt utvikleren via e-postadressen i Google Play-oppføringen. Siden utvikleren ikke lagrer oppslagshistorikk, finnes det normalt ingen oppslagslogg hos utvikleren å hente ut eller slette.'),
        _PolicySection('Barn og endringer',
            'Appen er ikke laget spesielt for barn. Personvernerklæringen kan bli oppdatert hvis appens funksjoner eller databehandling endres. Den nyeste versjonen står på personvernsiden for appen.'),
      ],
    ),
  );
}

class _PolicySection extends StatelessWidget {
  const _PolicySection(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(context, title), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(tr(context, body)),
      ],
    ),
  );
}
