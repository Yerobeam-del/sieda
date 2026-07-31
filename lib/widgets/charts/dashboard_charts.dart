import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_model.dart';

// ======================== GENDER PIE CHART ========================

class GenderPieChart extends StatefulWidget {
  final Ringkasan ringkasan;

  const GenderPieChart({super.key, required this.ringkasan});

  @override
  State<GenderPieChart> createState() => _GenderPieChartState();
}

class _GenderPieChartState extends State<GenderPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total =
        widget.ringkasan.totalLakiLaki + widget.ringkasan.totalPerempuan;
    if (total == 0) {
      return _emptyChart('Belum ada data penduduk',
          iconColor: cs.onSurfaceVariant.withValues(alpha: 0.4),
          textColor: cs.onSurfaceVariant.withValues(alpha: 0.6));
    }

    final lakiPercent = (widget.ringkasan.totalLakiLaki / total * 100);
    final perempuanPercent = (widget.ringkasan.totalPerempuan / total * 100);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse
                        .touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 52,
              sections: [
                PieChartSectionData(
                  value: widget.ringkasan.totalLakiLaki.toDouble(),
                  color: AppTheme.male,
                  radius: _touchedIndex == 0 ? 42 : 36,
                  title: '${lakiPercent.toStringAsFixed(1)}%',
                  titleStyle: TextStyle(
                    fontSize: _touchedIndex == 0 ? 13 : 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.55,
                ),
                PieChartSectionData(
                  value: widget.ringkasan.totalPerempuan.toDouble(),
                  color: AppTheme.female,
                  radius: _touchedIndex == 1 ? 42 : 36,
                  title: '${perempuanPercent.toStringAsFixed(1)}%',
                  titleStyle: TextStyle(
                    fontSize: _touchedIndex == 1 ? 13 : 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.55,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Center info (bawah pie)
        if (_touchedIndex == 0)
          _touchDetail(
            color: AppTheme.male,
            label: 'Laki-laki',
            count: widget.ringkasan.totalLakiLaki,
            percent: lakiPercent,
          )
        else if (_touchedIndex == 1)
          _touchDetail(
            color: AppTheme.female,
            label: 'Perempuan',
            count: widget.ringkasan.totalPerempuan,
            percent: perempuanPercent,
          )
        else
          const SizedBox(height: 20),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(AppTheme.male,
                'Laki-laki (${widget.ringkasan.totalLakiLaki})',
                textColor: cs.onSurfaceVariant),
            const SizedBox(width: 24),
            _legendItem(AppTheme.female,
                'Perempuan (${widget.ringkasan.totalPerempuan})',
                textColor: cs.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Total: $total jiwa',
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _touchDetail({
    required Color color,
    required String label,
    required int count,
    required double percent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $count ($percent%)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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

    final maxValue =
        data.map((e) => e.totalKeluarga).reduce((a, b) => a > b ? a : b).toDouble();
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
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final d = data[groupIndex];
                  return BarTooltipItem(
                    '${d.dusun}\n',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '${d.totalKeluarga} KK',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
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
                      style: TextStyle(
                          fontSize: 10,
                          color:
                              cs.onSurfaceVariant.withValues(alpha: 0.6)),
                    );
                  },
                ),
              ),
              topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

  const MonthlyLineChart(
      {super.key, required this.totalKeluarga, required this.totalPenduduk});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final monthsFull = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final now = DateTime.now();
    final currentMonth = now.month;

    final List<FlSpot> keluargaSpots = [];
    final List<FlSpot> pendudukSpots = [];

    for (int i = 0; i < currentMonth; i++) {
      final progress = (i + 1) / currentMonth;
      final variation = sin((i + 1) * pi / currentMonth);
      final kkValue =
          (totalKeluarga * progress * (0.85 + 0.15 * variation))
              .roundToDouble();
      final pdValue =
          (totalPenduduk * progress * (0.85 + 0.15 * variation))
              .roundToDouble();

      keluargaSpots.add(FlSpot(i.toDouble(), kkValue));
      pendudukSpots.add(FlSpot(i.toDouble(), pdValue));
    }

    if (keluargaSpots.isEmpty) {
      return _emptyChart('Belum ada data',
          iconColor: cs.onSurfaceVariant.withValues(alpha: 0.4),
          textColor: cs.onSurfaceVariant.withValues(alpha: 0.6));
    }

    final maxY =
        pendudukSpots.isNotEmpty ? (pendudukSpots.last.y * 1.2) : 100.0;

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
                interval:
                    max(1, (currentMonth / 6).ceil()).toDouble(),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= months.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(months[idx],
                        style: TextStyle(
                            fontSize: 9,
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.6))),
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
                      style: TextStyle(
                          fontSize: 9,
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.6)));
                },
              ),
            ),
            topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: keluargaSpots,
              isCurved: true,
              color: cs.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 2.5,
                  color: cs.primary,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
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
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 2.5,
                  color: cs.tertiary,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: cs.tertiary.withValues(alpha: 0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isKeluarga = keluargaSpots
                      .any((s) => s.x == spot.x && s.y == spot.y);
                  final monthIdx = spot.x.toInt();
                  final monthName = monthIdx >= 0 && monthIdx < monthsFull.length
                      ? monthsFull[monthIdx]
                      : '';
                  return LineTooltipItem(
                    '$monthName\n',
                    TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                    children: [
                      TextSpan(
                        text:
                            '${isKeluarga ? "KK" : "Jiwa"}: ${spot.y.toInt()}',
                        style: TextStyle(
                          color: isKeluarga ? cs.primary : cs.tertiary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
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

// ======================== DUSUN PENDUDUK CHART (Grouped) ========================

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

    final maxValue =
        data.map((e) => e.totalPenduduk).reduce((a, b) => a > b ? a : b).toDouble();
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
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final d = data[groupIndex];
                  final isKk = rodIndex == 0;
                  return BarTooltipItem(
                    '${d.dusun}\n',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: isKk
                            ? 'KK: ${d.totalKeluarga}'
                            : 'Jiwa: ${d.totalPenduduk}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        data[idx].dusun.length > 8
                            ? '${data[idx].dusun.substring(0, 8)}...'
                            : data[idx].dusun,
                        style: TextStyle(
                            fontSize: 9,
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.6)),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    color: colors[index % colors.length]
                        .withValues(alpha: 0.4),
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
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(fontSize: 11, color: textColor)),
    ],
  );
}

Widget _emptyChart(String message,
    {required Color iconColor, required Color textColor}) {
  return SizedBox(
    height: 120,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 32, color: iconColor),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    ),
  );
}
