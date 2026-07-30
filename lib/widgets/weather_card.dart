import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/weather_service.dart';

class WeatherCard extends StatefulWidget {
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
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _spinController;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _contentFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
    ));

    // Start spin if already loading on first build
    if (widget.isLoading) _spinController.repeat();
  }

  @override
  void didUpdateWidget(WeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger entry animation when weather data arrives
    if (oldWidget.weather == null &&
        widget.weather != null &&
        widget.weather!.isValid) {
      _entryController.forward(from: 0);
    }

    // Manage spin animation based on loading state
    if (widget.isLoading) {
      _spinController.repeat();
    } else {
      _spinController.reset();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasCachedData =
        widget.weather != null && widget.weather!.isValid;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            _buildHeader(theme, cs, hasCachedData),
            const SizedBox(height: 14),

            // ── Content ──
            _buildContent(theme, cs, hasCachedData),
          ],
        ),
      ),
    );
  }

  // ── Header Row ──
  Widget _buildHeader(ThemeData theme, ColorScheme cs, bool hasCachedData) {
    return Row(
      children: [
        _weatherIconContainer(cs),
        const SizedBox(width: 10),
        Text('Cuaca', style: theme.textTheme.titleMedium),
        if (!hasCachedData && !widget.isLoading)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              '(offline)',
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        const Spacer(),
        if (widget.onRefresh != null) _buildRefreshButton(cs),
      ],
    );
  }

  // ── Weather Icon Container with Gradient ──
  Widget _weatherIconContainer(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: _weatherGradient(cs),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.wb_sunny_rounded,
        size: 18,
        color: cs.surface,
      ),
    );
  }

  LinearGradient _weatherGradient(ColorScheme cs) {
    if (!widget.isLoading &&
        widget.weather != null &&
        widget.weather!.isValid) {
      final icon = widget.weather!.icon;
      switch (icon) {
        case WeatherIcon.sunny:
          return const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case WeatherIcon.partlyCloudy:
          return const LinearGradient(
            colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case WeatherIcon.cloudy:
          return const LinearGradient(
            colors: [Color(0xFF64748B), Color(0xFF475569)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case WeatherIcon.fogMist:
          return const LinearGradient(
            colors: [Color(0xFF94A3B8), Color(0xFFCBD5E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case WeatherIcon.drizzle:
        case WeatherIcon.rain:
          return const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case WeatherIcon.snowShowers:
        case WeatherIcon.snow:
          return const LinearGradient(
            colors: [Color(0xFF93C5FD), Color(0xFFE2E8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case WeatherIcon.thunderstorm:
          return const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
      }
    }

    // Default / loading gradient
    return LinearGradient(
      colors: [
        cs.primary.withValues(alpha: 0.6),
        cs.primary.withValues(alpha: 0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ── Refresh Button (Continuous Spin) ──
  Widget _buildRefreshButton(ColorScheme cs) {
    return GestureDetector(
      onTap: widget.onRefresh,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedBuilder(
          animation: _spinController,
          builder: (context, child) {
            return Transform.rotate(
              angle: widget.isLoading
                  ? _spinController.value * 2 * math.pi
                  : 0,
              child: Icon(
                Icons.refresh_rounded,
                size: 16,
                color: cs.primary,
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Content Router ──
  Widget _buildContent(ThemeData theme, ColorScheme cs, bool hasCachedData) {
    if (widget.isLoading && !hasCachedData) {
      return _buildAnimatedShimmer(cs);
    }

    if (!hasCachedData) {
      return _buildEmpty(cs);
    }

    return FadeTransition(
      opacity: _contentFade,
      child: SlideTransition(
        position: _contentSlide,
        child: Column(
          children: [
            _buildWeatherContent(theme, cs),
            if (widget.errorMessage != null)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildCacheBanner(cs),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Animated Shimmer Loading ──
  Widget _buildAnimatedShimmer(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _WeatherShimmer(colorScheme: cs),
    );
  }

  // ── Empty State ──
  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 20,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              'Cuaca tidak tersedia',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cache Banner ──
  Widget _buildCacheBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 14, color: cs.tertiary),
          const SizedBox(width: 6),
          Text(
            'Data dari cache terakhir',
            style: TextStyle(
              fontSize: 10,
              color: cs.tertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Weather Content ──
  Widget _buildWeatherContent(ThemeData theme, ColorScheme cs) {
    final w = widget.weather!;
    final iconData = _iconFor(w.icon);
    final iconColor = w.iconColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weather icon + description
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(iconData, size: 36, color: iconColor),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 80,
              child: Text(
                w.description,
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(width: 18),

        // Temperature & details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 12, color: cs.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      w.location,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Temperature
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.thermostat_rounded,
                      size: 16, color: const Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(
                    '${w.tempCelsius.toStringAsFixed(1)}°',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      'C',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Terasa ${w.feelsLikeCelsius.toStringAsFixed(1)}°',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Humidity & Wind
              Row(
                children: [
                  _miniStat(
                    Icons.water_drop_rounded,
                    '${w.humidity}%',
                    AppTheme.info,
                  ),
                  const SizedBox(width: 20),
                  _miniStat(
                    Icons.air_rounded,
                    '${w.windKph.toStringAsFixed(0)} km/j',
                    cs.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ──

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
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// Shimmer skeleton widget — dark-mode aware
// ════════════════════════════════════════════════════

class _WeatherShimmer extends StatefulWidget {
  final ColorScheme colorScheme;

  const _WeatherShimmer({required this.colorScheme});

  @override
  State<_WeatherShimmer> createState() => _WeatherShimmerState();
}

class _WeatherShimmerState extends State<_WeatherShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    // Use surfaceContainerHighest which is a muted grey in both modes.
    // Fall back to surfaceContainerLow if containerHighest isn't available.
    final skeletonColor = cs.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        final progress = _shimmerAnim.value;
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              skeletonColor.withValues(alpha: 0.3),
              skeletonColor.withValues(alpha: 0.7),
              skeletonColor.withValues(alpha: 0.3),
            ],
            stops: [progress - 0.3, progress, progress + 0.3],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: child,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon skeleton
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location bar
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // Temperature bar
                Container(
                  width: 100,
                  height: 28,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                // Stats bar
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
