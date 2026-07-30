import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/weather_service.dart';
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
    final user = context.read<AuthProvider>().user;
    final desa = user?.desaName ?? user?.kecamatanName ?? '';
    if (desa.isEmpty) {
      if (mounted) setState(() => _weatherLoading = false);
      return;
    }

    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });

    final weather = await _weatherService.getWeather(desa);
    if (mounted) {
      setState(() {
        _weather = weather;
        _weatherLoading = false;
        if (!weather.isValid && weather.description == 'Tidak tersedia') {
          _weatherError = 'Gagal memuat cuaca';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProv = context.watch<DashboardProvider>();

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => dashboardProv.loadDashboard(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 140,
              pinned: false,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: AppTheme.gradientHeader,
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Dashboard SIEDA',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sistem Informasi e-Dasawisma',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 4),
                      // Desa & Kecamatan info
                      _buildDesaInfo(context),
                    ],
                  ),
                ),
              ),
            ),

            // Content
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
                    // Ringkasan Cards
                    _buildRingkasanSection(context, dashboardProv),
                    const SizedBox(height: 16),

                    // Catatan Kelahiran & Kematian — Ringkasan
                    _buildCatatanSection(context, dashboardProv),
                    const SizedBox(height: 16),

                    // Weather Card
                    WeatherCard(
                      weather: _weather,
                      isLoading: _weatherLoading,
                      errorMessage: _weatherError,
                      onRefresh: _loadWeather,
                    ),
                    const SizedBox(height: 16),

                    // Pie Chart: Gender Distribution
                    _buildChartCard(
                      context,
                      'Perbandingan Gender',
                      Icons.pie_chart_rounded,
                      GenderPieChart(ringkasan: dashboardProv.dashboard!.ringkasan),
                    ),
                    const SizedBox(height: 16),

                    // Bar Chart: KK per Dusun
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

                    // Line Chart: Monthly Progress
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
                              _legendDot(AppTheme.primary, 'KK'),
                              const SizedBox(width: 24),
                              _legendDot(AppTheme.info, 'Jiwa'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab Bar: Detail per Dusun + Kesehatan
                    _buildPerDusunSection(context, dashboardProv),
                    const SizedBox(height: 16),
                    _buildKesehatanSection(context, dashboardProv),
                  ],

                  if (dashboardProv.apiMessage != null && dashboardProv.dashboard != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.info),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dashboardProv.apiMessage!,
                                style: const TextStyle(fontSize: 12, color: AppTheme.info),
                              ),
                            ),
                          ],
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

  Widget _buildChartCard(BuildContext context, String title, IconData icon, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          chart,
        ],
      ),
    );
  }

  Widget _buildRingkasanSection(BuildContext context, DashboardProvider prov) {
    final data = prov.dashboard!;
    final ringkasan = data.ringkasan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Ringkasan', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            Text('Tahun ${data.configYear}', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
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
              color: AppTheme.primary,
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

  Widget _buildCatatanSection(BuildContext context, DashboardProvider prov) {
    final cs = prov.dashboard!.catatanSummary;

    // Only show if there is at least some data
    if (cs.totalCatatan == 0 && cs.hamilBulanIni == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.female.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.child_care_rounded, size: 18, color: AppTheme.female),
            ),
            const SizedBox(width: 10),
            Text('Ibu & Anak', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            if (cs.totalCatatan > 0)
              Text('${cs.totalCatatan} catatan', style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
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
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerDusunSection(BuildContext context, DashboardProvider prov) {
    final data = prov.dashboard!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Detail per Dusun', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        ...data.perDusun.map((dusun) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.cardDecoration,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${dusun.id}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dusun.dusun, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${dusun.totalKeluarga} KK | ${dusun.totalPenduduk} Jiwa',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
                ],
              ),
            )),
        if (data.perDusun.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DusunPendudukChart(perDusun: data.perDusun),
          ),
      ],
    );
  }

  Widget _buildKesehatanSection(BuildContext context, DashboardProvider prov) {
    final data = prov.dashboard!;

    if (data.kesehatan.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Data Kesehatan', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        ...data.kesehatan.map((k) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k.dusun, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _kesehatanChip('Balita', k.totalBalita, Colors.orange),
                      const SizedBox(width: 6),
                      _kesehatanChip('Bumil', k.ibuHamil, AppTheme.female),
                      const SizedBox(width: 6),
                      _kesehatanChip('Stunting', k.stunting, AppTheme.error),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildDesaInfo(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user?.desaName == null && user?.kecamatanName == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              [
                if (user?.desaName != null) user!.desaName!,
                if (user?.kecamatanName != null) 'Kec. ${user!.kecamatanName!}',
              ].join(' · '),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kesehatanChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
