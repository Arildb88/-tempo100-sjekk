import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'app_localizations.dart';
import 'plate_input.dart';
import 'ad_banner.dart';
import 'lookup_api.dart';
import 'plate_scanner.dart';
import 'privacy_policy.dart';

void main() => runApp(const Tempo100App());

class Tempo100App extends StatefulWidget {
  const Tempo100App({super.key});

  @override
  State<Tempo100App> createState() => _Tempo100AppState();
}

class _Tempo100AppState extends State<Tempo100App> {
  String _language = 'no';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  void initState() {
    super.initState();
    _restoreLanguage();
  }

  Future<void> _restoreLanguage() async {
    try {
      final saved = await _preferences.getString('tempo100.language');
      if (mounted && (saved == 'no' || saved == 'en')) {
        setState(() => _language = saved!);
      }
    } catch (_) {
      // Keep the default language if preferences are unavailable.
    }
  }

  Future<void> _setLanguage(String language) async {
    if (language != 'no' && language != 'en') return;
    setState(() => _language = language);
    await _preferences.setString('tempo100.language', language);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Tempo 100',
    locale: Locale(_language),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('no'), Locale('en')],
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF123B37)), scaffoldBackgroundColor: const Color(0xFFF3F6F3)),
    home: HomePage(language: _language, onLanguageChanged: _setLanguage),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.language, required this.onLanguageChanged});

  final String language;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LookupApi _api = LookupApi();
  final _plate = TextEditingController();
  final _server = TextEditingController();
  String? _mode;
  String? _error;
  LookupResult? _result;
  bool _loading = false;
  bool _speechReady = false;
  bool _listening = false;
  final SpeechToText _speech = SpeechToText();
  final SharedPreferencesAsync _voicePreferences = SharedPreferencesAsync();
  int _lookupVersion = 0;
  int _configVersion = 0;
  Timer? _autoLookupTimer;
  String? _autoLookupCandidate;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final version = ++_configVersion;
    try {
      final mode = await _api.mode();
      if (mounted && version == _configVersion) {
        setState(() { _mode = mode; _error = null; });
        _scheduleAutomaticLookup(_plate.text);
      }
    } catch (_) {
      if (mounted && version == _configVersion) setState(() => _error = 'Får ikke kontakt med serveren. Sjekk nettverket og prøv igjen.');
    }
  }

  Future<void> _lookup() async {
    if (_loading || _mode == null) return;
    final value = _plate.text.trim();
    if (value.isEmpty) return;
    final version = ++_lookupVersion;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final result = await _api.lookup(value);
      if (mounted && version == _lookupVersion) setState(() => _result = result);
    } catch (error) {
      if (mounted && version == _lookupVersion) setState(() => _error = error is LookupException ? error.message : 'Kunne ikke hente oppslaget. Prøv igjen.');
    } finally {
      if (mounted && version == _lookupVersion) setState(() => _loading = false);
    }
  }

  void _onPlateChanged(String value) {
    _autoLookupTimer?.cancel();
    _autoLookupCandidate = null;
    _lookupVersion++;
    if (_loading || _result != null || _error != null) {
      setState(() { _loading = false; _result = null; _error = null; });
    }
    _scheduleAutomaticLookup(value);
  }

  void _scheduleAutomaticLookup(String value) {
    _autoLookupTimer?.cancel();
    final plate = normalizeTypedPlate(value);
    if (_mode == null || !isCompleteTypedPlate(plate) || _autoLookupCandidate == plate) return;
    _autoLookupTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted || _mode == null || normalizeTypedPlate(_plate.text) != plate || _autoLookupCandidate == plate) return;
      _autoLookupCandidate = plate;
      FocusScope.of(context).unfocus();
      _lookup();
    });
  }

  void _submitPlate() {
    _autoLookupTimer?.cancel();
    final plate = normalizeTypedPlate(_plate.text);
    FocusScope.of(context).unfocus();
    if (!isCompleteTypedPlate(plate) || _mode == null) return;
    _autoLookupCandidate = plate;
    _lookup();
  }

  Future<void> _startVoiceInput() async {
    final alreadyAccepted = await _voicePreferences.getBool('tempo100.voiceNoticeAccepted') ?? false;
    if (!mounted) return;
    if (!alreadyAccepted) {
      final continueVoice = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(tr(dialogContext, 'Talegjenkjenning')),
          content: Text(tr(dialogContext, 'Lyd brukes bare mens du sier registreringsnummeret. Telefonens talegjenkjenning kan behandle lyd via en ekstern tjeneste. Tempo 100 lagrer ikke lydopptak. Fortsett?')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(tr(dialogContext, 'Avbryt')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(tr(dialogContext, 'Fortsett')),
            ),
          ],
        ),
      );
      if (!mounted || continueVoice != true) return;
      await _voicePreferences.setBool('tempo100.voiceNoticeAccepted', true);
      if (!mounted) return;
    }
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _listening = false);
      }
      return;
    }
    try {
      if (!_speechReady) {
        _speechReady = await _speech.initialize(
          onStatus: (status) {
            if ((status == 'done' || status == 'notListening') && mounted) {
              setState(() => _listening = false);
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() => _listening = false);
            }
          },
        );
      }
      if (!_speechReady) {
        setState(() => _error = 'Mikrofon eller talegjenkjenning er ikke tilgjengelig.');
        return;
      }
      setState(() { _error = null; _listening = true; });
      await _speech.listen(
        onResult: (result) {
          if (!mounted || !result.finalResult) {
            return;
          }
          final plate = normalizeSpokenPlate(result.recognizedWords);
          if (!isValidSpokenPlate(plate)) {
            setState(() {
              _listening = false;
              _error = 'Kunne ikke tolke skiltet. Prøv å si bokstavene og tallene tydelig, eller skriv det inn.';
            });
            return;
          }
          _plate.value = TextEditingValue(text: plate, selection: TextSelection.collapsed(offset: plate.length));
          setState(() => _listening = false);
          _lookup();
        },
        listenOptions: SpeechListenOptions(
          localeId: widget.language == 'en' ? 'en-US' : 'nb-NO',
          listenFor: const Duration(seconds: 8),
          pauseFor: const Duration(seconds: 2),
          partialResults: false,
        ),
      );
      if (mounted) {
        setState(() => _listening = _speech.isListening);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _listening = false;
          _error = 'Talegjenkjenning feilet. Prøv igjen eller skriv nummeret inn.';
        });
      }
    }
  }

  Future<void> _scan() async {
    final detected = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const PlateScanner()));
    if (!mounted || detected == null) return;
    _plate.text = detected;
    await _lookup();
  }

  void _setTestServer() {
    if (kReleaseMode) return;
    final address = _server.text.trim();
    try {
      final next = LookupApi(baseUrl: address.isEmpty ? null : address);
      if (next.base.host.isEmpty) throw const FormatException('Mangler servernavn.');
      _api.dispose();
      _api = next;
      _lookupVersion++;
      _configVersion++;
      _autoLookupTimer?.cancel();
      _autoLookupCandidate = null;
      setState(() { _mode = null; _result = null; _error = null; _loading = false; });
      _loadConfig();
    } catch (_) {
      setState(() => _error = 'Skriv en gyldig serveradresse, for eksempel http://192.168.1.10:3000.');
    }
  }

  @override
  void dispose() {
    _lookupVersion++;
    _configVersion++;
    _autoLookupTimer?.cancel();
    _plate.dispose();
    _server.dispose();
    _api.dispose();
    unawaited(_speech.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tempo 100'),
      backgroundColor: const Color(0xFFF3F6F3),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'no', label: Text('NO')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {widget.language},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => widget.onLanguageChanged(selection.first),
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(child: Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
        Text(tr(context, 'Er tilhengeren registrert som godkjent?'), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold, height: 1.2)),
        const SizedBox(height: 16),
        if (_mode != null) _Notice(tr(context, _mode == 'demo' ? 'DEMO · fiktive data' : 'Registeroppslag · Statens vegvesen'), _mode == 'demo' ? const Color(0xFFFFF2D6) : const Color(0xFFE3F5E8)),
        if (!kReleaseMode) ExpansionTile(title: Text(tr(context, 'Testserver (debug)')), children: [
          TextField(controller: _server, keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: tr(context, 'Serveradresse'), hintText: 'http://192.168.1.10:3000', border: const OutlineInputBorder()),
            onSubmitted: (_) => _setTestServer()),
          TextButton(onPressed: _setTestServer, child: Text(tr(context, 'Koble til server'))),
        ]),
        const SizedBox(height: 18),
        Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _plate, textCapitalization: TextCapitalization.characters, keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: tr(context, 'Hengerens registreringsnummer'), hintText: 'AB 1234', border: const OutlineInputBorder()),
            onChanged: _onPlateChanged,
            onSubmitted: (_) => _submitPlate()),
          const SizedBox(height: 12),
          FilledButton(onPressed: _loading || _mode == null ? null : _submitPlate, child: Text(tr(context, _loading ? 'Sjekker …' : 'Sjekk registreringsnummer'))),
          OutlinedButton.icon(onPressed: _mode == null ? null : _scan, icon: const Icon(Icons.camera_alt_outlined), label: Text(tr(context, 'Les skilt med kamera'))),
          OutlinedButton.icon(
            onPressed: _loading || _mode == null ? null : _startVoiceInput,
            icon: Icon(_listening ? Icons.mic : Icons.mic_none),
            label: Text(tr(context, _listening ? 'Lytter … si bokstaver og tall' : 'Si skiltet')),
          ),
          if (_mode == 'demo') ...[
            const SizedBox(height: 8),
            Text(tr(context, 'Fiktive eksempler:'), style: const TextStyle(fontSize: 12)),
            Wrap(spacing: 8, children: [
              for (final example in ['DEMO100', 'DEMO80', 'DEMOU', 'DEMOE'])
                ActionChip(label: Text(example), onPressed: () { _plate.text = example; _lookup(); }),
            ]),
          ],
        ]))),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _Notice(tr(context, _error!), const Color(0xFFFFE8E8)),
          if (_mode == null) TextButton(onPressed: _loadConfig, child: Text(tr(context, 'Prøv på nytt'))),
        ],
        if (_result != null) ...[const SizedBox(height: 16), _ResultCard(_result!)],
        const SizedBox(height: 24),
        Text(tr(context, 'Kontroller opplysninger og skilt. Resultatet gjelder hengerens registerstatus, ikke om den aktuelle kjøringen er lovlig. For passasjer eller når bilen står parkert.'), style: const TextStyle(fontSize: 12, color: Color(0xFF556B61))),
      ])),
      if (MediaQuery.viewInsetsOf(context).bottom == 0) ...[
        const ConsentBanner(),
        TextButton(
          onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage())),
          child: Text(tr(context, 'Personvern')),
        ),
      ],
    ])),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.all(12), child: Text(text),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(this.result);
  final LookupResult result;

  @override
  Widget build(BuildContext context) {
    final status = result.status;
    final color = switch (status) {
      'approved' => const Color(0xFF217A4B),
      'not_recorded' => const Color(0xFFAF3434),
      _ => const Color(0xFF9B7520),
    };
    final heading = switch (status) {
      'approved' => tr(context, 'Registrert som godkjent'),
      'not_recorded' => tr(context, 'Ingen registrert godkjenning'),
      'not_applicable' => tr(context, 'Utenfor ordningen'),
      _ => tr(context, 'Kan ikke bekreftes'),
    };
    final checkedAt = DateTime.tryParse(result.data['checkedAt'] as String? ?? '')?.toLocal();
    return Card(elevation: 0, color: Colors.white, clipBehavior: Clip.antiAlias,
      child: Container(decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: 5))),
        padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (result.mode == 'demo') Text(tr(context, 'DEMO · fiktive data').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(result.plate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(heading, style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(tr(context, result.tempo['explanation'] as String? ?? '')),
          for (final warning in result.blockers) ...[const SizedBox(height: 8), _Notice(tr(context, 'OBS: ') + tr(context, warning), const Color(0xFFFFF0D9))],
          const SizedBox(height: 8),
          ExpansionTile(title: Text(tr(context, 'Utvidet informasjon')), tilePadding: EdgeInsets.zero, childrenPadding: EdgeInsets.zero, children: [
            _info(context, 'Merke og modell', [result.vehicle['brand'], result.vehicle['model']].whereType<String>().join(' ')),
            _info(context, 'Kjøretøyklasse', result.vehicle['category']),
            _info(context, 'Tillatt totalvekt', result.vehicle['totalWeight'] == null ? null : '${result.vehicle['totalWeight']} kg'),
            _info(context, 'Registreringsstatus', result.vehicle['registration']),
            _info(context, 'EU-kontrollfrist', result.inspection['deadline']),
            _info(context, 'Hentet', checkedAt == null ? null : '${checkedAt.day}.${checkedAt.month}.${checkedAt.year} ${tr(context, 'kl.')} ${checkedAt.hour.toString().padLeft(2, '0')}:${checkedAt.minute.toString().padLeft(2, '0')}'),
            const SizedBox(height: 10),
            Text(tr(context, result.driving['explanation'] as String? ?? '')),
          ]),
        ])),
    );
  }

  Widget _info(BuildContext context, String label, Object? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(tr(context, label), style: const TextStyle(color: Color(0xFF5B7065)))),
      Expanded(child: Text(value?.toString().isNotEmpty == true ? tr(context, value.toString()) : tr(context, 'Ikke oppgitt'), textAlign: TextAlign.end)),
    ]),
  );
}
