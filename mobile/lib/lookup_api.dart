import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const _configuredBase = String.fromEnvironment('API_BASE_URL');

class LookupApi {
  LookupApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Uri get base {
    final input = _configuredBase.isNotEmpty
        ? _configuredBase
        : Platform.isAndroid
            ? 'http://10.0.2.2:3000'
            : 'http://127.0.0.1:3000';
    final uri = Uri.parse(input);
    if (!uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https') ||
        (kReleaseMode && uri.scheme != 'https')) {
      throw const FormatException('Appen trenger en HTTPS-adresse til serveren.');
    }
    return uri;
  }

  Future<String> mode() async {
    final response = await _client.get(base.resolve('/api/config'))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw const HttpException('Serveren svarer ikke.');
    return (jsonDecode(response.body) as Map<String, dynamic>)['mode'] as String;
  }

  Future<LookupResult> lookup(String plate) async {
    final response = await _client.post(base.resolve('/api/lookup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plate': plate})).timeout(const Duration(seconds: 16));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw LookupException(data['error'] as String? ?? 'Oppslaget feilet.');
    }
    return LookupResult(data);
  }

  void dispose() => _client.close();
}

class LookupException implements Exception {
  const LookupException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LookupResult {
  const LookupResult(this.data);
  final Map<String, dynamic> data;
  Map<String, dynamic> get tempo => data['tempo100'] as Map<String, dynamic>;
  Map<String, dynamic> get vehicle => data['vehicle'] as Map<String, dynamic>;
  Map<String, dynamic> get inspection => data['inspection'] as Map<String, dynamic>;
  Map<String, dynamic> get driving => data['driving'] as Map<String, dynamic>;
  String get plate => data['plate'] as String;
  String get mode => data['mode'] as String;
  String get status => tempo['status'] as String? ?? 'unknown';
  List<String> get blockers => (driving['blockers'] as List<dynamic>? ?? [])
      .whereType<String>().toList();
}
