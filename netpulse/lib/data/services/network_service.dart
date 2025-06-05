import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:dart_ping/dart_ping.dart';
import 'phone_service.dart';
import 'location_service.dart';

class NetworkService {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();
  final PhoneService _phoneService;
  final LocationService? _locationService; // Private field, nullable
  Timer? _simCheckTimer;
  Map<String, dynamic> _currentNetworkInfo = {
    'networkType': 'Offline',
    'isp': 'Offline',
  };
  String? _lastCarrierName;

  NetworkService({required PhoneService phoneService, LocationService? locationService})
      : _phoneService = phoneService,
        _locationService = locationService {
    _startListening();
    _startSimChangeDetection();
  }

  void _startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty) {
        getNetworkInfoFromResult(results.first);
      }
    });
  }

  void _startSimChangeDetection() {
    _simCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final simInfo = await _phoneService.getSimInfo();
      final currentCarrierName = simInfo?.carrierName ?? 'Unknown';
      if (_lastCarrierName != null && _lastCarrierName != currentCarrierName) {
        print('SIM change detected: $_lastCarrierName -> $currentCarrierName');
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult.isNotEmpty) {
          await getNetworkInfoFromResult(connectivityResult.first);
        }
      }
      _lastCarrierName = currentCarrierName;
    });
  }

  Future<void> getNetworkInfoFromResult(ConnectivityResult result, {bool isBackground = false}) async {
    Map<String, dynamic> networkInfo = {
      'networkType': 'Offline',
      'isp': 'Offline',
    };

    final simInfo = await _phoneService.getSimInfo();
    if (simInfo != null) {
      networkInfo['isp'] = simInfo.carrierName;
    }

    if (result == ConnectivityResult.wifi) {
      networkInfo['networkType'] = 'Wi-Fi';
      networkInfo['isp'] = 'Wi-Fi';
    } else if (result == ConnectivityResult.mobile) {
      networkInfo['networkType'] = 'Mobile';
    } else if (result == ConnectivityResult.none) {
      networkInfo['networkType'] = 'Offline';
    }

    _currentNetworkInfo = networkInfo;
    await _logNetworkState(networkInfo, isBackground: isBackground);
  }

  Future<void> _logNetworkState(Map<String, dynamic> networkInfo, {bool isBackground = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> loggedStates = prefs.getStringList('network_states') ?? [];
    final now = DateTime.now();
    final timestampStr = now.toIso8601String();
    final quality = await _measureThroughput(networkInfo['networkType']);
    final metrics = await _measureNetworkMetrics(networkInfo['networkType']);
    
    // Skip location fetch in background mode or if _locationService is null
    final position = isBackground || _locationService == null ? null : await _locationService.getCurrentLocation();
    final latitude = position?.latitude;
    final longitude = position?.longitude;

    final state = {
      'timestamp': timestampStr,
      'networkType': networkInfo['networkType'],
      'isp': networkInfo['isp'],
      'stateValue': _getStateValue(networkInfo['networkType']),
      'quality': quality,
      'latency': metrics['latency'],
      'packetLoss': metrics['packetLoss'],
      'latitude': latitude,
      'longitude': longitude,
    };
    loggedStates.add(jsonEncode(state));
    if (loggedStates.length > 144) {
      loggedStates = loggedStates.sublist(loggedStates.length - 144);
    }
    await prefs.setStringList('network_states', loggedStates);
  }

  Future<Map<String, dynamic>> getNetworkInfo() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.isNotEmpty) {
      await getNetworkInfoFromResult(connectivityResult.first);
    } else {
      _currentNetworkInfo = {'networkType': 'Offline', 'isp': 'Offline'};
    }
    return _currentNetworkInfo;
  }

  Map<String, dynamic> getCurrentNetworkInfoSync() {
    return _currentNetworkInfo;
  }

  Future<double> _measureThroughput(String networkType) async {
    if (networkType == 'Offline') {
      return 0.0;
    }

    try {
      const testFileUrl =
          'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png';
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(testFileUrl));
      stopwatch.stop();

      if (response.statusCode != 200) {
        return 0.0;
      }

      final bytes = response.bodyBytes.length;
      final timeInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
      final speedInKbps = ((bytes * 8) / timeInSeconds / 1000);
      return speedInKbps;
    } catch (e) {
      print("Failed to measure throughput: $e");
      return 0.0;
    }
  }

  Future<Map<String, String>> _measureNetworkMetrics(String networkType) async {
    if (networkType == 'Offline') {
      return {'latency': 'N/A', 'packetLoss': 'N/A'};
    }
    try {
      final ping = Ping('8.8.8.8', count: 5, timeout: 2);
      int sent = 0;
      int received = 0;
      int totalRtt = 0;

      await for (final result in ping.stream) {
        sent++;
        if (result.response != null && result.response!.time != null) {
          received++;
          totalRtt += result.response!.time!.inMilliseconds;
        }
      }

      String latency;
      String packetLoss;

      if (sent == 0) {
        latency = 'N/A';
        packetLoss = 'N/A';
      } else {
        latency = received > 0 ? '${(totalRtt / received).round()} ms' : 'N/A';
        final loss = ((sent - received) / sent) * 100;
        packetLoss = '${loss.toStringAsFixed(1)}%';
      }

      return {'latency': latency, 'packetLoss': packetLoss};
    } catch (e) {
      print("Failed to measure network metrics: $e");
      return {'latency': 'N/A', 'packetLoss': 'N/A'};
    }
  }

  int _getStateValue(String networkType) {
    switch (networkType) {
      case 'Wi-Fi':
        return 2;
      case 'Mobile':
        return 1;
      default:
        return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getLoggedNetworkStates() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedStates = prefs.getStringList('network_states') ?? [];
    return loggedStates
        .map((state) => jsonDecode(state) as Map<String, dynamic>)
        .toList();
  }

  Stream<Map<String, dynamic>> getNetworkStream() async* {
    yield _currentNetworkInfo;

    await for (final result in _connectivity.onConnectivityChanged) {
      if (result.isNotEmpty) {
        await getNetworkInfoFromResult(result.first);
        yield _currentNetworkInfo;
      } else {
        final offlineState = {'networkType': 'Offline', 'isp': 'Offline'};
        _currentNetworkInfo = offlineState;
        await _logNetworkState(offlineState);
        yield offlineState;
      }
    }
  }

  void dispose() {
    _connectivitySubscription.cancel();
    _simCheckTimer?.cancel();
  }
}