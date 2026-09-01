import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/engagement.dart';
import '../data/weather_repository.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository();
});

final homeWeatherProvider = FutureProvider<WeatherSnapshot>((ref) {
  return ref.watch(weatherRepositoryProvider).fetchCurrent();
});
