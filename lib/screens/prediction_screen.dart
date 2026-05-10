import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  double sleepHours = 7;
  double stressLevel = 5;
  double hydrationLevel = 5;
  double screenTime = 4;
  double moodLevel = 5;

  String predictionResult = "";
  bool isLoading = false;

  final Color _primaryColor = const Color(0xFF4A6FA5);
  final Color _accentColor = const Color(0xFF7B61FF);

  final Color _textColor = const Color(0xFF1E2A38);
  final Color _subtitleColor = const Color(0xFF6B7C93);

  final Color _backgroundColor = const Color.fromARGB(255, 3, 33, 78);
  final Color _cardColor = const Color(0xFFDADFE6);

  Future<void> predictMigraine() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://web-production-bdd01.up.railway.app/predict'),
        headers: {'Content-Type': 'application/json'},

        body: jsonEncode({
          'sleep_hours': sleepHours,
          'stress_level': stressLevel,
          'hydration_level': hydrationLevel,
          'screen_time': screenTime,
          'mood_level': moodLevel,
        }),
      );

      final data = jsonDecode(response.body);

debugPrint(data.toString());
int severity = (data['severity'] as num?)?.toInt() ?? 0;

setState(() {
  if (severity == 0) {
    predictionResult = "✅ Low Migraine Risk";
  } else if (severity == 1) {
    predictionResult = "⚠ Moderate Migraine Risk";
  } else {
    predictionResult = "🚨 High Migraine Risk";
  }

  isLoading = false;
});
    } catch (e) {
      setState(() {
        predictionResult = "Error: $e";
        isLoading = false;
      });
    }
  }

  Widget buildSlider(
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w600),
            ),

            Text(
              value.toStringAsFixed(1),
              style: TextStyle(color: _subtitleColor),
            ),
          ],
        ),

        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: _accentColor,
          onChanged: onChanged,
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,

      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: const Text(
          "AI Migraine Prediction",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Prediction Analysis",
              style: TextStyle(
                color: _cardColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "AI-based migraine risk assessment",
              style: TextStyle(color: _subtitleColor, fontSize: 16),
            ),

            const SizedBox(height: 24),

            // Top Banner
            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_primaryColor, _accentColor]),
                borderRadius: BorderRadius.circular(20),
              ),

              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Expanded(
                    child: Text(
                      "Adjust your health patterns below and let AI estimate your migraine risk.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Input Card
            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: [
                  buildSlider("Sleep Hours", sleepHours, 0, 12, (value) {
                    setState(() {
                      sleepHours = value;
                    });
                  }),

                  buildSlider("Stress Level", stressLevel, 0, 10, (value) {
                    setState(() {
                      stressLevel = value;
                    });
                  }),

                  buildSlider("Hydration Level", hydrationLevel, 0, 10, (
                    value,
                  ) {
                    setState(() {
                      hydrationLevel = value;
                    });
                  }),

                  buildSlider("Screen Time", screenTime, 0, 15, (value) {
                    setState(() {
                      screenTime = value;
                    });
                  }),


                  buildSlider("Mood Level", moodLevel, 0, 10, (value) {
                    setState(() {
                      moodLevel = value;
                    });
                  }),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,

                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _accentColor],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: ElevatedButton(
                        onPressed: predictMigraine,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),

                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Predict Migraine Risk",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Result Card
            if (predictionResult.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  children: [
                    Icon(
                      predictionResult.contains("High")
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      color: predictionResult.contains("High")
                          ? Colors.orange
                          : Colors.green,
                      size: 50,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      predictionResult,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
