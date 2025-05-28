import 'package:get/get.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/create_account_screen.dart';
import 'presentation/screens/confirmation_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String createAccount = '/create_account';
  static const String confirmation = '/confirmation';
  static const String login = '/login';
  static const String home = '/home';

  static List<GetPage> get pages => [
        GetPage(name: splash, page: () => const SplashScreen()),
        GetPage(name: createAccount, page: () => const CreateAccountScreen()),
        GetPage(name: confirmation, page: () => const ConfirmationScreen()),
        GetPage(name: login, page: () => const LoginScreen()),
        GetPage(name: home, page: () => const HomeScreen()),
      ];
}