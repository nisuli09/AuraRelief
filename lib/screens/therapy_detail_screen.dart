import 'package:flutter/material.dart';

class TherapyDetailScreen extends StatelessWidget {
  final String title;
  final String description;

  const TherapyDetailScreen({
    super.key,
    required this.title,
    required this.description,
  });

  final Color _primaryColor = const Color(0xFF4A6FA5);
  final Color _accentColor = const Color(0xFF7B61FF);

  final Color _backgroundColor = const Color.fromARGB(255, 3, 33, 78);
  final Color _cardColor = const Color(0xFFDADFE6);

  final Color _textColor = const Color(0xFF1E2A38);
  final Color _subtitleColor = const Color(0xFF6B7C93);

  String getInstructions(String title) {
    if (title.contains("Breathing")) {
      return "Inhale slowly for 4 seconds.\nHold for 4 seconds.\nExhale for 6 seconds.\nRepeat for 5 minutes.";
    } else if (title.contains("Meditation")) {
      return "Sit comfortably.\nClose your eyes.\nFocus on your breath.\nLet thoughts pass without reacting.";
    } else if (title.contains("Hydration")) {
      return "Drink a glass of water.\nRest in a calm place.\nAvoid bright lights.\nStay hydrated.";
    } else if (title.contains("Stress")) {
      return "Sit in a dark quiet room.\nAvoid screens.\nRelax your body.\nTake slow breaths.";
    } else {
      return "Relax your body and take a short break.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_primaryColor, _accentColor]),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),

                Icon(Icons.self_improvement, size: 100, color: _accentColor),

                const SizedBox(height: 24),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: _subtitleColor),
                ),

                const SizedBox(height: 40),

                Text(
                  getInstructions(title),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: _textColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
