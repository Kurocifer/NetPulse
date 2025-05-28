import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes.dart';
import 'config/supabase_config.dart';
import 'presentation/blocs/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final initialRoute = isLoggedIn ? AppRoutes.home : AppRoutes.splash;
  runApp(NetPulseApp(initialRoute: initialRoute));
}

class NetPulseApp extends StatelessWidget {
  final String initialRoute;

  const NetPulseApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()),
      ],
      child: GetMaterialApp(
        title: 'NetPulse',
        initialRoute: initialRoute,
        getPages: AppRoutes.routes,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
      ),
    );
  }
}