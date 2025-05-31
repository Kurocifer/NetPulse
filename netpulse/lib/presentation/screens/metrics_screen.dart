import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/network_service.dart';
import '../../data/services/location_service.dart';
import '../blocs/network_bloc.dart';
import 'dart:developer' as developer;

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  String _selectedFilter = 'All';
  bool _isSubmitting = false;

  String formatThroughput(double quality) {
    if (quality >= 1000) {
      return '${(quality / 1000).toStringAsFixed(1)} Mbps';
    }
    return '${quality.toStringAsFixed(0)} Kbps';
  }

  String formatYAxisLabel(double value, double maxQuality) {
    final isMbps = maxQuality >= 1000;
    final quality = isMbps ? value * 1000 : value;
    String label;
    if (isMbps) {
      if (value >= 1) label = 'Good';
      else if (value > 0.3) label = 'Fair';
      else label = 'Poor';
      return '${value.toStringAsFixed(1)} Mbps ($label)';
    } else {
      if (quality >= 1000) label = 'Good';
      else if (quality > 300) label = 'Fair';
      else label = 'Poor';
      return '$quality Kbps ($label)';
    }
  }

  String formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String getSignalStrength(double quality) {
    if (quality >= 1000) return 'Good';
    if (quality > 300) return 'Fair';
    return 'Poor';
  }

  String _determineIsp(String isp, String networkType) {
    final List<String> _ispPrefixes = ['MTN', 'ORANGE', 'CAMTEL'];
    if (networkType == 'Wi-Fi' || networkType == 'Offline') {
      return 'MTN';
    }
    for (var prefix in _ispPrefixes) {
      if (isp.startsWith(prefix)) {
        var ispp = isp.split(' ').first;
        print(ispp);
        return isp.split(' ').first;
      }
    }
    return 'MTN';
  }

  Future<void> _submitMetrics() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated.');
      }

      final queryEmail = (user.email ?? '').trim();
      developer.log('Auth User Email (trimmed): "$queryEmail"');

      final response = await Supabase.instance.client
          .from('Users')
          .select('UserID')
          .ilike('Email', queryEmail)
          .limit(1);
      developer.log('Users table query response: $response');

      if (response.isEmpty) {
        final allUsers = await Supabase.instance.client.from('Users').select('Emails');
        developer.log('All emails in Users table: $allUsers');
        throw Exception('User not found in Users table with email: "$queryEmail"');
      }

      final userRow = response.first;
      final userIdFromUsersTable = userRow['UserID'];
      if (userIdFromUsersTable == null) {
        throw Exception('User ID is null in Users table for email: "$queryEmail"');
      }
      if (userIdFromUsersTable is! String) {
        throw Exception('User ID is not a string: $userIdFromUsersTable');
      }

      developer.log('User ID from Users table: "$userIdFromUsersTable"');

      final networkService = context.read<NetworkService>();
      final loggedStates = await networkService.getLoggedNetworkStates();
      if (loggedStates.isEmpty) {
        throw Exception('No network state available.');
      }
      final latestState = loggedStates.last;
      final networkType = latestState['networkType'] as String;
      final quality = (latestState['quality'] as num? ?? 0).toDouble();
      final isp = latestState['isp'] as String;
      final latency = latestState['latency'] as String? ?? 'N/A';
      final packetLoss = latestState['packetLoss'] as String? ?? 'N/A';

      // Fetch location from LocationService
      final locationService = context.read<LocationService>();
      final position = await locationService.getCurrentLocation();
      final latitude = position?.latitude;
      final longitude = position?.longitude;

      // Log location access status
      developer.log('Location data - Latitude: $latitude, Longitude: $longitude');
      if (latitude == null || longitude == null) {
        developer.log('Location unavailable: Check permissions or GPS status.');
      }

      final signalStrength = getSignalStrength(quality);
      final throughput = quality;
      final ispToSend = _determineIsp(isp, networkType);

      await Supabase.instance.client.from('NetworkMetrics').insert({
        'UserID': userIdFromUsersTable,
        'SignalStrength': signalStrength,
        'Latency': latency,
        'PacketLoss': packetLoss,
        'ISP': ispToSend,
        'Latitude': latitude,
        'Longitude': longitude,
        'Throughput': throughput,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metrics submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting metrics: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NetworkBloc(context.read<NetworkService>()),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network Metrics',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: context.read<NetworkService>().getLoggedNetworkStates(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No data available.');
                    }
                    final loggedStates = snapshot.data!;
                    final timestamps = loggedStates
                        .map((state) => DateTime.parse(state['timestamp'] as String))
                        .toList();
                    final earliestTime = timestamps.reduce((a, b) => a.isBefore(b) ? a : b);
                    final latestTime = timestamps.reduce((a, b) => a.isAfter(b) ? a : b);
                    return Text(
                      'From ${formatTime(earliestTime)} ${earliestTime.day} May to ${formatTime(latestTime)} ${latestTime.day} May',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                    );
                  },
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: context.read<NetworkService>().getLoggedNetworkStates(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final loggedStates = snapshot.data!;
                    final latestState = loggedStates.last;
                    final networkType = latestState['networkType'] as String;
                    final quality = (latestState['quality'] as num? ?? 0).toDouble();
                    final latency = latestState['latency'] as String? ?? 'N/A';
                    final packetLoss = latestState['packetLoss'] as String? ?? 'N/A';

                    return Column(
                      children: [
                        _buildMetricCard(
                          icon: Icons.signal_cellular_alt,
                          title: 'Signal Strength',
                          value: getSignalStrength(quality),
                          color: Colors.red[200],
                        ),
                        const SizedBox(height: 10),
                        _buildMetricCard(
                          icon: Icons.access_time,
                          title: 'Latency',
                          value: latency,
                          color: Colors.blue[100],
                        ),
                        const SizedBox(height: 10),
                        _buildMetricCard(
                          icon: Icons.cloud,
                          title: 'Packet Loss',
                          value: packetLoss,
                          color: Colors.green[100],
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: context.read<NetworkService>().getLoggedNetworkStates(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final loggedStates = snapshot.data!;
                    final qualities = loggedStates
                        .map((state) => (state['quality'] as num? ?? 0).toDouble())
                        .toList();
                    final avgQuality = qualities.reduce((a, b) => a + b) / qualities.length;
                    final maxQuality = qualities.reduce((a, b) => a > b ? a : b);
                    final minQuality = qualities.where((q) => q > 0).reduce((a, b) => a < b ? a : b);
                    final uptime = (loggedStates.where((state) => state['networkType'] != 'Offline').length / loggedStates.length * 100).toStringAsFixed(1);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryCard('Avg Throughput', formatThroughput(avgQuality)),
                        _buildSummaryCard('Max Throughput', formatThroughput(maxQuality)),
                        _buildSummaryCard('Min Throughput', formatThroughput(minQuality)),
                        _buildSummaryCard('Uptime', '$uptime%'),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitMetrics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit Metrics',
                            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildFilterOptions(),
                const SizedBox(height: 10),
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
                        child: const Text('No data available for graph.'),
                      );
                    }

                    final loggedStates = snapshot.data!;
                    final filteredStates = _selectedFilter == 'All'
                        ? loggedStates
                        : loggedStates.where((state) => state['networkType'] == _selectedFilter).toList();

                    if (filteredStates.isEmpty) {
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
                        child: const Text('No data available for the selected network type.'),
                      );
                    }

                    // Ensure we have at least 2 data points to avoid interval issues
                    if (filteredStates.length < 2) {
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
                        child: const Text('Not enough data to display the graph (minimum 2 data points required).'),
                      );
                    }

                    List<FlSpot> wifiSpots = [];
                    List<FlSpot> mobileSpots = [];
                    List<FlSpot> offlineSpots = [];
                    List<DateTime> timestamps = [];

                    for (int i = 0; i < filteredStates.length; i++) {
                      final state = filteredStates[i];
                      final quality = (state['quality'] as num? ?? 0).toDouble();
                      final timestamp = DateTime.parse(state['timestamp'] as String);
                      timestamps.add(timestamp);

                      switch (state['networkType']) {
                        case 'Wi-Fi':
                          wifiSpots.add(FlSpot(i.toDouble(), quality));
                          break;
                        case 'Mobile':
                          mobileSpots.add(FlSpot(i.toDouble(), quality));
                          break;
                        default:
                          offlineSpots.add(FlSpot(i.toDouble(), quality));
                          break;
                      }
                    }

                    final minQuality = filteredStates
                        .map((state) => (state['quality'] as num? ?? 0).toDouble())
                        .reduce((a, b) => a < b ? a : b);
                    final maxQuality = filteredStates
                        .map((state) => (state['quality'] as num? ?? 0).toDouble())
                        .reduce((a, b) => a > b ? a : b);
                    final yRange = maxQuality - minQuality;

                    const desiredLabelCount = 6;
                    final rawInterval = yRange == 0 ? 50.0 : yRange / (desiredLabelCount - 1); // Prevent zero yRange
                    final yInterval = max(rawInterval, 50.0);

                    final roundedMinQuality = ((minQuality / 50).floor() * 50).toDouble();
                    final roundedMaxQuality = (((maxQuality + 50) / 50).ceil() * 50).toDouble();
                    final isMbps = maxQuality >= 1000;

                    // Ensure bottom interval is never zero
                    final bottomInterval = (filteredStates.length - 1) / 4 == 0 ? 1.0 : (filteredStates.length - 1) / 4;

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
                            'Throughput Over Time',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 350,
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
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: Text(
                                              formatYAxisLabel(value, maxQuality),
                                              style: GoogleFonts.poppins(fontSize: 9),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles()),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles()),
                                ),
                                borderData: FlBorderData(show: true),
                                minX: 0,
                                maxX: (filteredStates.length - 1).toDouble(),
                                minY: roundedMinQuality < 0 ? 0 : roundedMinQuality,
                                maxY: roundedMaxQuality,
                                lineBarsData: [
                                  if (_selectedFilter == 'All' || _selectedFilter == 'Wi-Fi')
                                    LineChartBarData(
                                      spots: wifiSpots,
                                      isCurved: true,
                                      color: Colors.blue,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.blue.withOpacity(0.1),
                                      ),
                                    ),
                                  if (_selectedFilter == 'All' || _selectedFilter == 'Mobile')
                                    LineChartBarData(
                                      spots: mobileSpots,
                                      isCurved: true,
                                      color: Colors.green,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.green.withOpacity(0.1),
                                      ),
                                    ),
                                  if (_selectedFilter == 'All' || _selectedFilter == 'Offline')
                                    LineChartBarData(
                                      spots: offlineSpots,
                                      isCurved: true,
                                      color: Colors.red,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.red.withOpacity(0.1),
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
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: context.read<NetworkService>().getLoggedNetworkStates(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final loggedStates = snapshot.data!;
                    final wifiStates = loggedStates.where((state) => state['networkType'] == 'Wi-Fi').toList();
                    final mobileStates = loggedStates.where((state) => state['networkType'] == 'Mobile').toList();
                    final offlineCount = loggedStates.where((state) => state['networkType'] == 'Offline').length;
                    String insight = '';

                    if (wifiStates.isNotEmpty) {
                      final maxWifi = wifiStates.reduce((a, b) => (a['quality'] as num) > (b['quality'] as num) ? a : b);
                      final maxWifiTime = DateTime.parse(maxWifi['timestamp'] as String);
                      insight += 'Wi-Fi peaked at ${formatThroughput((maxWifi['quality'] as num).toDouble())} on ${formatTime(maxWifiTime)}.\n';
                    }
                    if (mobileStates.isNotEmpty) {
                      final poorMobileCount = mobileStates.where((state) => (state['quality'] as num) < 300).length;
                      if (poorMobileCount > 0) {
                        insight += 'Mobile data dropped below 300 Kbps $poorMobileCount times—check your signal strength.';
                      }
                    }
                    if (offlineCount > 5) {
                      insight += '\nYour network was offline $offlineCount times. Consider checking your connection stability.';
                    }

                    if (insight.isEmpty) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.teal[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Insights:\n$insight',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.teal[900],
                        ),
                      ),
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

  Widget _buildMetricCard({required IconData icon, required String title, required String value, required Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.black54),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filter by Network Type:',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
          DropdownButton<String>(
            value: _selectedFilter,
            items: ['All', 'Wi-Fi', 'Mobile', 'Offline']
                .map((type) => DropdownMenuItem(value: type, child: Text(type, style: GoogleFonts.poppins())))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!; // Fixed variable name from _submitMetrics to _selectedFilter
              });
            },
          ),
        ],
      ),
    );
  }
}