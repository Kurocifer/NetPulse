import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netpulse/presentation/screens/home_screen.dart';
import 'package:netpulse/presentation/screens/metrics_screen.dart';
import 'package:netpulse/presentation/screens/feedback_screen.dart';
import 'package:netpulse/presentation/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    MetricsScreen(),
    FeedbackScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ['Home', 'Metrics', 'Feedback', 'Settings'][_selectedIndex],
          style: GoogleFonts.poppins(fontSize: 24, color: Colors.white),
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28), // Larger icon
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart, size: 28), // Larger icon
            label: 'Metrics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback, size: 28), // Larger icon
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 28), // Larger icon
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white, // Background color for contrast
        elevation: 10, // Shadow for depth
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
        ),
        iconSize: 28, // Ensure consistency
        selectedIconTheme: const IconThemeData(size: 32), // Slightly larger when selected
        unselectedIconTheme: const IconThemeData(size: 28),
        showUnselectedLabels: true,
        selectedFontSize: 14,
        unselectedFontSize: 12,
      ),
    );
  }
}