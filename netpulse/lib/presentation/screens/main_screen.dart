import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netpulse/presentation/screens/home_screen.dart';
import 'package:netpulse/presentation/screens/metrics_screen.dart';
import 'package:netpulse/presentation/screens/feedback_screen.dart';
import 'package:netpulse/presentation/screens/settings_screen.dart';
import 'package:netpulse/main.dart';

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;


    // final LinearGradient commonAppBarAndNavBarGradient = LinearGradient(
    //   begin: Alignment.topLeft,
    //   end: Alignment.bottomRight,
    //   colors: isDarkMode
    //       ? [colorScheme.surface, primaryColor.withOpacity(0.5)]
    //       : [colorScheme.surface, secondaryColor.withOpacity(0.05)],
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ['Home', 'Metrics', 'Feedback', 'Settings'][_selectedIndex],
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : primaryColor, 
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 1,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            // gradient: commonAppBarAndNavBarGradient,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(0),
            ),
          ),
        ),
      ),
      body: Container(
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //     colors: isDarkMode
        //         ? [colorScheme.background, primaryColor.withOpacity(0.7)]
        //         : [colorScheme.background, secondaryColor.withOpacity(0.3)],
        //   ),
        // ),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // gradient: commonAppBarAndNavBarGradient,
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.2),
          //     spreadRadius: 0,
          //     blurRadius: 10,
          //     offset: const Offset(0, -2),
          //   ),
          // ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_rounded, 'Home'),
              _buildNavItem(context, 1, Icons.bar_chart_rounded, 'Metrics'),
              _buildNavItem(context, 2, Icons.feedback_rounded, 'Feedback'),
              _buildNavItem(context, 3, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    // final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isSelected = _selectedIndex == index;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          height: 70,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? secondaryColor.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  icon,
                  size: isSelected ? 28 : 24,
                  color: isSelected
                      ? secondaryColor
                      : isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : primaryColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSelected ? 12 : 10,
                  color: isSelected
                      ? secondaryColor
                      : isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : primaryColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
