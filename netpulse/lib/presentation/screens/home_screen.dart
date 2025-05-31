import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../blocs/network_bloc.dart';
import '../../data/services/network_service.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String formatThroughput(double quality) {
    if (quality >= 1000) {
      return '${(quality / 1000).toStringAsFixed(1)} Mbps';
    }
    return '${quality.toStringAsFixed(0)} Kbps';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network Status',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.lightBlue[100]!, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<NetworkBloc, NetworkState>(
                        builder: (context, state) {
                          return SizedBox(
                            height: 100,
                            child: CustomPaint(
                              painter: NetworkGraphicPainter(state.networkType),
                              child: const SizedBox.expand(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: context.read<NetworkService>().getLoggedNetworkStates(),
                        builder: (context, snapshot) {
                          String statusText = 'Good Network';
                          String message = 'Your network is performing well...';
                          Color statusColor = Colors.green;

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            final blocState = context.read<NetworkBloc>().state;
                            if (blocState.networkType == 'Offline') {
                              statusText = 'You are currently offline';
                              message = 'No network data available.';
                              statusColor = Colors.red;
                            }
                          } else {
                            final latestState = snapshot.data!.last;
                            final quality = (latestState['quality'] as num? ?? 0).toDouble();

                            if (quality == 0) {
                              statusText = 'Offline or Very Poor Network';
                              message = 'Check your connection.';
                              statusColor = Colors.red;
                            } else if (quality > 0 && quality <= 300) {
                              statusText = 'Poor Network';
                              message = 'Low throughput, consider a better signal...';
                              statusColor = Colors.orange;
                            } else if (quality > 300 && quality <= 1000) {
                              statusText = 'Average Network';
                              message = 'Moderate throughput, could improve...';
                              statusColor = Colors.amber;
                            } else {
                              statusText = 'Good Network';
                              message = 'Your network is performing well...';
                              statusColor = Colors.green;
                            }
                          }

                          return BlocBuilder<NetworkBloc, NetworkState>(
                            builder: (context, state) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statusText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    message,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'ISP: ${state.isp}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: context.read<NetworkService>().getLoggedNetworkStates(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Throughput Trend',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No data available yet.',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
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
                        print('Failed to parse timestamp: $e');
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
                    final isMbps = maxQuality >= 1000;

                    String formatTime(DateTime time) {
                      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
                      final period = time.hour >= 12 ? 'PM' : 'AM';
                      return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
                    }

                    double bottomInterval = (spots.length > 1)
                        ? (spots.length - 1) / 4
                        : 1.0;

                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Network Overview',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${formatThroughput(minQuality)} to ${formatThroughput(maxQuality)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'From ${formatTime(earliestTime)} to ${formatTime(latestTime)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 250,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 50,
                                      interval: bottomInterval,
                                      getTitlesWidget: (value, meta) {
                                        if (spots.length <= 1) {
                                          return const SideTitleWidget(
                                            axisSide: AxisSide.bottom,
                                            child: Text('No Data',
                                                style: TextStyle(fontSize: 12)),
                                          );
                                        }
                                        final index = value.toInt().clamp(0, timestamps.length - 1);
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              formatTime(timestamps[index]),
                                              style: GoogleFonts.poppins(fontSize: 10),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 80,
                                      interval: yInterval,
                                      getTitlesWidget: (value, meta) {
                                        final quality = value.toInt();
                                        String label;
                                        if (isMbps) {
                                          final qualityMbps = quality / 1000;
                                          if (qualityMbps >= 1) {
                                            label = 'Good';
                                          } else if (qualityMbps > 0.3) {
                                            label = 'Fair';
                                          } else {
                                            label = 'Poor';
                                          }
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Text(
                                                '${(quality / 1000).toStringAsFixed(1)} Mbps ($label)',
                                                style: GoogleFonts.poppins(fontSize: 9),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          );
                                        } else {
                                          if (quality >= 1000) {
                                            label = 'Good';
                                          } else if (quality > 300) {
                                            label = 'Fair';
                                          } else {
                                            label = 'Poor';
                                          }
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Text(
                                                '$quality Kbps ($label)',
                                                style: GoogleFonts.poppins(fontSize: 9),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles()),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles()),
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
                                    color: const Color(0xFF1E88E5),
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(0xFF1E88E5).withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<NetworkBloc>().add(NetworkStatusRequested());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Refreshing network status...')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          ),
                          child: Text(
                            'Refresh Status',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          ),
                          child: Text(
                            'Run Speed Test',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: () => Get.toNamed('/metrics'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          ),
                          child: Text(
                            'View History',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: context.read<NetworkService>().getLoggedNetworkStates(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Tip: No network data available, please check your connection.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.orange[900],
                          ),
                        ),
                      );
                    }

                    final latestState = snapshot.data!.last;
                    final quality = (latestState['quality'] as num? ?? 0).toDouble();

                    if (quality <= 300) {
                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Tip: Low throughput, try moving to a better signal area.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.orange[900],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
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

class NetworkGraphicPainter extends CustomPainter {
  final String networkType;

  NetworkGraphicPainter(this.networkType);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = networkType == 'Offline' ? Colors.red : const Color(0xFF1E88E5);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.1;

    if (networkType == 'Wi-Fi' || networkType == 'Mobile') {
      for (int i = 1; i <= 3; i++) {
        final arcPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = paint.color.withOpacity(1 - i * 0.3);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * i),
          3.14 / 2,
          3.14,
          false,
          arcPaint,
        );
      }
    } else {
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
      final crossPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 4;
      canvas.drawLine(
        Offset(centerX - radius * 0.7, centerY - radius * 0.7),
        Offset(centerX + radius * 0.7, centerY + radius * 0.7),
        crossPaint,
      );
      canvas.drawLine(
        Offset(centerX + radius * 0.7, centerY - 0.7),
        Offset(centerX - radius * 0.7, centerY + radius * 0.7),
        crossPaint,
      );
    }

    final patternPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), patternPaint);
    }
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), patternPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}