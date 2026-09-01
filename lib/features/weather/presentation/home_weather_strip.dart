import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/engagement.dart';
import '../application/weather_providers.dart';

class HomeWeatherStrip extends ConsumerWidget {
  const HomeWeatherStrip({super.key});

  void _showDetail(BuildContext context, WeatherSnapshot w) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                w.placeName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('${w.tempC.round()}°C · feels like ${w.feelsLikeC.round()}°C'),
              Text(
                '${w.description} · humidity ${w.humidity}%',
              ),
              Text(
                'Wind ${w.windSpeedMs.toStringAsFixed(1)} m/s from ${w.windDirectionLabel} (${w.windDirectionDeg}°)',
              ),
              if (w.isFallback) ...[
                const SizedBox(height: 12),
                Text(
                  'Demo weather — pass --dart-define=OPENWEATHER_API_KEY=... for live data.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.clay,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(homeWeatherProvider);

    return weather.when(
      loading: () => _box(
        context,
        label: 'Weather & wind',
        detail: 'Loading conditions…',
        onTap: null,
      ),
      error: (_, __) => _box(
        context,
        label: 'Weather & wind',
        detail: 'Unavailable right now',
        onTap: () => ref.invalidate(homeWeatherProvider),
      ),
      data: (w) => _box(
        context,
        label: '${w.placeName} weather',
        detail: w.compactLine,
        onTap: () => _showDetail(context, w),
      ),
    );
  }

  Widget _box(
    BuildContext context, {
    required String label,
    required String detail,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.snow.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.mistDeep.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.canopy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.air_rounded,
                  color: AppColors.canopySoft,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.clay,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.clay),
            ],
          ),
        ),
      ),
    );
  }
}
