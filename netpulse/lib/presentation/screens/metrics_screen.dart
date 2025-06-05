import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/network_service.dart';
import '../../data/services/location_service.dart';
import '../blocs/network_bloc.dart';
import 'dart:developer' as developer;
import 'package:netpulse/main.dart';

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
        SnackBar(
          content: Text('Metrics submitted successfully!', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting metrics: $e', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Helper to get network type icon
  IconData _getNetworkTypeIcon(String networkType) {
    switch (networkType) {
      case 'Wi-Fi':
        return Icons.wifi_rounded;
      case 'Mobile':
        return Icons.signal_cellular_alt_rounded;
      case 'Offline':
        return Icons.signal_cellular_off_rounded;
      default:
        return Icons.question_mark_rounded;
    }
  }

  // Helper to build header section
  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Network Metrics',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Detailed insights into your network performance.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String value,
    required IconData icon,
    required ColorScheme colorScheme,
    bool isError = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 28, color: isError ? colorScheme.error : secondaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onBackground.withOpacity(0.8),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isError ? colorScheme.error : colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build summary item
  Widget _buildSummaryItem(String title, String value, ColorScheme colorScheme) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper to build filter options
  Widget _buildFilterOptions(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ['All', 'Wi-Fi', 'Mobile', 'Offline'].map((filter) {
        final isSelected = _selectedFilter == filter;
        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedFilter = filter;
              });
            }
          },
          selectedColor: secondaryColor,
          backgroundColor: colorScheme.surfaceVariant,
          labelStyle: GoogleFonts.poppins(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? secondaryColor : Colors.transparent),
          ),
          elevation: 0,
        );
      }).toList(),
    );
  }

  // Helper for empty chart placeholder
  Widget _buildEmptyChartPlaceholder(ColorScheme colorScheme, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.show_chart_rounded, size: 60, color: colorScheme.onBackground.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // Helper to build insights section
  Widget _buildInsightsSection(ColorScheme colorScheme, List<Map<String, dynamic>> loggedStates) {
    String insightMessage = 'No specific insights yet.';
    IconData insightIcon = Icons.info_outline_rounded;
    Color insightIconColor = colorScheme.onBackground.withOpacity(0.7);

    if (loggedStates.isNotEmpty) {
      final latestQuality = (loggedStates.last['quality'] as num? ?? 0).toDouble();
      final offlineCount = loggedStates.where((s) => s['networkType'] == 'Offline').length;
      final totalEntries = loggedStates.length;

      if (offlineCount / totalEntries > 0.5) {
        insightMessage = 'Frequent disconnections detected. Consider checking your router or mobile data plan.';
        insightIcon = Icons.wifi_off_rounded;
        insightIconColor = Colors.redAccent;
      } else if (latestQuality <= 300 && latestQuality > 0) {
        insightMessage = 'Your current connection is poor. Try moving closer to your Wi-Fi source or switching to mobile data.';
        insightIcon = Icons.lightbulb_outline_rounded;
        insightIconColor = Colors.orangeAccent;
      } else if (latestQuality > 300 && latestQuality <= 1000) {
        insightMessage = 'Your connection is average. For better performance, close background applications or optimize network settings.';
        insightIcon = Icons.tune_rounded;
        insightIconColor = colorScheme.primary;
      } else if (latestQuality > 1000) {
        insightMessage = 'Excellent network performance! Enjoy seamless browsing and streaming.';
        insightIcon = Icons.check_circle_outline_rounded;
        insightIconColor = Colors.green;
      } else {
        insightMessage = 'Network status unknown. Ensure monitoring is active.';
        insightIcon = Icons.help_outline_rounded;
        insightIconColor = colorScheme.onBackground.withOpacity(0.5);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(insightIcon, color: insightIconColor, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            insightMessage,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: colorScheme.onBackground.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Helper to build gradient action button
  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    LinearGradient? buttonGradient,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: buttonGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => NetworkBloc(context.read<NetworkService>()),
      child: Scaffold(
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: context.read<NetworkService>().getLoggedNetworkStates(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: secondaryColor),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error loading data: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: colorScheme.error, fontSize: 16),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(colorScheme),
                        _buildInfoSection(
                          title: 'No Data Available',
                          value: 'Please ensure network monitoring is active and data is being logged.',
                          icon: Icons.info_outline_rounded,
                          colorScheme: colorScheme,
                          isError: true,
                        ),
                        const SizedBox(height: 30),
                        _buildActionButton( // Use the styled button
                          context: context,
                          label: 'Submit Latest Metrics',
                          icon: Icons.send_rounded,
                          onPressed: _isSubmitting ? null : _submitMetrics,
                          buttonGradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          textColor: colorScheme.onPrimary,
                        ),
                      ],
                    ),
                  );
                }

                // Data is available, proceed with building the UI
                final loggedStates = snapshot.data!;
                final timestamps = loggedStates
                    .map((state) => DateTime.parse(state['timestamp'] as String))
                    .toList();
                final earliestTime = timestamps.reduce((a, b) => a.isBefore(b) ? a : b);
                final latestTime = timestamps.reduce((a, b) => a.isAfter(b) ? a : b);

                final latestState = loggedStates.last;
                final networkType = latestState['networkType'] as String;
                final quality = (latestState['quality'] as num? ?? 0).toDouble();
                final latency = latestState['latency'] as String? ?? 'N/A';
                final packetLoss = latestState['packetLoss'] as String? ?? 'N/A';
                // final isp = latestState['isp'] as String;

                final allQualities = loggedStates.map((state) => (state['quality'] as num? ?? 0).toDouble()).toList();
                final avgQuality = allQualities.reduce((a, b) => a + b) / allQualities.length;
                final maxQuality = allQualities.reduce((a, b) => a > b ? a : b);
                final minQuality = allQualities.where((q) => q > 0).isEmpty ? 0.0 : allQualities.where((q) => q > 0).reduce((a, b) => a < b ? a : b);
                final uptime = (loggedStates.where((state) => state['networkType'] != 'Offline').length / loggedStates.length * 100).toStringAsFixed(1);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(colorScheme),
                      const SizedBox(height: 30),

                      Text(
                        'Current Network Status',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          _buildInfoSection(
                            title: 'Network Type',
                            value: networkType,
                            icon: _getNetworkTypeIcon(networkType),
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoSection(
                            title: 'Signal Strength',
                            value: getSignalStrength(quality),
                            icon: Icons.signal_cellular_alt_rounded,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoSection(
                            title: 'Throughput',
                            value: formatThroughput(quality),
                            icon: Icons.download_rounded,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoSection(
                            title: 'Latency',
                            value: latency,
                            icon: Icons.access_time_rounded,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoSection(
                            title: 'Packet Loss',
                            value: packetLoss,
                            icon: Icons.cloud_off_rounded,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      Text(
                        'Overall Performance Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem('Avg Throughput', formatThroughput(avgQuality), colorScheme),
                          _buildSummaryItem('Max Throughput', formatThroughput(maxQuality), colorScheme),
                          _buildSummaryItem('Min Throughput', formatThroughput(minQuality), colorScheme),
                          _buildSummaryItem('Uptime', '$uptime%', colorScheme),
                        ],
                      ),
                      const SizedBox(height: 30),

                      _buildActionButton(
                        context: context,
                        label: 'Submit Network Metrics',
                        icon: Icons.send_rounded,
                        onPressed: _isSubmitting ? null : _submitMetrics,
                        buttonGradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        textColor: colorScheme.onPrimary,
                      ),
                      const SizedBox(height: 40),

                      Text(
                        'Throughput Over Time',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFilterOptions(colorScheme),
                      const SizedBox(height: 20),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: context.read<NetworkService>().getLoggedNetworkStates(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.show_chart_rounded, size: 60, color: colorScheme.onBackground.withOpacity(0.4)),
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
                          final filteredStates = _selectedFilter == 'All'
                              ? loggedStates
                              : loggedStates.where((state) => state['networkType'] == _selectedFilter).toList();

                          if (filteredStates.isEmpty) {
                            return _buildEmptyChartPlaceholder(colorScheme, 'No data available for the selected network type.');
                          }
                          if (filteredStates.length < 2) {
                             return _buildEmptyChartPlaceholder(colorScheme, 'Not enough data to display the graph (minimum 2 data points required).');
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

                            final xValue = i.toDouble();

                            switch (state['networkType']) {
                              case 'Wi-Fi':
                                wifiSpots.add(FlSpot(xValue, quality));
                                break;
                              case 'Mobile':
                                mobileSpots.add(FlSpot(xValue, quality));
                                break;
                              default:
                                offlineSpots.add(FlSpot(xValue, quality));
                                break;
                            }
                          }

                          final allQualitiesInFiltered = filteredStates.map((state) => (state['quality'] as num? ?? 0).toDouble()).toList();
                          final minQuality = allQualitiesInFiltered.reduce((a, b) => a < b ? a : b);
                          final maxQuality = allQualitiesInFiltered.reduce((a, b) => a > b ? a : b);
                          final yRange = maxQuality - minQuality;

                          const desiredLabelCount = 5;
                          final rawInterval = yRange <= 0 ? 100.0 : yRange / (desiredLabelCount - 1);
                          final yInterval = (rawInterval / 50).ceil() * 50.0;

                          final roundedMinQuality = (minQuality - 50).floorToDouble().clamp(0.0, double.infinity);
                          final roundedMaxQuality = (maxQuality + 50).ceilToDouble();

                          double bottomInterval = (filteredStates.length > 1)
                              ? (filteredStates.length - 1) / 4
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
                                            if (timestamps.length <= 1) {
                                              return SideTitleWidget(
                                                axisSide: meta.axisSide,
                                                child: Text('N/A', style: GoogleFonts.poppins(fontSize: 10, color: colorScheme.onBackground.withOpacity(0.7))),
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
                                    maxX: (filteredStates.length > 0) ? (filteredStates.length - 1).toDouble() : 0,
                                    minY: roundedMinQuality,
                                    maxY: roundedMaxQuality,
                                    lineBarsData: [
                                      if (_selectedFilter == 'All' || _selectedFilter == 'Wi-Fi')
                                        LineChartBarData(
                                          spots: wifiSpots,
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
                                      if (_selectedFilter == 'All' || _selectedFilter == 'Mobile')
                                        LineChartBarData(
                                          spots: mobileSpots,
                                          isCurved: true,
                                          color: colorScheme.primary, // Mobile color
                                          barWidth: 2,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                colorScheme.primary.withOpacity(0.15),
                                                colorScheme.primary.withOpacity(0.0),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                        ),
                                      if (_selectedFilter == 'All' || _selectedFilter == 'Offline')
                                        LineChartBarData(
                                          spots: offlineSpots,
                                          isCurved: true,
                                          color: Colors.redAccent,
                                          barWidth: 2,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.redAccent.withOpacity(0.15),
                                                Colors.redAccent.withOpacity(0.0),
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
                        'Insights & Recommendations',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: context.read<NetworkService>().getLoggedNetworkStates(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return _buildInfoSection(
                              title: 'No Insights Available',
                              value: 'No network data to generate insights.',
                              icon: Icons.info_outline_rounded,
                              colorScheme: colorScheme,
                              isError: true,
                            );
                          }
                          final loggedStates = snapshot.data!;
                          return _buildInsightsSection(colorScheme, loggedStates);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
