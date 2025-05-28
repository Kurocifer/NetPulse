import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'routes.dart';
import 'config/supabase_config.dart';
import 'presentation/blocs/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const NetPulseApp());
}

class NetPulseApp extends StatelessWidget {
  const NetPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(),
      child: GetMaterialApp(
        title: 'NetPulse',
        initialRoute: AppRoutes.login, // Start at LoginScreen
        getPages: AppRoutes.pages,
      ),
    );
  }
}