import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import '../services/report_service.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'User';
  String _userEmail = '';

  String? _photoUrl;

  int _daysTracked = 0;
  int _totalLogs = 0;
  int _currentStreak = 0;
  bool _isLoading = true;
  TimeOfDay? _selectedTime;

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Privacy Policy"),
          content: SingleChildScrollView(
            child: Text("""
AuraRelief Privacy Policy

We value your privacy.

• Your migraine logs are securely stored using Firebase.
• We do not share your personal data with third parties.
• Your data is used only to provide insights and improve your experience.
• You can delete your data anytime by removing your account.

This app is designed for educational purposes and does not replace medical advice.
            """, style: TextStyle(fontSize: 13)),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _pickTime() async {
  TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (picked != null) {
    setState(() {
      _selectedTime = picked;
    });

    // Schedule notification
    await NotificationService.scheduleDailyReminder(
      hour: picked.hour,
      minute: picked.minute,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Daily reminder set for ${picked.format(context)}",
        ),
      ),
    );
  }
}

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (mounted) {
          setState(() {
            _userEmail = user.email ?? '';
          });
        }

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        int streak = 0;
        int daysTracked = 0;

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          streak = data['streak'] ?? 0;

          if (data['createdAt'] != null) {
            final createdAt = (data['createdAt'] as Timestamp).toDate();
            // Calculate days tracked from account creation
            daysTracked = DateTime.now().difference(createdAt).inDays + 1;
          }
          if (mounted) {
            setState(() {
              _userName = data['name'] ?? 'User';
              _photoUrl = data['photoUrl'];
              _currentStreak = streak;
              _daysTracked = daysTracked;
            });
          }
        }

        // Fetch logs count
        final logsQuery = await FirebaseFirestore.instance
            .collection('logs')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (mounted) {
          setState(() {
            _totalLogs = logsQuery.docs.length;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching profile data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // MATCH Dashboard Theme
  final Color _primaryColor = const Color(0xFF4A6FA5); // calm blue
  final Color _accentColor = const Color(0xFF7B61FF); // soft purple

  final Color _textColor = const Color(0xFF1E2A38);
  final Color _subtitleColor = const Color(0xFF6B7C93);

  final Color _backgroundColor = const Color.fromARGB(255, 3, 33, 78);
  final Color _cardColor = const Color(0xFFDADFE6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _primaryColor))
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
                      'Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _cardColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your account',
                      style: TextStyle(fontSize: 16, color: _subtitleColor),
                    ),
                    const SizedBox(height: 24),

                    // Profile Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.03),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryColor, _accentColor],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _photoUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _photoUrl!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Text(
                                    _userName.isNotEmpty
                                        ? _userName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userEmail.isNotEmpty
                                      ? _userEmail
                                      : 'No Email',
                                  style: TextStyle(
                                    color: _subtitleColor,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const EditProfileScreen(),
                                      ),
                                    );

                                    if (result == true) {
                                      _loadUserData(); // refresh after editing
                                    }
                                  },
                                  child: Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: _accentColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.calendar_today_outlined,
                            iconColor: _accentColor,
                            value: _daysTracked.toString(),
                            label: 'Days Tracked',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.monitor_heart_outlined,
                            iconColor: _accentColor,
                            value: _totalLogs.toString(),
                            label: 'Total Logs',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.military_tech_outlined,
                            iconColor: const Color(0xFFE5B567),
                            value: '$_currentStreak days',
                            label: 'Current Streak',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Settings Header
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _cardColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ⏰ Reminder Time Card
                    Container(
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
                      child: ListTile(
                        leading: Icon(Icons.access_time, color: _accentColor),
                        title: Text(
                          "Reminder Time",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        subtitle: Text(
                          _selectedTime == null
                              ? "Set daily log reminder"
                              : "Reminder at ${_selectedTime!.format(context)}",
                          style: TextStyle(color: _subtitleColor, fontSize: 12),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _pickTime,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 📄 Download Report Card
                    Container(
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
                      child: ListTile(
                        leading: Icon(
                          Icons.picture_as_pdf,
                          color: _accentColor,
                        ),
                        title: Text(
                          "Download Report",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        subtitle: Text(
                          "Export your migraine history",
                          style: TextStyle(color: _subtitleColor, fontSize: 12),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final selectedDays = await showModalBottomSheet<int>(
                            context: context,
                            builder: (context) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Select Report Range",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    ListTile(
                                      leading: Icon(Icons.calendar_view_week),
                                      title: Text("Last 7 Days"),
                                      onTap: () => Navigator.pop(context, 7),
                                    ),

                                    ListTile(
                                      leading: Icon(Icons.calendar_today),
                                      title: Text("Last 30 Days"),
                                      onTap: () => Navigator.pop(context, 30),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );

                          if (selectedDays == null) return;

                          // 🔄 Loading
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: _primaryColor,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Generating report...",
                                      style: TextStyle(
                                        color: _textColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          try {
                            await ReportService.generateMigraineReport(7);

                            if (!context.mounted) return;

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Report generated successfully"),
                              ),
                            );
                          } catch (e) {
                            debugPrint("ERROR: $e");

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
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
                      child: ListTile(
                        leading: Icon(Icons.info_outline, color: _accentColor),
                        title: Text(
                          "About AuraRelief",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        subtitle: Text(
                          "Version 1.0",
                          style: TextStyle(color: _subtitleColor, fontSize: 12),
                        ),

                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: "AuraRelief",
                            applicationVersion: "1.0",
                            applicationLegalese:
                                "© 2026 AuraRelief\nAI-powered migraine tracking system",
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
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
                      child: ListTile(
                        leading: Icon(
                          Icons.privacy_tip_outlined,
                          color: _accentColor,
                        ),
                        title: Text(
                          "Privacy Policy",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        subtitle: Text(
                          "How we handle your data",
                          style: TextStyle(color: _subtitleColor, fontSize: 12),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _showPrivacyPolicy();
                        },
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Log Out Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.signOut();
                          } catch (e) {
                            debugPrint("Error during logout: $e");
                          }
                          if (!context.mounted) return;
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: Icon(
                          Icons.logout,
                          color: Colors.redAccent.shade200,
                          size: 20,
                        ),
                        label: Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.redAccent.shade200,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Colors.redAccent.shade200.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.red.shade50.withValues(
                            alpha: 0.3,
                          ),
                          elevation: 0,
                        ),
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
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: _subtitleColor, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
