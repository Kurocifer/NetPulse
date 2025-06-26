import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:netpulse/presentation/widgets/action_button.dart';
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
  bool _isButtonPressed = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _loggedStates = [];
  Future<void>? _dataFetchFuture;

  @override
  void initState() {
    super.initState();
    _dataFetchFuture = _fetchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final networkService = context.read<NetworkService>();
    _loggedStates = await networkService.getLoggedNetworkStates();
    if (mounted) {
      setState(() {});
    }
  }

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
      _isButtonPressed = true;
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
        final allUsers = await Supabase.instance.client
            .from('Users')
            .select('Emails');
        developer.log('All emails in Users table: $allUsers');
        throw Exception(
          'User not found in Users table with email: "$queryEmail"',
        );
      }

      final userRow = response.first;
      final userIdFromUsersTable = userRow['UserID'];
      if (userIdFromUsersTable == null) {
        throw Exception(
          'User ID is null in Users table for email: "$queryEmail"',
        );
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

      final locationService = context.read<LocationService>();
      final position = await locationService.getCurrentLocation();
      final latitude = position?.latitude;
      final longitude = position?.longitude;

      developer.log(
        'Location data - Latitude: $latitude, Longitude: $longitude',
      );
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
          content: Text(
            'Metrics submitted successfully!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      await _fetchData();
    } catch (e) {
      String errorMessage = 'Error submitting feedback. Please try again.';
      if (e is PostgrestException) {
        if (e.message.contains('Failed to fetch') ||
            e.message.contains('Network error')) {
          errorMessage = 'No internet connection. Please check your network.';
        } else if (e.code == 'PGRST301' || e.message.contains('timeout')) {
          errorMessage = 'Connection timed out. Please check your network.';
        } else if (e.message.contains('not found')) {
          errorMessage = 'User not found. Please ensure you are logged in.';
        }
      } else if (e.toString().contains('No network state available')) {
        errorMessage =
            'No network data available. Please monitor your network first.';
      } else if (e.toString().contains('User not authenticated')) {
        errorMessage = 'Please log in to submit feedback.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
        _isButtonPressed = false;
      });
    }
  }

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
          Icon(
            icon,
            size: 28,
            color: isError ? colorScheme.error : secondaryColor,
          ),
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
                    color: isError
                        ? colorScheme.error
                        : colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    ColorScheme colorScheme,
  ) {
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

  Widget _buildFilterOptions(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ['All', 'Wi-Fi', 'Mobile', 'Offline'].map((filter) {
        final isSelected = _selectedFilter == filter;
        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (selected) {
            if (selected && _selectedFilter != filter) {
              final currentPosition = _scrollController.hasClients
                  ? _scrollController.offset
                  : 0.0;
              setState(() {
                _selectedFilter = filter;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(currentPosition);
                  developer.log('Restored scroll position: $currentPosition');
                }
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
            side: BorderSide(
              color: isSelected ? secondaryColor : Colors.transparent,
            ),
          ),
          elevation: 0,
        );
      }).toList(),
    );
  }

  double _getNiceInterval(double min, double max, int desiredCount) {
    if (min == max) {
      return 1000.0;
    }
    final range = max - min;
    final roughInterval = range / (desiredCount - 1);

    final List<double> niceIntervals = [
      100,
      200,
      500,
      1000,
      2000,
      2500,
      5000,
      10000,
      20000,
      25000,
      50000,
      100000,
      200000,
      500000,
      1000000,
    ];

    for (var interval in niceIntervals) {
      if (interval >= roughInterval) {
        return interval;
      }
    }
    return roughInterval.ceilToDouble();
  }

  Widget _buildEmptyChartPlaceholder(ColorScheme colorScheme, String message) {
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

  Widget _buildInsightsSection(
    ColorScheme colorScheme,
    List<Map<String, dynamic>> loggedStates,
  ) {
    String tipMessage = 'No specific insights yet.';
    IconData tipIcon = Icons.info_outline_rounded;
    Color tipIconColor = colorScheme.onBackground.withOpacity(0.7);
    const Color statusGreen = Color(0xFF4CAF50);
    const Color statusOrange = Color(0xFFFF9800);
    const Color statusRed = Color(0xFFF44336);

    if (loggedStates.isNotEmpty) {
      final quality = (loggedStates.last['quality'] as num? ?? 0).toDouble();

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
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Helper to lighten a color
    Color lightenColor(Color color, [double amount = 0.2]) {
      final hsl = HSLColor.fromColor(color);
      return hsl
          .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
          .toColor();
    }

    return BlocProvider(
      create: (context) => NetworkBloc(context.read<NetworkService>()),
      child: Scaffold(
        body: Container(
          child: SafeArea(
            child: FutureBuilder<void>(
              future: _dataFetchFuture,
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
                        style: GoogleFonts.poppins(
                          color: colorScheme.error,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }
                if (_loggedStates.isEmpty) {
                  return SingleChildScrollView(
                    key: const ValueKey('empty_scroll_view'),
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(colorScheme),
                        _buildInfoSection(
                          title: 'No Data Available',
                          value:
                              'Please ensure network monitoring is active and data is being logged.',
                          icon: Icons.info_outline_rounded,
                          colorScheme: colorScheme,
                          isError: true,
                        ),
                        const SizedBox(height: 30),
                        AnimatedScale(
                          scale: _isButtonPressed ? 0.9 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              BuildActionButton(
                                context: context,
                                label: _isSubmitting
                                    ? ''
                                    : 'Submit Network Metrics',
                                icon: _isSubmitting ? null : Icons.send_rounded,
                                onPressed: _isSubmitting
                                    ? null
                                    : () async {
                                        setState(() {
                                          _isButtonPressed = true;
                                        });
                                        await _submitMetrics();
                                        Future.delayed(
                                          const Duration(milliseconds: 200),
                                          () {
                                            if (mounted) {
                                              setState(() {
                                                _isButtonPressed = false;
                                              });
                                            }
                                          },
                                        );
                                      },
                                buttonGradient: LinearGradient(
                                  colors: _isButtonPressed || _isSubmitting
                                      ? [
                                          primaryColor.withOpacity(0.8),
                                          lightenColor(secondaryColor, 0.3),
                                        ]
                                      : [primaryColor, secondaryColor],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                textColor: colorScheme.onPrimary,
                                fontSize: 18,
                              ),
                              if (_isSubmitting)
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                  strokeWidth: 2,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final loggedStates = _loggedStates;
                final timestamps = loggedStates
                    .map(
                      (state) => DateTime.parse(state['timestamp'] as String),
                    )
                    .toList();
                final earliestTime = timestamps.reduce(
                  (a, b) => a.isBefore(b) ? a : b,
                );
                final latestTime = timestamps.reduce(
                  (a, b) => a.isAfter(b) ? a : b,
                );

                final latestState = loggedStates.last;
                final networkType = latestState['networkType'] as String;
                final quality = (latestState['quality'] as num? ?? 0)
                    .toDouble();
                final latency = latestState['latency'] as String? ?? 'N/A';
                final packetLoss =
                    latestState['packetLoss'] as String? ?? 'N/A';

                final allQualities = loggedStates
                    .map((state) => (state['quality'] as num? ?? 0).toDouble())
                    .toList();
                final avgQuality =
                    allQualities.reduce((a, b) => a + b) / allQualities.length;
                final maxQuality = allQualities.reduce((a, b) => a > b ? a : b);
                final minQuality = allQualities.where((q) => q > 0).isEmpty
                    ? 0.0
                    : allQualities
                          .where((q) => q > 0)
                          .reduce((a, b) => a < b ? a : b);
                final uptime =
                    (loggedStates
                                .where(
                                  (state) => state['networkType'] != 'Offline',
                                )
                                .length /
                            loggedStates.length *
                            100)
                        .toStringAsFixed(1);

                return SingleChildScrollView(
                  key: const ValueKey('data_scroll_view'),
                  controller: _scrollController,
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
                          _buildSummaryItem(
                            'Avg Throughput',
                            formatThroughput(avgQuality),
                            colorScheme,
                          ),
                          _buildSummaryItem(
                            'Max Throughput',
                            formatThroughput(maxQuality),
                            colorScheme,
                          ),
                          _buildSummaryItem(
                            'Min Throughput',
                            formatThroughput(minQuality),
                            colorScheme,
                          ),
                          _buildSummaryItem('Uptime', '$uptime%', colorScheme),
                        ],
                      ),
                      const SizedBox(height: 30),

                      AnimatedScale(
                        scale: _isButtonPressed ? 0.9 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            BuildActionButton(
                              context: context,
                              label: _isSubmitting
                                  ? ''
                                  : 'Submit Network Metrics',
                              icon: _isSubmitting ? null : Icons.send_rounded,
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isButtonPressed = true;
                                      });
                                      await _submitMetrics();
                                      Future.delayed(
                                        const Duration(milliseconds: 200),
                                        () {
                                          if (mounted) {
                                            setState(() {
                                              _isButtonPressed = false;
                                            });
                                          }
                                        },
                                      );
                                    },
                              buttonGradient: LinearGradient(
                                colors: _isButtonPressed || _isSubmitting
                                    ? [
                                        primaryColor.withOpacity(0.8),
                                        lightenColor(secondaryColor, 0.3),
                                      ]
                                    : [primaryColor, secondaryColor],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              textColor: colorScheme.onPrimary,
                            ),
                            if (_isSubmitting)
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                                strokeWidth: 2,
                              ),
                          ],
                        ),
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
                      _buildChartSection(colorScheme, loggedStates),
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
                      _buildInsightsSection(colorScheme, loggedStates),
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

  Widget _buildChartSection(
    ColorScheme colorScheme,
    List<Map<String, dynamic>> allLoggedStates,
  ) {
    if (allLoggedStates.isEmpty) {
      return _buildEmptyChartPlaceholder(
        colorScheme,
        'No historical data available yet.\nStart monitoring to see trends.',
      );
    }

    List<DateTime> timestampsForChart = [];
    List<FlSpot> wifiSpots = [];
    List<FlSpot> mobileSpots = [];
    List<FlSpot> offlineSpots = [];

    if (_selectedFilter == 'All') {
      for (int i = 0; i < allLoggedStates.length; i++) {
        final state = allLoggedStates[i];
        final quality = (state['quality'] as num? ?? 0).toDouble();
        final timestamp = DateTime.parse(state['timestamp'] as String);
        timestampsForChart.add(timestamp);
        final xValue = i.toDouble();

        switch (state['networkType']) {
          case 'Wi-Fi':
            wifiSpots.add(FlSpot(xValue, quality));
            break;
          case 'Mobile':
            mobileSpots.add(FlSpot(xValue, quality));
            break;
          case 'Offline':
            offlineSpots.add(FlSpot(xValue, quality));
            break;
        }
      }
    } else {
      final filteredStates = allLoggedStates
          .where((state) => state['networkType'] == _selectedFilter)
          .toList();
      if (filteredStates.isEmpty) {
        return _buildEmptyChartPlaceholder(
          colorScheme,
          'No data available for the selected network type.',
        );
      }

      for (int i = 0; i < filteredStates.length; i++) {
        final state = filteredStates[i];
        final quality = (state['quality'] as num? ?? 0).toDouble();
        final timestamp = DateTime.parse(state['timestamp'] as String);
        timestampsForChart.add(timestamp);
        final xValue = i.toDouble();

        switch (_selectedFilter) {
          case 'Wi-Fi':
            wifiSpots.add(FlSpot(xValue, quality));
            break;
          case 'Mobile':
            mobileSpots.add(FlSpot(xValue, quality));
            break;
          case 'Offline':
            offlineSpots.add(FlSpot(xValue, quality));
            break;
        }
      }
    }

    final List<double> qualitiesForYAxisCalculation = [];
    if (_selectedFilter == 'All' || _selectedFilter == 'Wi-Fi') {
      qualitiesForYAxisCalculation.addAll(wifiSpots.map((e) => e.y));
    }
    if (_selectedFilter == 'All' || _selectedFilter == 'Mobile') {
      qualitiesForYAxisCalculation.addAll(mobileSpots.map((e) => e.y));
    }
    if (_selectedFilter == 'All' || _selectedFilter == 'Offline') {
      qualitiesForYAxisCalculation.addAll(offlineSpots.map((e) => e.y));
    }

    if (qualitiesForYAxisCalculation.isEmpty) {
      return _buildEmptyChartPlaceholder(
        colorScheme,
        'Not enough data to display the graph with the current filter.',
      );
    }
    if (timestampsForChart.length < 2) {
      return _buildEmptyChartPlaceholder(
        colorScheme,
        'Not enough data points (minimum 2 required) to display a trend.',
      );
    }

    double minQualityGraph = qualitiesForYAxisCalculation.reduce(min);
    double maxQualityGraph = qualitiesForYAxisCalculation.reduce(max);

    if (minQualityGraph < 0) minQualityGraph = 0;
    if (maxQualityGraph == minQualityGraph)
      maxQualityGraph = minQualityGraph + 1.0;

    const int desiredYLabelCount = 5;
    final yInterval = _getNiceInterval(
      minQualityGraph,
      maxQualityGraph,
      desiredYLabelCount,
    );

    double calculatedMinY = (minQualityGraph / yInterval).floor() * yInterval;
    if (calculatedMinY < 0) calculatedMinY = 0;

    double calculatedMaxY = (maxQualityGraph / yInterval).ceil() * yInterval;
    if (calculatedMaxY <= calculatedMinY)
      calculatedMaxY = calculatedMinY + yInterval;

    if (calculatedMaxY - calculatedMinY < yInterval &&
        qualitiesForYAxisCalculation.isNotEmpty) {
      if (minQualityGraph == 0 && maxQualityGraph == 0) {
        calculatedMaxY = yInterval * (desiredYLabelCount - 1);
        if (calculatedMaxY == 0) calculatedMaxY = 1000.0;
      } else if (minQualityGraph == maxQualityGraph) {
        calculatedMaxY += yInterval;
      }
    }

    final int numberOfDataPoints = timestampsForChart.length;
    const int desiredXLabelCount = 4;

    double bottomInterval;
    if (numberOfDataPoints <= 1) {
      bottomInterval = 1.0;
    } else {
      bottomInterval =
          (numberOfDataPoints - 1) /
          (desiredXLabelCount - 1).clamp(1, desiredXLabelCount);
      if (bottomInterval < 1.0) bottomInterval = 1.0;
    }
    double latestDisplayedQuality = 0.0;
    if (_selectedFilter == 'Wi-Fi' && wifiSpots.isNotEmpty)
      latestDisplayedQuality = wifiSpots.last.y;
    else if (_selectedFilter == 'Mobile' && mobileSpots.isNotEmpty)
      latestDisplayedQuality = mobileSpots.last.y;
    else if (_selectedFilter == 'Offline' && offlineSpots.isNotEmpty)
      latestDisplayedQuality = offlineSpots.last.y;
    else if (_selectedFilter == 'All' &&
        qualitiesForYAxisCalculation.isNotEmpty) {
      latestDisplayedQuality = (allLoggedStates.last['quality'] as num? ?? 0.0)
          .toDouble();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest: ${formatThroughput(latestDisplayedQuality)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onBackground,
              ),
            ),
            Text(
              '${formatTime(timestampsForChart.first)} - ${formatTime(timestampsForChart.last)}',
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
                      if (timestampsForChart.isEmpty) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                        );
                      }
                      final index = value.toInt().clamp(
                        0,
                        timestampsForChart.length - 1,
                      );
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          formatTime(timestampsForChart[index]),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: colorScheme.onBackground.withOpacity(0.7),
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
                            color: colorScheme.onBackground.withOpacity(0.7),
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
              maxX: (timestampsForChart.length > 0)
                  ? (timestampsForChart.length - 1).toDouble()
                  : 0,
              minY: calculatedMinY,
              maxY: calculatedMaxY,
              lineBarsData: [
                if (_selectedFilter == 'All' || _selectedFilter == 'Wi-Fi')
                  LineChartBarData(
                    spots: wifiSpots,
                    isCurved: true,
                    color: const Color.fromARGB(255, 99, 222, 37),
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
                    color: colorScheme.primary,
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
  }
}
