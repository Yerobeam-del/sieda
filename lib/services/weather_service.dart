import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import '../database/local_database.dart';

/// Numeric weather icon codes used by [WeatherData.iconCode].
/// Mapping to Material Icons happens in the widget layer.
enum WeatherIcon {
  sunny(0),
  partlyCloudy(1),
  cloudy(2),
  fogMist(3),
  drizzle(4),
  snowShowers(5),
  snow(6),
  rain(7),
  thunderstorm(8);

  final int code;
  const WeatherIcon(this.code);

  static WeatherIcon fromWeatherCode(String weatherCode) {
    final code = int.tryParse(weatherCode) ?? 113;

    // Reference: https://www.npmjs.com/package/weather-codes
    // 113 = Sunny/Clear
    if (code == 113) {
      return WeatherIcon.sunny;
    }
    // 116 = Partly cloudy
    if (code == 116) {
      return WeatherIcon.partlyCloudy;
    }
    // 119, 122 = Cloudy, Overcast
    if (code == 119 || code == 122) {
      return WeatherIcon.cloudy;
    }
    // 143, 248, 260 = Fog, Mist, Freezing fog
    if (code == 143 || code == 248 || code == 260) {
      return WeatherIcon.fogMist;
    }
    // 176-284 = Light drizzle / patchy rain
    if (code >= 176 && code <= 284) {
      return WeatherIcon.drizzle;
    }
    // 227-338 = Snow (light, moderate, heavy, blizzard, patchy, etc.)
    if (code >= 227 && code <= 338) {
      return WeatherIcon.snow;
    }
    // 293-356 = Rain (light, moderate, heavy)
    if (code >= 293 && code <= 356) {
      return WeatherIcon.rain;
    }
    // 317-320, 350-371 = Heavy showers, sleet, hail
    if ((code >= 317 && code <= 320) ||
        (code >= 350 && code <= 371)) {
      return WeatherIcon.thunderstorm;
    }
    // 179, 182, 200, 362-395 = Snow showers, heavy snow, thunder + hail/snow, ice pellets
    if (code == 179 || code == 182 || code == 200 ||
        (code >= 362 && code <= 377)) {
      return WeatherIcon.snowShowers;
    }
    // 386-395 = Thunderstorm (heavy rain, hail)
    if (code >= 386 && code <= 395) {
      return WeatherIcon.thunderstorm;
    }

    return WeatherIcon.cloudy;
  }
}

/// Weather data model.
class WeatherData {
  final String location;
  final String condition;
  final String description;
  final double tempCelsius;
  final double feelsLikeCelsius;
  final int humidity;
  final double windKph;
  final String windDir;
  final WeatherIcon icon;
  final int cloudCover;
  final DateTime observationTime;

  WeatherData({
    required this.location,
    required this.condition,
    required this.description,
    required this.tempCelsius,
    required this.feelsLikeCelsius,
    required this.humidity,
    required this.windKph,
    required this.windDir,
    required this.icon,
    required this.cloudCover,
    required this.observationTime,
  });

