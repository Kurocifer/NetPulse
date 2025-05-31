import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'config/supabase_config.dart';
import 'data/services/network_service.dart';
import 'data/services/location_service.dart';
import 'data/services/phone_service.dart';
import 'presentation/blocs/auth_bloc.dart';
import 'presentation/blocs/network_bloc.dart';
import 'routes.dart';

// Define a unique name for the background task
const String backgroundTaskKey = "com.example.netpulse.networkMonitoringTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize Supabase for background submission
      await Supabase.initialize(
        url: 'YOUR_SUPABASE_URL',
        anonKey: 'YOUR_SUPABASE_ANON_KEY',
      );

      // Initialize services for background task
      final phoneService = PhoneService();
      final networkService = NetworkService(phoneService: phoneService, locationService: null);

      // Check network connectivity before proceeding
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        // Update network state in background mode
        await networkService.getNetworkInfoFromResult(
          connectivityResult.isNotEmpty ? connectivityResult.first : ConnectivityResult.none,
          isBackground: true,
        );

        // Retrieve logged states
        final loggedStates = await networkService.getLoggedNetworkStates();
        if (loggedStates.isEmpty) {
          print('Background task: No network states logged.');
          return Future.value(true);
        }

        // Log the latest state for debugging
        final latestState = loggedStates.last;
        final networkType = latestState['networkType'] as String;
        final quality = (latestState['quality'] as num? ?? 0).toDouble();
        final isp = latestState['isp'] as String;
        final latency = latestState['latency'] as String? ?? 'N/A';
        final packetLoss = latestState['packetLoss'] as String? ?? 'N/A';

        print('Background task executed: NetworkType: $networkType, Quality: $quality, ISP: $isp, Latency: $latency, PacketLoss: $packetLoss');

        // Submit to Supabase if user is authenticated
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final queryEmail = (user.email ?? '').trim();
          final response = await Supabase.instance.client
              .from('Users')
              .select('UserID')
              .ilike('Email', queryEmail)
              .limit(1);

          if (response.isNotEmpty) {
            final userId = response.first['UserID'] as String;
            await Supabase.instance.client.from('NetworkMetrics').insert({
              'UserID': userId,
              'SignalStrength': quality >= 1000 ? 'Good' : quality > 300 ? 'Fair' : 'Poor',
              'Latency': latency,
              'PacketLoss': packetLoss,
              'ISP': isp,
              'Latitude': null,
              'Longitude': null,
              'Throughput': quality,
            });
            print('Background task: Metrics submitted to Supabase.');
          }
        }
      } else {
        print('Background task skipped: No network connection.');
      }

      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

Future<void> requestPhoneStatePermission() async {
  var status = await Permission.phone.status;
  if (!status.isGranted) {
    await Permission.phone.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  await requestPhoneStatePermission();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final initialTheme = prefs.getString('theme') ?? 'System';
  final initialRoute = isLoggedIn ? AppRoutes.home : AppRoutes.splash;

  // Initialize WorkManager for background tasks
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false in production
  );

  // Register a periodic background task (every 15 minutes)
  await Workmanager().registerPeriodicTask(
    backgroundTaskKey,
    backgroundTaskKey,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(seconds: 10),
    // Removed invalid constraints parameter
  );

  runApp(NetPulseApp(initialRoute: initialRoute, initialTheme: initialTheme));
}

class NetPulseApp extends StatelessWidget {
  final String initialRoute;
  final String initialTheme;

  const NetPulseApp({super.key, required this.initialRoute, required this.initialTheme});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => PhoneService()),
        RepositoryProvider(create: (context) => LocationService()),
      ],
      child: Builder(
        builder: (context) {
          return MultiRepositoryProvider(
            providers: [
              RepositoryProvider(
                create: (context) => NetworkService(
                  phoneService: context.read<PhoneService>(),
                  locationService: context.read<LocationService>(),
                ),
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (context) => AuthBloc()),
                BlocProvider(
                  create: (context) => NetworkBloc(context.read<NetworkService>()),
                ),
              ],
              child: GetMaterialApp(
                title: 'NetPulse',
                initialRoute: initialRoute,
                getPages: AppRoutes.routes,
                theme: ThemeData(
                  brightness: Brightness.light,
                  primarySwatch: Colors.blue,
                  scaffoldBackgroundColor: Colors.grey[100],
                  textTheme: GoogleFonts.poppinsTextTheme(
                    ThemeData.light().textTheme,
                  ),
                  colorScheme: ColorScheme.fromSwatch(
                    primarySwatch: Colors.blue,
                    brightness: Brightness.light,
                  ).copyWith(
                    secondary: Colors.teal,
                    onBackground: Colors.black87,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  primarySwatch: Colors.blue,
                  scaffoldBackgroundColor: Colors.grey[850],
                  textTheme: GoogleFonts.poppinsTextTheme(
                    ThemeData.dark().textTheme,
                  ),
                  colorScheme: ColorScheme.fromSwatch(
                    primarySwatch: Colors.blue,
                    brightness: Brightness.dark,
                  ).copyWith(
                    secondary: Colors.teal,
                    onBackground: Colors.white70,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                themeMode: initialTheme == 'System'
                    ? ThemeMode.system
                    : initialTheme == 'Light'
                        ? ThemeMode.light
                        : ThemeMode.dark,
              ),
            ),
          );
        },
      ),
    );
  }
}