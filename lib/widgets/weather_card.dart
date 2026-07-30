import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/weather_service.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData? weather;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;

  const WeatherCard({
    super.key,
    this.weather,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hasCachedData = weather != null && weather!.isValid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wb_sunny_rounded, size: 18, color: AppTheme.info),
              ),
              const SizedBox(width: 10),
              Text('Cuaca', style: Theme.of(context).textTheme.titleMedium),
              if (!hasCachedData && !isLoading)
                Text(' (offline)', style: TextStyle(fontSize: 10, color: AppTheme.textHint.withOpacity(0.5))),
              const Spacer(),
              if (onRefresh != null)
                GestureDetector(
                  onTap: onRefresh,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Content — show cached data first, then overlay error as banner
          if (isLoading && !hasCachedData)
            _buildLoading()
          else if (!hasCachedData)
            _buildEmpty()
          else ...[
            _buildWeatherContent(context),

            // If there's an error but we have cached data, show a small banner
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 14, color: AppTheme.warning),
                    const SizedBox(width: 6),
                    Text(
                      'Data dari cache terakhir',
                      style: const TextStyle(fontSize: 10, color: AppTheme.warning, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(height: 8),
            Text('Memuat cuaca...', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 20, color: AppTheme.textHint.withOpacity(0.6)),
            const SizedBox(width: 8),
            const Text('Cuaca tidak tersedia', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent(BuildContext context) {
    final w = weather!;
    final iconData = _iconFor(w.icon);
    final iconColor = w.iconColor;

    return Row(
      children: [
        // Weather icon + description
        Column(
          children: [
            Icon(iconData, size: 40, color: iconColor),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                w.description,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),

        // Temperature details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                w.location,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.thermostat_rounded, size: 14, color: AppTheme.warning),
                  const SizedBox(width: 4),
                  Text(
                    '${w.tempCelsius.toStringAsFixed(1)}°C',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Terasa ${w.feelsLikeCelsius.toStringAsFixed(1)}°C',
                style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
              ),
            ],
          ),
        ),

        // Humidity & Wind
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _miniStat(Icons.water_drop_rounded, '${w.humidity}%', AppTheme.info),
            const SizedBox(height: 8),
            _miniStat(Icons.air_rounded, '${w.windKph.toStringAsFixed(0)} km/j', AppTheme.textSecondary),
          ],
        ),
      ],
    );
  }

  /// Map a [WeatherIcon] enum to the corresponding Material [IconData].
  IconData _iconFor(WeatherIcon icon) {
    switch (icon) {
      case WeatherIcon.sunny:
        return Icons.wb_sunny_rounded;
      case WeatherIcon.partlyCloudy:
        return Icons.wb_cloudy_rounded;
      case WeatherIcon.cloudy:
        return Icons.cloud_rounded;
      case WeatherIcon.fogMist:
        return Icons.foggy;
      case WeatherIcon.drizzle:
        return Icons.grain_rounded;
      case WeatherIcon.snowShowers:
      case WeatherIcon.snow:
        return Icons.ac_unit_rounded;
      case WeatherIcon.rain:
        return Icons.water_drop_rounded;
      case WeatherIcon.thunderstorm:
        return Icons.thunderstorm_rounded;
    }
  }

  Widget _miniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