  factory WeatherData.fromWttrJson(Map<String, dynamic> json) {
    try {
      final current = json['current_condition'] as List<dynamic>?;
      if (current == null || current.isEmpty) {
        return WeatherData.empty();
      }
      final c = current[0] as Map<String, dynamic>;

      // Try to get location name from nearest area
      String location = 'Daerah sekitar';
      final nearest = json['nearest_area'] as List<dynamic>?;
      if (nearest != null && nearest.isNotEmpty) {
        final area = nearest[0] as Map<String, dynamic>;
        final areaName = area['areaName'] as List<dynamic>?;
        if (areaName != null && areaName.isNotEmpty) {
          location = (areaName[0] as Map<String, dynamic>)['value'] as String? ?? location;
        }
      }

      final weatherDesc = c['weatherDesc'] as List<dynamic>?;
      final desc = (weatherDesc != null && weatherDesc.isNotEmpty)
          ? (weatherDesc[0] as Map<String, dynamic>)['value'] as String? ?? ''
          : '';

      final weatherCode = c['weatherCode'] as String? ?? '113';

      return WeatherData(
        location: location,
        condition: weatherCode,
        description: desc,
        tempCelsius: double.tryParse(c['temp_C'] as String? ?? '0') ?? 0,
        feelsLikeCelsius: double.tryParse(c['FeelsLikeC'] as String? ?? '0') ?? 0,
        humidity: int.tryParse(c['humidity'] as String? ?? '0') ?? 0,
        windKph: double.tryParse(c['windspeedKmph'] as String? ?? '0') ?? 0,
        windDir: c['winddir16Point'] as String? ?? '',
        icon: WeatherIcon.fromWeatherCode(weatherCode),
        cloudCover: int.tryParse(c['cloudcover'] as String? ?? '0') ?? 0,
        observationTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[Weather] Parse error: $e');
      return WeatherData.empty();
    }
  }

  factory WeatherData.empty() {
    return WeatherData(
      location: '',
      condition: '',
      description: 'Tidak tersedia',
      tempCelsius: 0,
      feelsLikeCelsius: 0,
      humidity: 0,
      windKph: 0,
      windDir: '',
      icon: WeatherIcon.cloudy,
      cloudCover: 0,
      observationTime: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'location': location,
        'condition': condition,
        'description': description,
        'temp_c': tempCelsius,
        'feels_like_c': feelsLikeCelsius,
        'humidity': humidity,
        'wind_kph': windKph,
        'wind_dir': windDir,
        'icon_code': condition,
        'cloud_cover': cloudCover,
        'observation_time': observationTime.toIso8601String(),
      };

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final weatherCode = json['icon_code'] as String? ?? '';
    return WeatherData(
      location: json['location'] as String? ?? '',
      condition: weatherCode,
      description: json['description'] as String? ?? 'Tidak tersedia',
      tempCelsius: (json['temp_c'] as num?)?.toDouble() ?? 0,
      feelsLikeCelsius: (json['feels_like_c'] as num?)?.toDouble() ?? 0,
      humidity: json['humidity'] as int? ?? 0,
      windKph: (json['wind_kph'] as num?)?.toDouble() ?? 0,
      windDir: json['wind_dir'] as String? ?? '',
      icon: WeatherIcon.fromWeatherCode(weatherCode),
      cloudCover: json['cloud_cover'] as int? ?? 0,
      observationTime: DateTime.tryParse(json['observation_time'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Get weather icon tint color based on weather condition.
  Color get iconColor {
    switch (icon) {
      case WeatherIcon.sunny:
        return const Color(0xFFF59E0B);
      case WeatherIcon.partlyCloudy:
        return const Color(0xFF94A3B8);
      case WeatherIcon.cloudy:
        return const Color(0xFF64748B);
      case WeatherIcon.fogMist:
        return const Color(0xFF94A3B8);
      case WeatherIcon.drizzle:
        return const Color(0xFF3B82F6);
      case WeatherIcon.snowShowers:
        return const Color(0xFF93C5FD);
      case WeatherIcon.snow:
        return const Color(0xFFE2E8F0);
      case WeatherIcon.rain:
        return const Color(0xFF3B82F6);
      case WeatherIcon.thunderstorm:
        return const Color(0xFF6366F1);
    }
  }

  /// True if weather data is from a real observation (not empty).
  bool get isValid => location.isNotEmpty;
}

/// Service to fetch weather data from wttr.in (free, no API key).
/// Caches results locally for offline use.
class WeatherService {
  final LocalDatabase _db = LocalDatabase();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://wttr.in',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'User-Agent': 'SIEDA-Mobile/1.0'},
  ));

  /// Fetch current weather for a location name (desa/kecamatan).
  /// Returns cached data on failure or if offline.
  Future<WeatherData> getWeather(String location) async {
    if (location.isEmpty) return WeatherData.empty();

    final locationKey = location.toLowerCase().replaceAll(' ', '-');

    try {
      final response = await _dio.get(
        '/$locationKey',
        queryParameters: {'format': 'j1', 'lang': 'id'},
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final weather = WeatherData.fromWttrJson(response.data as Map<String, dynamic>);

        if (weather.isValid) {
          // Cache for offline use
          await _db.cacheWeather(weather.toJson(), locationKey);
        }

        return weather;
      }
    } catch (e) {
      debugPrint('[Weather] Fetch error: $e');
    }

    // Try to load from cache
    final cached = await _db.getCachedWeather(locationKey);
    if (cached != null && cached['json_data'] != null) {
      try {
        final jsonData = jsonDecode(cached['json_data'] as String) as Map<String, dynamic>;
        return WeatherData.fromJson(jsonData);
      } catch (_) {}
    }

    return WeatherData.empty();
  }
}
