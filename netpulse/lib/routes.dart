import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String createAccount = '/create_account';
  static const String confirmation = '/confirmation';
  static const String login = '/login';
  static const String home = '/home';

  static List<GetPage> get pages => [
        GetPage(
          name: splash,
          page: () => const Scaffold(
            body: Center(child: Text('Splash Screen Placeholder')),
          ),
        ),
        GetPage(
          name: createAccount,
          page: () => const Scaffold(
            body: Center(child: Text('Create Account Placeholder')),
          ),
        ),
        GetPage(
          name: confirmation,
          page: () => const Scaffold(
            body: Center(child: Text('Confirmation Placeholder')),
          ),
        ),
        GetPage(
          name: login,
          page: () => const Scaffold(
            body: Center(child: Text('Login Placeholder')),
          ),
        ),
        GetPage(
          name: home,
          page: () => const Scaffold(
            body: Center(child: Text('Home Placeholder')),
          ),
        ),
      ];
}