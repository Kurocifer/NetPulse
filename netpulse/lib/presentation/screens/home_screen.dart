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
    } else if (quality > 0 && quality <= 500) {
      return Icons.signal_cellular_alt_1_bar_rounded;
    } else if (quality > 500 && quality <= 2000) {
      return Icons.signal_cellular_alt_2_bar_rounded;
    } else {
      return Icons.signal_cellular_alt_rounded;
    }
  }

  double _getNiceInterval(double min, double max, int desiredCount) {
    if (min == max) return 1.0; // Handle flat line
    final range = max - min;
    final roughInterval = range / (desiredCount - 1);

    final List<double> niceIntervals = [
      1, 2, 5, 10, 20, 25, 50, 100, 200, 250, 500,
      1000, 2000, 2500, 5000, 10000, 20000, 25000, 50000, 100000
    ];

    for (var interval in niceIntervals) {
      if (interval >= roughInterval) {
        return interval;
      }
    }
    return roughInterval.ceilToDouble();
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
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //     colors: isDarkMode
        //         ? [colorScheme.background, primaryColor.withOpacity(0.7)]
        //         : [colorScheme.background, secondaryColor.withOpacity(0.3)],
        //   ),
        // ),
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
                      future: context
                          .read<NetworkService>()
                          .getLoggedNetworkStates(),
                      builder: (context, snapshot) {
                        double currentQuality = 0;
                        String currentNetworkType = state.networkType;

                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final latestState = snapshot.data!.last;
                          currentQuality = (latestState['quality'] as num? ?? 0)
                              .toDouble();
                          currentNetworkType =
                              latestState['networkType'] as String;

                          if (currentQuality == 0) {
                            statusText = 'Offline';
                            message =
                                'No active connection. Check your internet.';
                            statusColor = statusRed;
                          } else if (currentQuality > 0 &&
                              currentQuality <= 500) {
                            statusText = 'Very Poor';
                            message = 'Connection is too slow for most tasks.';
                            statusColor = statusRed;
                          } else if (currentQuality > 500 &&
                              currentQuality <= 2000) {
                            statusText = 'Poor Connection';
                            message =
                                'Limited throughput. Expect slow loading.';
                            statusColor = statusOrange;
                          } else if (currentQuality > 2000 &&
                              currentQuality <= 10000) {
                            statusText = 'Average Connection';
                            message =
                                'Suitable for basic Browse and SD streaming.';
                            statusColor = colorScheme.primary;
                          } else if (currentQuality > 10000 &&
                              currentQuality <= 25000) {
                            statusText = 'Good Connection';
                            message =
                                'Solid performance for HD streaming and general use.';
                            statusColor = statusGreen.withOpacity(
                              0.7,
                            );
                          } else {
                            statusText = 'Excellent Connection';
                            message =
                                'Your network is performing perfectly for high-bandwidth tasks.';
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
                            statusColor = colorScheme.onBackground.withOpacity(
                              0.5,
                            );
                          }
                        }

                        networkIcon = _getNetworkBarIcon(
                          currentQuality,
                          currentNetworkType,
                        );

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
                                color: colorScheme.onBackground.withOpacity(
                                  0.7,
                                ),
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
                  future: context
                      .read<NetworkService>()
                      .getLoggedNetworkStates(),
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
                    if (loggedStates.isEmpty) {
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


                    for (int i = 0; i < loggedStates.length; i++) {
                      final state = loggedStates[i];
                      final quality = (state['quality'] as num? ?? 0)
                          .toDouble();
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

                    double minQuality = spots.map((spot) => spot.y).reduce(min);
                    double maxQuality = spots.map((spot) => spot.y).reduce(max);

                    if (minQuality < 0) minQuality = 0;
                    if (maxQuality == minQuality) maxQuality = minQuality + 1.0;

                    const desiredYLabelCount = 5;
                    final yInterval = _getNiceInterval(minQuality, maxQuality, desiredYLabelCount);

                    double calculatedMinY = (minQuality / yInterval).floor() * yInterval;
                    if (calculatedMinY < 0) calculatedMinY = 0;

                    double calculatedMaxY = (maxQuality / yInterval).ceil() * yInterval;
                    if (calculatedMaxY <= calculatedMinY) calculatedMaxY = calculatedMinY + yInterval;

                    if (calculatedMaxY - calculatedMinY < yInterval) {
                       if (calculatedMinY == 0 && calculatedMaxY == 0) {
                          calculatedMaxY = yInterval * (desiredYLabelCount - 1);
                          if (calculatedMaxY == 0) calculatedMaxY = 1000.0;
                       } else if (calculatedMinY == calculatedMaxY) {
                           calculatedMaxY += yInterval;
                       }
                    }

                    final int numberOfDataPoints = spots.length;
                    const int desiredXLabelCount = 4;

                    double bottomInterval;
                    if (numberOfDataPoints <= 1) {
                      bottomInterval = 1.0;
                    } else {
                      bottomInterval = (numberOfDataPoints - 1) / (desiredXLabelCount - 1).clamp(1, desiredXLabelCount);
                      if (bottomInterval < 1.0) bottomInterval = 1.0;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Latest: ${formatThroughput(spots.isNotEmpty ? spots.last.y : 0.0)}', 
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
                                color: colorScheme.onBackground.withOpacity(
                                  0.7,
                                ),
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
                                  color: colorScheme.onBackground.withOpacity(
                                    0.1,
                                  ),
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
                                      if (spots.isEmpty) { 
                                        return SideTitleWidget(
                                          axisSide: AxisSide.bottom,
                                          child: Text(
                                            '',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: colorScheme.onBackground
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        );
                                      }
                                      final index = value.toInt().clamp(0, timestamps.length - 1);
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          formatTime(timestamps[index]),
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: colorScheme.onBackground
                                                .withOpacity(0.7),
                                          ),
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
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: colorScheme.onBackground
                                                .withOpacity(0.7),
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (spots.length > 0)
                                  ? (spots.length - 1).toDouble()
                                  : 0,
                              minY: calculatedMinY,
                              maxY: calculatedMaxY,
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
                          context.read<NetworkBloc>().add(
                            NetworkStatusRequested(),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Refreshing network status...',
                                style: GoogleFonts.poppins(
                                  color: colorScheme.onPrimary,
                                ),
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
                  future: context
                      .read<NetworkService>()
                      .getLoggedNetworkStates(),
                  builder: (context, snapshot) {
                    String tipMessage =
                        'No network data available. Ensure the app has permissions to monitor your network.';
                    IconData tipIcon = Icons.info_outline_rounded;
                    Color tipIconColor = colorScheme.onBackground.withOpacity(
                      0.7,
                    );

                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      final latestState = snapshot.data!.last;
                      final quality = (latestState['quality'] as num? ?? 0)
                          .toDouble();

                      if (quality == 0) {
                        tipMessage =
                            'Your device is currently offline. Check your Wi-Fi or mobile data settings.';
                        tipIcon = Icons.signal_wifi_off_rounded;
                        tipIconColor = statusRed;
                      } else if (quality <= 500) {
                        tipMessage =
                            'Experiencing very poor signal? Try moving to a better location or checking provider coverage.';
                        tipIcon = Icons.lightbulb_outline_rounded;
                        tipIconColor = statusRed;
                      } else if (quality <= 2000) {
                        tipMessage =
                            'Your connection is limited. Consider closing background apps for a smoother experience.';
                        tipIcon = Icons.info_outline_rounded;
                        tipIconColor = statusOrange;
                      } else if (quality <= 10000) {
                        tipMessage =
                            'Your connection is average. Optimize by ensuring no large downloads are running.';
                        tipIcon = Icons.tune_rounded;
                        tipIconColor = colorScheme.primary;
                      } else if (quality <= 25000) {
                        tipMessage =
                            'Good connection! Enjoy reliable HD streaming and general use.';
                        tipIcon = Icons.check_circle_outline_rounded;
                        tipIconColor = statusGreen.withOpacity(0.7);
                      } else {
                        tipMessage =
                            'Excellent network! You\'re all set for high-speed Browse and streaming.';
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
}