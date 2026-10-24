import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// App IDs are configured natively; these are banner ad unit IDs.
const _androidBanner = 'ca-app-pub-5656443533422331/2423334922';
const _iosBanner = 'ca-app-pub-5656443533422331/4986842520';
const _androidTest = 'ca-app-pub-3940256099942544/9214589741';
const _iosTest = 'ca-app-pub-3940256099942544/2435281174';

class ConsentBanner extends StatefulWidget {
  const ConsentBanner({super.key});
  @override
  State<ConsentBanner> createState() => _ConsentBannerState();
}

class _ConsentBannerState extends State<ConsentBanner> {
  BannerAd? _ad;
  bool _showPrivacyOptions = false;
  bool _requested = false;
  bool _loadingAds = false;

  @override
  void initState() {
    super.initState();
    _requestConsent();
  }

  void _requestConsent() {
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        final required = await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() == PrivacyOptionsRequirementStatus.required;
        if (mounted) setState(() => _showPrivacyOptions = required);
        ConsentForm.loadAndShowConsentFormIfRequired((_) => _loadIfAllowed());
        _loadIfAllowed(); // Previous session's consent may already allow ads.
      },
      (_) => _loadIfAllowed(),
    );
  }

  Future<void> _loadIfAllowed() async {
    if (!mounted || _requested || _loadingAds) return;
    _loadingAds = true; // Both consent callbacks can complete before either await returns.
    try {
      if (!await ConsentInformation.instance.canRequestAds() || !mounted) return;
      _requested = true;
      await MobileAds.instance.initialize();
      if (!mounted) return;
      // A compact 320×50 banner stays clear of the lookup and camera controls.
      const size = AdSize.banner;
      final id = Platform.isAndroid
          ? (kReleaseMode ? _androidBanner : _androidTest)
          : (kReleaseMode ? _iosBanner : _iosTest);
      final ad = BannerAd(
        adUnitId: id,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) { ad.dispose(); return; }
            setState(() => _ad = ad as BannerAd);
          },
          onAdFailedToLoad: (ad, _) => ad.dispose(),
        ),
      );
      await ad.load();
    } catch (_) {
      _requested = false;
    } finally {
      _loadingAds = false;
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_ad != null) ...[
        Padding(padding: const EdgeInsets.only(top: 4), child: Text(tr(context, 'Annonse'), style: const TextStyle(fontSize: 11))),
        SizedBox(width: _ad!.size.width.toDouble(), height: _ad!.size.height.toDouble(), child: AdWidget(ad: _ad!)),
      ],
      if (_showPrivacyOptions)
        TextButton(
          onPressed: () => ConsentForm.showPrivacyOptionsForm((_) {}),
          child: Text(tr(context, 'Personvernvalg')),
        ),
    ],
  );
}
