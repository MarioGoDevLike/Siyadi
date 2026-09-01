import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../data/models/engagement.dart';

/// OpenWeather current conditions. Pass key via --dart-define=OPENWEATHER_API_KEY=...
class WeatherRepository {
  WeatherRepository({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ??
            const String.fromEnvironment(
              'OPENWEATHER_API_KEY',
              defaultValue: '',
            );

  final http.Client _client;
  final String _apiKey;

  /// Beirut default for Lebanon launch.
  static const defaultLat = 33.8938;
  static const defaultLon = 35.5018;

  Future<WeatherSnapshot> fetchCurrent({
    double lat = defaultLat,
    double lon = defaultLon,
    String placeName = 'Beirut',
  }) async {
    if (_apiKey.isEmpty) {
      return const WeatherSnapshot(
        tempC: 24,
        feelsLikeC: 24,
        windSpeedMs: 3.5,
        windDirectionDeg: 225,
        description: 'clear sky (demo)',
        humidity: 55,
        placeName: 'Beirut',
        isFallback: true,
      );
    }

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'lat': '$lat',
      'lon': '$lon',
      'appid': _apiKey,
      'units': 'metric',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw WeatherException('Weather unavailable (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final weather = (json['weather'] as List<dynamic>? ?? const []).isNotEmpty
        ? json['weather'][0] as Map<String, dynamic>
        : <String, dynamic>{};
    final name = json['name'] as String? ?? placeName;

    return WeatherSnapshot(
      tempC: (main['temp'] as num?)?.toDouble() ?? 0,
      feelsLikeC: (main['feels_like'] as num?)?.toDouble() ?? 0,
      windSpeedMs: (wind['speed'] as num?)?.toDouble() ?? 0,
      windDirectionDeg: (wind['deg'] as num?)?.toInt() ?? 0,
      description: weather['description'] as String? ?? 'n/a',
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      placeName: name,
    );
  }
}

class WeatherException implements Exception {
  WeatherException(this.message);
  final String message;

  @override
  String toString() => message;
}
