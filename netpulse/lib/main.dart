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

// const Color primaryColor = Color.fromARGB(255, 15, 52, 170); // Dark Blue: #051650
// const Color secondaryColor = Color.fromARGB(255, 57, 99, 228); // Medium Blue: #123499
const Color primaryColor = Color.fromARGB(255, 45, 86, 221); // Dark Blue: #051650
const Color secondaryColor = Color.fromARGB(255, 71, 110, 226);


const String backgroundTaskKey = "com.example.netpulse.networkMonitoringTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // await Supabase.initialize(
      //   url: 'YOUR_SUPABASE_URL',
      //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
      // );

      final phoneService = PhoneService();
      final networkService = NetworkService(phoneService: phoneService, locationService: null);

      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        await networkService.getNetworkInfoFromResult(
          connectivityResult.isNotEmpty ? connectivityResult.first : ConnectivityResult.none,
          isBackground: true,
        );

        final loggedStates = await networkService.getLoggedNetworkStates();
        if (loggedStates.isEmpty) {
          print('Background task: No network states logged.');
          return Future.value(true);
        }

        final latestState = loggedStates.last;
        final networkType = latestState['networkType'] as String;
        final quality = (latestState['quality'] as num? ?? 0).toDouble();
        final isp = latestState['isp'] as String;
        final latency = latestState['latency'] as String? ?? 'N/A';
        final packetLoss = latestState['packetLoss'] as String? ?? 'N/A';

        print('Background task executed: NetworkType: $networkType, Quality: $quality, ISP: $isp, Latency: $latency, PacketLoss: $packetLoss');

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
  // final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final initialTheme = prefs.getString('theme') ?? 'System';
  // final initialRoute = isLoggedIn ? AppRoutes.home : AppRoutes.splash;
  final initialRoute = AppRoutes.splash;

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  await Workmanager().registerPeriodicTask(
    backgroundTaskKey,
    backgroundTaskKey,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(seconds: 10),
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
                debugShowCheckedModeBanner: false,
                title: 'NetPulse',
                initialRoute: initialRoute,
                getPages: AppRoutes.routes,
                // Light Theme Definition
                theme: ThemeData(
                  brightness: Brightness.light,
                  primaryColor: primaryColor,
                  colorScheme: ColorScheme.light(
                    primary: secondaryColor,
                    secondary: secondaryColor,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                    onPrimary: Colors.white,
                    onSecondary: Colors.white,
                    error: Colors.redAccent,
                  ),
                  scaffoldBackgroundColor: Colors.white,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: true,
                  ),
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: secondaryColor,
                    selectionColor: secondaryColor,
                    selectionHandleColor: secondaryColor,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: secondaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryColor,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
                ),

                // Updated Dark Theme Definition
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  primaryColor: primaryColor,
                  colorScheme: ColorScheme.dark(
                    primary: primaryColor,
                    secondary: secondaryColor,
                    surface: const Color(0xFF1A1A2E),
                    onSurface: Colors.white70,
                    onPrimary: Colors.white,
                    onSecondary: Colors.white,
                    error: Colors.redAccent,
                  ),
                  scaffoldBackgroundColor: const Color(0xFF0F0F1A),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: true,
                  ),
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: secondaryColor,
                    selectionColor: secondaryColor,
                    selectionHandleColor: secondaryColor,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.grey[700],
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: secondaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryColor,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
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
