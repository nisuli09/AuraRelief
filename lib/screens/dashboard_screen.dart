import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'prediction_screen.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _streakDays = 0;
  double _averagePain = 0.0;

  StreamSubscription? _subscription;

  List<FlSpot> _weeklySpots = [];
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;
  String _painStatusText = 'No data available yet';

  String _getGreeting() {
  final hour = DateTime.now().hour;

  if (hour < 12) {
    return 'Good Morning';
  } else if (hour < 17) {
    return 'Good Afternoon';
  } else if (hour < 21) {
    return 'Good Evening';
  } else {
    return 'Good Night';
  }
}

  final Color _primaryColor = const Color(0xFF4A6FA5); // calm blue
  final Color _accentColor = const Color(0xFF7B61FF); // soft purple

  final Color _textColor = const Color(0xFF1E2A38); // dark text
  final Color _subtitleColor = const Color(0xFF6B7C93); // soft gray

  final Color _backgroundColor = const Color.fromARGB(
    255,
    3,
    33,
    78,
  ); // light background
  final Color _cardColor = const Color(0xFFDADFE6); // white card

  @override
  void initState() {
    super.initState();
    _listenToDashboardData();
  }

  void _listenToDashboardData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _subscription = FirebaseFirestore.instance
        .collection('logs')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
          final docs = snapshot.docs.toList();

          // SORT
          docs.sort((a, b) {
            final aTimestamp = a.data()['date'] as Timestamp?;
            final bTimestamp = b.data()['date'] as Timestamp?;

            if (aTimestamp == null || bTimestamp == null) {
              return 0;
            }

            final aDate = aTimestamp.toDate();
            final bDate = bTimestamp.toDate();

            return bDate.compareTo(aDate);
          });

          int migraineFreeStreak = 0;

          DateTime today = DateTime.now();
          today = DateTime(today.year, today.month, today.day);

          for (var doc in docs) {
            final data = doc.data();
            final pain = data['painLevel'] ?? 0;

            final timestamp = data['date'] as Timestamp?;
            if (timestamp == null) continue;

            final rawDate = timestamp.toDate();
            final date = DateTime(rawDate.year, rawDate.month, rawDate.day);

            final diff = today.difference(date).inDays;

            if (diff <= migraineFreeStreak + 1) {
              if (pain == 0) {
                migraineFreeStreak++;
              } else {
                break;
              }
            }
          }

          double totalPain = 0;
          int painCount = 0;
          List<int> dailyEpisodes = List.filled(7, 0);
          List<Map<String, dynamic>> activities = [];

          final now = DateTime.now();
          final sevenDaysAgo = now.subtract(const Duration(days: 6));
          final startDate = DateTime(
            sevenDaysAgo.year,
            sevenDaysAgo.month,
            sevenDaysAgo.day,
          );

          for (var doc in docs) {
            final data = doc.data();
            final timestamp = data['date'] as Timestamp?;
            if (timestamp == null) continue;

            final date = timestamp.toDate();

            if (date.isBefore(startDate)) continue;

            final daysDifference = now.difference(date).inDays;

            if (daysDifference >= 0 && daysDifference < 7) {
              int index = 6 - daysDifference;
              if (index >= 0 && index < 7) {
                dailyEpisodes[index]++;
              }
            }

            if (data['painLevel'] != null) {
              totalPain += (data['painLevel'] as num).toDouble();
              painCount++;
            }

            if (activities.length < 3) {
              activities.add({
                'title': 'Logged migraine episode (Pain: ${data['painLevel']})',
                'time': _getTimeAgo(date),
                'color': _accentColor,
              });
            }
          }

          List<FlSpot> spots = [];
          for (int i = 0; i < 7; i++) {
            spots.add(FlSpot(i.toDouble(), dailyEpisodes[i].toDouble()));
          }

          String painStatus = 'No recent episodes';
          if (painCount > 0) {
            double avg = totalPain / painCount;

            if (avg < 3) {
              painStatus = 'Great job! Keep up the healthy habits';
            } else if (avg <= 6) {
              painStatus = 'Hang in there! Make sure to rest';
            } else {
              painStatus = 'Tough week. Consider consulting a doctor';
            }
          }

          if (mounted) {
            setState(() {
              _streakDays = migraineFreeStreak;
              _averagePain = painCount > 0 ? totalPain / painCount : 0.0;
              _weeklySpots = spots;
              _recentActivities = activities;
              _painStatusText = painStatus;
              _isLoading = false;
            });
          }
        });
  }

  String _getTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    

    double maxY = _weeklySpots.isEmpty
        ? 4
        : _weeklySpots
                  .map((e) => e.y)
                  .fold(4.0, (max, y) => y > max ? y : max) +
              1;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _accentColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Hello, ${_getGreeting()} 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _cardColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Track your migraine wellness',
                      style: TextStyle(fontSize: 16, color: _subtitleColor),
                    ),
                    const SizedBox(height: 24),

                    // Streak Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _accentColor],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Migraine-Free Streak',
                                    style: TextStyle(
                                      color: Color(0xFFF5F7FB),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _streakDays.toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF1E2A38),
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'days',
                                        style: TextStyle(
                                          color: Color(0xFFF5F7FB),
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Color(0xFF1E2A38),
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _painStatusText,
                                  style: TextStyle(
                                    color: const Color(0xFFF5F7FB),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Weekly Overview
                    Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Overview (Episodes)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _cardColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 160,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: 1,
                                    verticalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withValues(
                                          alpha: 0.2,
                                        ),
                                        strokeWidth: 1,
                                        dashArray: [4, 4],
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withValues(
                                          alpha: 0.2,
                                        ),
                                        strokeWidth: 1,
                                        dashArray: [4, 4],
                                      );
                                    },
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
                                        reservedSize: 30,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          final now = DateTime.now();
                                          final int val = value.toInt();
                                          if (val >= 0 && val < 7) {
                                            final date = now.subtract(
                                              Duration(days: 6 - val),
                                            );
                                            final titles = [
                                              'Mon',
                                              'Tue',
                                              'Wed',
                                              'Thu',
                                              'Fri',
                                              'Sat',
                                              'Sun',
                                            ];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                titles[date.weekday - 1],
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
                                        interval: 1,
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

                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipColor: (touchedSpot) =>
                                          _textColor,
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          return LineTooltipItem(
                                            spot.y.toInt().toString(),
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),

                                  minX: 0,
                                  maxX: 6,
                                  minY: 0,
                                  maxY: maxY,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _weeklySpots.isEmpty
                                          ? [const FlSpot(0, 0)]
                                          : _weeklySpots,
                                      isCurved: true,
                                      curveSmoothness: 0.35,
                                      color: _accentColor,
                                      barWidth: 2.5,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter:
                                            (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 4,
                                                color: _accentColor,
                                                strokeWidth: 2,
                                                strokeColor: _cardColor,
                                              );
                                            },
                                      ),

                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: _accentColor.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Text(
                                'Average pain level: ${_averagePain.toStringAsFixed(1)} / 10',
                                style: TextStyle(
                                  color: _subtitleColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _cardColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      'Quick Log',
                      Icons.flash_on,
                      _accentColor,
                      true,
                      () {
                        widget.onTabChange?.call(1);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      'View Insights',
                      Icons.trending_down,
                      _primaryColor,
                      false,
                      () {
                        widget.onTabChange?.call(2);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      'AI Therapy',
                      Icons.auto_awesome,
                      _accentColor,
                      true,
                      () {
                        widget.onTabChange?.call(3);
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildActionButton(
                      'AI Prediction',
                      Icons.psychology,
                      _primaryColor,
                      false,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PredictionScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _cardColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_recentActivities.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'No recent activities yet',
                            style: TextStyle(
                              color: _subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: _recentActivities.asMap().entries.map((
                            entry,
                          ) {
                            final isLast =
                                entry.key == _recentActivities.length - 1;
                            return Column(
                              children: [
                                _buildActivityItem(
                                  entry.value['title'],
                                  entry.value['time'],
                                  entry.value['color'],
                                ),
                                if (!isLast) const SizedBox(height: 16),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color bgColor,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDark ? Colors.white : _textColor),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : _textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, Color dotColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: _subtitleColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
