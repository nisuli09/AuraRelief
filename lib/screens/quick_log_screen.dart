import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuickLogScreen extends StatefulWidget {
  const QuickLogScreen({super.key});

  @override
  State<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends State<QuickLogScreen> {
  // Removed unused _selectedIndex

  double _painLevel = 5;
  bool _hadMigraine = true;
  double _sleepDuration = 7;
  double _stressLevel = 5;
  double _hydrationLevel = 5;
  double _screenTime = 4;
  double _moodLevel = 5;
  final Set<String> _selectedTriggers = {};
  final Set<String> _selectedMedications = {};

  final List<String> _triggers = [
    'Stress',
    'Noise',
    'Weather',
    'Lack of Sleep',
    'Screen Time',
    'Caffeine',
    'Other',
  ];

  final List<String> _medications = ['None', 'Panadol', 'Other'];

  final TextEditingController _notesController = TextEditingController();

  final TextEditingController _otherTriggerController = TextEditingController();
  final TextEditingController _otherMedicationController =
      TextEditingController();

  Future<void> saveLog() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      //  1. Save log
      await FirebaseFirestore.instance.collection('logs').add({
        'date': Timestamp.now(),
        'timestamp': FieldValue.serverTimestamp(),
        'painLevel': _hadMigraine ? _painLevel.toInt() : 0,
        'isMigraine': _hadMigraine,
        'sleepHours': _sleepDuration,
        'stressLevel': _stressLevel.toInt(),
        'hydrationLevel': _hydrationLevel.toInt(),
        'screenTime': _screenTime.toInt(),
        'moodLevel': _moodLevel.toInt(),
        'triggers': _selectedTriggers.toList(),
        'medication': _selectedMedications.toList(),
        'notes': _notesController.text,
        'userId': user.uid,
      });

      //  2. Update streak
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final doc = await userDoc.get();

      int streak = 0;
      DateTime today = DateTime.now();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        streak = data['streak'] ?? 0;

        final lastLogDate = data['lastLogDate']?.toDate();

        if (lastLogDate != null) {
          final difference = today.difference(lastLogDate).inDays;

          if (difference == 1) {
            streak += 1;
          } else if (difference > 1) {
            streak = 1;
          } else if (difference == 0) {
            // same day → do nothing
          }
        } else {
          streak = 1;
        }
      } else {
        streak = 1;
      }

      await userDoc.set({
        'streak': streak,
        'lastLogDate': Timestamp.now(),
      }, SetOptions(merge: true));

      //  3. Success message
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Log saved successfully ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

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
  final Color _cardColor = const Color(0xFFDADFE6); // light card

  final Color _sliderInactiveColor = Colors.grey.shade400;
  final Color _chipBgColor = const Color(0xFFDADFE6);

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
                'Quick Log',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _cardColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Record your daily information',
                style: TextStyle(fontSize: 16, color: _subtitleColor),
              ),
              const SizedBox(height: 24),

              // Had Migraine Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
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

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Had Migraine Today?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    Switch(
                      value: _hadMigraine,
                      onChanged: (value) {
                        setState(() {
                          _hadMigraine = value;

                          // If no migraine → reset pain
                          if (!_hadMigraine) {
                            _painLevel = 0;
                          }
                        });
                      },
                      activeThumbColor: _accentColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Pain Level
              _buildSliderCard(
                title: 'Pain Level',
                icon: Icons.error_outline,
                iconColor: _primaryColor,
                value: _painLevel,
                min: 0,
                max: 10,
                divisions: 10,
                minText: 'No pain',
                maxText: 'Severe',
                valueText: _hadMigraine
                    ? _painLevel.toInt().toString()
                    : "No Pain",
                onChanged: _hadMigraine
                    ? (val) => setState(() => _painLevel = val)
                    : null,
              ),
              const SizedBox(height: 16),

              // Sleep Duration
              _buildSliderCard(
                title: 'Sleep Duration',
                icon: Icons.dark_mode_outlined,
                iconColor: _primaryColor,
                value: _sleepDuration,
                min: 0,
                max: 12,
                divisions: 24, // half-hour increments
                minText: '0 hours',
                maxText: '12 hours',
                valueText: _sleepDuration % 1 == 0
                    ? '${_sleepDuration.toInt()}h'
                    : '${_sleepDuration.toStringAsFixed(1)}h',
                onChanged: (val) => setState(() => _sleepDuration = val),
              ),
              const SizedBox(height: 16),

              // Stress Level
              _buildSliderCard(
                title: 'Stress Level',
                icon: Icons.psychology_outlined,
                iconColor: Colors.orangeAccent.withValues(alpha: 0.8),
                value: _stressLevel,
                min: 0,
                max: 10,
                divisions: 10,
                minText: 'Relaxed',
                maxText: 'Very Stressed',
                valueText: _stressLevel.toInt().toString(),
                onChanged: (val) => setState(() => _stressLevel = val),
              ),
              const SizedBox(height: 16),

              // hydration level
              _buildSliderCard(
                title: 'Hydration Level',
                icon: Icons.water_drop_outlined,
                iconColor: Colors.blueAccent,
                value: _hydrationLevel,
                min: 0,
                max: 10,
                divisions: 10,
                minText: 'Dehydrated',
                maxText: 'Well Hydrated',
                valueText: _hydrationLevel.toInt().toString(),
                onChanged: (val) => setState(() => _hydrationLevel = val),
              ),

              const SizedBox(height: 16),

              // screen time
              _buildSliderCard(
                title: 'Screen Time',
                icon: Icons.phone_android,
                iconColor: Colors.teal,
                value: _screenTime,
                min: 0,
                max: 12,
                divisions: 12,
                minText: '0h',
                maxText: '12h',
                valueText: '${_screenTime.toInt()}h',
                onChanged: (val) => setState(() => _screenTime = val),
              ),

              const SizedBox(height: 16),

              // mood level
              _buildSliderCard(
                title: 'Mood Level',
                icon: Icons.mood,
                iconColor: Colors.pinkAccent,
                value: _moodLevel,
                min: 0,
                max: 10,
                divisions: 10,
                minText: 'Very Bad',
                maxText: 'Very Happy',
                valueText: _moodLevel.toInt().toString(),
                onChanged: (val) => setState(() => _moodLevel = val),
              ),

              const SizedBox(height: 16),

              // Triggers
              _buildChipsCard(
                title: 'Triggers',
                icon: Icons.flash_on,
                iconColor: Colors.redAccent.withValues(alpha: 0.7),
                items: _triggers,
                selectedItems: _selectedTriggers,
                controller: _otherTriggerController,
                hintText: "e.g. Loud music, perfume...",
                onSelected: (selected, item) {
                  setState(() {
                    if (selected) {
                      _selectedTriggers.add(item);
                    } else {
                      _selectedTriggers.remove(item);
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              // Medication Taken
              _buildChipsCard(
                title: 'Medication Taken',
                icon: Icons.medication_outlined,
                iconColor: _primaryColor,
                items: _medications,
                selectedItems: _selectedMedications,
                controller: _otherMedicationController,
                hintText: "e.g. Ibuprofen, Aspirin...",
                onSelected: (selected, item) {
                  setState(() {
                    if (item == 'None' && selected) {
                      _selectedMedications.clear();
                      _selectedMedications.add('None');
                    } else if (selected) {
                      _selectedMedications.remove('None');
                      _selectedMedications.add(item);
                    } else {
                      _selectedMedications.remove(item);
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              // Notes & Food Log
              Container(
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
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.restaurant_menu,
                            color: _primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Notes & Food Log',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Add any notes about food, activities, or observations...',
                        hintStyle: TextStyle(color: _cardColor, fontSize: 14),
                        filled: true,
                        fillColor: _backgroundColor.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Log Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Log',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String minText,
    required String maxText,
    required String valueText,
    ValueChanged<double>? onChanged,
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
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
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accentColor,
              inactiveTrackColor: _sliderInactiveColor,
              thumbColor: Colors.white,
              overlayColor: _primaryColor.withValues(alpha: 0.1),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10,
                elevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    minText,
                    style: TextStyle(color: _subtitleColor, fontSize: 12),
                    textAlign: TextAlign.left,
                  ),
                ),
                Text(
                  valueText,
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Expanded(
                  child: Text(
                    maxText,
                    style: TextStyle(color: _subtitleColor, fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
    required Set<String> selectedItems,
    required Function(bool, String) onSelected,
    TextEditingController? controller,
    String? hintText,
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final isSelected = selectedItems.contains(item);
              return FilterChip(
                label: Text(
                  item,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : _textColor.withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) => onSelected(selected, item),
                backgroundColor: _chipBgColor,
                selectedColor: _accentColor,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              );
            }).toList(),
          ),
          if (items.contains("Other") && selectedItems.contains("Other"))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText ?? "Enter details...",
                  filled: true,
                  fillColor: _backgroundColor.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _otherTriggerController.dispose();
    _otherMedicationController.dispose();
    super.dispose();
  }
}
