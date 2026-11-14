import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Personvern'), backgroundColor: const Color(0xFFF3F6F3)),
    body: const SafeArea(
      child: SelectionArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Text(_privacyBody, style: TextStyle(height: 1.45, fontSize: 15)),
        ),
      ),
    ),
  );
}

const _privacyBody = '''
Sist oppdatert 23. oktober 2026

Behandlingsansvarlig er utgiveren av Tempo 100 i Google Play (pakke no.arildb.tempo100). Bruk e-postadressen i butikkoppføringen for spørsmål om personvern.

Hva appen gjør
Tempo 100 slår opp om en tilhenger har teknisk underkode TEMPO100 i Statens vegvesens registerdata. Resultatet er registerstatus for hengeren, ikke tillatelse til 100 km/t og ikke bevis for en trafikkovertredelse.

Opplysninger vi behandler
• Registreringsnummer du skriver inn eller som kameraet leser. Det sendes til vår server og ved ekte oppslag videre til Statens vegvesen. Registreringsnummer er en personopplysning.
• Kamerabilde brukes bare på telefonen til skiltlesing (Google ML Kit). Bildet lastes ikke opp og lagres ikke av oss.
• IP-adresse brukes kortvarig i minnet på serveren for å begrense antall oppslag. App-serveren logger ikke skiltnummer eller rådata. Vertsmiljøet kan ha egne tilgangslogger.
• Ingen brukerkonto, ingen database og ingen oppslagshistorikk.

Formål og grunnlag
Oppslaget skjer bare når du ber om det, for å levere tjenesten (GDPR art. 6 nr. 1 b). Kamera brukes bare hvis du velger skiltlesing. Annonser vises etter Googles samtykkeskjema (UMP); da er grunnlaget samtykke (art. 6 nr. 1 a) for den behandlingen Google beskriver.

Mottakere
• Statens vegvesen ved live-oppslag.
• Google AdMob og UMP for annonser og samtykke. Du kan åpne personvernvalg når appen viser den muligheten.
API-nøkkelen til Vegvesenet ligger bare på serveren.

Lagringstid
Vi lagrer ikke oppslag. Ratebegrensning i minnet forsvinner når serveren restarter eller tidsvinduet utløper.

Dine rettigheter
Du kan be om innsyn, retting, sletting, begrensning og klage til Datatilsynet. Fordi vi ikke lagrer historikk, har vi vanligvis ingen søk å vise etter at svaret er sendt. Du kan la være å bruke kamera og avinstallere appen.

Barn
Appen er laget for førere og eiere av tilhenger, ikke for barn.

Den samme teksten publiseres på serveren under /personvern. Bruk den adressen i Google Play.
''';
