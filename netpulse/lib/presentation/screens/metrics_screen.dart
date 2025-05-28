import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Network Metrics',
            style: GoogleFonts.poppins(fontSize: 24, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          Text(
            'Detailed metrics like speed, latency, and data usage will be shown here.',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}