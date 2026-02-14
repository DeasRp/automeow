import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../service/mqtt_service.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  int touchedIndex = -1;

  List<double> calculateWeeklyConsumption(List<Map<String, dynamic>> history) {
    List<double> weeklyTotals = List.filled(7, 0.0);
    final now = DateTime.now();
    
    // Cari awal minggu ini (Senin)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final resetTime = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    for (var item in history) {
      if (item['time'] != null && item['amount'] != null) {
        DateTime date = item['time'];
        // Hanya hitung data jika terjadi di minggu ini
        if (date.isAfter(resetTime) || date.isAtSameMomentAs(resetTime)) {
          double amount = (item['amount'] is int)
              ? (item['amount'] as int).toDouble()
              : item['amount'];
          int index = date.weekday - 1;
          if (index >= 0 && index < 7) {
            weeklyTotals[index] += amount;
          }
        }
      }
    }
    return weeklyTotals;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mqtt = Provider.of<MQTTService>(context);
    final weeklyData = calculateWeeklyConsumption(mqtt.feedHistory);
    final int todayIndex = DateTime.now().weekday - 1;
    final double totalWeek = weeklyData.reduce((a, b) => a + b);
    
    // Mencari nilai tertinggi untuk skala Y yang dinamis
    double maxVal = weeklyData.reduce((a, b) => a > b ? a : b);
    maxVal = maxVal < 1.0 ? 1.0 : maxVal * 1.2; 

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(isDark),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSummaryCard(totalWeek, isDark),
                  const SizedBox(height: 20),
                  _buildChartCard(weeklyData, todayIndex, maxVal, isDark),
                  const SizedBox(height: 20),
                  _buildInfoSection(totalWeek, isDark),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? Colors.black : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Statistik Pakan',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            //fontSize: 18,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
    );
  }

  Widget _buildSummaryCard(double total, bool isDark) {
    return _buildSectionCard(
      'Ringkasan',
      FontAwesomeIcons.circleInfo,
      isDark,
      [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(FontAwesomeIcons.weightHanging, 
                  color: Colors.blue.shade700, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Konsumsi Minggu Ini',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  '${total.toStringAsFixed(2)} Kg',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard(List<double> data, int today, double max, bool isDark) {
    return _buildSectionCard(
      'Grafik Konsumsi',
      FontAwesomeIcons.chartLine,
      isDark,
      [
        SizedBox(
          height: 250,
          child: BarChart(
            mainBarData(data, today, max, isDark),
            duration: const Duration(milliseconds: 250),
            curve: Curves.linear,
          ),
        ),
      ],
    );
  }

  BarChartData mainBarData(List<double> data, int today, double max, bool isDark) {
    return BarChartData(
      maxY: max,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => isDark ? Colors.grey[800]! : Colors.blueGrey[900]!,
          tooltipBorder: const BorderSide(color: Colors.transparent, width: 0),          
          tooltipPadding: const EdgeInsets.all(8),
          tooltipMargin: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${rod.toY.toStringAsFixed(2)} Kg',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          },
        ),
        touchCallback: (event, response) {
          setState(() {
            if (!event.isInterestedForInteractions || response == null || response.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = response.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) => Text(
              value.toStringAsFixed(1),
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
              final isToday = value.toInt() == today;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  days[value.toInt()],
                  style: TextStyle(
                    color: isToday ? Colors.orange : Colors.grey,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark ? Colors.white10 : Colors.black12,
          strokeWidth: 1,
        ),
      ),
      barGroups: List.generate(7, (i) => makeGroupData(i, data[i], i == today, isDark)),
    );
  }

  BarChartGroupData makeGroupData(int x, double y, bool isToday, bool isDark) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: x == touchedIndex 
              ? Colors.orangeAccent 
              : (isToday ? Colors.orange : Colors.blue.shade400),
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(
            show: false,
            toY: 2.0, // Bisa dibuat dinamis sesuai maxY
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(double total, bool isDark) {
    if (total <= 0) return _buildEmptyState(isDark);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withValues(alpha:0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tips: Konsumsi pakan stabil minggu ini. Pastikan stok dispenser tetap terisi.',
              style: TextStyle(
                fontSize: 12, 
                color: isDark ? Colors.orange.shade200 : Colors.orange.shade900
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withValues(alpha:0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          FaIcon(FontAwesomeIcons.database, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data pakan minggu ini',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}