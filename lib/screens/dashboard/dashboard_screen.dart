import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/weather_service.dart';
import '../../services/location_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/error_display.dart';
import '../../widgets/charts/dashboard_charts.dart';
import '../../widgets/weather_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _weatherService = WeatherService();
  WeatherData? _weather;
  bool _weatherLoading = false;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
      _loadWeather();
    });
  }

  Future<void> _loadWeather() async {
    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });

    final user = context.read<AuthProvider>().user;
    final desa = user?.desaName ?? user?.kecamatanName ?? '';

    WeatherData? weather;
    final locationService = LocationService();
    final position = await locationService.getCurrentPosition();

    if (position != null) {
      weather = await _weatherService.getWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );
    }

    if ((weather == null || !weather.isValid) && desa.isNotEmpty) {
      weather = await _weatherService.getWeather(desa);
    }

    if (mounted) {
      setState(() {
        _weather = weather;
        _weatherLoading = false;
        if (weather == null || (!weather.isValid && weather.description == 'Tidak tersedia')) {
          _weatherError = 'Gagal memuat cuaca';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProv = context.watch<DashboardProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () => dashboardProv.loadDashboard(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header Premium ──
            SliverAppBar(
              expandedHeight: 200,
              pinned: false,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F766E),
                            const Color(0xFF0D9488),
                            const Color(0xFF14B8A6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                    // Decorative curves overlay
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -60,
                      left: -20,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 52, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Icon + greeting
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.dashboard_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dashboard SIEDA',
                                      style: theme.textTheme.displaySmall?.copyWith(
                                        color: Colors.white,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sistem Informasi e-Dasawisma',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Desa & Kecamatan info
                          _buildDesaInfo(context, cs),
                        ],
                      ),
                    ),
                    // Subtle bottom fade
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ──
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (dashboardProv.isLoading && dashboardProv.dashboard == null)
                    const SizedBox(height: 200, child: LoadingWidget(message: 'Memuat dashboard...'))
                  else if (dashboardProv.error != null && dashboardProv.dashboard == null)
                    ErrorDisplay(
                      error: dashboardProv.error,
                      onRetry: () => dashboardProv.loadDashboard(),
                    )
                  else if (dashboardProv.dashboard != null) ...[
                    _buildRingkasanSection(context, dashboardProv),
                    const SizedBox(height: 16),

                    _buildCatatanSection(context, dashboardProv),
                    const SizedBox(height: 16),

                    WeatherCard(
                      weather: _weather,
                      isLoading: _weatherLoading,
                      errorMessage: _weatherError,
                      onRefresh: _loadWeather,
                    ),
                    const SizedBox(height: 16),

                    _buildChartCard(
                      context,
                      'Perbandingan Gender',
                      Icons.pie_chart_rounded,
                      GenderPieChart(ringkasan: dashboardProv.dashboard!.ringkasan),
                    ),
                    const SizedBox(height: 16),

                    if (dashboardProv.dashboard!.perDusun.isNotEmpty)
                      _buildChartCard(
                        context,
                        'Jumlah KK per Dusun',
                        Icons.bar_chart_rounded,
                        Column(
                          children: [
                            const SizedBox(height: 8),
                            DusunBarChart(perDusun: dashboardProv.dashboard!.perDusun),
                          ],
                        ),
                      ),
                    if (dashboardProv.dashboard!.perDusun.isNotEmpty)
                      const SizedBox(height: 16),

                    _buildChartCard(
                      context,
                      'Perkembangan Data (Bulanan)',
                      Icons.show_chart_rounded,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 180,
                            child: MonthlyLineChart(
                              totalKeluarga: dashboardProv.dashboard!.ringkasan.totalKeluarga,
                              totalPenduduk: dashboardProv.dashboard!.ringkasan.totalPenduduk,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            _legendDot(cs.primary, 'KK'),
                            const SizedBox(width: 24),
                            _legendDot(AppTheme.info, 'Jiwa'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildPerDusunSection(context, dashboardProv),
                    const SizedBox(height: 16),
                    _buildKesehatanSection(context, dashboardProv),
                  ],

                  if (dashboardProv.apiMessage != null && dashboardProv.dashboard != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Card(
                        color: cs.secondaryContainer.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 18, color: cs.onSecondaryContainer),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  dashboardProv.apiMessage!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSecondaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chart Card using M3 Card widget ──
  Widget _buildChartCard(BuildContext context, String title, IconData icon, Widget chart) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 14),
            chart,
          ],
        ),
      ),
    );
  }

  // ── Ringkasan ──
  Widget _buildRingkasanSection(BuildContext context, DashboardProvider prov) {
    final data = prov.dashboard!;
    final ringkasan = data.ringkasan;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics_rounded, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Text('Ringkasan', style: theme.textTheme.titleLarge),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tahun ${data.configYear}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            StatCard(
              title: 'Keluarga',
              value: ringkasan.totalKeluarga.toString(),
              icon: Icons.family_restroom_rounded,
              color: cs.primary,
            ),
            StatCard(
              title: 'Penduduk',
              value: ringkasan.totalPenduduk.toString(),
              icon: Icons.people_rounded,
              color: AppTheme.info,
            ),
            StatCard(
              title: 'Laki-laki',
              value: ringkasan.totalLakiLaki.toString(),
              icon: Icons.male_rounded,
              color: AppTheme.male,
            ),
            StatCard(
              title: 'Perempuan',
              value: ringkasan.totalPerempuan.toString(),
              icon: Icons.female_rounded,
              color: AppTheme.female,
            ),
          ],
        ),
      ],
    );
  }

  // ── Ibu & Anak Catatan ──
  Widget _buildCatatanSection(BuildContext context, DashboardProvider prov) {
    final cs = prov.dashboard!.catatanSummary;
    final theme = Theme.of(context);

    if (cs.totalCatatan == 0 && cs.hamilBulanIni == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.female.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.child_care_rounded, size: 18, color: AppTheme.female),
            ),
            const SizedBox(width: 10),
            Text('Ibu & Anak', style: theme.textTheme.titleLarge),
            const Spacer(),
            if (cs.totalCatatan > 0)
              Text(
                '${cs.totalCatatan} catatan',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _catatanStatCard(
                icon: Icons.pregnant_woman_rounded,
                value: cs.hamilBulanIni,
                label: 'Hamil',
                color: AppTheme.female,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _catatanStatCard(
                icon: Icons.child_friendly_rounded,
                value: cs.melahirkanBulanIni,
                label: 'Melahirkan',
                color: AppTheme.info,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _catatanStatCard(
                icon: Icons.healing_rounded,
                value: cs.kematianBayiBalita,
                label: 'Kematian',
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _catatanStatCard({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Detail per Dusun ──
  Widget _buildPerDusunSection(BuildContext context, DashboardProvider prov) {
    final data = prov.dashboard!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_rounded, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Text('Detail per Dusun', style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        ...data.perDusun.map((dusun) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${dusun.id}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dusun.dusun,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dusun.totalKeluarga} KK  ·  ${dusun.totalPenduduk} Jiwa',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            )),
        if (data.perDusun.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grafik Penduduk per Dusun',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    DusunPendudukChart(perDusun: data.perDusun),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Data Kesehatan ──
  Widget _buildKesehatanSection(BuildContext context, DashboardProvider prov) {
    final data = prov.dashboard!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (data.kesehatan.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite_rounded, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Text('Data Kesehatan', style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        ...data.kesehatan.map((k) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          k.dusun,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _kesehatanChip('Balita', k.totalBalita, Colors.orange),
                        const SizedBox(width: 8),
                        _kesehatanChip('Bumil', k.ibuHamil, AppTheme.female),
                        const SizedBox(width: 8),
                        _kesehatanChip('Stunting', k.stunting, AppTheme.error),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // ── Desa Info Chip ──
  Widget _buildDesaInfo(BuildContext context, ColorScheme cs) {
    final user = context.watch<AuthProvider>().user;
    if (user?.desaName == null && user?.kecamatanName == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 13, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              [
                if (user?.desaName != null) user!.desaName!,
                if (user?.kecamatanName != null) 'Kec. ${user!.kecamatanName!}',
              ].join(' · '),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ──

  Widget _kesehatanChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
