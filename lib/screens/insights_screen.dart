import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/trigger_engine.dart';
import 'dart:async';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final Color _primaryColor = const Color(0xFF4A6FA5); // blue
  final Color _accentColor = const Color(0xFF7B61FF); // purple

  final Color _textColor = const Color(0xFF1E2A38);
  final Color _subtitleColor = const Color(0xFF6B7C93);

  final Color _backgroundColor = const Color.fromARGB(
    255,
    3,
    33,
    78,
  ); // dark bg
  final Color _cardColor = const Color(0xFFDADFE6); // light cards
  String _topTrigger = '';
  bool _isLoading = true;

  // Stats
  int _thisMonthEpisodes = 0;
  String _improvementStr = '0%';
  bool _isImprovementPositive = true;
  Timer? _refreshTimer;

  // Monthly Trend (6 months)
  List<FlSpot> _monthlyTrendSpots = [];
  List<String> _monthlyTrendLabels = [];
  double _maxTrendY = 8.0;

  // Top Triggers
  List<PieChartSectionData> _triggerSections = [];
  List<Map<String, dynamic>> _triggerLegends = [];

  // Time of Day
  List<int> _timeOfDayCounts = [
    0,
    0,
    0,
    0,
  ]; // Morning, Afternoon, Evening, Night
  int _maxTimeOfDayCount = 10;
  String _mostFrequentTime = 'afternoon';

  @override
  void initState() {
    super.initState();

    _fetchInsightsData();

    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchInsightsData();
    });
  }

  Future<void> _fetchInsightsData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final logsQuery = await FirebaseFirestore.instance
          .collection('logs')
          .where('userId', isEqualTo: user.uid)
          .get();

      final now = DateTime.now();

      // Stats calculations
      int currentMonthEpisodes = 0;
      int previousMonthEpisodes = 0;

      // Monthly arrays (6 months including current)
      List<int> monthlyCounts = List.filled(6, 0);
      List<String> monthLabels = [];

      for (int i = 5; i >= 0; i--) {
        int targetMonth = now.month - i;

        while (targetMonth <= 0) {
          targetMonth += 12;
        }
        final monthStr = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ][targetMonth - 1];
        monthLabels.add(monthStr);
      }

      Map<String, int> triggersMap = {};
      Map<String, int> detectedTriggersMap = {};
      List<int> timeCounts = [0, 0, 0, 0];

      for (var doc in logsQuery.docs) {
        final data = doc.data();
        final detected = TriggerEngine.detectTriggers(data);

        detected.forEach((key, value) {
          detectedTriggersMap[key] = (detectedTriggersMap[key] ?? 0) + value;
        });
        final timestamp = data['date'] as Timestamp?;
        if (timestamp == null) continue;

        final date = timestamp.toDate();

        // This Month vs Last Month
        if ((data['isMigraine'] ?? false) &&
            date.year == now.year &&
            date.month == now.month) {
          currentMonthEpisodes++;
        } else {
          int prevMonth = now.month - 1;
          int prevYear = now.year;
          if (prevMonth == 0) {
            prevMonth = 12;
            prevYear -= 1;
          }
          if (date.year == prevYear && date.month == prevMonth) {
            previousMonthEpisodes++;
          }
        }

        // Monthly Trend
        int monthDiff = (now.year - date.year) * 12 + (now.month - date.month);
        if (monthDiff >= 0 && monthDiff < 6) {
          int index = 5 - monthDiff;
          monthlyCounts[index]++;
        }

        // Triggers
        if (data['triggers'] != null) {
          List<dynamic> triggers = data['triggers'];
          for (var t in triggers) {
            String trig = t.toString().trim();
            triggersMap[trig] = (triggersMap[trig] ?? 0) + 1;
          }
        }

        // Time of Day
        int hour = date.hour;
        if (hour >= 6 && hour < 12) {
          timeCounts[0]++; // Morning
        } else if (hour >= 12 && hour < 17) {
          timeCounts[1]++; // Afternoon
        } else if (hour >= 17 && hour < 21) {
          timeCounts[2]++; // Evening
        } else {
          timeCounts[3]++; // Night
        }
      }

      // Improvement calc
      double improvement = 0;
      bool isPos = true;
      String improvementText = '';

      if (previousMonthEpisodes == 0) {
        if (currentMonthEpisodes == 0) {
          improvementText = 'No data';
        } else {
          improvementText = 'New activity';
        }
        isPos = true;
      } else {
        improvement =
            ((previousMonthEpisodes - currentMonthEpisodes) /
                previousMonthEpisodes) *
            100;

        isPos = improvement >= 0;
        improvementText = '${improvement.abs().toInt()}%';
      }

      // Prepare LineChart
      List<FlSpot> spots = [];
      double maxY = 4;
      for (int i = 0; i < 6; i++) {
        double y = monthlyCounts[i].toDouble();
        if (y > maxY) maxY = y;
        spots.add(FlSpot(i.toDouble(), y));
      }

      Map<String, int> combinedTriggers = {};

      triggersMap.forEach((key, value) {
        combinedTriggers[key] = (combinedTriggers[key] ?? 0) + value;
      });

      detectedTriggersMap.forEach((key, value) {
        combinedTriggers[key] = (combinedTriggers[key] ?? 0) + value;
      });

      // Prepare PieChart
      var sortedTriggers = combinedTriggers.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sortedTriggers.isNotEmpty) {
        _topTrigger = sortedTriggers.first.key;
      } else {
        _topTrigger = 'No data';
      }
      List<PieChartSectionData> pieSections = [];
      List<Map<String, dynamic>> legends = [];
      int totalTriggers = combinedTriggers.values.fold(0, (a, b) => a + b);

      final colors = [
        _accentColor,
        const Color(0xFF9F8CFF),
        const Color(0xFFC3B8FF),
        const Color(0xFF6C8CFF),
        const Color(0xFF4A6FA5),
        Colors.grey,
      ];
      if (totalTriggers > 0) {
        int count = 0;
        for (var entry in sortedTriggers) {
          if (count >= 5) break; // show top 5
          double pct = (entry.value / totalTriggers) * 100;
          pieSections.add(
            PieChartSectionData(
              color: colors[count % colors.length],
              value: entry.value.toDouble(),
              title: '${entry.key} ${pct.toInt()}%',
              radius: 90,
              titleStyle: TextStyle(
                fontSize: 11,
                color: colors[count % colors.length],
                fontWeight: FontWeight.w500,
              ),
              titlePositionPercentageOffset: 1.3,
            ),
          );

          legends.add({
            'title': entry.key,
            'percentage': '${pct.toInt()}%',
            'color': colors[count % colors.length],
          });

          count++;
        }
      } else {
        pieSections.add(
          PieChartSectionData(
            color: Colors.grey.shade300,
            value: 1,
            title: 'No Data',
            radius: 90,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        );
      }

      // Time of Day stats
      int maxTime = timeCounts.fold(0, (a, b) => a > b ? a : b);
      String freqTime = 'afternoon';
      if (maxTime > 0) {
        int maxIndex = timeCounts.indexOf(maxTime);
        freqTime = ['morning', 'afternoon', 'evening', 'night'][maxIndex];
      }

      if (mounted) {
        setState(() {
          _thisMonthEpisodes = currentMonthEpisodes;
          _improvementStr = improvementText;
          _isImprovementPositive = isPos;
          _monthlyTrendSpots = spots;
          _monthlyTrendLabels = monthLabels;
          _maxTrendY = maxY + (maxY * 0.2); // Add 20% headroom
          _triggerSections = pieSections;
          _triggerLegends = legends;
          _timeOfDayCounts = timeCounts;
          _maxTimeOfDayCount = maxTime == 0 ? 5 : maxTime + (maxTime ~/ 2);
          _mostFrequentTime = freqTime;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching insights: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    color: _accentColor,
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Insights',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _cardColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analyze your patterns',
                      style: TextStyle(fontSize: 16, color: _subtitleColor),
                    ),
                    const SizedBox(height: 24),

                    // Top Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'This Month',
                            icon: Icons.calendar_today_outlined,
                            value: _thisMonthEpisodes.toString(),
                            subtitle: 'Episodes',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Improvement',
                            icon: _isImprovementPositive
                                ? Icons.trending_up
                                : Icons.trending_down,
                            value: _improvementStr,
                            subtitle:
                                _improvementStr == 'No data' ||
                                    _improvementStr == 'New activity'
                                ? ''
                                : 'vs Last Month',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Monthly Trend Line Chart
                    _buildChartCard(
                      title: 'Monthly Trend',
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: (_maxTrendY / 4) == 0
                                      ? 1
                                      : (_maxTrendY / 4).ceilToDouble(),
                                  verticalInterval: 1,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: _accentColor.withValues(alpha: 0.1),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
                                  ),
                                  getDrawingVerticalLine: (value) => FlLine(
                                    color: _accentColor.withValues(alpha: 0.1),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 &&
                                            value.toInt() <
                                                _monthlyTrendLabels.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: Text(
                                              _monthlyTrendLabels[value
                                                  .toInt()],
                                              style: TextStyle(
                                                color: _subtitleColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: (_maxTrendY / 4) == 0
                                          ? 1
                                          : (_maxTrendY / 4).ceilToDouble(),
                                      reservedSize: 24,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: TextStyle(
                                            color: _subtitleColor,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: 5,
                                minY: 0,
                                maxY: _maxTrendY,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _monthlyTrendSpots,
                                    isCurved: false,
                                    color: _accentColor,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter:
                                          (spot, percent, barData, index) =>
                                              FlDotCirclePainter(
                                                radius: 4,
                                                color: _accentColor,
                                                strokeWidth: 2,
                                                strokeColor: Colors.white,
                                              ),
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: _accentColor.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                ],
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        final month =
                                            _monthlyTrendLabels[spot.x.toInt()];
                                        return LineTooltipItem(
                                          '$month\nepisodes: ${spot.y.toInt()}',
                                          TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _cardColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _improvementStr == 'New activity'
                                      ? '🆕'
                                      : _improvementStr == 'No data'
                                      ? 'ℹ️'
                                      : _isImprovementPositive
                                      ? '📈'
                                      : '📉',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: _subtitleColor,
                                        fontSize: 13,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              _improvementStr == 'New activity'
                                              ? 'Tracking started! '
                                              : _improvementStr == 'No data'
                                              ? 'Insights unavailable! '
                                              : _isImprovementPositive
                                              ? 'Great progress! '
                                              : 'Keep tracking! ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _textColor,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _improvementStr == 'No data'
                                              ? 'Not enough data to compare with last month.'
                                              : _improvementStr ==
                                                    'New activity'
                                              ? 'New migraine activity detected this month.'
                                              : 'Your episodes have ${_isImprovementPositive ? 'decreased' : 'increased'} by $_improvementStr over the last month.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Top Triggers Pie Chart
                    _buildChartCard(
                      title: 'Top Triggers',
                      titleIcon: Icons.bolt,
                      iconColor: Colors.redAccent.withValues(alpha: 0.7),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 0,
                                    sections: _triggerSections,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),

                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: _cardColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🧠',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Most common trigger: $_topTrigger',
                                    style: TextStyle(
                                      color: _textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ), // Padding for pie chart labels
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _cardColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _triggerLegends.isEmpty
                                ? Text(
                                    'No trigger data found',
                                    style: TextStyle(color: _subtitleColor),
                                  )
                                : Column(
                                    children: _triggerLegends
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          bool isLast =
                                              entry.key ==
                                              _triggerLegends.length - 1;
                                          return Column(
                                            children: [
                                              _buildLegendItem(
                                                entry.value['title'],
                                                entry.value['percentage'],
                                                entry.value['color'],
                                              ),
                                              if (!isLast)
                                                const Divider(
                                                  height: 16,
                                                  color: Colors.white,
                                                ),
                                            ],
                                          );
                                        })
                                        .toList(),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Time of Day Bar Chart
                    _buildChartCard(
                      title: 'Time of Day',
                      child: Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,

                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (group) => _textColor,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                          return BarTooltipItem(
                                            rod.toY.toInt().toString(),
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                  ),
                                ),

                                maxY: _maxTimeOfDayCount.toDouble() + 1,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval:
                                      (_maxTimeOfDayCount / 3) == 0
                                      ? 1
                                      : (_maxTimeOfDayCount / 3).ceilToDouble(),
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: _primaryColor.withValues(alpha: 0.1),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget:
                                          (double value, TitleMeta meta) {
                                            const style = TextStyle(
                                              color: Color(0xFF788F94),
                                              fontSize: 11,
                                            );
                                            String text;
                                            switch (value.toInt()) {
                                              case 0:
                                                text = 'Morning';
                                                break;
                                              case 1:
                                                text = 'Afternoon';
                                                break;
                                              case 2:
                                                text = 'Evening';
                                                break;
                                              case 3:
                                                text = 'Night';
                                                break;
                                              default:
                                                text = '';
                                                break;
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(text, style: style),
                                            );
                                          },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: (_maxTimeOfDayCount / 3) == 0
                                          ? 1
                                          : (_maxTimeOfDayCount / 3)
                                                .ceilToDouble(),
                                      reservedSize: 24,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: TextStyle(
                                            color: _subtitleColor,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),

                                barGroups: [
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [
                                      BarChartRodData(
                                        toY: _timeOfDayCounts[0].toDouble(),
                                        color: _accentColor,
                                        width: 40,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: _timeOfDayCounts[1].toDouble(),
                                        color: _accentColor,
                                        width: 40,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 2,
                                    barRods: [
                                      BarChartRodData(
                                        toY: _timeOfDayCounts[2].toDouble(),
                                        color: _accentColor,
                                        width: 40,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 3,
                                    barRods: [
                                      BarChartRodData(
                                        toY: _timeOfDayCounts[3].toDouble(),
                                        color: _accentColor,
                                        width: 40,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _cardColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text('⏰', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: _subtitleColor,
                                        fontSize: 13,
                                      ),
                                      children: [
                                        const TextSpan(
                                          text: 'Most episodes occur in the ',
                                        ),
                                        TextSpan(
                                          text: _mostFrequentTime,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    IconData? titleIcon,
    Color? iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconColor?.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(titleIcon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, String percentage, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(color: _textColor, fontSize: 14)),
        const Spacer(),
        Text(
          percentage,
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
