// Run after `flutter create --platforms=android,ios --org no.tempo100 --project-name app .`.
import 'dart:io';

void update(String path, String Function(String) transform) {
  final file = File(path);
  if (!file.existsSync()) throw StateError('Mangler $path. Kjør flutter create først.');
  final current = file.readAsStringSync();
  final next = transform(current);
  if (next == current) return;
  file.writeAsStringSync(next);
}

void main() {
  update('android/app/src/main/AndroidManifest.xml', (xml) {
    if (!xml.contains('android.permission.CAMERA')) {
      xml = xml.replaceFirst('<application',
          '<uses-permission android:name="android.permission.CAMERA"/>\n    <uses-permission android:name="android.permission.INTERNET"/>\n    <application');
    }
    xml = xml.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="Tempo 100 - Tilhengersjekk"');
    if (!xml.contains('com.google.android.gms.ads.APPLICATION_ID')) {
      xml = xml.replaceFirst('<activity',
          '<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-5656443533422331~3206856994"/>\n        <activity');
    }
    return xml;
  });
  update('android/app/src/debug/AndroidManifest.xml', (xml) {
    if (!xml.contains('usesCleartextTraffic')) {
      xml = xml.replaceFirst('</manifest>',
          '    <application android:usesCleartextTraffic="true"/>\n</manifest>');
    }
    return xml;
  });
  if (Directory('ios').existsSync()) {
  update('ios/Runner/Info.plist', (xml) {
    xml = xml.replaceFirst(RegExp(r'(<key>CFBundleDisplayName</key>\\s*<string>)[^<]*(</string>)'), r'\$1Tempo 100 - Tilhengersjekk\$2');
    if (!xml.contains('NSCameraUsageDescription')) {
      xml = xml.replaceFirst('</dict>\n</plist>',
          '  <key>NSCameraUsageDescription</key>\n'
          '  <string>Tempo 100 bruker kameraet til å lese tilhengerens registreringsnummer. Bilder lagres ikke.</string>\n'
          '  <key>GADApplicationIdentifier</key>\n'
          '  <string>ca-app-pub-5656443533422331~6654138256</string>\n'
          '</dict>\n</plist>');
    }
    return xml;
  });
  update('ios/Podfile', (podfile) {
    if (RegExp(r'^\s*#?\s*platform :ios,', multiLine: true).hasMatch(podfile)) {
      return podfile.replaceFirst(RegExp(r'^\s*#?\s*platform :ios,.*$', multiLine: true), "platform :ios, '15.5'");
    }
    return "platform :ios, '15.5'\n$podfile";
  });
  update('ios/Runner.xcodeproj/project.pbxproj', (project) =>
      project.replaceAll(RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;'), 'IPHONEOS_DEPLOYMENT_TARGET = 15.5;'));
  }
  final sampleTest = File('test/widget_test.dart');
  if (sampleTest.existsSync() &&
      sampleTest.readAsStringSync().contains('Counter increments smoke test')) {
    sampleTest.deleteSync(); // Flutter's counter example does not match this app.
  }
  stdout.writeln('Android- og iOS-oppsettet for Tempo 100 er klart.');
}
