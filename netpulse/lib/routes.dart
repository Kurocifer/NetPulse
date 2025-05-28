import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/splash_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/confirmation_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; // Import the new screen

class AppRoutes {
  static const String splash = '/splash';
  static const String createAccount = '/create_account';
  static const String confirmation = '/confirmation';
  static const String login = '/login';
  static const String home = '/home';

  static List<GetPage> get pages => [
        GetPage(
          name: splash,
          page: () => const SplashScreen(),
        ),
        GetPage(
          name: createAccount,
          page: () => const CreateAccountScreen(),
        ),
        GetPage(
          name: confirmation,
          page: () => const ConfirmationScreen(),
        ),
        GetPage(
          name: login,
          page: () => const LoginScreen(),
        ),
        GetPage(
          name: home,
          page: () => const HomeScreen(),
        ),
      ];
}