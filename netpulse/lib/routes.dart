import 'package:get/get.dart';
import 'package:netpulse/presentation/screens/splash_screen.dart';
import 'package:netpulse/presentation/screens/login_screen.dart';
import 'package:netpulse/presentation/screens/create_account_screen.dart';
import 'package:netpulse/presentation/screens/confirmation_screen.dart';
import 'package:netpulse/presentation/screens/main_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String createAccount = '/createAccount';
  static const String confirmation = '/confirmation';
  static const String home = '/home';

  static final routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: createAccount, page: () => const CreateAccountScreen()),
    GetPage(name: confirmation, page: () => const ConfirmationScreen()),
    GetPage(name: home, page: () => const MainScreen()),
  ];
}