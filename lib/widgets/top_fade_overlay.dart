import 'package:flutter/material.dart';

/// Fade lembut di tepi atas layar saat konten di-scroll.
///
/// Overlay gradasi (warna latar -> transparan) muncul di tepi paling atas
/// layar setelah header selesai scroll menghilang ([fadeInAfter]), sehingga
/// konten yang lewat di tepi atas layar memudar alih-alih terpotong kaku.
/// Overlay tidak menghalangi sentuhan (IgnorePointer) dan hanya me-rebuild
/// lapisan kecilnya sendiri (ValueNotifier), bukan seluruh layar.
class TopFadeOverlay extends StatefulWidget {
  /// Scrollable yang dibungkus.
  final Widget child;

  /// Offset scroll (px) setelah fade mulai muncul — isi dengan tinggi header
  /// yang ikut hilang saat scroll (expandedHeight), agar fade tidak menutupi
  /// header yang masih terlihat.
  final double fadeInAfter;

  const TopFadeOverlay({super.key, required this.child, this.fadeInAfter = 0});

  @override
  State<TopFadeOverlay> createState() => _TopFadeOverlayState();
}

class _TopFadeOverlayState extends State<TopFadeOverlay> {
  /// Tinggi area gradasi di tepi atas layar.
  static const double _fadeHeight = 72;

  /// Jarak scroll (px) untuk transisi opacity 0 -> 1 setelah [fadeInAfter].
  static const double _fadeInRange = 60;

  final ValueNotifier<double> _pixels = ValueNotifier(0);

  @override
  void dispose() {
    _pixels.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    _pixels.value = n.metrics.pixels;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _fadeHeight,
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: _pixels,
                builder: (context, pixels, _) {
                  final t = ((pixels - widget.fadeInAfter) / _fadeInRange)
                      .clamp(0.0, 1.0);
                  return Opacity(
                    opacity: t,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [bg, bg.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
