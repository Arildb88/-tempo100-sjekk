# Tempo 100 for iOS og Android

Flutter-klient for den eksisterende Node-serveren i repoets rot. Vegvesenets API-nøkkel skal bare ligge på serveren. Appen gjør oppslag med `POST /api/lookup`, leser skilt lokalt med kamera/ML Kit og viser et AdMob-banner på hovedsiden etter samtykkekontroll.

## Oppsett på PC-en din

Bruk Flutter 3.47 eller nyere. I PowerShell fra `mobile`:

```powershell
flutter create --platforms=android,ios --org no.arildb --project-name tempo100 .
dart tool/setup_platforms.dart
flutter pub get
flutter analyze
flutter test
```

Dette lager de vanlige Android- og iOS-filene og setter inn appnavn, kameratillatelse og de to AdMob-app-ID-ene fra skjermbildene. `setup_platforms.dart` kan kjøres igjen etter regenerering. Hvis Flutter bare genererer Android-filer på PC-en din, lager du også iOS-plattformen senere på Mac og kjører oppsettet på nytt. Flutter og Dart var ikke installert i arbeidsmiljøet som laget kildekoden, så native bygg og test må utføres i CI eller på en maskin med Flutter. iOS-bygg krever macOS/Xcode.

Start serveren i repoets rot med `.env` for demomodus eller live-modus. For Android-emulatoren brukes `http://10.0.2.2:3000` automatisk i debug. På en fysisk telefon må serveren være tilgjengelig på nettverket eller over HTTPS. For eksempel:

```powershell
flutter run --dart-define=API_BASE_URL=https://DIN-SERVER.NO
```

For lokal test mot en PC på samme nett, sett `HOST=0.0.0.0` på serveren og bruk `http://PC-ENS-IP:3000` som `API_BASE_URL`. I debug-APK-en fra GitHub Actions kan du også åpne **Testserver (debug)** og skrive denne adressen i appen. Telefon og PC må være på samme nett, og brannmuren må slippe gjennom port 3000. Android tillater lokal HTTP bare i debug-konfigurasjonen. En iPhone bør testes mot HTTPS. En release-bygging avviser HTTP og trenger en reell HTTPS-server. Testsiden som tidligere ble publisert er en separat demo og fungerer ikke som live API-server for denne appen.

Under **Actions → Flutter mobile** i GitHub kan du laste ned `tempo100-android-debug` fra en vellykket kjøring og pakke ut APK-en. Dette er en debug-signert testversjon for direkte installasjon; den er ikke en Play Store-pakke.

## Annonser

Android-app-ID og iOS-app-ID ligger i de genererte native-filene etter oppsett. Banner-ID-ene fra AdMob ligger i `lib/ad_banner.dart`. Debug bruker **Googles testannonseenheter**; release bruker dine egne banner-ID-er. Appen ber om oppdatert samtykkestatus ved start, viser eventuelt Googles UMP-skjema og laster bare annonse hvis `canRequestAds()` er sant. Opprett og publiser riktig melding i AdMob «Personvern og meldinger» før ekte annonser og offentlig utgivelse. Test personvernvalg på begge plattformer. Annonsen vises ikke over kamerabildet.

## Før utgivelse

- Bekreft et kjent Tempo 100-godkjent og et ikke godkjent registreringsnummer mot dokumentasjon fra Statens vegvesen.
- Test kamera og automatisk avlesning på en fysisk Android og iPhone; OCR kan lese feil. Resultatkortet viser alltid nummeret som ble slått opp.
- Sett opp HTTPS-hosting av Node-serveren med API-nøkkelen som serverhemmelighet, personvernerklæring og riktig behandling av logger og oppslagsdata.
- Kontroller annonse/samtykke, butikkopplysninger og app-ikon før publisering. En lokal Flutter-kildekode er ikke en godkjent App Store- eller Play Store-utgivelse.

Teknisk dokumentasjon: [Flutter AdMob](https://developers.google.com/admob/flutter/quick-start), [UMP](https://developers.google.com/admob/flutter/privacy), [ML Kit kameraformat](https://github.com/flutter-ml/google_ml_kit_flutter/tree/develop/packages/google_mlkit_commons).
