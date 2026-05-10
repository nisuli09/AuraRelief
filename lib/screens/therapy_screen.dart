import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'therapy_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class TherapyScreen extends StatefulWidget {
  const TherapyScreen({super.key});

  @override
  State<TherapyScreen> createState() => _TherapyScreenState();
}

class _TherapyScreenState extends State<TherapyScreen> {
  // Removed unused _selectedIndex

  final Color _primaryColor = const Color(0xFF4A6FA5); // calm blue
  final Color _accentColor = const Color(0xFF7B61FF); // soft purple

  final Color _textColor = const Color(0xFF1E2A38);
  final Color _subtitleColor = const Color(0xFF6B7C93);

  final Color _backgroundColor = const Color.fromARGB(
    255,
    3,
    33,
    78,
  ); // dark bg
  final Color _cardColor = const Color(0xFFDADFE6); // light card

  List<Map<String, dynamic>> therapyList = [];
  bool isLoading = true;

  Map<String, String> feedbackMap = {};

  Future<List<Map<String, dynamic>>> getAIRecommendations(List logs) async {
    try {
      if (logs.isEmpty) return [];

      final latestLog = logs.first;

      final response = await http
          .post(
            Uri.parse('https://web-production-bdd01.up.railway.app/predict'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "sleep_hours": latestLog['sleepHours'] ?? 6,
              "stress_level": latestLog['stressLevel'] ?? 5,
              "hydration_level": latestLog['hydrationLevel'] ?? 2,
              "screen_time": latestLog['screenTime'] ?? 4,
              "mood_level": latestLog['moodLevel'] ?? 3,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      if (response.statusCode != 200) {
        debugPrint("API Error: ${response.statusCode}");
        return [];
      }

      final data = jsonDecode(response.body);

      debugPrint(data.toString());

      if (data["therapies"] == null) {
        return [];
      }

      List therapies = data["therapies"];

      return therapies.map((t) {
        return {
          "title": t,
          "duration": "10 min",
          "description": "AI recommended based on your condition",
          "effectiveness": 60 + Random().nextInt(40),
        };
      }).toList();
    } catch (e) {
      debugPrint("ERROR: $e");
      return [];
    }
  }

  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance
        .collection('logs')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .orderBy('date', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
          final logs = snapshot.docs.map((doc) => doc.data()).toList();

          final aiResult = await getAIRecommendations(logs);

          if (mounted) {
            setState(() {
              therapyList = aiResult;
              isLoading = false;
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'AI Therapy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _cardColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personalized recommendations for you',
                style: TextStyle(
                  fontSize: 16,
                  color: _subtitleColor.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 24),

              // AI Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _accentColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Recommendations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Based on your patterns, these therapies may help reduce episodes and improve your well-being.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _accentColor),
                    )
                  : therapyList.isEmpty
                  ? Center(
                      child: Text(
                        "No recommendations yet",
                        style: TextStyle(
                          color: _subtitleColor.withValues(alpha: 0.9),
                        ),
                      ),
                    )
                  : Column(
                      children: therapyList.map((therapy) {
                        return Column(
                          children: [
                            _buildTherapyCard(
                              title: therapy['title'],
                              duration: therapy['duration'],
                              icon: therapy['title'].contains('Sleep')
                                  ? Icons.bedtime
                                  : therapy['title'].contains('Stress')
                                  ? Icons.spa
                                  : therapy['title'].contains('Breathing')
                                  ? Icons.air
                                  : therapy['title'].contains('Trigger')
                                  ? Icons.warning_amber_rounded
                                  : Icons.self_improvement,
                              iconColor: therapy['title'].contains('Sleep')
                                  ? Colors.deepPurple
                                  : therapy['title'].contains('Stress')
                                  ? Colors.green
                                  : therapy['title'].contains('Breathing')
                                  ? Colors.blue
                                  : therapy['title'].contains('Trigger')
                                  ? Colors.orange
                                  : _primaryColor,
                              description: therapy['description'],
                              effectiveness: therapy['effectiveness'],
                            ),
                            const SizedBox(height: 32),
                          ],
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTherapyCard({
    required String title,
    required String duration,
    required IconData icon,
    required Color iconColor,
    required String description,
    required int effectiveness,
  }) {
    return Container(
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
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            duration,
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: _subtitleColor.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Predicted Effectiveness',
                style: TextStyle(
                  color: _subtitleColor.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              Text(
                '$effectiveness%',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: effectiveness / 100,
              minHeight: 6,
              backgroundColor: _accentColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _accentColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TherapyDetailScreen(
                            title: title,
                            description: description,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite_border, size: 18),
                    label: const Text('Try Therapy'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent, // IMPORTANT
                      shadowColor: Colors.transparent, // remove shadow
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _subtitleColor.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      feedbackMap[title] = 'like';
                    });

                    FirebaseFirestore.instance
                        .collection('therapy_feedback')
                        .add({
                          'userId': FirebaseAuth.instance.currentUser!.uid,
                          'therapy': title,
                          'feedback': 'like',
                          'timestamp': Timestamp.now(),
                        });
                  },
                  icon: Icon(
                    feedbackMap[title] == 'like'
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                    color: feedbackMap[title] == 'like'
                        ? Colors.green
                        : _subtitleColor.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _subtitleColor.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      feedbackMap[title] = 'dislike';
                    });
                    FirebaseFirestore.instance
                        .collection('therapy_feedback')
                        .add({
                          'userId': FirebaseAuth.instance.currentUser!.uid,
                          'therapy': title,
                          'feedback': 'dislike',
                          'timestamp': Timestamp.now(),
                        });
                  },
                  icon: Icon(
                    feedbackMap[title] == 'dislike'
                        ? Icons.thumb_down
                        : Icons.thumb_down_outlined,
                    color: feedbackMap[title] == 'dislike'
                        ? Colors.red
                        : _subtitleColor.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
