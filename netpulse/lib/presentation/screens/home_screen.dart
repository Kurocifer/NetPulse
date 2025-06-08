import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:netpulse/presentation/widgets/action_button.dart';
import '../blocs/network_bloc.dart';
import '../../data/services/network_service.dart';
import 'package:netpulse/main.dart';
import 'dart:developer' as developer;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String formatThroughput(double quality) {
    if (quality >= 1000) {
      return '${(quality / 1000).toStringAsFixed(1)} Mbps';
    }
    return '${quality.toStringAsFixed(0)} Kbps';
  }

  String formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  IconData _getNetworkBarIcon(double quality, String networkType) {
    if (networkType == 'Offline' || quality == 0) {
      return Icons.signal_cellular_off_rounded;
    } else if (quality > 0 && quality <= 300) {
      return Icons.signal_cellular_alt_1_bar_rounded;
    } else if (quality > 300 && quality <= 1000) {
      return Icons.signal_cellular_alt_2_bar_rounded;
    } else {
      return Icons.signal_cellular_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    const Color statusGreen = Color(0xFF4CAF50);
    const Color statusOrange = Color(0xFFFF9800);
    const Color statusRed = Color(0xFFF44336);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [colorScheme.background, primaryColor.withOpacity(0.7)]
                : [colorScheme.background, secondaryColor.withOpacity(0.3)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Network Pulse',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Real-time network health overview.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),

                BlocBuilder<NetworkBloc, NetworkState>(
                  builder: (context, state) {
                    String statusText = 'Good Network';
                    String message = 'Your network is performing optimally.';
                    Color statusColor = statusGreen;
                    IconData networkIcon = Icons.signal_cellular_alt_rounded;

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: context.read<NetworkService>().getLoggedNetworkStates(),
                      builder: (context, snapshot) {
                        double currentQuality = 0;
                        String currentNetworkType = state.networkType;

                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final latestState = snapshot.data!.last;
                          currentQuality = (latestState['quality'] as num? ?? 0).toDouble();
                          currentNetworkType = latestState['networkType'] as String;

                          if (currentQuality == 0) {
                            statusText = 'Offline';
                            message = 'No active connection. Check your internet.';
                            statusColor = statusRed;
                          } else if (currentQuality > 0 && currentQuality <= 300) {
                            statusText = 'Poor Connection';
                            message = 'Low throughput. Signal may be weak.';
                            statusColor = statusOrange;
                          } else if (currentQuality > 300 && currentQuality <= 1000) {
                            statusText = 'Average Connection';
                            message = 'Moderate throughput. Room for improvement.';
                            statusColor = colorScheme.primary;
                          } else {
                            statusText = 'Excellent Connection';
                            message = 'Your network is performing perfectly.';
                            statusColor = statusGreen;
                          }
                        } else {
                          if (state.networkType == 'Offline') {
                            statusText = 'Offline';
                            message = 'No active network connection.';
                            statusColor = statusRed;
                          } else {
                            statusText = 'Gathering Data';
                            message = 'Initializing network monitoring...';
                            statusColor = colorScheme.onBackground.withOpacity(0.5);
                          }
                        }

                        networkIcon = _getNetworkBarIcon(currentQuality, currentNetworkType);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Icon(
                                networkIcon,
                                size: 60,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                statusText,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: colorScheme.onBackground.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ISP: ${state.isp}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onBackground,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),

                Text(
                  'Throughput Trend',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: context.read<NetworkService>().getLoggedNetworkStates(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart_rounded,
                            size: 60,
                            color: colorScheme.onBackground.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No historical data available yet.\nStart monitoring to see trends.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                        ],
                      );
                    }

                    final loggedStates = snapshot.data!;
                    List<FlSpot> spots = [];
                    List<DateTime> timestamps = [];

                    for (int i = 0; i < loggedStates.length; i++) {
                      final state = loggedStates[i];
                      final quality = (state['quality'] as num? ?? 0).toDouble();
                      spots.add(FlSpot(i.toDouble(), quality));
                      final timestampStr = state['timestamp'] as String?;
                      DateTime timestamp;
                      try {
                        timestamp = timestampStr != null
                            ? DateTime.parse(timestampStr)
                            : DateTime.now();
                      } catch (e) {
                        timestamp = DateTime.now();
                        developer.log('Failed to parse timestamp: $e');
                      }
                      timestamps.add(timestamp);
                    }

                    final earliestTime = timestamps.isNotEmpty
                        ? timestamps.reduce((a, b) => a.isBefore(b) ? a : b)
                        : DateTime.now().subtract(const Duration(hours: 24));
                    final latestTime = timestamps.isNotEmpty
                        ? timestamps.reduce((a, b) => a.isAfter(b) ? a : b)
                        : DateTime.now();

                    final minQuality = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
                    final maxQuality = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
                    final yRange = maxQuality - minQuality;

                    const desiredLabelCount = 5;
                    final rawInterval = yRange / (desiredLabelCount - 1);
                    final yInterval = max(rawInterval, 50.0);

                    final roundedMinQuality = (minQuality - 50).floorToDouble();
                    final roundedMaxQuality = (maxQuality + 50).ceilToDouble();

                    double bottomInterval = (spots.length > 1)
                        ? (spots.length - 1) / 4
                        : 1.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Latest: ${formatThroughput(maxQuality)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            Text(
                              '${formatTime(earliestTime)} - ${formatTime(latestTime)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: colorScheme.onBackground.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 250,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: yInterval,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: colorScheme.onBackground.withOpacity(0.1),
                                  strokeWidth: 0.5,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: bottomInterval,
                                    getTitlesWidget: (value, meta) {
                                      if (spots.length <= 1) {
                                        return SideTitleWidget(
                                          axisSide: AxisSide.bottom,
                                          child: Text(
                                            'N/A',
                                            style: GoogleFonts.poppins(fontSize: 10, color: colorScheme.onBackground.withOpacity(0.7)),
                                          ),
                                        );
                                      }
                                      final index = value.toInt().clamp(0, timestamps.length - 1);
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          formatTime(timestamps[index]),
                                          style: GoogleFonts.poppins(fontSize: 10, color: colorScheme.onBackground.withOpacity(0.7)),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    interval: yInterval,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          formatThroughput(value),
                                          style: GoogleFonts.poppins(fontSize: 10, color: colorScheme.onBackground.withOpacity(0.7)),
                                          textAlign: TextAlign.right,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (spots.length > 0) ? (spots.length - 1).toDouble() : 0,
                              minY: roundedMinQuality < 0 ? 0 : roundedMinQuality,
                              maxY: roundedMaxQuality,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: secondaryColor,
                                  barWidth: 2,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        secondaryColor.withOpacity(0.15),
                                        secondaryColor.withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),

                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: BuildActionButton(
                        context: context,
                        label: 'Refresh Status',
                        icon: Icons.refresh_rounded,
                        onPressed: () {
                          context.read<NetworkBloc>().add(NetworkStatusRequested());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Refreshing network status...',
                                style: GoogleFonts.poppins(color: colorScheme.onPrimary),
                              ),
                              backgroundColor: secondaryColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        },
                        buttonGradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        textColor: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Tip Section
                Text(
                  'Insights & Tips',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: context.read<NetworkService>().getLoggedNetworkStates(),
                  builder: (context, snapshot) {
                    String tipMessage = 'No network data available. Ensure the app has permissions to monitor your network.';
                    IconData tipIcon = Icons.info_outline_rounded;
                    Color tipIconColor = colorScheme.onBackground.withOpacity(0.7);

                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      final latestState = snapshot.data!.last;
                      final quality = (latestState['quality'] as num? ?? 0).toDouble();

                      if (quality == 0) {
                        tipMessage = 'Your device is currently offline. Check your Wi-Fi or mobile data settings.';
                        tipIcon = Icons.signal_wifi_off_rounded;
                        tipIconColor = statusRed;
                      } else if (quality <= 300) {
                        tipMessage = 'Experiencing poor signal? Try moving to a better location for improved throughput.';
                        tipIcon = Icons.lightbulb_outline_rounded;
                        tipIconColor = statusOrange;
                      } else if (quality <= 1000) {
                        tipMessage = 'Your connection is average. Consider closing background apps for a smoother experience.';
                        tipIcon = Icons.tune_rounded;
                        tipIconColor = colorScheme.primary;
                      } else {
                        tipMessage = 'Excellent network! You\'re all set for high-speed Browse and streaming.';
                        tipIcon = Icons.check_circle_outline_rounded;
                        tipIconColor = statusGreen;
                      }
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(tipIcon, color: tipIconColor, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            tipMessage,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: colorScheme.onBackground.withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildActionButton({
  //   required BuildContext context,
  //   required String label,
  //   required IconData icon,
  //   required VoidCallback? onPressed,
  //   LinearGradient? buttonGradient,
  //   required Color textColor,
  // }) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: buttonGradient,
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: ElevatedButton(
  //       onPressed: onPressed,
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.transparent,
  //         foregroundColor: textColor,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         padding: EdgeInsets.zero,
  //         elevation: 0,
  //         shadowColor: Colors.transparent,
  //       ),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(icon, size: 28),
  //             const SizedBox(width: 8),
  //             Expanded(
  //               child: Text(
  //                 label,
  //                 textAlign: TextAlign.center,
  //                 overflow: TextOverflow.ellipsis,
  //                 maxLines: 1,
  //                 style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
