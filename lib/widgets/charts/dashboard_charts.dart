import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_model.dart';

// ======================== GENDER PIE CHART ========================

class GenderPieChart extends StatelessWidget {
  final Ringkasan ringkasan;

  const GenderPieChart({super.key, required this.ringkasan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = ringkasan.totalLakiLaki + ringkasan.totalPerempuan;
    if (total == 0) {
      return _emptyChart('Belum ada data penduduk',
        iconColor: cs.onSurfaceVariant.withValues(alpha: 0.4),
        textColor: cs.onSurfaceVariant.withValues(alpha: 0.6),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 45,
              sections: [
                PieChartSectionData(
                  value: ringkasan.totalLakiLaki.toDouble(),
                  color: AppTheme.male,
                  radius: 35,
                  title: '${(ringkasan.totalLakiLaki / total * 100).toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  value: ringkasan.totalPerempuan.toDouble(),
                  color: AppTheme.female,
                  radius: 35,
                  title: '${(ringkasan.totalPerempuan / total * 100).toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(AppTheme.male, 'Laki-laki (${ringkasan.totalLakiLaki})',
                textColor: cs.onSurfaceVariant),
            const SizedBox(width: 24),
            _legendItem(AppTheme.female, 'Perempuan (${ringkasan.totalPerempuan})',
                textColor: cs.onSurfaceVariant),
          ],
        ),
      ],
    );
  }
}

// ======================== DUSUN BAR CHART ========================

class DusunBarChart extends StatelessWidget {
  final List<PerDusun> perDusun;

  const DusunBarChart({super.key, required this.perDusun});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = perDusun;
    if (data.isEmpty) {
      return _emptyChart('Belum ada data dusun',
          iconColor: cs.onSurfaceVariant.withValues(alpha: 0.4),
          textColor: cs.onSurfaceVariant.withValues(alpha: 0.6));
    }

    final maxValue = data.map((e) => e.totalKeluarga).reduce((a, b) => a > b ? a : b).toDouble();
    final colors = [
      cs.primary,
      cs.tertiary,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.female,
      AppTheme.male,
    ];

    return SizedBox(
      height: data.length * 60.0 + 20,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue * 1.2,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxValue / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: cs.outlineVariant,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: d.totalKeluarga.toDouble(),
                    color: colors[index % colors.length],
                    width: 22,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ======================== LINE CHART (Monthly Simulation) ========================

class MonthlyLineChart extends StatelessWidget {
  final int totalKeluarga;
  final int totalPenduduk;

  const MonthlyLineChart({super.key, required this.totalKeluarga, required this.totalPenduduk});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Generate simulated monthly data based on real totals
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final now = DateTime.now();
    final currentMonth = now.month;

    final List<FlSpot> keluargaSpots = [];
    final List<FlSpot> pendudukSpots = [];

    for (int i = 0; i < currentMonth; i++) {
      final progress = (i + 1) / currentMonth;
      final variation = sin((i + 1) * pi / currentMonth);
      final kkValue = (totalKeluarga * progress * (0.85 + 0.15 * variation)).roundToDouble();
      final pdValue = (totalPenduduk * progress * (0.85 + 0.15 * variation)).roundToDouble();

      keluargaSpots.add(FlSpot(i.toDouble(), kkValue));
      pendudukSpots.add(FlSpot(i.toDouble(), pdValue));
    }

    if (keluargaSpots.isEmpty) {
      return _emptyChart('Belum ada data',
          iconColor: cs.onSurfaceVariant.withValues(alpha: 0.4),
          textColor: cs.onSurfaceVariant.withValues(alpha: 0.6));
    }

    final maxY = pendudukSpots.isNotEmpty
        ? (pendudukSpots.last.y * 1.2)
        : 100.0;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (currentMonth - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: cs.outlineVariant,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: max(1, (currentMonth / 6).ceil()).toDouble(),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(months[idx],
                        style: TextStyle(fontSize: 9,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text('${value.toInt()}',
                      style: TextStyle(fontSize: 9,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6)));
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: keluargaSpots,
              isCurved: true,
              color: cs.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: cs.primary.withValues(alpha: 0.08),
              ),
            ),
            LineChartBarData(
              spots: pendudukSpots,
              isCurved: true,
              color: cs.tertiary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: cs.tertiary.withValues(alpha: 0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isKeluarga = keluargaSpots.any((s) => s.x == spot.x && s.y == spot.y);
                  return LineTooltipItem(
                    '${isKeluarga ? "KK" : "Jiwa"}: ${spot.y.toInt()}',
                    TextStyle(
                      color: isKeluarga ? cs.primary : cs.tertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ======================== DUSUN PENDUDUK CHART (Stacked) ========================

class DusunPendudukChart extends StatelessWidget {
  final List<PerDusun> perDusun;

  const DusunPendudukChart({super.key, required this.perDusun});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = perDusun;
    if (data.isEmpty) {
      return _emptyChart('Belum ada data',
          iconColor: cs.onSurfaceVariant.withValues(alpha: 0.4),
          textColor: cs.onSurfaceVariant.withValues(alpha: 0.6));
    }

    final maxValue = data.map((e) => e.totalPenduduk).reduce((a, b) => a > b ? a : b).toDouble();
    final colors = [
      cs.primary,
      cs.tertiary,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.female,
      AppTheme.male,
    ];

    return SizedBox(
      height: data.length * 60.0 + 20,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue * 1.2,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        data[idx].dusun.length > 8 ? '${data[idx].dusun.substring(0, 8)}...' : data[idx].dusun,
                        style: TextStyle(fontSize: 9,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: data.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: d.totalKeluarga.toDouble(),
                    color: colors[index % colors.length],
                    width: 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  BarChartRodData(
                    toY: d.totalPenduduk.toDouble(),
                    color: colors[index % colors.length].withValues(alpha: 0.4),
                    width: 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ======================== HELPERS ========================

Widget _legendItem(Color color, String label, {required Color textColor}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: textColor)),
    ],
  );
}

Widget _emptyChart(String message, {required Color iconColor, required Color textColor}) {
  return SizedBox(
    height: 120,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 32, color: iconColor),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    ),
  );
}
