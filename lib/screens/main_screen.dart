import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'quick_log_screen.dart';
import 'insights_screen.dart';
import 'therapy_screen.dart';
import 'profile_screen.dart';


Future<void> testFirestore() async {
  await FirebaseFirestore.instance.collection('test').add({
    'message': 'Hello Firebase',
    'time': Timestamp.now(),
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final Color _accentColor = const Color(0xFF7B61FF); // soft purple
  final Color _subtitleColor = const Color(0xFF6B7C93); // soft gray
  final Color _backgroundColor = const Color.fromARGB(
    255,
    3,
    33,
    78,
  ); // dark bg
  final Color _navBarColor = const Color(0xFF1C2A3A); // dark blue-grey

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    bool isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      label: "",
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        decoration: BoxDecoration(
          color: isSelected
              ? _accentColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),

          border: isSelected ? Border.all(color: _accentColor, width: 1) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : _subtitleColor),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : _subtitleColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(
        onTabChange: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const QuickLogScreen(),
      const InsightsScreen(),
      const TherapyScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: _navBarColor,
                  elevation: 0,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  items: [
                    _buildNavItem(Icons.home, "Home", 0),
                    _buildNavItem(Icons.add_circle, "Log", 1),
                    _buildNavItem(Icons.analytics, "Insights", 2),
                    _buildNavItem(Icons.favorite, "Therapy", 3),
                    _buildNavItem(Icons.person, "Profile", 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
